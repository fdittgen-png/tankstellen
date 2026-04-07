import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

import '../fixtures/stations.dart';
import '../helpers/pump_app.dart';

void main() {
  group('Accessibility - Semantics', () {
    testWidgets('StationCard has semantic label with brand and status',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      // The Semantics widget wraps the card with brand, street, price, status
      expect(
        find.bySemanticsLabel(RegExp(r'STAR.*Hauptstr.*Open')),
        findsOneWidget,
      );
    });

    testWidgets('StationCard shows Closed for closed stations', (tester) async {
      final closedStation = testStationList[2]; // isOpen: false

      await pumpApp(
        tester,
        StationCard(
          station: closedStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'SHELL.*Closed')),
        findsOneWidget,
      );
    });

    testWidgets('StationCard favorite button has tooltip', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: false,
        ),
      );

      expect(find.byTooltip('Add to favorites'), findsOneWidget);
    });

    testWidgets('StationCard favorite button tooltip changes when favorited',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
      );

      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });

    testWidgets('SortSelector chips have semantic labels', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (_) {},
        ),
      );

      // Distance chip is selected
      expect(
        find.bySemanticsLabel(RegExp(r'Sort by Distance.*selected')),
        findsOneWidget,
      );

      // Price chip is not selected
      expect(
        find.bySemanticsLabel(RegExp(r'Sort by Price$')),
        findsOneWidget,
      );

      // A-Z chip is not selected
      expect(
        find.bySemanticsLabel(RegExp(r'Sort by A-Z$')),
        findsOneWidget,
      );
    });

    testWidgets('SortSelector selected state updates semantic label',
        (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.price,
          onChanged: (_) {},
        ),
      );

      // Price chip should be marked as selected
      expect(
        find.bySemanticsLabel(RegExp(r'Sort by Price.*selected')),
        findsOneWidget,
      );

      // Distance chip should NOT be marked as selected
      expect(
        find.bySemanticsLabel(RegExp(r'Sort by Distance$')),
        findsOneWidget,
      );
    });
  });
}
