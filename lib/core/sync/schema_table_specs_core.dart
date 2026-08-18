// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Required-table specs of the TankSync schema — the tables core sync
/// needs before it can function at all (a missing one means the wizard
/// SQL has not been run). Data half of `schema_table_specs.dart`; the
/// SQL text is byte-identical to the pre-refactor `tableSql` / `rlsSql`
/// blocks (pinned by `test/core/sync/schema_sql_golden_test.dart`).
library;

import 'schema_table_specs.dart';

/// Core tables, in wizard-SQL emission order.
const List<SyncedTableSpec> coreTableSpecs = [
  (
    name: 'users',
    isRequired: true,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS users_own ON public.users;
CREATE POLICY users_own ON public.users FOR ALL USING (id = auth.uid());''',
  ),
  // #3452 (v5): `kind` discriminates fuel vs EV favorites in the ONE
  // table; `data` carries the full station JSON payload.
  (
    name: 'favorites',
    isRequired: true,
    createSql: '''
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
    rlsPolicySql: '''
DROP POLICY IF EXISTS favorites_own ON public.favorites;
CREATE POLICY favorites_own ON public.favorites
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'alerts',
    isRequired: true,
    createSql: '''
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
    rlsPolicySql: '''
DROP POLICY IF EXISTS alerts_own ON public.alerts;
CREATE POLICY alerts_own ON public.alerts
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'price_snapshots',
    isRequired: true,
    createSql: '''
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
    rlsPolicySql: '''
-- Price snapshots: readable by all; only service_role writes.
DROP POLICY IF EXISTS snapshots_read ON public.price_snapshots;
CREATE POLICY snapshots_read ON public.price_snapshots
  FOR SELECT USING (true);''',
  ),
  (
    name: 'sync_settings',
    isRequired: true,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.sync_settings (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sync_favorites BOOLEAN NOT NULL DEFAULT true,
  sync_alerts BOOLEAN NOT NULL DEFAULT true,
  sync_history BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS sync_own ON public.sync_settings;
CREATE POLICY sync_own ON public.sync_settings
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'vehicles',
    isRequired: true,
    createSql: '''
CREATE TABLE IF NOT EXISTS public.vehicles (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS vehicles_user_idx ON public.vehicles(user_id);
''',
    rlsPolicySql: '''
DROP POLICY IF EXISTS vehicles_own ON public.vehicles;
CREATE POLICY vehicles_own ON public.vehicles
  FOR ALL USING (user_id = auth.uid());''',
  ),
  (
    name: 'fill_ups',
    isRequired: true,
    createSql: '''
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
    rlsPolicySql: '''
DROP POLICY IF EXISTS fill_ups_own ON public.fill_ups;
CREATE POLICY fill_ups_own ON public.fill_ups
  FOR ALL USING (user_id = auth.uid());''',
  ),
];
