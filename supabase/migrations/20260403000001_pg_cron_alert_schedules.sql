-- Enable pg_cron extension (requires superuser, available on Supabase Pro+)
-- On free tier, use an external cron (GitHub Actions, cron-job.org) instead.
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule: check price alerts every 15 minutes
-- Calls the check-alerts Edge Function via pg_net (HTTP from Postgres)
SELECT cron.schedule(
  'check-alerts-every-15min',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-alerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- Schedule: record price snapshots every hour (for trend analysis)
SELECT cron.schedule(
  'record-prices-hourly',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/record-prices',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- View scheduled jobs
-- SELECT * FROM cron.job;

-- To unschedule:
-- SELECT cron.unschedule('check-alerts-every-15min');
-- SELECT cron.unschedule('record-prices-hourly');
