-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #4212 (Epic #4211, ADR 0025) — fleet tenancy: organisations, members,
-- vehicles, effective-dated assignments and per-org policies, behind
-- two SECURITY DEFINER oracles and four RPCs. Schema version 12 → 13.
--
-- ── The shape, and why ───────────────────────────────────────────────
-- Every existing policy is `user_id = auth.uid()`. Fleet rows belong to
-- an ORGANISATION, so this migration introduces the second tenancy
-- boundary the schema has ever had — and the naive form recurses: a
-- fleet_vehicles policy that queries fleet_members, whose policy queries
-- fleet_vehicles… #4049 hit the same cycle with trip shares; its fix is
-- the template here. `is_fleet_member(p_org)` / `fleet_role(p_org)` are
-- SECURITY DEFINER (RLS bypassed inside, so the cycle never forms),
-- STABLE, `SET search_path = public`, REVOKE'd from PUBLIC, GRANT'ed to
-- authenticated and — NOT redundant — REVOKE'd from anon.
--
-- Unlike owns_trip(trip, user) the oracles take NO user parameter: they
-- read auth.uid() inside. A (org, user) signature callable over PostgREST
-- would be an existence oracle for other people's memberships; the
-- assign RPC, which needs to check a *target* user, queries fleet_members
-- directly as the definer instead.
--
-- ── Writes are RPC-only (ADR 0025 D7) ────────────────────────────────
-- There is no client INSERT / UPDATE / DELETE policy on any of the five
-- tables. Every write below re-checks auth.uid(), the org and the
-- caller's role INSIDE the definer body, because a definer function
-- bypasses RLS and the policies are never consulted (#4049's third
-- surface). fleet_end_assignment stamps effective_to and never deletes:
-- an assignment is history, and a fill-up recorded during it stays
-- attributed to it.
--
-- ── Privacy-first hard rules (ADR 0025 D5) ───────────────────────────
-- No policy is added to trip_summaries / trip_details / obd2_baselines.
-- No fleet table has a location column. fleet_members and
-- vehicle_assignments join erase_my_data() (they name the person);
-- organisations, vehicles and policies are the org's, not the user's.
--
-- ── Operator switch (ADR 0025 D3) ────────────────────────────────────
-- fleet_create_organization refuses unless the self-host operator has
-- run, in the SQL editor:
--
--   INSERT INTO public.tanksync_meta (key, value)
--     VALUES ('fleet_enabled', 'true')
--     ON CONFLICT (key) DO UPDATE SET value = 'true', updated_at = now();
--
-- The community project never gets that row, so fleet creation there
-- fails closed.
--
-- RLS impact:
--   [x] Five new tables, SELECT-only policies through the oracles.
--   [x] No change to any existing table's policies.
--
-- RLS confirmed: [ ]
--   Live matrix (two orgs invisible to each other; ended assignment keeps
--   history; employee cannot call a manager RPC; anon cannot call an
--   oracle) to be run with the live-RPC skill and pasted into the F2 PR
--   — see `test/core/sync/fleet/fleet_rls_contract_test.dart` for the
--   static half CI enforces.

-- ───────────────────────────────────────────────────────────────────
-- 1. Tables
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fleet_organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS fleet_organizations_created_by_idx
  ON public.fleet_organizations(created_by);

CREATE TABLE IF NOT EXISTS public.fleet_members (
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('employee', 'manager', 'admin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'left')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (org_id, user_id)
);
-- ADR 0025 D1: one organisation per user in v1. Also the oracle's lookup.
CREATE UNIQUE INDEX IF NOT EXISTS fleet_members_single_org_idx
  ON public.fleet_members(user_id);

CREATE TABLE IF NOT EXISTS public.fleet_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  fleet_code TEXT NOT NULL,
  display_name TEXT NOT NULL,
  plate_masked TEXT,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (org_id, fleet_code)
);
CREATE INDEX IF NOT EXISTS fleet_vehicles_org_idx
  ON public.fleet_vehicles(org_id);

CREATE TABLE IF NOT EXISTS public.vehicle_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  fleet_vehicle_id UUID NOT NULL REFERENCES public.fleet_vehicles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  effective_to TIMESTAMPTZ,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);
CREATE INDEX IF NOT EXISTS vehicle_assignments_org_idx
  ON public.vehicle_assignments(org_id);
CREATE INDEX IF NOT EXISTS vehicle_assignments_user_idx
  ON public.vehicle_assignments(user_id);
