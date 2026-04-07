import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices_station_card.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../fixtures/stations.dart';

void main() {
  group('AllPricesStationCard', () {
    testWidgets('renders station brand name', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
      );

      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('renders address line when brand is present', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
      );

      expect(find.textContaining('Hauptstr.'), findsOneWidget);
      expect(find.textContaining('10115'), findsOneWidget);
    });

    testWidgets('renders distance', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
      );

      expect(find.textContaining('1,5 km'), findsOneWidget);
    });

    testWidgets('shows open status badge when station is open', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
      );

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('shows closed status badge when station is closed',
        (tester) async {
      final closedStation = testStationList[2]; // isOpen: false

      await pumpApp(
        tester,
        AllPricesStationCard(station: closedStation),
      );

      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('renders fuel price badges for available fuels',
        (tester) async {
      // testStation has e5, e10, diesel
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
      );

      expect(find.text('E5'), findsOneWidget);
      expect(find.text('E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
    });

    testWidgets('does not render badges for unavailable fuels without price',
        (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(station: testStation),
      );

      // testStation has no e98, e85, lpg, cng prices and they are not in
      // unavailableFuels, so badges should not appear
      expect(find.text('E98'), findsNothing);
      expect(find.text('E85'), findsNothing);
      expect(find.text('GPL'), findsNothing);
      expect(find.text('GNV'), findsNothing);
    });

    testWidgets('shows out-of-stock badge for unavailable fuels',
        (tester) async {
      const stationWithUnavailable = Station(
        id: 'test-unavail',
        name: 'Test Station',
        brand: 'TEST',
        street: 'Test Str.',
        postCode: '12345',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        e5: 1.859,
        diesel: 1.659,
        isOpen: true,
        unavailableFuels: ['e10'],
      );

      await pumpApp(
        tester,
        const AllPricesStationCard(station: stationWithUnavailable),
      );

      expect(find.text('E10'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('renders favorite star when isFavorite=true', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(
          station: testStation,
          isFavorite: true,
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, Colors.amber);
    });

    testWidgets('renders unfilled star when isFavorite=false', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(
          station: testStation,
          isFavorite: false,
        ),
      );

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;

      await pumpApp(
        tester,
        AllPricesStationCard(
          station: testStation,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(AllPricesStationCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onFavoriteTap when star is tapped', (tester) async {
      var favTapped = false;

      await pumpApp(
        tester,
        AllPricesStationCard(
          station: testStation,
          onFavoriteTap: () => favTapped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();

      expect(favTapped, isTrue);
    });

    testWidgets('highlights cheapest price badge', (tester) async {
      await pumpApp(
        tester,
        const AllPricesStationCard(
          station: testStation,
          cheapestFlags: {FuelType.diesel: true},
        ),
      );

      // The diesel badge should be rendered (we verify it exists)
      expect(find.text('Diesel'), findsOneWidget);
    });

    testWidgets('renders station with all fuel types', (tester) async {
      const fullStation = Station(
        id: 'full-station',
        name: 'Full Station',
        brand: 'TOTAL',
        street: 'Grande Rue',
        postCode: '34000',
        place: 'Montpellier',
        lat: 43.61,
        lng: 3.88,
        e5: 1.899,
        e10: 1.839,
        e98: 1.989,
        diesel: 1.729,
        e85: 0.859,
        lpg: 0.959,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const AllPricesStationCard(station: fullStation),
      );

      expect(find.text('E5'), findsOneWidget);
      expect(find.text('E10'), findsOneWidget);
      expect(find.text('E98'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('E85'), findsOneWidget);
      expect(find.text('GPL'), findsOneWidget);
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
      );

      expect(find.text('Rue de la Gare'), findsOneWidget);
    });
  });
}
