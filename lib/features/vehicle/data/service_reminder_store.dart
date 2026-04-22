import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/entities/service_reminder.dart';

/// Hive-backed store for [ServiceReminder] records (#584 phase 1).
///
/// Reuses the existing encrypted [HiveBoxes.settings] box — see the
/// PR description for why the `profiles` box (the prompt's
/// suggested fallback) is NOT suitable: `ProfilesHiveStore
/// .getAllProfiles()` iterates every value in that box through
/// `UserProfile.fromJson`, which would throw on the extra service-
/// reminder payloads and break the profile listing. The settings
/// box is the only encrypted Hive box in this repo that stores
/// targeted key/value pairs without value-wise enumeration, so it's
/// the right home for a prefix-keyed record set.
///
/// Mirrors the `RadiusAlertStore` pattern (#578 phase 1): keys are
/// `service_reminder:<id>`, which makes `remove` a cheap single-key
/// drop and avoids collisions with unrelated settings keys.
///
/// Every method degrades gracefully when the settings box isn't
/// open (e.g. widget tests that don't call `HiveBoxes.initForTest()`)
/// so providers can `ref.watch` the store without worrying about
/// startup order.
class ServiceReminderStore {
  /// Shared key prefix. Public so future phase-2 background workers
  /// can iterate reminders from an isolate without re-importing this
  /// class.
  static const String keyPrefix = 'service_reminder:';

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return null;
      return Hive.box(HiveBoxes.settings);
    } catch (e) {
      debugPrint('ServiceReminderStore: settings box unavailable: $e');
      return null;
    }
  }

  /// Load every persisted service reminder. Corrupt payloads are
  /// logged and skipped — one bad write mustn't wipe the whole list.
  Future<List<ServiceReminder>> list() async {
    final box = _boxOrNull();
    if (box == null) return const [];
    final out = <ServiceReminder>[];
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(keyPrefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final json = _decode(raw);
        if (json == null) continue;
        out.add(ServiceReminder.fromJson(json));
      } catch (e) {
        debugPrint('ServiceReminderStore.list: skipping $key: $e');
      }
    }
    // Stable order — oldest-first keeps the UI deterministic.
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  /// Return only the reminders attached to [vehicleId]. A thin
  /// wrapper over [list] so the caller doesn't have to filter itself
  /// — the UI / provider nearly always wants a per-vehicle view.
  Future<List<ServiceReminder>> listForVehicle(String vehicleId) async {
    final all = await list();
    return all.where((r) => r.vehicleId == vehicleId).toList();
  }

  /// Insert or overwrite [reminder] by id. The JSON payload is
  /// stored as a plain map (not a JSON string) to mirror the
  /// existing per-alert and per-profile shapes the rest of the app
  /// already reads back.
  Future<void> upsert(ServiceReminder reminder) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'ServiceReminderStore.upsert: settings box closed, dropping ${reminder.id}');
      return;
    }
    await box.put('$keyPrefix${reminder.id}', reminder.toJson());
  }

  /// Remove a reminder by id. No-op when the key isn't present.
  Future<void> remove(String id) async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete('$keyPrefix$id');
  }

  /// Accept either a `Map` (the default Hive round-trip for our
  /// payloads) or a `String` (older entries that may have been
  /// written as JSON text). Returns null when neither shape applies.
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
