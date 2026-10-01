import {initializeApp} from "firebase-admin/app";
import {
  DocumentReference,
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();

const db = getFirestore();

setGlobalOptions({
  maxInstances: 10,
});

type BookingData = {
  customerId?: unknown;
  shopId?: unknown;
  barberId?: unknown;
  serviceName?: unknown;
  customerName?: unknown;
  barberName?: unknown;
  startTime?: unknown;
  endTime?: unknown;
  bookingDate?: unknown;
  status?: unknown;
  cancelledBy?: unknown;
  reminderSent?: unknown;
};

type NotificationType =
  | "bookingCreated"
  | "bookingConfirmed"
  | "bookingRejected"
  | "bookingCancelled"
  | "bookingCompleted"
  | "bookingNoShow"
  | "scheduleChanged"
  | "appointmentReminder";

type NotificationPayload = {
  recipientId: string;
  type: NotificationType;
  title: string;
  body: string;
  bookingId: string;
};

/// Android channel created by the Flutter client; keep the two in sync.
const DEFAULT_CHANNEL_ID = "barber_booking_default";

/// FCM error codes that mean the token must be removed.
const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function getBookingData(
  data: Record<string, unknown> | undefined,
): BookingData {
  return data ?? {};
}

function notificationId(
  bookingId: string,
  type: NotificationType,
  recipientId: string,
): string {
  return `${bookingId}_${type}_${recipientId}`;
}

function buildNotification(
  payload: NotificationPayload,
) {
  return {
    recipientId: payload.recipientId,
    type: payload.type,
    title: payload.title,
    body: payload.body,
    bookingId: payload.bookingId,
    createdAt: FieldValue.serverTimestamp(),
    isRead: false,
  };
}

async function getOwnerId(shopId: string): Promise<string> {
  if (!shopId) {
    return "";
  }

  const shopSnapshot = await db
    .collection("barberShops")
    .doc(shopId)
    .get();

  if (!shopSnapshot.exists) {
    console.warn(
      `Barber shop ${shopId} was not found.`,
    );
    return "";
  }

  const data = shopSnapshot.data();

  return stringValue(data?.ownerId);
}

/**
 * Resolves the authenticated user id of a barber.
 *
 * Bookings store the barber *document* id; notifications and device tokens are
 * scoped by the barber's auth uid (`barbers/{barberId}.userId`).
 */
async function getBarberUserId(barberId: string): Promise<string> {
  if (!barberId) {
    return "";
  }

  const barberSnapshot = await db
    .collection("barbers")
    .doc(barberId)
    .get();

  if (!barberSnapshot.exists) {
    console.warn(`Barber ${barberId} was not found.`);
    return "";
  }

  return stringValue(barberSnapshot.data()?.userId);
}

/** Parses an "HH:mm" booking time into minutes from midnight. */
function timeToMinutes(value: unknown): number | null {
  const text = stringValue(value);

  if (text.length !== 5 || text[2] !== ":") {
    return null;
  }

  const hours = Number.parseInt(text.slice(0, 2), 10);
  const minutes = Number.parseInt(text.slice(3, 5), 10);

  if (Number.isNaN(hours) || Number.isNaN(minutes)) {
    return null;
  }

  if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
    return null;
  }

  return hours * 60 + minutes;
}

async function createNotifications(
  notifications: NotificationPayload[],
): Promise<void> {
  const uniqueNotifications = new Map<string, NotificationPayload>();

  for (const notification of notifications) {
    if (!notification.recipientId) {
      continue;
    }

    const id = notificationId(
      notification.bookingId,
      notification.type,
      notification.recipientId,
    );

    uniqueNotifications.set(id, notification);
  }

  if (uniqueNotifications.size === 0) {
    return;
  }

  const batch = db.batch();

  for (const [id, notification] of uniqueNotifications) {
    const reference = db
      .collection("notifications")
      .doc(id);

    batch.set(
      reference,
      buildNotification(notification),
      {merge: false},
    );
  }

  await batch.commit();
}

/**
 * Sends one push notification to every device registered for [recipientId]
 * (`users/{recipientId}/devices/{token}`) and deletes tokens FCM reports as
 * invalid.
 */
