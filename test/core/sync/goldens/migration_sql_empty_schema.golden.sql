-- TankSync Schema Setup (schema version 9)
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

ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'fuel';
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS data JSONB;

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
ALTER TABLE public.deletions ENABLE ROW LEVEL SECURITY;

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

-- Deletion tombstones (#3078): a user only ever sees / writes their own.
DROP POLICY IF EXISTS deletions_own ON public.deletions;
CREATE POLICY deletions_own ON public.deletions
  FOR ALL USING (user_id = auth.uid());

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
  VALUES ('schema_version', '9', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();

