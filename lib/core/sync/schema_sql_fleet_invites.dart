// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The invite table and the join RPCs of the TankSync wizard SQL
/// (#4399, ADR 0025 D1/D2/D3/D7, schema v16) — the wizard twin of
/// `supabase/migrations/20260920000001_fleet_invites.sql`.
///
/// `fleet_invites` is a **server-only** table like `fleet_audit_events`:
/// the sync code never `.from()`s it, RLS is enabled with no policy at
/// all, and the default `anon` / `authenticated` table grants are
/// revoked, so the SECURITY DEFINER functions here are its only reader
/// and its only writer. It is therefore emitted unconditionally rather
/// than registered as a [SyncedTableSpec] and probed by the verifier.
///
/// Two properties are load-bearing and are pinned by
/// `test/core/sync/fleet/fleet_invite_rls_contract_test.dart`:
///
///  * **the plaintext code is never stored** — the primary key is the
///    SHA-256 of the normalised code (`sha256` / `convert_to` /
///    `encode` are core since PostgreSQL 11, so a self-hoster installs
///    no extension), and `fleet_create_invite` returns the plaintext
///    exactly once;
///  * **a code is not an oracle** — every check that does not depend on
///    the code runs first (`not_authenticated`, `identity_required`,
///    `fleet_disabled`, `already_member`, all of which describe the
///    CALLER), and unknown / expired / spent / cascaded-away codes all
///    raise the one `invalid_code` from a single indexed probe. The
///    client understands an `invite_not_found` token; this SQL never
///    raises it, because "not found" as a distinct answer IS the
///    oracle.
///
/// Emission order is load-bearing (`schema_sql.dart`): the block goes
/// out after `fleetAuditTableSql` (the join writes an audit row), after
/// the fleet tables (`fleet_invites` has an FK onto
/// `fleet_organizations`) and after `fleetOracleSql` (the issuer calls
/// `fleet_role`).
library;

/// `fleet_invites` plus the one normalisation-and-hash definition both
/// RPCs share, so the issuer and the redeemer can never disagree about
/// what "the same code" means.
const String fleetInviteTableSql = '''
-- ── Fleet invites (#4399, v16, ADR 0025 D7) ────────────────────────
-- Server-only: RLS enabled and deliberately POLICY-LESS, with the
-- default anon/authenticated table grants revoked, so only the
-- SECURITY DEFINER functions below touch it. The plaintext code is
-- never stored — the key is its SHA-256.
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
-- Hygiene, not redundancy: Supabase grants table privileges to anon and
-- authenticated by default, and a privilege still applies where a
-- policy is missing.
REVOKE ALL ON TABLE public.fleet_invites FROM anon, authenticated;

-- One definition, called by both the issuer and the redeemer. Pure: it
-- hashes whatever the caller passes and touches no table, so EXECUTE
-- for authenticated discloses nothing.
CREATE OR REPLACE FUNCTION public.fleet_invite_hash(p_code TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS \$\$
  SELECT encode(
    sha256(
      convert_to(
        upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Za-z]', '', 'g')),
        'UTF8')),
    'hex');
\$\$;
REVOKE ALL ON FUNCTION public.fleet_invite_hash(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_invite_hash(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_invite_hash(TEXT) FROM anon;
''';

/// Issuing and redeeming — the two halves of the invite path
/// (#4399). Both re-check `auth.uid()`, the org and the caller's role
/// INSIDE the definer body, because SECURITY DEFINER bypasses RLS and
/// the policies are never consulted (#4049's third surface).
const String fleetInviteRpcSql = '''
-- ── Fleet invite RPCs (#4399, v16) ─────────────────────────────────

-- Issuing: manager / admin only, and an invite may never grant more
-- than its issuer holds. There is no UI in this slice; a manager runs
--   SELECT public.fleet_create_invite('<org uuid>'::uuid, 'employee', 14, 1);
-- and hands the returned string — the one moment the plaintext exists
-- — to the employee.
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
AS \$\$
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
  -- coalesce: NULL NOT IN (…) is NULL, which IF would treat as allowed.
  v_caller_role := coalesce(public.fleet_role(p_org), '');
  IF v_caller_role NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF v_role NOT IN ('employee', 'manager', 'admin') THEN
    RAISE EXCEPTION 'unknown_role' USING ERRCODE = '22023';
  END IF;
  IF v_role = 'admin' AND v_caller_role <> 'admin' THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF v_days < 1 OR v_days > 90 THEN
    RAISE EXCEPTION 'invite_lifetime_out_of_range' USING ERRCODE = '22023';
  END IF;
  IF v_max_uses < 1 OR v_max_uses > 200 THEN
    RAISE EXCEPTION 'invite_uses_out_of_range' USING ERRCODE = '22023';
  END IF;
  -- 80 bits from gen_random_uuid()'s CSPRNG, grouped in an alphabet
  -- with no ambiguous glyph. Only the hash is stored.
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
\$\$;
REVOKE ALL ON FUNCTION public.fleet_create_invite(UUID, TEXT, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_create_invite(UUID, TEXT, INTEGER, INTEGER) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_create_invite(UUID, TEXT, INTEGER, INTEGER) FROM anon;

-- Redeeming. The parameter is `p_invite_code` because that is the key
-- FleetJoinService puts on the wire; PostgREST resolves an RPC by its
-- argument NAMES, so a `p_code` signature would 404 as PGRST202 and the
-- employee would be told their administrator has not enabled fleets.
-- Returns the {org_id, role} object the client already decodes.
CREATE OR REPLACE FUNCTION public.fleet_join(p_invite_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  v_uid UUID := auth.uid();
  v_enabled TEXT;
  v_hash TEXT;
  v_org UUID;
  v_role TEXT;
BEGIN
  -- Everything that does NOT depend on the code, first: each of these
  -- answers a question about the CALLER, so none can probe a code.
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  IF coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
    RAISE EXCEPTION 'identity_required' USING ERRCODE = '42501';
  END IF;
  SELECT value INTO v_enabled FROM public.tanksync_meta WHERE key = 'fleet_enabled';
  IF v_enabled IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'fleet_disabled' USING ERRCODE = '42501';
  END IF;
  IF EXISTS (SELECT 1 FROM public.fleet_members WHERE user_id = v_uid) THEN
    RAISE EXCEPTION 'already_member' USING ERRCODE = '23505';
  END IF;

  -- One probe, one failure token: unknown, expired, spent and
  -- cascaded-away codes are indistinguishable.
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
  -- gets the same invalid_code as a stranger.
  UPDATE public.fleet_invites
     SET uses = uses + 1
   WHERE code_hash = v_hash;

  INSERT INTO public.fleet_members (org_id, user_id, role)
    VALUES (v_org, v_uid, v_role);
  -- ADR 0025 D5.4. A hash PREFIX: enough to correlate two joins on one
  -- code, never enough to replay it.
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (v_org, v_uid, 'member_joined', left(v_hash, 12));

  RETURN jsonb_build_object('org_id', v_org::text, 'role', v_role);
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_join(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_join(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_join(TEXT) FROM anon;
''';