async function sendPushToRecipient(
  notification: NotificationPayload,
): Promise<void> {
  const {recipientId} = notification;

  if (!recipientId) {
    return;
  }

  const devicesSnapshot = await db
    .collection("users")
    .doc(recipientId)
    .collection("devices")
    .get();

  if (devicesSnapshot.empty) {
    return;
  }

  const tokens: string[] = [];
  const referencesByToken = new Map<string, DocumentReference>();

  for (const device of devicesSnapshot.docs) {
    const token = stringValue(device.data().token) || device.id;

    if (!token || referencesByToken.has(token)) {
      continue;
    }

    referencesByToken.set(token, device.ref);
    tokens.push(token);
  }

  if (tokens.length === 0) {
    return;
  }

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      type: notification.type,
      bookingId: notification.bookingId,
      recipientId,
    },
    android: {
      priority: "high",
      notification: {
        channelId: DEFAULT_CHANNEL_ID,
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });

  const staleReferences: DocumentReference[] = [];

  response.responses.forEach((result, index) => {
    if (result.success) {
      return;
    }

    const code = result.error?.code ?? "";

    if (!INVALID_TOKEN_CODES.has(code)) {
      console.warn(
        `Push to device of ${recipientId} failed: ${code}`,
      );
      return;
    }

    const reference = referencesByToken.get(tokens[index]);

    if (reference) {
      staleReferences.push(reference);
    }
  });

  for (const reference of staleReferences) {
    try {
      await reference.delete();
    } catch (error) {
      console.warn(`Failed to delete stale device token: ${error}`);
    }
  }
}

/**
 * Persists a Firestore notification document for every payload **and** sends
 * the matching push notification. Push sending is server-side only.
 */
async function dispatchNotifications(
  notifications: NotificationPayload[],
): Promise<void> {
  await createNotifications(notifications);

  const uniqueRecipients = new Map<string, NotificationPayload>();

  for (const notification of notifications) {
    if (!notification.recipientId) {
      continue;
    }

    uniqueRecipients.set(notification.recipientId, notification);
  }

  for (const notification of uniqueRecipients.values()) {
    try {
      await sendPushToRecipient(notification);
    } catch (error) {
      console.error(
        `Failed to send push to ${notification.recipientId}: ${error}`,
      );
    }
  }
}

function bookingDateText(value: unknown): string {
  if (
    value &&
    typeof value === "object" &&
    "toDate" in value &&
    typeof value.toDate === "function"
  ) {
    const date = value.toDate() as Date;

    return date.toISOString().slice(0, 10);
  }

  return "";
}

/** True when the appointment date or start time changed. */
function bookingTimeChanged(
  before: BookingData,
  after: BookingData,
): boolean {
  if (
    bookingDateText(before.bookingDate) !==
    bookingDateText(after.bookingDate)
  ) {
    return true;
  }

  return (
    stringValue(before.startTime) !== stringValue(after.startTime)
  );
}

function createBookingCreatedNotifications(
  bookingId: string,
  booking: BookingData,
  ownerId: string,
  barberUserId: string,
): NotificationPayload[] {
  const customerName =
    stringValue(booking.customerName) || "A customer";
  const serviceName =
    stringValue(booking.serviceName) || "a service";
  const date = bookingDateText(booking.bookingDate);
  const startTime = stringValue(booking.startTime);

  const body =
    `${customerName} requested ${serviceName}` +
    `${date ? ` on ${date}` : ""}` +
    `${startTime ? ` at ${startTime}` : ""}.`;

  return [
    {
      recipientId: barberUserId,
      type: "bookingCreated",
      title: "New booking request",
      body,
      bookingId,
    },
    {
      recipientId: ownerId,
      type: "bookingCreated",
      title: "New booking request",
      body,
      bookingId,
    },
  ];
}

