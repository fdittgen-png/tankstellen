-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #4399 (Epic #4211, ADR 0025 D1/D2/D3/D7) — the JOIN half of fleet
-- onboarding. #4212 shipped the administrator's path
-- (`fleet_create_organization`) and ADR 0025's D7 table has no invite
-- row, so `FleetJoinService.joinRpc = 'fleet_join'` has been calling a
-- function that does not exist: an employee cannot join at all.
-- Schema version 15 → 16.
--
-- ── What an invite IS ────────────────────────────────────────────────
-- One row in `fleet_invites`, bound to exactly one organisation, with an
-- explicit granted role, a hard expiry and a use budget (single-use by
-- default). The PLAINTEXT CODE IS NEVER STORED: the primary key is the
-- SHA-256 of the normalised code, so a database dump — or a self-host
-- operator browsing the table — yields nothing replayable. `sha256()`,
-- `convert_to()` and `encode()` are core since PostgreSQL 11; no
-- pgcrypto, no extension, nothing for a self-hoster to install.
--
-- The code itself is 20 uppercase hex characters (80 bits) taken from
-- `gen_random_uuid()`'s CSPRNG and grouped `XXXXX-XXXXX-XXXXX-XXXXX`.
-- Uppercase hex has no ambiguous glyph to mistype (no O/0, no I/1/l),
-- which matters for a code read aloud or off a printout. Normalisation
-- before hashing strips every non-alphanumeric character and uppercases,
-- so dashes, spaces and lower case are all the same code.
--
-- ── An invite code is NOT an oracle (the issue's hard property) ───────
-- Two rules, both structural rather than advisory:
--
--  1. **Order.** Every check that does not depend on the code runs
--     FIRST — no session (`not_authenticated`), an anonymous identity
--     (`identity_required`, D2), a backend whose operator never set
--     `fleet_enabled` (`fleet_disabled`, D3), and a caller who is
--     already in a fleet (`already_member`, D1). Each of those answers a
--     question about the CALLER, never about the code, so none of them
--     can be used to probe. In particular the operator switch is read
--     before the invite table is touched: on a non-fleet backend a code
--     is never even looked up.
--  2. **One token for every code outcome.** Unknown code, expired code,
--     spent code, a code whose organisation has since been deleted — all
--     four raise the SAME `invalid_code` with the SAME SQLSTATE, from a
--     SINGLE indexed probe with a single failure branch. There is no
--     `invite_expired`, no `invite_not_found`, no "this code belonged to
--     an org but is spent": a caller holding a guess learns only that
--     the guess did not work, never that the organisation exists, that
--     somebody else already used the code, or that anyone is a member.
--
-- The client's `_classify` already understands an `invite_not_found`
-- token; this function deliberately never raises it, because "not found"
-- as a distinct answer is precisely the oracle.
--
-- ── Writes stay RPC-only (ADR 0025 D7) ───────────────────────────────
-- `fleet_invites` has RLS enabled and NO policy, and the table
-- privileges Supabase hands `anon` / `authenticated` by default are
-- revoked outright: nothing but the SECURITY DEFINER functions below
-- ever reads or writes it. `fleet_join` therefore also stays the only
-- INSERT path onto `fleet_members` — the table has no client write
-- policy either.
--
-- ── Issuing a code ───────────────────────────────────────────────────
-- `fleet_create_invite` is manager/admin only and an invite may never
-- grant more than its issuer holds (a manager cannot mint an admin).
-- There is no UI for it in this slice; a manager runs, in the SQL
-- editor or over the REST API:
--
--   SELECT public.fleet_create_invite('<org uuid>'::uuid, 'employee', 14, 1);
--
-- The returned string is the only time the plaintext exists.
--
-- RLS impact:
--   [x] One new table, RLS enabled, deliberately POLICY-LESS and with
--       the default anon/authenticated table grants revoked.
--   [x] No change to any existing table's policies.
--
-- RLS confirmed: [ ] — the live behavioural matrix (an invite from org A
--   cannot join org B; a used/expired code is refused; an anonymous
--   identity is refused; a second attempt says `already_member`; `anon`
--   cannot execute the RPC) is run with the live-RPC skill against the
--   maintainer project and pasted into the PR. The static half CI holds
--   is `test/core/sync/fleet/fleet_invite_rls_contract_test.dart`.

-- ───────────────────────────────────────────────────────────────────
-- 1. The invite table
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fleet_invites (
  code_hash TEXT PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('employee', 'manager', 'admin')),
  max_uses INTEGER NOT NULL DEFAULT 1 CHECK (max_uses BETWEEN 1 AND 200),
  uses INTEGER NOT NULL DEFAULT 0 CHECK (uses >= 0),
  expires_at TIMESTAMPTZ NOT NULL,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (uses <= max_uses)
);
CREATE INDEX IF NOT EXISTS fleet_invites_org_idx
  ON public.fleet_invites(org_id);
