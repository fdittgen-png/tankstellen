// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../obd2/api.dart' show ActiveTripRepository;
import 'trip_history_repository.dart';

/// #4378 — trips whose history write failed, kept under their OWN id until
/// a retry lands.
///
/// #4328 made a failed save keep the active-trip WAL row, so the trip
/// survives to the next launch. But that box holds exactly ONE row (the
/// `active` sentinel): the next recording seeds over it, and the unsaved
/// trip was gone. A kept trip is the whole [TripHistoryEntry] — samples
/// included — written beside the sentinel under `pending-save:<id>`, so a
/// new recording cannot touch it and the retry needs nothing else.
///
/// It lives in the active-trip box rather than a box of its own because
/// that box is already deferred-opened, already encrypted (#3611) and
/// already the recording's durability surface; `ActiveTripRepository`
/// reads and clears only the sentinel, so the two never collide.
class PendingTripSaves {
  PendingTripSaves({required Box<String> box})
      : _box = box; // ignore: prefer_initializing_formals

  final Box<String> _box;

  /// Row-key prefix inside the active-trip box.
  static const String keyPrefix = 'pending-save:';

  /// At most this many kept trips: a disk that keeps failing must not turn
  /// the box into an unbounded log. The oldest keys go first.
  static const int cap = 20;

  /// The store over the open active-trip box, or null when it is closed
  /// (widget tests, a launch before the deferred opens).
  static PendingTripSaves? resolve() {
    if (!Hive.isBoxOpen(ActiveTripRepository.boxName)) return null;
    try {
      return PendingTripSaves(
          box: Hive.box<String>(ActiveTripRepository.boxName));
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'PendingTripSaves.resolve'});
      return null;
    }
  }

  /// Keep [entry] for a later retry. Best-effort: the write that brought
  /// us here already failed, and this one must not throw on top of it.
  Future<void> keep(TripHistoryEntry entry) async {
    try {
      await _box.put('$keyPrefix${entry.id}', jsonEncode(entry.toJson()));
      final keys = _keys().toList();
      if (keys.length > cap) await _box.deleteAll(keys.take(keys.length - cap));
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'PendingTripSaves.keep'});
    }
  }

  /// Every kept trip, oldest first. A corrupt row is logged and skipped.
  List<TripHistoryEntry> loadAll() {
    final out = <TripHistoryEntry>[];
    for (final key in _keys()) {
      final raw = _box.get(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        out.add(TripHistoryEntry.fromJson(
            (jsonDecode(raw) as Map).cast<String, dynamic>()));
      } catch (e, st) {
        log.error(e, st, layer: ErrorLayer.storage, context: {'where': 'PendingTripSaves.loadAll: skipping $key', 'entity': key});
      }
    }
    return out;
  }

  /// Drop the kept copy of trip [id] — it is in history now.
  Future<void> drop(String id) async {
    try {
      await _box.delete('$keyPrefix$id');
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'PendingTripSaves.drop'});
    }
  }

  Iterable<String> _keys() =>
      _box.keys.whereType<String>().where((k) => k.startsWith(keyPrefix));
}

/// #4378 — retry every kept trip into history; returns how many landed.
///
/// Runs at launch (before the recovery sweeps, so a trip that lands turns
/// its own WAL row into an already-saved row the active pass retires —
/// #4328) and behind the stop's "Retry" action. A trip that lands drops
/// its kept copy, and the WAL row it left behind goes with it. A trip that
/// fails again stays kept: the next launch tries once more.
Future<int> retryPendingTripSaves({TripHistoryRepository? historyRepo}) async {
  final pending = PendingTripSaves.resolve();
  if (pending == null) return 0;
  final repo = historyRepo ?? _resolveHistory();
  if (repo == null) return 0;
  var saved = 0;
  for (final entry in pending.loadAll()) {
    try {
      if (!await repo.save(entry)) continue;
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'retryPendingTripSaves: save failed again'});
      continue;
    }
    saved++;
    await pending.drop(entry.id);
    await _retireWalRowOf(entry.id);
  }
  return saved;
}

TripHistoryRepository? _resolveHistory() {
  if (!Hive.isBoxOpen(TripHistoryRepository.boxName)) return null;
  try {
    return TripHistoryRepository(
        box: Hive.box<String>(TripHistoryRepository.boxName));
  } catch (e, st) {
    log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'retryPendingTripSaves: history repo'});
    return null;
  }
}

/// The saved trip's WAL row is the copy the launch recovery would hand
/// back; it belongs to THIS trip only when the ids match (#4328).
Future<void> _retireWalRowOf(String id) async {
  if (!Hive.isBoxOpen(ActiveTripRepository.boxName)) return;
  try {
    final repo = ActiveTripRepository(
        box: Hive.box<String>(ActiveTripRepository.boxName));
    if (repo.loadSnapshot()?.id != id) return;
    await repo.clearSnapshot();
  } catch (e, st) {
    log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'retryPendingTripSaves: WAL retire'});
  }
}
