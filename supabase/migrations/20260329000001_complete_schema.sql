-- TankSync Complete Schema — v4.1.0
-- Run this in Supabase SQL Editor if tables are missing.
-- All CREATE TABLE use IF NOT EXISTS, so it's safe to run multiple times.

-- ═══════════════════════════════════════════════════════════════════
-- TABLES
-- ═══════════════════════════════════════════════════════════════════

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

CREATE TABLE IF NOT EXISTS public.price_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  station_id TEXT NOT NULL,
  country_code TEXT NOT NULL DEFAULT 'DE',
  fuel_type TEXT NOT NULL,
  reported_price DOUBLE PRECISION NOT NULL,
  is_validated BOOLEAN DEFAULT false,
  reported_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.push_tokens (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  ntfy_topic TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sync_settings (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sync_favorites BOOLEAN NOT NULL DEFAULT true,
  sync_alerts BOOLEAN NOT NULL DEFAULT true,
  sync_history BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS public.database_owner (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_database_owner_singleton
  ON public.database_owner ((true));

-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ignored_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.station_ratings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts on re-run
DO $$ BEGIN
  DROP POLICY IF EXISTS users_own ON public.users;
  DROP POLICY IF EXISTS favorites_own ON public.favorites;
  DROP POLICY IF EXISTS alerts_own ON public.alerts;
  DROP POLICY IF EXISTS reports_insert ON public.price_reports;
  DROP POLICY IF EXISTS reports_read ON public.price_reports;
  DROP POLICY IF EXISTS push_own ON public.push_tokens;
  DROP POLICY IF EXISTS sync_own ON public.sync_settings;
  DROP POLICY IF EXISTS snapshots_read ON public.price_snapshots;
  DROP POLICY IF EXISTS snapshots_insert ON public.price_snapshots;
  DROP POLICY IF EXISTS itineraries_own ON public.itineraries;
  DROP POLICY IF EXISTS ignored_own ON public.ignored_stations;
  DROP POLICY IF EXISTS ratings_own ON public.station_ratings;
  DROP POLICY IF EXISTS ratings_shared_read ON public.station_ratings;
END $$;

CREATE POLICY users_own ON public.users FOR ALL USING (id = auth.uid());
CREATE POLICY favorites_own ON public.favorites FOR ALL USING (user_id = auth.uid());
CREATE POLICY alerts_own ON public.alerts FOR ALL USING (user_id = auth.uid());
CREATE POLICY reports_insert ON public.price_reports FOR INSERT WITH CHECK (reporter_id = auth.uid());
CREATE POLICY reports_read ON public.price_reports FOR SELECT USING (true);
CREATE POLICY push_own ON public.push_tokens FOR ALL USING (user_id = auth.uid());
CREATE POLICY sync_own ON public.sync_settings FOR ALL USING (user_id = auth.uid());
CREATE POLICY snapshots_read ON public.price_snapshots FOR SELECT USING (true);
CREATE POLICY snapshots_insert ON public.price_snapshots FOR INSERT WITH CHECK (auth.role() = 'service_role');
CREATE POLICY itineraries_own ON public.itineraries FOR ALL USING (user_id = auth.uid());
CREATE POLICY ignored_own ON public.ignored_stations FOR ALL USING (user_id = auth.uid());
CREATE POLICY ratings_own ON public.station_ratings FOR ALL USING (user_id = auth.uid());
CREATE POLICY ratings_shared_read ON public.station_ratings FOR SELECT USING (is_shared = true OR user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_favorites_user ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_station ON public.favorites(station_id);
CREATE INDEX IF NOT EXISTS idx_alerts_user ON public.alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_station ON public.alerts(station_id);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON public.alerts(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_snapshots_station ON public.price_snapshots(station_id);
CREATE INDEX IF NOT EXISTS idx_snapshots_recorded ON public.price_snapshots(recorded_at);
CREATE INDEX IF NOT EXISTS idx_snapshots_station_time ON public.price_snapshots(station_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_station ON public.price_reports(station_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_at ON public.price_reports(reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_itineraries_user ON public.itineraries(user_id);
CREATE INDEX IF NOT EXISTS idx_itineraries_updated ON public.itineraries(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ignored_user ON public.ignored_stations(user_id);
CREATE INDEX IF NOT EXISTS idx_ignored_station ON public.ignored_stations(station_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user ON public.station_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_station ON public.station_ratings(station_id);
CREATE INDEX IF NOT EXISTS idx_ratings_shared ON public.station_ratings(is_shared) WHERE is_shared = true;
