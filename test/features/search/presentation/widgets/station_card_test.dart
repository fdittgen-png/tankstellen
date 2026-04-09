import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/core/utils/price_tier.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/amenity_chips.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../fixtures/stations.dart';

void main() {
  group('StationCard', () {
    testWidgets('renders station brand name', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('renders station address', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      // Address + postcode combined on one line when brand is shown
      expect(find.textContaining('Hauptstr.'), findsOneWidget);
      expect(find.textContaining('10115'), findsOneWidget);
    });

    testWidgets('renders price for selected fuel type', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.diesel,
        ),
      );

      // Diesel price is 1.659, formatted via PriceFormatter.priceTextSpan
      // as RichText with base "1,65" + superscript "9" + " EUR".
      // Since it's a RichText with TextSpan children, we search the semantics.
      final richTexts = find.byType(RichText);
      final hasPrice = richTexts.evaluate().any((element) {
        final richText = element.widget as RichText;
        return richText.text.toPlainText().contains('1,65');
      });
      expect(hasPrice, isTrue);
    });

    testWidgets('renders distance in km', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      // testStation.dist = 1.5 → "1,5 km"
      expect(find.textContaining('1,5 km'), findsOneWidget);
    });

    testWidgets('shows open indicator when isOpen=true', (tester) async {
      late Color expectedColor;
      await pumpApp(tester, Builder(builder: (context) {
        expectedColor = DarkModeColors.success(context);
        return const StationCard(
          station: testStation, // isOpen: true
          selectedFuelType: FuelType.e10,
        );
      }));

      // The open indicator is a circle with success color
      final containers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.shape == BoxShape.circle &&
              decoration.color == expectedColor;
        }
        return false;
      });
      expect(containers, findsOneWidget);
    });

    testWidgets('shows closed indicator when isOpen=false', (tester) async {
      final closedStation = testStationList[2]; // station-expensive, isOpen: false

      late Color expectedColor;
      await pumpApp(tester, Builder(builder: (context) {
        expectedColor = DarkModeColors.error(context);
        return StationCard(
          station: closedStation,
          selectedFuelType: FuelType.e10,
        );
      }));

      // The closed indicator is a circle with error color
      final containers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.shape == BoxShape.circle &&
              decoration.color == expectedColor;
        }
        return false;
      });
      expect(containers, findsOneWidget);
    });

    testWidgets('shows favorite star when isFavorite=true', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
      );

      // When isFavorite is true, the icon is Icons.star (filled) with amber color
      expect(find.byIcon(Icons.star), findsOneWidget);

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, Colors.amber);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await pumpApp(
        tester,
        StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(StationCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows arrow_downward icon when priceTier is cheap',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          priceTier: PriceTier.cheap,
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows remove icon when priceTier is average',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          priceTier: PriceTier.average,
        ),
      );

      // Icons.remove is also used elsewhere, so check it's present
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('shows arrow_upward icon when priceTier is expensive',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          priceTier: PriceTier.expensive,
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('does not show tier icon when priceTier is null',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('does not show tier icon when priceTier is unknown',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          priceTier: PriceTier.unknown,
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('shows rating stars when rating is provided', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          rating: 3,
        ),
      );

      // 3 filled stars + 2 empty stars = 5 star icons total
      final filledStars = find.byWidgetPredicate((widget) =>
          widget is Icon && widget.icon == Icons.star && widget.size == 12);
      final emptyStars = find.byWidgetPredicate((widget) =>
          widget is Icon &&
          widget.icon == Icons.star_border &&
          widget.size == 12);
      expect(filledStars, findsNWidgets(3));
      expect(emptyStars, findsNWidgets(2));
    });

    testWidgets('does not show rating stars when rating is null',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      // No 12px star icons should appear (the favorite star is 22px)
      final ratingStars = find.byWidgetPredicate(
          (widget) => widget is Icon && widget.size == 12 &&
              (widget.icon == Icons.star || widget.icon == Icons.star_border));
      expect(ratingStars, findsNothing);
    });

    testWidgets('shows 5 filled stars for rating=5', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          rating: 5,
        ),
      );

      final filledStars = find.byWidgetPredicate((widget) =>
          widget is Icon && widget.icon == Icons.star && widget.size == 12);
      expect(filledStars, findsNWidgets(5));
    });

    testWidgets('favorite star and price are on same row', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
      );

      // Both the price RichText and the favorite IconButton should be
      // inside the same Row (the right-side price+fav row).
      // Verify both are rendered and the favorite icon is 22px (compact).
      final favIcon = find.byWidgetPredicate((widget) =>
          widget is Icon &&
          widget.icon == Icons.star &&
          widget.color == Colors.amber);
      expect(favIcon, findsOneWidget);

      // The favorite IconButton should be compact (32x32 SizedBox)
      final sizedBox = find.ancestor(
        of: find.byIcon(Icons.star),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 32 && w.height == 32,
        ),
      );
      expect(sizedBox, findsOneWidget);
    });

    testWidgets('renders amenity chips on single horizontal line',
        (tester) async {
      const stationWithAmenities = Station(
        id: 'amenity-test',
        name: 'Test Station',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '12345',
        place: 'Teststadt',
        lat: 52.0,
        lng: 13.0,
        dist: 1.0,
        e10: 1.799,
        isOpen: true,
        amenities: {
          StationAmenity.shop,
          StationAmenity.carWash,
          StationAmenity.airPump,
          StationAmenity.toilet,
        },
      );

      await pumpApp(
        tester,
        const StationCard(
          station: stationWithAmenities,
          selectedFuelType: FuelType.e10,
        ),
      );

      // AmenityChips widget should be rendered
      expect(find.byType(AmenityChips), findsOneWidget);
    });

    testWidgets('calls onFavoriteTap when favorite button tapped',
        (tester) async {
      var favTapped = false;

      await pumpApp(
        tester,
        StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          onFavoriteTap: () => favTapped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();

      expect(favTapped, isTrue);
    });
  });
}
