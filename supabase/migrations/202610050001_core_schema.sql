create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check (role in ('owner', 'barber', 'customer')),
  name text,
  phone text,
  barber_shop_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.barber_shops (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  owner_id uuid not null references public.profiles(id),
  phone text,
  address text,
  description text,
  image_url text,
  timezone text not null default 'Africa/Cairo',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles drop constraint if exists profiles_barber_shop_fk;
do $$ begin
  if to_regclass('public.services') is not null then
    alter table public.services drop constraint if exists services_barber_shop_id_fkey;
  end if;
  if to_regclass('public.bookings') is not null then
    alter table public.bookings drop constraint if exists bookings_shop_id_fkey;
    alter table public.bookings drop constraint if exists bookings_service_id_fkey;
  end if;
end $$;
-- barber_shop_id is already text on the remote database.alter table public.barber_shops alter column id type text using id::text;
alter table public.profiles add constraint profiles_barber_shop_fk
  foreign key (barber_shop_id) references public.barber_shops(id) on delete set null;

create table if not exists public.services (
  id text primary key default gen_random_uuid()::text,
  barber_shop_id text not null references public.barber_shops(id) on delete cascade,
  name text not null,
  description text,
  duration_minutes integer not null check (duration_minutes > 0),
  price numeric(10,2) not null check (price >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.services drop constraint if exists services_barber_shop_id_fkey;
alter table public.services alter column id type text using id::text;
-- barber_shop_id is already text on the remote database.
alter table public.services add constraint services_barber_shop_id_fkey
  foreign key (barber_shop_id) references public.barber_shops(id) on delete cascade;

create table if not exists public.bookings (
  id text primary key default gen_random_uuid()::text,
  customer_id uuid not null references public.profiles(id),
  shop_id text not null references public.barber_shops(id),
  barber_id uuid not null references public.profiles(id),
  service_id text not null references public.services(id),
  booking_date date not null,
  start_time text not null,
  end_time text not null,
  status text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled','noShow')),
  cancelled_by text check (cancelled_by is null or cancelled_by in ('customer','barber','owner')),
  service_name text not null,
  service_duration_minutes integer not null,
  service_price numeric(10,2) not null,
  customer_name text not null,
  barber_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.bookings drop constraint if exists bookings_shop_id_fkey;
alter table public.bookings drop constraint if exists bookings_service_id_fkey;
do $$ begin
  if to_regclass('public.booking_locks') is not null then
    alter table public.booking_locks drop constraint if exists booking_locks_booking_id_fkey;
  end if;
end $$;
alter table public.bookings alter column id type text using id::text;
alter table public.bookings alter column shop_id type text using shop_id::text;
alter table public.bookings alter column service_id type text using service_id::text;
alter table public.bookings add constraint bookings_shop_id_fkey
  foreign key (shop_id) references public.barber_shops(id);
alter table public.bookings add constraint bookings_service_id_fkey
  foreign key (service_id) references public.services(id);

create index if not exists barber_shops_owner_idx on public.barber_shops(owner_id);
create index if not exists services_shop_idx on public.services(barber_shop_id);
create index if not exists bookings_customer_idx on public.bookings(customer_id, booking_date desc);
create index if not exists bookings_shop_idx on public.bookings(shop_id, booking_date);

alter table public.profiles enable row level security;
alter table public.barber_shops enable row level security;
alter table public.services enable row level security;
alter table public.bookings enable row level security;
create or replace function public.is_barber_shop_owner(p_shop_id text)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.barber_shops s where s.id = p_shop_id and s.owner_id = auth.uid()) $$;
create or replace function public.owns_any_barber_shop()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.barber_shops s where s.owner_id = auth.uid()) $$;
create or replace function public.is_active_barber_shop(p_shop_id text)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.barber_shops s where s.id = p_shop_id and s.is_active) $$;
revoke all on function public.is_barber_shop_owner(text) from public;
revoke all on function public.owns_any_barber_shop() from public;
revoke all on function public.is_active_barber_shop(text) from public;
grant execute on function public.is_barber_shop_owner(text) to authenticated;
grant execute on function public.owns_any_barber_shop() to authenticated;
grant execute on function public.is_active_barber_shop(text) to authenticated;

drop policy if exists "profiles_read_self_or_shop_owner" on public.profiles;
create policy "profiles_read_self_or_shop_owner" on public.profiles for select to authenticated
using (id = auth.uid()
  or (role = 'barber' and barber_shop_id is null and public.owns_any_barber_shop())
  or (role = 'barber' and barber_shop_id is not null and
      (public.is_active_barber_shop(barber_shop_id) or public.is_barber_shop_owner(barber_shop_id))));
drop policy if exists "profiles_insert_customer_self" on public.profiles;
create policy "profiles_insert_customer_self" on public.profiles for insert to authenticated
with check (id = auth.uid() and role = 'customer' and barber_shop_id is null);
drop policy if exists "profiles_update_self_safe" on public.profiles;
create policy "profiles_update_self_safe" on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid() and role = 'customer' and barber_shop_id is null);

