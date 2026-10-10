-- Schedule exceptions move off Firestore (`barbers/{id}/scheduleExceptions`)
-- onto Supabase, mirroring how `weekly_schedule` already lives in app tables.
create table if not exists public.schedule_exceptions (
  barber_id text not null references public.barbers(id) on delete cascade,
  id text not null,
  date date not null,
  is_working boolean not null default false,
  start_time text not null default '09:00',
  end_time text not null default '17:00',
  breaks jsonb not null default '[]'::jsonb,
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (barber_id, id)
);

create index if not exists schedule_exceptions_barber_date_idx
  on public.schedule_exceptions(barber_id, date);

alter table public.schedule_exceptions
  drop constraint if exists schedule_exceptions_breaks_is_array;
alter table public.schedule_exceptions
  add constraint schedule_exceptions_breaks_is_array
  check (jsonb_typeof(breaks) = 'array');

grant select, insert, update, delete on public.schedule_exceptions to authenticated;
alter table public.schedule_exceptions enable row level security;

-- Read: the barber themselves, the owner of their shop, and any signed-in user
-- for barbers that are discoverable for booking. Customers need the override
-- day while picking a slot, i.e. before any booking row exists, so availability
-- read access is tied to barber discovery instead of booking participation.
drop policy if exists "schedule_exceptions_read_visible_barbers" on public.schedule_exceptions;
create policy "schedule_exceptions_read_visible_barbers" on public.schedule_exceptions
  for select to authenticated
  using (
    exists (
      select 1 from public.barbers b
      where b.id = schedule_exceptions.barber_id
        and b.user_id = auth.uid()
    )
    or public.is_barber_shop_owner(
      (select b.barber_shop_id from public.barbers b
        where b.id = schedule_exceptions.barber_id)
    )
    or exists (
      select 1 from public.barbers b
      where b.id = schedule_exceptions.barber_id
        and b.is_active
        and public.is_active_barber_shop(b.barber_shop_id)
    )
  );

-- Manage: only the barber whose schedule the exception belongs to.
drop policy if exists "schedule_exceptions_barber_manage" on public.schedule_exceptions;
create policy "schedule_exceptions_barber_manage" on public.schedule_exceptions
  for all to authenticated
  using (exists (
    select 1 from public.barbers b
    where b.id = schedule_exceptions.barber_id
      and b.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.barbers b
    where b.id = schedule_exceptions.barber_id
      and b.user_id = auth.uid()
  ));

-- Manage: only the owner of the barber's shop.
drop policy if exists "schedule_exceptions_owner_manage" on public.schedule_exceptions;
create policy "schedule_exceptions_owner_manage" on public.schedule_exceptions
  for all to authenticated
  using (public.is_barber_shop_owner(
    (select b.barber_shop_id from public.barbers b
      where b.id = schedule_exceptions.barber_id)
  ))
  with check (public.is_barber_shop_owner(
    (select b.barber_shop_id from public.barbers b
      where b.id = schedule_exceptions.barber_id)
  ));