CREATE INDEX IF NOT EXISTS vehicle_assignments_vehicle_idx
  ON public.vehicle_assignments(fleet_vehicle_id);
CREATE INDEX IF NOT EXISTS vehicle_assignments_created_by_idx
  ON public.vehicle_assignments(created_by);

CREATE TABLE IF NOT EXISTS public.fleet_policies (
  org_id UUID PRIMARY KEY REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.fleet_organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_policies ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────────
-- 2. Oracles — SECURITY DEFINER purely to break the RLS cycle
-- ───────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_fleet_member(p_org UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.fleet_members
     WHERE org_id = p_org
       AND user_id = auth.uid()
       AND status = 'active'
  );
$$;
REVOKE ALL ON FUNCTION public.is_fleet_member(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_fleet_member(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_fleet_member(UUID) FROM anon;

CREATE OR REPLACE FUNCTION public.fleet_role(p_org UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role FROM public.fleet_members
   WHERE org_id = p_org
     AND user_id = auth.uid()
     AND status = 'active'
   LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.fleet_role(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_role(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_role(UUID) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 3. Read policies — SELECT only; every one goes through an oracle
-- ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS fleet_organizations_member_select ON public.fleet_organizations;
CREATE POLICY fleet_organizations_member_select ON public.fleet_organizations
  FOR SELECT TO authenticated
  USING (public.is_fleet_member(id));

-- Own row always; the whole roster for managers and admins.
DROP POLICY IF EXISTS fleet_members_select ON public.fleet_members;
CREATE POLICY fleet_members_select ON public.fleet_members
  FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR public.fleet_role(org_id) IN ('manager', 'admin')
  );

-- Every member sees the org's vehicle directory (it is how a driver
-- finds the car); nothing in it is about a person.
DROP POLICY IF EXISTS fleet_vehicles_member_select ON public.fleet_vehicles;
CREATE POLICY fleet_vehicles_member_select ON public.fleet_vehicles
  FOR SELECT TO authenticated
  USING (public.is_fleet_member(org_id));

-- An assignment names a person: own rows only, org-wide for managers.
DROP POLICY IF EXISTS fleet_assignments_select ON public.vehicle_assignments;
CREATE POLICY fleet_assignments_select ON public.vehicle_assignments
  FOR SELECT TO authenticated
  USING (
    (user_id = (SELECT auth.uid()) AND public.is_fleet_member(org_id))
    OR public.fleet_role(org_id) IN ('manager', 'admin')
  );

DROP POLICY IF EXISTS fleet_policies_member_select ON public.fleet_policies;
CREATE POLICY fleet_policies_member_select ON public.fleet_policies
  FOR SELECT TO authenticated
  USING (public.is_fleet_member(org_id));

-- ───────────────────────────────────────────────────────────────────
-- 4. RPCs — the only write path (ADR 0025 D7)
-- ───────────────────────────────────────────────────────────────────
-- Raised messages are stable snake_case tokens the client maps to its
-- own (translated) wording; they are never shown verbatim.
CREATE OR REPLACE FUNCTION public.fleet_create_organization(p_name TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid UUID := auth.uid();
  org UUID;
  enabled TEXT;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  -- ADR 0025 D2: a fleet membership needs the e-mail identity.
  IF coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
    RAISE EXCEPTION 'identity_required' USING ERRCODE = '42501';
  END IF;
  -- ADR 0025 D3: the operator switch. Absent on the community project.
  SELECT value INTO enabled FROM public.tanksync_meta WHERE key = 'fleet_enabled';
  IF enabled IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'fleet_disabled' USING ERRCODE = '42501';
  END IF;
  IF p_name IS NULL OR length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'name_required' USING ERRCODE = '22023';
  END IF;
  -- ADR 0025 D1: one organisation per user in v1.
  IF EXISTS (SELECT 1 FROM public.fleet_members WHERE user_id = uid) THEN
    RAISE EXCEPTION 'already_member' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.fleet_organizations (name, created_by)
    VALUES (trim(p_name), uid)
    RETURNING id INTO org;
  INSERT INTO public.fleet_members (org_id, user_id, role)
    VALUES (org, uid, 'admin');
  -- ADR 0025 D9: placeholder defaults, documented as deployment config.
  INSERT INTO public.fleet_policies (org_id, data)
    VALUES (org, '{"aggregationMinSamples": 5, "retention": {"expensesYears": 10, "attributionEventsMonths": 12, "auditYears": 3}}'::jsonb);
  RETURN org;
END;
$$;
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
AS $$
DECLARE
  vid UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  -- coalesce: a NULL role (not a member) must fail, and NULL NOT IN (…)
  -- is NULL, which an IF would silently treat as "allowed".
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
    -- org_id in the WHERE: an id from another org updates nothing.
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
$$;
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
AS $$
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
  -- The TARGET must be an active member of the same org. Checked here
  -- as the definer rather than through the caller-bound oracle.
  IF NOT EXISTS (SELECT 1 FROM public.fleet_members
                  WHERE org_id = p_org AND user_id = p_user
                    AND status = 'active') THEN
    RAISE EXCEPTION 'not_a_member' USING ERRCODE = 'P0002';
  END IF;
  -- Idempotent: an already-open assignment of this car to this person
  -- is returned, not duplicated.
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
$$;
REVOKE ALL ON FUNCTION public.fleet_assign_vehicle(UUID, UUID, UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_assign_vehicle(UUID, UUID, UUID, TIMESTAMPTZ) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_assign_vehicle(UUID, UUID, UUID, TIMESTAMPTZ) FROM anon;

-- Ends an assignment: stamps effective_to, never deletes (history rule).
-- Returns FALSE for "no such open assignment" AND for "not your org" —
-- the same value, so it is not an existence oracle for assignment ids.
CREATE OR REPLACE FUNCTION public.fleet_end_assignment(
  p_assignment_id UUID,
  p_effective_to TIMESTAMPTZ DEFAULT now()
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;
REVOKE ALL ON FUNCTION public.fleet_end_assignment(UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_end_assignment(UUID, TIMESTAMPTZ) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_end_assignment(UUID, TIMESTAMPTZ) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 5. Erasure — the person's rows join erase_my_data() (GDPR Art. 17)
-- ───────────────────────────────────────────────────────────────────
-- Same body as 20260829000001 plus the two user-linked fleet tables,
-- listed first (children before parents). The org's own rows are not
-- the user's to erase (ADR 0025 D9 matrix).
CREATE OR REPLACE FUNCTION public.erase_my_data()
RETURNS TABLE(table_name TEXT, rows_deleted BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid UUID := auth.uid();
  spec TEXT[];
  n BIGINT;
BEGIN
  IF uid IS NULL THEN
    RETURN;
  END IF;
  -- Transaction-local: lets limit_bulk_delete() pass for this erase only.
  PERFORM set_config('request.jwt.claims',
                     json_build_object('role', 'service_role')::text, true);

  FOREACH spec SLICE 1 IN ARRAY ARRAY[
    ARRAY['vehicle_assignments', 'user_id'],
    ARRAY['fleet_members',    'user_id'],
    ARRAY['trip_shares',      'owner_id'],
    ARRAY['trip_shares',      'shared_with_id'],
    ARRAY['trip_details',     'user_id'],
    ARRAY['trip_summaries',   'user_id'],
    ARRAY['content_reports',  'reporter_user_id'],
    ARRAY['price_reports',    'reporter_id'],
    ARRAY['wait_time_pings',  'user_id'],
    ARRAY['push_tokens',      'user_id'],
    ARRAY['obd2_baselines',   'user_id'],
    ARRAY['station_ratings',  'user_id'],
    ARRAY['ignored_stations', 'user_id'],
    ARRAY['itineraries',      'user_id'],
    ARRAY['fill_ups',         'user_id'],
    ARRAY['vehicles',         'user_id'],
    ARRAY['alerts',           'user_id'],
    ARRAY['favorites',        'user_id'],
    ARRAY['sync_settings',    'user_id'],
    ARRAY['deletions',        'user_id'],
    ARRAY['users',            'id']
  ]
  LOOP
    IF to_regclass('public.' || spec[1]) IS NULL THEN
      CONTINUE;
    END IF;
    EXECUTE format('DELETE FROM public.%I WHERE %I = $1', spec[1], spec[2])
      USING uid;
    GET DIAGNOSTICS n = ROW_COUNT;
    table_name := spec[1] || CASE WHEN spec[2] = 'shared_with_id'
                                  THEN ' (received)' ELSE '' END;
    rows_deleted := n;
    RETURN NEXT;
  END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.erase_my_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.erase_my_data() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.erase_my_data() FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 6. Schema version
-- ───────────────────────────────────────────────────────────────────
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '13', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
