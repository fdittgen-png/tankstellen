// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../core/storage/hive_trip_history_index.dart';
import '../../../core/storage/hive_box_mutation_epoch.dart';

import '../domain/trip_sample.dart';
import '../domain/trip_verdict.dart';
import 'trip_column_chunk.dart';
import 'trip_dedup.dart';
import 'trip_history_entry.dart';
import 'trip_history_store_v2.dart';
import 'trip_history_column_source.dart';
import 'trip_history_payload_reader.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';

// #3613 — TripHistoryEntry moved into its own file so this one stays
// under the 400-line cap; the re-export keeps every existing
// `trip_history_repository.dart` import working.
export 'trip_history_entry.dart';
export 'trip_history_column_source.dart';
export 'trip_history_entry_columns.dart'; // #3882
export 'trip_column_chunk.dart' show TripColumns;

/// #3613 — above this stored-sample count, [TripHistoryRepository.save]
/// encodes on a background isolate via `compute()` (~10 ms hop; a
/// 2000-sample trip is ~33 min at 1 Hz).
const int kTripSaveComputeSampleThreshold = 2000;

/// Hive-backed list of finalised trips (#726).
///
/// Stores at most [cap] trips under stable IDs, dropping the oldest entries.
///
/// Metadata stays synchronously available; [loadByIdAsync] and
/// [columnSourcesAsync] read payloads on demand. JSON runs on workers,
/// Hive stays on its owner. Legacy rows migrate via [migrateLegacyRow].
class TripHistoryRepository {
  final BoxBase<String> _box;
  final HiveTripHistoryIndex? _index;
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
    // The public constructor keeps its existing named `box` argument.
    // ignore: prefer_initializing_formals
  }) : _box = box,
       _index = null;

  TripHistoryRepository.lazy({
    required LazyBox<String> box,
    this.cap = 100,
    this.onSavedHook,
  }) : _box = box,
       _index = HiveTripHistoryIndex.of(box);

  /// Resolves the production lazy box, or a regular box used by tests.
  static TripHistoryRepository fromOpenBox(String name) {
    try {
      return TripHistoryRepository.lazy(box: Hive.lazyBox<String>(name));
      // Hive uses Error for its regular/lazy type mismatch, not Exception.
      // ignore: avoid_catching_errors
    } on HiveError {
      return TripHistoryRepository(box: Hive.box<String>(name));
    }
  }

  String? _get(Object key) =>
      _index == null ? (_box as Box<String>).get(key) : _index.get(key);
  TripHistoryPayloadReader get _payload => TripHistoryPayloadReader(_box);
  HiveBoxMutationEpoch get _epoch => HiveBoxMutationEpoch.of(_box);
  Future<String?> _read(Object key) => _payload.read(key);
  Future<void> _putAll(Map<dynamic, String> rows) =>
      _index?.putAll(rows) ?? _epoch.mutate(() => _box.putAll(rows));
  Future<void> _deleteAll(Iterable<dynamic> keys) =>
      _index?.deleteAll(keys) ?? _epoch.mutate(() => _box.deleteAll(keys));

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
  ///
  /// #4328 — returns whether the trip is in history now: false when the
  /// write failed. A caller holding the trip's only other copy (the
  /// recording's WAL row) must keep it on false.
  Future<bool> save(TripHistoryEntry entry) async {
    try {
      final skip = await guardGhostDoubleSave(
        entry: entry,
        existing: loadSummaries(dedupe: false),
        deleteById: delete,
      );
      if (skip) return true; // its sampled twin is already in history
    } catch (e, st) {
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: const {'where': 'TripHistoryRepository.save ghost-guard'},
      );
    }
    try {
      await _writeRows(entry);
    } catch (e, st) {
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: const {'where': 'TripHistoryRepository.save'},
      );
      return false;
    }
    await _trim();
    final vehicleId = entry.vehicleId;
    final hook = onSavedHook;
    if (vehicleId != null && hook != null) {
      try {
        hook(entry);
      } catch (e, st) {
        log.error(
          e,
          st,
          layer: ErrorLayer.storage,
          context: const {'where': 'TripHistoryRepository.save onSavedHook'},
        );
      }
    }
    return true;
  }

  /// Encode (#3613: off-thread above the threshold) and write the v2
  /// rows; stale sidecars of a re-saved trip are removed first.
  Future<void> _writeRows(TripHistoryEntry entry) async {
    final json = entry.toJson();
    final rows = entry.samples.length > kTripSaveComputeSampleThreshold
        ? await compute(encodeTripRowsV2, json)
        : encodeTripRowsV2(json);
    await _epoch.mutate(() async {
      await _deleteSidecars(entry.id, keep: rows.keys.toSet());
      await _putAll(rows);
    });
  }

  Future<void> _deleteSidecars(String id, {Set<String> keep = const {}}) async {
    final stale = [
      for (final k in _box.keys.whereType<String>())
        if (isTripSidecarKey(k) && tripIdOfKey(k) == id && !keep.contains(k)) k,
    ];
    if (stale.isNotEmpty) await _deleteAll(stale);
  }

  /// Synchronous compatibility reads for regular (non-lazy) test boxes.
  List<TripColumnSource> columnSources(Iterable<String> ids) =>
      _payload.sourcesSync(ids);

  static bool _isV2(Map<String, dynamic> json) => json['v'] == kTripRowVersion;

  /// Deserialise the trip stored under [key], or null when absent or
  /// corrupt (a single bad row is logged + skipped, never thrown).
  TripHistoryEntry? _decode(Object key, {bool summaryOnly = false}) {
    final raw = _get(key);
    if (raw == null || raw.isEmpty || isTripSidecarKey(key)) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (_isV2(json)) {
        if (summaryOnly) return TripHistoryEntry.summaryFromJson(json);
        return decodeTripRowsV2ToEntry(_payload.rowsSync(key as String, raw));
      }
      if (summaryOnly) return TripHistoryEntry.summaryFromJson(json);
      // Legacy v1 row: decode as before and rewrite it in the background.
      _scheduleMigration(key as String);
      return TripHistoryEntry.fromJson(json);
    } catch (e, st) {
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: {
          'where': 'TripHistoryRepository._decode: skipping $key',
          'entity': key,
        },
      );
      return null;
    }
  }

  final Set<String> _migrating = {};
  void _scheduleMigration(String id) {
    if (!_migrating.add(id)) return;
    unawaited(
      Future<void>(
        () => migrateLegacyRow(id),
      ).whenComplete(() => _migrating.remove(id)),
    );
  }

  /// #3882 — rewrite a legacy v1 row into meta + chunks. No-op on a v2
  /// row or a missing/corrupt one. Returns true when a rewrite happened.
  Future<bool> migrateLegacyRow(String id) async {
    try {
      await _epoch.whenIdle;
      final generation = _epoch.generation;
      final raw = await _read(id);
      if (raw == null || raw.isEmpty) return false;
      final rows = await compute(migrateLegacyTripRow, raw);
      // A delete/edit while the worker was running owns the newer row.
      if (rows == null || generation != _epoch.generation || !_epoch.isIdle) {
        return false;
      }
      await _putAll(rows);
      return true;
    } catch (e, st) {
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: {
          'where': 'TripHistoryRepository.migrateLegacyRow $id',
          'entity': id,
        },
      );
      return false;
    }
  }

  /// #3882 — low-priority sweep: migrate every legacy row, one at a time,
  /// yielding [pause] between rows so the UI isolate stays responsive.
  /// Returns the number of rows rewritten. Never throws.
  Future<int> migrateLegacyRowsInBackground({
    Duration pause = const Duration(milliseconds: 50),
  }) async {
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

  /// Compatibility full read for regular boxes; lazy stores use [loadByIdAsync].
  TripHistoryEntry? loadById(String id) => _decode(id);

  /// #3882 — full decode of one trip on a background isolate: only the
  /// raw strings cross to the worker, the finished entry comes back.
  Future<TripHistoryEntry?> loadByIdAsync(String id) => _loadById(id, false);

  Future<TripHistoryEntry?> _loadById(
    String id,
    bool requireStableSnapshot,
  ) async {
    try {
      final result = await _payload.decode(id);
      if (result == null) return null;
      if (result.legacy) _scheduleMigration(id);
      return result.entry;
    } catch (e, st) {
      if (requireStableSnapshot && e is HiveBoxSnapshotConflict) rethrow;
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: {
          'where': 'TripHistoryRepository.loadByIdAsync $id',
          'entity': id,
        },
      );
      return null;
    }
  }

  Future<List<TripColumnSource>> columnSourcesAsync(Iterable<String> ids) =>
      _payload.sources(ids);

  Future<List<TripSample>> loadSamplesWithAsync(String id, Set<String> keys) =>
      _payload.samples(id, keys);

  Future<List<TripHistoryEntry>> loadAllAsync() async {
    final entries = <TripHistoryEntry>[];
    for (final summary in loadSummaries()) {
      final entry = await _loadById(summary.id, true);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  /// #3882 — only the requested sample columns of one trip (codec keys
  /// such as `s`, `f`, `la`), without materialising samples. Legacy rows
  /// decode fully and are projected. Empty when the trip is absent.
  TripColumns loadColumns(String id, Set<String> keys) =>
      _payload.safeColumnsSync(id, keys);

  /// #3882 — a light sample list carrying only [keys] (plus timestamps),
  /// for readers such as the speed/consumption aggregator that take
  /// `List<TripSample>` but touch two or three fields.
  List<TripSample> loadSamplesWith(String id, Set<String> keys) =>
      samplesFromColumns(loadColumns(id, keys), keys);

  Future<void> delete(String id) => _epoch.mutate(() async {
    await _deleteAll([id]);
    await _deleteSidecars(id);
  });

  /// #3501 — persist the driver's post-trip verdict onto an existing entry.
  /// #3882 — a v2 row rewrites its META row only (the chunks are untouched).
  Future<bool> saveVerdict(String id, TripVerdict verdict) async {
    try {
      await _epoch.whenIdle;
      final generation = _epoch.generation;
      final raw = await _read(id);
      if (raw == null) return false;
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (generation != _epoch.generation || !_epoch.isIdle) return false;
      if (_isV2(json)) {
        json['verdict'] = verdict.wireName;
        await _putAll({id: jsonEncode(json)});
        return true;
      }
      final entry = TripHistoryEntry.fromJson(json);
      await _putAll({
        id: jsonEncode(entry.copyWith(verdict: verdict.wireName).toJson()),
      });
      return true;
    } catch (e, st) {
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: const {'where': 'TripHistoryRepository.saveVerdict'},
      );
      return false;
    }
  }

  /// Wipe every persisted trip (#2571) — backup RESTORE (replace mode).
  Future<void> clearAll() async {
    await (_index?.clear() ??
        _epoch.mutate(() async {
          await _box.clear();
        }));
  }

  Future<void> _trim() async {
    if (storedIds.length <= cap) return;
    final entries = loadSummaries(); // newest-first
    for (final e in entries.skip(cap)) {
      await delete(e.id);
    }
  }
}
