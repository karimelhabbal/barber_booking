import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { defineString } from "firebase-functions/params";
import { isTrustedPendingCallback, paymentNotificationPayload, providerPaymentStatus, verifyPaymobHmac } from "./payment_notification_contract.js";

const db = getFirestore();
const paymobSecretKey = defineSecret("PAYMOB_SECRET_KEY");
const paymobPublicKey = defineSecret("PAYMOB_PUBLIC_KEY");
const paymobHmacSecret = defineSecret("PAYMOB_HMAC_SECRET");
const paymobIntegrationId = defineSecret("PAYMOB_INTEGRATION_ID");
const supabaseServiceRoleKey = defineSecret("SUPABASE_SERVICE_ROLE_KEY");
const supabaseUrl = defineString("SUPABASE_URL");
const paymobSecrets = [paymobSecretKey, paymobPublicKey, paymobHmacSecret, paymobIntegrationId];
const paymentWebhookSecrets = [...paymobSecrets, supabaseServiceRoleKey];

const FUNCTIONS_REGION = "europe-west1";
const FUNCTIONS_RETURN_URL =
  "https://europe-west1-flash-392b3.cloudfunctions.net/paymentReturn";
const PAYMOB_INTENTION_URL = "https://accept.paymob.com/v1/intention/";
const PAYMOB_CHECKOUT_URL = "https://eg.checkout.paymob.com/";
const PAYMOB_WEBHOOK_URL =
  "https://europe-west1-flash-392b3.cloudfunctions.net/paymobWebhook";

type PaymobAccountConfig = {
  secretKey: string;
  publicKey: string;
  hmacSecret: string;
  integrationId: number;
};

async function resolveShopOwner(shopId: string): Promise<string> {
  const shopSnap = await db.collection("barberShops").doc(shopId).get();
  if (!shopSnap.exists) {
    throw new HttpsError("not-found", "shop_not_found");
  }

  const ownerId = readString(shopSnap.data()?.ownerId);
  if (!ownerId) {
    throw new HttpsError("failed-precondition", "shop_owner_missing");
  }

  return ownerId;
}

function loadPlatformPaymobAccount(): PaymobAccountConfig {
  const secretKey = paymobSecretKey.value().trim();
  const publicKey = paymobPublicKey.value().trim();
  const hmacSecret = paymobHmacSecret.value().trim();
  const integrationId = Number(paymobIntegrationId.value());
  if (!secretKey || !publicKey || !hmacSecret || !Number.isSafeInteger(integrationId) || integrationId <= 0) {
    throw new HttpsError("failed-precondition", "payment_not_configured");
  }
  return { secretKey, publicKey, hmacSecret, integrationId };
}

async function validateOnlineShopSettings(shopId: string): Promise<void> {
  const settingsSnap = await db.collection("shopPaymentSettings").doc(shopId).get();
  const settings = settingsSnap.data() as Record<string, unknown> | undefined;

  if (!settings || settings.enabled !== true || settings.provider !== "paymob") {
    throw new HttpsError("failed-precondition", "payment_not_configured");
  }

  const onlineEnabled = settings.onlineEnabled === true;
  if (!onlineEnabled) {
    throw new HttpsError("failed-precondition", "payment_not_configured");
  }

  loadPlatformPaymobAccount();
}

type AuthContext = {
  uid: string;
};

type CallableRequest = {
  auth?: AuthContext | null;
  data: Record<string, unknown>;
};

function requireAuthenticated(request: CallableRequest): string {
  const uid = request.auth?.uid?.trim();
  if (!uid) {
    throw new HttpsError("unauthenticated", "sign_in_required");
  }

  return uid;
}

function readString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function readIdentifier(value: unknown): string {
  if (typeof value === "string") return value.trim();
  if (typeof value === "number" && Number.isSafeInteger(value)) return String(value);
  return "";
}

function readNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

