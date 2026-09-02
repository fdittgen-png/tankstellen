// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/theme/fuel_colors.dart';
import 'package:tankstellen/core/widgets/animated_price_text.dart';
import 'package:tankstellen/core/widgets/station_card_shell.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices/fuel_comparison_cell.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices/fuel_comparison_table.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices_station_card.dart';
import 'package:tankstellen/features/search/providers/all_prices_comparison_model.dart';
import 'package:tankstellen/features/search/providers/all_prices_table_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3933 (Epic #3925) — the all-prices card is a fuel comparison table.
///
/// Structural assertions only (no golden PNGs): the column set, the cell
/// contents, the delta, the per-100 km number and the verdict, plus the
/// documented degradation to a plain price table.
void main() {
  /// Columns of the flex-fuel French case the issue is written around.
  const franceColumns = AllPricesColumns(
    visible: [FuelType.e10, FuelType.e98, FuelType.diesel, FuelType.e85],
    overflow: [FuelType.lpg],
  );

  const flexStation = Station(
    id: 'fr-flex',
    name: 'Flex',
    brand: 'TOTAL',
    street: 'Grande Rue',
    postCode: '34000',
    place: 'Montpellier',
    lat: 43.61,
    lng: 3.88,
    dist: 2.4,
    e10: 2.089,
    e98: 2.189,
    diesel: 1.929,
    e85: 0.839,
    lpg: 0.959,
    isOpen: true,
  );

  List<Object> tableOverrides({
    AllPricesColumns columns = franceColumns,
    Map<FuelType, double> best = const {},
    FuelCostModel cost = FuelCostModel.empty,
  }) => <Object>[
    ...standardTestOverrides().overrides,
    allPricesColumnsProvider.overrideWithValue(columns),
    allPricesBestByFuelProvider.overrideWithValue(best),
    allPricesFuelCostModelProvider.overrideWithValue(cost),
  ];

  group('AllPricesStationCard — chrome kept from the chip version', () {
    testWidgets('renders station brand name', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('renders address line when brand is present', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      expect(find.textContaining('Hauptstr.'), findsOneWidget);
      expect(find.textContaining('10115'), findsOneWidget);
    });

    testWidgets('renders distance', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      expect(find.textContaining('1,5 km'), findsOneWidget);
    });

    testWidgets('shows open status badge when station is open', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('shows closed status badge when station is closed', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AllPricesStationCard(station: testStationList[2]),
        overrides: tableOverrides(),
      );

      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets(
      '#3198 — an unknown open state shows the Unknown badge, never Closed',
      (tester) async {
        await pumpApp(
          tester,
          AllPricesStationCard(station: testStation.copyWith(isOpen: null)),
          overrides: tableOverrides(),
        );

        expect(find.text('Unknown'), findsOneWidget);
        expect(find.text('Closed'), findsNothing);
        expect(find.text('Open'), findsNothing);
      },
    );

    testWidgets('renders favorite star when isFavorite=true', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation, isFavorite: true),
        overrides: tableOverrides(),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.star)).color, Colors.amber);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        AllPricesStationCard(station: testStation, onTap: () => tapped = true),
        overrides: tableOverrides(),
      );

      await tester.tap(find.byType(AllPricesStationCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('#2974 — the favourite toggle fires a selectionClick haptic', (
      tester,
    ) async {
      final haptics = <String?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String?);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpApp(
        tester,
        AllPricesStationCard(station: testStation, onFavoriteTap: () {}),
        overrides: tableOverrides(),
      );

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();

      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('uses street as title when brand is generic', (tester) async {
      const noBrandStation = Station(
        id: 'no-brand',
        name: 'Generic Station',
        brand: 'Station',
        street: 'Rue de la Gare',
        postCode: '34120',
        place: 'Pezenas',
        lat: 43.46,
        lng: 3.42,
        diesel: 1.659,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const AllPricesStationCard(station: noBrandStation),
        overrides: tableOverrides(),
      );

      expect(find.text('Rue de la Gare'), findsOneWidget);
    });

    testWidgets(
      '#2061 — the "Independent" sentinel does not leak into the title',
      (tester) async {
        const independentStation = Station(
          id: 'indep-2061',
          name: '',
          brand: 'Independent',
          street: '26 AVENUE DE VERDUN',
          postCode: '34120',
          place: 'Pézenas',
          lat: 43.46,
          lng: 3.42,
          e10: 1.999,
          isOpen: true,
        );

        await pumpApp(
          tester,
          const AllPricesStationCard(station: independentStation),
          overrides: tableOverrides(),
        );

        expect(find.text('Independent'), findsNothing);
        expect(find.text('26 AVENUE DE VERDUN'), findsOneWidget);
      },
    );

    testWidgets('built from the shared shell with no accent stripe (#2493)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      final shell = tester.widget<StationCardShell>(
        find.byType(StationCardShell),
      );
      expect(shell.stripeColor, isNull);
    });

    testWidgets('#2973 — each priced cell still flashes on a price change', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(),
      );

      // Four visible columns → four flashable cells, priced or not.
      expect(find.byType(AnimatedPriceText), findsNWidgets(4));
    });
  });

  group('aligned columns (#3933)', () {
    testWidgets(
      'every card renders the SAME columns in the same order, whatever the '
      'station sells',
      (tester) async {
        const sparse = Station(
          id: 'fr-sparse',
          name: 'Sparse',
          brand: 'AVIA',
          street: 's',
          postCode: '34000',
          place: 'p',
          lat: 43.6,
          lng: 3.8,
          diesel: 1.899,
          isOpen: true,
        );

        for (final station in const [flexStation, sparse]) {
          await pumpApp(
            tester,
            AllPricesStationCard(station: station),
            overrides: tableOverrides(),
          );

          final cells = tester
              .widgetList<FuelComparisonCell>(find.byType(FuelComparisonCell))
              .toList();
          expect(
            cells.map((c) => c.data.fuel).toList(),
            franceColumns.visible,
            reason:
                'The column set is list-wide: a station missing a grade must '
                'render a blank cell, never reflow the row.',
          );
        }
      },
    );

    testWidgets('a station without the fuel renders a blank, dimmed cell', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      final cells = tester
          .widgetList<FuelComparisonCell>(find.byType(FuelComparisonCell))
          .toList();
      final e98 = cells.firstWhere((c) => c.data.fuel == FuelType.e98);
      expect(e98.data.isBlank, isTrue);
      // The em-dash placeholder holds the column.
      expect(find.text('—'), findsWidgets);
    });
  });

  group('deltas + emphasis (#3933)', () {
    testWidgets('a dearer price shows its delta against the best result', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(
          best: const {FuelType.e10: 2.029, FuelType.e85: 0.839},
        ),
      );

      expect(find.text('+0,060'), findsOneWidget);
      expect(find.text('best'), findsOneWidget);
    });

    testWidgets('the cheapest cell is filled in its fuel colour', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(best: const {FuelType.e85: 0.839}),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(const ValueKey('all-prices-cell-e85')),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, FuelColors.forType(FuelType.e85));
    });

    testWidgets(
      'the legacy cheapestFlags parameter still drives the emphasis when no '
      'live search backs the card',
      (tester) async {
        await pumpApp(
          tester,
          const AllPricesStationCard(
            station: flexStation,
            cheapestFlags: {FuelType.diesel: true},
          ),
          overrides: tableOverrides(),
        );

        final cells = tester
            .widgetList<FuelComparisonCell>(find.byType(FuelComparisonCell))
            .toList();
        final diesel = cells.firstWhere((c) => c.data.fuel == FuelType.diesel);
        expect(diesel.data.isBestInResults, isTrue);
      },
    );
  });

  group('cost per 100 km + verdict (#3933)', () {
    const flexCost = FuelCostModel(
      litersPer100kmByFuel: {FuelType.e85: 6.0, FuelType.e10: 4.6},
      usableFuels: {
        FuelType.e10,
        FuelType.e5,
        FuelType.e98,
        FuelType.e85,
      },
    );

    testWidgets('the verdict names the fuel that is cheapest per 100 km here', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(cost: flexCost),
      );

      // 0,839 x 6,0 = 5,03 €/100 km beats 2,089 x 4,6 = 9,61 €/100 km.
      expect(find.textContaining('E85'), findsWidgets);
      expect(find.textContaining('5,03 €/100 km'), findsOneWidget);
    });

    testWidgets('the outright-winner marker appears when the price also wins', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(
          best: const {FuelType.e85: 0.839},
          cost: flexCost,
        ),
      );

      expect(find.text('cheapest of the results'), findsOneWidget);
    });

    testWidgets('a fuel the vehicle cannot take is dimmed and priced only', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(cost: flexCost),
      );

      final cells = tester
          .widgetList<FuelComparisonCell>(find.byType(FuelComparisonCell))
          .toList();
      final diesel = cells.firstWhere((c) => c.data.fuel == FuelType.diesel);
      expect(diesel.data.isUsable, isFalse);
      expect(diesel.data.costPer100km, isNull);
    });

    testWidgets(
      'no vehicle / no history — the per-100 km row and the verdict vanish, '
      'the price table survives',
      (tester) async {
        await pumpApp(
          tester,
          const AllPricesStationCard(station: flexStation),
          overrides: tableOverrides(best: const {FuelType.e10: 2.029}),
        );

        final cells = tester
            .widgetList<FuelComparisonCell>(find.byType(FuelComparisonCell))
            .toList();
        expect(cells.every((c) => c.data.costPer100km == null), isTrue);
        expect(find.textContaining('/100 km'), findsNothing);
        expect(find.text('cheapest of the results'), findsNothing);
        // …but prices + deltas are still there.
        expect(find.text('2,089'), findsOneWidget);
        expect(find.text('+0,060'), findsOneWidget);
      },
    );
  });

  group('the "+n" overflow expander (#3933)', () {
    testWidgets('hidden fuels sit behind the expander until it is tapped', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: flexStation),
        overrides: tableOverrides(),
      );

      expect(find.text('+1'), findsOneWidget);
      expect(find.byKey(const ValueKey('all-prices-extra-lpg')), findsNothing);

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('all-prices-extra-lpg')),
        findsOneWidget,
      );
    });

    testWidgets('no expander when the country fits the column budget', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(
          columns: const AllPricesColumns(
            visible: [FuelType.e5, FuelType.e10, FuelType.diesel],
          ),
        ),
      );

      expect(find.textContaining('+1'), findsNothing);
      expect(find.byType(FuelComparisonTable), findsOneWidget);
    });
  });

  group('Mexico PEMEX fuel-grade labels (#2717)', () {
    testWidgets('mx- station shows Magna + Premium, never E5/E98', (
      tester,
    ) async {
      const mxStation = Station(
        id: 'mx-11702',
        name: 'TRENOGAS SA DE CV',
        brand: '',
        street: 'TRENOGAS SA DE CV',
        postCode: '',
        place: '',
        lat: 19.43,
        lng: -99.13,
        e5: 22.95,
        e98: 24.89,
        diesel: 23.45,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const AllPricesStationCard(station: mxStation),
        overrides: tableOverrides(
          columns: const AllPricesColumns(
            visible: [FuelType.e5, FuelType.e98, FuelType.diesel],
          ),
        ),
      );

      expect(find.text('Magna'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('E5'), findsNothing);
      expect(find.text('E98'), findsNothing);
      expect(find.text('Diesel'), findsOneWidget);
    });
  });

  group('card polish (#592)', () {
    testWidgets('card keeps its 6dp margin, elevation 2 and 12dp corners', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
        overrides: tableOverrides(),
      );

      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.margin, const EdgeInsets.symmetric(horizontal: 8,
        vertical: 6));
      expect(card.elevation, 2.0);
      expect(
        (card.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(12),
      );
    });
  });

  group('provider-free rendering (the fallback seam)', () {
    testWidgets(
      'with no overrides at all the card still renders the station\'s own '
      'priced fuels — no provider fault may take the results list down',
      (tester) async {
        await pumpApp(tester, const AllPricesStationCard(station: flexStation));

        expect(find.byType(FuelComparisonTable), findsOneWidget);
        expect(find.byType(FuelComparisonCell), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