CREATE INDEX IF NOT EXISTS fleet_invites_created_by_idx
  ON public.fleet_invites(created_by);
ALTER TABLE public.fleet_invites ENABLE ROW LEVEL SECURITY;
-- Deliberately policy-less: the definer functions below are the only
-- readers and the only writers. The REVOKE is not redundant with RLS —
-- Supabase's ALTER DEFAULT PRIVILEGES grants the full table ACL to anon
-- and authenticated on every new public table, and a privilege still
-- applies where a policy is missing.
REVOKE ALL ON TABLE public.fleet_invites FROM anon, authenticated;

-- ───────────────────────────────────────────────────────────────────
-- 2. Code normalisation + hash
-- ───────────────────────────────────────────────────────────────────
-- One definition, called by both the issuer and the redeemer, so the
-- two can never disagree about what "the same code" means. Pure: it
-- hashes whatever the caller passes and touches no table, so EXECUTE
-- for authenticated discloses nothing.
CREATE OR REPLACE FUNCTION public.fleet_invite_hash(p_code TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT encode(
    sha256(
      convert_to(
        upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Za-z]', '', 'g')),
        'UTF8')),
    'hex');
$$;
REVOKE ALL ON FUNCTION public.fleet_invite_hash(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_invite_hash(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_invite_hash(TEXT) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 3. Issuing an invite — manager / admin only
-- ───────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fleet_create_invite(
  p_org UUID,
  p_role TEXT DEFAULT 'employee',
  p_expires_in_days INTEGER DEFAULT 14,
  p_max_uses INTEGER DEFAULT 1
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_role TEXT := coalesce(nullif(trim(p_role), ''), 'employee');
  v_days INTEGER := coalesce(p_expires_in_days, 14);
  v_max_uses INTEGER := coalesce(p_max_uses, 1);
  v_raw TEXT;
  v_code TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  -- coalesce: a NULL role (not a member) must fail, and NULL NOT IN (…)
  -- is NULL, which an IF would silently treat as "allowed".
  v_caller_role := coalesce(public.fleet_role(p_org), '');
  IF v_caller_role NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF v_role NOT IN ('employee', 'manager', 'admin') THEN
    RAISE EXCEPTION 'unknown_role' USING ERRCODE = '22023';
  END IF;
  -- An invite may never grant more than its issuer holds.
  IF v_role = 'admin' AND v_caller_role <> 'admin' THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF v_days < 1 OR v_days > 90 THEN
    RAISE EXCEPTION 'invite_lifetime_out_of_range' USING ERRCODE = '22023';
  END IF;
  IF v_max_uses < 1 OR v_max_uses > 200 THEN
    RAISE EXCEPTION 'invite_uses_out_of_range' USING ERRCODE = '22023';
  END IF;
  -- 80 bits from gen_random_uuid()'s CSPRNG, in an alphabet with no
  -- ambiguous glyph. Only the hash is stored; this is the one moment
  -- the plaintext exists.
  v_raw := upper(replace(gen_random_uuid()::text, '-', ''));
  v_code := substr(v_raw, 1, 5) || '-' || substr(v_raw, 6, 5) || '-' ||
            substr(v_raw, 11, 5) || '-' || substr(v_raw, 16, 5);
  INSERT INTO public.fleet_invites
    (code_hash, org_id, role, max_uses, expires_at, created_by)
    VALUES (public.fleet_invite_hash(v_code), p_org, v_role, v_max_uses,
            now() + (v_days * INTERVAL '1 day'), auth.uid());
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (p_org, auth.uid(), 'invite_created', v_role);
  RETURN v_code;
END;
$$;
REVOKE ALL ON FUNCTION public.fleet_create_invite(UUID, TEXT, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_create_invite(UUID, TEXT, INTEGER, INTEGER) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_create_invite(UUID, TEXT, INTEGER, INTEGER) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 4. Redeeming an invite — the employee's one write path
-- ───────────────────────────────────────────────────────────────────
-- The parameter is `p_invite_code` because that is the key
-- `FleetJoinService.joinWithInviteCode` puts on the wire; PostgREST
-- resolves an RPC by its argument NAMES, so a `p_code` signature would
-- 404 as PGRST202 and the employee would be told their administrator
-- has not enabled fleet mode.
--
-- Returns a JSON object, which reaches the client as the `{org_id, role}`
-- map `FleetJoinService._decode` already accepts, so the granted role is
-- honoured instead of the `employee` fallback.
CREATE OR REPLACE FUNCTION public.fleet_join(p_invite_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_enabled TEXT;
  v_hash TEXT;
  v_org UUID;
  v_role TEXT;
BEGIN
  -- ── Everything that does NOT depend on the code, first ────────────
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  -- ADR 0025 D2: a fleet membership needs the e-mail identity.
  IF coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
    RAISE EXCEPTION 'identity_required' USING ERRCODE = '42501';
  END IF;
  -- ADR 0025 D3: the operator switch, read BEFORE the invite table is
  -- touched, so a code cannot be probed on a non-fleet backend.
  SELECT value INTO v_enabled FROM public.tanksync_meta WHERE key = 'fleet_enabled';
  IF v_enabled IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'fleet_disabled' USING ERRCODE = '42501';
  END IF;
  -- ADR 0025 D1: one organisation per user in v1. Answered from the
  -- caller's own membership, before any lookup, so an existing member
  -- cannot use this function to test codes.
  IF EXISTS (SELECT 1 FROM public.fleet_members WHERE user_id = v_uid) THEN
    RAISE EXCEPTION 'already_member' USING ERRCODE = '23505';
  END IF;

  -- ── One probe, one failure token ──────────────────────────────────
  -- Unknown, expired, spent, or an organisation that has since been
  -- deleted (the FK cascades the invite away) are indistinguishable:
  -- one indexed lookup, one branch, one `invalid_code`.
  v_hash := public.fleet_invite_hash(p_invite_code);
  SELECT i.org_id, i.role INTO v_org, v_role
    FROM public.fleet_invites i
   WHERE i.code_hash = v_hash
     AND i.expires_at > now()
     AND i.uses < i.max_uses
   FOR UPDATE;
  IF v_org IS NULL THEN
    RAISE EXCEPTION 'invalid_code' USING ERRCODE = 'P0002';
  END IF;

  -- The row is locked, so two devices redeeming a single-use code
  -- serialise: the loser re-evaluates `uses < max_uses`, fails it, and
  -- gets the same `invalid_code` as a stranger.
  UPDATE public.fleet_invites
     SET uses = uses + 1
   WHERE code_hash = v_hash;

  INSERT INTO public.fleet_members (org_id, user_id, role)
    VALUES (v_org, v_uid, v_role);
  -- ADR 0025 D5.4. The target is a hash PREFIX: enough to correlate two
  -- joins on one code, never enough to replay it.
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (v_org, v_uid, 'member_joined', left(v_hash, 12));

  RETURN jsonb_build_object('org_id', v_org::text, 'role', v_role);
END;
$$;
REVOKE ALL ON FUNCTION public.fleet_join(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_join(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_join(TEXT) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 5. Schema version
-- ───────────────────────────────────────────────────────────────────
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '16', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
