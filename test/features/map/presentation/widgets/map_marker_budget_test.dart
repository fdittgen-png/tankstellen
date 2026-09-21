// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4163 — the map's structural marker budget.
///
/// `clusterAlways: true` means every marker is BUILT even when it
/// collapses into a cluster badge, so the build cost is linear in the
/// station count regardless of what is finally painted.
///
/// **What this test can and cannot say.** It cannot assert a frame time:
/// a CI runner has no mid-range Android GPU. What it can hold is the
/// SHAPE of the cost — that the builder stays linear in its input up to
/// the cap, and does not, say, start building a marker per fuel type per
/// station.
///
/// #4181 closed the gap this file used to record: the builder bounds its
/// own output now, so [kMapMarkerBudget] is a DERIVED ceiling rather
/// than a guard on an unbounded quantity. The test that deliberately
/// asserted the absence of a bound is inverted below.
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
    // 250 stations is a dense-city 25 km search, under the ceiling. Since
    // #4181 the builder also KEEPS it there, which is what makes the
    // number a bound rather than a hope.
    final model = await buildFor(tester, 250);
    expect(model.markers.length,
        lessThanOrEqualTo(kMapMarkerBudget.limit!),
        reason: 'a dense search now exceeds the ${kMapMarkerBudget.limit} '
            'marker guard. Bound the input (#4181) rather than raising '
            'this.');
  });

  testWidgets('#4181 — the count IS bounded now, and the budget is the bound',
      (tester) async {
    // The inverse of what this test asserted before #4181: handed more
    // than the ceiling, the builder keeps the ceiling's worth.
    final model = await buildFor(tester, kMapMarkerBudget.limit!.toInt() + 50);
    expect(model.markers.length, kMapMarkerBudget.limit!.toInt());
    expect(model.omittedCount, 50,
        reason: 'the loss is REPORTED, not silent — a cluster badge that '
            'counts fewer members than exist has to be explainable');
  });

  testWidgets('#4181 — the cap keeps the cheapest under a price sort',
      (tester) async {
    // The rule the issue warns about: "silently dropping the cheapest
    // station off the map is worse than a slow map". _stations() cycles
    // prices 1.70..1.99, so the cheapest exist throughout the input and
    // a naive truncation would lose most of them.
    final cap = kMapMarkerBudget.limit!.toInt();
    final model = await buildFor(tester, cap + 200);

    final cheapest = model.meta.values
        .map((m) => m.price)
        .whereType<double>()
        .reduce((a, b) => a < b ? a : b);
    expect(cheapest, closeTo(1.70, 1e-9),
        reason: 'the cheapest price in the input must survive the cap');
  });

  testWidgets('#4181 — an ordinary result is untouched, cap and all',
      (tester) async {
    final model = await buildFor(tester, 250);
    expect(model.markers, hasLength(250));
    expect(model.omittedCount, 0,
        reason: 'below the cap nothing is culled and nothing is capped, so '
            'the map behaves exactly as it did before #4181');
  });
}