function toPiasters(value: unknown): number {
  const raw = typeof value === "number" ? String(value) : readString(value);
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(raw);
  if (!match) return 0;
  return Number(match[1]) * 100 + Number((match[2] ?? "").padEnd(2, "0"));
}

function readDate(value: unknown): Date | null {
  if (value instanceof Date) return value;
  if (value && typeof value === "object" && "toDate" in value && typeof value.toDate === "function") {
    return (value.toDate as () => Date)();
  }
  return null;
}

function isStaleCheckoutReservation(data: Record<string, unknown>): boolean {
  const createdAt = readDate(data.createdAt);
  return createdAt !== null && Date.now() - createdAt.getTime() > 5 * 60_000;
}

function addSubscriptionInterval(start: Date, interval: string): Date | null {
  if (interval !== "monthly" && interval !== "yearly") return null;
  const year = start.getUTCFullYear() + (interval === "yearly" ? 1 : 0);
  const month = start.getUTCMonth() + (interval === "monthly" ? 1 : 0);
  const targetYear = year + Math.floor(month / 12);
  const targetMonth = month % 12;
  const lastDay = new Date(Date.UTC(targetYear, targetMonth + 1, 0)).getUTCDate();
  const day = Math.min(start.getUTCDate(), lastDay);
  return new Date(Date.UTC(
    targetYear,
    targetMonth,
    day,
    start.getUTCHours(),
    start.getUTCMinutes(),
    start.getUTCSeconds(),
    start.getUTCMilliseconds(),
  ));
}

function readBoolean(value: unknown): boolean {
  return value === true;
}

function isValidEgyptianIban(value: string): boolean {
  if (!/^EG\d{27}$/.test(value)) return false;
  const rearranged = `${value.slice(4)}${value.slice(0, 4)}`;
  let remainder = 0;
  for (const character of rearranged) {
    const digits = /[A-Z]/.test(character)
      ? String(character.charCodeAt(0) - 55)
      : character;
    for (const digit of digits) {
      remainder = (remainder * 10 + Number(digit)) % 97;
    }
  }
  return remainder === 1;
}

function getCheckoutUrl(publicKey: string, clientSecret: string): string {
  const url = new URL(PAYMOB_CHECKOUT_URL);
  url.searchParams.set("publicKey", publicKey);
  url.searchParams.set("clientSecret", clientSecret);
  return url.toString();
}

async function getBillingData(uid: string, fallbackName: string, suppliedEmail: string) {
  const [user, profileSnap] = await Promise.all([
    getAuth().getUser(uid),
    db.collection("users").doc(uid).get(),
  ]);
  const profile = profileSnap.data() as Record<string, unknown> | undefined;
  const fullName = readString(profile?.name) || readString(user.displayName) || fallbackName;
  const nameParts = fullName.split(/\s+/).filter(Boolean);
  const email = readString(suppliedEmail) || readString(user.email);
  const phoneNumber = readString(profile?.phone) || readString(user.phoneNumber);

  if (
    nameParts.length < 2 ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
    !phoneNumber
  ) {
    throw new HttpsError("failed-precondition", "billing_profile_incomplete");
  }

  return {
    first_name: nameParts[0].slice(0, 50),
    last_name: nameParts.slice(1).join(" ").slice(0, 50),
    email,
    phone_number: phoneNumber,
  };
}

