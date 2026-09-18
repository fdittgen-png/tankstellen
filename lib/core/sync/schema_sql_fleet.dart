// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The fleet oracles and RPCs of the TankSync wizard SQL (#4212, ADR
/// 0025, schema v13) — the wizard twin of
/// `supabase/migrations/20260918000001_fleet_tenancy.sql`, sections 2
/// and 4. The tables and their policies live in
/// `schema_table_specs_fleet.dart`; the `erase_my_data()` amendment
/// (section 5) is in `schema_sql_policies.dart`, where that function
/// has always lived.
///
/// Emission order is load-bearing (`schema_sql.dart`):
///
///  * [fleetOracleSql] goes out with `ownershipFnSql`, BEFORE `rlsSql`
///    — `CREATE POLICY` resolves the functions in its expression at
///    creation time, so a self-hoster's paste would otherwise die with
///    "function public.is_fleet_member(uuid) does not exist";
///  * [fleetRpcSql] goes out after `rpcSql`.
library;

/// The two SECURITY DEFINER oracles every fleet policy calls.
///
/// SECURITY DEFINER purely to break the RLS cycle (a `fleet_vehicles`
/// policy that queried `fleet_members` directly would recurse through
/// `fleet_members`' own policy). Caller-bound: unlike `owns_trip(trip,
/// user)` they take no user parameter and read `auth.uid()` inside, so
/// an authenticated client cannot use them as an existence oracle for
/// other people's memberships.
const String fleetOracleSql = '''
-- #4212 (v13) — fleet membership oracles for the fleet_* policies.
-- SECURITY DEFINER purely to break an RLS cycle; caller-bound (no user
-- parameter) so they cannot probe other people's memberships. Must
-- exist BEFORE the fleet policies that call them.
CREATE OR REPLACE FUNCTION public.is_fleet_member(p_org UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS \$\$
  SELECT EXISTS (
    SELECT 1 FROM public.fleet_members
     WHERE org_id = p_org
       AND user_id = auth.uid()
       AND status = 'active'
  );
\$\$;
REVOKE ALL ON FUNCTION public.is_fleet_member(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_fleet_member(UUID) TO authenticated;
-- NOT redundant with the PUBLIC revoke: Supabase grants anon separately.
REVOKE EXECUTE ON FUNCTION public.is_fleet_member(UUID) FROM anon;

CREATE OR REPLACE FUNCTION public.fleet_role(p_org UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS \$\$
  SELECT role FROM public.fleet_members
   WHERE org_id = p_org
     AND user_id = auth.uid()
     AND status = 'active'
   LIMIT 1;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_role(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_role(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_role(UUID) FROM anon;
''';

