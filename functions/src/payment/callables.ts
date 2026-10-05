import { createHmac, timingSafeEqual } from "node:crypto";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const db = getFirestore();
const paymobSecretKey = defineSecret("PAYMOB_SECRET_KEY");
const paymobPublicKey = defineSecret("PAYMOB_PUBLIC_KEY");
const paymobHmacSecret = defineSecret("PAYMOB_HMAC_SECRET");
const paymobIntegrationId = defineSecret("PAYMOB_INTEGRATION_ID");
const paymobSecrets = [paymobSecretKey, paymobPublicKey, paymobHmacSecret, paymobIntegrationId];

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

  const existing = await db
    .collection("bookingPayments")
    .where("bookingId", "==", bookingId)
    .limit(10)
    .get();

  for (const existingDoc of existing.docs) {
    const existingData = existingDoc.data() as Record<string, unknown>;
    const existingStatus = readString(existingData.status);
    const existingOwnerId = readString(existingData.ownerId);

    if (existingOwnerId && existingOwnerId !== ownerId) {
      continue;
    }

    if (
      readString(existingData.method) === method &&
      existingStatus !== "cancelled" &&
      existingStatus !== "failed"
    ) {
      return {
        paymentId: existingDoc.id,
        checkoutUrl: method === "online" ? readString(existingData.checkoutUrl) || null : null,
      };
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

  const paymentRef = db.collection("bookingPayments").doc();
  const paymentId = paymentRef.id;
  let checkoutUrl: string | null = null;
  let providerOrderId: string | null = null;
  if (method === "online") {
    const account = loadPlatformPaymobAccount();
    const billingData = await getBillingData(
      uid,
      readString(booking.customerName),
      readString(request.data.billingEmail),
    );
    const intention = await createPaymobIntention({
      account,
      paymentId,
      amountPiasters: grossAmount,
      itemName: readString(service.name) || readString(booking.serviceName) || "Barber service",
      billingData,
    });
    checkoutUrl = intention.checkoutUrl;
    providerOrderId = intention.providerOrderId;
  }

  const payment = {
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
    ...(providerOrderId ? { providerOrderId } : {}),
    ...(checkoutUrl ? { checkoutUrl } : {}),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  await paymentRef.set(payment);

  if (method === "cash") {
    return {
      paymentId,
      checkoutUrl: null,
    };
  }

  return {
    paymentId,
    checkoutUrl,
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
    const role = await getRole(uid);
    if (role !== "owner") {
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
  const paymentRef = db.collection("subscriptionPayments").doc();
  const paymentId = paymentRef.id;
  const intention = await createPaymobIntention({
    account,
    paymentId,
    amountPiasters,
    itemName: readString(plan.name) || planId,
    billingData,
    returnParameter: "subscriptionId",
  });

  await paymentRef.set({
    id: paymentId,
    ownerId: uid,
    planId,
    status: "pending",
    provider: "paymob",
    amountPiasters,
    currency: "EGP",
    providerOrderId: intention.providerOrderId,
    checkoutUrl: intention.checkoutUrl,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    paymentId,
    checkoutUrl: intention.checkoutUrl,
  };
});

const TRANSACTION_HMAC_FIELDS = [
  "amount_cents",
  "created_at",
  "currency",
  "error_occured",
  "has_parent_transaction",
  "id",
  "integration_id",
  "is_3d_secure",
  "is_auth",
  "is_capture",
  "is_refunded",
  "is_standalone_payment",
  "is_voided",
  "order_id",
  "owner",
  "pending",
  "source_data.pan",
  "source_data.sub_type",
  "source_data.type",
  "success",
] as const;

function getNestedValue(value: Record<string, unknown>, path: string): unknown {
  return path.split(".").reduce<unknown>((current, key) => {
    if (!current || typeof current !== "object") return undefined;
    return (current as Record<string, unknown>)[key];
  }, value);
}

function verifyPaymobHmac(
  transaction: Record<string, unknown>,
  providedHmac: string,
  secret: string,
): boolean {
  if (!providedHmac || !/^[a-f\d]{128}$/i.test(providedHmac)) return false;
  const order = transaction.order as Record<string, unknown> | undefined;
  const values = TRANSACTION_HMAC_FIELDS.map((field) => {
    const path = field === "id" ? "id" : field === "order_id" ? "order.id" : field;
    const value = getNestedValue(transaction, path);
    if (value === undefined) return null;
    return value === null ? "" : String(value);
  });
  if (values.some((value) => value === null) || !order) return false;

  const expected = createHmac("sha512", secret)
    .update(values.join(""), "utf8")
    .digest();
  const supplied = Buffer.from(providedHmac, "hex");
  return expected.length === supplied.length && timingSafeEqual(expected, supplied);
}

async function finalizeProviderPayment(
  collectionName: "bookingPayments" | "subscriptionPayments",
  paymentId: string,
  transaction: Record<string, unknown>,
): Promise<void> {
  const paymentRef = db.collection(collectionName).doc(paymentId);
  await db.runTransaction(async (firestoreTransaction) => {
    const paymentSnap = await firestoreTransaction.get(paymentRef);
    if (!paymentSnap.exists) return;
    const payment = paymentSnap.data() as Record<string, unknown>;
    if (readString(payment.status) !== "pending") return;

    const expectedAmount = collectionName === "bookingPayments"
      ? readNumber(payment.grossAmount)
      : readNumber(payment.amountPiasters);
    const callbackAmount = readNumber(transaction.amount_cents);
    const callbackCurrency = readString(transaction.currency);
    const order = transaction.order as Record<string, unknown>;
    if (
      callbackAmount !== expectedAmount ||
      callbackCurrency !== readString(payment.currency) ||
      readIdentifier(order.id) !== readString(payment.providerOrderId) ||
      readBoolean(transaction.pending)
    ) {
      return;
    }

    const succeeded = readBoolean(transaction.success);
    if (collectionName === "subscriptionPayments" && succeeded) {
      const ownerId = readString(payment.ownerId);
      const planId = readString(payment.planId);
      const planRef = db.collection("subscriptionPlans").doc(planId);
      const subscriptionRef = db.collection("ownerSubscriptions").doc(ownerId);
      const [planSnap, subscriptionSnap] = await Promise.all([
        firestoreTransaction.get(planRef),
        firestoreTransaction.get(subscriptionRef),
      ]);
      if (!planSnap.exists || !ownerId) return;

      const interval = readString(planSnap.data()?.interval);
      const now = new Date();
      const existingSubscription = subscriptionSnap.data() as Record<string, unknown> | undefined;
      const existingEnd = readDate(existingSubscription?.currentPeriodEnd);
      const periodStart = existingSubscription?.status === "active" && existingEnd && existingEnd > now
        ? existingEnd
        : now;
      const periodEnd = addSubscriptionInterval(periodStart, interval);
      if (!periodEnd) return;

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
      status: succeeded ? "paid" : "failed",
      providerTransactionId: readIdentifier(transaction.id),
      paidAt: succeeded ? FieldValue.serverTimestamp() : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

export const paymobWebhook = onRequest({ region: FUNCTIONS_REGION, secrets: paymobSecrets }, async (request, response) => {
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
  await finalizeProviderPayment(match.collection, match.doc.id, transaction);
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

  const payload: Record<string, unknown> = {
    ownerId: uid,
    type,
    accountHolderName: readString(request.data.accountHolderName),
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (type === "wallet") {
    payload.walletMsisdn = readString(request.data.walletMsisdn);
  } else {
    payload.iban = readString(request.data.iban);
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