function createStatusChangeNotifications(
  bookingId: string,
  beforeStatus: string,
  afterStatus: string,
  booking: BookingData,
  ownerId: string,
  barberUserId: string,
): NotificationPayload[] {
  const customerId = stringValue(booking.customerId);
  const customerName =
    stringValue(booking.customerName) || "The customer";
  const serviceName =
    stringValue(booking.serviceName) || "the service";
  const startTime = stringValue(booking.startTime);

  if (
    beforeStatus === "pending" &&
    afterStatus === "confirmed"
  ) {
    // Spec: booking confirmed → customer only.
    return [
      {
        recipientId: customerId,
        type: "bookingConfirmed",
        title: "Booking confirmed",
        body:
          `Your booking for ${serviceName}` +
          `${startTime ? ` at ${startTime}` : ""} has been confirmed.`,
        bookingId,
      },
    ];
  }

  if (afterStatus === "cancelled") {
    const cancelledBy = stringValue(booking.cancelledBy);

    // The client records the cancelling role in `cancelledBy`
    // (customer / barber / owner; enforced by Firestore rules).
    if (cancelledBy === "customer") {
      // Customer cancelled: notify barber + owner only.
      return [
        {
          recipientId: barberUserId,
          type: "bookingCancelled",
          title: "Booking cancelled",
          body:
            `${customerName}'s booking for ${serviceName}` +
            " has been cancelled.",
          bookingId,
        },
        {
          recipientId: ownerId,
          type: "bookingCancelled",
          title: "Booking cancelled",
          body:
            `${customerName}'s booking for ${serviceName}` +
            " has been cancelled.",
          bookingId,
        },
      ];
    }

    if (cancelledBy === "barber" || cancelledBy === "owner") {
      const rejected = beforeStatus === "pending";

      // Barber/owner cancelled (pending → cancelled is the rejection path):
      // notify the customer only.
      return [
        {
          recipientId: customerId,
          type: rejected ? "bookingRejected" : "bookingCancelled",
          title: rejected ? "Booking rejected" : "Booking cancelled",
          body: rejected
            ? `Your booking for ${serviceName}` +
              " could not be confirmed."
            : `Your booking for ${serviceName}` +
              " has been cancelled.",
          bookingId,
        },
      ];
    }

    // Legacy documents without `cancelledBy`: fall back to the previous
    // status-based routing (pending → customer rejection; confirmed →
    // customer cancellation) plus barber/owner cancellation coverage.
    if (beforeStatus === "pending") {
      return [
        {
          recipientId: customerId,
          type: "bookingRejected",
          title: "Booking rejected",
          body:
            `Your booking for ${serviceName}` +
            " could not be confirmed.",
          bookingId,
        },
        {
          recipientId: barberUserId,
          type: "bookingCancelled",
          title: "Booking cancelled",
          body:
            `${customerName}'s booking for ${serviceName}` +
            " has been cancelled.",
          bookingId,
        },
        {
          recipientId: ownerId,
          type: "bookingCancelled",
          title: "Booking cancelled",
          body:
            `${customerName}'s booking for ${serviceName}` +
            " has been cancelled.",
          bookingId,
        },
      ];
    }

    return [
      {
        recipientId: customerId,
        type: "bookingCancelled",
        title: "Booking cancelled",
        body:
          `Your confirmed booking for ${serviceName}` +
          " has been cancelled.",
        bookingId,
      },
    ];
  }

  if (
    beforeStatus === "confirmed" &&
    afterStatus === "completed"
  ) {
    return [
      {
        recipientId: ownerId,
        type: "bookingCompleted",
        title: "Booking completed",
        body:
          `${customerName}'s booking for ${serviceName}` +
          " has been completed.",
        bookingId,
      },
    ];
  }

  if (
    beforeStatus === "confirmed" &&
    afterStatus === "noShow"
  ) {
    return [
      {
        recipientId: customerId,
        type: "bookingNoShow",
        title: "Booking marked as no-show",
        body:
          `Your booking for ${serviceName}` +
          " was marked as no-show.",
        bookingId,
      },
      {
        recipientId: ownerId,
        type: "bookingNoShow",
        title: "Booking marked as no-show",
        body:
          `${customerName}'s booking for ${serviceName}` +
          " was marked as no-show.",
        bookingId,
      },
    ];
  }

  return [];
}

