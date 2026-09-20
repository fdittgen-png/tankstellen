-- TankSync Schema Setup (schema version 14)
-- Run this in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste → Run

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  station_name TEXT,
  country_code TEXT NOT NULL DEFAULT 'DE',
  kind TEXT NOT NULL DEFAULT 'fuel',
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);

CREATE TABLE IF NOT EXISTS public.alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  station_name TEXT,
  fuel_type TEXT NOT NULL,
  target_price DOUBLE PRECISION NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_triggered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.price_snapshots (
  id BIGSERIAL PRIMARY KEY,
  station_id TEXT NOT NULL,
  country_code TEXT NOT NULL DEFAULT 'DE',
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  e5 DOUBLE PRECISION,
  e10 DOUBLE PRECISION,
  e98 DOUBLE PRECISION,
  diesel DOUBLE PRECISION,
  diesel_premium DOUBLE PRECISION,
  e85 DOUBLE PRECISION,
  lpg DOUBLE PRECISION,
  cng DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS public.sync_settings (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sync_favorites BOOLEAN NOT NULL DEFAULT true,
  sync_alerts BOOLEAN NOT NULL DEFAULT true,
  sync_history BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.vehicles (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS vehicles_user_idx ON public.vehicles(user_id);

CREATE TABLE IF NOT EXISTS public.fill_ups (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  vehicle_id TEXT,
  recorded_at TIMESTAMPTZ NOT NULL,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS fill_ups_user_idx ON public.fill_ups(user_id);
CREATE INDEX IF NOT EXISTS fill_ups_user_date_idx
  ON public.fill_ups(user_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS public.itineraries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  waypoints JSONB NOT NULL DEFAULT '[]',
  distance_km DOUBLE PRECISION NOT NULL DEFAULT 0,
  duration_minutes DOUBLE PRECISION NOT NULL DEFAULT 0,
  avoid_highways BOOLEAN NOT NULL DEFAULT false,
  fuel_type TEXT NOT NULL DEFAULT 'e10',
  selected_station_ids TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ignored_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);

CREATE TABLE IF NOT EXISTS public.station_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  is_shared BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);

CREATE TABLE IF NOT EXISTS public.price_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  station_id TEXT NOT NULL,
  country_code TEXT NOT NULL DEFAULT 'DE',
  fuel_type TEXT NOT NULL,
  reported_price DOUBLE PRECISION,
  correction_text TEXT,
  is_validated BOOLEAN DEFAULT false,
  reported_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.push_tokens (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  ntfy_topic TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.obd2_baselines (
  vehicle_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_samples INTEGER NOT NULL DEFAULT 0,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, vehicle_id)
);
CREATE INDEX IF NOT EXISTS obd2_baselines_user_idx
  ON public.obd2_baselines(user_id);

CREATE TABLE IF NOT EXISTS public.trip_summaries (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  vehicle_id TEXT,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS trip_summaries_user_idx
  ON public.trip_summaries(user_id);
CREATE INDEX IF NOT EXISTS trip_summaries_user_started_idx
  ON public.trip_summaries(user_id, started_at DESC);

CREATE TABLE IF NOT EXISTS public.trip_details (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS trip_details_user_idx
  ON public.trip_details(user_id);

CREATE TABLE IF NOT EXISTS public.trip_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shared_with_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  share_token TEXT UNIQUE,
  permission TEXT NOT NULL DEFAULT 'read',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS trip_shares_unique_direct_idx
  ON public.trip_shares(trip_id, owner_id, shared_with_id)
  WHERE shared_with_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS trip_shares_owner_idx
  ON public.trip_shares(owner_id);
CREATE INDEX IF NOT EXISTS trip_shares_recipient_idx
  ON public.trip_shares(shared_with_id);
CREATE INDEX IF NOT EXISTS trip_shares_trip_recipient_idx
  ON public.trip_shares(trip_id, shared_with_id);

CREATE TABLE IF NOT EXISTS public.content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_kind TEXT NOT NULL,
  target_id TEXT NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS content_reports_reporter_idx
  ON public.content_reports(reporter_user_id);

CREATE TABLE IF NOT EXISTS public.wait_time_pings (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL,
  station_id TEXT NOT NULL,
  country_code TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('arrived', 'left')),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS wait_time_pings_user_idx
  ON public.wait_time_pings(user_id);
CREATE INDEX IF NOT EXISTS wait_time_pings_station_recorded_idx
  ON public.wait_time_pings(station_id, recorded_at);
CREATE INDEX IF NOT EXISTS wait_time_pings_session_idx
  ON public.wait_time_pings(session_id);

CREATE TABLE IF NOT EXISTS public.deletions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  deleted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  device_id TEXT,
  app_version TEXT,
  UNIQUE(user_id, table_name, record_id)
);
CREATE INDEX IF NOT EXISTS deletions_user_table_idx
  ON public.deletions(user_id, table_name);

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

ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'fuel';
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS data JSONB;

-- #4049 — ownership oracle for the trip_shares write policies. It is
-- SECURITY DEFINER purely to break an RLS cycle: trip_summaries' read
-- policy queries trip_shares, so a trip_shares policy that looked up
-- trip_summaries directly would recurse. Must exist BEFORE the share
-- policies that call it.
CREATE OR REPLACE FUNCTION public.owns_trip(p_trip_id TEXT, p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_summaries
     WHERE id = p_trip_id AND user_id = p_user
  );
$$;
REVOKE ALL ON FUNCTION public.owns_trip(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owns_trip(TEXT, UUID) TO authenticated;
-- NOT redundant with the PUBLIC revoke: Supabase grants anon separately,
-- and without this owns_trip() is an unauthenticated existence oracle.
REVOKE EXECUTE ON FUNCTION public.owns_trip(TEXT, UUID) FROM anon;

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
-- NOT redundant with the PUBLIC revoke: Supabase grants anon separately.
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

-- Advisor hygiene (#4212): Supabase's ALTER DEFAULT PRIVILEGES grants the
-- full table ACL to anon and authenticated on every new public table.
-- RLS already refuses anon every row (verified by the live matrix), so
-- this REVOKE is behaviourally a no-op; it keeps the fleet tables off the
-- pg_graphql_anon_table_exposed lint instead of adding five rows to it.
REVOKE ALL ON TABLE
  public.fleet_organizations,
  public.fleet_members,
  public.fleet_vehicles,
  public.vehicle_assignments,
  public.fleet_policies
  FROM anon;

-- ── Row Level Security ──────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fill_ups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ignored_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.station_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obd2_baselines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wait_time_pings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deletions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_own ON public.users;
CREATE POLICY users_own ON public.users FOR ALL USING (id = auth.uid());

DROP POLICY IF EXISTS favorites_own ON public.favorites;
CREATE POLICY favorites_own ON public.favorites
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS alerts_own ON public.alerts;
CREATE POLICY alerts_own ON public.alerts
  FOR ALL USING (user_id = auth.uid());

-- Price snapshots: readable by all; only service_role writes.
DROP POLICY IF EXISTS snapshots_read ON public.price_snapshots;
CREATE POLICY snapshots_read ON public.price_snapshots
  FOR SELECT USING (true);

DROP POLICY IF EXISTS sync_own ON public.sync_settings;
CREATE POLICY sync_own ON public.sync_settings
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS vehicles_own ON public.vehicles;
CREATE POLICY vehicles_own ON public.vehicles
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS fill_ups_own ON public.fill_ups;
CREATE POLICY fill_ups_own ON public.fill_ups
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS itineraries_own ON public.itineraries;
CREATE POLICY itineraries_own ON public.itineraries
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS ignored_own ON public.ignored_stations;
CREATE POLICY ignored_own ON public.ignored_stations
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS ratings_own ON public.station_ratings;
CREATE POLICY ratings_own ON public.station_ratings
  FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS ratings_shared_read ON public.station_ratings;
CREATE POLICY ratings_shared_read ON public.station_ratings
  FOR SELECT USING (is_shared = true OR user_id = auth.uid());

-- Price reports: anyone reads, reporter inserts their own.
DROP POLICY IF EXISTS reports_read ON public.price_reports;
CREATE POLICY reports_read ON public.price_reports
  FOR SELECT USING (true);
DROP POLICY IF EXISTS reports_insert ON public.price_reports;
CREATE POLICY reports_insert ON public.price_reports
  FOR INSERT WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS push_own ON public.push_tokens;
CREATE POLICY push_own ON public.push_tokens
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS obd2_baselines_own ON public.obd2_baselines;
CREATE POLICY obd2_baselines_own ON public.obd2_baselines
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS trip_summaries_own ON public.trip_summaries;
CREATE POLICY trip_summaries_own ON public.trip_summaries
  FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS trip_details_own ON public.trip_details;
CREATE POLICY trip_details_own ON public.trip_details
  FOR ALL USING (user_id = auth.uid());

-- Trip shares: owner has full CRUD over rows they created; the recipient
-- may only READ a grant pointing at them.
DROP POLICY IF EXISTS trip_shares_owner_select ON public.trip_shares;
CREATE POLICY trip_shares_owner_select ON public.trip_shares
  FOR SELECT USING (owner_id = auth.uid());
-- #4049 — a grant may only name a trip the grantor OWNS. `owns_trip`
-- is SECURITY DEFINER purely to break the RLS cycle (trip_summaries'
-- read policy queries trip_shares, so a direct lookup would recurse).
DROP POLICY IF EXISTS trip_shares_owner_insert ON public.trip_shares;
CREATE POLICY trip_shares_owner_insert ON public.trip_shares
  FOR INSERT WITH CHECK (
    owner_id = auth.uid() AND public.owns_trip(trip_id, auth.uid()));
-- Both sides: USING stops an already-foreign grant being touched,
-- WITH CHECK stops a legitimate one being repointed at another's trip.
DROP POLICY IF EXISTS trip_shares_owner_update ON public.trip_shares;
CREATE POLICY trip_shares_owner_update ON public.trip_shares
  FOR UPDATE
  USING (owner_id = auth.uid() AND public.owns_trip(trip_id, auth.uid()))
  WITH CHECK (owner_id = auth.uid() AND public.owns_trip(trip_id, auth.uid()));
DROP POLICY IF EXISTS trip_shares_owner_delete ON public.trip_shares;
CREATE POLICY trip_shares_owner_delete ON public.trip_shares
  FOR DELETE USING (owner_id = auth.uid());
DROP POLICY IF EXISTS trip_shares_recipient_select ON public.trip_shares;
CREATE POLICY trip_shares_recipient_select ON public.trip_shares
  FOR SELECT USING (shared_with_id = auth.uid());

-- Additive read access so a recipient can read a shared trip (never write).
-- #4049 — the grant's owner must be the row's owner. Defence in depth:
-- an invalid grant written before this change grants nothing.
DROP POLICY IF EXISTS trip_summaries_shared_read ON public.trip_summaries;
CREATE POLICY trip_summaries_shared_read ON public.trip_summaries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_summaries.id
        AND s.shared_with_id = auth.uid()
        AND s.owner_id = trip_summaries.user_id
    )
  );
DROP POLICY IF EXISTS trip_details_shared_read ON public.trip_details;
CREATE POLICY trip_details_shared_read ON public.trip_details
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_details.id
        AND s.shared_with_id = auth.uid()
        AND s.owner_id = trip_details.user_id
    )
  );

-- Content reports (#3726, v7): a user may only file reports naming
-- THEMSELVES as reporter, and only ever sees / deletes their own (the
-- delete path serves the GDPR wipe). Moderation review happens with the
-- service role / SQL editor, never through the client.
DROP POLICY IF EXISTS content_reports_insert_own ON public.content_reports;
CREATE POLICY content_reports_insert_own ON public.content_reports
  FOR INSERT WITH CHECK (reporter_user_id = auth.uid());
DROP POLICY IF EXISTS content_reports_select_own ON public.content_reports;
CREATE POLICY content_reports_select_own ON public.content_reports
  FOR SELECT USING (reporter_user_id = auth.uid());
DROP POLICY IF EXISTS content_reports_delete_own ON public.content_reports;
CREATE POLICY content_reports_delete_own ON public.content_reports
  FOR DELETE USING (reporter_user_id = auth.uid());

-- Wait-time pings (#2650): a user reads, writes and deletes only their own.
DROP POLICY IF EXISTS wait_time_pings_own ON public.wait_time_pings;
CREATE POLICY wait_time_pings_own ON public.wait_time_pings
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Deletion tombstones (#3078): a user only ever sees / writes their own.
DROP POLICY IF EXISTS deletions_own ON public.deletions;
CREATE POLICY deletions_own ON public.deletions
  FOR ALL USING (user_id = auth.uid());

-- Fleet (#4212, v13): SELECT-only, through the SECURITY DEFINER oracles
-- emitted before this block. No client write policy exists on any
-- fleet table — writes are the fleet_* RPCs (ADR 0025 D7).
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

-- Every member sees the org's vehicle directory; nothing in it names a
-- person.
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
  );

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
  );

-- ── Owner protection (#3747, v8) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.database_owner (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT single_owner CHECK (id IS NOT NULL)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_database_owner_singleton
  ON public.database_owner ((true));
ALTER TABLE public.database_owner ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS owner_read ON public.database_owner;
CREATE POLICY owner_read ON public.database_owner FOR SELECT USING (true);
DROP POLICY IF EXISTS owner_manage ON public.database_owner;
CREATE POLICY owner_manage ON public.database_owner
  FOR ALL USING (auth.role() = 'service_role');

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

CREATE OR REPLACE FUNCTION public.auto_register_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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

-- users policy split: DELETE restricted to self / owner / service_role.
DROP POLICY IF EXISTS users_own ON public.users;
DROP POLICY IF EXISTS users_own_select ON public.users;
CREATE POLICY users_own_select ON public.users FOR SELECT USING (id = auth.uid());
DROP POLICY IF EXISTS users_own_insert ON public.users;
CREATE POLICY users_own_insert ON public.users FOR INSERT WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS users_own_update ON public.users;
CREATE POLICY users_own_update ON public.users FOR UPDATE USING (id = auth.uid());
DROP POLICY IF EXISTS users_delete_owner_only ON public.users;
CREATE POLICY users_delete_owner_only ON public.users
  FOR DELETE USING (
    id = auth.uid()
    OR public.is_database_owner()
    OR auth.role() = 'service_role'
  );

-- Shared community data: snapshots deletable by service_role only;
-- reports deletable by their reporter, the owner, or service_role.
DROP POLICY IF EXISTS snapshots_delete ON public.price_snapshots;
CREATE POLICY snapshots_delete ON public.price_snapshots
  FOR DELETE USING (auth.role() = 'service_role');
DROP POLICY IF EXISTS reports_delete ON public.price_reports;
CREATE POLICY reports_delete ON public.price_reports
  FOR DELETE USING (
    reporter_id = auth.uid()
    OR public.is_database_owner()
    OR auth.role() = 'service_role'
  );

-- 100-row bulk-delete rate limit on the user-data tables.
CREATE OR REPLACE FUNCTION public.limit_bulk_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  delete_count INTEGER;
BEGIN
  IF current_setting('request.jwt.claims', true)::json->>'role' = 'service_role' THEN
    RETURN OLD;
  END IF;
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

-- ── Trip-sharing RPCs ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.resolve_share_recipient(recipient_email TEXT)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS $$
  SELECT id FROM auth.users
  WHERE lower(email) = lower(trim(recipient_email))
  LIMIT 1;
$$;
-- v8 (#3747): the raw-UUID resolver is an email→UUID oracle. It stays
-- defined (idempotent re-runs; service_role use) but authenticated
-- clients lost EXECUTE — they call share_trip_with_email below instead.
REVOKE ALL ON FUNCTION public.resolve_share_recipient(TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) FROM anon;

-- v8 (#3747): resolve+insert server-side; returns ONLY success/failure
-- so the recipient's UUID never crosses the wire. Ownership mirrors the
-- old client insert path: owner_id is forced to auth.uid().
CREATE OR REPLACE FUNCTION public.share_trip_with_email(p_trip_id TEXT, p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  recipient UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  -- #4049 — the caller must OWN the trip. SECURITY DEFINER bypasses RLS
  -- on the insert below, so without this guard the write policies are
  -- never consulted and any trip id could be shared. Returns the same
  -- FALSE as an unresolvable recipient, so it is not an existence
  -- oracle for trip ids.
  IF NOT public.owns_trip(p_trip_id, auth.uid()) THEN
    RETURN FALSE;
  END IF;
  SELECT id INTO recipient FROM auth.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  IF recipient IS NULL THEN
    RETURN FALSE;
  END IF;
  INSERT INTO public.trip_shares (trip_id, owner_id, shared_with_id, permission)
    VALUES (p_trip_id, auth.uid(), recipient, 'read')
    ON CONFLICT (trip_id, owner_id, shared_with_id)
      WHERE shared_with_id IS NOT NULL
    DO UPDATE SET permission = 'read';
  RETURN TRUE;
END;
$$;
REVOKE ALL ON FUNCTION public.share_trip_with_email(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.share_trip_with_email(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.share_trip_with_email(TEXT, TEXT) FROM anon;

-- v11 (#4060): share_trip_with_email_v2 returns a TEXT outcome. v1 gave
-- the same FALSE for "no such recipient" and "caller does not own the
-- trip / trip not on the server yet", and the client blamed the email
-- for both. Not an existence oracle: 'not_owned' covers "does not exist"
-- and "someone else's" identically. v1 stays for clients in the field.
CREATE OR REPLACE FUNCTION public.share_trip_with_email_v2(p_trip_id TEXT, p_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  recipient UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN 'not_authenticated';
  END IF;
  IF NOT public.owns_trip(p_trip_id, auth.uid()) THEN
    RETURN 'not_owned';
  END IF;
  SELECT id INTO recipient FROM auth.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  IF recipient IS NULL THEN
    RETURN 'recipient_not_found';
  END IF;
  INSERT INTO public.trip_shares (trip_id, owner_id, shared_with_id, permission)
    VALUES (p_trip_id, auth.uid(), recipient, 'read')
    ON CONFLICT (trip_id, owner_id, shared_with_id)
      WHERE shared_with_id IS NOT NULL
    DO UPDATE SET permission = 'read';
  RETURN 'shared';
END;
$$;
REVOKE ALL ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) FROM anon;

CREATE OR REPLACE FUNCTION public.claim_trip_share(token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  claimed_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  UPDATE public.trip_shares
    SET shared_with_id = auth.uid()
    WHERE share_token = token
      AND shared_with_id IS NULL
      AND owner_id <> auth.uid()
    RETURNING id INTO claimed_id;
  RETURN claimed_id;
END;
$$;
REVOKE ALL ON FUNCTION public.claim_trip_share(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_trip_share(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.claim_trip_share(TEXT) FROM anon;

-- ── Account deletion RPC (#3712, schema v6) ─────────────────────────
-- Play's account-deletion requirement: "Delete account" must remove the
-- auth identity itself, not only the data rows. Pinned to auth.uid() so
-- a caller can only ever delete THEMSELVES; a null uid deletes nothing.
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  DELETE FROM auth.users WHERE id = auth.uid();
$$;
REVOKE ALL ON FUNCTION public.delete_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon;

-- v9 (#3868, GDPR Art. 17) — erase every row the caller owns in ONE
-- transaction, bypassing limit_bulk_delete for the caller's own rows;
-- public.users, sync_settings, wait_time_pings and trip_shares included.
-- v13 (#4212) — the two user-linked fleet tables join the list; the
-- org's own rows (organisations, vehicles, policies) are not the user's.
-- v14 (#4215) — fleet_expenses + fleet_documents join it, and the
-- stored receipt BYTES go with them: deleting the metadata row without
-- its object would leave the receipt in the bucket, which is exactly
-- the failure Art. 17 is about. The sweep runs BEFORE the loop, while
-- the rows that name the object keys still exist.
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

  -- #4215 — the receipt objects, keyed through the rows deleted below.
  -- BEST-EFFORT, and structurally unable to abort the erasure.
  --
  -- Supabase ships protect_objects_delete on storage.objects: a BEFORE
  -- DELETE FOR EACH STATEMENT trigger that raises 42501 for a direct
  -- SQL delete. Statement-level means it fires even when the statement
  -- matches ZERO rows, so the first shape of this sweep took down
  -- erase_my_data() for EVERY caller, fleet member or not — an Art. 17
  -- regression on a shipped path (#3865). The live matrix caught it.
  --
  -- Two guards, and the second is the one that matters: the
  -- transaction-local allow_delete_query switch is what the trigger
  -- looks for, and the EXCEPTION block means no future storage-side
  -- guard can ever again take the row erasure down with it. A skipped
  -- sweep is a WARNING, never a failed erase.
  --
  -- The client removes the bytes through the Storage API BEFORE calling
  -- this function (FleetDocumentStore.eraseOwnObjects), because that is
  -- the only path that deletes the S3 object as well as its row. This
  -- statement is the fallback for a caller that did not, and on its own
  -- it can leave the stored bytes orphaned in the bucket.
  IF to_regclass('storage.objects') IS NOT NULL THEN
    BEGIN
      IF EXISTS (
        SELECT 1 FROM pg_trigger
         WHERE tgrelid = 'storage.objects'::regclass
           AND NOT tgisinternal
           AND tgname = 'protect_objects_delete'
      ) THEN
        PERFORM set_config('storage.allow_delete_query', 'true', true);
      END IF;
      DELETE FROM storage.objects o
        USING public.fleet_documents d
        WHERE o.bucket_id = 'fleet-documents'
          AND o.name = d.object_key
          AND d.user_id = uid;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'erase_my_data: fleet-documents object sweep skipped (%)',
        SQLERRM;
    END;
  END IF;

  FOREACH spec SLICE 1 IN ARRAY ARRAY[
    ARRAY['fleet_expenses',   'user_id'],
    ARRAY['fleet_documents',  'user_id'],
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
AS $$
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
$$;
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

-- ── Fleet audit log (#4215, v14, ADR 0025 D5.4) ────────────────────
-- Server-only: written by the fleet_* RPCs, read by the subject (own
-- rows) and by an org admin. No client write policy exists, so the
-- trail cannot be rewritten by the party it is about.
CREATE TABLE IF NOT EXISTS public.fleet_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  actor UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target TEXT,
  at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS fleet_audit_events_org_at_idx
  ON public.fleet_audit_events(org_id, at DESC);
CREATE INDEX IF NOT EXISTS fleet_audit_events_actor_idx
  ON public.fleet_audit_events(actor);
ALTER TABLE public.fleet_audit_events ENABLE ROW LEVEL SECURITY;
-- Hygiene, not redundancy: Supabase grants table privileges to anon
-- by default, and a privilege still applies where a policy is missing.
REVOKE ALL ON TABLE public.fleet_audit_events FROM anon;
DROP POLICY IF EXISTS fleet_audit_events_select ON public.fleet_audit_events;
CREATE POLICY fleet_audit_events_select ON public.fleet_audit_events
  FOR SELECT TO authenticated
  USING (
    actor = (SELECT auth.uid())
    OR public.fleet_role(org_id) = 'admin'
  );

-- ── Fleet expense RPCs (#4215, v14) ────────────────────────────────

-- Manager review: submitted -> approved | rejected, audited. Raised
-- messages are stable snake_case tokens the client maps to its own
-- translated wording; they are never shown verbatim.
CREATE OR REPLACE FUNCTION public.fleet_review_expense(
  p_id TEXT,
  p_user UUID,
  p_decision TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  org UUID;
  current_status TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_decision IS NULL OR p_decision NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'unknown_decision' USING ERRCODE = '22023';
  END IF;
  SELECT org_id, status INTO org, current_status
    FROM public.fleet_expenses
   WHERE user_id = p_user AND id = p_id;
  -- Same error for "no such expense" and "not yours to see", so this is
  -- not an existence oracle for other people's expense ids.
  IF org IS NULL THEN
    RAISE EXCEPTION 'expense_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF coalesce(public.fleet_role(org), '') NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  -- The device allows submitted -> approved | rejected and nothing
  -- else; the server agrees, so a draft cannot be approved even by a
  -- manager who guessed its id.
  IF current_status IS DISTINCT FROM 'submitted' THEN
    RAISE EXCEPTION 'not_submitted' USING ERRCODE = '22023';
  END IF;
  UPDATE public.fleet_expenses
     SET status = p_decision, updated_at = now()
   WHERE user_id = p_user AND id = p_id;
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (org, auth.uid(), 'expense_' || p_decision, p_id);
  RETURN p_decision;
END;
$$;
REVOKE ALL ON FUNCTION public.fleet_review_expense(TEXT, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_review_expense(TEXT, UUID, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_review_expense(TEXT, UUID, TEXT) FROM anon;

-- One audit row per signed URL the client asks Storage for (D5.4). Its
-- access test MIRRORS the object policy rather than merely checking
-- membership, so a row in the log means a URL was really issued: the
-- looser first version recorded an access for a manager asking after a
-- DRAFT receipt, which the bytes policy then refused, leaving an
-- auditor unable to tell a real access from a refused one.
-- It returns a boolean and never the URL: issuing the URL is the
-- Storage API's job, governed by the object policies, so a caller
-- cannot use this to obtain access it does not already have.
CREATE OR REPLACE FUNCTION public.fleet_log_document_access(p_document UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  org UUID;
  doc_owner UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  SELECT org_id, user_id INTO org, doc_owner
    FROM public.fleet_documents
   WHERE id = p_document AND deleted_at IS NULL;
  IF org IS NULL THEN
    RETURN FALSE;
  END IF;
  -- Mirror the READ rule exactly. "Any member of the org" was not
  -- enough: a manager asking for a DRAFT receipt they may never read
  -- got a 'document_signed_url' row and a TRUE while the object policy
  -- correctly refused the bytes, so the log claimed an access that
  -- never happened and an auditor could not tell the two apart. The
  -- owner always passes; anybody else needs the role on the
  -- document's org AND a non-draft expense of that org citing it.
  IF doc_owner IS DISTINCT FROM auth.uid() THEN
    IF coalesce(public.fleet_role(org), '') NOT IN ('manager', 'admin') THEN
      RETURN FALSE;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.fleet_expenses e
       WHERE e.org_id = org
         AND e.status <> 'draft'
         AND e.data ->> 'documentId' = p_document::text
    ) THEN
      RETURN FALSE;
    END IF;
  END IF;
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (org, auth.uid(), 'document_signed_url', p_document::text);
  RETURN TRUE;
END;
$$;
REVOKE ALL ON FUNCTION public.fleet_log_document_access(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_log_document_access(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_log_document_access(UUID) FROM anon;

-- ── Private receipt bucket (#4215, v14) ────────────────────────────
DO $fleet_storage$
BEGIN
  IF to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'storage schema absent - fleet-documents bucket skipped';
    RETURN;
  END IF;

  INSERT INTO storage.buckets (id, name, public)
       VALUES ('fleet-documents', 'fleet-documents', false)
  ON CONFLICT (id) DO UPDATE SET public = false;

  EXECUTE $p$DROP POLICY IF EXISTS fleet_documents_object_own ON storage.objects$p$;
  EXECUTE $p$
    CREATE POLICY fleet_documents_object_own ON storage.objects
      FOR ALL TO authenticated
      USING (bucket_id = 'fleet-documents' AND owner = (SELECT auth.uid()))
      WITH CHECK (
        bucket_id = 'fleet-documents'
        AND owner = (SELECT auth.uid())
        AND split_part(name, '/', 2) = (SELECT auth.uid())::text
      )
  $p$;

  EXECUTE $p$DROP POLICY IF EXISTS fleet_documents_object_manager_read ON storage.objects$p$;
  EXECUTE $p$
    CREATE POLICY fleet_documents_object_manager_read ON storage.objects
      FOR SELECT TO authenticated
      USING (
        bucket_id = 'fleet-documents'
        AND EXISTS (
          SELECT 1
            FROM public.fleet_documents d
            JOIN public.fleet_expenses e
              ON e.org_id = d.org_id
             AND e.data ->> 'documentId' = d.id::text
           WHERE d.object_key = storage.objects.name
             AND d.user_id = storage.objects.owner
             AND d.deleted_at IS NULL
             AND e.status <> 'draft'
             AND public.fleet_role(d.org_id) IN ('manager', 'admin')
        )
      )
  $p$;
END
$fleet_storage$;

CREATE TABLE IF NOT EXISTS public.tanksync_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.tanksync_meta ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tanksync_meta_read ON public.tanksync_meta;
CREATE POLICY tanksync_meta_read ON public.tanksync_meta
  FOR SELECT USING (true);
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '14', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();

