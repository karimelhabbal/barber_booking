create table if not exists public.notifications (
  id text primary key default gen_random_uuid()::text,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in (
    'bookingCreated',
    'bookingConfirmed',
    'bookingRejected',
    'bookingCancelled',
    'bookingCompleted',
    'bookingNoShow',
    'appointmentReminder',
    'scheduleChanged',
    'general'
  )),
  title text not null,
  body text not null,
  booking_id text references public.bookings(id) on delete set null,
  created_at timestamptz not null default now(),
  is_read boolean not null default false,
  idempotency_key text not null unique,
  push_status text not null default 'pending'
    check (push_status in ('pending', 'processing', 'sent', 'failed', 'skipped')),
  push_attempts integer not null default 0 check (push_attempts >= 0),
  push_next_attempt_at timestamptz not null default now(),
  push_claimed_at timestamptz,
  push_pending_tokens text[] not null default '{}',
  push_error text
);

alter table public.notifications
  add column if not exists push_pending_tokens text[] not null default '{}';

create index if not exists notifications_recipient_created_idx
  on public.notifications(recipient_id, created_at desc);
create index if not exists notifications_push_queue_idx
  on public.notifications(push_next_attempt_at, created_at)
  where push_status in ('pending', 'processing');
create index if not exists bookings_confirmed_reminder_idx
  on public.bookings(booking_date, start_time)
  where status = 'confirmed';

alter table public.notifications enable row level security;
revoke all on public.notifications from public, anon, authenticated;
grant select, update(is_read) on public.notifications to authenticated;
grant all on public.notifications to service_role;
revoke all on public.notifications from anon;

drop policy if exists "notifications_read_own" on public.notifications;
create policy "notifications_read_own" on public.notifications
  for select to authenticated using (recipient_id = auth.uid());
drop policy if exists "notifications_mark_own_read" on public.notifications;
create policy "notifications_mark_own_read" on public.notifications
  for update to authenticated
  using (recipient_id = auth.uid() and is_read = false)
  with check (recipient_id = auth.uid() and is_read = true);

