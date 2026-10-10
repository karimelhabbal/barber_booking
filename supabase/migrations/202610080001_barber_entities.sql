-- Keep barber entities separate from auth profiles.
create table if not exists public.barbers (
  id text primary key,
  user_id uuid not null references public.profiles(id),
  barber_shop_id text not null references public.barber_shops(id),
  name text not null,
  phone text,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists barbers_user_idx on public.barbers(user_id);
create index if not exists barbers_shop_idx on public.barbers(barber_shop_id);
grant select, insert, update, delete on public.barbers to authenticated;
alter table public.barbers enable row level security;
drop policy if exists "barbers_read_shop_staff" on public.barbers;
create policy "barbers_read_shop_staff" on public.barbers
  for select to authenticated using (
    is_active or user_id = auth.uid() or public.is_barber_shop_owner(barber_shop_id)
  );

alter table public.bookings drop constraint if exists bookings_barber_id_fkey;
alter table public.bookings alter column barber_id type text using barber_id::text;
alter table public.bookings add constraint bookings_barber_id_fkey
  foreign key (barber_id) references public.barbers(id);

alter table public.booking_locks drop constraint if exists booking_locks_barber_id_fkey;
alter table public.booking_locks alter column barber_id type text using barber_id::text;
alter table public.booking_locks add constraint booking_locks_barber_id_fkey
  foreign key (barber_id) references public.barbers(id) on delete cascade;

drop policy if exists "booking_participants_delete_locks" on public.booking_locks;
create policy "booking_participants_delete_locks" on public.booking_locks
  for delete to authenticated using (exists (
    select 1 from public.bookings b where b.id = booking_id and (
      b.customer_id = auth.uid() or exists (
        select 1 from public.barbers br where br.id = b.barber_id and br.user_id = auth.uid()
      ) or exists (select 1 from public.barber_shops s where s.id = b.shop_id and s.owner_id = auth.uid())
    )
  ));

drop function if exists public.create_booking_with_locks(text, uuid, text, date, text, text, text, integer, numeric, text, text);
drop function if exists public.create_booking_with_locks(uuid, uuid, uuid, date, text, text, text, integer, numeric, text, text);
create or replace function public.create_booking_with_locks(
  p_shop_id text,
  p_barber_id text,
  p_service_id text,
  p_booking_date date,
  p_start_time text,
  p_end_time text,
  p_service_name text,
  p_service_duration_minutes integer,
  p_service_price numeric,
  p_customer_name text,
  p_barber_name text
) returns setof public.bookings
language plpgsql security definer set search_path = public as $$
declare
  v_service public.services%rowtype;
  v_booking public.bookings%rowtype;
  v_start integer;
  v_end integer;
  v_minute integer;
  v_barber_user uuid;
  v_barber_display_name text;
  v_id text := gen_random_uuid()::text;
begin
  if auth.uid() is null then raise exception 'Authentication required.'; end if;
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'customer') then
    raise exception 'Only customers can create bookings.';
  end if;
  select * into v_service from public.services
    where id = p_service_id and barber_shop_id = p_shop_id and is_active;
  if not found then raise exception 'Service is unavailable.'; end if;
  if not exists (select 1 from public.barber_shops s where s.id = p_shop_id and s.is_active) then
    raise exception 'Barber shop is unavailable.';
  end if;
  select user_id, name into v_barber_user, v_barber_display_name
    from public.barbers where id = p_barber_id and barber_shop_id = p_shop_id and is_active;
  if not found then raise exception 'Barber is not assigned to this shop.'; end if;
  if p_start_time !~ '^(?:[01][0-9]|2[0-3]):[0-5][0-9]$'
     or p_end_time !~ '^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'Invalid booking time.';
  end if;
  v_start := split_part(p_start_time, ':', 1)::integer * 60 + split_part(p_start_time, ':', 2)::integer;
  v_end := split_part(p_end_time, ':', 1)::integer * 60 + split_part(p_end_time, ':', 2)::integer;
  if v_start % 5 <> 0 or v_end <= v_start or v_end - v_start <> v_service.duration_minutes then
    raise exception 'Booking duration does not match the selected service.';
  end if;
  insert into public.bookings (
    id, customer_id, shop_id, barber_id, service_id, booking_date, start_time, end_time,
    status, service_name, service_duration_minutes, service_price, customer_name,
    barber_name, created_at, updated_at
  ) values (
    v_id, auth.uid(), p_shop_id, p_barber_id, p_service_id, p_booking_date, p_start_time, p_end_time,
    'pending', v_service.name, v_service.duration_minutes, v_service.price,
    coalesce((select nullif(name, '') from public.profiles where id = auth.uid()), p_customer_name),
    coalesce(nullif(v_barber_display_name, ''), p_barber_name), now(), now()
  ) returning * into v_booking;
  begin
    for v_minute in v_start..(v_end - 5) by 5 loop
      insert into public.booking_locks(barber_id, booking_date, start_time, end_time, booking_id)
      values (
        p_barber_id, p_booking_date,
        lpad((v_minute / 60)::text, 2, '0') || ':' || lpad((v_minute % 60)::text, 2, '0'),
        lpad(((v_minute + 5) / 60)::text, 2, '0') || ':' || lpad(((v_minute + 5) % 60)::text, 2, '0'),
        v_id
      );
    end loop;
  exception when unique_violation then
    raise exception 'The selected time slot is no longer available.';
  end;
  return next v_booking;
