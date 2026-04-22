import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/entities/radius_alert.dart';

/// Hive-backed store for [RadiusAlert] records (#578 phase 1).
///
/// Reuses the existing [HiveBoxes.alerts] box — deliberately *no*
/// new box — and namespaces its keys under `radius_alert:<id>` so
/// the legacy per-station [PriceAlert] list stored under the
/// `'alerts'` key is left untouched. That also means deleting a
/// RadiusAlert by id is a cheap single-key drop rather than a list
/// rewrite.
///
/// Every method degrades gracefully when the alerts box isn't open
/// yet (e.g. widget tests that never call `HiveBoxes.initForTest()`)
/// so the provider can `ref.watch` us from the tree without
/// worrying about startup order.
class RadiusAlertStore {
  /// Shared key prefix. Public so the phase-2 background worker can
  /// iterate alerts from an isolate without re-importing this class.
  static const String keyPrefix = 'radius_alert:';

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e) {
      debugPrint('RadiusAlertStore: alerts box unavailable: $e');
      return null;
    }
  }

  /// Load every persisted radius alert. Corrupt payloads are logged
  /// and skipped — one bad write mustn't wipe the whole watchlist.
  Future<List<RadiusAlert>> list() async {
    final box = _boxOrNull();
    if (box == null) return const [];
    final out = <RadiusAlert>[];
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(keyPrefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final json = _decode(raw);
        if (json == null) continue;
        out.add(RadiusAlert.fromJson(json));
      } catch (e) {
        debugPrint('RadiusAlertStore.list: skipping $key: $e');
      }
    }
    // Stable order — oldest-first keeps the UI deterministic across
    // reloads.
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  /// Insert or overwrite [alert] by id. The JSON payload is stored
  /// as a plain map (not a JSON string) to mirror the way the legacy
  /// per-station alerts already sit in this box.
  Future<void> upsert(RadiusAlert alert) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint('RadiusAlertStore.upsert: alerts box closed, dropping ${alert.id}');
      return;
    }
    await box.put('$keyPrefix${alert.id}', alert.toJson());
  }

  /// Remove a radius alert by id. No-op when the key isn't present.
  Future<void> remove(String id) async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete('$keyPrefix$id');
  }

  /// Accept either a `Map` (the default Hive round-trip for our
  /// payloads) or a `String` (belt-and-braces for older entries that
  /// may have been written as JSON text elsewhere). Returns null when
  /// neither shape applies.
  Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is Map) {
      return HiveBoxes.toStringDynamicMap(raw);
    }
    if (raw is String) {
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return HiveBoxes.toStringDynamicMap(decoded);
    }
    return null;
  }
}
