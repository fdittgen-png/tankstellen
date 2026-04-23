import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/ev_favorite_card.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/pump_app.dart';

ChargingStation _station({
  String name = 'IONITY Tournefeuille',
  String operator = 'IONITY',
  List<EvConnector> connectors = const [],
}) =>
    ChargingStation(
      id: 'ev-1',
      name: name,
      operator: operator,
      latitude: 43.5,
      longitude: 1.4,
      address: 'A64',
      connectors: connectors,
    );

void main() {
  group('EvFavoriteCard', () {
    testWidgets('renders name, operator, and ev_station icon',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(station: _station()),
      );
      expect(find.text('IONITY Tournefeuille'), findsOneWidget);
      expect(find.text('IONITY'), findsOneWidget);
      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });

    testWidgets('hides operator row when operator is empty',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(station: _station(operator: '')),
      );
      expect(find.text('IONITY Tournefeuille'), findsOneWidget);
      // Only the station name should be present; no operator row.
      expect(find.textContaining('IONITY Tournefeuille,'), findsNothing);
    });

    testWidgets('shows the highest connector power as max kW',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(
          station: _station(connectors: const [
            EvConnector(
                id: '1', type: ConnectorType.type2, maxPowerKw: 22),
            EvConnector(id: '2', type: ConnectorType.ccs, maxPowerKw: 350),
            EvConnector(
                id: '3', type: ConnectorType.chademo, maxPowerKw: 50),
          ]),
        ),
      );
      // 350 kW wins over 22 / 50
      expect(find.text('350 kW'), findsOneWidget);
    });

    testWidgets('shows 0 kW when no connectors are listed', (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(station: _station()),
      );
      expect(find.text('0 kW'), findsOneWidget);
    });

    testWidgets('available/total count reflects connector status',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(
          station: _station(connectors: const [
            EvConnector(
                id: '1',
                type: ConnectorType.ccs,
                maxPowerKw: 150,
                status: ConnectorStatus.available),
            EvConnector(
                id: '2',
                type: ConnectorType.type2,
                maxPowerKw: 22,
                status: ConnectorStatus.occupied),
            EvConnector(
                id: '3',
                type: ConnectorType.ccs,
                maxPowerKw: 150,
                status: ConnectorStatus.unknown),
          ]),
        ),
      );
      // 1 available / 3 total
      expect(find.textContaining('1/3'), findsOneWidget);
    });

    testWidgets('availability label is green when any connector is free',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(
          station: _station(connectors: const [
            EvConnector(
                id: '1',
                type: ConnectorType.ccs,
                maxPowerKw: 150,
                status: ConnectorStatus.available),
          ]),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.power));
      expect(icon.color, Colors.green);
    });

    testWidgets('availability icon is grey when none available',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(
          station: _station(connectors: const [
            EvConnector(
                id: '1',
                type: ConnectorType.ccs,
                maxPowerKw: 150,
                status: ConnectorStatus.occupied),
          ]),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.power));
      expect(icon.color, Colors.grey);
    });

    testWidgets(
        'deduplicates connector-type chips using rawType when present',
        (tester) async {
      await pumpApp(
        tester,
        EvFavoriteCard(
          station: _station(connectors: const [
            EvConnector(
                id: '1',
                type: ConnectorType.ccs,
                rawType: 'CCS',
                maxPowerKw: 150),
            EvConnector(
                id: '2',
                type: ConnectorType.ccs,
                rawType: 'CCS',
                maxPowerKw: 150),
            EvConnector(
                id: '3',
                type: ConnectorType.type2,
                rawType: 'Type 2',
                maxPowerKw: 22),
          ]),
        ),
      );
      // CCS appears on 2 connectors but only as 1 chip
      expect(find.widgetWithText(Chip, 'CCS'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Type 2'), findsOneWidget);
    });

    testWidgets('tap on the card invokes onTap', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        EvFavoriteCard(station: _station(), onTap: () => tapped++),
      );
      await tester.tap(find.text('IONITY Tournefeuille'));
      expect(tapped, 1);
    });

    testWidgets('tap on the star icon invokes onFavoriteTap',
        (tester) async {
      var removed = 0;
      await pumpApp(
        tester,
        EvFavoriteCard(
          station: _station(),
          onFavoriteTap: () => removed++,
        ),
      );
      await tester.tap(find.byIcon(Icons.star));
      expect(removed, 1);
    });

    testWidgets('star is the amber "favorite" cue', (tester) async {
      await pumpApp(tester, EvFavoriteCard(station: _station()));
      final star = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(star.color, Colors.amber);
    });
  });
}
