// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/features/alerts/data/test_alert_runner.dart';

/// Records every notification the runner emits and lets the test control
/// whether the OS permission is granted. Stand-in for
/// [LocalNotificationService] — [TestAlertRunner] only needs
/// `requestPermission` + `showPriceAlert`.
class _FakeNotifier implements NotificationService {
  _FakeNotifier({this.permissionGranted = true});

  final bool permissionGranted;
  int permissionRequests = 0;

  final List<({int id, String title, String body, String? payload})>
      priceAlerts = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    priceAlerts.add((id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  group('TestAlertRunner (#2248)', () {
    test('fires exactly one notification against the synthetic match', () async {
      final notifier = _FakeNotifier();
      final runner = TestAlertRunner(notifier: notifier);

      final count = await runner.run(title: 'Title', body: 'Body');

      expect(count, 1);
      expect(notifier.priceAlerts, hasLength(1));
      final fired = notifier.priceAlerts.single;
      expect(fired.id, TestAlertRunner.notificationId);
      expect(fired.title, 'Title');
      expect(fired.body, 'Body');
      // The payload is a real radius-kind deep-link payload so tapping it
      // resolves the same way a production radius alert does.
      expect(fired.payload, isNotNull);
      expect(fired.payload, contains('radius'));
    });

    test('requests the OS permission before firing', () async {
      final notifier = _FakeNotifier();
      final runner = TestAlertRunner(notifier: notifier);

      await runner.run(title: 'T', body: 'B');

      expect(notifier.permissionRequests, 1);
    });

    test('fires nothing and returns 0 when notifications are blocked',
        () async {
      final notifier = _FakeNotifier(permissionGranted: false);
      final runner = TestAlertRunner(notifier: notifier);

      final count = await runner.run(title: 'T', body: 'B');

      expect(count, 0);
      expect(notifier.priceAlerts, isEmpty);
    });

    test('re-running overwrites the same notification id (no stacking)',
        () async {
      final notifier = _FakeNotifier();
      final runner = TestAlertRunner(notifier: notifier);

      await runner.run(title: 'T', body: 'B');
      await runner.run(title: 'T', body: 'B');

      expect(notifier.priceAlerts, hasLength(2));
      expect(
        notifier.priceAlerts.map((e) => e.id).toSet(),
        {TestAlertRunner.notificationId},
        reason: 'a stable id means re-fires update the banner in place',
      );
    });
  });
}
