-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #3747 (item 1) — pin `search_path` on the three owner-protection
-- functions from `20260401000001_owner_protection.sql`.
--
-- All three previously ran with the caller's/session `search_path`
-- unpinned. For the two SECURITY DEFINER functions that is the classic
-- Postgres privilege-escalation vector: a caller who can create objects
-- in a schema earlier on the effective search_path could shadow
-- `public.database_owner` (or an operator) and have the function —
-- running as its owner — resolve the malicious object instead.
-- `limit_bulk_delete()` is not SECURITY DEFINER but is pinned too so a
-- session-level `search_path` can never redirect its `set_config` /
-- `current_setting` bookkeeping.
--
-- The bodies below are byte-identical to the originals — ONLY the
-- `SET search_path = public` clause is new (every cross-schema
-- reference in the bodies is already schema-qualified: `public.*` and
-- `auth.uid()`).
--
-- First-signin-owner bootstrap semantics (unchanged, documented here
-- because these functions ARE that mechanism): the wizard/migration
-- creates `public.database_owner` empty. The FIRST user row inserted
-- into `public.users` after that (i.e. the first account to sign in —
-- on a self-host, the person who just ran the setup SQL) fires
-- `trg_auto_register_owner`, which registers that user as the one and
-- only database owner (the singleton unique index blocks any second
-- row). Every later signer-in is a plain user; only the owner (or
-- service_role) passes `is_database_owner()` in the delete policies.

-- 1. Ownership probe used by the users/price_reports delete policies.
CREATE OR REPLACE FUNCTION public.is_database_owner()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.database_owner WHERE user_id = auth.uid()
  );
$$;

-- 2. First-signin bootstrap trigger function (see semantics above).
CREATE OR REPLACE FUNCTION public.auto_register_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only register if no owner exists yet
  IF NOT EXISTS (SELECT 1 FROM public.database_owner) THEN
    INSERT INTO public.database_owner (user_id) VALUES (NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

-- 3. Per-statement bulk-delete rate limiter (not SECURITY DEFINER —
-- pinned as hygiene, see header).
CREATE OR REPLACE FUNCTION public.limit_bulk_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
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
