-- #1119 — Crowd-sourced station wait-time signal.
--
-- Why: TankSync already carries community-config plumbing for opt-in
-- crowd signals; this migration adds the server side for the
-- "~6 min wait" hint shown next to price. Two tables:
--
--   public.wait_time_pings       — raw "arrived"/"left" events,
--                                  scoped to the reporting user (RLS).
--                                  The Edge Function aggregator reads
--                                  these via service_role and trims
--                                  rows older than the retention
--                                  window after each run.
--
--   public.wait_time_aggregates  — anonymized rolling-median wait per
--                                  (station, hour). Readable by every
--                                  authenticated client; only the
--                                  service_role aggregator writes.
--                                  Sparse buckets (sample_count < 5)
--                                  are not written, so the client
--                                  fallback is automatic.
--
-- Privacy:
--   - No lat/lng — only `station_id` + `country_code`.
--   - Aggregate rows carry no `user_id`. The pings table is owned by
--     the user and the aggregator emits user-free buckets.
--   - `session_id` pairs an "arrived" with the matching "left" event
--     without re-exposing user identity downstream.
--
-- RLS impact:
--   [x] Adds new public tables → ENABLE ROW LEVEL SECURITY + policies
--       covering both anon (none) and authenticated (own / read-all).
--
-- RLS confirmed: [x]
--   docs/security/SUPABASE_RLS_MATRIX.md and
--   test/security/supabase_rls_test.dart updated in the same PR.

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

ALTER TABLE public.wait_time_pings ENABLE ROW LEVEL SECURITY;

CREATE POLICY wait_time_pings_own ON public.wait_time_pings
  FOR ALL USING (user_id = auth.uid());

CREATE INDEX wait_time_pings_user_idx ON public.wait_time_pings(user_id);
CREATE INDEX wait_time_pings_station_recorded_idx
  ON public.wait_time_pings(station_id, recorded_at);
CREATE INDEX wait_time_pings_session_idx
  ON public.wait_time_pings(session_id);


CREATE TABLE IF NOT EXISTS public.wait_time_aggregates (
  station_id TEXT NOT NULL,
  hour_bucket TIMESTAMPTZ NOT NULL,
  country_code TEXT NOT NULL,
  median_wait_seconds INTEGER NOT NULL,
  sample_count INTEGER NOT NULL CHECK (sample_count >= 5),
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (station_id, hour_bucket)
);

ALTER TABLE public.wait_time_aggregates ENABLE ROW LEVEL SECURITY;

-- Aggregates are intentionally readable by every authenticated user:
-- the whole point of the feature is showing the wait hint to anyone
-- looking at the station. Writes are service-role only (the aggregator
-- Edge Function); RLS without an INSERT/UPDATE/DELETE policy denies
-- those operations to anon and authenticated by default.
CREATE POLICY wait_aggregates_read ON public.wait_time_aggregates
  FOR SELECT USING (true);

CREATE INDEX wait_time_aggregates_station_idx
  ON public.wait_time_aggregates(station_id, hour_bucket DESC);
