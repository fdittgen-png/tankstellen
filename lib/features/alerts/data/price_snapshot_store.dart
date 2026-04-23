import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import 'models/price_snapshot.dart';

/// Hive-backed rolling store of [PriceSnapshot] records (#579).
///
/// Feeds the velocity detector by keeping a short history (last 6 h
/// by default) of observed fuel prices per station. Every
/// [recordSnapshot] call auto-prunes anything older than
/// [retention] so the box stays bounded regardless of how long the
/// user runs the app.
///
/// Keys are synthetic composites of
/// `station:fuel:epochMillis` — collisions are impossible at the
/// millisecond resolution the background worker uses (one fetch
/// per hour on battery, per 30 min on charger) and the prefix makes
/// tests and ad-hoc inspection easier than raw hashes.
class PriceSnapshotStore {
  /// How long a snapshot stays in the box before being pruned on
  /// write. The issue specifies 6 h to comfortably cover the default
  /// 1 h lookback plus a few fetch cycles for the detector to compare.
  static const Duration retention = Duration(hours: 6);

  /// Key prefix for every snapshot. Public so background and tests
  /// can iterate without re-importing private constants.
  static const String keyPrefix = 'snapshot:';

  /// Injectable clock — production callers leave the default
  /// [DateTime.now]. Tests pass a fixed instant to assert pruning.
  final DateTime Function() _now;

  PriceSnapshotStore({DateTime Function()? now}) : _now = now ?? DateTime.now;

  Box<String>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.priceSnapshots)) return null;
      return Hive.box<String>(HiveBoxes.priceSnapshots);
    } catch (e) {
      debugPrint('PriceSnapshotStore: box unavailable: $e');
      return null;
    }
  }

  /// Record a new snapshot and prune anything older than
  /// [retention]. Missing box (e.g. tests that skipped
  /// [HiveBoxes.initForTest]) is logged and ignored so the caller
  /// never has to guard.
  Future<void> recordSnapshot(PriceSnapshot snapshot) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'PriceSnapshotStore.recordSnapshot: box closed, dropping ${snapshot.stationId}');
      return;
    }
    final key =
        '$keyPrefix${snapshot.stationId}:${snapshot.fuelType}:${snapshot.timestamp.millisecondsSinceEpoch}';
    await box.put(key, jsonEncode(snapshot.toJson()));
    await _prune(box);
  }

  /// Return every snapshot currently in the box, oldest-first.
  /// Corrupt payloads are logged and skipped so one bad write can't
  /// blind the detector.
  Future<List<PriceSnapshot>> all() async {
    final box = _boxOrNull();
    if (box == null) return const [];
    final out = <PriceSnapshot>[];
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(keyPrefix)) continue;
      final raw = box.get(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final map = HiveBoxes.toStringDynamicMap(decoded);
          if (map == null) continue;
          out.add(PriceSnapshot.fromJson(map));
        }
      } catch (e) {
        debugPrint('PriceSnapshotStore.all: skipping $key: $e');
      }
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  /// Return snapshots strictly older than [cutoff]. Used by the
  /// detector to pick a "before" comparison point for each station.
  Future<List<PriceSnapshot>> snapshotsOlderThan(Duration lookback) async {
    final cutoff = _now().subtract(lookback);
    final all = await this.all();
    return all.where((s) => s.timestamp.isBefore(cutoff)).toList();
  }

  /// Drop every snapshot in the box. Used by tests.
  @visibleForTesting
  Future<void> clear() async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.clear();
  }

  /// Remove snapshots older than [retention]. Cheap: iterates the
  /// keys once, deletes in a batch.
  Future<void> _prune(Box<String> box) async {
    final cutoff = _now().subtract(retention);
    final toDelete = <String>[];
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(keyPrefix)) continue;
      final raw = box.get(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          toDelete.add(key);
          continue;
        }
        final ts = DateTime.tryParse(decoded['timestamp']?.toString() ?? '');
        if (ts == null || ts.isBefore(cutoff)) {
          toDelete.add(key);
        }
      } catch (e) {
        debugPrint('PriceSnapshotStore._prune: removing corrupt $key: $e');
        toDelete.add(key);
      }
    }
    if (toDelete.isNotEmpty) {
      await box.deleteAll(toDelete);
    }
  }
}
