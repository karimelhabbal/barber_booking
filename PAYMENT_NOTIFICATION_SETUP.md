# Payment notification setup

The payment backend authenticates users with Firebase Auth. The notification
backend authenticates users with Supabase Auth. Their user IDs are independent;
`firebase_user_identity_map` is the explicit bridge to `public.profiles.id`.

1. Apply `supabase/migrations/202610090002_firebase_payment_notifications.sql`.
2. Store `SUPABASE_SERVICE_ROLE_KEY` as a Firebase Functions secret. Set the
   Firebase Functions parameter `SUPABASE_URL` to the Supabase project URL.
   The payment function also needs its existing `PAYMOB_SECRET_KEY`,
   `PAYMOB_PUBLIC_KEY`, `PAYMOB_HMAC_SECRET`, and `PAYMOB_INTEGRATION_ID`
   secrets.
3. Provision each identity link only after verifying that the Firebase user
   and Supabase profile belong to the same person. Run this as a trusted
   database administrator (never from the client):

   ```sql
   insert into public.firebase_user_identity_map (firebase_uid, profile_id)
   values ('<verified-firebase-uid>', '<supabase-profile-uuid>')
   on conflict (firebase_uid) do update
     set profile_id = excluded.profile_id;
   ```

   The mapping table has no client or service-role table grants; only its
   security-definer notification RPC can read it.
4. Set each Firebase user's `users/{uid}.languageCode` to `ar` or `en`. The
   app writes this field when the user loads or changes the language setting.
   Missing or unsupported values use English.
5. The existing Supabase `dispatch-notifications` function must have
   `SUPABASE_SERVICE_ROLE_KEY` and `FCM_SERVICE_ACCOUNT_JSON` configured and
   its existing schedule enabled. It sends the stored localized title/body to
   FCM; it does not generate a second notification.

Only a Paymob HMAC-verified callback that matches the pending Firestore payment
can enqueue `paymentSuccess`. The RPC resolves the recipient from the trusted
mapping, and its unique idempotency key deduplicates callback retries. Provider
declines/voids remain failed payments. There is no client-driven expiration.
