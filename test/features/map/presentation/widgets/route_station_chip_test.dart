import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_station_chip.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';

void main() {
  // Now that RouteStationChip is a public widget we can test it directly.

  Widget buildChip({
    Station? station,
    int stopNumber = 1,
    bool isSelected = false,
    double? price,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RouteStationChip(
          station: station ?? testStation,
          stopNumber: stopNumber,
          isSelected: isSelected,
          price: price,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('RouteStationChip', () {
    testWidgets('displays stop number', (tester) async {
      await tester.pumpWidget(buildChip(stopNumber: 3));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays station name', (tester) async {
      await tester.pumpWidget(buildChip());
      expect(find.text(testStation.displayName), findsOneWidget);
    });

    testWidgets('displays formatted price when available', (tester) async {
      await tester.pumpWidget(buildChip(price: 1.965));
      expect(find.text('1.965\u20ac'), findsOneWidget);
    });

    testWidgets('displays dash when price is null', (tester) async {
      await tester.pumpWidget(buildChip(price: null));
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('displays distance with one decimal', (tester) async {
      final station = Station(
        id: testStation.id,
        name: testStation.name,
        brand: testStation.brand,
        street: testStation.street,
        houseNumber: testStation.houseNumber,
        postCode: testStation.postCode,
        place: testStation.place,
        lat: testStation.lat,
        lng: testStation.lng,
        dist: 9.87,
        isOpen: testStation.isOpen,
      );
      await tester.pumpWidget(buildChip(station: station));
      expect(find.textContaining('9.9 km'), findsOneWidget);
    });

    testWidgets('selected chip uses primary background color', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: true));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.primary);
    });

    testWidgets('unselected chip uses surface background color',
        (tester) async {
      await tester.pumpWidget(buildChip(isSelected: false));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.surface);
    });

    testWidgets('selected chip has box shadow', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: true));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('unselected chip has no box shadow', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: false));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildChip(onTap: () => tapped = true));
      await tester.tap(find.text(testStation.displayName));
      expect(tapped, isTrue);
    });

    testWidgets('stop number badge is circular', (tester) async {
      await tester.pumpWidget(buildChip(stopNumber: 3));

      final containers = find.byType(Container);
      bool foundCircle = false;
      for (final element in containers.evaluate()) {
        final widget = element.widget as Container;
        if (widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          if (deco.shape == BoxShape.circle) {
            foundCircle = true;
            break;
          }
        }
      }
      expect(foundCircle, isTrue,
          reason: 'Stop number badge should be circular');
    });
  });
}
