-- #2929 — TankSync schema version marker.
--
-- A single-row metadata table the app reads to detect when a self-hoster's
-- database is on an OUTDATED schema (they ran an older setup SQL and have
-- not re-applied the latest). The SchemaVerifier reads `schema_version`
-- and, when it is lower than the version the app build expects, surfaces a
-- clear "your TankSync schema is outdated — re-run the setup SQL" hint
-- instead of silent per-table sync failures.
--
-- The wizard SQL (lib/core/sync/schema_sql.dart) creates this table and
-- upserts the current version; this migration mirrors it so `supabase db
-- push` keeps a maintainer's project in sync. Bump the inserted value here
-- AND `kSupabaseSchemaVersion` in schema_sql.dart together whenever a
-- schema change must be re-applied by self-hosters. Every statement is
-- idempotent.

CREATE TABLE IF NOT EXISTS public.tanksync_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.tanksync_meta ENABLE ROW LEVEL SECURITY;

-- Read-only to everyone (carries no user data — only the schema version
-- the verifier probes). Writes happen via the SQL editor / service_role.
DROP POLICY IF EXISTS tanksync_meta_read ON public.tanksync_meta;
CREATE POLICY tanksync_meta_read ON public.tanksync_meta
  FOR SELECT USING (true);

INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '2', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
