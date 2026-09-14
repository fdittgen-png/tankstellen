// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4163 — the map's structural marker budget.
///
/// `clusterAlways: true` means every marker is BUILT even when it
/// collapses into a cluster badge, so the build cost is linear in the
/// station count regardless of what is finally painted.
///
/// **What this test can and cannot say.** It cannot assert a frame time:
/// a CI runner has no mid-range Android GPU. What it can hold is the
/// SHAPE of the cost — that the builder stays linear in its input and
/// does not, say, start building a marker per fuel type per station. And
/// it records the fact that nothing bounds the input (#4181), so the
/// budget is a guard rather than a derived ceiling.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/perf/perf_budgets.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker_model_builder.dart';

List<Station> _stations(int n) => [
      for (var i = 0; i < n; i++)
        Station(
          id: 'de-$i',
          name: 'S$i',
          brand: 'ARAL',
          street: 'Str $i',
          postCode: '10117',
          place: 'Berlin',
          lat: 52.50 + i * 0.001,
          lng: 13.39 + i * 0.001,
          e10: 1.70 + (i % 30) / 100,
        ),
    ];

void main() {
  late BuildContext ctx;

  Future<StationMarkerModel> buildFor(WidgetTester tester, int n) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    return StationMarkerModelBuilder.build(
      context: ctx,
      stations: _stations(n),
      selectedFuel: FuelType.e10,
      selectedStationIds: null,
      byPrice: true,
      clusterAlways: true,
      fuelResolver: null,
      onStationTap: null,
      markerVariant: StationMarkerVariant.pill,
    );
  }

  testWidgets('one marker per station — the cost is linear, not worse',
      (tester) async {
    // The regression this guards is a builder that starts emitting a
    // marker per fuel, or per amenity: the count would still "look
    // fine" on a small fixture and quadruple in the field.
    for (final n in [1, 10, 120]) {
      final model = await buildFor(tester, n);
      expect(model.markers, hasLength(n), reason: 'for $n stations');
    }
  });

  testWidgets('a realistic dense result stays inside the guard',
      (tester) async {
    // 250 stations is a dense-city 25 km search. It is under the guard
    // today; nothing in the code KEEPS it there, which is the point of
    // #4181.
    final model = await buildFor(tester, 250);
    expect(model.markers.length,
        lessThanOrEqualTo(kMapMarkerBudget.limit!),
        reason: 'a dense search now exceeds the ${kMapMarkerBudget.limit} '
            'marker guard. Bound the input (#4181) rather than raising '
            'this.');
  });

  testWidgets('the count is NOT bounded by the builder — recorded, not '
      'asserted as safe', (tester) async {
    // Deliberately documents the gap instead of hiding it: handed more
    // than the guard, the builder happily produces more than the guard.
    // If this ever starts failing, someone capped it and #4181 can close.
    final model = await buildFor(tester, kMapMarkerBudget.limit!.toInt() + 50);
    expect(model.markers.length, greaterThan(kMapMarkerBudget.limit!),
        reason: 'the builder now bounds its output — good. Update '
            'kMapMarkerBudget to say it is derived, and close #4181.');
  });
}
