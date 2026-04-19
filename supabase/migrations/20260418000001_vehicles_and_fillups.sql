-- Vehicles + consumption fill-ups synced across the user's linked devices.
-- Profiles are intentionally NOT synced — each device keeps its own active
-- profile and per-device defaults (fuel, radius, landing screen).

CREATE TABLE IF NOT EXISTS public.vehicles (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);

ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY vehicles_own ON public.vehicles
  FOR ALL USING (user_id = auth.uid());

CREATE INDEX vehicles_user_idx ON public.vehicles(user_id);

CREATE TABLE IF NOT EXISTS public.fill_ups (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  vehicle_id TEXT,
  recorded_at TIMESTAMPTZ NOT NULL,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);

ALTER TABLE public.fill_ups ENABLE ROW LEVEL SECURITY;

CREATE POLICY fill_ups_own ON public.fill_ups
  FOR ALL USING (user_id = auth.uid());

CREATE INDEX fill_ups_user_idx ON public.fill_ups(user_id);
CREATE INDEX fill_ups_user_date_idx ON public.fill_ups(user_id, recorded_at DESC);
