// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/summary_chip.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('UserPositionBar (row A position segment, #3926)', () {
    testWidgets('renders as ONE summary pill, not a full-width strip', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
        overrides: [userPositionOverride(lat: 52.52, lng: 13.405)],
      );

      expect(find.byType(SummaryChip), findsOneWidget);
    });

    testWidgets('shows "Position unknown" when no GPS data', (tester) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
        overrides: [userPositionNullOverride()],
      );

      expect(find.textContaining('Position unknown'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets(
        'the unknown state keeps the "distances from search center" hint in '
        'its accessibility label', (tester) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
        overrides: [userPositionNullOverride()],
      );

      expect(
        find.bySemanticsLabel(RegExp('Distances from search center')),
        findsOneWidget,
      );
    });

    testWidgets('shows position source and age when GPS data is available', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
        overrides: [
          userPositionOverride(lat: 52.52, lng: 13.405, source: 'GPS'),
        ],
      );

      expect(find.textContaining('GPS'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('shows named source when location has a custom source', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
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

    testWidgets(
        '#3926 — the segment carries NO refresh of its own; the screen has '
        'exactly one refresh, in the app bar', (tester) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
        overrides: [userPositionOverride(lat: 52.52, lng: 13.405)],
      );

      expect(find.byIcon(Icons.refresh), findsNothing);
      // The old "GPS" text button on the unknown branch is gone too.
      expect(find.widgetWithText(TextButton, 'GPS'), findsNothing);
    });

    testWidgets('an explicit onUpdatePosition makes the pill tappable', (
      tester,
    ) async {
      var tapped = false;

      await pumpApp(
        tester,
        UserPositionBar(onUpdatePosition: () => tapped = true),
        overrides: [userPositionOverride(lat: 52.52, lng: 13.405)],
      );

      await tester.tap(find.byType(SummaryChip));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets(
        '#2630 — the route-mode banner is gone: the segment always renders '
        'the GPS readout (no route corridor label, no route icon)',
        (tester) async {
      await pumpApp(
        tester,
        const UserPositionBar(),
        overrides: [
          userPositionOverride(lat: 48.8566, lng: 2.3522, source: 'GPS'),
        ],
      );

      expect(find.byIcon(Icons.route), findsNothing);
      expect(
        find.textContaining('distances are along the corridor'),
        findsNothing,
      );
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });
  });
}
