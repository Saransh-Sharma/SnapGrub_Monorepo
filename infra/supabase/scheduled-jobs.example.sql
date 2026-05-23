-- Staging/prod schedule template for Supabase SQL editor or migration-managed ops.
-- Requires pg_cron, pg_net, and Vault secrets:
--   supabase_functions_url = https://<project-ref>.supabase.co/functions/v1
--   supabase_service_role_key = <service-role-key>

create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.unschedule('snapgrub-weekly-insights-generate')
where exists (select 1 from cron.job where jobname = 'snapgrub-weekly-insights-generate');

select cron.schedule(
  'snapgrub-weekly-insights-generate',
  '15 2 * * 1',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'supabase_functions_url') || '/weekly-insights-generate',
    headers := jsonb_build_object(
      'authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'supabase_service_role_key'),
      'content-type', 'application/json'
    ),
    body := jsonb_build_object('limit', 500)
  );
  $$
);

select cron.unschedule('snapgrub-media-retention-cleanup')
where exists (select 1 from cron.job where jobname = 'snapgrub-media-retention-cleanup');

select cron.schedule(
  'snapgrub-media-retention-cleanup',
  '45 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'supabase_functions_url') || '/media-retention-cleanup',
    headers := jsonb_build_object(
      'authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'supabase_service_role_key'),
      'content-type', 'application/json'
    ),
    body := jsonb_build_object('limit', 1000)
  );
  $$
);
