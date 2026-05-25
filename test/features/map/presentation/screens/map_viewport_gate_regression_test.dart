// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/current_shell_branch_provider.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Regression lock for the cold-start grey-tile bug (#1605, child #1655).
///
/// The bug — "fixed" nine times across #473–#1316 — is that `flutter_map`'s
/// `TileLayer` captures a zero-sized viewport when `MapScreen` lays out
/// inside the shell's offstage `IndexedStack` branch, then never re-issues
/// tile fetches once real constraints arrive. The structural cure is the
/// viewport gate: `MapScreen` builds the map subtree (`NearbyMapView` /
/// `RouteMapView`) only while Carte is the *visible* shell branch.
///
/// This test pumps `MapScreen` through the exact offstage → onstage →
/// offstage → onstage `IndexedStack` transition the bug lives in. If a
/// future change deletes the gate — the #843-style "delete the defenses"
/// regression — the offstage assertions fail in CI.
void main() {
  /// Branch index of the Carte tab in the bottom-nav `IndexedStack`.
  const mapBranchIndex = 1;

  Future<void> goBranch(WidgetTester tester, int index) async {
    ProviderScope.containerOf(tester.element(find.byType(MapScreen)))
        .read(currentShellBranchProvider.notifier)
        .set(index);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'offstage -> onstage IndexedStack transition builds the map subtree '
    'only while Carte is the visible branch',
    (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [...test.overrides, userPositionNullOverride()],
      );

      // Phase 1 — Carte offstage (default branch 0). The gate is shut:
      // no map subtree, so TileLayer can never capture the degenerate
      // offstage viewport.
      expect(
        find.byType(NearbyMapView),
        findsNothing,
        reason: 'while Carte is offstage the map subtree must not exist',
      );

      // Phase 2 — Carte promoted onstage. The map is built fresh, against
      // real onstage constraints.
      await goBranch(tester, mapBranchIndex);
      expect(
        find.byType(NearbyMapView),
        findsOneWidget,
        reason: 'the map subtree must be built once Carte is visible',
      );

      // Phase 3 — flip away. The gate shuts again: no offstage map is
      // left behind holding a stale viewport.
      await goBranch(tester, 0);
      expect(
        find.byType(NearbyMapView),
        findsNothing,
        reason: 'leaving Carte must tear the map subtree down — if this '
            'fails the structural viewport gate has been removed (#1605)',
      );

      // Phase 4 — return to Carte. The map rebuilds cleanly.
      await goBranch(tester, mapBranchIndex);
      expect(find.byType(NearbyMapView), findsOneWidget);
    },
  );
}
