// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_request.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';

/// #4432 — a refresh has to re-run THIS search, which means the search
/// has to exist as a value and not only as arguments already consumed.
void main() {
  RouteSearchRequest request({bool vehicleOrigin = true}) =>
      RouteSearchRequest(
        revision: 7,
        waypoints: [
          RouteWaypoint(
            lat: 45.5636,
            lng: 5.4456,
            label: 'Current location',
            isVehiclePosition: vehicleOrigin,
          ),
          const RouteWaypoint(lat: 45.9, lng: 5.9, label: 'Culoz'),
          const RouteWaypoint(lat: 46.2044, lng: 6.1432, label: 'Genève'),
        ],
        fuelType: FuelType.e85,
        searchRadiusKm: 12,
        strategyType: RouteSearchStrategyType.uniform,
        segmentKm: 60,
        minSavingPerLiter: 0.03,
        originCapturedAt: DateTime(2026, 3, 11, 14, 30),
      );

  test('a vehicle origin is what makes refresh mean "from where I am"', () {
    expect(request().originIsVehiclePosition, isTrue);
    expect(request(vehicleOrigin: false).originIsVehiclePosition, isFalse);
  });

  test('withOrigin moves ONLY the origin', () {
    final moved = request().withOrigin(
      const LatLng(45.7594, 5.6842), // Belley, 50 km on
      DateTime(2026, 3, 11, 15, 7),
    );

    expect(moved.waypoints.first.lat, closeTo(45.7594, 1e-9));
    expect(moved.waypoints.first.lng, closeTo(5.6842, 1e-9));
    // Still the vehicle's position, still labelled, still three stops in
    // the same order with the same options — a refresh must not quietly
    // become a different search.
    expect(moved.waypoints.first.isVehiclePosition, isTrue);
    expect(moved.waypoints.map((w) => w.label),
        ['Current location', 'Culoz', 'Genève']);
    expect(moved.waypoints[1].lat, closeTo(45.9, 1e-9));
    expect(moved.waypoints.last.lng, closeTo(6.1432, 1e-9));
    expect(moved.fuelType, FuelType.e85);
    expect(moved.searchRadiusKm, 12);
    expect(moved.segmentKm, 60);
    expect(moved.minSavingPerLiter, 0.03);
    expect(moved.originCapturedAt, DateTime(2026, 3, 11, 15, 7));
  });
}
