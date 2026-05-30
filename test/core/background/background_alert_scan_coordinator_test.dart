// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_alert_scan_coordinator.dart';
import 'package:tankstellen/core/background/background_scan_runners.dart';
import 'package:tankstellen/core/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_runner.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_evaluator.dart';
import 'package:tankstellen/features/alerts/domain/velocity_alert_detector.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #2415 — the shared scan coordinator. The full [scan] body needs Hive +
/// platform channels, so here we lock down the pure, platform-neutral
/// surface: the trigger taxonomy, the cooldown tuning, and the notification
/// copy builders all triggers share.
void main() {
  group('BackgroundScanTrigger', () {
    test('every trigger has a stable, unique log tag', () {
      final tags =
          BackgroundScanTrigger.values.map((t) => t.tag).toSet();
      expect(tags.length, BackgroundScanTrigger.values.length,
          reason: 'trigger tags must be unique');
      expect(
        tags,
        containsAll(<String>[
          'workmanager_periodic',
          'workmanager_charging',
          'android_widget',
          'ios_bg_refresh',
        ]),
      );
    });
  });

  group('cooldown tuning', () {
    test('scan cooldown is shorter than the charging cadence', () {
      // The coarse cross-trigger cooldown must never starve a legitimately
      // scheduled 30-minute charging task.
      expect(
        BackgroundAlertScanCoordinator.scanCooldown,
        lessThan(const Duration(minutes: 30)),
      );
      expect(
        BackgroundAlertScanCoordinator.scanCooldown,
        greaterThan(Duration.zero),
      );
    });

    test('per-alert retrigger cooldown is far longer than scan cooldown', () {
      // The per-alert throttle (don\'t re-notify the same alert) is a
      // separate, much longer window than the trigger-dedup cooldown.
      expect(
        BackgroundAlertScanCoordinator.priceAlertRetriggerCooldown,
        greaterThan(BackgroundAlertScanCoordinator.scanCooldown),
      );
    });
  });

  group('tankerkoenigKeyFor', () {
    test('maps the three BG-supported fuels', () {
      expect(tankerkoenigKeyFor(FuelType.e5), 'e5');
      expect(tankerkoenigKeyFor(FuelType.e10), 'e10');
      expect(tankerkoenigKeyFor(FuelType.diesel), 'diesel');
    });

    test('returns null for fuels the BG isolate cannot fetch', () {
      expect(tankerkoenigKeyFor(FuelType.lpg), isNull);
      expect(tankerkoenigKeyFor(FuelType.electric), isNull);
    });
  });

  final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

  group('buildVelocityCopy', () {
    test('renders station count and max drop in the body', () {
      final copy = buildVelocityCopy(
        const VelocityAlertEvent(
          fuelType: FuelType.diesel,
          affectedStationIds: ['s1', 's2', 's3'],
          maxDropCents: 7.4,
        ),
        templates,
      );
      expect(copy.body, contains('3'));
      expect(copy.body, contains('7'));
      expect(copy.title, isNotEmpty);
    });
  });

  group('buildRadiusAlertCopy', () {
    RadiusAlert alert() => RadiusAlert(
          id: 'a1',
          fuelType: 'diesel',
          threshold: 1.659,
          centerLat: 52.5,
          centerLng: 13.4,
          radiusKm: 5,
          label: 'Home diesel',
          createdAt: DateTime.utc(2026, 5, 30),
        );

    StationPriceSample sample(String id, double price) => StationPriceSample(
          stationId: id,
          name: id,
          lat: 52.5,
          lng: 13.4,
          fuelType: 'diesel',
          pricePerLiter: price,
        );

    test('title carries the label, total count, and threshold', () {
      final copy = buildRadiusAlertCopy(
        RadiusAlertGroupedEvent(
          alert: alert(),
          matches: [sample('s1', 1.629), sample('s2', 1.639)],
        ),
        templates,
      );
      expect(copy.title, contains('Home diesel'));
      expect(copy.title, contains('2'));
      expect(copy.title, contains('1.659'));
    });

    test('appends a "+ N more" line when matches were truncated', () {
      final copy = buildRadiusAlertCopy(
        RadiusAlertGroupedEvent(
          alert: alert(),
          matches: [sample('s1', 1.629)],
          truncatedMoreCount: 4,
        ),
        templates,
      );
      // total = visible (1) + truncated (4) = 5
      expect(copy.title, contains('5'));
      expect(copy.body, contains('4'));
    });
  });
}
