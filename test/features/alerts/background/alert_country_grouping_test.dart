// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/background/alert_country_grouping.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

void main() {
  PriceAlert priceAlert(String id, String stationId, {bool active = true}) =>
      PriceAlert(
        id: id,
        stationId: stationId,
        stationName: stationId,
        fuelType: FuelType.diesel,
        targetPrice: 1.5,
        isActive: active,
        createdAt: DateTime.utc(2026, 6, 4),
      );

  RadiusAlert radiusAlert(
    String id,
    double lat,
    double lng, {
    bool enabled = true,
  }) =>
      RadiusAlert(
        id: id,
        fuelType: 'diesel',
        threshold: 1.6,
        centerLat: lat,
        centerLng: lng,
        radiusKm: 5,
        label: id,
        enabled: enabled,
        createdAt: DateTime.utc(2026, 6, 4),
      );

  group('country derivation', () {
    test('per-station id prefix resolves to its country', () {
      expect(CountryServiceRegistry.countryForStationId('pt-123'), 'PT');
      expect(CountryServiceRegistry.countryForStationId('uk-abc'), 'GB');
      expect(CountryServiceRegistry.countryForStationId('lu-9'), 'LU');
    });

    test('a prefix-less id (raw DE Tankerkönig UUID) resolves to null', () {
      expect(
        CountryServiceRegistry.countryForStationId(
            '51d4b6a2-a095-1aa0-e100-80009459e03a'),
        isNull,
      );
    });

    test('radius centre resolves via the bounding box', () {
      // Berlin → DE, Lisbon → PT, Vienna → AT.
      expect(CountryServiceRegistry.countryForLatLng(52.52, 13.40), 'DE');
      expect(CountryServiceRegistry.countryForLatLng(38.72, -9.14), 'PT');
      expect(CountryServiceRegistry.countryForLatLng(48.21, 16.37), 'AT');
    });

    test('a centre outside every registered box resolves to null', () {
      // Mid-Atlantic, far from any country box.
      expect(CountryServiceRegistry.countryForLatLng(0.0, -40.0), isNull);
    });
  });

  group('groupAlertsByCountry', () {
    test('alerts spanning 3 countries group into 3 single-provider buckets',
        () {
      final groups = groupAlertsByCountry(
        priceAlerts: [
          priceAlert('a1', 'pt-1'),
          priceAlert('a2', 'pt-2'), // same country, second station
          priceAlert('a3', 'lu-1'),
        ],
        radiusAlerts: [
          radiusAlert('r1', 48.21, 16.37), // Vienna → AT
        ],
      );

      expect(groups.keys.toSet(), {'PT', 'LU', 'AT'});
      expect(groups['PT']!.stationIds, {'pt-1', 'pt-2'});
      expect(groups['LU']!.stationIds, {'lu-1'});
      expect(groups['AT']!.stationIds, isEmpty);
      expect(groups['AT']!.radiusAlerts.single.id, 'r1');
    });

    test('two alerts on the SAME station collapse to one fetch id', () {
      final groups = groupAlertsByCountry(
        priceAlerts: [
          priceAlert('a1', 'pt-1'),
          priceAlert('a2', 'pt-1'), // E5 + Diesel on the same station
        ],
        radiusAlerts: const [],
      );
      expect(groups['PT']!.stationIds, {'pt-1'});
    });

    test('inactive price alerts and disabled radius alerts are excluded', () {
      final groups = groupAlertsByCountry(
        priceAlerts: [
          priceAlert('a1', 'pt-1', active: false),
        ],
        radiusAlerts: [
          radiusAlert('r1', 38.72, -9.14, enabled: false), // Lisbon, disabled
        ],
      );
      expect(groups, isEmpty);
    });

    test('a prefix-less station id falls back to the active country', () {
      final groups = groupAlertsByCountry(
        priceAlerts: [
          priceAlert('a1', '51d4b6a2-a095-1aa0-e100-80009459e03a'),
        ],
        radiusAlerts: const [],
        fallbackCountryCode: 'DE',
      );
      expect(groups.keys.toSet(), {'DE'});
      expect(groups['DE']!.stationIds,
          {'51d4b6a2-a095-1aa0-e100-80009459e03a'});
    });

    test('a prefix-less id with NO fallback is dropped (no provider to ask)',
        () {
      final groups = groupAlertsByCountry(
        priceAlerts: [priceAlert('a1', 'rawuuid')],
        radiusAlerts: const [],
      );
      expect(groups, isEmpty);
    });

    test('a radius centre outside every box is dropped', () {
      final groups = groupAlertsByCountry(
        priceAlerts: const [],
        radiusAlerts: [radiusAlert('r1', 0.0, -40.0)],
      );
      expect(groups, isEmpty);
    });
  });
}
