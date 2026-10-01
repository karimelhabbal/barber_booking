import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";

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
};

type NotificationType =
  | "bookingCreated"
  | "bookingConfirmed"
  | "bookingRejected"
  | "bookingCancelled"
  | "bookingCompleted"
  | "bookingNoShow";

type NotificationPayload = {
  recipientId: string;
  type: NotificationType;
  title: string;
  body: string;
  bookingId: string;
};

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

function createBookingCreatedNotifications(
  bookingId: string,
  booking: BookingData,
  ownerId: string,
): NotificationPayload[] {
  const barberId = stringValue(booking.barberId);
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
      recipientId: barberId,
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
): NotificationPayload[] {
  const customerId = stringValue(booking.customerId);
  const barberId = stringValue(booking.barberId);
  const customerName =
    stringValue(booking.customerName) || "The customer";
  const serviceName =
    stringValue(booking.serviceName) || "the service";
  const startTime = stringValue(booking.startTime);

  if (
    beforeStatus === "pending" &&
    afterStatus === "confirmed"
  ) {
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
      {
        recipientId: ownerId,
        type: "bookingConfirmed",
        title: "Booking confirmed",
        body:
          `${customerName}'s booking for ${serviceName}` +
          `${startTime ? ` at ${startTime}` : ""} has been confirmed.`,
        bookingId,
      },
    ];
  }

  if (
    beforeStatus === "pending" &&
    afterStatus === "cancelled"
  ) {
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
        recipientId: ownerId,
        type: "bookingRejected",
        title: "Booking rejected",
        body:
          `${customerName}'s booking for ${serviceName}` +
          " was rejected.",
        bookingId,
      },
    ];
  }

  if (
    beforeStatus === "confirmed" &&
    afterStatus === "cancelled"
  ) {
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
      {
        recipientId: barberId,
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

console.log("BOOKING DATA:", JSON.stringify(snapshot.data()));
    const shopId = stringValue(booking.shopId);

    if (!shopId) {
      console.error(
        `Booking ${bookingId} has no shopId.`,
      );
      return;
    }

    const ownerId = await getOwnerId(shopId);

    const notifications =
      createBookingCreatedNotifications(
        bookingId,
        booking,
        ownerId,
      );

    await createNotifications(notifications);

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
console.log("BOOKING AFTER:", JSON.stringify(afterSnapshot.data()));
    const beforeStatus = stringValue(before.status);
    const afterStatus = stringValue(after.status);

    if (!beforeStatus || !afterStatus) {
      console.warn(
        `Booking ${bookingId} has an invalid status transition.`,
      );
      return;
    }

    if (beforeStatus === afterStatus) {
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

    const notifications =
      createStatusChangeNotifications(
        bookingId,
        beforeStatus,
        afterStatus,
        after,
        ownerId,
      );

    if (notifications.length === 0) {
      console.log(
        `No notification mapping for ` +
        `${beforeStatus} → ${afterStatus} ` +
        `on booking ${bookingId}.`,
      );
      return;
    }

    await createNotifications(notifications);

    console.log(
      `Created ${notifications.length} notification(s) ` +
      `for ${beforeStatus} → ${afterStatus} ` +
      `on booking ${bookingId}.`,
    );
  },
);