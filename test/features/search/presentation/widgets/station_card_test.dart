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
      String priceRichText(WidgetTester tester) {
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

        final rendered = priceRichText(tester);
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

        expect(priceRichText(tester), contains('€'));
      });

      testWidgets(
          'unprefixed Tankerkoenig UUID with German coordinates resolves '
          'to € via bbox fallback (#516)', (tester) async {
        // Under #516 the bounding-box fallback kicks in when the id
        // carries no country prefix. testStation has a UUID + Berlin
        // coords, so it must render with € regardless of the active
        // profile — previously (#514) it would have fallen through
        // to the profile currency.
        PriceFormatter.setCountry('GB');

        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e5,
          ),
        );

        final rendered = priceRichText(tester);
        expect(rendered, contains('€'),
            reason: 'Berlin coordinates must resolve to DE → € even '
                'under a GB profile (bbox fallback)');
        expect(rendered, isNot(contains('£')),
            reason: 'a German station must not borrow the profile £');
      });

      testWidgets(
          '#516: bare-numeric FR Prix-Carburants id at Paris coords '
          'renders € under a GB profile', (tester) async {
        // The exact scenario from the bug report screenshot: the
        // active profile is UK, a favorite French station has a raw
        // Prix-Carburants numeric id (no fr- prefix), and the old
        // #514 dispatch fell through to the profile currency (£).
        // With #516 the bounding-box lookup must pick up the French
        // coords and render €.
        PriceFormatter.setCountry('GB');

        const frStation = Station(
          id: '12345', // Prix-Carburants emits bare numeric ids
          name: 'Pézenas Carburant',
          brand: 'INTERMARCHÉ',
          street: '18 Avenue de Verdun',
          postCode: '34120',
          place: 'Pézenas',
          lat: 43.4612, // Pézenas, Hérault, France
          lng: 3.4252,
          dist: 2.5,
          e5: 1.999,
          e10: 1.999,
          diesel: 2.269,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: frStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        final rendered = priceRichText(tester);
        expect(rendered, contains('€'),
            reason: 'French coordinates must resolve to FR → € even '
                'with a bare numeric id and a GB profile');
        expect(rendered, isNot(contains('£')),
            reason: 'French station must not inherit the profile £');
      });

      testWidgets(
          '#516: uk- prefixed station under a FR profile still renders £',
          (tester) async {
        // Mirror of the scenario above — the other direction, to prove
        // the prefix path still works after #516 changes the resolver.
        PriceFormatter.setCountry('FR');

        const ukStation = Station(
          id: 'uk-MFG-Streatham',
          name: 'MFG Streatham Leigham',
          brand: 'ESSO',
          street: '928.3 km',
          postCode: 'SW16',
          place: 'London',
          lat: 51.42,
          lng: -0.13,
          dist: 928.3,
          e5: 1.759,
          e10: 1.579,
          diesel: 1.939,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: ukStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        final rendered = priceRichText(tester);
        expect(rendered, contains('£'));
        expect(rendered, isNot(contains('€')));
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

        final rendered = priceRichText(tester);
        expect(rendered, contains('\$'),
            reason: 'MX station must render the peso \$ symbol');
        expect(rendered, isNot(contains('€')));
      });
    });

    group('micro-animations (#595)', () {
      testWidgets('brand/name title is wrapped in a Hero with the station id',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        final heroes = find.byType(Hero);
        final matching = heroes.evaluate().where((element) {
          final widget = element.widget as Hero;
          return widget.tag ==
              'station-name-51d4b477-a095-1aa0-e100-80009459e03a';
        });
        expect(matching, isNotEmpty,
            reason: 'Station card title must be a Hero so the text flies '
                'to the detail app bar on push.');
      });

      testWidgets('favorite star is rendered via AnimatedFavoriteStar',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            isFavorite: true,
          ),
        );

        // The favorite icon should be hosted inside the animated wrapper
        // so the toggle bounce fires in one place everywhere we render
        // a favorite indicator.
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'AnimatedFavoriteStar',
          ),
          findsOneWidget,
        );
      });

      testWidgets('price display is wrapped in AnimatedPriceText',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'AnimatedPriceText',
          ),
          findsOneWidget,
        );
      });
    });

    group('loyalty discount (#1120)', () {
      testWidgets(
          'matching brand renders an effective price + badge',
          (tester) async {
        // testStation.brand == 'STAR' which is in BrandRegistry as
        // an alias of Orlen. Use a Total station instead.
        const totalStation = Station(
          id: 'fr-totalenergies-1',
          name: 'TotalEnergies Pézenas',
          brand: 'TotalEnergies',
          street: 'Avenue Jean Jaurès',
          postCode: '34120',
          place: 'Pézenas',
          lat: 43.46,
          lng: 3.42,
          dist: 1.0,
          e10: 1.799,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: totalStation,
            selectedFuelType: FuelType.e10,
            activeDiscountsByBrand: {'TotalEnergies': 0.05},
          ),
        );

        // Effective price = 1.799 - 0.05 = 1.749 → "1,74⁹"
        final richTexts = find.byType(RichText);
        final hasEffective = richTexts.evaluate().any((element) {
          final richText = element.widget as RichText;
          return richText.text.toPlainText().contains('1,74');
        });
        expect(hasEffective, isTrue,
            reason: 'effective price (raw - discount) must be the headline');

        // Raw price stays accessible — appears struck through in the badge.
        final hasRaw = find.textContaining('1,799');
        expect(hasRaw, findsOneWidget,
            reason: 'raw price must remain visible to the user');
      });

      testWidgets('non-matching brand leaves the price unchanged',
          (tester) async {
        // testStation brand "STAR" canonicalises to Orlen — no
        // Total card applies. Headline price must stay 1,79⁹.
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            activeDiscountsByBrand: {'TotalEnergies': 0.05},
          ),
        );

        final richTexts = find.byType(RichText);
        final hasOriginal = richTexts.evaluate().any((element) {
          final richText = element.widget as RichText;
          return richText.text.toPlainText().contains('1,79');
        });
        expect(hasOriginal, isTrue);

        // No struck-through raw-price text from the badge — there is
        // no badge for unmatched stations.
        final hasStrike = find.byWidgetPredicate((w) {
          if (w is Text && w.style?.decoration == TextDecoration.lineThrough) {
            return true;
          }
          return false;
        });
        expect(hasStrike, findsNothing);
      });

      testWidgets(
          'empty discount map leaves matching-brand stations unchanged',
          (tester) async {
        const totalStation = Station(
          id: 'fr-totalenergies-2',
          name: 'TotalEnergies Béziers',
          brand: 'Total',
          street: 'Boulevard Pasteur',
          postCode: '34500',
          place: 'Béziers',
          lat: 43.34,
          lng: 3.21,
          dist: 1.0,
          e10: 1.799,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: totalStation,
            selectedFuelType: FuelType.e10,
            activeDiscountsByBrand: {},
          ),
        );

        // Strike-through text is what the badge renders. Empty map
        // → no badge → no strike-through.
        final hasStrike = find.byWidgetPredicate((w) {
          if (w is Text && w.style?.decoration == TextDecoration.lineThrough) {
            return true;
          }
          return false;
        });
        expect(hasStrike, findsNothing);
      });

      testWidgets(
          'zero discount is rejected (defensive — never floor below raw)',
          (tester) async {
        const totalStation = Station(
          id: 'fr-totalenergies-3',
          name: 'TotalEnergies Sète',
          brand: 'TotalEnergies',
          street: 'Quai',
          postCode: '34200',
          place: 'Sète',
          lat: 43.40,
          lng: 3.69,
          dist: 1.0,
          e10: 1.799,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const StationCard(
            station: totalStation,
            selectedFuelType: FuelType.e10,
            activeDiscountsByBrand: {'TotalEnergies': 0},
          ),
        );

        // Strike-through text would only appear if a real discount
        // applied. 0 → no badge → no strike-through.
        final hasStrike = find.byWidgetPredicate((w) {
          if (w is Text && w.style?.decoration == TextDecoration.lineThrough) {
            return true;
          }
          return false;
        });
        expect(hasStrike, findsNothing);
      });
    });

    group('card polish (#592)', () {
      testWidgets('card has 6dp vertical margin (breathing room)',
          (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        final card = tester.widget<Card>(find.byType(Card).first);
        expect(
          card.margin,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          reason: 'Vertical margin must be 6dp per #592 spec.',
        );
      });

      testWidgets('card uses elevation 2 in light mode', (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        final card = tester.widget<Card>(find.byType(Card).first);
        expect(card.elevation, 2.0);
      });

      testWidgets('card uses elevation 1 in dark mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: StationCard(
                station: testStation,
                selectedFuelType: FuelType.e10,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final card = tester.widget<Card>(find.byType(Card).first);
        expect(card.elevation, 1.0);
      });

      testWidgets('card has 12dp rounded corners', (tester) async {
        await pumpApp(
          tester,
          const StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        final card = tester.widget<Card>(find.byType(Card).first);
        final shape = card.shape as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          BorderRadius.circular(12),
        );
      });
    });
  });
}
