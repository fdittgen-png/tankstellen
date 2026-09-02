// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/brand_appearance.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/core/widgets/brand_logo.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_header_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const station = ChargingStation(
    id: 'ocm-123',
    name: 'Test Charging Hub',
    operator: 'ChargePoint',
    address: '123 Test St',
    postCode: '12345',
    place: 'Test City',
    latitude: 48.5,
    longitude: 2.3,
    dist: 1.5,
    totalPoints: 4,
  );

  group('EVStationHeaderCard', () {
    testWidgets('renders station name and operator', (tester) async {
      await pumpApp(
        tester,
        const EVStationHeaderCard(
          station: station,
          evColor: Colors.green,
        ),
      );

      expect(find.text('Test Charging Hub'), findsOneWidget);
      expect(find.text('ChargePoint'), findsOneWidget);
    });

    testWidgets('shows status unknown for null operational', (tester) async {
      await pumpApp(
        tester,
        const EVStationHeaderCard(
          station: station,
          evColor: Colors.green,
        ),
      );

      expect(find.text('Status unknown'), findsOneWidget);
    });

    testWidgets('shows Operational for operational station', (tester) async {
      const opStation = ChargingStation(
        id: 'ocm-456',
        name: 'Operational Station',
        operator: 'Operator',
        address: '456 St',
        postCode: '00000',
        place: 'Place',
        latitude: 48.0,
        longitude: 2.0,
        dist: 1.0,
        totalPoints: 1,
        isOperational: true,
      );

      await pumpApp(
        tester,
        const EVStationHeaderCard(
          station: opStation,
          evColor: Colors.green,
        ),
      );

      expect(find.text('Operational'), findsOneWidget);
    });

    // #3931 — every charging point used to carry the same generic
    // `Icons.ev_station`, so a list of Ionity / Fastned / Allego sites
    // read identically. The network's own mark replaces it.
    group('network mark (#3931)', () {
      testWidgets('a recognised network renders its mark, not the generic '
          'charging glyph', (tester) async {
        await pumpApp(
          tester,
          const EVStationHeaderCard(
            station: ChargingStation(
              id: 'ocm-ionity',
              name: 'Aire de Beaune',
              operator: 'IONITY',
              address: 'A6',
              postCode: '21200',
              place: 'Beaune',
              latitude: 47.0,
              longitude: 4.8,
              dist: 3.0,
              totalPoints: 6,
            ),
            evColor: Colors.green,
          ),
        );

        final logo = tester.widget<BrandLogo>(find.byType(BrandLogo));
        expect(logo.kind, BrandKind.ev);
        expect(logo.brand, 'Ionity', reason: 'the raw OCM operator title '
            'must be canonicalised so every spelling shares one mark');
        expect(find.text('IO'), findsOneWidget);
        expect(find.byIcon(Icons.ev_station), findsNothing);
        // The operator text line is unchanged.
        expect(find.text('IONITY'), findsOneWidget);
      });

      testWidgets('an unrecognised operator keeps the raw title and falls '
          'back to the neutral charging tile', (tester) async {
        await pumpApp(
          tester,
          const EVStationHeaderCard(
            station: station, // operator: 'ChargePoint'
            evColor: Colors.green,
          ),
        );

        final logo = tester.widget<BrandLogo>(find.byType(BrandLogo));
        expect(logo.brand, 'ChargePoint');
        expect(find.byIcon(Icons.ev_station), findsOneWidget);
      });

      testWidgets('a station with no operator at all still renders the '
          'neutral charging tile', (tester) async {
        await pumpApp(
          tester,
          const EVStationHeaderCard(
            station: ChargingStation(
              id: 'ocm-bare',
              name: 'Parking Centre',
              address: 'Rue',
              postCode: '75001',
              place: 'Paris',
              latitude: 48.8,
              longitude: 2.3,
              dist: 0.5,
              totalPoints: 2,
            ),
            evColor: Colors.green,
          ),
        );

        final logo = tester.widget<BrandLogo>(find.byType(BrandLogo));
        expect(logo.brand, isEmpty);
        expect(find.byIcon(Icons.ev_station), findsOneWidget);
      });
    });
  });
}
