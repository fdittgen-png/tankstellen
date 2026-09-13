// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_best_stops_list.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_station_chip.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../../fixtures/stations.dart';

void main() {
  Widget buildHost({
    required List<Station> stations,
    Set<String> selected = const {},
    dynamic selectedFuel = FuelType.diesel,
    void Function(String stationId)? onToggle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RouteBestStopsList(
          stations: stations,
          selectedStationIds: selected,
          selectedFuel: selectedFuel,
          onToggleStation: onToggle ?? (_) {},
        ),
      ),
    );
  }

  group('RouteBestStopsList', () {
    testWidgets('renders one chip per station', (tester) async {
      await tester.pumpWidget(buildHost(stations: testStationList));
      expect(
        find.byType(RouteStationChip),
        findsNWidgets(testStationList.length),
      );
    });

    testWidgets('renders no chips when stations list is empty',
        (tester) async {
      await tester.pumpWidget(buildHost(stations: const []));
      expect(find.byType(RouteStationChip), findsNothing);
    });

    testWidgets('marks a chip as selected when its id is in the selection',
        (tester) async {
      await tester.pumpWidget(buildHost(
        stations: testStationList,
        selected: {testStationList.first.id},
      ));

      final chip = tester.widget<RouteStationChip>(
        find.byType(RouteStationChip).first,
      );
      expect(chip.isSelected, isTrue);
    });

    testWidgets('assigns a 1-based stopNumber in list order',
        (tester) async {
      await tester.pumpWidget(buildHost(stations: testStationList));

      final chips = tester
          .widgetList<RouteStationChip>(find.byType(RouteStationChip))
          .toList();
      for (var i = 0; i < chips.length; i++) {
        expect(chips[i].stopNumber, i + 1);
      }
    });

    testWidgets('tapping a chip fires onToggleStation with its id',
        (tester) async {
      String? toggledId;
      await tester.pumpWidget(buildHost(
        stations: testStationList,
        onToggle: (id) => toggledId = id,
      ));

      await tester.tap(find.byType(RouteStationChip).first);
      await tester.pump();
      expect(toggledId, testStationList.first.id);
    });

    testWidgets('each chip carries a stable ValueKey so scroll state '
        'survives list updates', (tester) async {
      await tester.pumpWidget(buildHost(stations: testStationList));

      for (final s in testStationList) {
        expect(
          find.byKey(ValueKey('route-station-${s.id}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('the band is 52 px of chips plus the FAB protrusion '
        'beneath them (#4121)', (tester) async {
      // The height is a visual contract — it aligns with the map overlay
      // the chips sit on top of — so it is pinned rather than tuned.
      //
      // #4121 — it grew by the shell FAB's protrusion (32). The docked
      // search button is centred on the bottom bar's top edge and
      // punched a fixed hole through the middle of this row; the chips
      // are lifted above it while the band's surface still meets the
      // bar.
      await tester.pumpWidget(buildHost(stations: testStationList));
      final size = tester.getSize(find.byType(RouteBestStopsList));
      expect(size.height, 52 + 32);

      // The lift must be UNDER the chips, not around them: a chip's
      // bottom edge has to clear the protrusion, or the fix is only a
      // taller band with the same hole in it.
      final chip = tester.getRect(find.byType(RouteStationChip).first);
      final band = tester.getRect(find.byType(RouteBestStopsList));
      expect(band.bottom - chip.bottom, greaterThanOrEqualTo(32),
          reason: 'the chips sit above the docked button, not behind it');
    });
  });
}
