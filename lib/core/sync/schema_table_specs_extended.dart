// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Optional-table specs of the TankSync schema — the tables opt-in
/// features (history, ratings, trips, sharing, push, reports) write.
/// Their absence degrades a feature rather than breaking core sync, but
/// the wizard SQL still creates every one so a self-hoster ends up with
/// a complete schema. Data half of `schema_table_specs.dart`; the SQL
/// text is byte-identical to the pre-refactor `tableSql` / `rlsSql`
/// blocks (pinned by `test/core/sync/schema_sql_golden_test.dart`).
library;

import 'schema_table_specs.dart';

/// Optional tables, in wizard-SQL emission order.
const List<SyncedTableSpec> extendedTableSpecs = [
  (
    name: 'itineraries',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS itineraries_own ON public.itineraries;
CREATE POLICY itineraries_own ON public.itineraries
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'ignored_stations',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.ignored_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS ignored_own ON public.ignored_stations;
CREATE POLICY ignored_own ON public.ignored_stations
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'station_ratings',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.station_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  is_shared BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS ratings_own ON public.station_ratings;
CREATE POLICY ratings_own ON public.station_ratings
  FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS ratings_shared_read ON public.station_ratings;
CREATE POLICY ratings_shared_read ON public.station_ratings
  FOR SELECT USING (is_shared = true OR user_id = auth.uid());''',
  ),
  (
    name: 'price_reports',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
-- Price reports: anyone reads, reporter inserts their own.
DROP POLICY IF EXISTS reports_read ON public.price_reports;
CREATE POLICY reports_read ON public.price_reports
  FOR SELECT USING (true);
DROP POLICY IF EXISTS reports_insert ON public.price_reports;
CREATE POLICY reports_insert ON public.price_reports
  FOR INSERT WITH CHECK (reporter_id = auth.uid());''',
  ),
  (
    name: 'push_tokens',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.push_tokens (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  ntfy_topic TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS push_own ON public.push_tokens;
CREATE POLICY push_own ON public.push_tokens
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'obd2_baselines',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS obd2_baselines_own ON public.obd2_baselines;
CREATE POLICY obd2_baselines_own ON public.obd2_baselines
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'trip_summaries',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS trip_summaries_own ON public.trip_summaries;
CREATE POLICY trip_summaries_own ON public.trip_summaries
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'trip_details',
    isRequired: false,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.trip_details (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS trip_details_user_idx
  ON public.trip_details(user_id);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS trip_details_own ON public.trip_details;
CREATE POLICY trip_details_own ON public.trip_details
  FOR ALL USING (user_id = auth.uid());''',
  ),
  // The trip_shares policy block also carries the additive shared-read
  // policies ON trip_summaries / trip_details: a recipient may read a
  // shared trip (never write). They exist because of the sharing grant
  // rows, so they live (and are emitted) with the trip_shares spec.
  (
    name: 'trip_shares',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
-- Trip shares: owner has full CRUD over rows they created; the recipient
-- may only READ a grant pointing at them.
DROP POLICY IF EXISTS trip_shares_owner_select ON public.trip_shares;
CREATE POLICY trip_shares_owner_select ON public.trip_shares
  FOR SELECT USING (owner_id = auth.uid());
DROP POLICY IF EXISTS trip_shares_owner_insert ON public.trip_shares;
CREATE POLICY trip_shares_owner_insert ON public.trip_shares
  FOR INSERT WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS trip_shares_owner_update ON public.trip_shares;
CREATE POLICY trip_shares_owner_update ON public.trip_shares
  FOR UPDATE USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS trip_shares_owner_delete ON public.trip_shares;
CREATE POLICY trip_shares_owner_delete ON public.trip_shares
  FOR DELETE USING (owner_id = auth.uid());
DROP POLICY IF EXISTS trip_shares_recipient_select ON public.trip_shares;
CREATE POLICY trip_shares_recipient_select ON public.trip_shares
  FOR SELECT USING (shared_with_id = auth.uid());

-- Additive read access so a recipient can read a shared trip (never write).
DROP POLICY IF EXISTS trip_summaries_shared_read ON public.trip_summaries;
CREATE POLICY trip_summaries_shared_read ON public.trip_summaries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_summaries.id
        AND s.shared_with_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS trip_details_shared_read ON public.trip_details;
CREATE POLICY trip_details_shared_read ON public.trip_details
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_details.id
        AND s.shared_with_id = auth.uid()
    )
  );''',
  ),
  // #3726 (v7) — in-app "Report content" rows for community UGC (Play
  // UGC-policy prerequisite). The reporter files a row naming the content
  // (`target_kind`/`target_id`); the operator reviews out-of-band.
  (
    name: 'content_reports',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
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
  FOR DELETE USING (reporter_user_id = auth.uid());''',
  ),
  // #3078 — deletion tombstones. One row per deleted record so a delete on
  // one device doesn't resurrect from another's still-local copy through the
  // union merge. The owning sync class records a tombstone on delete and
  // filters server rows against these ids before the union.
  (
    name: 'deletions',
    isRequired: false,
    createSql: '''
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
''',
    rlsPolicySql: '''
-- Deletion tombstones (#3078): a user only ever sees / writes their own.
DROP POLICY IF EXISTS deletions_own ON public.deletions;
CREATE POLICY deletions_own ON public.deletions
  FOR ALL USING (user_id = auth.uid());''',
  ),
];
