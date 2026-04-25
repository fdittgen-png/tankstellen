import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/service_reminder_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';
import 'package:tankstellen/features/vehicle/domain/services/service_reminder_evaluator.dart';

/// Local fake that mirrors `test/core/notifications/notification_service_test.dart`.
/// Duplicated on purpose so this test file stays self-contained and
/// doesn't reach into another test file at import time.
class _FakeNotificationService implements NotificationService {
  final List<({int id, String title, String body})> serviceReminders = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    serviceReminders.add((id: id, title: title, body: body));
  }

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late Directory tempDir;
  late Box<String> box;
  late ServiceReminderRepository repo;
  late _FakeNotificationService notifications;
  late ServiceReminderEvaluator evaluator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reminder_eval_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await box.clear();
    repo = ServiceReminderRepository(box);
    notifications = _FakeNotificationService();
    evaluator = ServiceReminderEvaluator(
      repository: repo,
      notifications: notifications,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ServiceReminderEvaluator (#584)', () {
    test('fires a notification when a reminder is due', () async {
      await repo.save(
        const ServiceReminder(
          id: 'r-1',
          vehicleId: 'v-1',
          label: 'Oil change',
          intervalKm: 15000,
        ),
      );

      final fired = await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 15200,
      );

      expect(fired, hasLength(1));
      expect(notifications.serviceReminders, hasLength(1));
      expect(notifications.serviceReminders.first.title, 'Service due');
      // Default-English fallback: "{label} is due — {kmOver} km past the interval."
      expect(
        notifications.serviceReminders.first.body,
        contains('Oil change'),
      );
      expect(
        notifications.serviceReminders.first.body,
        contains('200'),
      );
    });

    test('does not fire before the threshold', () async {
      await repo.save(
        const ServiceReminder(
          id: 'r-1',
          vehicleId: 'v-1',
          label: 'Oil change',
          intervalKm: 15000,
        ),
      );

      final fired = await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 14000,
      );

      expect(fired, isEmpty);
      expect(notifications.serviceReminders, isEmpty);
    });

    test('persists the pending flag once triggered', () async {
      await repo.save(
        const ServiceReminder(
          id: 'r-1',
          vehicleId: 'v-1',
          label: 'Oil change',
          intervalKm: 15000,
        ),
      );

      await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 15001,
      );

      expect(repo.getById('r-1')!.pendingAcknowledgment, isTrue);
    });

    test('does not re-notify while pending', () async {
      await repo.save(
        const ServiceReminder(
          id: 'r-1',
          vehicleId: 'v-1',
          label: 'Oil change',
          intervalKm: 15000,
        ),
      );

      await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 15200,
      );
      // Second fill-up further past the threshold — the reminder is
      // still pending, so no new notification fires.
      await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 15500,
      );

      expect(notifications.serviceReminders, hasLength(1));
    });

    test('after mark-done at 15000, odometer 20000 does not fire', () async {
      const reminder = ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-1',
        label: 'Oil change',
        intervalKm: 15000,
      );
      await repo.save(reminder);
      await repo.markDone('r-1', 15000);

      await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 20000,
      );

      expect(notifications.serviceReminders, isEmpty);
    });

    test('notification id is stable for the same reminder id', () {
      const id = 'reminder-12345';
      expect(
        ServiceReminderEvaluator.notificationIdFor(id),
        ServiceReminderEvaluator.notificationIdFor(id),
      );
      // Different reminders should generally map to different ids.
      expect(
        ServiceReminderEvaluator.notificationIdFor('reminder-a'),
        isNot(ServiceReminderEvaluator.notificationIdFor('reminder-b')),
      );
    });

    test('respects a localised messages bundle', () async {
      await repo.save(
        const ServiceReminder(
          id: 'r-1',
          vehicleId: 'v-1',
          label: 'Reifen',
          intervalKm: 20000,
        ),
      );

      await evaluator.evaluate(
        vehicleId: 'v-1',
        currentOdometerKm: 21000,
        messages: ServiceReminderMessages(
          title: 'Wartung fällig',
          bodyFor: ({required String label, required int kmOver}) =>
              '$label ist fällig — $kmOver km über dem Intervall.',
        ),
      );

      expect(notifications.serviceReminders, hasLength(1));
      expect(notifications.serviceReminders.first.title, 'Wartung fällig');
      expect(
        notifications.serviceReminders.first.body,
        'Reifen ist fällig — 1000 km über dem Intervall.',
      );
    });
  });
}
