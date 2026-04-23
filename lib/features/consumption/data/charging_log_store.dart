import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../ev/domain/entities/charging_log.dart';

/// Hive-backed CRUD store for [ChargingLog] records (#582 phase 1).
///
/// Reuses the existing encrypted [HiveBoxes.settings] box — no new
/// box — and namespaces its keys under `charging_log:<id>` so the
/// rest of the settings payloads (user preferences, last-used
/// filters, etc.) are untouched. Keys-with-prefix also mean deleting
/// a single log is a cheap `delete(key)` rather than rewriting a
/// whole list.
///
/// Storage format mirrors [HiveBoxes.achievements] /
/// `service_reminders`: each entry is a JSON **string** payload so
/// no custom TypeAdapter is needed and the encrypted settings box
/// (which holds mixed value types) stays predictable.
///
/// Every method degrades gracefully when the settings box isn't open
/// — widget tests that skip the full `HiveBoxes.init` pathway can
/// still construct a provider that watches an empty list instead of
/// crashing at read time.
class ChargingLogStore {
  /// Shared key prefix. Exposed publicly so a future background
  /// isolate (e.g. Supabase sync worker) can iterate the logs
  /// without importing this class.
  static const String keyPrefix = 'charging_log:';

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return null;
      return Hive.box(HiveBoxes.settings);
    } catch (e) {
      debugPrint('ChargingLogStore: settings box unavailable: $e');
      return null;
    }
  }

  /// Every persisted log across all vehicles, oldest-first by [ChargingLog.date].
  ///
  /// Corrupt payloads are logged via `debugPrint` and skipped so one
  /// bad write cannot wipe the whole history.
  Future<List<ChargingLog>> list() async {
    final box = _boxOrNull();
    if (box == null) return const [];
    final out = <ChargingLog>[];
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(keyPrefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final json = _decode(raw);
        if (json == null) continue;
        out.add(ChargingLog.fromJson(json));
      } catch (e) {
        debugPrint('ChargingLogStore.list: skipping $key: $e');
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Subset of [list] filtered to the supplied [vehicleId]. Cheap
  /// enough to re-run on every mutation — the expected backlog size
  /// is "dozens per car" over the product's life.
  Future<List<ChargingLog>> listForVehicle(String vehicleId) async {
    final all = await list();
    return all.where((log) => log.vehicleId == vehicleId).toList();
  }

  /// Insert or overwrite [log] by id. No-op when the settings box is
  /// closed — the provider retries on next read.
  Future<void> upsert(ChargingLog log) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'ChargingLogStore.upsert: settings box closed, dropping ${log.id}');
      return;
    }
    await box.put('$keyPrefix${log.id}', jsonEncode(log.toJson()));
  }

  /// Remove the log with [id]. Silent no-op when the key is missing —
  /// the UI layer decides whether to surface that to the user.
  Future<void> remove(String id) async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete('$keyPrefix$id');
  }

  /// Accept either a JSON string (our canonical shape) or a raw Map
  /// (belt-and-braces for entries written via an older code path).
  /// Returns null when neither shape applies so the caller can skip
  /// silently.
  Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is String) {
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return HiveBoxes.toStringDynamicMap(decoded);
      return null;
    }
    if (raw is Map) {
      return HiveBoxes.toStringDynamicMap(raw);
    }
    return null;
  }
}
