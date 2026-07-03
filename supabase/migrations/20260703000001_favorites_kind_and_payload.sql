-- #3452 — EV favorites + favorite-station payloads (schema v5).
--
-- Two gaps closed:
--  1. EV favorites (OpenChargeMap `ocm-*` ids) never synced at all — only
--     fuel favorite ids reached the `favorites` table.
--  2. Only IDs synced: a favorite pulled on device B had no name/coords
--     until the station was visited there.
--
-- Shape decision: extend the ONE `favorites` table instead of adding a
-- sibling table. A sibling would need its own verifier entry, wizard
-- CREATE + RLS policy, deletion-tombstone `table_name`, and a second
-- registered pull — all for the same `(user_id, station_id, data)` shape.
--
--  * `kind`  — 'fuel' | 'ev'; the app additionally routes `ocm-*` ids to
--              the EV store regardless of this column (#3455 leak guard).
--  * `data`  — full station JSON (`Station.toJson` /
--              `ChargingStation.toJson`), carried as JSONB like the
--              vehicles / fill_ups / trip_summaries payload columns.
--
-- Existing RLS (`favorites_own`: FOR ALL USING user_id = auth.uid())
-- covers the new columns unchanged. Existing tombstones keep working —
-- the conflict key stays (user_id, station_id).
--
-- Mirrors the wizard SQL (lib/core/sync/schema_sql.dart: `tableSql` +
-- `upgradeSql`). Bumps the recorded schema version to 5 so a self-hoster
-- who has not re-applied the setup SQL is flagged as outdated. Every
-- statement is idempotent.

ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'fuel';
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS data JSONB;

-- Record the new schema version so the verifier can flag outdated self-hosts.
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '5', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
