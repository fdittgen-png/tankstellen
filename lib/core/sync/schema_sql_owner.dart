// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Owner-protection block of the TankSync wizard SQL (#3747, schema v8).
///
/// Mirrors `supabase/migrations/20260401000001_owner_protection.sql` +
/// `20260818000001_pin_owner_fn_search_path.sql`. The block never shipped
/// in the wizard before v8, so every self-host lacked the delete
/// restrictions the maintainer's project has had since #1110 — any
/// authenticated user could bulk-delete shared `price_reports` rows and
/// the `users_own FOR ALL` policy let a user delete their own row (and,
/// pre-split, nothing distinguished the operator). This block gives
/// self-hosts the same posture:
///
///  * `database_owner` — singleton table; the FIRST account to sign in
///    after the SQL runs (on a self-host: the operator, who signs in
///    right after pasting the wizard SQL) is auto-registered as owner by
///    `trg_auto_register_owner`; the partial unique index blocks any
///    second row, and only service_role may edit it.
///  * `is_database_owner()` / `auto_register_owner()` — SECURITY DEFINER
///    with `SET search_path = public` pinned (#3747: an unpinned
///    SECURITY DEFINER function is a privilege-escalation vector via
///    schema shadowing).
///  * users policy split — SELECT/INSERT/UPDATE stay own-row; DELETE is
///    own-row OR owner OR service_role. Emitted AFTER `rlsSql` (which
///    still creates the legacy `users_own FOR ALL` for ordering safety),
///    so the split policies are the final state on every run.
///  * delete lock-downs on the shared community tables
///    (`price_snapshots`, `price_reports`) + the 100-row bulk-delete
///    rate-limit triggers.
///
/// Everything is idempotent (IF NOT EXISTS / DROP … IF EXISTS /
/// CREATE OR REPLACE) so re-running the wizard repairs drift.
library;

/// See the library doc above. Appended by `buildMigrationSql` after
/// [rlsSql] and before [rpcSql].
const String ownerProtectionSql = '''
-- ── Owner protection (#3747, v8) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.database_owner (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT single_owner CHECK (id IS NOT NULL)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_database_owner_singleton
  ON public.database_owner ((true));
ALTER TABLE public.database_owner ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS owner_read ON public.database_owner;
CREATE POLICY owner_read ON public.database_owner FOR SELECT USING (true);
DROP POLICY IF EXISTS owner_manage ON public.database_owner;
CREATE POLICY owner_manage ON public.database_owner
  FOR ALL USING (auth.role() = 'service_role');

CREATE OR REPLACE FUNCTION public.is_database_owner()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS \$\$
  SELECT EXISTS (
    SELECT 1 FROM public.database_owner WHERE user_id = auth.uid()
  );
\$\$;

CREATE OR REPLACE FUNCTION public.auto_register_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.database_owner) THEN
    INSERT INTO public.database_owner (user_id) VALUES (NEW.id);
  END IF;
  RETURN NEW;
END;
\$\$;

DROP TRIGGER IF EXISTS trg_auto_register_owner ON public.users;
CREATE TRIGGER trg_auto_register_owner
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_register_owner();

-- users policy split: DELETE restricted to self / owner / service_role.
DROP POLICY IF EXISTS users_own ON public.users;
DROP POLICY IF EXISTS users_own_select ON public.users;
CREATE POLICY users_own_select ON public.users FOR SELECT USING (id = auth.uid());
DROP POLICY IF EXISTS users_own_insert ON public.users;
CREATE POLICY users_own_insert ON public.users FOR INSERT WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS users_own_update ON public.users;
CREATE POLICY users_own_update ON public.users FOR UPDATE USING (id = auth.uid());
DROP POLICY IF EXISTS users_delete_owner_only ON public.users;
CREATE POLICY users_delete_owner_only ON public.users
  FOR DELETE USING (
    id = auth.uid()
    OR public.is_database_owner()
    OR auth.role() = 'service_role'
  );

-- Shared community data: snapshots deletable by service_role only;
-- reports deletable by their reporter, the owner, or service_role.
DROP POLICY IF EXISTS snapshots_delete ON public.price_snapshots;
CREATE POLICY snapshots_delete ON public.price_snapshots
  FOR DELETE USING (auth.role() = 'service_role');
DROP POLICY IF EXISTS reports_delete ON public.price_reports;
CREATE POLICY reports_delete ON public.price_reports
  FOR DELETE USING (
    reporter_id = auth.uid()
    OR public.is_database_owner()
    OR auth.role() = 'service_role'
  );

-- 100-row bulk-delete rate limit on the user-data tables.
CREATE OR REPLACE FUNCTION public.limit_bulk_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS \$\$
DECLARE
  delete_count INTEGER;
BEGIN
  IF current_setting('request.jwt.claims', true)::json->>'role' = 'service_role' THEN
    RETURN OLD;
  END IF;
  BEGIN
    delete_count := current_setting('app.delete_count_' || TG_TABLE_NAME, true)::int + 1;
  EXCEPTION WHEN OTHERS THEN
    delete_count := 1;
  END;
  PERFORM set_config('app.delete_count_' || TG_TABLE_NAME, delete_count::text, true);
  IF delete_count > 100 THEN
    RAISE EXCEPTION 'Bulk delete limit exceeded (max 100 rows per operation). Contact the database owner.';
  END IF;
  RETURN OLD;
END;
\$\$;

DROP TRIGGER IF EXISTS trg_limit_delete_favorites ON public.favorites;
CREATE TRIGGER trg_limit_delete_favorites
  BEFORE DELETE ON public.favorites
  FOR EACH ROW EXECUTE FUNCTION public.limit_bulk_delete();
DROP TRIGGER IF EXISTS trg_limit_delete_alerts ON public.alerts;
CREATE TRIGGER trg_limit_delete_alerts
  BEFORE DELETE ON public.alerts
  FOR EACH ROW EXECUTE FUNCTION public.limit_bulk_delete();
DROP TRIGGER IF EXISTS trg_limit_delete_reports ON public.price_reports;
CREATE TRIGGER trg_limit_delete_reports
  BEFORE DELETE ON public.price_reports
  FOR EACH ROW EXECUTE FUNCTION public.limit_bulk_delete();
DROP TRIGGER IF EXISTS trg_limit_delete_itineraries ON public.itineraries;
CREATE TRIGGER trg_limit_delete_itineraries
  BEFORE DELETE ON public.itineraries
  FOR EACH ROW EXECUTE FUNCTION public.limit_bulk_delete();
''';