drop policy if exists "shops_read_active_or_owner" on public.barber_shops;
create policy "shops_read_active_or_owner" on public.barber_shops for select to authenticated
using (is_active or public.is_barber_shop_owner(id) or exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'barber' and p.barber_shop_id = barber_shops.id
));
drop policy if exists "shops_owner_manage" on public.barber_shops;
create policy "shops_owner_manage" on public.barber_shops for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid() and exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner'
));

drop policy if exists "services_read_active_or_shop_staff" on public.services;
create policy "services_read_active_or_shop_staff" on public.services for select to authenticated
using (is_active or exists (select 1 from public.barber_shops s where s.id = barber_shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'barber' and p.barber_shop_id = services.barber_shop_id));
drop policy if exists "services_owner_manage" on public.services;
create policy "services_owner_manage" on public.services for all to authenticated
using (exists (select 1 from public.barber_shops s where s.id = barber_shop_id and s.owner_id = auth.uid()))
with check (exists (select 1 from public.barber_shops s where s.id = barber_shop_id and s.owner_id = auth.uid()));

drop policy if exists "bookings_customer_or_shop_staff_read" on public.bookings;
create policy "bookings_customer_or_shop_staff_read" on public.bookings for select to authenticated
using (customer_id = auth.uid() or exists (select 1 from public.barber_shops s where s.id = shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'barber' and p.barber_shop_id = shop_id));
drop policy if exists "bookings_customer_create" on public.bookings;
create policy "bookings_customer_create" on public.bookings for insert to authenticated
with check (customer_id = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'customer'));
drop policy if exists "bookings_customer_cancel_or_staff_update" on public.bookings;
create policy "bookings_customer_cancel_or_staff_update" on public.bookings for update to authenticated
using (customer_id = auth.uid() or exists (select 1 from public.barber_shops s where s.id = shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'barber' and p.barber_shop_id = shop_id))
with check (customer_id = auth.uid() or exists (select 1 from public.barber_shops s where s.id = shop_id and s.owner_id = auth.uid())
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'barber' and p.barber_shop_id = shop_id));

create or replace function public.assign_barber_profile_to_shop(p_profile_id uuid, p_shop_id text)
returns void language plpgsql security definer set search_path = public as $$
declare v_current_shop text;
begin
  select barber_shop_id into v_current_shop from public.profiles
    where id = p_profile_id and role = 'barber' for update;
  if not found then raise exception 'Barber profile does not exist.'; end if;
  if not public.is_barber_shop_owner(coalesce(p_shop_id, v_current_shop)) then raise exception 'Not authorized.'; end if;
  if p_shop_id is not null and v_current_shop is not null and v_current_shop <> p_shop_id then
    raise exception 'Barber is assigned to another shop.';
  end if;
  if p_shop_id is null and v_current_shop is null then return; end if;
  update public.profiles set barber_shop_id = p_shop_id, updated_at = now() where id = p_profile_id;
