// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui' as ui;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/repositories/service_reminder_repository.dart';
import '../domain/entities/service_reminder.dart';
import '../domain/services/service_reminder_evaluator.dart';

part 'service_reminder_providers.g.dart';

/// Repository for CRUD on [ServiceReminder] entries (#584).
///
/// Opens against the already-registered `service_reminders` Hive box
/// (see [HiveBoxes.serviceReminders]).
@Riverpod(keepAlive: true)
ServiceReminderRepository serviceReminderRepository(Ref ref) {
  return ServiceReminderRepository.fromHive();
}

/// Evaluator that combines [ServiceReminderRepository] with the
/// app's [NotificationService]. Exposed as a provider so the fill-up
/// save path can fire it after a new fill-up is persisted.
@Riverpod(keepAlive: true)
ServiceReminderEvaluator serviceReminderEvaluator(Ref ref) {
  return ServiceReminderEvaluator(
    repository: ref.watch(serviceReminderRepositoryProvider),
    notifications: ref.watch(notificationServiceProvider),
    // #3162 — localized notification copy via the context-free
    // `lookupAppLocalizations` resolve (the #2766 pattern); previously
    // the evaluator silently fired an English fallback table on every
    // locale. Guarded so a harness without the language graph degrades
    // to English; the `en` lookup itself is total (template locale).
    messages: ServiceReminderMessages.fromL10n(_reminderL10n(ref)),
  );
}

AppLocalizations _reminderL10n(Ref ref) {
  String code;
  try {
    code = ref.watch(activeLanguageProvider).code;
  } on Object {
    code = 'en';
  }
  try {
    return lookupAppLocalizations(ui.Locale(code));
  } on Object {
    return lookupAppLocalizations(const ui.Locale('en'));
  }
}

/// Mutable list of every stored reminder. Individual screens watch
/// [serviceRemindersForVehicle] — this provider is the source of
/// truth for the mutations.
@Riverpod(keepAlive: true)
class ServiceReminderList extends _$ServiceReminderList {
  @override
  List<ServiceReminder> build() {
    return ref.watch(serviceReminderRepositoryProvider).getAll();
  }

  Future<void> save(ServiceReminder reminder) async {
    await ref.read(serviceReminderRepositoryProvider).save(reminder);
    state = ref.read(serviceReminderRepositoryProvider).getAll();
  }

  Future<void> remove(String id) async {
    await ref.read(serviceReminderRepositoryProvider).delete(id);
    state = ref.read(serviceReminderRepositoryProvider).getAll();
  }

  /// Mark the reminder done at [currentOdometerKm] — rebases the
  /// threshold and clears the pending flag.
  Future<void> markDone(String id, double currentOdometerKm) async {
    await ref
        .read(serviceReminderRepositoryProvider)
        .markDone(id, currentOdometerKm);
    state = ref.read(serviceReminderRepositoryProvider).getAll();
  }

  /// Used when a vehicle is deleted — cascades the reminders so the
  /// box does not accumulate orphans.
  Future<void> removeAllForVehicle(String vehicleId) async {
    await ref
        .read(serviceReminderRepositoryProvider)
        .deleteForVehicle(vehicleId);
    state = ref.read(serviceReminderRepositoryProvider).getAll();
  }
}

/// Derived list of reminders attached to a specific vehicle.
///
/// Vehicle-edit UI watches this instead of the global list so a
/// reminder change on one vehicle doesn't invalidate the edit screen
/// of another.
@riverpod
List<ServiceReminder> serviceRemindersForVehicle(Ref ref, String vehicleId) {
  return ref
      .watch(serviceReminderListProvider)
      .where((r) => r.vehicleId == vehicleId)
      .toList();
}
