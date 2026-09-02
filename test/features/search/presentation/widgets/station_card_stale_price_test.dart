// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// #3905 — the optional stale-price badge on [StationCard].
void main() {
  const badge = Key('station_card_stale_price_badge');

  group('StationCard.isStalePrice', () {
    testWidgets('default (false) renders the plain "Updated" row, no badge',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
      );

      expect(find.byKey(badge), findsNothing);
      expect(find.text('Old price'), findsNothing);
      expect(find.textContaining('Updated'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.update));
      final scheme = Theme.of(tester.element(find.byType(StationCard)))
          .colorScheme;
      expect(icon.color, scheme.onSurfaceVariant);
    });

    testWidgets('true renders the "Old price" badge and the amber row',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isStalePrice: true,
        ),
      );

      expect(find.byKey(badge), findsOneWidget);
      expect(find.text('Old price'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.update));
      final scheme = Theme.of(tester.element(find.byType(StationCard)))
          .colorScheme;
      expect(icon.color, scheme.tertiary);
    });

    testWidgets('no badge when the station carries no timestamp at all',
        (tester) async {
      await pumpApp(
        tester,
        StationCard(
          station: testStation.copyWith(updatedAt: null),
          selectedFuelType: FuelType.e10,
          isStalePrice: true,
        ),
      );

      expect(find.byKey(badge), findsNothing);
    });

    testWidgets('German badge copy', (tester) async {
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

    testWidgets('French badge copy', (tester) async {
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

    // #1699 / #3662 — the badge sits in the cramped distance row; it must
    // survive the en_XA expansion at 320 dp and a 1.3x font setting.
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
      expect(find.byKey(badge), findsOneWidget);
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
      expect(find.byKey(badge), findsOneWidget);
    });
  });
}
