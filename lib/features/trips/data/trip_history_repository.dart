// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/trip_sample.dart';
import '../domain/trip_verdict.dart';
import 'trip_column_chunk.dart';
import 'trip_dedup.dart';
import 'trip_history_entry.dart';
import 'trip_history_store_v2.dart';
import 'trip_sample_codec.dart';
import '../../../core/logging/error_logger.dart';

// #3613 — TripHistoryEntry moved into its own file so this one stays
// under the 400-line cap; the re-export keeps every existing
// `trip_history_repository.dart` import working.
export 'trip_history_entry.dart';
export 'trip_history_entry_columns.dart'; // #3882
export 'trip_column_chunk.dart' show TripColumns;

/// #3613 — above this stored-sample count, [TripHistoryRepository.save]
/// encodes on a background isolate via `compute()` (~10 ms hop; a
/// 2000-sample trip is ~33 min at 1 Hz).
const int kTripSaveComputeSampleThreshold = 2000;

/// Hive-backed list of finalised trips (#726).
///
/// Stores at most [cap] trips keyed by a stable trip id (ISO start
/// timestamp). Oldest entries drop off when the cap is hit — trip
/// history is a rolling log, not an archive.
///
/// #3882 — trip detail v2: a trip is a META row (`<id>`) plus columnar
/// CHUNK rows (`<id>::chunk::<n>`, ≤ 300 samples each) and a diagnostics
/// row (`<id>::gpsd`), see `trip_history_store_v2.dart`. The summary list
/// reads meta rows only; [loadById] assembles the chunks; [loadByIdAsync]
/// does so in an isolate; [loadColumns] reads only the arrays asked for.
/// Legacy v1 rows (one JSON string with `samples`) keep decoding and are
/// rewritten to v2 on their first full read ([migrateLegacyRow]) or by
/// the background [migrateLegacyRowsInBackground] sweep.
class TripHistoryRepository {
  final Box<String> _box;
  final int cap;

  /// Optional hook fired after a successful [save] when the saved
  /// entry's `vehicleId` is non-null (#1193 phase 2, #3878: receives the
  /// entry so the vehicle aggregates can be FOLDED in). MUST NOT throw —
  /// a throw is caught and logged, never propagated into the save flow.
  void Function(TripHistoryEntry entry)? onSavedHook;

  TripHistoryRepository({
    required Box<String> box,
    this.cap = 100,
    this.onSavedHook,
  }) : _box = box; // ignore: prefer_initializing_formals

  /// Box name used by the production wiring.
  static const String boxName = 'obd2_trip_history';

  /// The ids of every persisted trip — the meta-row keys (#3613, #3882:
  /// sidecar chunk rows are not trips). Zero JSON decoding.
  Iterable<String> get storedIds =>
      _box.keys.whereType<String>().where((k) => !isTripSidecarKey(k));

