import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_tile.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_info_cards.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/pump_app.dart';

void main() {
  // Minimal station fixture — extended per test by copyWith.
  const baseStation = ChargingStation(
    id: 'ocm-1',
    name: 'Test Hub',
    latitude: 48.0,
    longitude: 2.0,
  );

  group('EVAddressCard', () {
    testWidgets('renders address text and place icon', (tester) async {
      final station = baseStation.copyWith(
        address: '123 Rue de Test',
        postCode: '34120',
        place: 'Pézenas',
        dist: 1.5,
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('123 Rue de Test'), findsOneWidget);
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('renders postcode + place when both present', (tester) async {
      final station = baseStation.copyWith(
        address: 'Some street',
        postCode: '34120',
        place: 'Pézenas',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('34120 Pézenas'), findsOneWidget);
    });

    testWidgets('renders only postcode when place is empty', (tester) async {
      final station = baseStation.copyWith(
        address: 'Some street',
        postCode: '34120',
        place: '',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('34120'), findsOneWidget);
    });

    testWidgets('renders only place when postcode is empty', (tester) async {
      final station = baseStation.copyWith(
        address: 'Some street',
        postCode: '',
        place: 'Pézenas',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('Pézenas'), findsOneWidget);
    });

    testWidgets('hides postcode/place row when both empty', (tester) async {
      final station = baseStation.copyWith(
        address: 'Just a street',
        postCode: '',
        place: '',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      // Address still shown
      expect(find.text('Just a street'), findsOneWidget);
      // The trimmed combined text would be the empty string; ensure the
      // conditional row does not render any non-empty placeholder.
      expect(find.text(' '), findsNothing);
    });

    testWidgets('renders distance text', (tester) async {
      final station = baseStation.copyWith(
        address: 'Street',
        dist: 2.5,
      );

      await pumpApp(tester, EVAddressCard(station: station));

      // PriceFormatter.formatDistance is exercised. The exact unit/format
      // depends on the locale, but the widget MUST emit a non-empty Text
      // for it. Assert that some Text descendant other than the address
      // is present at the distance position.
      expect(find.byType(Text), findsAtLeastNWidgets(2));
    });
  });

  group('EVConnectorsCard', () {
    testWidgets('renders header with totalPoints count', (tester) async {
      final station = baseStation.copyWith(totalPoints: 4);

      await pumpApp(
        tester,
        EVConnectorsCard(station: station, evColor: Colors.green),
      );

      // English fallback: "Connectors (4 points)"
      expect(find.text('Connectors (4 points)'), findsOneWidget);
      expect(find.byIcon(Icons.electrical_services), findsOneWidget);
    });

    testWidgets('renders one EVConnectorTile per connector', (tester) async {
      final station = baseStation.copyWith(
        totalPoints: 2,
        connectors: const [
          EvConnector(
            id: 'c1',
            type: ConnectorType.ccs,
            rawType: 'CCS2',
            maxPowerKw: 150,
          ),
          EvConnector(
            id: 'c2',
            type: ConnectorType.type2,
            rawType: 'Type 2',
            maxPowerKw: 22,
          ),
        ],
      );

      await pumpApp(
        tester,
        EVConnectorsCard(station: station, evColor: Colors.green),
      );

      expect(find.byType(EVConnectorTile), findsNWidgets(2));
      expect(find.text('CCS2'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
    });

    testWidgets('shows fallback message when connectors empty',
        (tester) async {
      final station = baseStation.copyWith(totalPoints: 0);

      await pumpApp(
        tester,
        EVConnectorsCard(station: station, evColor: Colors.green),
      );

      expect(find.text('No connector details available'), findsOneWidget);
      expect(find.byType(EVConnectorTile), findsNothing);
    });
  });

  group('EVPricingCard', () {
    testWidgets('renders usage cost when present', (tester) async {
      final station = baseStation.copyWith(usageCost: '0.45 €/kWh');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(find.text('Usage cost'), findsOneWidget);
      expect(find.text('0.45 €/kWh'), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget);
    });

    testWidgets('renders unavailable fallback when usageCost null',
        (tester) async {
      await pumpApp(
        tester,
        const EVPricingCard(station: baseStation, evColor: Colors.green),
      );

      expect(find.text('Usage cost'), findsOneWidget);
      expect(
        find.text('Pricing not available from provider'),
        findsOneWidget,
      );
    });

    testWidgets('renders unavailable fallback when usageCost empty',
        (tester) async {
      final station = baseStation.copyWith(usageCost: '');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(
        find.text('Pricing not available from provider'),
        findsOneWidget,
      );
    });
  });

  group('EVLastUpdatedCard', () {
    testWidgets('renders updatedAt timestamp when present', (tester) async {
      final station = baseStation.copyWith(updatedAt: '2024-01-15 14:30');

      await pumpApp(tester, EVLastUpdatedCard(station: station));

      expect(find.text('Last updated'), findsOneWidget);
      expect(find.text('2024-01-15 14:30'), findsOneWidget);
      expect(find.byIcon(Icons.update), findsOneWidget);
    });

    testWidgets('renders Unknown when updatedAt is null', (tester) async {
      await pumpApp(tester, const EVLastUpdatedCard(station: baseStation));

      expect(find.text('Last updated'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('renders attribution and disclaimer', (tester) async {
      await pumpApp(tester, const EVLastUpdatedCard(station: baseStation));

      expect(
        find.text('Data from OpenChargeMap (community-sourced)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Status may not reflect real-time availability'),
        findsOneWidget,
      );
    });
  });
}
