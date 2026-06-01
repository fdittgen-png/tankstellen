// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('UserPositionBar', () {
    testWidgets('shows "Position unknown" when no GPS data', (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionNullOverride(),
        ],
      );

      // When position is null, should show unknown label
      expect(find.textContaining('Position unknown'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('shows GPS button when no position', (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionNullOverride(),
        ],
      );

      expect(find.text('GPS'), findsOneWidget);
    });

    testWidgets('shows distances from search center hint when no position',
        (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionNullOverride(),
        ],
      );

      expect(
        find.textContaining('Distances from search center'),
        findsOneWidget,
      );
    });

    testWidgets('shows position source when GPS data available',
        (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionOverride(lat: 52.52, lng: 13.405, source: 'GPS'),
        ],
      );

      expect(find.textContaining('GPS'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('shows named source when location has custom source',
        (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionOverride(
            lat: 48.8566,
            lng: 2.3522,
            source: 'Paris, France',
          ),
        ],
      );

      expect(find.textContaining('Paris, France'), findsOneWidget);
    });

    testWidgets('shows refresh icon when position is available',
        (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionOverride(lat: 52.52, lng: 13.405),
        ],
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onUpdatePosition when GPS button tapped',
        (tester) async {
      var tapped = false;

      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () => tapped = true),
        overrides: [
          userPositionNullOverride(),
        ],
      );

      await tester.tap(find.text('GPS'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('calls onUpdatePosition when refresh tapped', (tester) async {
      var tapped = false;

      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () => tapped = true),
        overrides: [
          userPositionOverride(lat: 52.52, lng: 13.405),
        ],
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets(
        '#2630 — the route-mode banner is gone: the bar always renders the '
        'GPS readout (no route corridor label, no route icon)', (tester) async {
      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () {}),
        overrides: [
          userPositionOverride(lat: 48.8566, lng: 2.3522, source: 'GPS'),
        ],
      );

      // The removed route-mode branch used Icons.route + the corridor label.
      expect(find.byIcon(Icons.route), findsNothing);
      expect(
        find.textContaining('distances are along the corridor'),
        findsNothing,
      );
      // The normal GPS readout still renders for every mode.
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });
  });
}