async function createPaymobIntention(input: {
  account: PaymobAccountConfig;
  paymentId: string;
  amountPiasters: number;
  itemName: string;
  billingData: Record<string, string>;
  returnParameter?: "paymentId" | "subscriptionId";
}): Promise<{ checkoutUrl: string; providerOrderId: string }> {
  const response = await fetch(PAYMOB_INTENTION_URL, {
    method: "POST",
    headers: {
      Authorization: `Token ${input.account.secretKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: input.amountPiasters,
      currency: "EGP",
      payment_methods: [input.account.integrationId],
      items: [{ name: input.itemName.slice(0, 50), amount: input.amountPiasters, quantity: 1 }],
      billing_data: input.billingData,
      special_reference: input.paymentId,
      notification_url: PAYMOB_WEBHOOK_URL,
      redirection_url: `${FUNCTIONS_RETURN_URL}?${input.returnParameter ?? "paymentId"}=${encodeURIComponent(input.paymentId)}`,
    }),
  });

  const result = await response.json() as Record<string, unknown>;
  const clientSecret = readString(result.client_secret);
  const providerOrderId = readIdentifier(result.intention_order_id);
  if (!response.ok || !clientSecret || !providerOrderId) {
    console.error("Paymob intention creation failed", response.status);
    throw new HttpsError("unavailable", "checkout_creation_failed");
  }

  return {
    checkoutUrl: getCheckoutUrl(input.account.publicKey, clientSecret),
    providerOrderId,
  };
}

async function getRole(uid: string): Promise<string> {
  if (!uid) {
    return "";
  }

  const userSnap = await db.collection("users").doc(uid).get();
  return readString(userSnap.data()?.role);
}

function ensureNotCancelled(booking: Record<string, unknown>): void {
  if (readString(booking.status) === "cancelled") {
    throw new HttpsError("failed-precondition", "booking_cancelled");
  }
}

export const createBookingPayment = onCall({ region: FUNCTIONS_REGION, secrets: paymobSecrets }, async (request: CallableRequest) => {
  const uid = requireAuthenticated(request);

  const bookingId = readString(request.data.bookingId);
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "booking_id_required");
  }

  const method = readString(request.data.method);
  if (method !== "online" && method !== "cash") {
    throw new HttpsError("invalid-argument", "method_invalid");
  }

  const bookingSnap = await db.collection("bookings").doc(bookingId).get();
  if (!bookingSnap.exists) {
    throw new HttpsError("not-found", "booking_not_found");
  }

  const booking = (bookingSnap.data() ?? {}) as Record<string, unknown>;
  const customerId = readString(booking.customerId);
  const shopId = readString(booking.shopId);
  if (!customerId || !shopId) {
    throw new HttpsError("failed-precondition", "booking_missing_context");
  }

  if (customerId !== uid) {
    throw new HttpsError("permission-denied", "not_booking_customer");
  }
  if (await getRole(uid) !== "customer") {
    throw new HttpsError("permission-denied", "customer_only");
  }

  ensureNotCancelled(booking);

  const ownerId = await resolveShopOwner(shopId);
  if (method === "online") {
    await validateOnlineShopSettings(shopId);
  } else {
    const shopSettingsSnap = await db.collection("shopPaymentSettings").doc(shopId).get();
    const shopSettings = shopSettingsSnap.data() as Record<string, unknown> | undefined;
    if (shopSettings?.cashEnabled !== true) {
      throw new HttpsError("failed-precondition", "cash_payment_not_enabled");
    }
  }

  const serviceId = readString(booking.serviceId);
  if (!serviceId) {
    throw new HttpsError("failed-precondition", "booking_service_missing");
  }
  const serviceSnap = await db
    .collection("barberShops")
    .doc(shopId)
    .collection("services")
    .doc(serviceId)
    .get();
  if (!serviceSnap.exists) {
    throw new HttpsError("not-found", "booking_service_not_found");
  }

  const service = serviceSnap.data() as Record<string, unknown>;
  const grossAmount = toPiasters(service.price);
  if (!Number.isSafeInteger(grossAmount) || grossAmount <= 0) {
    throw new HttpsError("failed-precondition", "booking_amount_invalid");
  }

  const payments = db.collection("bookingPayments");
  const paymentRef = payments.doc();
  const paymentId = paymentRef.id;
  const reservation = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(
      payments.where("bookingId", "==", bookingId),
    );
    for (const document of existing.docs) {
      const data = document.data() as Record<string, unknown>;
      const status = readString(data.status);
      if (
        readString(data.ownerId) === ownerId &&
        !["cancelled", "failed", "expired"].includes(status)
      ) {
        if (
          method === "online" &&
          status === "pending" &&
          !readString(data.checkoutUrl) &&
          isStaleCheckoutReservation(data)
        ) {
          transaction.update(document.ref, {
            status: "failed",
            failureReason: "checkout_creation_timeout",
            updatedAt: FieldValue.serverTimestamp(),
          });
          continue;
        }
        return { ref: document.ref, data, created: false };
      }
    }

    transaction.create(paymentRef, {
      id: paymentId,
      bookingId,
      shopId,
      ownerId,
      customerId,
      method,
      status: method === "online" ? "pending" : "cash_pending",
      provider: method === "online" ? "paymob" : "cash",
      currency: "EGP",
      grossAmount,
      commissionAmount: 0,
      ownerNetAmount: grossAmount,
      refundedAmount: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { ref: paymentRef, data: null, created: true };
  });

  if (!reservation.created) {
    const data = reservation.data!;
    const checkoutUrl = readString(data.checkoutUrl) || null;
    if (
      method === "online" &&
      readString(data.status) === "pending" &&
      !checkoutUrl
    ) {
      throw new HttpsError("unavailable", "checkout_initializing");
    }
    return {
      paymentId: reservation.ref.id,
      checkoutUrl: method === "online" ? checkoutUrl : null,
    };
  }

  if (method === "cash") {
    return {
      paymentId,
      checkoutUrl: null,
    };
  }

  let intention: { checkoutUrl: string; providerOrderId: string };
  try {
    const account = loadPlatformPaymobAccount();
    const billingData = await getBillingData(
      uid,
      readString(booking.customerName),
      readString(request.data.billingEmail),
    );
    intention = await createPaymobIntention({
      account,
      paymentId,
      amountPiasters: grossAmount,
      itemName: readString(service.name) || readString(booking.serviceName) || "Barber service",
      billingData,
    });
  } catch (error) {
    await paymentRef.update({
      status: "failed",
      updatedAt: FieldValue.serverTimestamp(),
    });
    throw error;
  }

  await paymentRef.update({
    providerOrderId: intention.providerOrderId,
    checkoutUrl: intention.checkoutUrl,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {
    paymentId,
    checkoutUrl: intention.checkoutUrl,
  };
});

export const refreshPaymentStatus = onCall({ region: FUNCTIONS_REGION }, async (request: CallableRequest) => {
  const uid = requireAuthenticated(request);
  const paymentId = readString(request.data.paymentId);

  if (!paymentId) {
    throw new HttpsError("invalid-argument", "payment_id_required");
  }

  const paymentSnap = await db.collection("bookingPayments").doc(paymentId).get();
  if (!paymentSnap.exists) {
    throw new HttpsError("not-found", "payment_not_found");
  }

  const payment = paymentSnap.data() as Record<string, unknown>;
  const ownerId = readString(payment.ownerId);
  const customerId = readString(payment.customerId);

  if (uid !== ownerId && uid !== customerId) {
    const shopId = readString(payment.shopId);
    if (!shopId || await resolveShopOwner(shopId) !== uid) {
      throw new HttpsError("permission-denied", "not_payment_owner");
    }
  }

  return {
    ok: true,
    paymentId,
    status: readString(payment.status),
  };
});

export const createSubscriptionCheckout = onCall({ region: FUNCTIONS_REGION, secrets: paymobSecrets }, async (request: CallableRequest) => {
  const uid = requireAuthenticated(request);
  const planId = readString(request.data.planId);

  if (!planId) {
    throw new HttpsError("invalid-argument", "plan_id_required");
  }

  const role = await getRole(uid);
  if (role !== "owner") {
    throw new HttpsError("permission-denied", "owner_only");
  }

  const planSnap = await db.collection("subscriptionPlans").doc(planId).get();
  if (!planSnap.exists) {
    throw new HttpsError("not-found", "plan_not_found");
  }

  const plan = planSnap.data() as Record<string, unknown>;
  const amountPiasters = readNumber(plan.price);
  const interval = readString(plan.interval);
  if (plan.active !== true || (interval !== "monthly" && interval !== "yearly") || !Number.isSafeInteger(amountPiasters) || amountPiasters <= 0) {
    throw new HttpsError("failed-precondition", "subscription_amount_invalid");
  }

  const account = loadPlatformPaymobAccount();
  const billingData = await getBillingData(uid, "", readString(request.data.billingEmail));
  const payments = db.collection("subscriptionPayments");
  const paymentRef = payments.doc();
  const paymentId = paymentRef.id;
  const reservation = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(
      payments.where("ownerId", "==", uid),
    );
    for (const document of existing.docs) {
      const data = document.data() as Record<string, unknown>;
      if (
        readString(data.planId) === planId &&
        readString(data.status) === "pending"
      ) {
        if (
          !readString(data.checkoutUrl) &&
          isStaleCheckoutReservation(data)
        ) {
          transaction.update(document.ref, {
            status: "failed",
            failureReason: "checkout_creation_timeout",
            updatedAt: FieldValue.serverTimestamp(),
          });
          continue;
        }
        return { ref: document.ref, data, created: false };
      }
    }

    transaction.create(paymentRef, {
      id: paymentId,
      ownerId: uid,
      planId,
      status: "pending",
      provider: "paymob",
      amountPiasters,
      currency: "EGP",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { ref: paymentRef, data: null, created: true };
  });

  if (!reservation.created) {
    const checkoutUrl = readString(reservation.data?.checkoutUrl);
    if (!checkoutUrl) {
      throw new HttpsError("unavailable", "checkout_initializing");
    }
    return { paymentId: reservation.ref.id, checkoutUrl };
  }

  let intention: { checkoutUrl: string; providerOrderId: string };
  try {
    intention = await createPaymobIntention({
      account,
      paymentId,
      amountPiasters,
      itemName: readString(plan.name) || planId,
      billingData,
      returnParameter: "subscriptionId",
    });
  } catch (error) {
    await paymentRef.update({
      status: "failed",
      updatedAt: FieldValue.serverTimestamp(),
    });
    throw error;
  }

  await paymentRef.update({
    providerOrderId: intention.providerOrderId,
    checkoutUrl: intention.checkoutUrl,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    paymentId,
    checkoutUrl: intention.checkoutUrl,
  };
});

async function finalizeProviderPayment(
  collectionName: "bookingPayments" | "subscriptionPayments",
  paymentId: string,
  transaction: Record<string, unknown>,
): Promise<boolean> {
  const paymentRef = db.collection(collectionName).doc(paymentId);
  return db.runTransaction(async (firestoreTransaction) => {
    const paymentSnap = await firestoreTransaction.get(paymentRef);
    if (!paymentSnap.exists) return false;
    const payment = paymentSnap.data() as Record<string, unknown>;
    if (readString(payment.status) !== "pending") {
      // A valid provider retry after a committed callback is idempotently acked.
      return readIdentifier(payment.providerTransactionId) ===
        readIdentifier(transaction.id);
    }

    const expectedAmount = collectionName === "bookingPayments"
      ? readNumber(payment.grossAmount)
      : readNumber(payment.amountPiasters);
    const callbackAmount = readNumber(transaction.amount_cents);
    const callbackCurrency = readString(transaction.currency);
    const order = transaction.order as Record<string, unknown>;
    // Paymob returns special_reference as merchant_order_id on the transaction
    // callback (it is not nested in order).
    const merchantOrderId = readString(transaction.merchant_order_id);
    const integrationId = Number(paymobIntegrationId.value());
    if (!isTrustedPendingCallback({
      hmacVerified: true,
      amountMatches: callbackAmount === expectedAmount,
      currencyMatches: callbackCurrency === readString(payment.currency),
      orderMatches: readIdentifier(order.id) === readString(payment.providerOrderId),
      merchantReferenceMatches: merchantOrderId === paymentRef.id,
      integrationMatches: readIdentifier(transaction.integration_id) === String(integrationId),
      notPending: !readBoolean(transaction.pending),
      status: readString(payment.status),
    })) {
      return false;
    }

    const succeeded = readBoolean(transaction.success);
    const nextStatus = providerPaymentStatus({
      callbackTrusted: true,
      success: succeeded,
      voided: readBoolean(transaction.is_voided),
    });
    if (!nextStatus) return false;
    if (collectionName === "subscriptionPayments" && succeeded) {
      const ownerId = readString(payment.ownerId);
      const planId = readString(payment.planId);
      const planRef = db.collection("subscriptionPlans").doc(planId);
      const subscriptionRef = db.collection("ownerSubscriptions").doc(ownerId);
      const [planSnap, subscriptionSnap] = await Promise.all([
        firestoreTransaction.get(planRef),
        firestoreTransaction.get(subscriptionRef),
      ]);
      if (!planSnap.exists || !ownerId) return false;

      const interval = readString(planSnap.data()?.interval);
      const now = new Date();
      const existingSubscription = subscriptionSnap.data() as Record<string, unknown> | undefined;
      const existingEnd = readDate(existingSubscription?.currentPeriodEnd);
      const periodStart = existingSubscription?.status === "active" && existingEnd && existingEnd > now
        ? existingEnd
        : now;
      const periodEnd = addSubscriptionInterval(periodStart, interval);
      if (!periodEnd) return false;

      firestoreTransaction.set(subscriptionRef, {
        ownerId,
        planId,
        interval,
        status: "active",
        currentPeriodStart: periodStart,
        currentPeriodEnd: periodEnd,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    firestoreTransaction.update(paymentRef, {
      status: nextStatus,
      providerTransactionId: readIdentifier(transaction.id),
      paidAt: succeeded ? FieldValue.serverTimestamp() : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function enqueuePaymentNotification(
  firebaseUid: string,
  collectionName: "bookingPayments" | "subscriptionPayments",
  paymentId: string,
  payment: Record<string, unknown> | undefined,
): Promise<void> {
  const key = supabaseServiceRoleKey.value().trim();
  const baseUrl = supabaseUrl.value().trim().replace(/\/$/, "");
  if (!key || !/^https:\/\/[a-z\d-]+\.supabase\.co$/i.test(baseUrl)) {
    throw new Error("Supabase payment notification configuration is incomplete.");
  }

  const userSnap = await db.collection("users").doc(firebaseUid).get();
  const amountPiasters = collectionName === "bookingPayments"
    ? readNumber(payment?.grossAmount)
    : readNumber(payment?.amountPiasters);
  const localized = paymentNotificationPayload({
    languageCode: userSnap.data()?.languageCode,
    collectionName,
    paymentId,
    amountPiasters,
  });
  const result = await fetch(`${baseUrl}/rest/v1/rpc/enqueue_firebase_payment_notification`, {
    method: "POST",
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      p_firebase_uid: firebaseUid,
      p_title: localized.title,
      p_body: localized.body,
      p_booking_id: collectionName === "bookingPayments" ? readString(payment?.bookingId) || null : null,
      p_idempotency_key: localized.idempotencyKey,
    }),
  });
  if (!result.ok) {
    // Never include response text: provider or infrastructure errors can contain sensitive details.
    throw new Error(`Supabase payment notification RPC failed (${result.status}).`);
  }
}

export const paymobWebhook = onRequest({ region: FUNCTIONS_REGION, secrets: paymentWebhookSecrets }, async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method not allowed");
    return;
  }

  const body = request.body as Record<string, unknown> | undefined;
  const transaction = body?.obj as Record<string, unknown> | undefined;
  const order = transaction?.order as Record<string, unknown> | undefined;
  const providerOrderId = readIdentifier(order?.id);
  if (!transaction || !providerOrderId) {
    response.status(400).send("Invalid transaction callback");
    return;
  }

  const [bookingMatches, subscriptionMatches] = await Promise.all([
    db.collection("bookingPayments").where("providerOrderId", "==", providerOrderId).get(),
    db.collection("subscriptionPayments").where("providerOrderId", "==", providerOrderId).get(),
  ]);
  const candidates = [
    ...bookingMatches.docs.map((doc) => ({ collection: "bookingPayments" as const, doc })),
    ...subscriptionMatches.docs.map((doc) => ({ collection: "subscriptionPayments" as const, doc })),
  ];

  const providedHmac = readString(transaction.hmac) || readString(body?.hmac) || readString(request.query.hmac);
  const verified = [];
  for (const candidate of candidates) {
    const hmacSecret = paymobHmacSecret.value().trim();
    if (hmacSecret && verifyPaymobHmac(transaction, providedHmac, hmacSecret)) {
      verified.push(candidate);
    }
  }

  if (verified.length !== 1) {
    response.status(verified.length > 1 ? 409 : 401).send("Callback verification failed");
    return;
  }

  const match = verified[0];
  const finalized = await finalizeProviderPayment(match.collection, match.doc.id, transaction);
  if (!finalized) {
    response.status(409).send("Transaction does not match payment");
    return;
  }
  if (readBoolean(transaction.success)) {
    try {
      const paymentSnap = await match.doc.ref.get();
      const payment = paymentSnap.data() as Record<string, unknown> | undefined;
      if (
        readString(payment?.status) !== "paid" ||
        readIdentifier(payment?.providerTransactionId) !== readIdentifier(transaction.id)
      ) {
        response.status(409).send("Payment is not in a paid state");
        return;
      }
      const firebaseUid = match.collection === "bookingPayments"
        ? readString(payment?.customerId)
        : readString(payment?.ownerId);
      if (firebaseUid) {
        await enqueuePaymentNotification(firebaseUid, match.collection, match.doc.id, payment);
      }
    } catch (error) {
      console.error("Could not enqueue verified payment notification", error);
      response.status(503).send("Notification enqueue failed");
      return;
    }
  }
  response.status(200).send("OK");
});

export const setPayoutDestination = onCall({ region: FUNCTIONS_REGION }, async (request: CallableRequest) => {
  const uid = requireAuthenticated(request);
  const role = await getRole(uid);
  if (role !== "owner") {
    throw new HttpsError("permission-denied", "owner_only");
  }

  const type = readString(request.data.type);
  if (type !== "wallet" && type !== "iban") {
    throw new HttpsError("invalid-argument", "type_invalid");
  }

  const accountHolderName = readString(request.data.accountHolderName);
  if (!accountHolderName || accountHolderName.length > 100) {
    throw new HttpsError("invalid-argument", "account_holder_name_invalid");
  }

  const payload: Record<string, unknown> = {
    ownerId: uid,
    type,
    accountHolderName,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (type === "wallet") {
    const walletMsisdn = readString(request.data.walletMsisdn).replace(/[\s-]/g, "");
    if (!/^(?:01[0125]\d{8}|(?:\+?20)1[0125]\d{8})$/.test(walletMsisdn)) {
      throw new HttpsError(
        "invalid-argument",
        "wallet_number_must_be_egyptian_mobile",
      );
    }
    payload.walletMsisdn = walletMsisdn;
    payload.iban = FieldValue.delete();
  } else {
    const iban = readString(request.data.iban).replace(/\s/g, "").toUpperCase();
    if (!isValidEgyptianIban(iban)) {
      throw new HttpsError("invalid-argument", "iban_invalid");
    }
    payload.iban = iban;
    payload.walletMsisdn = FieldValue.delete();
  }

  await db.collection("payoutDestinations").doc(uid).set(payload, { merge: true });

  return { ok: true };
});

export const getShopPaymentOptions = onCall({ region: FUNCTIONS_REGION, secrets: paymobSecrets }, async (request: CallableRequest) => {
  requireAuthenticated(request);
  const shopId = readString(request.data.shopId);
  if (!shopId) throw new HttpsError("invalid-argument", "shop_id_required");
  const settingsSnap = await db.collection("shopPaymentSettings").doc(shopId).get();
  const settings = settingsSnap.data() as Record<string, unknown> | undefined;
  let onlineEnabled = false;
  if (settings?.enabled === true && settings.provider === "paymob" && settings.onlineEnabled === true) {
    try { loadPlatformPaymobAccount(); onlineEnabled = true; } catch { onlineEnabled = false; }
  }
  return { onlineEnabled, cashEnabled: settings?.cashEnabled === true };
});

export const confirmCashPayment = onCall({ region: FUNCTIONS_REGION }, async (request: CallableRequest) => {
  const uid = requireAuthenticated(request);
  if (await getRole(uid) !== "owner") throw new HttpsError("permission-denied", "owner_only");
  const paymentId = readString(request.data.paymentId);
  if (!paymentId) throw new HttpsError("invalid-argument", "payment_id_required");
  const paymentRef = db.collection("bookingPayments").doc(paymentId);
  await db.runTransaction(async (transaction) => {
    const paymentSnap = await transaction.get(paymentRef);
    if (!paymentSnap.exists) throw new HttpsError("not-found", "payment_not_found");
    const payment = paymentSnap.data() as Record<string, unknown>;
    if (readString(payment.method) !== "cash" || readString(payment.status) !== "cash_pending") return;
    const ownerId = readString(payment.ownerId);
    const shopId = readString(payment.shopId);
    if (uid !== ownerId) throw new HttpsError("permission-denied", "not_shop_owner");
    const shopSnap = await transaction.get(db.collection("barberShops").doc(shopId));
    if (!shopSnap.exists || readString(shopSnap.data()?.ownerId) !== uid) {
      throw new HttpsError("permission-denied", "not_shop_owner");
    }
    transaction.update(paymentRef, { status: "cash_collected", paidAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  });
  return { ok: true, paymentId };
});

export const paymentReturn = onRequest({ region: FUNCTIONS_REGION }, async (request, response) => {
  const paymentId = readString(request.query.paymentId);
  const subscriptionId = readString(request.query.subscriptionId);

  if (paymentId) {
    const paymentSnap = await db.collection("bookingPayments").doc(paymentId).get();
    if (paymentSnap.exists) {
      const existing = paymentSnap.data() as Record<string, unknown>;
      const status = readString(existing.status);
      if (status === "pending" || status === "cash_pending") {
        // Intentionally no provider-authoritative state change here.
        // The browser return-flow is a UX redirect only; payment success is
        // established only by provider-verified transaction processing.
      }
    }
  }

  if (subscriptionId) {
    const subscriptionSnap = await db.collection("subscriptionPayments").doc(subscriptionId).get();
    if (subscriptionSnap.exists) {
      const existing = subscriptionSnap.data() as Record<string, unknown>;
      const status = readString(existing.status);
      if (status === "pending") {
        // Intentionally no state mutation here. Provider verification remains authoritative.
      }
    }
  }

  response.status(200).send(`<!doctype html>
    <html>
      <head><meta charset="utf-8"><title>Payment return</title></head>
      <body style="font-family: sans-serif; text-align: center; padding: 48px;">
        <h2>Payment verification is still pending.</h2>
        <p>Please return to the app and wait for the server-verified payment status.</p>
      </body>
    </html>`);
});