end;
$$;
revoke all on function public.assign_barber_profile_to_shop(uuid, text) from public;
grant execute on function public.assign_barber_profile_to_shop(uuid, text) to authenticated;

-- Preserve legacy Firestore semantics: bookingDate represented the shop-local
-- calendar day. Convert using the existing default shop timezone, not UTC date.
do $$ begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'bookings'
      and column_name = 'booking_date' and data_type <> 'date'
  ) then
    alter table public.bookings alter column booking_date type date
      using (booking_date at time zone 'Africa/Cairo')::date;
  end if;
end $$;

create table if not exists public.booking_locks (
  barber_id uuid not null references public.profiles(id) on delete cascade,
  booking_date date not null,
  start_time text not null,
  end_time text not null,
  booking_id text not null references public.bookings(id) on delete cascade,
  primary key (barber_id, booking_date, start_time)
);
alter table public.booking_locks drop constraint if exists booking_locks_booking_id_fkey;
alter table public.booking_locks alter column booking_id type text using booking_id::text;
alter table public.booking_locks add constraint booking_locks_booking_id_fkey
  foreign key (booking_id) references public.bookings(id) on delete cascade;
create index if not exists booking_locks_date_idx on public.booking_locks(barber_id, booking_date);
alter table public.booking_locks enable row level security;
drop policy if exists "authenticated_users_read_booking_slots" on public.booking_locks;
create policy "authenticated_users_read_booking_slots" on public.booking_locks
  for select to authenticated using (true);
drop policy if exists "customer_create_own_booking_locks" on public.booking_locks;
create policy "customer_create_own_booking_locks" on public.booking_locks
  for insert to authenticated with check (exists (
    select 1 from public.bookings b where b.id = booking_id and b.customer_id = auth.uid()
  ));
drop policy if exists "booking_participants_delete_locks" on public.booking_locks;
create policy "booking_participants_delete_locks" on public.booking_locks
  for delete to authenticated using (exists (
    select 1 from public.bookings b where b.id = booking_id and (
      b.customer_id = auth.uid() or b.barber_id = auth.uid() or exists (
        select 1 from public.barber_shops s where s.id = b.shop_id and s.owner_id = auth.uid()
      )
    )
  ));

drop function if exists public.create_booking_with_locks(uuid, uuid, uuid, date, text, text, text, integer, numeric, text, text);
create or replace function public.create_booking_with_locks(
  p_shop_id text,
  p_barber_id uuid,
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
language plpgsql security invoker set search_path = public as $$
declare
  v_service public.services%rowtype;
  v_booking public.bookings%rowtype;
  v_start integer;
  v_end integer;
  v_minute integer;
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
  if not exists (select 1 from public.profiles p where p.id = p_barber_id and p.role = 'barber' and p.barber_shop_id = p_shop_id) then
    raise exception 'Barber is not assigned to this shop.';
  end if;
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
    coalesce((select nullif(name, '') from public.profiles where id = p_barber_id), p_barber_name),
    now(), now()
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
  if p_cancelled_by = 'barber' and v_booking.barber_id <> auth.uid() then raise exception 'Not authorized.'; end if;
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
  if not (v_booking.barber_id = auth.uid() or exists (
    select 1 from public.barber_shops s where s.id = v_booking.shop_id and s.owner_id = auth.uid()
  )) then raise exception 'Not authorized.'; end if;
  if not ((v_booking.status = 'pending' and p_status = 'confirmed') or
          (v_booking.status = 'confirmed' and p_status in ('completed', 'noShow'))) then
    raise exception 'Booking status transition is not allowed.';
  end if;
  update public.bookings set status = p_status, updated_at = now() where id = p_booking_id;
end;
$$;