function createRescheduledNotifications(
  bookingId: string,
  booking: BookingData,
  ownerId: string,
  barberUserId: string,
): NotificationPayload[] {
  const customerId = stringValue(booking.customerId);
  const customerName =
    stringValue(booking.customerName) || "The customer";
  const serviceName =
    stringValue(booking.serviceName) || "the service";
  const startTime = stringValue(booking.startTime);
  const date = bookingDateText(booking.bookingDate);
  const when =
    `${date ? ` on ${date}` : ""}` +
    `${startTime ? ` at ${startTime}` : ""}`;

  return [
    {
      recipientId: customerId,
      type: "scheduleChanged",
      title: "Booking rescheduled",
      body:
        `Your booking for ${serviceName}${when} has been rescheduled.`,
      bookingId,
    },
    {
      recipientId: barberUserId,
      type: "scheduleChanged",
      title: "Booking rescheduled",
      body:
        `${customerName}'s booking for ${serviceName}${when} ` +
        "has been rescheduled.",
      bookingId,
    },
    {
      recipientId: ownerId,
      type: "scheduleChanged",
      title: "Booking rescheduled",
      body:
        `${customerName}'s booking for ${serviceName}${when} ` +
        "has been rescheduled.",
      bookingId,
    },
  ];
}

export const onBookingCreated = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.warn("Booking created event has no document data.");
      return;
    }

    const bookingId = event.params.bookingId;
    const booking = getBookingData(snapshot.data());

    const shopId = stringValue(booking.shopId);

    if (!shopId) {
      console.error(
        `Booking ${bookingId} has no shopId.`,
      );
      return;
    }

    const ownerId = await getOwnerId(shopId);

    const barberUserId = await getBarberUserId(
      stringValue(booking.barberId),
    );

    const notifications =
      createBookingCreatedNotifications(
        bookingId,
        booking,
        ownerId,
        barberUserId,
      );

    await dispatchNotifications(notifications);

    console.log(
      `Created bookingCreated notifications for ${bookingId}.`,
    );
  },
);

export const onBookingUpdated = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnapshot = event.data?.before;
    const afterSnapshot = event.data?.after;

    if (!beforeSnapshot || !afterSnapshot) {
      console.warn(
        "Booking update event is missing before/after data.",
      );
      return;
    }

    const bookingId = event.params.bookingId;

    const before = getBookingData(
      beforeSnapshot.data(),
    );

    const after = getBookingData(
      afterSnapshot.data(),
    );

    // Appointment moved: re-arm the 1-hour reminder so a new one can be sent.
    if (bookingTimeChanged(before, after) && after.reminderSent === true) {
      await afterSnapshot.ref.update({
        reminderSent: false,
        reminderSentAt: FieldValue.delete(),
      });

      console.log(
        `Reset reminder state for rescheduled booking ${bookingId}.`,
      );
    }

    const beforeStatus = stringValue(before.status);
    const afterStatus = stringValue(after.status);

    if (!beforeStatus || !afterStatus) {
      console.warn(
        `Booking ${bookingId} has an invalid status transition.`,
      );
      return;
    }

    const shopId = stringValue(after.shopId);

    if (!shopId) {
      console.error(
        `Booking ${bookingId} has no shopId.`,
      );
      return;
    }

    const ownerId = await getOwnerId(shopId);

    const barberUserId = await getBarberUserId(
      stringValue(after.barberId),
    );

    // Rescheduled without a status change: Firestore rules keep
    // bookingDate/startTime/endTime immutable for customer/barber/owner
    // status updates today, so this is future-proofing for a dedicated
    // reschedule flow. Notify all relevant parties.
    if (
      beforeStatus === afterStatus &&
      bookingTimeChanged(before, after)
    ) {
      await dispatchNotifications(
        createRescheduledNotifications(
          bookingId,
          after,
          ownerId,
          barberUserId,
        ),
      );

      console.log(
        `Created rescheduled notifications for booking ${bookingId}.`,
      );
      return;
    }

    if (beforeStatus === afterStatus) {
      return;
    }

    const notifications =
      createStatusChangeNotifications(
        bookingId,
        beforeStatus,
        afterStatus,
        after,
        ownerId,
        barberUserId,
      );

    if (notifications.length === 0) {
      console.log(
        `No notification mapping for ` +
        `${beforeStatus} → ${afterStatus} ` +
        `on booking ${bookingId}.`,
      );
      return;
    }

    await dispatchNotifications(notifications);

    console.log(
      `Created ${notifications.length} notification(s) ` +
      `for ${beforeStatus} → ${afterStatus} ` +
      `on booking ${bookingId}.`,
    );
  },
);

