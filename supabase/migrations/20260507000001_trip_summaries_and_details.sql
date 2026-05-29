-- Trip recordings (OBD2 + GPS) synced across the user's linked devices.
-- Two-row split (#1479 phase 1):
--   public.trip_summaries — ~1 KB JSONB, queried for the trip-history list
--   public.trip_details   — full pointSamples + gpsSampleDiagnostics, lazy-loaded
-- Local-only by default; rows only land here once the user signs in to TankSync.
--
-- Applied to PROD on 2026-05-29 via MCP (it had been committed but never
-- pushed — the missing tables were the entire "trip sync not working" bug,
-- #2239). Every statement below is idempotent so a later `supabase db push`
-- reconciles cleanly against the already-applied schema.

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

ALTER TABLE public.trip_summaries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trip_summaries_own ON public.trip_summaries;
CREATE POLICY trip_summaries_own ON public.trip_summaries
  FOR ALL USING (user_id = auth.uid());

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

ALTER TABLE public.trip_details ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trip_details_own ON public.trip_details;
CREATE POLICY trip_details_own ON public.trip_details
  FOR ALL USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS trip_details_user_idx
  ON public.trip_details(user_id);
