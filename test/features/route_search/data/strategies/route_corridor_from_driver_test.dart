// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/utils/geo_utils.dart';
import 'package:tankstellen/features/route_search/data/strategies/uniform_search_strategy.dart';

/// #4432 — the corridor is what the ORIGIN makes it.
///
/// The field report's complaint ("28 stations, including ones already
/// passed") followed from the origin, not from the corridor filter: the
/// route was drawn from where GPS had been sampled 50 km earlier, so a
/// forecourt the driver had long passed was still within the detour
/// budget of that route. Once the origin is renewed to where the
/// vehicle IS, the corridor is B→C and the passed stop is simply not in
/// it — which the production filter, not a test-only reimplementation,
/// is asked to show here.
void main() {
  // A — where GPS was sampled when the driver tapped the button.
  const laTourDuPin = LatLng(45.5636, 5.4456);
  // B — where the vehicle is now; C — the destination.
  const belley = LatLng(45.7594, 5.6842);
  const geneva = LatLng(46.2044, 6.1432);

  /// The corridor a route from B to C actually spans.
  const corridorFromB = <LatLng>[
    belley,
    LatLng(45.8470, 5.7830), // Culoz
    LatLng(45.9570, 5.8330), // Seyssel
    LatLng(46.1200, 6.0100),
    geneva,
  ];

  /// The corridor the stale origin produced: A → … → C, which still
  /// covers everything the driver had already driven past.
  const corridorFromA = <LatLng>[laTourDuPin, ...corridorFromB];

  FuelStationResult stop(String id, LatLng at) => FuelStationResult(
        Station(
          id: id,
          name: id,
          brand: id,
          street: '',
          postCode: '',
          place: id,
          lat: at.latitude,
          lng: at.longitude,
          dist: 1,
          e85: 0.849,
          isOpen: true,
        ),
      );

  // A station beside A — the driver passed it before the search.
  final passedStop = stop('la-tour-du-pin', laTourDuPin);
  final aheadStop = stop('culoz', const LatLng(45.8470, 5.7830));
  final farAheadStop = stop('seyssel', const LatLng(45.9570, 5.8330));

  test('the passed stop really is ~30 km behind the vehicle', () {
    // Pins the scenario's own geometry, so the assertions below are
    // about the filter and not about accidental coordinates.
    expect(
      distanceKm(
        belley.latitude,
        belley.longitude,
        laTourDuPin.latitude,
        laTourDuPin.longitude,
      ),
      closeTo(28, 8),
    );
  });

  test(
      'origin at A (the stale snapshot): the passed stop IS a candidate — '
      'the reported bug', () async {
    final survivors = await runFilterAndSortForTest(
      results: [passedStop, aheadStop, farAheadStop],
      polyline: corridorFromA,
      detourLimitKm: 15,
    );

    expect(survivors.map((s) => s.id), contains('la-tour-du-pin'));
  });

  test(
      'origin at B (renewed at search time): the corridor is B→C and the '
      'stop passed 30 km ago is not a candidate', () async {
    final survivors = await runFilterAndSortForTest(
      results: [passedStop, aheadStop, farAheadStop],
      polyline: corridorFromB,
      detourLimitKm: 15,
    );

    expect(survivors.map((s) => s.id), ['culoz', 'seyssel']);
    expect(survivors.map((s) => s.id), isNot(contains('la-tour-du-pin')));
  });
}
