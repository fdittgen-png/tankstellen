// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #2622 — the station-card layout was reworked (favourite star hoisted out
// of the price row to the top-right, Cheapest badge promoted above the
// price). The previous pixel-golden baselines became stale and, per the
// project rule, macOS-baselined goldens fail Linux CI (3-4% > 1.5% tol) and
// turn master red. These assertions were converted to STRUCTURAL widget
// tests — they exercise the same scenarios without committing platform-
// specific PNGs, so they run identically on macOS and Linux.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_tier.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/amenity_chips.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../helpers/pump_app.dart';
import '../fixtures/stations.dart';

void main() {
  group('StationCard structural snapshots (#2622 — ex-goldens)', () {
    testWidgets('normal open station renders brand + a price', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      expect(find.text('STAR'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('favorite station shows the filled amber star', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
      );

      final star = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(star.color, Colors.amber);
    });

    testWidgets('cheapest station shows the Cheapest badge above the price',
        (tester) async {
      await pumpApp(
        tester,
        StationCard(
          station: testStationList[0],
          selectedFuelType: FuelType.diesel,
          isCheapest: true,
          priceTier: PriceTier.cheap,
        ),
      );

      final cheapest = find.text('Cheapest');
      expect(cheapest, findsOneWidget);
      final cheapestTop = tester.getTopLeft(cheapest).dy;
      final priceTop = tester.getTopLeft(find.byType(RichText).last).dy;
      expect(cheapestTop, lessThan(priceTop));
    });

    testWidgets('closed station shows the expensive tier arrow', (tester) async {
      await pumpApp(
        tester,
        StationCard(
          station: testStationList[2], // isOpen: false
          selectedFuelType: FuelType.e10,
          priceTier: PriceTier.expensive,
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('station with no price still renders the card', (tester) async {
      const noPriceStation = Station(
        id: 'no-price',
        name: 'No Price Station',
        brand: 'ESSO',
        street: 'Alexanderplatz',
        postCode: '10178',
        place: 'Berlin',
        lat: 52.5219,
        lng: 13.4132,
        dist: 3.2,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const StationCard(
          station: noPriceStation,
          selectedFuelType: FuelType.diesel,
        ),
      );

      expect(find.byType(StationCard), findsOneWidget);
      expect(find.text('ESSO'), findsOneWidget);
    });

    testWidgets('station with amenities renders amenity chips', (tester) async {
      const amenityStation = Station(
        id: 'amenity-station',
        name: 'Full Service',
        brand: 'TOTAL',
        street: 'Potsdamer Str.',
        houseNumber: '42',
        postCode: '10785',
        place: 'Berlin',
        lat: 52.5065,
        lng: 13.3721,
        dist: 2.0,
        e5: 1.879,
        e10: 1.819,
        diesel: 1.679,
        isOpen: true,
        updatedAt: '10:30',
        amenities: {
          StationAmenity.shop,
          StationAmenity.carWash,
          StationAmenity.toilet,
        },
      );

      await pumpApp(
        tester,
        const StationCard(
          station: amenityStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      expect(find.byType(AmenityChips), findsOneWidget);
    });

    testWidgets('all-fuels view renders the three price rows', (tester) async {
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

    testWidgets('24h station shows the 24h badge', (tester) async {
      const station24h = Station(
        id: '24h-station',
        name: '24h Tankstelle',
        brand: 'ARAL',
        street: 'Leipziger Str.',
        postCode: '10117',
        place: 'Berlin',
        lat: 52.5100,
        lng: 13.3900,
        dist: 0.5,
        e10: 1.809,
        diesel: 1.669,
        isOpen: true,
        is24h: true,
      );

      await pumpApp(
        tester,
        const StationCard(
          station: station24h,
          selectedFuelType: FuelType.e10,
        ),
      );

      expect(find.text('24h'), findsOneWidget);
    });

    testWidgets(
        'no brand and no name — localized "Unbranded station" title, street '
        'on the address line (#2926)', (tester) async {
      const noBrandStation = Station(
        id: 'no-brand',
        name: '',
        brand: '',
        street: 'Unter den Linden',
        houseNumber: '77',
        postCode: '10117',
        place: 'Berlin',
        lat: 52.5170,
        lng: 13.3889,
        dist: 1.0,
        e10: 1.799,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const StationCard(
          station: noBrandStation,
          selectedFuelType: FuelType.e10,
        ),
      );

      // #2926 — the raw street is NEVER hoisted to the title; an unbranded,
      // unnamed forecourt shows the localized label, and the street drops to
      // the address line instead.
      expect(find.text('Unbranded station'), findsOneWidget);
      expect(find.textContaining('Unter den Linden'), findsOneWidget);
    });
  });
}
