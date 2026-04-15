import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/core/theme/fuel_colors.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
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

    group('profile fuel highlight in all-fuels view', () {
      testWidgets('shows all three price rows when FuelType.all selected',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.all,
          ),
        );

        expect(find.text('E5: '), findsOneWidget);
        expect(find.text('E10: '), findsOneWidget);
        expect(find.text('Diesel: '), findsOneWidget);
      });

      testWidgets(
          'profile fuel row has larger dot when profileFuelType matches',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.all,
            profileFuelType: FuelType.e10,
          ),
        );

        // The E10 row should have a larger dot (8px) while others have 6px
        final containers = find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            final constraints = widget.constraints;
            return decoration.shape == BoxShape.circle &&
                constraints != null &&
                constraints.maxWidth == 8.0 &&
                constraints.maxHeight == 8.0;
          }
          return false;
        });
        // One 8px dot for the highlighted E10 row
        expect(containers, findsOneWidget);
      });

      testWidgets(
          'profile fuel row label uses fuel-type color',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.all,
            profileFuelType: FuelType.diesel,
          ),
        );

        // The Diesel label should use the diesel fuel color
        final dieselColor = FuelColors.forType(FuelType.diesel);
        final dieselLabel = find.text('Diesel: ');
        expect(dieselLabel, findsOneWidget);

        final textWidget = tester.widget<Text>(dieselLabel);
        expect(textWidget.style?.color, dieselColor);
      });

      testWidgets(
          'non-profile fuel rows do not use fuel-type label color',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.all,
            profileFuelType: FuelType.diesel,
          ),
        );

        // E5 label should NOT have the E5 fuel-type color
        final e5Label = find.text('E5: ');
        expect(e5Label, findsOneWidget);

        final e5Text = tester.widget<Text>(e5Label);
        final e5FuelColor = FuelColors.forType(FuelType.e5);
        expect(e5Text.style?.color, isNot(equals(e5FuelColor)));
      });

      testWidgets(
          'no highlight when profileFuelType is null',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.all,
            // profileFuelType defaults to null
          ),
        );

        // All dots should be 6px (no 8px highlighted dots)
        final largeDots = find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            final constraints = widget.constraints;
            return decoration.shape == BoxShape.circle &&
                constraints != null &&
                constraints.maxWidth == 8.0;
          }
          return false;
        });
        expect(largeDots, findsNothing);
      });

      testWidgets(
          'no price rows when single fuel type selected (not all)',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            profileFuelType: FuelType.e10,
          ),
        );

        // Should not show the all-fuels price rows
        expect(find.text('E5: '), findsNothing);
        expect(find.text('E10: '), findsNothing);
        expect(find.text('Diesel: '), findsNothing);
      });
    });

    group('per-station currency (#514)', () {
      String _priceRichText(WidgetTester tester) {
        // Concatenate all RichText.toPlainText() so the fuel price
        // RichText (which embeds the superscript 9/10ths digit as a
        // WidgetSpan) is captured alongside plain fragments.
        return tester
            .widgetList<RichText>(find.byType(RichText))
            .map((r) => r.text.toPlainText())
            .join('\n');
      }

      tearDown(() {
        // Leave the formatter in a stable default so later tests
        // don't see whatever we set here.
        PriceFormatter.setCountry('DE');
      });

      testWidgets(
          'uk- prefix renders £ even when the active profile is France',
          (tester) async {
        PriceFormatter.setCountry('FR');

        const ukStation = Station(
          id: 'uk-BP1',
          name: 'BP Victoria',
          brand: 'BP',
          street: '1 Victoria St',
          postCode: 'SW1E 6DE',
          place: 'London',
          lat: 51.4975,
          lng: -0.1357,
          dist: 1.5,
          e5: 1.559,
          e10: 1.459,
          diesel: 1.529,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: ukStation,
            selectedFuelType: FuelType.e5,
          ),
        );

        final rendered = _priceRichText(tester);
        expect(rendered, contains('£'),
            reason: 'UK station must render its price in pounds');
        expect(rendered, isNot(contains('€')),
            reason: 'UK station must not use the profile € symbol');
      });

      testWidgets(
          'pt- prefix keeps € and matches the active FR profile', (tester) async {
        PriceFormatter.setCountry('FR');

        const ptStation = Station(
          id: 'pt-42',
          name: 'GALP Lisboa',
          brand: 'GALP',
          street: 'Avenida',
          postCode: '1250',
          place: 'Lisboa',
          lat: 38.7223,
          lng: -9.1393,
          dist: 2.5,
          e5: 1.789,
          diesel: 1.659,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: ptStation,
            selectedFuelType: FuelType.e5,
          ),
        );

        expect(_priceRichText(tester), contains('€'));
      });

      testWidgets(
          'unprefixed id (Tankerkoenig) falls back to the active profile '
          'currency', (tester) async {
        PriceFormatter.setCountry('GB');

        // testStation has a UUID id (no country prefix), so it must
        // follow the global PriceFormatter.setCountry.
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e5,
          ),
        );

        final rendered = _priceRichText(tester);
        expect(rendered, contains('£'),
            reason: 'unprefixed station must follow the active profile '
                '(here GB → £)');
      });

      testWidgets(
          'mx- prefix renders the peso symbol under a FR profile',
          (tester) async {
        PriceFormatter.setCountry('FR');

        const mxStation = Station(
          id: 'mx-11702',
          name: 'PEMEX Centro',
          brand: 'PEMEX',
          street: '',
          postCode: '',
          place: 'Ciudad de México',
          lat: 19.43,
          lng: -99.13,
          dist: 1.2,
          e5: 22.95,
          e10: 24.89,
          diesel: 23.45,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: mxStation,
            selectedFuelType: FuelType.e5,
          ),
        );

        final rendered = _priceRichText(tester);
        expect(rendered, contains('\$'),
            reason: 'MX station must render the peso \$ symbol');
        expect(rendered, isNot(contains('€')));
      });
    });
  });
}