end;
$$;

drop function if exists public.cancel_booking_and_release_locks(uuid, text);
create or replace function public.cancel_booking_and_release_locks(p_booking_id text, p_cancelled_by text)
returns void language plpgsql security invoker set search_path = public as $$
declare v_booking public.bookings%rowtype;
begin
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking does not exist.'; end if;
  if p_cancelled_by = 'customer' and v_booking.customer_id <> auth.uid() then raise exception 'Not authorized.'; end if;
  if p_cancelled_by = 'barber' and not exists (
    select 1 from public.barbers br where br.id = v_booking.barber_id and br.user_id = auth.uid()
  ) then raise exception 'Not authorized.'; end if;
  if p_cancelled_by = 'owner' and not exists (
    select 1 from public.barber_shops s where s.id = v_booking.shop_id and s.owner_id = auth.uid()
  ) then raise exception 'Not authorized.'; end if;
  if p_cancelled_by not in ('customer', 'barber', 'owner') then raise exception 'Invalid cancellation actor.'; end if;
  if v_booking.status <> 'cancelled' then
    update public.bookings set status = 'cancelled', cancelled_by = p_cancelled_by, updated_at = now() where id = p_booking_id;
    delete from public.booking_locks where booking_id = p_booking_id;
  end if;
end;
$$;

drop function if exists public.update_booking_status(uuid, text);
create or replace function public.update_booking_status(p_booking_id text, p_status text)
returns void language plpgsql security invoker set search_path = public as $$
declare v_booking public.bookings%rowtype;
begin
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking does not exist.'; end if;
  if not (exists (select 1 from public.barbers br where br.id = v_booking.barber_id and br.user_id = auth.uid())
    or exists (select 1 from public.barber_shops s where s.id = v_booking.shop_id and s.owner_id = auth.uid())) then
    raise exception 'Not authorized.';
  end if;
  if not ((v_booking.status = 'pending' and p_status = 'confirmed') or
          (v_booking.status = 'confirmed' and p_status in ('completed', 'noShow'))) then
    raise exception 'Booking status transition is not allowed.';
  end if;
  update public.bookings set status = p_status, updated_at = now() where id = p_booking_id;
end;
$$;

-- Complete the barber entity schema while keeping its business ID distinct from the auth profile ID.
alter table public.barbers
  add column if not exists weekly_schedule jsonb not null default '{}'::jsonb;

alter table public.barbers drop constraint if exists barbers_user_id_fkey;
alter table public.barbers add constraint barbers_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;
alter table public.barbers drop constraint if exists barbers_barber_shop_id_fkey;
alter table public.barbers add constraint barbers_barber_shop_id_fkey
  foreign key (barber_shop_id) references public.barber_shops(id) on delete cascade;

drop policy if exists "barbers_read_shop_staff" on public.barbers;
drop policy if exists "barbers_read_discovery_and_self" on public.barbers;
create policy "barbers_read_discovery_and_self" on public.barbers
  for select to authenticated using (
    user_id = auth.uid()
    or public.is_barber_shop_owner(barber_shop_id)
    or (is_active and public.is_active_barber_shop(barber_shop_id))
  );
drop policy if exists "barbers_owner_manage" on public.barbers;
create policy "barbers_owner_manage" on public.barbers
  for all to authenticated
  using (public.is_barber_shop_owner(barber_shop_id))
  with check (public.is_barber_shop_owner(barber_shop_id));
drop policy if exists "barbers_self_update" on public.barbers;
create policy "barbers_self_update" on public.barbers
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.protect_barber_self_update()
returns trigger language plpgsql set search_path = public as $$
begin
  if old.user_id = auth.uid() and not public.is_barber_shop_owner(old.barber_shop_id) then
    if new.id is distinct from old.id
       or new.user_id is distinct from old.user_id
       or new.barber_shop_id is distinct from old.barber_shop_id
       or new.is_active is distinct from old.is_active
       or new.created_at is distinct from old.created_at then
      raise exception 'Barbers may only update their own profile details and schedule.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists protect_barber_self_update on public.barbers;
create trigger protect_barber_self_update
  before update on public.barbers
  for each row execute function public.protect_barber_self_update();


drop policy if exists "barbers_owner_manage" on public.barbers;
create policy "barbers_owner_manage" on public.barbers
  for all to authenticated
  using (public.is_barber_shop_owner(barber_shop_id))
  with check (
    public.is_barber_shop_owner(barber_shop_id)
    and exists (select 1 from public.profiles p where p.id = user_id and p.role = 'barber')
  );

drop policy if exists "bookings_customer_or_shop_staff_read" on public.bookings;
create policy "bookings_customer_or_shop_staff_read" on public.bookings for select to authenticated
using (customer_id = auth.uid()
  or exists (select 1 from public.barber_shops s where s.id = shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.barbers br where br.user_id = auth.uid() and br.barber_shop_id = shop_id));

drop policy if exists "bookings_customer_cancel_or_staff_update" on public.bookings;
create policy "bookings_customer_cancel_or_staff_update" on public.bookings for update to authenticated
using (customer_id = auth.uid()
  or exists (select 1 from public.barber_shops s where s.id = shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.barbers br where br.user_id = auth.uid() and br.barber_shop_id = shop_id))
with check (customer_id = auth.uid()
  or exists (select 1 from public.barber_shops s where s.id = shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.barbers br where br.user_id = auth.uid() and br.barber_shop_id = shop_id));
