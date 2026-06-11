// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_scan_runners.dart';
import 'package:tankstellen/core/background/notification_templates.dart';
import 'package:tankstellen/core/constants/field_names.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/data/repositories/alert_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// In-memory [AlertStorage] so the per-station alert runner can persist a fired
/// alert's cooldown without Hive.
class _FakeAlertStorage implements AlertStorage {
  List<Map<String, dynamic>> _alerts = [];

  @override
  List<Map<String, dynamic>> getAlerts() => _alerts;

  @override
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    _alerts = alerts;
  }

  @override
  Future<void> clearAlerts() async => _alerts = [];

  @override
  int get alertCount => _alerts.length;
}

/// Captures every notification the runner emits.
class _FakeNotifier implements NotificationService {
  final List<({int id, String title, String body, String? payload})>
      priceAlerts = [];

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
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

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
  final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

  PriceAlert alert({
    required String id,
    required String stationId,
    required FuelType fuelType,
    required double target,
  }) =>
      PriceAlert(
        id: id,
        stationId: stationId,
        stationName: 'Test Station',
        fuelType: fuelType,
        targetPrice: target,
        createdAt: DateTime.utc(2026, 6, 1),
      );

  group('runPerStationAlerts — #2864 country/currency/fuel aware', () {
    test('an FR LPG alert resolves the lpg field, fires, and renders in €',
        () async {
      final notifier = _FakeNotifier();
      final repo = AlertRepository(_FakeAlertStorage());
      final fr = alert(
        id: 'a-fr',
        stationId: 'fr-1',
        fuelType: FuelType.lpg,
        target: 1.000,
      );

      await BackgroundScanRunners.runPerStationAlerts(
        repo: repo,
        alerts: [fr],
        prices: {
          'fr-1': {
            TankerkoenigFields.status: TankerkoenigFields.statusOpen,
            // No e5/e10/diesel match would have fired under the old switch;
            // the LPG price is below the user's target.
            TankerkoenigFields.lpg: 0.899,
          },
        },
        now: DateTime.utc(2026, 6, 4, 8),
        templates: templates,
        fallbackCountryCode: 'FR',
        notifier: notifier,
      );

      expect(notifier.priceAlerts, hasLength(1),
          reason: 'FR LPG alert must fire — the old e5/e10/diesel-only switch '
              'could never resolve LPG.');
      // FR is EUR-zone, so the body renders the euro.
      expect(notifier.priceAlerts.single.body, contains('€'));
      expect(notifier.priceAlerts.single.body, contains('0.899'));
    });

    test('a GB diesel alert renders £, not a forced euro', () async {
      final notifier = _FakeNotifier();
      final repo = AlertRepository(_FakeAlertStorage());
      final gb = alert(
        id: 'a-gb',
        stationId: 'uk-1',
        fuelType: FuelType.diesel,
        target: 1.500,
      );

      await BackgroundScanRunners.runPerStationAlerts(
        repo: repo,
        alerts: [gb],
        prices: {
          'uk-1': {
            TankerkoenigFields.status: TankerkoenigFields.statusOpen,
            TankerkoenigFields.diesel: 1.439,
          },
        },
        now: DateTime.utc(2026, 6, 4, 8),
        templates: templates,
        fallbackCountryCode: 'GB',
        notifier: notifier,
      );

      expect(notifier.priceAlerts, hasLength(1));
      expect(notifier.priceAlerts.single.body, contains('£'));
      expect(notifier.priceAlerts.single.body, isNot(contains('€')));
    });

    test('a DE e5 alert is byte-identical (resolves e5 + €)', () async {
      final notifier = _FakeNotifier();
      final repo = AlertRepository(_FakeAlertStorage());
      final de = alert(
        id: 'a-de',
        stationId: 'de-1',
        fuelType: FuelType.e5,
        target: 1.800,
      );

      await BackgroundScanRunners.runPerStationAlerts(
        repo: repo,
        alerts: [de],
        prices: {
          'de-1': {
            TankerkoenigFields.status: TankerkoenigFields.statusOpen,
            TankerkoenigFields.e5: 1.759,
          },
        },
        now: DateTime.utc(2026, 6, 4, 8),
        templates: templates,
        fallbackCountryCode: 'DE',
        notifier: notifier,
      );

      expect(notifier.priceAlerts, hasLength(1));
      expect(notifier.priceAlerts.single.body, contains('€'));
      expect(notifier.priceAlerts.single.body, contains('1.759'));
    });

    test('a DE LPG alert does NOT fire (LPG absent from the DE feed)',
        () async {
      final notifier = _FakeNotifier();
      final repo = AlertRepository(_FakeAlertStorage());
      final deLpg = alert(
        id: 'a-de-lpg',
        stationId: 'de-2',
        fuelType: FuelType.lpg,
        target: 1.000,
      );

      await BackgroundScanRunners.runPerStationAlerts(
        repo: repo,
        alerts: [deLpg],
        prices: {
          'de-2': {
            TankerkoenigFields.status: TankerkoenigFields.statusOpen,
            // Even if a stray lpg value were present, the per-country gate
            // refuses it because DE's fuel set has no LPG.
            TankerkoenigFields.lpg: 0.899,
          },
        },
        now: DateTime.utc(2026, 6, 4, 8),
        templates: templates,
        fallbackCountryCode: 'DE',
        notifier: notifier,
      );

      expect(notifier.priceAlerts, isEmpty,
          reason: 'DE has no LPG in its feed — the alert must not fire.');
    });
  });
}
