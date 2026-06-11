// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StationBrandHeader', () {
    testWidgets(
        'renders real brand as headline and street + postal/place as '
        'subtitle (#1996 — body Address section was dropped, so the '
        'header carries the full address)', (tester) async {
      await pumpApp(
        tester,
        const StationBrandHeader(station: testStation),
      );

      // Real brand renders as headline (STAR); the subtitle now also
      // carries postal code + place so the user keeps the city info
      // even though the dedicated body Address block is gone.
      expect(find.text('STAR'), findsOneWidget);
      expect(find.textContaining('Hauptstr.'), findsAtLeast(1));
      expect(find.textContaining('Berlin'), findsAtLeast(1),
          reason: 'place must still surface in the subtitle');
    });

    testWidgets('shows "Independent station" subtitle for independent sentinel',
        (tester) async {
      const independent = Station(
        id: 's-indep',
        name: 'Independent',
        brand: BrandRegistry.independentLabel,
        street: 'Some Street',
        houseNumber: '1',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        dist: 1.0,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const StationBrandHeader(station: independent),
      );

      // #2161 — when brand is the independent sentinel but `name` is
      // populated, the name takes over the headline (the widget builder
      // already does this — the detail header now matches). The
      // localised "Independent station" subtitle still appears.
      expect(find.text('Independent'), findsOneWidget);
      expect(find.text('Independent station'), findsOneWidget);
    });

    testWidgets(
        '#2161 brand-empty + name-populated → name is the headline '
        '(matches widget builder; widget cold-launch no longer renders '
        'the street in bold)', (tester) async {
      const fromWidget = Station(
        id: 'fr-12345',
        name: 'Intermarché',
        brand: '',
        street: 'Route St Thibéry',
        postCode: '34550',
        place: 'Bessan',
        lat: 43.36,
        lng: 3.40,
        dist: 7.2,
        isOpen: true,
      );

      await pumpApp(tester, const StationBrandHeader(station: fromWidget));

      expect(find.text('Intermarché'), findsOneWidget,
          reason: 'name must take over the headline when brand is empty');
      // Subtitle carries the full address line.
      expect(find.textContaining('Route St Thibéry'), findsAtLeast(1));
      expect(find.textContaining('34550'), findsAtLeast(1));
    });

    testWidgets(
        '#2161 brand-empty + name-empty → street is the headline',
        (tester) async {
      const bareStation = Station(
        id: 'bare',
        name: '',
        brand: '',
        street: 'Only Street',
        postCode: '00000',
        place: 'Nowhere',
        lat: 0,
        lng: 0,
        isOpen: true,
      );

      await pumpApp(tester, const StationBrandHeader(station: bareStation));

      expect(find.text('Only Street'), findsOneWidget,
          reason: 'street is the last-resort headline');
    });
  });
}