/// The only write path onto the fleet tables (ADR 0025 D7). Every
/// function re-checks `auth.uid()`, the org and the caller's role
/// INSIDE its body — SECURITY DEFINER bypasses RLS, so the policies are
/// never consulted (#4049's third surface). Raised messages are stable
/// snake_case tokens the client maps to its own wording.
const String fleetRpcSql = '''
-- ── Fleet RPCs (#4212, v13) — the only write path (ADR 0025 D7) ─────

-- Refuses unless the operator set tanksync_meta.fleet_enabled = 'true'
-- (ADR 0025 D3), the caller has the e-mail identity (D2) and is in no
-- fleet yet (D1). Creates the org, the caller as admin, and the policy
-- row with its placeholder defaults (D9).
CREATE OR REPLACE FUNCTION public.fleet_create_organization(p_name TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  uid UUID := auth.uid();
  org UUID;
  enabled TEXT;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  IF coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
    RAISE EXCEPTION 'identity_required' USING ERRCODE = '42501';
  END IF;
  SELECT value INTO enabled FROM public.tanksync_meta WHERE key = 'fleet_enabled';
  IF enabled IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'fleet_disabled' USING ERRCODE = '42501';
  END IF;
  IF p_name IS NULL OR length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'name_required' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.fleet_members WHERE user_id = uid) THEN
    RAISE EXCEPTION 'already_member' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.fleet_organizations (name, created_by)
    VALUES (trim(p_name), uid)
    RETURNING id INTO org;
  INSERT INTO public.fleet_members (org_id, user_id, role)
    VALUES (org, uid, 'admin');
  INSERT INTO public.fleet_policies (org_id, data)
    VALUES (org, '{"aggregationMinSamples": 5, "retention": {"expensesYears": 10, "attributionEventsMonths": 12, "auditYears": 3}}'::jsonb);
  RETURN org;
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_create_organization(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_create_organization(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_create_organization(TEXT) FROM anon;

CREATE OR REPLACE FUNCTION public.fleet_upsert_vehicle(
  p_org UUID,
  p_id UUID,
  p_fleet_code TEXT,
  p_display_name TEXT,
  p_plate_masked TEXT,
  p_data JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  vid UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  -- coalesce: NULL NOT IN (…) is NULL, which IF would treat as allowed.
  IF coalesce(public.fleet_role(p_org), '') NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF p_fleet_code IS NULL OR length(trim(p_fleet_code)) = 0
     OR p_display_name IS NULL OR length(trim(p_display_name)) = 0 THEN
    RAISE EXCEPTION 'vehicle_fields_required' USING ERRCODE = '22023';
  END IF;
  IF p_id IS NULL THEN
    INSERT INTO public.fleet_vehicles
      (org_id, fleet_code, display_name, plate_masked, data)
      VALUES (p_org, trim(p_fleet_code), trim(p_display_name), p_plate_masked,
              coalesce(p_data, '{}'::jsonb))
      RETURNING id INTO vid;
  ELSE
    UPDATE public.fleet_vehicles
       SET fleet_code = trim(p_fleet_code),
           display_name = trim(p_display_name),
           plate_masked = p_plate_masked,
           data = coalesce(p_data, '{}'::jsonb),
           updated_at = now()
     WHERE id = p_id AND org_id = p_org
     RETURNING id INTO vid;
    IF vid IS NULL THEN
      RAISE EXCEPTION 'vehicle_not_found' USING ERRCODE = 'P0002';
    END IF;
  END IF;
  RETURN vid;
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_upsert_vehicle(UUID, UUID, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_upsert_vehicle(UUID, UUID, TEXT, TEXT, TEXT, JSONB) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_upsert_vehicle(UUID, UUID, TEXT, TEXT, TEXT, JSONB) FROM anon;

CREATE OR REPLACE FUNCTION public.fleet_assign_vehicle(
  p_org UUID,
  p_fleet_vehicle_id UUID,
  p_user UUID,
  p_effective_from TIMESTAMPTZ DEFAULT now()
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  aid UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  IF coalesce(public.fleet_role(p_org), '') NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.fleet_vehicles
                  WHERE id = p_fleet_vehicle_id AND org_id = p_org) THEN
    RAISE EXCEPTION 'vehicle_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.fleet_members
                  WHERE org_id = p_org AND user_id = p_user
                    AND status = 'active') THEN
    RAISE EXCEPTION 'not_a_member' USING ERRCODE = 'P0002';
  END IF;
  SELECT id INTO aid FROM public.vehicle_assignments
   WHERE org_id = p_org AND fleet_vehicle_id = p_fleet_vehicle_id
     AND user_id = p_user AND effective_to IS NULL
   LIMIT 1;
  IF aid IS NOT NULL THEN
    RETURN aid;
  END IF;
  INSERT INTO public.vehicle_assignments
    (org_id, fleet_vehicle_id, user_id, effective_from, created_by)
    VALUES (p_org, p_fleet_vehicle_id, p_user,
            coalesce(p_effective_from, now()), auth.uid())
    RETURNING id INTO aid;
  RETURN aid;
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_assign_vehicle(UUID, UUID, UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_assign_vehicle(UUID, UUID, UUID, TIMESTAMPTZ) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_assign_vehicle(UUID, UUID, UUID, TIMESTAMPTZ) FROM anon;

-- Stamps effective_to, never deletes. FALSE for "no such open
-- assignment" AND for "not your org": not an existence oracle.
CREATE OR REPLACE FUNCTION public.fleet_end_assignment(
  p_assignment_id UUID,
  p_effective_to TIMESTAMPTZ DEFAULT now()
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  org UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  SELECT org_id INTO org FROM public.vehicle_assignments
   WHERE id = p_assignment_id;
  IF org IS NULL THEN
    RETURN FALSE;
  END IF;
  IF coalesce(public.fleet_role(org), '') NOT IN ('manager', 'admin') THEN
    RETURN FALSE;
  END IF;
  UPDATE public.vehicle_assignments
     SET effective_to = coalesce(p_effective_to, now()),
         updated_at = now()
   WHERE id = p_assignment_id
     AND effective_to IS NULL
     AND coalesce(p_effective_to, now()) >= effective_from;
  RETURN FOUND;
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_end_assignment(UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_end_assignment(UUID, TIMESTAMPTZ) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_end_assignment(UUID, TIMESTAMPTZ) FROM anon;
''';
