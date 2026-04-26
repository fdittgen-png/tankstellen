-- #1110 — RLS audit helper for `test/security/supabase_rls_test.dart`.
--
-- Why: Supabase RLS is the only thing that prevents one anon-key
-- holder from reading another user's rows. Without a programmatic
-- way to inventory live policies we have no automated guard against
-- a future migration that accidentally drops one. This function is
-- the read-only entry point the verification test calls; it returns
-- one row per policy on every `public.*` table plus a row with NULL
-- policy columns for tables that have RLS enabled but zero policies
-- (the silent-fail case where a table is read-locked).
--
-- Security:
--   - SECURITY INVOKER: the function runs with the caller's
--     privileges. The test calls it with the service-role key, which
--     can read `pg_policies` and `pg_class`. Anon callers get an
--     empty result because they lack `SELECT` on those catalogs —
--     which is the correct posture; we don't want to leak policy
--     structure to anon clients.
--   - REVOKE EXECUTE FROM anon, authenticated: belt-and-braces.
--
-- RLS impact:
--   [x] No public-table RLS change (adds a helper function only).
--
-- RLS confirmed: [x]
--   This migration adds verification machinery; the matrix in
--   docs/security/SUPABASE_RLS_MATRIX.md is unchanged.

CREATE OR REPLACE FUNCTION public.audit_rls_policies()
RETURNS TABLE (
  table_name TEXT,
  rls_enabled BOOLEAN,
  policy_name TEXT,
  policy_cmd TEXT,
  policy_roles TEXT[]
)
LANGUAGE sql
SECURITY INVOKER
STABLE
AS $$
  SELECT
    c.relname::TEXT AS table_name,
    c.relrowsecurity AS rls_enabled,
    p.policyname::TEXT AS policy_name,
    p.cmd::TEXT AS policy_cmd,
    p.roles::TEXT[] AS policy_roles
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN pg_policies p
    ON p.schemaname = n.nspname
   AND p.tablename = c.relname
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'  -- ordinary tables only (skip views, sequences)
  ORDER BY c.relname, p.policyname NULLS FIRST;
$$;

REVOKE EXECUTE ON FUNCTION public.audit_rls_policies() FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_rls_policies() TO service_role;

COMMENT ON FUNCTION public.audit_rls_policies() IS
  'Read-only RLS policy inventory for verification tests (#1110). '
  'Service-role only. Returns one row per (table, policy); tables '
  'with RLS-enabled-but-zero-policies surface as a single row with '
  'NULL policy_name. See docs/security/SUPABASE_RLS_MATRIX.md.';
