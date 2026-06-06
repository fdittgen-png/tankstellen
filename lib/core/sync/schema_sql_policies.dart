// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// RLS policies + SECURITY DEFINER RPCs for the TankSync schema, split out of
/// `schema_sql.dart` (which holds the CREATE TABLE blocks) to keep each file
/// reviewable under the line cap. Both are always (idempotently) re-asserted
/// by the wizard so re-running the setup SQL repairs drifted policies.
library;

/// Row-level security: enables RLS + own-row / shared-read policies on every
/// table. Idempotent via DROP POLICY IF EXISTS so the wizard can re-assert
/// policies even when the tables already exist.
const String rlsSql = '''
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
  );
''';

/// SECURITY DEFINER RPCs the trip-sharing sync code calls
/// (`resolve_share_recipient`, `claim_trip_share`). Without these the
/// account-to-account and link-claim share flows fail on a self-host.
const String rpcSql = '''
-- ── Trip-sharing RPCs ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.resolve_share_recipient(recipient_email TEXT)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS \$\$
  SELECT id FROM auth.users
  WHERE lower(email) = lower(trim(recipient_email))
  LIMIT 1;
\$\$;
REVOKE ALL ON FUNCTION public.resolve_share_recipient(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) FROM anon;

CREATE OR REPLACE FUNCTION public.claim_trip_share(token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
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
\$\$;
REVOKE ALL ON FUNCTION public.claim_trip_share(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_trip_share(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.claim_trip_share(TEXT) FROM anon;
''';
