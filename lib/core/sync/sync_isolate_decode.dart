// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';

/// #3451 — off-main-isolate decode for pulled sync payloads.
///
/// Decoding a few hundred JSONB `data` blobs back into freezed models
/// (`FillUp.fromJson`, `VehicleProfile.fromJson`,
/// `TripHistoryEntry.fromJson`) is pure CPU on the UI isolate during the
/// launch/resume pull window. [BatchDecode.run] moves it through ONE
/// `compute()` call per table (never per row — isolate spawn cost would
/// dwarf the work).
///
/// ## Contract for entrypoints
///
/// The decode entrypoint MUST be a **top-level pure function** (enforced
/// by `test/core/sync/sync_isolate_decode_test.dart`): no Hive, no
/// plugins, no `errorLogger`, no captured state — only
/// `List<Map<String, dynamic>> → List<T?>` where a corrupt row maps to
/// `null` (the caller counts/logs the nulls on the main isolate). The
/// entrypoints live NEXT TO their models' existing sync configs
/// (`decodeFillUpDataRows` in fill_ups_sync.dart, `decodeVehicleDataRows`
/// in vehicles_sync.dart, `decodeTripSummaryDataRows` in
/// trips_sync_json.dart) so no new core→feature import pair is created.
class BatchDecode {
  BatchDecode._();

  /// Below this row count the decode runs inline — spawning an isolate
  /// for a handful of rows costs more than it saves, and the common
  /// steady-state pull (0-5 new rows) stays allocation-free.
  static const int isolateThreshold = 10;

  /// Test seam: force the inline path so widget tests without isolate
  /// support stay deterministic (`null` = automatic threshold policy;
  /// `false` = always inline; `true` = always isolate).
  @visibleForTesting
  static bool? offloadOverride;

  /// Decode [rows] through the top-level [entrypoint] — via `compute()`
  /// when the batch is big enough (reliability-first: the entrypoint is
  /// PURE, so a fallback to inline on any isolate fault is
  /// behaviour-identical, just slower).
  static Future<List<T?>> run<T>(
    List<Map<String, dynamic>> rows,
    List<T?> Function(List<Map<String, dynamic>>) entrypoint,
  ) async {
    final offload =
        offloadOverride ?? rows.length >= isolateThreshold;
    if (!offload) return entrypoint(rows);
    try {
      return await compute(entrypoint, rows);
    } catch (e, st) {
      // A failed isolate spawn (platform restriction, shutdown race) must
      // never cost the pull — decode inline instead: behaviour-identical,
      // only the thread changes. Logged so a systematically broken
      // offload is field-visible.
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'BatchDecode compute() failed — decoded inline'
      }));
      return entrypoint(rows);
    }
  }
}