/** Builds the reminder text shared by the customer and barber variants. */
function buildReminderBody(booking: BookingData, prefix: string): string {
  const serviceName = stringValue(booking.serviceName) || "your appointment";
  const startTime = stringValue(booking.startTime);
  const barberName = stringValue(booking.barberName);

  const parts = [`${prefix} for ${serviceName}`];

  if (startTime) {
    parts.push(`at ${startTime}`);
  }

  if (barberName) {
    parts.push(`with ${barberName}`);
  }

  return `${parts.join(" ")} starts in about an hour.`;
}

/**
 * Sends the "1 hour before the appointment" reminder.
 *
 * Runs approximately every 5 minutes in Africa/Cairo (the project's operating
 * timezone). The client stores `bookingDate` as the local midnight of the
 * appointment, so the appointment instant is `bookingDate + startTime` and no
 * timezone maths is required here.
 *
 * Only confirmed bookings are considered, reminders are sent once
 * (`reminderSent`), and `onBookingUpdated` re-arms the flag when the
 * appointment date/time changes.
 */
export const bookingReminders = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Africa/Cairo",
  },
  async () => {
    const now = new Date();

    // bookingDate ranges from "now - 24h" (latest start time) to "now + 2h"
    // (earliest start time still ahead of us).
    const windowStart = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const windowEnd = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    const snapshot = await db
      .collection("bookings")
      .where("status", "==", "confirmed")
      .where("bookingDate", ">=", Timestamp.fromDate(windowStart))
      .where("bookingDate", "<=", Timestamp.fromDate(windowEnd))
      .get();

    console.log(
      `Reminder scan: ${snapshot.size} confirmed booking(s) in window.`,
    );

    for (const document of snapshot.docs) {
      const booking = getBookingData(document.data());

      // Already reminded and not rescheduled since (see onBookingUpdated).
      if (booking.reminderSent === true) {
        continue;
      }

      const bookingDate = booking.bookingDate;

      if (
        !bookingDate ||
        typeof bookingDate !== "object" ||
        !("toDate" in bookingDate) ||
        typeof bookingDate.toDate !== "function"
      ) {
        continue;
      }

      const startMinutes = timeToMinutes(booking.startTime);

      if (startMinutes === null) {
        continue;
      }

      const bookingInstant = bookingDate.toDate() as Date;
      const appointmentMs =
        bookingInstant.getTime() + startMinutes * 60 * 1000;
      const minutesUntilAppointment =
        (appointmentMs - now.getTime()) / 60000;

      // Window is wider than the 5-minute cadence so every booking is caught
      // at least once; `reminderSent` guarantees it is only sent once.
      if (minutesUntilAppointment < 55 || minutesUntilAppointment > 65) {
        continue;
      }

      const barberUserId = await getBarberUserId(
        stringValue(booking.barberId),
      );

      // Reminder goes to the customer and the barber.
      const notifications: NotificationPayload[] = [
        {
          recipientId: stringValue(booking.customerId),
          type: "appointmentReminder",
          title: "Appointment reminder",
          body: buildReminderBody(booking, "Your appointment"),
          bookingId: document.id,
        },
        {
          recipientId: barberUserId,
          type: "appointmentReminder",
          title: "Appointment reminder",
          body: buildReminderBody(booking, "You have an appointment"),
          bookingId: document.id,
        },
      ];

      await dispatchNotifications(notifications);

      await document.ref.update({
        reminderSent: true,
        reminderSentAt: FieldValue.serverTimestamp(),
      });

      console.log(
        `Sent appointment reminder for booking ${document.id}.`,
      );
    }
  },
);