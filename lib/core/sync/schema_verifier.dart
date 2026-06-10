// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'schema_sql.dart';
import 'supabase_client.dart';
import '../../core/logging/error_logger.dart';

/// Verifies that the required TankSync database schema exists.
///
/// When connecting to a Supabase database for the first time, the tables
/// may not exist yet (user hasn't run migrations). This class detects
/// missing tables and provides the SQL to create them.
///
/// The table lists below and [getMigrationSql] are kept a **superset** of
/// every table the sync code (`lib/core/sync/*.dart`) `.from()`s. The drift
/// guard `test/core/sync/schema_verifier_completeness_test.dart` fails CI if
/// a newly-synced table is not added here + to the wizard SQL.
class SchemaVerifier {
  SchemaVerifier._();

  /// Core tables TankSync needs before sync can function at all. A missing
  /// one means the wizard SQL has not been run — the verifier flags it.
  static const requiredTables = [
    'users',
    'favorites',
    'alerts',
    'price_snapshots',
    'sync_settings',
    'vehicles',
    'fill_ups',
  ];

  /// Tables the sync code writes for opt-in features (history, ratings,
  /// trips, sharing, push). Their absence degrades a feature rather than
  /// breaking core sync, but the wizard SQL still creates every one so a
  /// self-hoster ends up with a complete schema.
  static const optionalTables = [
    'itineraries',
    'ignored_stations',
    'station_ratings',
    'price_reports',
    'push_tokens',
    'obd2_baselines',
    'trip_summaries',
    'trip_details',
    'trip_shares',
    'deletions',
  ];

  /// Every table the wizard SQL creates / the verifier probes.
  static List<String> get allTables => [...requiredTables, ...optionalTables];

  /// Check which required tables exist in the database.
  ///
  /// Returns a map of table name → exists (true/false).
  /// Returns null if the client is not connected.
  ///
  /// #2310 — the existence probes are independent, so they run in
  /// parallel via [Future.wait]. #2929 — each probe is a column-agnostic
  /// `count()` HEAD request (was `select('id')`, which false-negatived
  /// every `id`-less table like `sync_settings` / `obd2_baselines` /
  /// `push_tokens`). It transfers no row data — a missing table / failed
  /// probe maps to false.
  static Future<Map<String, bool>?> checkSchema() async {
    final client = TankSyncClient.client;
    if (client == null) return null;

    final entries = await Future.wait(
      allTables.map(
        (table) => client
            .from(table)
            .count()
            .then((_) => MapEntry(table, true))
            .catchError((Object e, StackTrace st) {
          unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'SchemaVerifier: table check failed'}));
          return MapEntry(table, false);
        }),
      ),
    );
    final result = Map<String, bool>.fromEntries(entries);

    debugPrint('SchemaVerifier: ${result.entries.where((e) => e.value).length}/${result.length} tables found');
    return result;
  }

  /// Whether all required tables exist.
  static Future<bool> isSchemaReady() async {
    final schema = await checkSchema();
    if (schema == null) return false;
    return requiredTables.every((t) => schema[t] == true);
  }

  /// Reads the schema version a self-hoster recorded when they last ran the
  /// wizard SQL (stored in `public.tanksync_meta`). Returns:
  ///   * the recorded version (int) when present,
  ///   * `0` when the meta table / row is missing — i.e. the schema predates
  ///     versioning and must be re-applied,
  ///   * `null` when not connected (caller can't tell, so stays quiet).
  ///
  /// Never throws — a failed probe maps to `0` (outdated) so the caller
  /// surfaces a "re-run the setup SQL" hint rather than crashing.
  static Future<int?> recordedSchemaVersion() async {
    final client = TankSyncClient.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('tanksync_meta')
          .select('value')
          .eq('key', 'schema_version')
          .maybeSingle();
      final value = row?['value'];
      return value == null ? 0 : (int.tryParse('$value') ?? 0);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'SchemaVerifier: schema-version probe failed'}));
      return 0;
    }
  }

  /// True when the connected database's recorded schema version is older
  /// than the version this app build expects ([kSupabaseSchemaVersion]) — a
  /// self-hoster who has not re-run the latest setup SQL. Returns false when
  /// not connected or already up to date.
  static Future<bool> isSchemaOutdated() async {
    final recorded = await recordedSchemaVersion();
    if (recorded == null) return false;
    return recorded < kSupabaseSchemaVersion;
  }

  /// SQL to create all missing tables + (idempotently) every RLS policy and
  /// RPC the sync code needs. User pastes this into the Supabase SQL editor
  /// (Dashboard → SQL Editor → New Query). Delegates to [buildMigrationSql]
  /// in `schema_sql.dart`, the single source of truth for the schema.
  static String getMigrationSql(Map<String, bool> schema) =>
      buildMigrationSql(schema);
}