create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in (
    'android', 'ios', 'web', 'linux', 'macos', 'windows', 'fuchsia'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists device_tokens_user_idx on public.device_tokens(user_id);
alter table public.device_tokens enable row level security;
revoke all on public.device_tokens from public, anon, authenticated;
grant select, delete on public.device_tokens to authenticated;
grant all on public.device_tokens to service_role;

drop policy if exists "device_tokens_read_own" on public.device_tokens;
create policy "device_tokens_read_own" on public.device_tokens
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "device_tokens_insert_own" on public.device_tokens;
drop policy if exists "device_tokens_update_own" on public.device_tokens;
drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own" on public.device_tokens
  for delete to authenticated using (user_id = auth.uid());

create or replace function public.register_device_token(
  p_token text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;
  if nullif(btrim(p_token), '') is null then
    raise exception 'Device token cannot be empty.';
  end if;

  insert into public.device_tokens (token, user_id, platform)
  values (btrim(p_token), auth.uid(), lower(btrim(p_platform)))
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;
revoke all on function public.register_device_token(text, text)
  from public, anon, authenticated;
grant execute on function public.register_device_token(text, text) to authenticated;

create or replace function public.touch_device_token_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists touch_device_token_updated_at on public.device_tokens;
create trigger touch_device_token_updated_at
  before update on public.device_tokens
  for each row execute function public.touch_device_token_updated_at();

create or replace function public.enqueue_notification(
  p_recipient_id uuid,
  p_type text,
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
begin
  if p_recipient_id is null or p_idempotency_key is null then
    return false;
  end if;

  insert into public.notifications (
    recipient_id, type, title, body, booking_id, idempotency_key
  )
  values (
    p_recipient_id, p_type, p_title, p_body, p_booking_id, p_idempotency_key
  )
  on conflict (idempotency_key) do nothing;
  return found;
end;
$$;
revoke all on function public.enqueue_notification(uuid, text, text, text, text, text)
  from public, anon, authenticated;

create or replace function public.create_booking_notifications()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid;
  v_barber_user_id uuid;
  v_customer_name text;
  v_service_name text;
  v_when text;
  v_idempotency text;
begin
  select s.owner_id, br.user_id
    into v_owner_id, v_barber_user_id
    from public.barber_shops s
    left join public.barbers br on br.id = new.barber_id
   where s.id = new.shop_id;

  v_customer_name := coalesce(nullif(new.customer_name, ''), 'A customer');
  v_service_name := coalesce(nullif(new.service_name, ''), 'a service');
  v_when := case
    when new.booking_date is null then ''
    else ' on ' || new.booking_date::text
  end || case
    when coalesce(new.start_time, '') = '' then ''
    else ' at ' || new.start_time
  end;

  if tg_op = 'INSERT' then
    v_idempotency := 'booking:' || new.id || ':bookingCreated:';
    perform public.enqueue_notification(
      v_barber_user_id,
      'bookingCreated',
      'New booking request',
      v_customer_name || ' requested ' || v_service_name || v_when || '.',
      new.id,
      v_idempotency || coalesce(v_barber_user_id::text, '')
    );
    perform public.enqueue_notification(
      v_owner_id,
      'bookingCreated',
      'New booking request',
      v_customer_name || ' requested ' || v_service_name || v_when || '.',
      new.id,
      v_idempotency || coalesce(v_owner_id::text, '')
    );
    return new;
  end if;

  if old.status = new.status
     and (old.booking_date is distinct from new.booking_date
       or old.start_time is distinct from new.start_time
       or old.end_time is distinct from new.end_time) then
    v_idempotency := 'booking:' || new.id || ':scheduleChanged:'
      || coalesce(old.booking_date::text, '') || ':' || coalesce(old.start_time, '')
      || ':' || coalesce(old.end_time, '') || ':to:'
      || coalesce(new.booking_date::text, '') || ':' || coalesce(new.start_time, '')
      || ':' || coalesce(new.end_time, '') || ':' || new.updated_at::text;

    perform public.enqueue_notification(
      new.customer_id,
      'scheduleChanged',
      'Booking rescheduled',
      'Your booking for ' || v_service_name || v_when || ' has been rescheduled.',
      new.id,
      v_idempotency || ':' || new.customer_id::text
    );
    perform public.enqueue_notification(
      v_barber_user_id,
      'scheduleChanged',
      'Booking rescheduled',
      v_customer_name || '''s booking for ' || v_service_name || v_when
        || ' has been rescheduled.',
      new.id,
      v_idempotency || ':' || coalesce(v_barber_user_id::text, '')
    );
    perform public.enqueue_notification(
      v_owner_id,
      'scheduleChanged',
      'Booking rescheduled',
      v_customer_name || '''s booking for ' || v_service_name || v_when
        || ' has been rescheduled.',
      new.id,
      v_idempotency || ':' || coalesce(v_owner_id::text, '')
    );
    return new;
  end if;

  if old.status = new.status then
    return new;
  end if;

  v_idempotency := 'booking:' || new.id || ':status:' || old.status || ':'
    || new.status || ':' || new.updated_at::text || ':';

  if old.status = 'pending' and new.status = 'confirmed' then
    perform public.enqueue_notification(
      new.customer_id,
      'bookingConfirmed',
      'Booking confirmed',
      'Your booking for ' || v_service_name
        || case when coalesce(new.start_time, '') = '' then ''
                else ' at ' || new.start_time end
        || ' has been confirmed.',
      new.id,
      v_idempotency || new.customer_id::text
    );
  elsif new.status = 'cancelled' then
    if new.cancelled_by = 'customer' then
      perform public.enqueue_notification(
        v_barber_user_id, 'bookingCancelled', 'Booking cancelled',
        v_customer_name || '''s booking for ' || v_service_name
          || ' has been cancelled.',
        new.id, v_idempotency || coalesce(v_barber_user_id::text, '')
      );
      perform public.enqueue_notification(
        v_owner_id, 'bookingCancelled', 'Booking cancelled',
        v_customer_name || '''s booking for ' || v_service_name
          || ' has been cancelled.',
        new.id, v_idempotency || coalesce(v_owner_id::text, '')
      );
    elsif new.cancelled_by in ('barber', 'owner') then
      perform public.enqueue_notification(
        new.customer_id,
        case when old.status = 'pending' then 'bookingRejected' else 'bookingCancelled' end,
        case when old.status = 'pending' then 'Booking rejected' else 'Booking cancelled' end,
        case when old.status = 'pending'
          then 'Your booking for ' || v_service_name || ' could not be confirmed.'
          else 'Your booking for ' || v_service_name || ' has been cancelled.'
        end,
        new.id, v_idempotency || new.customer_id::text
      );
    elsif old.status = 'pending' then
      perform public.enqueue_notification(
        new.customer_id, 'bookingRejected', 'Booking rejected',
        'Your booking for ' || v_service_name || ' could not be confirmed.',
        new.id, v_idempotency || new.customer_id::text
      );
      perform public.enqueue_notification(
        v_barber_user_id, 'bookingCancelled', 'Booking cancelled',
        v_customer_name || '''s booking for ' || v_service_name
          || ' has been cancelled.',
        new.id, v_idempotency || coalesce(v_barber_user_id::text, '')
      );
      perform public.enqueue_notification(
        v_owner_id, 'bookingCancelled', 'Booking cancelled',
        v_customer_name || '''s booking for ' || v_service_name
          || ' has been cancelled.',
        new.id, v_idempotency || coalesce(v_owner_id::text, '')
      );
    else
      perform public.enqueue_notification(
        new.customer_id, 'bookingCancelled', 'Booking cancelled',
        'Your confirmed booking for ' || v_service_name || ' has been cancelled.',
        new.id, v_idempotency || new.customer_id::text
      );
    end if;
  elsif old.status = 'confirmed' and new.status = 'completed' then
    perform public.enqueue_notification(
      v_owner_id, 'bookingCompleted', 'Booking completed',
      v_customer_name || '''s booking for ' || v_service_name || ' has been completed.',
      new.id, v_idempotency || coalesce(v_owner_id::text, '')
    );
  elsif old.status = 'confirmed' and new.status = 'noShow' then
    perform public.enqueue_notification(
      new.customer_id, 'bookingNoShow', 'Booking marked as no-show',
      'Your booking for ' || v_service_name || ' was marked as no-show.',
      new.id, v_idempotency || 'customer:' || new.customer_id::text
    );
    perform public.enqueue_notification(
      v_owner_id, 'bookingNoShow', 'Booking marked as no-show',
      v_customer_name || '''s booking for ' || v_service_name
        || ' was marked as no-show.',
      new.id, v_idempotency || 'owner:' || coalesce(v_owner_id::text, '')
    );
  end if;

  return new;
end;
$$;
revoke all on function public.create_booking_notifications() from public, anon, authenticated;

drop trigger if exists create_booking_notifications on public.bookings;
drop trigger if exists create_booking_notifications_after_insert on public.bookings;
drop trigger if exists create_booking_notifications_after_update on public.bookings;
create trigger create_booking_notifications
  after insert
  on public.bookings
  for each row execute function public.create_booking_notifications();
create trigger create_booking_notifications_after_update
  after update of status, cancelled_by, booking_date, start_time, end_time
  on public.bookings
  for each row execute function public.create_booking_notifications();

create or replace function public.claim_notification_pushes(p_limit integer default 100)
returns setof public.notifications
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.notifications
     set push_status = 'failed',
         push_claimed_at = null,
         push_error = 'Delivery claim expired after maximum attempts'
   where push_status = 'processing'
     and push_attempts >= 5
     and coalesce(push_claimed_at, '-infinity'::timestamptz)
       < now() - interval '5 minutes';

  return query
  with claimable as (
    select n.id
      from public.notifications n
     where n.push_attempts < 5
       and (
         (n.push_status = 'pending' and n.push_next_attempt_at <= now())
         or (n.push_status = 'processing'
             and coalesce(n.push_claimed_at, '-infinity'::timestamptz)
               < now() - interval '5 minutes')
       )
     order by n.created_at
     limit least(greatest(coalesce(p_limit, 100), 1), 500)
     for update skip locked
  )
  update public.notifications n
     set push_status = 'processing',
         push_attempts = n.push_attempts + 1,
         push_claimed_at = now(),
         push_error = null
    from claimable c
   where n.id = c.id
  returning n.*;
end;
$$;
revoke all on function public.claim_notification_pushes(integer) from public, anon, authenticated;
grant execute on function public.claim_notification_pushes(integer) to service_role;

create or replace function public.create_due_appointment_reminders()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_booking record;
  v_reminder_count integer := 0;
  v_appointment_at timestamptz;
  v_reminder_key text;
  v_service_name text;
  v_barber_name text;
begin
  for v_booking in
    select b.*, s.timezone, br.user_id as barber_user_id
      from public.bookings b
      join public.barber_shops s on s.id = b.shop_id
      join public.barbers br on br.id = b.barber_id
     where b.status = 'confirmed'
       and b.booking_date between
         (now() at time zone s.timezone)::date
         and ((now() at time zone s.timezone) + interval '1 hour')::date
  loop
    v_appointment_at := timezone(
      v_booking.timezone,
      v_booking.booking_date + v_booking.start_time::time
    );

    if v_appointment_at - interval '1 hour' < now() - interval '5 minutes'
       or v_appointment_at - interval '1 hour' > now() + interval '1 minute' then
      continue;
    end if;

    v_service_name := coalesce(nullif(v_booking.service_name, ''), 'your appointment');
    v_barber_name := coalesce(nullif(v_booking.barber_name, ''), '');
    v_reminder_key := 'booking:' || v_booking.id || ':appointmentReminder:'
      || v_booking.booking_date::text || ':' || v_booking.start_time;

    if public.enqueue_notification(
      v_booking.customer_id,
      'appointmentReminder',
      'Appointment reminder',
      'Your appointment for ' || v_service_name
        || case when coalesce(v_booking.start_time, '') = '' then ''
                else ' at ' || v_booking.start_time end
        || case when v_barber_name = '' then ''
                else ' with ' || v_barber_name end
        || ' starts in about an hour.',
      v_booking.id,
      v_reminder_key || ':' || v_booking.customer_id::text
    ) then
      v_reminder_count := v_reminder_count + 1;
    end if;
    if public.enqueue_notification(
      v_booking.barber_user_id,
      'appointmentReminder',
      'Appointment reminder',
      'You have an appointment for ' || v_service_name
        || case when coalesce(v_booking.start_time, '') = '' then ''
                else ' at ' || v_booking.start_time end
        || case when v_barber_name = '' then ''
                else ' with ' || v_barber_name end
        || ' starts in about an hour.',
      v_booking.id,
      v_reminder_key || ':' || coalesce(v_booking.barber_user_id::text, '')
    ) then
      v_reminder_count := v_reminder_count + 1;
    end if;
  end loop;

  return v_reminder_count;
end;
$$;
revoke all on function public.create_due_appointment_reminders() from public, anon, authenticated;
grant execute on function public.create_due_appointment_reminders() to service_role;