  /// Persist [entry]. Drops the oldest trip when the box reaches [cap].
  /// Errors are logged but swallowed. #2833 — a 0-sample ghost whose
  /// sampled twin already exists is a no-op; a sampled twin deletes any
  /// pre-existing 0-sample ghost (see [guardGhostDoubleSave]).
  Future<void> save(TripHistoryEntry entry) async {
    try {
      final skip = await guardGhostDoubleSave(
        entry: entry,
        existing: loadSummaries(dedupe: false),
        deleteById: delete,
      );
      if (skip) return;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'TripHistoryRepository.save ghost-guard'}));
    }
    try {
      await _writeRows(entry);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'TripHistoryRepository.save'}));
      return;
    }
    await _trim();
    final vehicleId = entry.vehicleId;
    final hook = onSavedHook;
    if (vehicleId != null && hook != null) {
      try {
        hook(entry);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st,
            context: const {'where': 'TripHistoryRepository.save onSavedHook'}));
      }
    }
  }

  /// Encode (#3613: off-thread above the threshold) and write the v2
  /// rows; stale sidecars of a re-saved trip are removed first.
  Future<void> _writeRows(TripHistoryEntry entry) async {
    final json = entry.toJson();
    final rows = entry.samples.length > kTripSaveComputeSampleThreshold
        ? await compute(encodeTripRowsV2, json)
        : encodeTripRowsV2(json);
    await _deleteSidecars(entry.id, keep: rows.keys.toSet());
    await _box.putAll(rows);
  }

  Future<void> _deleteSidecars(String id, {Set<String> keep = const {}}) async {
    final stale = [
      for (final k in _box.keys.whereType<String>())
        if (isTripSidecarKey(k) && tripIdOfKey(k) == id && !keep.contains(k)) k,
    ];
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  /// The raw rows of trip [id], or null when absent.
  TripRowsV2? _rowsOf(String id, String meta) {
    final chunks = <String>[];
    for (var i = 0;; i++) {
      final c = _box.get(tripChunkKey(id, i));
      if (c == null) break;
      chunks.add(c);
    }
    return TripRowsV2(meta: meta, chunks: chunks, gpsd: _box.get(tripGpsdKey(id)));
  }

  static bool _isV2(Map<String, dynamic> json) => json['v'] == kTripRowVersion;

  /// Deserialise the trip stored under [key], or null when absent or
  /// corrupt (a single bad row is logged + skipped, never thrown).
  TripHistoryEntry? _decode(Object key, {bool summaryOnly = false}) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty || isTripSidecarKey(key)) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (_isV2(json)) {
        if (summaryOnly) return TripHistoryEntry.summaryFromJson(json);
        return decodeTripRowsV2ToEntry(_rowsOf(key as String, raw)!);
      }
      if (summaryOnly) return TripHistoryEntry.summaryFromJson(json);
      // Legacy v1 row: decode as before and rewrite it in the background.
      _scheduleMigration(key as String);
      return TripHistoryEntry.fromJson(json);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'TripHistoryRepository._decode: skipping $key'}));
      return null;
    }
  }

  final Set<String> _migrating = {};
  void _scheduleMigration(String id) {
    if (!_migrating.add(id)) return;
    unawaited(Future<void>(() => migrateLegacyRow(id))
        .whenComplete(() => _migrating.remove(id)));
  }

  /// #3882 — rewrite a legacy v1 row into meta + chunks. No-op on a v2
  /// row or a missing/corrupt one. Returns true when a rewrite happened.
  Future<bool> migrateLegacyRow(String id) async {
    try {
      final raw = _box.get(id);
      if (raw == null || raw.isEmpty) return false;
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (_isV2(json)) return false;
      final rows = json['samples'] is List &&
              (json['samples'] as List).length > kTripSaveComputeSampleThreshold
          ? await compute(encodeTripRowsV2, json)
          : encodeTripRowsV2(json);
      await _box.putAll(rows);
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'TripHistoryRepository.migrateLegacyRow $id'}));
      return false;
    }
  }

  /// #3882 — low-priority sweep: migrate every legacy row, one at a time,
  /// yielding [pause] between rows so the UI isolate stays responsive.
  /// Returns the number of rows rewritten. Never throws.
  Future<int> migrateLegacyRowsInBackground(
      {Duration pause = const Duration(milliseconds: 50)}) async {
    var n = 0;
    for (final id in storedIds.toList()) {
      if (await migrateLegacyRow(id)) n++;
      await Future<void>.delayed(pause);
    }
    return n;
  }

  /// Every persisted trip, sorted newest-first, ghost-de-duped (#2833).
  List<TripHistoryEntry> loadAll({bool dedupe = true}) =>
      _loadSorted(dedupe: dedupe, summaryOnly: false);

  /// Summary-only variant of [loadAll] (#3613): no sample is decoded
  /// (#3882: v2 meta rows make this O(trips), not O(samples)).
  List<TripHistoryEntry> loadSummaries({bool dedupe = true}) =>
      _loadSorted(dedupe: dedupe, summaryOnly: true);

  List<TripHistoryEntry> _loadSorted({
    required bool dedupe,
    required bool summaryOnly,
  }) {
    final result = <TripHistoryEntry>[];
    for (final key in storedIds.toList()) {
      final entry = _decode(key, summaryOnly: summaryOnly);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) {
      final ax = a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax); // newest first
    });
    return dedupe ? dedupeGhostTrips(result) : result;
  }

  /// O(1) lookup of one persisted trip by [id] (#2304), samples assembled
  /// from its chunks on the calling isolate. Prefer [loadByIdAsync] on
  /// the UI isolate for long trips.
  TripHistoryEntry? loadById(String id) => _decode(id);

  /// #3882 — full decode of one trip on a background isolate: only the
  /// raw strings cross to the worker, the finished entry comes back.
  Future<TripHistoryEntry?> loadByIdAsync(String id) async {
    final raw = _box.get(id);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (_isV2(json)) {
        return await compute(decodeTripRowsV2ToEntry, _rowsOf(id, raw)!);
      }
      _scheduleMigration(id);
      return await compute(decodeLegacyRowToEntry, raw);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'TripHistoryRepository.loadByIdAsync $id'}));
      return null;
    }
  }

  /// #3882 — only the requested sample columns of one trip (codec keys
  /// such as `s`, `f`, `la`), without materialising samples. Legacy rows
  /// decode fully and are projected. Empty when the trip is absent.
  TripColumns loadColumns(String id, Set<String> keys) {
    final raw = _box.get(id);
    if (raw == null || raw.isEmpty) return TripColumns.empty;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (_isV2(json)) {
        return decodeTripColumnsV2(_rowsOf(id, raw)!.chunks, keys);
      }
      final samples = (json['samples'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList(growable: false) ??
          const <Map<String, dynamic>>[];
      return decodeTripChunkColumns(encodeTripChunkFromMaps(samples), keys);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'TripHistoryRepository.loadColumns $id'}));
      return TripColumns.empty;
    }
  }

  /// #3882 — a light sample list carrying only [keys] (plus timestamps),
  /// for readers such as the speed/consumption aggregator that take
  /// `List<TripSample>` but touch two or three fields.
  List<TripSample> loadSamplesWith(String id, Set<String> keys) {
    final cols = loadColumns(id, keys);
    return [
      for (var i = 0; i < cols.length; i++)
        sampleFromJson({
          't': cols.timestampsMs[i],
          's': cols.values['s']?[i] ?? 0.0,
          for (final k in keys)
            if (k != 's' && cols.values[k]?[i] != null) k: cols.values[k]![i],
        }),
    ];
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await _deleteSidecars(id);
  }

  /// #3501 — persist the driver's post-trip verdict onto an existing entry.
  /// #3882 — a v2 row rewrites its META row only (the chunks are untouched).
  Future<bool> saveVerdict(String id, TripVerdict verdict) async {
    try {
      final raw = _box.get(id);
      if (raw == null) return false;
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (_isV2(json)) {
        json['verdict'] = verdict.wireName;
        await _box.put(id, jsonEncode(json));
        return true;
      }
      final entry = TripHistoryEntry.fromJson(json);
      await _box.put(
          id, jsonEncode(entry.copyWith(verdict: verdict.wireName).toJson()));
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'TripHistoryRepository.saveVerdict'}));
      return false;
    }
  }

  /// Wipe every persisted trip (#2571) — backup RESTORE (replace mode).
  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> _trim() async {
    if (storedIds.length <= cap) return;
    final entries = loadSummaries(); // newest-first
    for (final e in entries.skip(cap)) {
      await delete(e.id);
    }
  }
}
