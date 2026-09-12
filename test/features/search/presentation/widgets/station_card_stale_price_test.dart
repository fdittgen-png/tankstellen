// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// #3905 — a stale price must not read like a fresh one.
///
/// #4092 — it no longer does so with a SECOND indicator. The separate
/// amber "Old price" pill beside an "Updated 16/07 11:00" line is gone;
/// the freshness segment itself is the word, so price age is stated once,
/// in words, in the one place the card talks about it.
void main() {
  const freshness = Key('station_card_freshness_word');
  // The fixture's stamp is a fixed instant, so the band it falls in
  // depends entirely on the clock — pin it rather than letting the wall
  // clock decide which band the assertions are about.
  final justAfterFixtureStamp =
      DateTime.parse('2026-03-27T10:00:00+01:00').add(const Duration(hours: 1));

  group('StationCard.isStalePrice', () {
    testWidgets('a fresh stamp reads as metadata: the word, in the muted '
        'colour, no attention state', (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
        overrides: [
          appClockProvider.overrideWithValue(FixedClock(justAfterFixtureStamp)),
        ],
      );

      expect(find.byKey(freshness), findsOneWidget);
      expect(find.text('Old price'), findsNothing);
      final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
      final scheme = Theme.of(tester.element(find.byType(StationCard)))
          .colorScheme;
      expect(icon.color, scheme.onSurfaceVariant);
    });

    testWidgets('the caller\'s own staleness verdict still wins, and it is '
        'the ONE band that gets an attention colour', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isStalePrice: true,
        ),
      );

      expect(find.text('Old price'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.history_toggle_off));
      final scheme = Theme.of(tester.element(find.byType(StationCard)))
          .colorScheme;
      expect(icon.color, scheme.tertiary);
    });

    testWidgets('no timestamp at all: nothing is said about price age',
        (tester) async {
      await pumpApp(
        tester,
        StationCard(
          station: testStation.copyWith(updatedAt: null),
          selectedFuelType: FuelType.e10,
          isStalePrice: true,
        ),
      );

      // An unknown age is not "old" — inventing a verdict from a missing
      // stamp is exactly the false flag #3905 refused to ship.
      expect(find.byKey(freshness), findsNothing);
      expect(find.text('Old price'), findsNothing);
    });

    testWidgets('German copy', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isStalePrice: true,
        ),
        locale: const Locale('de'),
      );

      expect(find.text('Alter Preis'), findsOneWidget);
    });

    testWidgets('French copy', (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isStalePrice: true,
        ),
        locale: const Locale('fr'),
      );

      expect(find.text('Prix ancien'), findsOneWidget);
    });

    // #1699 / #3662 — the segment sits in the cramped metadata row; it
    // must survive the en_XA expansion at 320 dp and a 1.3x font setting.
    testWidgets('stale row does not overflow under en_XA at 320 dp',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
          isStalePrice: true,
        ),
        locale: const Locale('en', 'XA'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(freshness), findsOneWidget);
    });

    testWidgets('stale row does not overflow at 1.3x text scale on 320 dp',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
          isStalePrice: true,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(freshness), findsOneWidget);
    });
  });
}
