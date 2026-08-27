// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/trip_verdict.dart';
import 'trip_dedup.dart';
import 'trip_history_entry.dart';
import '../../../core/logging/error_logger.dart';

// #3613 — TripHistoryEntry moved into its own file so this one stays
// under the 400-line cap; the re-export keeps every existing
// `trip_history_repository.dart` import working.
export 'trip_history_entry.dart';

/// #3613 — above this stored-sample count, [TripHistoryRepository.save]
/// runs `jsonEncode` on a background isolate via `compute()` (mirroring
/// the sync layer's one-`compute()`-per-payload pattern, #3451). A
/// 2000-sample trip is ~33 min at 1 Hz; encoding payloads that size on
/// the UI isolate was measurably janking the stop-trip flow, while the
/// isolate hop (~10 ms) dominates for anything smaller.
const int kTripSaveComputeSampleThreshold = 2000;

/// Hive-backed list of finalised trips (#726).
///
/// Stores at most [cap] entries keyed by a stable trip id (ISO start
/// timestamp). Oldest entries drop off when the cap is hit — trip
/// history is a rolling log, not an archive. The box holds one JSON
/// payload per entry so a single corrupt write can be skipped without
/// killing the whole list.
class TripHistoryRepository {
  final Box<String> _box;
  final int cap;

  /// Optional hook fired after a successful [save] when the saved
  /// entry's `vehicleId` is non-null (#1193 phase 2). Production wires
  /// this from `app_initializer.dart` to dispatch a vehicle-aggregate
  /// recompute via [VehicleAggregateUpdater]; tests inject a fake to
  /// observe the call.
  ///
  /// IMPORTANT — the hook MUST NOT throw. It's invoked synchronously
  /// from inside [save] and any throw is caught and logged via
  /// `errorLogger.log(ErrorLayer.background, ...)` so the save flow is
  /// never derailed by an aggregator failure. The hook itself should
  /// fire-and-forget any async work it kicks off (use `unawaited(...)`
  /// at the call site).
  void Function(String vehicleId)? onSavedHook;

  TripHistoryRepository({
    required this._box,
    this.cap = 100,
    this.onSavedHook,
  });

  /// Box name used by the production wiring.
  static const String boxName = 'obd2_trip_history';

  /// The ids of every persisted trip — the raw box keys (#3613). The
  /// box is keyed by `entry.id` (see [save]), so this answers "which
  /// trips are stored?" with ZERO JSON decoding. Includes ghost
  /// duplicates and corrupt rows; callers that need the de-duped,
  /// decodable truth use [loadSummaries] / [loadAll].
  Iterable<String> get storedIds => _box.keys.whereType<String>();

