// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../features/consumption/data/trip_history_repository.dart';
import '../logging/error_logger.dart';
import 'sync_isolate_decode.dart';

/// Trip-sync JSON payload shapers, split out of `trips_sync.dart` so the
/// wire/merge class stays under the file-length cap (#2319). Both are
/// pure functions over [TripHistoryEntry.toJson].

/// Strips the per-tick `samples` and GPS-diagnostics arrays from a
/// [TripHistoryEntry]'s JSON form so the upload payload stays under the
/// 1 KB target for `public.trip_summaries.data` (#1479 phase 2). The
/// full-detail blob (samples + gpsd) lands in `public.trip_details` via
/// [tripDetailsJson] instead.
Map<String, dynamic> compactSummaryJson(TripHistoryEntry entry) {
  final json = entry.toJson();
  json.remove('samples');
  json.remove('gpsd');
  return json;
}

/// Mirror of [compactSummaryJson] for the heavy blob: returns just
/// `samples` + `gpsd` for the `trip_details.data` payload. Empty arrays
/// are emitted explicitly so a future fetch round-trips through
/// `TripHistoryEntry.fromJson` cleanly even when only one of the two
/// arrays was populated at recording time.
Map<String, dynamic> tripDetailsJson(TripHistoryEntry entry) {
  final json = entry.toJson();
  return {
    'samples': json['samples'] ?? const <dynamic>[],
    'gpsd': json['gpsd'] ?? const <dynamic>[],
  };
}

/// #3451 — top-level PURE `compute()` entrypoint for the trip-summary
/// `data` blobs (no Hive / plugins / logging, so it can run on a worker
/// isolate). Mirrors the decode step of `TripsSync.mergeRows`: a corrupt
/// blob maps to `null`; the caller logs the failure count on the main
/// isolate.
List<TripHistoryEntry?> decodeTripSummaryDataRows(
        List<Map<String, dynamic>> blobs) =>
    [for (final blob in blobs) _decodeTripSummaryBlob(blob)];

TripHistoryEntry? _decodeTripSummaryBlob(Map<String, dynamic> blob) {
  try {
    return TripHistoryEntry.fromJson(blob);
  } catch (_) {
    return null;
  }
}

/// #3451 — async analogue of `TripsSync.mergeRows` that batch-decodes the
/// server-only `data` blobs through ONE `compute()` call (via
/// [BatchDecode.run]) instead of per-row `fromJson` on the UI isolate.
/// Identical union semantics: local wins on id collision, tombstoned ids
/// are skipped, and a row that fails to decode is dropped (logged, never
/// aborting the merge). The sync `mergeRows` stays as the pure seam the
/// #2239 regression test pins.
Future<List<TripHistoryEntry>> mergeTripRowsOffThread(
  List<TripHistoryEntry> localEntries,
  List<Map<String, dynamic>> serverRows, {
  Set<String> tombstoned = const {},
}) async {
  final localIds = localEntries.map((e) => e.id).toSet();
  final ids = <String>[];
  final blobs = <Map<String, dynamic>>[];
  for (final r in serverRows) {
    final id = r['id'];
    if (id is! String || localIds.contains(id) || tombstoned.contains(id)) {
      continue;
    }
    final data = r['data'];
    if (data is! Map) continue;
    ids.add(id);
    blobs.add(data.cast<String, dynamic>());
  }
  final decoded = await BatchDecode.run(blobs, decodeTripSummaryDataRows);
  final downloaded = <TripHistoryEntry>[];
  for (var i = 0; i < decoded.length; i++) {
    final entry = decoded[i];
    if (entry == null) {
      unawaited(errorLogger.log(
          ErrorLayer.sync,
          StateError('trip summary blob failed to decode'),
          StackTrace.current,
          context: {'where': 'mergeTripRowsOffThread decode', 'id': ids[i]}));
      continue;
    }
    downloaded.add(entry);
  }
  return [...localEntries, ...downloaded];
}
