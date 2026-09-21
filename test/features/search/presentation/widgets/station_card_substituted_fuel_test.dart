// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// #4124 — a price that is not the fuel you asked for must say so.
///
/// A cross-border route prices each station by its own country's profile
/// fuel (#2631), so a French E85 at 0,82 and a Spanish E5 at 1,62 land in
/// the same price column of the same list. Read as one column of numbers
/// that is a 50 % price drop; read as two products it is the obvious
/// consequence of Spain not selling E85. The card only ever showed the
/// number.
///
/// The label is opt-in through [StationCard.requestedFuelType]: a
/// single-fuel list leaves it null and every row stays exactly as it was,
/// because a label on all twenty rows tells the reader nothing.
void main() {
  group('StationCard substituted-fuel label', () {
    testWidgets('names the fuel when the price is not the one asked for',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          // What the row is priced by (what `fuelForStation` resolved)…
          selectedFuelType: FuelType.e5,
          // …against what the user chose in the criteria sheet.
          requestedFuelType: FuelType.e85,
        ),
      );

      expect(find.text('E5'), findsOneWidget);
    });

    testWidgets('a screen reader hears the sentence, not the pump code',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e5,
          requestedFuelType: FuelType.e85,
        ),
      );

      // "E5" read out after a price says nothing on its own, so the
      // card's own label carries the whole sentence.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').contains('This price is for E5'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says nothing when the price IS the fuel asked for',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          requestedFuelType: FuelType.e10,
        ),
      );

      expect(find.text('E10'), findsNothing);
    });

    testWidgets('says nothing on a list that never substitutes', (tester) async {
      // Every list but the cross-border route leaves requestedFuelType
      // null — the selected fuel IS what was asked for.
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e5),
      );

      expect(find.text('E5'), findsNothing);
    });

    testWidgets('says nothing under a wildcard search', (tester) async {
      // "Any fuel" already expects whatever the forecourt sells, so a
      // label would sit on every row and mean nothing on any of them.
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e5,
          requestedFuelType: FuelType.all,
        ),
      );

      expect(find.text('E5'), findsNothing);
    });

    testWidgets('says nothing when there is no number to qualify',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: Station(
            id: 'no-price',
            name: 'Ohne Preis',
            brand: 'STAR',
            street: 'Hauptstr.',
            postCode: '10115',
            place: 'Berlin',
            lat: 52.52,
            lng: 13.405,
          ),
          selectedFuelType: FuelType.e5,
          requestedFuelType: FuelType.e85,
        ),
      );

      expect(find.text('E5'), findsNothing);
    });

    testWidgets('uses the station country\'s own pump name (#2717)',
        (tester) async {
      // Mexico's pumps are PEMEX Magna and Premium; "E5" is not a grade
      // anyone there would recognise on a forecourt sign.
      await pumpApp(
        tester,
        const StationCard(
          station: Station(
            id: 'mx-12345',
            name: 'PEMEX',
            brand: 'PEMEX',
            street: 'Av. Reforma',
            postCode: '06500',
            place: 'Ciudad de Mexico',
            lat: 19.4326,
            lng: -99.1332,
            e5: 23.49,
          ),
          selectedFuelType: FuelType.e5,
          requestedFuelType: FuelType.diesel,
        ),
      );

      expect(find.text('Magna'), findsOneWidget);
      expect(find.text('E5'), findsNothing);
    });
  });
}
