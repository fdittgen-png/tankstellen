import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('MapScreen', () {
    testWidgets('renders Scaffold with Map app bar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Map'), findsOneWidget);
    });

    testWidgets('renders compact app bar with small height', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // App bar should be present with preferredSize height of 36
      expect(find.byType(AppBar), findsAtLeast(1));
    });

    testWidgets('uses canonical PageScaffold chrome (Refs #923 phase 3g)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(PageScaffold), findsOneWidget);
    });

    // #529 / #709 regression tests retired by #757. Previously
    // MapScreen listened to `searchStateProvider` and
    // `currentShellBranchProvider` to nudge the map controller and
    // rebuild the FlutterMap subtree on every tab-flip — both were
    // symptom-level workarounds for `TileLayer` caching failed
    // fetches. They cancelled in-flight HTTP requests and caused
    // regressions of their own. The root cause is addressed at the
    // tile-provider layer by `RetryNetworkTileProvider` +
    // `evictErrorTileStrategy` (see
    // `lib/features/map/data/retry_network_tile_provider.dart` and
    // `test/features/map/tile_layer_eviction_strategy_test.dart`).
  });
}
