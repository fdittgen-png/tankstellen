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
