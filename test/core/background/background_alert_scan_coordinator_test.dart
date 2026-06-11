// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_alert_scan_coordinator.dart';
import 'package:tankstellen/core/background/background_scan_runners.dart';
import 'package:tankstellen/core/background/fuel_price_fields.dart';
import 'package:tankstellen/core/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_runner.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_evaluator.dart';
import 'package:tankstellen/features/alerts/domain/velocity_alert_detector.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

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
          // #2866 — the charging-only trigger was dropped with the 30-min
          // cadence; the twice-daily scan reports `workmanager_periodic`.
          'workmanager_periodic',
          'android_widget',
          'ios_bg_refresh',
          // #3169 — the iOS alert-delivery mitigation lanes. These exact
          // tags land in the #3147 journal rows, so the SLA is field-
          // verifiable per wake source from one export.
          'bgProcessing',
          'slcWake',
          'opportunistic',
        ]),
      );
      expect(tags, isNot(contains('workmanager_charging')),
          reason: 'the charging trigger was removed (#2866)');
    });

    test('the #3169 mitigation triggers map to their journal tags', () {
      expect(BackgroundScanTrigger.iosBgProcessing.tag, 'bgProcessing');
      expect(BackgroundScanTrigger.iosSlcWake.tag, 'slcWake');
      expect(BackgroundScanTrigger.opportunistic.tag, 'opportunistic');
    });
  });

  group('cooldown tuning', () {
    test('scan cooldown is far shorter than the twice-daily cadence', () {
      // The coarse cross-trigger cooldown must never starve a legitimately
      // scheduled periodic scan. With the twice-daily (~12h) cadence (#2866)
      // a 10-minute cooldown only ever dedups a burst of near-simultaneous
      // triggers (e.g. an opportunistic widget refresh + the periodic wake).
      expect(
        BackgroundAlertScanCoordinator.scanCooldown,
        lessThan(const Duration(hours: 12)),
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

  group('priceFieldKeyFor (#2864)', () {
    test('maps the DE-historical fuels to their byte-identical keys', () {
      expect(priceFieldKeyFor(FuelType.e5), 'e5');
      expect(priceFieldKeyFor(FuelType.e10), 'e10');
      expect(priceFieldKeyFor(FuelType.diesel), 'diesel');
    });

    test('maps the widened fuel set to the price-map keys', () {
      expect(priceFieldKeyFor(FuelType.e98), 'e98');
      // diesel-premium is camelCase in the map, NOT its snake_case apiValue.
      expect(priceFieldKeyFor(FuelType.dieselPremium), 'dieselPremium');
      expect(priceFieldKeyFor(FuelType.e85), 'e85');
      expect(priceFieldKeyFor(FuelType.lpg), 'lpg');
      expect(priceFieldKeyFor(FuelType.cng), 'cng');
    });

    test('returns null for fuels with no price field in the feed', () {
      expect(priceFieldKeyFor(FuelType.electric), isNull);
      expect(priceFieldKeyFor(FuelType.hydrogen), isNull);
      expect(priceFieldKeyFor(FuelType.all), isNull);
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

    test('a DE centre renders the euro (byte-identical, #2864)', () {
      // Berlin (52.5, 13.4) → DE → €.
      final copy = buildRadiusAlertCopy(
        RadiusAlertGroupedEvent(
          alert: alert(),
          matches: [sample('s1', 1.629)],
        ),
        templates,
      );
      expect(copy.title, contains('€'));
      expect(copy.body, contains('€'));
    });

    test('a GB centre renders £, not a forced euro (#2864)', () {
      // Manchester (53.48, -2.24) → GB → £ (well north of FR's box, so the
      // bounding-box derivation is unambiguous).
      final gbAlert = RadiusAlert(
        id: 'gb1',
        fuelType: 'diesel',
        threshold: 1.459,
        centerLat: 53.48,
        centerLng: -2.24,
        radiusKm: 5,
        label: 'Manchester diesel',
        createdAt: DateTime.utc(2026, 5, 30),
      );
      const gbSample = StationPriceSample(
        stationId: 'uk-1',
        name: 'Shell Manchester',
        lat: 53.48,
        lng: -2.24,
        fuelType: 'diesel',
        pricePerLiter: 1.439,
      );
      final copy = buildRadiusAlertCopy(
        RadiusAlertGroupedEvent(alert: gbAlert, matches: [gbSample]),
        templates,
      );
      expect(copy.title, contains('£'));
      expect(copy.title, isNot(contains('€')));
      expect(copy.body, contains('£'));
    });
  });
}
