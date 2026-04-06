import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/swipeable_station_card.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SwipeableStationCard', () {
    late bool navigateCalled;
    late bool ignoreCalled;
    late bool tapCalled;
    late bool favoriteTapCalled;

    setUp(() {
      navigateCalled = false;
      ignoreCalled = false;
      tapCalled = false;
      favoriteTapCalled = false;
    });

    Widget buildCard({bool isFavorite = false}) {
      return SwipeableStationCard(
        station: testStation,
        isFavorite: isFavorite,
        onNavigate: () => navigateCalled = true,
        onIgnore: () => ignoreCalled = true,
        onTap: () => tapCalled = true,
        onFavoriteTap: () => favoriteTapCalled = true,
      );
    }

    testWidgets('renders station card content', (tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        buildCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );

      // Station brand should be visible
      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('tapping the card calls onTap', (tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        buildCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );

      // Tap the card (find the InkWell or GestureDetector inside StationCard)
      await tester.tap(find.byType(SwipeableStationCard));
      await tester.pumpAndSettle();

      expect(tapCalled, isTrue);
    });

    testWidgets('swiping right calls onNavigate and does not dismiss',
        (tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        buildCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );

      // Swipe right (start to end)
      await tester.drag(
        find.byType(Dismissible),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();

      expect(navigateCalled, isTrue);
      // Card should still be in the tree (confirmDismiss returns false)
      expect(find.byType(SwipeableStationCard), findsOneWidget);
    });

    testWidgets('swiping left calls onIgnore', (tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        buildCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );

      // Swipe left (end to start)
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(ignoreCalled, isTrue);
    });

    testWidgets('favorite tap callback is wired correctly',
        (tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        buildCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );

      // Find the favorite icon button and tap it
      final favoriteIcon = find.byIcon(Icons.favorite_border);
      if (favoriteIcon.evaluate().isNotEmpty) {
        await tester.tap(favoriteIcon);
        await tester.pumpAndSettle();
        expect(favoriteTapCalled, isTrue);
      }
    });

    testWidgets('contains Dismissible widget for swipe gestures',
        (tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        buildCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );

      expect(find.byType(Dismissible), findsOneWidget);
    });
  });
}
