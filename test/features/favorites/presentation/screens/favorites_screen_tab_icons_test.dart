// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #1163 — the `Favoris` and `Conso` bottom-nav destinations both use the
/// shared `TabSwitcher`, but historically only `ConsumptionScreen` passed
/// icons to its `TabSwitcherEntry` list. This left the Favoris sub-tabs
/// label-only — visually inconsistent across two adjacent destinations.
///
/// Lock the harmonised contract: every entry on the Favoris TabSwitcher
/// must carry both a star icon (Favoris) and a bell icon (Alertes de
/// prix), so both sub-tab rows render with the same icon-above-label
/// vertical rhythm.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesScreen sub-tab icons (#1163)', () {
    testWidgets(
      'Favoris tab carries Icons.star_outline and Alertes de prix '
      'tab carries Icons.notifications_outlined',
      (tester) async {
        final test = standardTestOverrides(favoriteIds: const []);
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          // #2155 — pin to a portrait phone surface so the tab-based
          // layout fires (≥600dp OR landscape → side-by-side).
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 800)),
            child: FavoritesScreen(),
          ),
          overrides: test.overrides,
        );

        // The TabSwitcher renders one Tab per entry. Both Tabs must
        // surface their icon — the visual fix the issue asks for.
        final tabs = tester.widgetList<Tab>(find.byType(Tab)).toList();
        expect(tabs, hasLength(2),
            reason: 'FavoritesScreen has exactly two sub-tabs');

        // Each Tab must render an Icon child (the symptom the issue
        // describes is that historically these were absent). #2237 made
        // the tab layout compact (icon beside label inside `Tab.child`
        // rather than the stacked `Tab.icon`), so we assert the rendered
        // Icon inside each Tab instead of the now-unused `Tab.icon` field.
        for (final tabFinder in [
          find.byType(Tab).at(0),
          find.byType(Tab).at(1),
        ]) {
          expect(
            find.descendant(of: tabFinder, matching: find.byType(Icon)),
            findsOneWidget,
            reason: 'Every Favoris sub-tab must carry an icon to match '
                'the Conso style — #1163.',
          );
        }

        // Targeted icon presence — find by IconData on the rendered tree.
        // Star outline lives on the Favoris tab; the empty-state body
        // also renders a star, so we tolerate >=1 here.
        expect(find.byIcon(Icons.star_outline), findsAtLeast(1));
        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      },
    );
  });
}
