// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The complete TankSync (self-hosted Supabase) schema, expressed as the
/// idempotent SQL a self-hoster pastes into their Supabase SQL Editor.
///
/// This file is the wizard's single source of truth and must stay a
/// **superset** of every table the sync code (`lib/core/sync/*.dart`)
/// `.from()`s — see `schema_verifier.dart` + the completeness drift-guard
/// test (`test/core/sync/schema_verifier_completeness_test.dart`).
///
/// It mirrors `supabase/migrations/*.sql`; when a migration adds a synced
/// table, RLS policy or RPC, the matching block here must be updated so the
/// wizard SQL keeps creating a working schema. Every statement is
/// idempotent (`CREATE TABLE IF NOT EXISTS`, `DROP POLICY IF EXISTS … CREATE
/// POLICY`, `CREATE OR REPLACE FUNCTION`) so a self-hoster can re-run it
/// safely after a schema bump.
library;

import 'schema_sql_policies.dart';

/// Bumped whenever the wizard SQL below changes in a way an existing
/// self-hoster must re-apply (a new table, RLS policy or RPC). The wizard
/// SQL records this into `public.tanksync_meta`; the verifier reads it back
/// and warns when a self-hoster's recorded version is older — turning what
/// used to be silent per-table breakage into a clear "re-run the setup SQL"
/// signal. See `SchemaVerifier.checkSchemaVersion`.
/// v4 (#3125): `deletions.device_id` + `deletions.app_version` forensic
/// columns (which install deleted a record, on which build).
/// v5 (#3452): `favorites.kind` (fuel | ev — EV favorites join the sync)
/// + `favorites.data` (JSONB station payload, so a favorite pulled on a
/// second device renders name/coords immediately).
const int kSupabaseSchemaVersion = 5;

/// The metadata table that records the applied schema version. Readable by
/// anyone (it carries no user data — only the schema version the verifier
/// probes); writes happen via the SQL editor / service_role, so the read-only
/// RLS policy keeps it from being an RLS-enabled-but-policy-less table.
const String _metaSql = '''
CREATE TABLE IF NOT EXISTS public.tanksync_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.tanksync_meta ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tanksync_meta_read ON public.tanksync_meta;
CREATE POLICY tanksync_meta_read ON public.tanksync_meta
  FOR SELECT USING (true);
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '$kSupabaseSchemaVersion', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
''';

