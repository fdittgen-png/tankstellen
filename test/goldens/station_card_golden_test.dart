import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_tier.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../helpers/pump_app.dart';
import '../fixtures/stations.dart';

void main() {
  group('StationCard golden tests', () {
    testWidgets('normal open station', (tester) async {
      await pumpApp(
        tester,
        const RepaintBoundary(
          child: StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_normal.png'),
      );
    });

    testWidgets('favorite station', (tester) async {
      await pumpApp(
        tester,
        const RepaintBoundary(
          child: StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            isFavorite: true,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_favorite.png'),
      );
    });

    testWidgets('cheapest station with badge', (tester) async {
      await pumpApp(
        tester,
        RepaintBoundary(
          child: StationCard(
            station: testStationList[0], // cheap station
            selectedFuelType: FuelType.diesel,
            isCheapest: true,
            priceTier: PriceTier.cheap,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_cheapest.png'),
      );
    });

    testWidgets('closed station', (tester) async {
      await pumpApp(
        tester,
        RepaintBoundary(
          child: StationCard(
            station: testStationList[2], // isOpen: false
            selectedFuelType: FuelType.e10,
            priceTier: PriceTier.expensive,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_closed.png'),
      );
    });

    testWidgets('station with no price', (tester) async {
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
        const RepaintBoundary(
          child: StationCard(
            station: noPriceStation,
            selectedFuelType: FuelType.diesel,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_no_price.png'),
      );
    });

    testWidgets('station with amenities', (tester) async {
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
        const RepaintBoundary(
          child: StationCard(
            station: amenityStation,
            selectedFuelType: FuelType.e10,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_amenities.png'),
      );
    });

    testWidgets('station with all fuel types displayed', (tester) async {
      await pumpApp(
        tester,
        const RepaintBoundary(
          child: StationCard(
            station: testStation,
            selectedFuelType: FuelType.all,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_all_fuels.png'),
      );
    });

    testWidgets('24h station', (tester) async {
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
        const RepaintBoundary(
          child: StationCard(
            station: station24h,
            selectedFuelType: FuelType.e10,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_24h.png'),
      );
    });

    testWidgets('no brand — address as title', (tester) async {
      const noBrandStation = Station(
        id: 'no-brand',
        name: 'Unknown',
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
        const RepaintBoundary(
          child: StationCard(
            station: noBrandStation,
            selectedFuelType: FuelType.e10,
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('station_card_no_brand.png'),
      );
    });
  });
}
