-- ═══════════════════════════════════════════════════════════════════
-- Owner Protection & Delete Restrictions
-- ═══════════════════════════════════════════════════════════════════
-- This migration adds:
-- 1. A `database_owner` table that tracks who created this database
-- 2. Helper function to check ownership
-- 3. Restricts bulk deletion of shared data (price_snapshots, price_reports)
-- 4. Limits user self-deletion to own data only (already enforced by RLS)
-- 5. Prevents deletion of the `users` table rows by non-owners
--
-- The first user to sign in after this migration becomes the owner.
-- Only the owner (or service_role) can delete other users' data.
-- ═══════════════════════════════════════════════════════════════════

-- 1. Owner tracking table
CREATE TABLE IF NOT EXISTS public.database_owner (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Only one row allowed
  CONSTRAINT single_owner CHECK (id IS NOT NULL)
);

-- Ensure only one owner row can ever exist
CREATE UNIQUE INDEX IF NOT EXISTS idx_database_owner_singleton
  ON public.database_owner ((true));

ALTER TABLE public.database_owner ENABLE ROW LEVEL SECURITY;

-- Anyone can read the owner (to check if they are the owner)
DROP POLICY IF EXISTS owner_read ON public.database_owner;
CREATE POLICY owner_read ON public.database_owner FOR SELECT USING (true);

-- Only service_role can insert/update/delete the owner record
DROP POLICY IF EXISTS owner_manage ON public.database_owner;
CREATE POLICY owner_manage ON public.database_owner
  FOR ALL USING (auth.role() = 'service_role');

-- 2. Helper function: is the current user the database owner?
CREATE OR REPLACE FUNCTION public.is_database_owner()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.database_owner WHERE user_id = auth.uid()
  );
$$;

-- 3. Auto-register first user as owner (trigger on users table)
CREATE OR REPLACE FUNCTION public.auto_register_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only register if no owner exists yet
  IF NOT EXISTS (SELECT 1 FROM public.database_owner) THEN
    INSERT INTO public.database_owner (user_id) VALUES (NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_register_owner ON public.users;
CREATE TRIGGER trg_auto_register_owner
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_register_owner();

-- 4. Prevent non-owners from deleting other users' rows
-- The existing RLS on `users` allows `id = auth.uid()` for ALL operations.
-- We refine this: users can SELECT/INSERT/UPDATE their own row,
-- but DELETE is restricted to the database owner or service_role.
DROP POLICY IF EXISTS users_own ON public.users;

-- Users can read/insert/update their own row
CREATE POLICY users_own_select ON public.users FOR SELECT USING (id = auth.uid());
CREATE POLICY users_own_insert ON public.users FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY users_own_update ON public.users FOR UPDATE USING (id = auth.uid());

-- Only the database owner or service_role can delete user rows
CREATE POLICY users_delete_owner_only ON public.users
  FOR DELETE USING (
    id = auth.uid()  -- Users can always delete their own row
    OR public.is_database_owner()  -- Owner can delete any user
    OR auth.role() = 'service_role'
  );

-- 5. Tighten price_snapshots: no deletion via anon key at all
-- (Already insert-only for service_role, read-only for all)
-- Add explicit deny on DELETE for anon users
DROP POLICY IF EXISTS snapshots_delete ON public.price_snapshots;
CREATE POLICY snapshots_delete ON public.price_snapshots
  FOR DELETE USING (auth.role() = 'service_role');

-- 6. Protect price_reports from deletion by non-reporters
-- Reporters can delete their own reports; owner can delete any
DROP POLICY IF EXISTS reports_delete ON public.price_reports;
CREATE POLICY reports_delete ON public.price_reports
  FOR DELETE USING (
    reporter_id = auth.uid()
    OR public.is_database_owner()
    OR auth.role() = 'service_role'
  );

-- 7. Rate-limit bulk deletes: prevent deleting more than 100 rows at once
-- This is a safety net against accidental mass deletion via the API.
CREATE OR REPLACE FUNCTION public.limit_bulk_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  delete_count INTEGER;
BEGIN
  -- Skip for service_role (Edge Functions need bulk operations)
  IF current_setting('request.jwt.claims', true)::json->>'role' = 'service_role' THEN
    RETURN OLD;
  END IF;

  -- Count how many rows this user is about to delete in this table
  -- We use a session variable to track deletions per-statement
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
$$;

-- Apply bulk delete protection to tables with user data
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
