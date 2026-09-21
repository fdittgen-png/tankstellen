// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/providers/road_distance_provider.dart';
import 'package:tankstellen/features/search/providers/station_off_route_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 — a route row's kilometres are not a distance-from-me, and the
/// two used to look identical.
///
/// The field report's row read `Auchan · 4,4 km` for a forecourt ~60 km
/// ahead of the driver, in the same typography a proximity row uses for
/// "4.4 km from you". Price without a trustworthy distance is not a
/// choice, which is exactly what the reporter said.
void main() {
  group('route rows name the quantity (#4432)', () {
    testWidgets('a proximity row still shows the bare distance from me',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
      );

      expect(find.byKey(const Key('station_card_distance')), findsOneWidget);
      expect(find.byKey(const Key('station_card_off_route')), findsNothing);
      expect(find.text('1,5 km'), findsOneWidget);
    });

    testWidgets('a route row names and qualifies its own measurement',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
        overrides: [
          stationOffRouteKmProvider.overrideWithValue({testStation.id: 4.4}),
        ],
      );

      expect(find.byKey(const Key('station_card_off_route')), findsOneWidget);
      expect(find.byKey(const Key('station_card_distance')), findsNothing);
      // Named ("from the route") AND qualified ("geometric estimate"):
      // it is neither the distance from the driver nor a road detour.
      expect(
        find.text('4,4 km from the route · geometric estimate'),
        findsOneWidget,
      );
      // The unstable first-seen `Station.dist` is not presented at all.
      expect(find.text('1,5 km'), findsNothing);
    });

    testWidgets('a route row ignores a radar distance for the same id',
        (tester) async {
      // `roadDistancesProvider` is keyed by station id from the NEARBY
      // search's origin. A matching id proves nothing about this route,
      // so the route surface must not borrow the number.
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
        overrides: [
          stationOffRouteKmProvider.overrideWithValue({testStation.id: 4.4}),
          roadDistancesProvider.overrideWith(() => _FixedRoadDistances(
                {testStation.id: 9.9},
              )),
        ],
      );

      expect(find.byKey(const Key('station_card_off_route')), findsOneWidget);
      expect(find.byKey(const Key('station_card_road_distance')), findsNothing);
      expect(find.textContaining('9,9 km'), findsNothing);
    });

    testWidgets('the route segment is visually distinct, not just worded',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
        overrides: [
          stationOffRouteKmProvider.overrideWithValue({testStation.id: 4.4}),
        ],
      );

      final segment = find.byKey(const Key('station_card_off_route'));
      expect(
        find.descendant(of: segment, matching: find.byIcon(Icons.alt_route)),
        findsOneWidget,
      );
      expect(
        tester.widget<Tooltip>(
          find.descendant(of: segment, matching: find.byType(Tooltip)),
        ).message,
        allOf(
          contains('Not the distance from you'),
          contains('not the extra driving'),
        ),
      );
    });

    testWidgets('a station absent from the route map keeps the plain reading',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
        overrides: [
          stationOffRouteKmProvider.overrideWithValue({'some-other-id': 9.9}),
        ],
      );

      expect(find.byKey(const Key('station_card_distance')), findsOneWidget);
      expect(find.byKey(const Key('station_card_off_route')), findsNothing);
    });
  });
}

class _FixedRoadDistances extends RoadDistances {
  _FixedRoadDistances(this._values);
  final Map<String, double> _values;

  @override
  Map<String, double> build() => _values;
}
