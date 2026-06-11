// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/notifications/notification_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/service_reminder_repository.dart';
import '../entities/service_reminder.dart';
import 'service_reminder_trigger.dart';
import '../../../../core/logging/error_logger.dart';

/// Copy of the strings the notification renders. The evaluator accepts
/// the already-localised title/body pair from the caller; context-free
/// callers (the fill-up save hook) build it via [fromL10n] with a
/// `lookupAppLocalizations` resolve (the #2766 pattern, #3162) — never
/// an English fallback table.
class ServiceReminderMessages {
  final String title;
  final String Function({required String label, required int kmOver}) bodyFor;

  const ServiceReminderMessages({required this.title, required this.bodyFor});

  /// Builds the localized bundle from [l] (#3162).
  factory ServiceReminderMessages.fromL10n(AppLocalizations l) =>
      ServiceReminderMessages(
        title: l.serviceReminderDueTitle,
        bodyFor: ({required String label, required int kmOver}) => kmOver <= 0
            ? l.serviceReminderDueNowBody(label)
            : l.serviceReminderDueBody(label, kmOver),
      );
}

/// Coordinates the three layers of the #584 reminder flow:
///   1. Pure trigger logic ([ServiceReminderTrigger]).
///   2. Persistence of the `pendingAcknowledgment` flag via
///      [ServiceReminderRepository].
///   3. A local notification per triggered reminder via
///      [NotificationService].
///
/// Keeping the evaluator separate from the provider makes it testable
/// without Riverpod and keeps the fill-up save path's hook trivial.
class ServiceReminderEvaluator {
  final ServiceReminderRepository repository;
  final NotificationService notifications;
  final ServiceReminderTrigger trigger;

  /// Localized notification copy, injected by the provider (#3162) —
  /// built there via `lookupAppLocalizations` (the #2766 pattern) so
  /// the context-free fill-up save hook never falls back to English.
  final ServiceReminderMessages messages;

  const ServiceReminderEvaluator({
    required this.repository,
    required this.notifications,
    required this.messages,
    this.trigger = const ServiceReminderTrigger(),
  });

  /// Stable 32-bit id derived from the reminder id. Local
  /// notifications are keyed by int; hashing the reminder's id gives
  /// us a deterministic mapping so repeated triggers for the same
  /// reminder replace rather than stack.
  static int notificationIdFor(String reminderId) {
    // Use the absolute value to stay positive and clamp to int32 so
    // platform channels do not choke on 64-bit values.
    return reminderId.hashCode.abs() & 0x7fffffff;
  }

  /// Evaluate every reminder attached to [vehicleId] against
  /// [currentOdometerKm]. For each triggered reminder, persists the
  /// `pendingAcknowledgment = true` flag and fires a local
  /// notification. Returns the list of reminders that fired (useful
  /// for callers that want to show a snackbar).
  Future<List<ServiceReminder>> evaluate({
    required String vehicleId,
    required double currentOdometerKm,
    ServiceReminderMessages? messages,
  }) async {
    final copy = messages ?? this.messages;
    final all = repository.getForVehicle(vehicleId);
    final triggered = trigger.findTriggered(
      vehicleId: vehicleId,
      currentOdometerKm: currentOdometerKm,
      reminders: all,
    );
    if (triggered.isEmpty) return const [];

    final fired = <ServiceReminder>[];
    for (final reminder in triggered) {
      // Flip the pending flag first so a race (second fill-up while
      // the notification is still showing) doesn't re-notify.
      final updated = reminder.copyWith(pendingAcknowledgment: true);
      try {
        await repository.save(updated);
      } catch (e, st) {
        unawaited(
          errorLogger.log(
            ErrorLayer.other,
            e,
            st,
            context: const {
              'where': 'ServiceReminderEvaluator: failed to persist flag',
            },
          ),
        );
        continue;
      }
      try {
        await notifications.showServiceReminder(
          id: notificationIdFor(reminder.id),
          title: copy.title,
          body: copy.bodyFor(
            label: reminder.label,
            kmOver: reminder.kmOverdue(currentOdometerKm).round(),
          ),
        );
      } catch (e, st) {
        unawaited(
          errorLogger.log(
            ErrorLayer.other,
            e,
            st,
            context: const {
              'where': 'ServiceReminderEvaluator: notification failed',
            },
          ),
        );
      }
      fired.add(updated);
    }
    return fired;
  }
}
