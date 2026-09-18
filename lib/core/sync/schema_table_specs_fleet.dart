// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Fleet-tenancy table specs of the TankSync schema (#4212, ADR 0025,
/// schema v13) — the wizard twins of
/// `supabase/migrations/20260918000001_fleet_tenancy.sql`.
///
/// These are the first tables in the schema whose rows belong to an
/// ORGANISATION rather than to `auth.uid()`. Two things follow, and both
/// are visible in the policy blocks below:
///
///  * every policy is `FOR SELECT` and goes through one of the two
///    SECURITY DEFINER oracles (`is_fleet_member` / `fleet_role`) that
///    `schema_sql_fleet.dart` emits BEFORE `rlsSql` — a policy that
///    queried `fleet_members` directly would recurse (#4049's cycle);
///  * there is NO client INSERT / UPDATE / DELETE policy on any of them
///    (ADR 0025 D7): writes are the `fleet_*` RPCs, which re-check role
///    and org inside the definer body.
///
/// Appended AFTER the extended specs in `syncedTableSpecs`, so every
/// pre-v13 golden byte is unchanged and the fleet block simply follows.
library;

import 'schema_table_specs.dart';

/// The fleet tables, in wizard-SQL emission order. All optional: their
/// absence degrades fleet mode, never core sync.
const List<SyncedTableSpec> fleetTableSpecs = [
  (
    name: 'fleet_organizations',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.fleet_organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS fleet_organizations_created_by_idx
  ON public.fleet_organizations(created_by);
''',
    rlsPolicySql: '''
-- Fleet (#4212, v13): SELECT-only, through the SECURITY DEFINER oracles
-- emitted before this block. No client write policy exists on any
-- fleet table — writes are the fleet_* RPCs (ADR 0025 D7).
DROP POLICY IF EXISTS fleet_organizations_member_select ON public.fleet_organizations;
CREATE POLICY fleet_organizations_member_select ON public.fleet_organizations
  FOR SELECT TO authenticated
  USING (public.is_fleet_member(id));''',
  ),
  (
    name: 'fleet_members',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.fleet_members (
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('employee', 'manager', 'admin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'left')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (org_id, user_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS fleet_members_single_org_idx
  ON public.fleet_members(user_id);
''',
    rlsPolicySql: '''
-- Own row always; the whole roster for managers and admins.
DROP POLICY IF EXISTS fleet_members_select ON public.fleet_members;
CREATE POLICY fleet_members_select ON public.fleet_members
  FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR public.fleet_role(org_id) IN ('manager', 'admin')
  );''',
  ),
  (
    name: 'fleet_vehicles',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
-- Every member sees the org's vehicle directory; nothing in it names a
-- person.
DROP POLICY IF EXISTS fleet_vehicles_member_select ON public.fleet_vehicles;
CREATE POLICY fleet_vehicles_member_select ON public.fleet_vehicles
  FOR SELECT TO authenticated
  USING (public.is_fleet_member(org_id));''',
  ),
  (
    name: 'vehicle_assignments',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
-- An assignment names a person: own rows only, org-wide for managers.
DROP POLICY IF EXISTS fleet_assignments_select ON public.vehicle_assignments;
CREATE POLICY fleet_assignments_select ON public.vehicle_assignments
  FOR SELECT TO authenticated
  USING (
    (user_id = (SELECT auth.uid()) AND public.is_fleet_member(org_id))
    OR public.fleet_role(org_id) IN ('manager', 'admin')
  );''',
  ),
  (
    name: 'fleet_policies',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.fleet_policies (
  org_id UUID PRIMARY KEY REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS fleet_policies_member_select ON public.fleet_policies;
CREATE POLICY fleet_policies_member_select ON public.fleet_policies
  FOR SELECT TO authenticated
  USING (public.is_fleet_member(org_id));''',
  ),
];