  /// Persist [entry]. Drops the oldest trip when the box reaches [cap].
  /// Errors are logged but swallowed. #2833 — a 0-sample ghost whose
  /// sampled twin already exists is a no-op; a sampled twin deletes any
  /// pre-existing 0-sample ghost (see [guardGhostDoubleSave]).
  Future<void> save(TripHistoryEntry entry) async {
    try {
      // A guard hiccup must never block the save — fall through to a write.
      // #3613 — the guard only reads summary-level fields (ids, summary
      // metrics, startedAt, the stored sample COUNT), so it rides the
      // cheap summary-only decode instead of materialising every stored
      // sample on every save.
      final skip = await guardGhostDoubleSave(
        entry: entry,
        existing: loadSummaries(dedupe: false),
        deleteById: _box.delete,
      );
      if (skip) return;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'TripHistoryRepository.save ghost-guard'}));
    }
    try {
      // #3613 — a long trip's JSON encode is O(samples) and was running
      // on the UI isolate inside the stop-trip flow; big payloads hop to
      // a background isolate (the map built by toJson() is plain
      // JSON-safe data, so it crosses the isolate boundary cheaply).
      final json = entry.toJson();
      final encoded = entry.samples.length > kTripSaveComputeSampleThreshold
          ? await compute(jsonEncode, json)
          : jsonEncode(json);
      await _box.put(entry.id, encoded);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'TripHistoryRepository.save'}));
      return;
    }
    await _trim();

    // Fire the post-save hook for vehicle-attributed trips. Wrapped in
    // a try/catch because the hook is user code (production: an
    // aggregator dispatch) and a failure there must not propagate up
    // into the trip-save flow — the trip already persisted. The hook
    // is responsible for fire-and-forget on its own async work.
    final vehicleId = entry.vehicleId;
    final hook = onSavedHook;
    if (vehicleId != null && hook != null) {
      try {
        hook(vehicleId);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'TripHistoryRepository.save onSavedHook'}));
      }
    }
  }

  /// Deserialise the row stored under [key], or null when absent or
  /// corrupt (a single bad write is logged + skipped, never thrown).
  TripHistoryEntry? _decode(Object key, {bool summaryOnly = false}) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return summaryOnly
          ? TripHistoryEntry.summaryFromJson(json)
          : TripHistoryEntry.fromJson(json);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'TripHistoryRepository._decode: skipping $key'}));
      return null;
    }
  }

  /// Return every persisted trip, sorted newest-first. Corrupt payloads
  /// are silently skipped. #2833 — by default ghost 0-sample duplicates
  /// are removed so the list, the aggregates (`loadAll().length`) and the
  /// re-export see the de-duped truth; `dedupe: false` is the raw set.
  List<TripHistoryEntry> loadAll({bool dedupe = true}) =>
      _loadSorted(dedupe: dedupe, summaryOnly: false);

  /// Summary-only variant of [loadAll] (#3613): same entries, same
  /// order, same ghost de-dupe — but the heavy per-tick payloads
  /// (`samples`, `gpsd`, `lcm`, `obd2d`) are never materialised into
  /// objects. `entry.samples` is always empty here; the stored sample
  /// count survives on `entry.sampleCount`. Use this wherever only the
  /// summary/bookkeeping fields are consumed (list totals, per-vehicle
  /// summary math, the save-time ghost guard); consumers that render or
  /// recompute samples stay on [loadAll] / [loadById].
  List<TripHistoryEntry> loadSummaries({bool dedupe = true}) =>
      _loadSorted(dedupe: dedupe, summaryOnly: true);

  List<TripHistoryEntry> _loadSorted({
    required bool dedupe,
    required bool summaryOnly,
  }) {
    final result = <TripHistoryEntry>[];
    for (final key in _box.keys) {
      final entry = _decode(key as Object, summaryOnly: summaryOnly);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) {
      final ax = a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax); // newest first
    });
    return dedupe ? dedupeGhostTrips(result) : result;
  }

  /// O(1) lookup of one persisted trip by [id] (#2304) — the box is keyed
  /// by `entry.id`, so this avoids the deserialise-everything + sort that
  /// `loadAll().firstWhere` paid just to fetch one row on trip stop.
  TripHistoryEntry? loadById(String id) => _decode(id);

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// #3501 — persist the driver's post-trip verdict onto an existing entry.
  /// Best-effort: a missing/corrupt row or a failed write is logged and
  /// swallowed (the prompt simply re-appears next visit). Returns true when
  /// the verdict was written.
  Future<bool> saveVerdict(String id, TripVerdict verdict) async {
    try {
      final raw = _box.get(id);
      if (raw == null) return false;
      final entry = TripHistoryEntry.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
      await _box.put(
        id,
        jsonEncode(entry.copyWith(verdict: verdict.wireName).toJson()),
      );
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'TripHistoryRepository.saveVerdict'}));
      return false;
    }
  }

  /// Wipe every persisted trip (#2571). Used by the full-backup RESTORE
  /// flow in [BackupImportMode.replace] before the backup's trips are
  /// written back. A no-op-equivalent when the box is already empty.
  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> _trim() async {
    if (_box.length <= cap) return;
    // #3613 — trimming only needs ids ordered by startedAt; the
    // summary-only decode is enough.
    final entries = loadSummaries(); // newest-first
    final toDrop = entries.skip(cap).map((e) => e.id).toList();
    for (final id in toDrop) {
      await _box.delete(id);
    }
  }
}
