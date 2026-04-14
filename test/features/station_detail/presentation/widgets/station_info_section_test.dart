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

      // Both zone and services should be present. After #483 the
      // services header includes the count in parentheses.
      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Services (3)'), findsOneWidget);

      // Services section should appear BELOW zone section
      final zonePos = tester.getTopLeft(find.text('Zone'));
      final servicesPos = tester.getTopLeft(find.text('Services (3)'));
      expect(servicesPos.dy, greaterThan(zonePos.dy));
    });

    // #483 — services section must be a collapsed-by-default
    // ExpansionTile so highway stations with 10+ services don't
    // blow out the detail screen's vertical layout.
    testWidgets(
        'services section is collapsed by default — service chips are '
        'NOT visible until the user taps the header (#483)',
        (tester) async {
      final stationWithServices = baseStation.copyWith(
        services: ['Toilettes', 'Boutique', 'Lavage', 'Air', 'WC',
            'DAB', 'Resto', 'WiFi', 'Piste poids lourds', 'Recharge'],
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

      // Header with count is visible...
      expect(find.text('Services (10)'), findsOneWidget);
      // ...but individual service chips are NOT yet materialised.
      expect(find.text('Toilettes'), findsNothing);
      expect(find.text('Resto'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets(
        'tapping the services header expands the section and shows '
        'every service chip (#483)',
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

      // Header visible, chips hidden.
      expect(find.text('Services (3)'), findsOneWidget);
      expect(find.byType(Chip), findsNothing);

      // Tap the header to expand.
      await tester.tap(find.text('Services (3)'));
      await tester.pumpAndSettle();

      // Now all three chips are visible.
      expect(find.byType(Chip), findsNWidgets(3));
      expect(find.text('Car Wash'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('ATM'), findsOneWidget);

      // Tap again to collapse.
      await tester.tap(find.text('Services (3)'));
      await tester.pumpAndSettle();
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets(
        'services expansion tile is NOT rendered when the services list '
        'is empty (#483 keeps the existing empty-behaviour)',
        (tester) async {
      final stationNoServices = baseStation.copyWith(
        services: const [],
        department: 'Berlin',
        region: 'Berlin',
      );
      final detail = StationDetail(station: stationNoServices);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(
              station: stationNoServices, detail: detail),
        ),
      );

      // No services header, no ExpansionTile at all for this section.
      expect(find.textContaining('Services ('), findsNothing);
      expect(
        find.byKey(const ValueKey('station-detail-services-expansion')),
        findsNothing,
      );
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

    testWidgets('does not show fuel type chips section', (tester) async {
      // Fuel types are already shown in the price list — the chip section
      // was removed as redundant (issue #321).
      final stationWithFuels = baseStation.copyWith(
        availableFuels: ['Super E5', 'Super E10', 'Diesel'],
      );
      final detail = StationDetail(station: stationWithFuels);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(
              station: stationWithFuels, detail: detail),
        ),
      );

      // "Fuels" section title should not be present
      expect(find.text('Fuels'), findsNothing);
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
