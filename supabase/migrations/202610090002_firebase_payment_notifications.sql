-- Firebase and Supabase Auth issue independent user IDs. This table is an
-- administrator-provisioned bridge; clients cannot create or alter mappings.
create table if not exists public.firebase_user_identity_map (
  firebase_uid text primary key check (length(btrim(firebase_uid)) between 1 and 128),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.firebase_user_identity_map enable row level security;
revoke all on public.firebase_user_identity_map from public, anon, authenticated, service_role;

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check check (type in (
  'bookingCreated', 'bookingConfirmed', 'bookingRejected', 'bookingCancelled',
  'bookingCompleted', 'bookingNoShow', 'appointmentReminder', 'scheduleChanged',
  'paymentSuccess', 'general'
));

-- Callable only by the Firebase Admin service role. Recipient resolution and
-- insert occur inside one trusted database function, with an idempotent key.
create or replace function public.enqueue_firebase_payment_notification(
  p_firebase_uid text,
  p_title text,
  p_body text,
  p_booking_id text,
  p_idempotency_key text
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipient uuid;
begin
  if nullif(btrim(p_firebase_uid), '') is null
     or nullif(btrim(p_title), '') is null
     or nullif(btrim(p_body), '') is null
     or nullif(btrim(p_idempotency_key), '') is null
     or length(p_title) > 120 or length(p_body) > 500 then
    raise exception 'Invalid payment notification.';
  end if;

  select profile_id into v_recipient
    from public.firebase_user_identity_map
   where firebase_uid = btrim(p_firebase_uid);
  if v_recipient is null then
    raise exception 'Firebase user mapping is not provisioned.';
  end if;

  insert into public.notifications (
    recipient_id, type, title, body, booking_id, idempotency_key
  ) values (
    v_recipient, 'paymentSuccess', btrim(p_title), btrim(p_body),
    case when p_booking_id is not null and exists (
      select 1 from public.bookings where id = p_booking_id
    ) then p_booking_id else null end,
    p_idempotency_key
  ) on conflict (idempotency_key) do nothing;
  return found;
end;
$$;
revoke all on function public.enqueue_firebase_payment_notification(text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.enqueue_firebase_payment_notification(text, text, text, text, text)
  to service_role;
