-- Row Level Security -- users can ONLY see/modify their own data

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_settings ENABLE ROW LEVEL SECURITY;
-- price_snapshots is read-only public (aggregate data)
ALTER TABLE public.price_snapshots ENABLE ROW LEVEL SECURITY;

-- Users: can only read own record
CREATE POLICY users_own ON public.users FOR ALL USING (id = auth.uid());

-- Favorites: full CRUD on own data
CREATE POLICY favorites_own ON public.favorites FOR ALL USING (user_id = auth.uid());

-- Alerts: full CRUD on own data
CREATE POLICY alerts_own ON public.alerts FOR ALL USING (user_id = auth.uid());

-- Price reports: insert own, read all (community data)
CREATE POLICY reports_insert ON public.price_reports FOR INSERT WITH CHECK (reporter_id = auth.uid());
CREATE POLICY reports_read ON public.price_reports FOR SELECT USING (true);

-- Push tokens: full CRUD on own data
CREATE POLICY push_own ON public.push_tokens FOR ALL USING (user_id = auth.uid());

-- Sync settings: full CRUD on own data
CREATE POLICY sync_own ON public.sync_settings FOR ALL USING (user_id = auth.uid());

-- Price snapshots: read-only for all authenticated users
CREATE POLICY snapshots_read ON public.price_snapshots FOR SELECT USING (true);
-- Only service role can insert (Edge Functions)
CREATE POLICY snapshots_insert ON public.price_snapshots FOR INSERT WITH CHECK (auth.role() = 'service_role');
