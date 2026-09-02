// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
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

    testWidgets(
        'no dedicated Address section — the street already lives in '
        'the AppBar header (#1996 compaction)', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: StationInfoSection(station: baseStation, detail: baseDetail),
        ),
      );

      // The body must NOT repeat the address heading or the street —
      // they are surfaced by the sliver-app-bar header, and duplicating
      // them here was the dominant waste of vertical space.
      expect(find.text('Address'), findsNothing);
      expect(find.textContaining('Hauptstr.'), findsNothing);
    });

    testWidgets('Opening hours — section header hidden when there is '
        'nothing to show (#1996)', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: StationInfoSection(station: baseStation, detail: baseDetail),
        ),
      );

      // baseStation has no `openingHoursText`, isn't 24h, and the
      // detail has no opening-times → the whole section disappears
      // rather than rendering an empty `—` ListTile.
      expect(find.text('Opening hours'), findsNothing);
    });

    testWidgets('Opening hours — section header IS rendered when the '
        'station is 24h (regression for #1996)', (tester) async {
      final station24h = baseStation.copyWith(is24h: true);
      final detail24h = StationDetail(station: station24h);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(station: station24h, detail: detail24h),
        ),
      );

      expect(find.text('Opening hours'), findsOneWidget);
    });

    // #3928 — "Amenities" chips and the collapsed "Services (N)"
    // ExpansionTile were two renderings of the same API list; they are
    // ONE deduplicated "Amenities & services" section now.
    testWidgets('merged Amenities & services section appears after '
        'location info (#3928)', (tester) async {
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

      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Amenities & services'), findsOneWidget);
      // The old separate headings are gone.
      expect(find.text('Amenities'), findsNothing);
      expect(find.textContaining('Services ('), findsNothing);

      final zonePos = tester.getTopLeft(find.text('Zone'));
      final mergedPos = tester.getTopLeft(find.text('Amenities & services'));
      expect(mergedPos.dy, greaterThan(zonePos.dy));
    });

    testWidgets('the merged section is NOT collapsed — up to eight chips '
        'render immediately (#3928 replaces the #483 ExpansionTile)',
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

      expect(find.byType(Chip), findsNWidgets(3));
      expect(find.text('Car Wash'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('ATM'), findsOneWidget);
      // No fold button: three chips are below the eight-chip threshold.
      expect(
        find.byKey(const ValueKey('station-detail-amenities-services-fold')),
        findsNothing,
      );
    });

    testWidgets('a long list folds after eight chips behind '
        '"Show more (n)" (#3928)', (tester) async {
      final stationWithServices = baseStation.copyWith(
        services: const [
          'Piste poids lourds', 'Automate CB', 'Location de vehicules',
          'Vente de gaz domestique', 'Bar', 'Vente de fioul', 'Relais colis',
          'Laverie', 'Douches', 'Aire de jeux',
        ],
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

      expect(find.byType(Chip), findsNWidgets(8));
      expect(find.text('Show more (2)'), findsOneWidget);
      expect(find.text('Douches'), findsNothing);

      await tester.tap(find.text('Show more (2)'));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNWidgets(10));
      expect(find.text('Douches'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('the merged section is NOT rendered when the station has '
        'neither amenities nor services (#3928)', (tester) async {
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

      expect(find.text('Amenities & services'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('a raw service string that repeats a typed amenity is '
        'deduplicated away (#3928)', (tester) async {
      // `Station de lavage` / `Gonflage` / `Distributeur` are the FR
      // wordings behind the carWash / airPump / atm chips above them.
      final station = baseStation.copyWith(
        amenities: {
          StationAmenity.carWash,
          StationAmenity.airPump,
          StationAmenity.atm,
        },
        services: const [
          'Station de lavage',
          'Gonflage',
          'Distributeur',
          'Piste poids lourds',
        ],
        department: 'Berlin',
        region: 'Berlin',
      );
      final detail = StationDetail(station: station);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: StationInfoSection(station: station, detail: detail),
        ),
      );

      // Three typed amenity pills + exactly ONE surviving service chip.
      expect(find.text('Station de lavage'), findsNothing);
      expect(find.text('Gonflage'), findsNothing);
      expect(find.text('Distributeur'), findsNothing);
      expect(find.byType(Chip), findsNWidgets(1));
      expect(find.text('Piste poids lourds'), findsOneWidget);
      expect(find.text('Car Wash'), findsOneWidget);
      expect(find.text('Air'), findsOneWidget);
      expect(find.text('ATM'), findsOneWidget);
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
