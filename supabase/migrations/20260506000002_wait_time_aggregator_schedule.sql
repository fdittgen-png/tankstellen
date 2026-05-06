-- #1119 — pg_cron schedule for the wait-time aggregator.
--
-- Why: keep the wait_time_aggregates rolling-median rows fresh
-- without round-tripping through the client. Mirrors the existing
-- check-alerts and record-prices schedules in
-- 20260403000001_pg_cron_alert_schedules.sql.
--
-- RLS impact:
--   [x] No public-table RLS change (schedules only).
--
-- RLS confirmed: [x] No matrix change required.

-- Schedule: aggregate wait-time pings every 30 minutes.
-- Edge Function returns within seconds for typical traffic; the
-- 30-minute cadence keeps the "~6 min wait" hint usefully fresh
-- without hammering pg_net.
SELECT cron.schedule(
  'aggregate-wait-times-every-30min',
  '*/30 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/aggregate-wait-times',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- To unschedule:
-- SELECT cron.unschedule('aggregate-wait-times-every-30min');
