-- #3125 — multi-device sync forensics: stamp tombstones with the writing
-- install's device id + app version.
--
-- With cross-device identity shipped (#3079/#3080) the same account writes
-- from several phones, but a deletion row was exactly
-- {user_id, table_name, record_id, deleted_at} — "which of my two phones
-- deleted this vehicle, and was it the buggy build?" was unanswerable.
-- The app now writes `device_id` (a random per-install UUID — not a
-- hardware identifier) and `app_version` into every tombstone; entity rows
-- carry the same stamps inside their JSONB `data` blob (no schema change
-- needed there).
--
-- Mirrors the wizard SQL (lib/core/sync/schema_sql.dart `upgradeSql`).
-- Bumps the recorded schema version to 4 so a self-hoster who has not
-- re-applied the setup SQL is flagged as outdated (the app additionally
-- falls back to stamp-less tombstone writes against a pre-v4 schema, so
-- nothing breaks in the meantime). Every statement is idempotent.

ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS app_version TEXT;

-- Record the new schema version so the verifier can flag outdated self-hosts.
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '4', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