/// CREATE TABLE blocks keyed by table name. Every table the sync code
/// `.from()`s must appear here (the completeness test enforces this).
const Map<String, String> tableSql = {
  'users': '''
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
  // #3452 (v5): `kind` discriminates fuel vs EV favorites in the ONE
  // table; `data` carries the full station JSON payload.
  'favorites': '''
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  station_name TEXT,
  country_code TEXT NOT NULL DEFAULT 'DE',
  kind TEXT NOT NULL DEFAULT 'fuel',
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''',
  'alerts': '''
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
''',
  'price_snapshots': '''
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
''',
  'sync_settings': '''
CREATE TABLE IF NOT EXISTS public.sync_settings (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sync_favorites BOOLEAN NOT NULL DEFAULT true,
  sync_alerts BOOLEAN NOT NULL DEFAULT true,
  sync_history BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
  'vehicles': '''
CREATE TABLE IF NOT EXISTS public.vehicles (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS vehicles_user_idx ON public.vehicles(user_id);
''',
  'fill_ups': '''
CREATE TABLE IF NOT EXISTS public.fill_ups (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  vehicle_id TEXT,
  recorded_at TIMESTAMPTZ NOT NULL,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS fill_ups_user_idx ON public.fill_ups(user_id);
CREATE INDEX IF NOT EXISTS fill_ups_user_date_idx
  ON public.fill_ups(user_id, recorded_at DESC);
''',
  'itineraries': '''
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
''',
  'ignored_stations': '''
CREATE TABLE IF NOT EXISTS public.ignored_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''',
  'station_ratings': '''
CREATE TABLE IF NOT EXISTS public.station_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  is_shared BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, station_id)
);
''',
  'price_reports': '''
CREATE TABLE IF NOT EXISTS public.price_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  station_id TEXT NOT NULL,
  country_code TEXT NOT NULL DEFAULT 'DE',
  fuel_type TEXT NOT NULL,
  reported_price DOUBLE PRECISION,
  correction_text TEXT,
  is_validated BOOLEAN DEFAULT false,
  reported_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
  'push_tokens': '''
CREATE TABLE IF NOT EXISTS public.push_tokens (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  ntfy_topic TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
  'obd2_baselines': '''
CREATE TABLE IF NOT EXISTS public.obd2_baselines (
  vehicle_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_samples INTEGER NOT NULL DEFAULT 0,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, vehicle_id)
);
CREATE INDEX IF NOT EXISTS obd2_baselines_user_idx
  ON public.obd2_baselines(user_id);
''',
  'trip_summaries': '''
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
CREATE INDEX IF NOT EXISTS trip_summaries_user_idx
  ON public.trip_summaries(user_id);
CREATE INDEX IF NOT EXISTS trip_summaries_user_started_idx
  ON public.trip_summaries(user_id, started_at DESC);
''',
  'trip_details': '''
CREATE TABLE IF NOT EXISTS public.trip_details (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS trip_details_user_idx
  ON public.trip_details(user_id);
''',
  'trip_shares': '''
CREATE TABLE IF NOT EXISTS public.trip_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shared_with_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  share_token TEXT UNIQUE,
  permission TEXT NOT NULL DEFAULT 'read',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS trip_shares_unique_direct_idx
  ON public.trip_shares(trip_id, owner_id, shared_with_id)
  WHERE shared_with_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS trip_shares_owner_idx
  ON public.trip_shares(owner_id);
CREATE INDEX IF NOT EXISTS trip_shares_recipient_idx
  ON public.trip_shares(shared_with_id);
CREATE INDEX IF NOT EXISTS trip_shares_trip_recipient_idx
  ON public.trip_shares(trip_id, shared_with_id);
''',
  // #3078 — deletion tombstones. One row per deleted record so a delete on
  // one device doesn't resurrect from another's still-local copy through the
  // union merge. The owning sync class records a tombstone on delete and
  // filters server rows against these ids before the union.
  'deletions': '''
CREATE TABLE IF NOT EXISTS public.deletions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  deleted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  device_id TEXT,
  app_version TEXT,
  UNIQUE(user_id, table_name, record_id)
);
CREATE INDEX IF NOT EXISTS deletions_user_table_idx
  ON public.deletions(user_id, table_name);
''',
};

/// Idempotent column adds for tables that may pre-exist with an older
/// shape. [buildMigrationSql] SKIPS the `CREATE TABLE` block of any table
/// the verifier already found, so a column added to an existing table
/// would never reach a self-hoster who re-runs the wizard — these `ALTER
/// TABLE … ADD COLUMN IF NOT EXISTS` statements are emitted
/// **unconditionally** (like the RLS/RPC blocks) to close that gap.
///
/// v4 (#3125): forensic origin stamps on tombstones.
/// v5 (#3452): EV favorites + station payloads on the favorites table.
const String upgradeSql = '''
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'fuel';
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS data JSONB;
''';

/// Builds the wizard SQL. [schema] maps table name → already-exists; a table
/// already present is skipped for the CREATE TABLE block (but RLS/RPCs are
/// always re-asserted, idempotently). A missing/empty map emits every table.
String buildMigrationSql(Map<String, bool> schema) {
  final buffer = StringBuffer()
    ..writeln('-- TankSync Schema Setup'
        ' (schema version $kSupabaseSchemaVersion)')
    ..writeln('-- Run this in your Supabase SQL Editor')
    ..writeln('-- Dashboard → SQL Editor → New Query → Paste → Run')
    ..writeln();

  for (final entry in tableSql.entries) {
    if (schema[entry.key] != true) {
      buffer.writeln(entry.value);
    }
  }

  buffer
    ..writeln(upgradeSql)
    ..writeln(rlsSql)
    ..writeln(rpcSql)
    ..writeln(_metaSql);

  return buffer.toString();
}
