-- Notification dispatcher scheduler (Supabase-native).
--
-- Replaces the former Firebase Scheduled Function
-- (`dispatchSupabaseNotifications`, onSchedule "every 1 minutes") with a
-- pg_cron + pg_net job that invokes the Supabase Edge Function
-- `dispatch-notifications` every minute.
--
-- The scheduled HTTP call is authenticated with a shared bearer secret that is
-- generated server-side and stored in Supabase Vault. The secret never appears
-- in source control, migrations, CLI history, or logs:
--   * pg_net reads it from `vault.decrypted_secrets` to build the request.
--   * the Edge Function reads the same value via the service_role-only RPC
--     `public.get_dispatch_secret()`.
--
-- This migration only adds scheduling infrastructure. It does not modify the
-- existing notification tables/RLS/triggers/RPCs.

create extension if not exists pg_net;

-- Ensure pg_cron is present (idempotent; already enabled on this project).
create extension if not exists pg_cron;

-- Shared secret for authenticating the scheduled invocation. Generated with
-- cryptographically secure randomness and stored encrypted in Vault. Created
-- only once so re-applying the migration never rotates it underneath a running
-- schedule.
do $$
begin
  if not exists (
    select 1 from vault.secrets where name = 'dispatch_notifications_secret'
  ) then
    perform vault.create_secret(
      encode(gen_random_bytes(32), 'hex'),
      'dispatch_notifications_secret',
      'Shared bearer secret authorizing the dispatch-notifications Edge Function scheduled invocation.'
    );
  end if;
end;
$$;

-- Exposes the dispatch secret to service_role only (used by the Edge Function
-- to verify the caller). Denied to anon/authenticated and the public role.
create or replace function public.get_dispatch_secret()
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_secret text;
begin
  select decrypted_secret
    into v_secret
    from vault.decrypted_secrets
   where name = 'dispatch_notifications_secret';

  return v_secret;
end;
$$;

revoke all on function public.get_dispatch_secret() from public;
revoke all on function public.get_dispatch_secret() from anon;
revoke all on function public.get_dispatch_secret() from authenticated;
grant execute on function public.get_dispatch_secret() to service_role;

-- (Re)create the every-minute schedule. pg_net's http_post is asynchronous, so
-- the cron tick returns immediately while the Edge Function runs in the
-- background. Reading the secret from Vault keeps it out of the job definition.
do $$
declare
  v_job_name text := 'dispatch-notifications';
  v_url text := 'https://fdvnqqjekkhtxobvcbqx.supabase.co/functions/v1/dispatch-notifications';
begin
  if exists (select 1 from cron.job where jobname = v_job_name) then
    perform cron.unschedule(v_job_name);
  end if;

  perform cron.schedule(
    v_job_name,
    '* * * * *',
    format(
      $cron$
        select
          net.http_post(
            url := %L,
            headers := jsonb_build_object(
              'Content-Type', 'application/json',
              'Authorization', 'Bearer ' || (
                select decrypted_secret
                  from vault.decrypted_secrets
                 where name = 'dispatch_notifications_secret'
              )
            ),
            body := '{}'::jsonb,
            timeout_milliseconds := 5000
          ) as request_id;
      $cron$,
      v_url
    )
  );
end;
$$;
