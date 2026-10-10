import { createHmac, timingSafeEqual } from "node:crypto";

const TRANSACTION_HMAC_FIELDS = [
  "amount_cents", "created_at", "currency", "error_occured",
  "has_parent_transaction", "id", "integration_id", "is_3d_secure",
  "is_auth", "is_capture", "is_refunded", "is_standalone_payment",
  "is_voided", "order_id", "owner", "pending", "source_data.pan",
  "source_data.sub_type", "source_data.type", "success",
] as const;

function nestedValue(value: Record<string, unknown>, path: string): unknown {
  return path.split(".").reduce<unknown>((current, key) => {
    if (!current || typeof current !== "object") return undefined;
    return (current as Record<string, unknown>)[key];
  }, value);
}

export function verifyPaymobHmac(
  transaction: Record<string, unknown>,
  providedHmac: string,
  secret: string,
): boolean {
  if (!providedHmac || !/^[a-f\d]{128}$/i.test(providedHmac)) return false;
  const order = transaction.order as Record<string, unknown> | undefined;
  const values = TRANSACTION_HMAC_FIELDS.map((field) => {
    const path = field === "id" ? "id" : field === "order_id" ? "order.id" : field;
    const value = nestedValue(transaction, path);
    if (value === undefined) return null;
    return value === null ? "" : String(value);
  });
  if (values.some((value) => value === null) || !order) return false;
  const expected = createHmac("sha512", secret).update(values.join(""), "utf8").digest();
  const supplied = Buffer.from(providedHmac, "hex");
  return expected.length === supplied.length && timingSafeEqual(expected, supplied);
}

export type PaymentNotificationPayload = {
  title: string;
  body: string;
  idempotencyKey: string;
};

export function paymentNotificationPayload(input: {
  languageCode: unknown;
  collectionName: "bookingPayments" | "subscriptionPayments";
  paymentId: string;
  amountPiasters: number;
}): PaymentNotificationPayload {
  const language = input.languageCode === "ar" ? "ar" : "en";
  const amount = (input.amountPiasters / 100).toFixed(2);
  return {
    title: language === "ar" ? "تم الدفع بنجاح" : "Payment successful",
    body: language === "ar"
      ? `تم استلام دفعتك بقيمة ${amount} ج.م بنجاح.`
      : `Your payment of EGP ${amount} was received successfully.`,
    idempotencyKey: `paymob:${input.collectionName}:${input.paymentId}:paid`,
  };
}

export function isTrustedPendingCallback(input: {
  hmacVerified: boolean;
  amountMatches: boolean;
  currencyMatches: boolean;
  orderMatches: boolean;
  merchantReferenceMatches: boolean;
  integrationMatches: boolean;
  notPending: boolean;
  status: string;
}): boolean {
  return input.hmacVerified && input.amountMatches && input.currencyMatches &&
    input.orderMatches && input.merchantReferenceMatches &&
    input.integrationMatches && input.notPending && input.status === "pending";
}

export function isVerifiedPaidTransition(input: Parameters<typeof isTrustedPendingCallback>[0] & {
  providerSuccess: boolean;
}): boolean {
  return input.providerSuccess && isTrustedPendingCallback(input);
}

export function providerPaymentStatus(input: {
  callbackTrusted: boolean;
  success: boolean;
  voided: boolean;
}): "paid" | "failed" | "cancelled" | null {
  if (!input.callbackTrusted) return null;
  if (input.success) return "paid";
  if (input.voided) return "cancelled";
  return "failed";
}
