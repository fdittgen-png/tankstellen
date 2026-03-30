-- Performance indexes for common queries
CREATE INDEX idx_favorites_user ON public.favorites(user_id);
CREATE INDEX idx_favorites_station ON public.favorites(station_id);
CREATE INDEX idx_alerts_user ON public.alerts(user_id);
CREATE INDEX idx_alerts_station ON public.alerts(station_id);
CREATE INDEX idx_alerts_active ON public.alerts(is_active) WHERE is_active = true;
CREATE INDEX idx_snapshots_station ON public.price_snapshots(station_id);
CREATE INDEX idx_snapshots_recorded ON public.price_snapshots(recorded_at);
CREATE INDEX idx_snapshots_station_time ON public.price_snapshots(station_id, recorded_at DESC);
CREATE INDEX idx_reports_station ON public.price_reports(station_id);
CREATE INDEX idx_reports_reported_at ON public.price_reports(reported_at DESC);

-- Auto-cleanup: delete price snapshots older than 90 days
-- (Run via pg_cron or scheduled Edge Function)
