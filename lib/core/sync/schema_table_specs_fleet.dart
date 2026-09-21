// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Fleet table specs of the TankSync schema (#4212 / #4215, ADR 0025,
/// schema v13 / v14) — the wizard twins of
/// `supabase/migrations/20260918000001_fleet_tenancy.sql` and
/// `20260918000002_fleet_expenses.sql`.
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
/// The #4215 pair is appended after the #4212 five for the same reason.
///
/// The #4215 tables break the "every fleet policy is SELECT-only"
/// pattern deliberately, and only because their tenancy is different:
/// an expense and its document belong to the EMPLOYEE, not to the
/// organisation. See the block comment above them.
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
  // ── #4215 (v14) — the two USER-owned fleet tables ────────────────
  // Everything above belongs to the organisation; these two belong to
  // the employee, so they carry the schema's ordinary own-row policy
  // (which is why `EntitySync` fits them unchanged) PLUS a manager
  // SELECT restricted to `status <> 'draft'`. A draft is the
  // employee's working copy of a photograph of their own payment
  // card; ADR 0025's visibility matrix stops the manager at
  // "non-draft", and the stop is a policy predicate rather than a
  // client-side filter a REST call could omit.
  (
    name: 'fleet_expenses',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.fleet_expenses (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  fleet_vehicle_id UUID REFERENCES public.fleet_vehicles(id) ON DELETE SET NULL,
  fill_up_id TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'needs_review', 'submitted', 'approved', 'rejected',
    'exported', 'archived')),
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS fleet_expenses_org_status_idx
  ON public.fleet_expenses(org_id, status);
CREATE INDEX IF NOT EXISTS fleet_expenses_vehicle_idx
  ON public.fleet_expenses(fleet_vehicle_id);
CREATE INDEX IF NOT EXISTS fleet_expenses_document_idx
  ON public.fleet_expenses((data ->> 'documentId'));
''',
    rlsPolicySql: '''
-- #4215 (v14): user-owned. `(SELECT auth.uid())` so the lookup is
-- evaluated once per statement rather than once per row.
REVOKE ALL ON TABLE public.fleet_expenses FROM anon;
DROP POLICY IF EXISTS fleet_expenses_own ON public.fleet_expenses;
CREATE POLICY fleet_expenses_own ON public.fleet_expenses
  FOR ALL TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- The manager sees submitted work, never a draft. fleet_role() is NULL
-- for a non-member and NULL IN (…) is NULL, so a stranger is refused.
DROP POLICY IF EXISTS fleet_expenses_manager_select ON public.fleet_expenses;
CREATE POLICY fleet_expenses_manager_select ON public.fleet_expenses
  FOR SELECT TO authenticated
  USING (
    status <> 'draft'
    AND public.fleet_role(org_id) IN ('manager', 'admin')
  );''',
  ),
  (
    name: 'fleet_documents',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.fleet_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  object_key TEXT NOT NULL,
  sha256 TEXT NOT NULL,
  retention_class TEXT NOT NULL DEFAULT 'user_managed' CHECK (
    retention_class IN (
      'accounting_document', 'attribution_evidence', 'user_managed')),
  deleted_at TIMESTAMPTZ,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, object_key)
);
CREATE INDEX IF NOT EXISTS fleet_documents_org_idx
  ON public.fleet_documents(org_id);
CREATE INDEX IF NOT EXISTS fleet_documents_user_idx
  ON public.fleet_documents(user_id);
CREATE INDEX IF NOT EXISTS fleet_documents_object_key_idx
  ON public.fleet_documents(object_key);
''',
    rlsPolicySql: '''
-- The WITH CHECK is not a restatement of the USING: it pins the
-- object_key to `<org>/<caller>/<id>`. Without it a client could insert
-- an own row naming ANOTHER user's object path, and the Storage policy
-- that joins this table would hand over their receipt (#4049's
-- ownership gap, one table over).
REVOKE ALL ON TABLE public.fleet_documents FROM anon;
DROP POLICY IF EXISTS fleet_documents_own ON public.fleet_documents;
CREATE POLICY fleet_documents_own ON public.fleet_documents
  FOR ALL TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND object_key = org_id::text || '/' || (SELECT auth.uid())::text
                     || '/' || id::text
  );

-- "Only inside the expense workflow, audited" (ADR 0025 D9 matrix):
-- a manager reaches a receipt only while a non-draft expense of their
-- org cites it. Both halves are stated here rather than inherited from
-- another table's RLS.
DROP POLICY IF EXISTS fleet_documents_manager_select ON public.fleet_documents;
CREATE POLICY fleet_documents_manager_select ON public.fleet_documents
  FOR SELECT TO authenticated
  USING (
    public.fleet_role(org_id) IN ('manager', 'admin')
    AND EXISTS (
      SELECT 1 FROM public.fleet_expenses e
       WHERE e.org_id = fleet_documents.org_id
         AND e.status <> 'draft'
         AND e.data ->> 'documentId' = fleet_documents.id::text
    )
  );''',
  ),
];
