const test = require('node:test');
const assert = require('node:assert/strict');
const {createHmac} = require('node:crypto');
const {
  isVerifiedPaidTransition,
  isTrustedPendingCallback,
  paymentNotificationPayload,
  providerPaymentStatus,
  verifyPaymobHmac,
} = require('../lib/payment/payment_notification_contract.js');

const validCallback = {
  hmacVerified: true,
  amountMatches: true,
  currencyMatches: true,
  orderMatches: true,
  merchantReferenceMatches: true,
  integrationMatches: true,
  notPending: true,
  providerSuccess: true,
  status: 'pending',
};

test('only a fully validated provider callback can transition pending payment to paid', () => {
  assert.equal(isVerifiedPaidTransition(validCallback), true);
  for (const field of Object.keys(validCallback)) {
    const rejected = {...validCallback, [field]: field === 'status' ? 'paid' : false};
    assert.equal(isVerifiedPaidTransition(rejected), false, `rejects invalid ${field}`);
  }
  const verifiedDecline = {...validCallback, providerSuccess: false};
  assert.equal(isTrustedPendingCallback(verifiedDecline), true);
  assert.equal(isVerifiedPaidTransition(verifiedDecline), false);
});

test('Paymob callback HMAC rejects tampering and malformed callback data', () => {
  const transaction = {
    amount_cents: 12345, created_at: '2026-10-09T12:00:00Z', currency: 'EGP',
    error_occured: false, has_parent_transaction: false, id: 99001,
    integration_id: 456, is_3d_secure: true, is_auth: false, is_capture: false,
    is_refunded: false, is_standalone_payment: true, is_voided: false,
    order: {id: 321}, owner: 1, pending: false,
    source_data: {pan: '0000', sub_type: 'card', type: 'card'}, success: true,
  };
  const fields = [
    'amount_cents', 'created_at', 'currency', 'error_occured',
    'has_parent_transaction', 'id', 'integration_id', 'is_3d_secure',
    'is_auth', 'is_capture', 'is_refunded', 'is_standalone_payment',
    'is_voided', 'order.id', 'owner', 'pending', 'source_data.pan',
    'source_data.sub_type', 'source_data.type', 'success',
  ];
  const valueAt = (path) => path.split('.').reduce((value, key) => value?.[key], transaction);
  const digest = createHmac('sha512', 'test-secret')
    .update(fields.map((field) => String(valueAt(field))).join(''))
    .digest('hex');
  assert.equal(verifyPaymobHmac(transaction, digest, 'test-secret'), true);
  assert.equal(verifyPaymobHmac({...transaction, amount_cents: 1}, digest, 'test-secret'), false);
  assert.equal(verifyPaymobHmac({...transaction, source_data: undefined}, digest, 'test-secret'), false);
  assert.equal(verifyPaymobHmac(transaction, 'not-a-hmac', 'test-secret'), false);
});

test('trusted provider voids cancel; declines fail; client-side expiration is not a transition', () => {
  assert.equal(providerPaymentStatus({callbackTrusted: true, success: true, voided: false}), 'paid');
  assert.equal(providerPaymentStatus({callbackTrusted: true, success: false, voided: true}), 'cancelled');
  assert.equal(providerPaymentStatus({callbackTrusted: true, success: false, voided: false}), 'failed');
  assert.equal(providerPaymentStatus({callbackTrusted: false, success: false, voided: true}), null);
});

test('localized notification content has stable per-payment idempotency', () => {
  const english = paymentNotificationPayload({
    languageCode: 'en', collectionName: 'bookingPayments', paymentId: 'p-1', amountPiasters: 12345,
  });
  const arabic = paymentNotificationPayload({
    languageCode: 'ar', collectionName: 'bookingPayments', paymentId: 'p-1', amountPiasters: 12345,
  });
  assert.equal(english.title, 'Payment successful');
  assert.match(english.body, /EGP 123\.45/);
  assert.equal(arabic.title, 'تم الدفع بنجاح');
  assert.match(arabic.body, /123\.45/);
  assert.equal(english.idempotencyKey, arabic.idempotencyKey);
  assert.equal(english.idempotencyKey, 'paymob:bookingPayments:p-1:paid');
  assert.notEqual(
    english.idempotencyKey,
    paymentNotificationPayload({
      languageCode: 'en', collectionName: 'subscriptionPayments', paymentId: 'p-1', amountPiasters: 12345,
    }).idempotencyKey,
  );
});

test('identity bridge is server-only and outbox uniqueness is keyed by provider payment', async () => {
  const fs = require('node:fs');
  const migration = fs.readFileSync(
    require('node:path').join(__dirname, '../../supabase/migrations/202610090002_firebase_payment_notifications.sql'),
    'utf8',
  );
  assert.match(migration, /firebase_uid text primary key/i);
  assert.match(migration, /where firebase_uid = btrim\(p_firebase_uid\)/i);
  assert.match(migration, /on conflict \(idempotency_key\) do nothing/i);
  assert.match(migration, /grant execute on function public\.enqueue_firebase_payment_notification[\s\S]*?to service_role/i);
  assert.match(migration, /from public, anon, authenticated/i);
});
