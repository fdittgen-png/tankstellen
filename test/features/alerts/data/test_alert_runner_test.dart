// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_payload.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/features/alerts/data/test_alert_runner.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_evaluator.dart';

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

    // #2408 — when the UI passes a REAL station sample, the encoded payload
    // must carry that station's id so tapping it deep-links to a station
    // `stationDetailProvider` can resolve (instead of the non-resolving
    // synthetic `debug-test-station` that left the detail screen stuck in
    // the shimmer skeleton forever).
    test('fires against the real station id when a station sample is passed',
        () async {
      final notifier = _FakeNotifier();
      final runner = TestAlertRunner(notifier: notifier);
      const sample = StationPriceSample(
        stationId: 'de-12345',
        name: 'Shell Hauptstraße',
        lat: 52.5,
        lng: 13.4,
        fuelType: 'e10',
        pricePerLiter: 1.789,
      );

      final count = await runner.run(
        title: 'T',
        body: 'B',
        station: sample,
        country: 'de',
      );

      expect(count, 1);
      final payload =
          NotificationPayload.tryDecode(notifier.priceAlerts.single.payload);
      expect(payload, isNotNull);
      expect(payload!.stationId, 'de-12345',
          reason: 'the deep link must point at the real station id');
      expect(payload.kind, NotificationPayload.kindRadius);
      expect(payload.country, 'de');
    });

    test('matches a real station even when its price is well above 1.50',
        () async {
      // The old synthetic alert hard-coded a 1.50 threshold, which would
      // never match a real petrol price near 1.80. The threshold now
      // tracks the sample, so any real station matches.
      final notifier = _FakeNotifier();
      final runner = TestAlertRunner(notifier: notifier);
      const sample = StationPriceSample(
        stationId: 'fr-99',
        name: 'Total',
        lat: 48.8,
        lng: 2.3,
        fuelType: 'diesel',
        pricePerLiter: 1.92,
      );

      final count = await runner.run(title: 'T', body: 'B', station: sample);

      expect(count, 1);
      final payload =
          NotificationPayload.tryDecode(notifier.priceAlerts.single.payload);
      expect(payload!.stationId, 'fr-99');
    });

    test('falls back to the synthetic sample when no station is passed',
        () async {
      final notifier = _FakeNotifier();
      final runner = TestAlertRunner(notifier: notifier);

      final count = await runner.run(title: 'T', body: 'B');

      expect(count, 1);
      final payload =
          NotificationPayload.tryDecode(notifier.priceAlerts.single.payload);
      expect(payload!.stationId, 'debug-test-station',
          reason: 'last-resort synthetic path is preserved');
    });
  });
}
