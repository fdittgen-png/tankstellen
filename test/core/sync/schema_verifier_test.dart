// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';

void main() {
  group('SchemaVerifier - table lists', () {
    test('requiredTables covers the core synced tables', () {
      expect(SchemaVerifier.requiredTables, containsAll([
        'users',
        'favorites',
        'alerts',
        'price_snapshots',
        'sync_settings',
        'vehicles',
        'fill_ups',
      ]));
    });

    test('optionalTables covers the opt-in synced tables', () {
      expect(SchemaVerifier.optionalTables, containsAll([
        'itineraries',
        'ignored_stations',
        'station_ratings',
        'price_reports',
        'push_tokens',
        'obd2_baselines',
        'trip_summaries',
        'trip_details',
        'trip_shares',
        'content_reports',
      ]));
    });

    test('database_owner is NOT listed — the app never reads it', () {
      // #2929 — it is only read by the is_database_owner() SQL function /
      // trigger, never `.from()`d by the client, so listing it made the
      // verifier flag a "missing" table the app does not use.
      expect(SchemaVerifier.allTables, isNot(contains('database_owner')));
    });
  });

  /// #2310/#2929 — checkSchema fires its per-table existence probes in
  /// parallel via Future.wait, now via a column-agnostic `count()` HEAD
  /// request. The live probes need a Supabase client, so the only pure
  /// surface is the unconnected guard — these pin the do-no-harm contract.
  group('SchemaVerifier.checkSchema — unconnected guard (#2310)', () {
    test('returns null when no client is connected', () async {
      final schema = await SchemaVerifier.checkSchema();
      expect(schema, isNull,
          reason: 'no client → null, so callers fall back to the '
              'not-ready render path rather than throwing');
    });

    test('isSchemaReady returns false when unconnected', () async {
      expect(await SchemaVerifier.isSchemaReady(), isFalse);
    });

    // #2929 never-throws contract: the schema-version probes must never
    // throw — a failed/unconnected probe degrades to a safe value rather
    // than crashing the wizard's connect path.
    test('recordedSchemaVersion completes (null) when unconnected', () async {
      await expectLater(SchemaVerifier.recordedSchemaVersion(), completes);
      expect(await SchemaVerifier.recordedSchemaVersion(), isNull);
    });

    test('isSchemaOutdated returns normally (false) when unconnected', () async {
      await expectLater(SchemaVerifier.isSchemaOutdated(), completes);
      expect(await SchemaVerifier.isSchemaOutdated(), isFalse);
    });
  });

  group('SchemaVerifier.getMigrationSql', () {
    test('omits CREATE TABLE for existing tables but keeps RLS/RPCs', () {
      final schema = {for (final t in SchemaVerifier.allTables) t: true};

      final sql = SchemaVerifier.getMigrationSql(schema);

      // No CREATE TABLE for already-present tables.
      expect(sql, isNot(contains('CREATE TABLE IF NOT EXISTS public.users')));
      expect(
          sql, isNot(contains('CREATE TABLE IF NOT EXISTS public.favorites')));
      // RLS + RPCs are always (idempotently) re-asserted.
      expect(sql.toLowerCase(), contains('row level security'));
      expect(sql, contains('public.resolve_share_recipient'));
      expect(sql, contains('public.claim_trip_share'));
    });

    test('includes CREATE TABLE for missing users table', () {
      final schema = <String, bool>{
        'users': false,
        'favorites': true,
      };

      final sql = SchemaVerifier.getMigrationSql(schema);

      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.users'));
    });

    test('includes CREATE TABLE for all missing tables', () {
      final schema = <String, bool>{
        'users': false,
        'favorites': false,
        'alerts': false,
        'price_snapshots': true,
      };

      final sql = SchemaVerifier.getMigrationSql(schema);

      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.users'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.favorites'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.alerts'));
      // Existing table gets no CREATE statement.
      expect(sql,
          isNot(contains('CREATE TABLE IF NOT EXISTS public.price_snapshots')));
    });

    test('records the schema version into tanksync_meta', () {
      final sql = SchemaVerifier.getMigrationSql(const {});
      expect(sql, contains('public.tanksync_meta'));
      expect(sql, contains("'schema_version', '$kSupabaseSchemaVersion'"));
    });

    test('#3712 (v6) — the delete_user account-deletion RPC ships in the '
        'wizard SQL, self-scoped and never callable anonymously', () {
      // Even a fully-provisioned older schema must receive the RPC — it
      // lives in the unconditional rpcSql tail, not a table block.
      final sql = SchemaVerifier.getMigrationSql(
          {for (final t in SchemaVerifier.allTables) t: true});
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.delete_user()'));
      expect(sql, contains('DELETE FROM auth.users WHERE id = auth.uid()'),
          reason: 'the RPC must be pinned to the CALLER — any broader '
              'predicate would let one user delete another');
      expect(sql,
          contains('REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon'));
      expect(sql,
          contains('GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated'));
    });

    test('#3726 (v7) — the content_reports UGC-report table ships in the '
        'wizard SQL with reporter-scoped RLS', () {
      final sql = SchemaVerifier.getMigrationSql(const {});
      expect(
          sql, contains('CREATE TABLE IF NOT EXISTS public.content_reports'));
      expect(sql, contains('reporter_user_id UUID NOT NULL'));
      expect(sql, contains('target_kind TEXT NOT NULL'));
      expect(sql, contains('target_id TEXT NOT NULL'));
      expect(
          sql,
          contains('ALTER TABLE public.content_reports '
              'ENABLE ROW LEVEL SECURITY'));
      // A user may only file reports naming THEMSELVES, and only ever
      // read / delete their own — never another user's reports.
      expect(
          sql,
          contains('CREATE POLICY content_reports_insert_own '
              'ON public.content_reports\n'
              '  FOR INSERT WITH CHECK (reporter_user_id = auth.uid())'));
      expect(
          sql,
          contains('CREATE POLICY content_reports_select_own '
              'ON public.content_reports\n'
              '  FOR SELECT USING (reporter_user_id = auth.uid())'));
      expect(
          sql,
          contains('CREATE POLICY content_reports_delete_own '
              'ON public.content_reports\n'
              '  FOR DELETE USING (reporter_user_id = auth.uid())'));
      // v7 is what the wizard records — an un-upgraded self-host is
      // flagged as outdated, not silently broken.
      expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(7));
    });

    test('#3747 (v8) — the owner-protection block ships in the wizard SQL '
        'with search_path pinned on its SECURITY DEFINER functions', () {
      // Even a fully-provisioned older schema must receive the block —
      // it is emitted unconditionally, like the RLS/RPC tails.
      final sql = SchemaVerifier.getMigrationSql(
          {for (final t in SchemaVerifier.allTables) t: true});
      expect(sql,
          contains('CREATE TABLE IF NOT EXISTS public.database_owner'));
      expect(sql,
          contains('ALTER TABLE public.database_owner ENABLE ROW LEVEL SECURITY'));
      // The three functions, each with a pinned search_path — an
      // unpinned SECURITY DEFINER function is the schema-shadowing
      // privilege-escalation vector #3747 closes.
      expect(
          sql,
          contains('CREATE OR REPLACE FUNCTION public.is_database_owner()\n'
              'RETURNS BOOLEAN\n'
              'LANGUAGE sql\n'
              'SECURITY DEFINER\n'
              'STABLE\n'
              'SET search_path = public'));
      expect(
          sql,
          contains('CREATE OR REPLACE FUNCTION public.auto_register_owner()\n'
              'RETURNS TRIGGER\n'
              'LANGUAGE plpgsql\n'
              'SECURITY DEFINER\n'
              'SET search_path = public'));
      expect(
          sql,
          contains('CREATE OR REPLACE FUNCTION public.limit_bulk_delete()\n'
              'RETURNS TRIGGER\n'
              'LANGUAGE plpgsql\n'
              'SET search_path = public'));
      // First-signin owner bootstrap + the delete restrictions.
      expect(sql, contains('CREATE TRIGGER trg_auto_register_owner'));
      expect(sql, contains('CREATE POLICY users_delete_owner_only'));
      expect(sql, contains('CREATE POLICY snapshots_delete'));
      expect(sql, contains('CREATE POLICY reports_delete'));
      expect(sql, contains('CREATE TRIGGER trg_limit_delete_reports'));
      // The legacy broad users policy must be dropped AFTER rlsSql
      // creates it — the split policies are the final state.
      expect(
          sql.lastIndexOf('DROP POLICY IF EXISTS users_own ON public.users'),
          greaterThan(sql.indexOf(
              'CREATE POLICY users_own ON public.users FOR ALL')),
          reason: 'ownerProtectionSql must run after rlsSql so the '
              'users_own FOR ALL policy does not survive');
      // v8 is what the wizard records — an un-upgraded self-host is
      // flagged as outdated, not silently broken.
      expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(8));
    });

    test('#3452 — the v5 favorites columns reach an EXISTING favorites '
        'table (idempotent ALTER upgrade path)', () {
      // A self-hoster whose `favorites` table pre-exists gets NO CREATE
      // block for it — the kind/data columns must therefore arrive via
      // the unconditional `upgradeSql` ALTERs, and be idempotent.
      final sql = SchemaVerifier.getMigrationSql(
          {for (final t in SchemaVerifier.allTables) t: true});
      expect(sql,
          isNot(contains('CREATE TABLE IF NOT EXISTS public.favorites')));
      expect(
          sql,
          contains('ALTER TABLE public.favorites\n'
              "  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'fuel'"));
      expect(
          sql,
          contains('ALTER TABLE public.favorites\n'
              '  ADD COLUMN IF NOT EXISTS data JSONB'));
      // Fresh installs get the columns in the CREATE block too.
      final freshSql = SchemaVerifier.getMigrationSql(const {});
      expect(freshSql, contains("kind TEXT NOT NULL DEFAULT 'fuel'"));
      expect(freshSql, contains('data JSONB'));
      // v5 is what the wizard records — an un-upgraded self-host is
      // flagged as outdated, not silently broken.
      expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(5));
    });

    test('always includes RLS policies in output', () {
      // All tables present
      final sqlAllPresent = SchemaVerifier.getMigrationSql(
          {for (final t in SchemaVerifier.allTables) t: true});
      expect(sqlAllPresent.toLowerCase(), contains('row level security'));

      // Some tables missing
      final sqlMissing =
          SchemaVerifier.getMigrationSql(const {'users': false});
      expect(sqlMissing.toLowerCase(), contains('row level security'));
    });

    test('SQL output uses CREATE TABLE IF NOT EXISTS syntax', () {
      final sql = SchemaVerifier.getMigrationSql(const {});
      expect(sql, contains('CREATE TABLE IF NOT EXISTS'));
    });

    test('handles empty schema map gracefully', () {
      final schema = <String, bool>{};

      // Should not throw
      final sql = SchemaVerifier.getMigrationSql(schema);
      expect(sql, isA<String>());
    });
  });
}
