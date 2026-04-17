import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_best_stops_list.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_station_chip.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

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

    testWidgets('bar has the fixed 52-px height', (tester) async {
      // Changing this height would misalign the map overlay the
      // chips sit on top of — pin it as a visual contract.
      await tester.pumpWidget(buildHost(stations: testStationList));
      final size = tester.getSize(find.byType(RouteBestStopsList));
      expect(size.height, 52);
    });
  });
}
