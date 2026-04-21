-- Per-vehicle OBD2 consumption baselines (#780).
--
-- One JSON payload per (user, vehicle) pair holding the Welford
-- accumulators keyed by driving situation. The `total_samples`
-- column surfaces the summed sample count across every situation so
-- server-side queries can pick a winner without decoding the JSON.
--
-- Merge rule on conflict: prefer the payload whose per-situation
-- sample count is higher. The Dart client resolves this per
-- situation (a device that drove more highway may have less urban
-- data), so the server copy is authoritative only after the client
-- has folded its own samples in.

CREATE TABLE IF NOT EXISTS public.obd2_baselines (
  vehicle_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_samples INTEGER NOT NULL DEFAULT 0,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, vehicle_id)
);

ALTER TABLE public.obd2_baselines ENABLE ROW LEVEL SECURITY;

CREATE POLICY obd2_baselines_own ON public.obd2_baselines
  FOR ALL USING (user_id = auth.uid());

CREATE INDEX obd2_baselines_user_idx ON public.obd2_baselines(user_id);
