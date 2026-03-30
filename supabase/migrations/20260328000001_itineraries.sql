-- Saved itineraries: routes prepared on one device, synced to others
CREATE TABLE IF NOT EXISTS public.itineraries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  waypoints JSONB NOT NULL,
  distance_km DOUBLE PRECISION NOT NULL,
  duration_minutes DOUBLE PRECISION NOT NULL,
  avoid_highways BOOLEAN DEFAULT false,
  fuel_type TEXT DEFAULT 'e10',
  selected_station_ids TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, name)
);

ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;

CREATE POLICY itineraries_own ON public.itineraries
  FOR ALL USING (user_id = auth.uid());

CREATE INDEX itineraries_user_idx ON public.itineraries(user_id);
CREATE INDEX itineraries_updated_idx ON public.itineraries(user_id, updated_at DESC);
