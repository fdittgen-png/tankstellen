// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory_sync.dart';
import 'package:tankstellen/core/sync/fleet/fleet_transport.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';
import 'package:tankstellen/core/sync/user_data_sync.dart';

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
    'content_reports',
    'deletions',
    'wait_time_pings', // #4062 — map-routed, never a literal .from()
    // #4212 (v13) — the org-scoped fleet tables, read through the
    // FleetTransport's closed set; writes are RPC-only (ADR 0025 D7).
    'fleet_organizations',
    'fleet_members',
    'fleet_vehicles',
    'vehicle_assignments',
    'fleet_policies',
    // #4215 (v14) — the two USER-owned fleet tables. `fleet_expenses`
    // rides the generic EntitySync transport, so its `.from()` is the
    // engine's parameterised one and the literal scan below cannot see
    // it; `fleet_documents` is written through FleetDocumentStore's
    // seam for the same reason. Both must be listed here, exactly like
    // the #4062 map-routed rule.
    'fleet_expenses',
    'fleet_documents',
  };

  // Tables read only by server-side SQL (functions / triggers / RPCs), never
  // `.from()`d by the Dart client, so they are intentionally excluded from
  // the verifier's probe list but are still created by the wizard SQL.
  // `tanksync_meta` is the schema-version row the verifier reads via a
  // dedicated probe (not a sync `.from()` of user data).
  // #4215 — `fleet_audit_events` joins them: the client never writes it
  // (the `fleet_*` SECURITY DEFINER RPCs do, and no client write policy
  // exists), so it is not a synced table; `UserDataSync` reads the
  // caller's own rows through its table MAP for the GDPR export.
  const serverOnlyTables = <String>{
    'database_owner',
    'tanksync_meta',
    'fleet_audit_events',
  };

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

    // The `.from()` scan below cannot see an RPC at all: a function is
    // invoked through `rpc('name')`, so a fleet slice that shipped a
    // SECURITY DEFINER read without its wizard twin would leave every
    // self-host with a dashboard that 404s and a gate that stayed
    // green. HARD RULE #5 covers RPCs as well as tables, so the fleet
    // functions are named here one by one.
    test('wizard SQL creates every fleet RPC the client calls (#4212, '
        '#4215, #4216)', () {
      final sql = SchemaVerifier.getMigrationSql(const {});
      for (final fn in const [
        'fleet_create_organization',
        'fleet_upsert_vehicle',
        'fleet_assign_vehicle',
        'fleet_end_assignment',
        'fleet_review_expense',
        'fleet_log_document_access',
        'fleet_period_metrics',
        'fleet_log_export',
      ]) {
        expect(sql, contains('FUNCTION public.$fn'),
            reason: 'wizard SQL is missing the "$fn" RPC — a self-hoster '
                'who re-runs the setup SQL would still not have it');
        expect(sql, contains('REVOKE EXECUTE ON FUNCTION public.$fn'),
            reason: '"$fn" must lose EXECUTE for anon explicitly: the '
                'PUBLIC revoke does not cover it');
      }
    });

    test('wizard SQL creates the server-only tables too (#3747 widened: '
        'not just the .from()-probed ones)', () {
      // `serverOnlyTables` are read by SQL functions/triggers, never
      // `.from()`d, so the verifier does not probe them — but the wizard
      // must still create them or the owner bootstrap / schema-version
      // probe break on a self-host. `tanksync_meta` ships via _metaSql;
      // `database_owner` via ownerProtectionSql (v8).
      final sql = SchemaVerifier.getMigrationSql(const {});
      for (final table in serverOnlyTables) {
        expect(sql, contains('CREATE TABLE IF NOT EXISTS public.$table'),
            reason: 'wizard SQL is missing server-only table "$table"');
        expect(sql, contains('ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY'),
            reason: 'wizard SQL does not enable RLS on "$table"');
      }
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

    // #4062 — HARD RULE 5's `.from('literal')` scan is blind to tables the
    // client routes through a map or a parameter. UserDataSync reads and
    // deletes `wait_time_pings` that way, and the wizard SQL shipped
    // without the table for months. Every map-routed table must be in
    // the authoritative set too.
    test('every table UserDataSync routes by map is in the authoritative '
        'set (#4062)', () {
      final routed = {
        ...UserDataSync.readableTables.keys,
        ...UserDataSync.deletableTables.keys,
      };
      final unaccounted =
          routed.difference(syncedTables).difference(serverOnlyTables);
      expect(unaccounted, isEmpty,
          reason: 'UserDataSync reads/deletes these tables but the wizard SQL '
              'never creates them on a self-host: $unaccounted');
    });

    // #4212 — the fleet pull routes its tables through FleetTransport
    // (a closed set with one literal `.from()` each) and names them in a
    // constant set; like the #4062 map-routed rule, that set must be in
    // the authoritative list so the wizard SQL creates every table.
    test('every table the fleet pull routes by constant is in the '
        'authoritative set (#4212)', () {
      final routed = {...FleetDirectorySync.tables, ...FleetTables.all};
      final unaccounted = routed.difference(syncedTables);
      expect(unaccounted, isEmpty,
          reason: 'the fleet transport reads these tables but the wizard '
              'SQL never creates them on a self-host: $unaccounted');
    });

    test('scans the sync sources — no .from() table is unaccounted for', () {
      final fromCall = RegExp(r'''\.from\(\s*['"]([a-z0-9_]+)['"]''');
      // #3743 (epic item 5) — the per-entity sync configs live in their
      // owning features now (features/<f>/data/<entity>_sync.dart), so the
      // scan sweeps ALL of lib/features too: a feature-side `.from()` on an
      // unknown table must stay CI-fatal (HARD RULE 5), wherever it lives.
      final dirs = [
        Directory('lib/core/sync'),
        Directory('lib/core/data'),
        Directory('lib/features'),
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
