-- #3078 (Epic #3075) — deletion tombstones.
--
-- TankSync merges synced entities as `server ∪ local` then upserts. So when
-- device A deletes a favorite, device B's next sync re-adds it (the union
-- re-includes the still-local row) and the delete RESURRECTS. A tombstone is
-- the durable "this id was deliberately deleted" record: on a synced delete
-- the app inserts a `deletions` row, and before each union the merge filters
-- the server rows against the user's tombstones — so a deleted id never comes
-- back, no matter which device still holds a local copy.
--
-- Mirrors the wizard SQL (lib/core/sync/schema_sql.dart +
-- schema_sql_policies.dart). Bumps the recorded schema version to 3 so a
-- self-hoster who has not re-applied the setup SQL is flagged as outdated
-- (see SchemaVerifier.isSchemaOutdated). Every statement is idempotent.

CREATE TABLE IF NOT EXISTS public.deletions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  deleted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, table_name, record_id)
);

CREATE INDEX IF NOT EXISTS deletions_user_table_idx
  ON public.deletions(user_id, table_name);

ALTER TABLE public.deletions ENABLE ROW LEVEL SECURITY;

-- A user only ever sees / writes their own tombstones.
DROP POLICY IF EXISTS deletions_own ON public.deletions;
CREATE POLICY deletions_own ON public.deletions
  FOR ALL USING (user_id = auth.uid());

-- Record the new schema version so the verifier can flag outdated self-hosts.
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '3', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
