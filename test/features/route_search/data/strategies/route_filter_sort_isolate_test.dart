// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/features/route_search/data/strategies/route_filter_sort_isolate.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';

/// #2303 — the Cheapest / Balanced / Eco strategies now route their detour
/// filter + itinerary sort through this shared off-isolate helper instead of
/// running the two haversine passes on the UI isolate. These tests pin the
/// behaviour the strategies depend on: far fuel stations drop, non-fuel (EV)
/// results pass through unfiltered, and survivors come back in itinerary order.
void main() {
  FuelStationResult fuel(String id, double lat, double lng) =>
      FuelStationResult(Station(
        id: id,
        name: id,
        brand: 'T',
        street: '',
        postCode: '',
        place: '',
        lat: lat,
        lng: lng,
        dist: 1.0,
        isOpen: true,
        e10: 1.50,
      ));

  EVStationResult ev(String id, double lat, double lng) =>
      EVStationResult(ChargingStation(
        id: id,
        name: id,
        latitude: lat,
        longitude: lng,
      ));

  // Polyline runs west→east along lat=48.
  const polyline = [
    LatLng(48.0, 2.0),
    LatLng(48.0, 2.5),
    LatLng(48.0, 3.0),
  ];

  group('filterAndSortAlongRoute (async / compute hop)', () {
    test('drops far fuel stations and sorts the rest in itinerary order',
        () async {
      final results = [
        fuel('east-on-route', 48.0, 2.9),
        fuel('off-route-far', 48.5, 2.5), // ~55 km north → fails 10 km detour
        fuel('mid-on-route', 48.0, 2.5),
        fuel('west-on-route', 48.0, 2.05),
      ];

      final survivors = await filterAndSortAlongRoute(
        results: results,
        polyline: polyline,
        detourLimitKm: 10.0,
      );

      expect(survivors.map((s) => s.id), [
        'west-on-route',
        'mid-on-route',
        'east-on-route',
      ]);
    });

    test('keeps EV (non-fuel) results regardless of detour distance',
        () async {
      final results = <SearchResultItem>[
        ev('ev-way-off-route', 49.0, 2.5), // far from polyline, must survive
        fuel('fuel-on-route', 48.0, 2.5),
        fuel('fuel-far', 48.4, 2.5), // far → dropped
      ];

      final survivors = await filterAndSortAlongRoute(
        results: results,
        polyline: polyline,
        detourLimitKm: 5.0,
      );

      final ids = survivors.map((s) => s.id).toSet();
      expect(ids, contains('ev-way-off-route'),
          reason: 'EV results bypass the detour filter.');
      expect(ids, contains('fuel-on-route'));
      expect(ids, isNot(contains('fuel-far')),
          reason: 'Far fuel stations are still dropped.');
    });

    test('empty inputs short-circuit without crossing the isolate boundary',
        () async {
      expect(
        await filterAndSortAlongRoute(
          results: const [],
          polyline: const [LatLng(48, 2)],
          detourLimitKm: 5.0,
        ),
        isEmpty,
      );
      final passthrough = await filterAndSortAlongRoute(
        results: [fuel('a', 48, 2)],
        polyline: const [],
        detourLimitKm: 5.0,
      );
      expect(passthrough, hasLength(1));
    });
  });

  group('filterAndSortAlongRouteSyncForTest (algorithm pin)', () {
    test('itinerary order is identical to the async path', () {
      final results = [
        fuel('end', 48.0, 2.95),
        fuel('start', 48.0, 2.05),
        fuel('mid', 48.0, 2.5),
      ];

      final survivors = filterAndSortAlongRouteSyncForTest(
        results: results,
        polyline: polyline,
        detourLimitKm: 20.0,
      );

      expect(survivors.map((s) => s.id), ['start', 'mid', 'end']);
    });
  });
}
