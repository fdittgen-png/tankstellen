-- Seed data for local development and testing
-- Run with: supabase db reset (applies migrations + seed)

-- Test user
INSERT INTO public.users (id) VALUES ('00000000-0000-0000-0000-000000000001');

-- Test favorites
INSERT INTO public.favorites (user_id, station_id, station_name, country_code)
VALUES ('00000000-0000-0000-0000-000000000001', 'test-station-1', 'STAR Tankstelle Berlin', 'DE');

-- Test alert
INSERT INTO public.alerts (user_id, station_id, station_name, fuel_type, target_price)
VALUES ('00000000-0000-0000-0000-000000000001', 'test-station-1', 'STAR Tankstelle Berlin', 'e10', 1.50);
