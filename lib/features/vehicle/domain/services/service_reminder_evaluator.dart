import 'package:flutter/foundation.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../data/repositories/service_reminder_repository.dart';
import '../entities/service_reminder.dart';
import 'service_reminder_trigger.dart';

/// Copy of the strings the notification renders. Dart doesn't have
/// test-time locale resolution for background isolates, so the
/// evaluator accepts the already-localised title/body pair from the
/// caller (the provider reads from the active [AppLocalizations]
/// before invoking `evaluate`).
class ServiceReminderMessages {
  final String title;
  final String Function({required String label, required int kmOver}) bodyFor;

  const ServiceReminderMessages({
    required this.title,
    required this.bodyFor,
  });

  /// English fallback used when the UI has no [AppLocalizations]
  /// handy (background isolates, unit tests).
  static const fallback = ServiceReminderMessages(
    title: 'Service due',
    bodyFor: _fallbackBody,
  );

  static String _fallbackBody({required String label, required int kmOver}) {
    if (kmOver <= 0) return '$label is due now.';
    return '$label is due — $kmOver km past the interval.';
  }
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

  const ServiceReminderEvaluator({
    required this.repository,
    required this.notifications,
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
    ServiceReminderMessages messages = ServiceReminderMessages.fallback,
  }) async {
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
        debugPrint('ServiceReminderEvaluator: failed to persist flag: $e\n$st');
        continue;
      }
      try {
        await notifications.showServiceReminder(
          id: notificationIdFor(reminder.id),
          title: messages.title,
          body: messages.bodyFor(
            label: reminder.label,
            kmOver: reminder.kmOverdue(currentOdometerKm).round(),
          ),
        );
      } catch (e, st) {
        debugPrint('ServiceReminderEvaluator: notification failed: $e\n$st');
      }
      fired.add(updated);
    }
    return fired;
  }
}
