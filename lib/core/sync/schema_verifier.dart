import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

/// Verifies that the required TankSync database schema exists.
///
/// When connecting to a Supabase database for the first time, the tables
/// may not exist yet (user hasn't run migrations). This class detects
/// missing tables and provides the SQL to create them.
class SchemaVerifier {
  SchemaVerifier._();

  /// Required tables for TankSync to function.
  static const requiredTables = [
    'users',
    'favorites',
    'alerts',
    'price_snapshots',
    'push_tokens',
    'sync_settings',
  ];

  /// Optional tables that enhance functionality but aren't required.
  static const optionalTables = [
    'price_reports',
    'itineraries',
    'ignored_stations',
    'station_ratings',
    'database_owner',
  ];

  /// Check which required tables exist in the database.
  ///
  /// Returns a map of table name → exists (true/false).
  /// Returns null if the client is not connected.
  static Future<Map<String, bool>?> checkSchema() async {
    final client = TankSyncClient.client;
    if (client == null) return null;

    final result = <String, bool>{};
    for (final table in [...requiredTables, ...optionalTables]) {
      try {
        await client.from(table).select('*').limit(0);
        result[table] = true;
      } catch (e) { debugPrint('SchemaVerifier: table check failed: $e');
        result[table] = false;
      }
    }

    debugPrint('SchemaVerifier: ${result.entries.where((e) => e.value).length}/${result.length} tables found');
    return result;
  }

  /// Whether all required tables exist.
  static Future<bool> isSchemaReady() async {
    final schema = await checkSchema();
    if (schema == null) return false;
    return requiredTables.every((t) => schema[t] == true);
  }

  /// SQL to create all missing tables. User can copy-paste this into
  /// the Supabase SQL editor (Dashboard → SQL Editor → New Query).
  static String getMigrationSql(Map<String, bool> schema) {
    final buffer = StringBuffer();
    buffer.writeln('-- TankSync Schema Setup');
    buffer.writeln('-- Run this in your Supabase SQL Editor');
    buffer.writeln('-- Dashboard → SQL Editor → New Query → Paste → Run');
    buffer.writeln();

    if (schema['users'] != true) {
      buffer.writeln(_usersSql);
    }
    if (schema['favorites'] != true) {
      buffer.writeln(_favoritesSql);
    }
    if (schema['alerts'] != true) {
      buffer.writeln(_alertsSql);
    }
    if (schema['price_snapshots'] != true) {
      buffer.writeln(_priceSnapshotsSql);
    }
    if (schema['push_tokens'] != true) {
      buffer.writeln(_pushTokensSql);
    }
    if (schema['sync_settings'] != true) {
      buffer.writeln(_syncSettingsSql);
    }
    if (schema['itineraries'] != true) {
      buffer.writeln(_itinerariesSql);
    }
    if (schema['ignored_stations'] != true) {
      buffer.writeln(_ignoredStationsSql);
    }
    if (schema['station_ratings'] != true) {
      buffer.writeln(_stationRatingsSql);
    }

    // RLS policies
    buffer.writeln(_rlsSql);

    return buffer.toString();
  }

  // --- SQL fragments ---

  static const _usersSql = '''
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''';

  static const _favoritesSql = '''
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  station_name TEXT,
  country_code TEXT NOT NULL DEFAULT 'DE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''';

  static const _alertsSql = '''
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
''';

  static const _priceSnapshotsSql = '''
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
''';

  static const _pushTokensSql = '''
CREATE TABLE IF NOT EXISTS public.push_tokens (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  ntfy_topic TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''';

  static const _syncSettingsSql = '''
CREATE TABLE IF NOT EXISTS public.sync_settings (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sync_favorites BOOLEAN NOT NULL DEFAULT true,
  sync_alerts BOOLEAN NOT NULL DEFAULT true,
  sync_history BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''';

  static const _itinerariesSql = '''
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
''';

  static const _ignoredStationsSql = '''
CREATE TABLE IF NOT EXISTS public.ignored_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''';

  static const _stationRatingsSql = '''
CREATE TABLE IF NOT EXISTS public.station_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  is_shared BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''';

  static const _rlsSql = '''
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ignored_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.station_ratings ENABLE ROW LEVEL SECURITY;

-- Users: own record only
CREATE POLICY IF NOT EXISTS "users_own" ON public.users FOR ALL USING (id = auth.uid());

-- Favorites: own data only
CREATE POLICY IF NOT EXISTS "favorites_own" ON public.favorites FOR ALL USING (user_id = auth.uid());

-- Alerts: own data only
CREATE POLICY IF NOT EXISTS "alerts_own" ON public.alerts FOR ALL USING (user_id = auth.uid());

-- Price snapshots: read all, no user writes (service_role only)
CREATE POLICY IF NOT EXISTS "snapshots_read" ON public.price_snapshots FOR SELECT USING (true);

-- Push tokens: own data only
CREATE POLICY IF NOT EXISTS "push_own" ON public.push_tokens FOR ALL USING (user_id = auth.uid());

-- Sync settings: own data only
CREATE POLICY IF NOT EXISTS "sync_own" ON public.sync_settings FOR ALL USING (user_id = auth.uid());

-- Itineraries: own data only
CREATE POLICY IF NOT EXISTS "itineraries_own" ON public.itineraries FOR ALL USING (user_id = auth.uid());

-- Ignored stations: own data only
CREATE POLICY IF NOT EXISTS "ignored_own" ON public.ignored_stations FOR ALL USING (user_id = auth.uid());

-- Station ratings: own data for write, shared ratings readable by all
CREATE POLICY IF NOT EXISTS "ratings_own_write" ON public.station_ratings FOR ALL USING (user_id = auth.uid());
CREATE POLICY IF NOT EXISTS "ratings_shared_read" ON public.station_ratings FOR SELECT USING (is_shared = true OR user_id = auth.uid());
''';
}
