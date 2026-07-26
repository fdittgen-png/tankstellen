// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/storage/json_box_repository.dart';
import '../../domain/entities/service_reminder.dart';

/// CRUD repository for [ServiceReminder] entries (#584).
///
/// Backed by the `service_reminders` Hive box. Each reminder is
/// stored as a JSON-encoded string keyed by its id — the same
/// pattern [HiveBoxes.achievements] and [HiveBoxes.obd2TripHistory]
/// use. No custom TypeAdapter is needed; freezed/json_serializable
/// handles (de)serialisation. Storage mechanics live in
/// [JsonBoxRepository] (#3614).
class ServiceReminderRepository extends JsonBoxRepository<ServiceReminder> {
  ServiceReminderRepository(Box<String> box)
      : super(
          box: box,
          fromJson: ServiceReminder.fromJson,
          toJson: (reminder) => reminder.toJson(),
          keyOf: (reminder) => reminder.id,
          debugName: 'ServiceReminderRepository',
        );

  /// Factory that grabs the open box from Hive. Use this in app code;
  /// tests can pass a specific [Box<String>] to the default ctor.
  factory ServiceReminderRepository.fromHive() =>
      ServiceReminderRepository(Hive.box<String>(HiveBoxes.serviceReminders));

  // getAll() — inherited from [JsonBoxRepository]: all stored
  // reminders, unsorted, corrupt entries skipped-and-logged.

  /// Returns all reminders attached to [vehicleId].
  List<ServiceReminder> getForVehicle(String vehicleId) =>
      getAll().where((r) => r.vehicleId == vehicleId).toList();

  /// Returns a single reminder by id or `null` when missing.
  ServiceReminder? getById(String id) => getByKey(id);

  /// Add or update a single reminder (matched by id).
  ///
  /// Callers fire-and-forget this write, so a failure is logged rather
  /// than rethrown — rethrowing would surface as an unhandled zone
  /// error with nobody awaiting it.
  Future<void> save(ServiceReminder reminder) async {
    try {
      await put(reminder);
    } catch (e, st) {
      // TODO(#3610-follow-up): surface to user
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'where': 'ServiceReminderRepository.save',
        'reminderId': reminder.id,
      }));
    }
  }

  /// Delete a reminder by id. No-op when it does not exist.
  ///
  /// Same fire-and-forget contract as [save]: log, never rethrow.
  Future<void> delete(String id) async {
    try {
      if (box.containsKey(id)) {
        await deleteByKey(id);
      }
    } catch (e, st) {
      // TODO(#3610-follow-up): surface to user
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'where': 'ServiceReminderRepository.delete',
        'reminderId': id,
      }));
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
      await box.deleteAll(victimKeys);
    }
  }

  /// Wipe the entire reminder box. Used by the privacy dashboard.
  Future<void> clear() async {
    await box.clear();
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
