import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../domain/entities/service_reminder.dart';

/// CRUD repository for [ServiceReminder] entries (#584).
///
/// Backed by the `service_reminders` Hive box. Each reminder is
/// stored as a JSON-encoded string keyed by its id — the same
/// pattern [HiveBoxes.achievements] and [HiveBoxes.obd2TripHistory]
/// use. No custom TypeAdapter is needed; freezed/json_serializable
/// handles (de)serialisation.
class ServiceReminderRepository {
  final Box<String> _box;

  ServiceReminderRepository(this._box);

  /// Factory that grabs the open box from Hive. Use this in app code;
  /// tests can pass a specific [Box<String>] to the default ctor.
  factory ServiceReminderRepository.fromHive() =>
      ServiceReminderRepository(Hive.box<String>(HiveBoxes.serviceReminders));

  /// Returns all stored reminders, unsorted.
  List<ServiceReminder> getAll() {
    final result = <ServiceReminder>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        result.add(ServiceReminder.fromJson(map));
      } catch (e) {
        debugPrint('ServiceReminderRepository: skipping "$key": $e');
      }
    }
    return result;
  }

  /// Returns all reminders attached to [vehicleId].
  List<ServiceReminder> getForVehicle(String vehicleId) =>
      getAll().where((r) => r.vehicleId == vehicleId).toList();

  /// Returns a single reminder by id or `null` when missing.
  ServiceReminder? getById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ServiceReminder.fromJson(map);
    } catch (e) {
      debugPrint('ServiceReminderRepository: failed to decode "$id": $e');
      return null;
    }
  }

  /// Add or update a single reminder (matched by id).
  Future<void> save(ServiceReminder reminder) async {
    await _box.put(reminder.id, jsonEncode(reminder.toJson()));
  }

  /// Delete a reminder by id. No-op when it does not exist.
  Future<void> delete(String id) async {
    if (_box.containsKey(id)) {
      await _box.delete(id);
    }
  }

  /// Delete every reminder attached to [vehicleId]. Used when the
  /// parent vehicle is removed.
  Future<void> deleteForVehicle(String vehicleId) async {
    final victimKeys = <dynamic>[];
    for (final r in getAll()) {
      if (r.vehicleId == vehicleId) victimKeys.add(r.id);
    }
    if (victimKeys.isNotEmpty) {
      await _box.deleteAll(victimKeys);
    }
  }

  /// Wipe the entire reminder box. Used by the privacy dashboard.
  Future<void> clear() async {
    await _box.clear();
  }

  /// Mark a reminder done at [currentOdometerKm] — rebases
  /// `lastServiceOdometerKm` and clears the pending-ack flag. No-op
  /// when [id] does not resolve.
  Future<ServiceReminder?> markDone(String id, double currentOdometerKm) async {
    final existing = getById(id);
    if (existing == null) return null;
    final updated = existing.markDone(currentOdometerKm);
    await save(updated);
    return updated;
  }
}
