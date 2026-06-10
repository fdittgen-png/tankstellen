// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../country/country_config.dart';
import 'supabase_client.dart';
import '../../core/logging/error_logger.dart';

/// Server-side price history queries, pulled out of [SyncService] (#727) and
/// clarified into a cache↔Supabase contract by #2249.
///
/// ## Responsibilities (cache↔Supabase split, #2249)
///
/// Local Hive history (recorded on-device by the background refresh and the
/// station-detail view) is the **source of truth for what the user has seen**.
/// Supabase `price_snapshots` is a **server-backfilled supplement** that fills
/// gaps when the local history is thin. This class:
///
///  - [fetch]es the remote supplement, **gated to DE** — Supabase only
///    backfills German (Tankerkönig / MTS-K) snapshots today, so a remote read
///    for any other country is a guaranteed-empty round-trip we now skip; and
///  - exposes a pure [mergeRemoteIntoLocal] that **de-duplicates** the remote
///    rows against the local records by `(stationId, recordedAt)` so a caller
///    can union the two histories without double-counting a snapshot that
///    exists in both stores.
///
/// Price history is read-only for clients — writes happen server-side via
/// scheduled Edge Functions. `price_snapshots` is readable by anon clients
/// (RLS grants SELECT to `authenticated` and `anon`), so the only failure
/// modes are network and Supabase being offline — both return an empty list.
class PriceHistorySync {
  PriceHistorySync._();

  /// The only country Supabase currently backfills price history for. The
  /// server-push phase scope is DE-only (matches the background recorder, which
  /// is Tankerkönig-only); a remote fetch for any other origin returns nothing,
  /// so [fetch] short-circuits it (#2249).
  static const String backfilledCountry = 'DE';

  /// Whether the remote `price_snapshots` table can have rows for [stationId].
  /// Derived from the station-id country prefix; only [backfilledCountry] is
  /// backed today. Exposed so callers (and tests) can pre-flight the gate.
  static bool isRemotelyBackfilled(String stationId) =>
      Countries.countryCodeForStationId(stationId) == backfilledCountry;

  /// Fetch price history snapshots for [stationId] over the last [days] days
  /// (default 30). Returns an empty list when:
  ///
  ///  - the station's country is not [backfilledCountry] (#2249 — skip the
  ///    guaranteed-empty round-trip for non-DE stations),
  ///  - the TankSync client isn't configured, or
  ///  - the fetch fails.
  ///
  /// Callers must treat empty as "no remote data", never "zero-price station".
  static Future<List<Map<String, dynamic>>> fetch(
    String stationId, {
    int days = 30,
  }) async {
    // #2249 — DE-only gate. Supabase has no rows for other countries, so a
    // network call would always come back empty; skip it.
    if (!isRemotelyBackfilled(stationId)) return [];

    final client = TankSyncClient.client;
    if (client == null) return [];

    try {
      final cutoff =
          DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
      final rows = await client
          .from('price_snapshots')
          .select()
          .eq('station_id', stationId)
          .gte('recorded_at', cutoff)
          .order('recorded_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'PriceHistorySync.fetch FAILED'}));
      return [];
    }
  }

  /// Merge server-backfilled [remoteRows] into the on-device [localRecords],
  /// de-duplicating by `(stationId, recordedAt)` so a snapshot present in both
  /// stores is counted once (#2249).
  ///
  /// Both inputs are the JSON-map shape used by `PriceRecord` /
  /// `price_snapshots`. Local records win on a key collision (they are the
  /// canonical on-device copy). The result is sorted **newest-first** to match
  /// the local repository's contract. Pure + side-effect-free so it is trivially
  /// unit-testable and reusable from any caller (station-detail view, a future
  /// background backfill, …) without coupling to Hive or Supabase.
  static List<Map<String, dynamic>> mergeRemoteIntoLocal({
    required List<Map<String, dynamic>> localRecords,
    required List<Map<String, dynamic>> remoteRows,
    required String stationId,
  }) {
    final byKey = <String, Map<String, dynamic>>{};

    // Remote first so a local record with the same key overwrites it.
    for (final row in remoteRows) {
      final normalized = _normalizeRemote(row, stationId);
      final key = _dedupKey(normalized);
      if (key != null) byKey[key] = normalized;
    }
    for (final rec in localRecords) {
      final key = _dedupKey(rec);
      if (key != null) byKey[key] = rec;
    }

    final merged = byKey.values.toList()
      ..sort((a, b) {
        final ta = _recordedAt(a);
        final tb = _recordedAt(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta); // newest first
      });
    return merged;
  }

  // PriceRecord JSON keys (json_serializable defaults — internal data keys,
  // not user-facing strings). The remote `price_snapshots` table uses
  // snake_case (`station_id`, `recorded_at`) which [_normalizeRemote] maps in.
  static const _kStationId = 'stationId';
  static const _kRecordedAt = 'recordedAt';

  /// Convert a remote `price_snapshots` row (snake_case columns) into the
  /// camelCase `PriceRecord` map shape the local store uses.
  static Map<String, dynamic> _normalizeRemote(
    Map<String, dynamic> row,
    String stationId,
  ) =>
      {
        _kStationId: row['station_id'] ?? stationId,
        _kRecordedAt: row['recorded_at'],
        'e5': row['e5'],
        'e10': row['e10'],
        'e98': row['e98'],
        'diesel': row['diesel'],
        'dieselPremium': row['diesel_premium'] ?? row['dieselPremium'],
        'e85': row['e85'],
        'lpg': row['lpg'],
        'cng': row['cng'],
      };

  static String? _dedupKey(Map<String, dynamic> record) {
    final ts = _recordedAt(record);
    if (ts == null) return null;
    final id = record[_kStationId]?.toString() ?? '';
    return '$id@${ts.toIso8601String()}';
  }

  static DateTime? _recordedAt(Map<String, dynamic> record) {
    final raw = record[_kRecordedAt];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
