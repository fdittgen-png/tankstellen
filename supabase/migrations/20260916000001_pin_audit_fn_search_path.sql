-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: AGPL-3.0-or-later
--
-- #4251 — pin `search_path` on `audit_rls_policies()` from
-- `20260426000001_rls_audit_function.sql`.
--
-- Found by `get_advisors(security)` against the live project on
-- 2026-09-16 while establishing a baseline before fleet schema work:
--
--     Function Search Path Mutable (WARN)
--       public.audit_rls_policies has a role mutable search_path
--
-- Same change `20260818000001` made for the three owner-protection
-- functions, and the last unpinned function in this schema.
--
-- ── Severity: hardening, not a live exposure ──────────────────────
-- This one is SECURITY INVOKER (it runs as the caller, so it cannot
-- escalate) and is already REVOKE'd from both `anon` and
-- `authenticated` — only `service_role` can call it. The mechanism the
-- advisor warns about is real: with an unpinned search_path a caller
-- who can create relations earlier on the effective path could shadow
-- `pg_class` / `pg_policies` and make the audit report whatever they
-- like — which matters because `test/security/supabase_rls_test.dart`
-- trusts this function's output as its oracle. But reaching it requires
-- the service-role key, which bypasses RLS anyway. So: clear the
-- warning, remove the footgun if the grants ever loosen, and do not
-- pretend this was open to users.
--
-- ── Why `pg_catalog` is in the list ───────────────────────────────
-- The precedent pinned `= public` because those bodies reference only
-- `public.*` and `auth.uid()`. This body reads `pg_class`,
-- `pg_namespace` and `pg_policies` UNQUALIFIED, so pinning to `public`
-- alone would break the function outright. `public, pg_catalog` keeps
-- every existing reference resolving exactly as it does today.
--
-- The body below is byte-identical to the original — ONLY the
-- `SET search_path` clause is new.
--
-- RLS impact:
--   [x] No public-table RLS change (hardens a helper function only).
--
-- RLS confirmed: [x]
--   `docs/security/SUPABASE_RLS_MATRIX.md` row for `audit_rls_policies()`
--   updated to record the pin; no policy is added, dropped or altered.

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
SET search_path = public, pg_catalog
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

-- Grants are unchanged and re-asserted so a re-run is idempotent.
REVOKE ALL ON FUNCTION public.audit_rls_policies() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.audit_rls_policies() FROM anon;
REVOKE EXECUTE ON FUNCTION public.audit_rls_policies() FROM authenticated;
