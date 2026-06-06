// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';

/// #2929 — drift guard for the TankSync (self-hosted Supabase) schema.
///
/// The setup wizard SQL (`getMigrationSql` / `schema_sql.dart`) is what a
/// real self-hoster pastes into their Supabase SQL editor, and the verifier's
/// table lists are what the wizard probes. Both had drifted behind the sync
/// code, leaving self-hosters with 7 missing tables → silent per-feature sync
/// failures the verifier couldn't even detect.
///
/// This test makes that class of regression CI-fatal: it pins the
/// authoritative set of tables the sync code writes, and then
///   1. asserts every authoritative table is in the verifier's required /
///      optional lists AND appears as a CREATE TABLE (+ RLS enable) in the
///      wizard SQL, and
///   2. greps the sync sources for `.from('...')` calls and flags any table
///      not in the authoritative list — so adding a new synced table without
///      updating BOTH this list and the verifier/wizard SQL fails here.
void main() {
  // The authoritative set of tables the sync code persists to. Adding a new
  // synced table means adding it here AND to SchemaVerifier + schema_sql.dart;
  // the `.from()` scan below fails if a synced table is missing from this set.
  const syncedTables = <String>{
    'users',
    'favorites',
    'alerts',
    'price_snapshots',
    'sync_settings',
    'vehicles',
    'fill_ups',
    'itineraries',
    'ignored_stations',
    'station_ratings',
    'price_reports',
    'push_tokens',
    'obd2_baselines',
    'trip_summaries',
    'trip_details',
    'trip_shares',
  };

  // Tables read only by server-side SQL (functions / triggers / RPCs), never
  // `.from()`d by the Dart client, so they are intentionally excluded from
  // the verifier's probe list but are still created by the wizard SQL.
  // `tanksync_meta` is the schema-version row the verifier reads via a
  // dedicated probe (not a sync `.from()` of user data).
  const serverOnlyTables = <String>{'database_owner', 'tanksync_meta'};

  group('SchemaVerifier completeness (#2929)', () {
    test('every synced table is in the verifier required/optional lists', () {
      final covered = SchemaVerifier.allTables.toSet();
      final missing = syncedTables.difference(covered);
      expect(
        missing,
        isEmpty,
        reason: 'These tables the sync code writes are NOT in '
            'SchemaVerifier.requiredTables/optionalTables, so the wizard '
            'never probes them and a self-hoster gets silent sync failures. '
            'Add them: $missing',
      );
    });

    test('the verifier lists no table the sync code does not write', () {
      final extra = SchemaVerifier.allTables.toSet().difference(syncedTables);
      expect(
        extra,
        isEmpty,
        reason: 'SchemaVerifier lists table(s) the sync code never .from()s — '
            'either wire them up or drop them from the lists: $extra',
      );
    });

    test('wizard SQL creates a CREATE TABLE + RLS enable for every '
        'synced table', () {
      // Empty schema → the wizard emits every table (the fresh-install path).
      final sql = SchemaVerifier.getMigrationSql(const {});
      for (final table in syncedTables) {
        expect(
          sql,
          contains('CREATE TABLE IF NOT EXISTS public.$table'),
          reason: 'wizard SQL is missing CREATE TABLE for "$table" — a '
              'self-hoster would not get this synced table',
        );
        expect(
          sql,
          contains('ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY'),
          reason: 'wizard SQL does not enable RLS on "$table" — its rows '
              'would be world-readable/writable',
        );
      }
    });

    test('wizard SQL creates the trip-sharing RPCs the sync code calls', () {
      final sql = SchemaVerifier.getMigrationSql(const {});
      expect(sql, contains('FUNCTION public.resolve_share_recipient'));
      expect(sql, contains('FUNCTION public.claim_trip_share'));
    });

    test('schema_sql.tableSql is itself complete + idempotent', () {
      // tableSql is the source of truth getMigrationSql iterates.
      for (final table in syncedTables) {
        expect(tableSql.keys, contains(table),
            reason: 'schema_sql.tableSql is missing "$table"');
      }
      for (final block in tableSql.values) {
        expect(block, contains('CREATE TABLE IF NOT EXISTS'),
            reason: 'every table block must be idempotent (IF NOT EXISTS)');
      }
    });

    test('scans the sync sources — no .from() table is unaccounted for', () {
      final fromCall = RegExp(r'''\.from\(\s*['"]([a-z0-9_]+)['"]''');
      final dirs = [
        Directory('lib/core/sync'),
        Directory('lib/core/data'),
      ];
      final found = <String, String>{}; // table -> first file it appeared in

      for (final dir in dirs) {
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          if (entity.path.endsWith('.g.dart') ||
              entity.path.endsWith('.freezed.dart')) {
            continue;
          }
          for (final match in fromCall.allMatches(entity.readAsStringSync())) {
            found.putIfAbsent(match.group(1)!, () => entity.path);
          }
        }
      }

      expect(found, isNotEmpty,
          reason: 'sanity: the scan should find .from() calls');

      final known = syncedTables.union(serverOnlyTables);
      final unaccounted = <String>[];
      found.forEach((table, file) {
        if (!known.contains(table)) {
          unaccounted.add('$table  (first seen in $file)');
        }
      });

      expect(
        unaccounted,
        isEmpty,
        reason: 'These tables are .from()-ed by the sync code but are NOT in '
            'the authoritative `syncedTables` set in this test. Add each to '
            '`syncedTables` here AND to SchemaVerifier + schema_sql.dart so '
            'the wizard SQL creates it:\n${unaccounted.join('\n')}',
      );
    });
  });
}
