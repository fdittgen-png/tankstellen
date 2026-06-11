// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';

/// Unit tests for the #1872 minimum-saving route filter — the pure
/// function that drops fuel stations not priced within the user's
/// saving threshold of the route's cheapest.
void main() {
  FuelStationResult fuel(String id, double? e10) => FuelStationResult(
        Station(
          id: id,
          name: id,
          brand: 'X',
          street: 'S',
          postCode: '10115',
          place: 'P',
          lat: 0,
          lng: 0,
          isOpen: true,
          e10: e10,
        ),
      );

  group('filterRouteResultsByMinSaving (#1872)', () {
    test('keeps stations within minSaving of the route cheapest', () {
      final results = [fuel('a', 1.50), fuel('b', 1.55), fuel('c', 1.65)];
      // Cheapest 1.50, threshold 0.10 → ceiling 1.60: a + b kept, c dropped.
      final out = filterRouteResultsByMinSaving(results, FuelType.e10, 0.10);
      expect(out.map((r) => r.id), ['a', 'b']);
    });

    test('a station with no price for the fuel type is kept', () {
      final results = [fuel('a', 1.50), fuel('noPrice', null)];
      final out = filterRouteResultsByMinSaving(results, FuelType.e10, 0.05);
      expect(out.map((r) => r.id), containsAll(<String>['a', 'noPrice']));
    });

    test('returns the list unchanged when no station has a price', () {
      final results = [fuel('a', null), fuel('b', null)];
      final out = filterRouteResultsByMinSaving(results, FuelType.e10, 0.05);
      expect(out, same(results));
    });

    test('non-fuel (EV) results are never filtered out', () {
      const ev = EVStationResult(ChargingStation(
        id: 'ev',
        name: 'EV',
        latitude: 0,
        longitude: 0,
      ));
      final results = <SearchResultItem>[
        fuel('cheap', 1.50),
        fuel('pricey', 2.00),
        ev,
      ];
      final out = filterRouteResultsByMinSaving(results, FuelType.e10, 0.05);
      expect(out.map((r) => r.id), containsAll(<String>['cheap', 'ev']));
      expect(out.map((r) => r.id), isNot(contains('pricey')));
    });
  });
}
