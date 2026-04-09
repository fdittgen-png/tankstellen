import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_info_section.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('StationInfoSection', () {
    const baseStation = Station(
      id: 'test-id',
      name: 'Test Station',
      brand: 'TEST',
      street: 'Hauptstr.',
      houseNumber: '12',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.405,
      dist: 1.0,
      e5: 1.85,
      e10: 1.79,
      diesel: 1.65,
      isOpen: true,
    );

    const baseDetail = StationDetail(station: baseStation);

    testWidgets('renders address section', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: StationInfoSection(station: baseStation, detail: baseDetail),
        ),
      );

      expect(find.text('Address'), findsOneWidget);
      expect(find.textContaining('Hauptstr.'), findsAtLeast(1));
      expect(find.textContaining('Berlin'), findsAtLeast(1));
    });

    testWidgets('renders opening hours section', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: StationInfoSection(station: baseStation, detail: baseDetail),
        ),
      );

      expect(find.text('Opening hours'), findsOneWidget);
    });

    testWidgets('services section appears after location info',
        (tester) async {
      final stationWithServices = baseStation.copyWith(
        services: ['Car Wash', 'Shop', 'ATM'],
        department: 'Berlin',
        region: 'Berlin',
      );
      final detail = StationDetail(station: stationWithServices);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(
              station: stationWithServices, detail: detail),
        ),
      );

      // Both zone and services should be present
      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);

      // Services section should appear BELOW zone section
      final zonePos = tester.getTopLeft(find.text('Zone'));
      final servicesPos = tester.getTopLeft(find.text('Services'));
      expect(servicesPos.dy, greaterThan(zonePos.dy));
    });

    testWidgets('amenities section appears after location info',
        (tester) async {
      final stationWithAmenities = baseStation.copyWith(
        amenities: {StationAmenity.shop, StationAmenity.toilet},
        department: 'Berlin',
        region: 'Berlin',
      );
      final detail = StationDetail(station: stationWithAmenities);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(
              station: stationWithAmenities, detail: detail),
        ),
      );

      expect(find.text('Amenities'), findsOneWidget);

      // Amenities should appear after zone
      final zonePos = tester.getTopLeft(find.text('Zone'));
      final amenitiesPos = tester.getTopLeft(find.text('Amenities'));
      expect(amenitiesPos.dy, greaterThan(zonePos.dy));
    });

    testWidgets('does not show separate last-update ListTile', (tester) async {
      final stationWithUpdate = baseStation.copyWith(
        updatedAt: '2026-03-27T10:00:00+01:00',
      );
      final detail = StationDetail(station: stationWithUpdate);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(
              station: stationWithUpdate, detail: detail),
        ),
      );

      // The old "Dernière mise à jour" ListTile should no longer exist
      expect(find.textContaining('Dernière mise à jour'), findsNothing);
    });
  });
}
