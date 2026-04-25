import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/current_shell_branch_provider.dart';
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

    testWidgets(
      'rebuilds FlutterMap subtree when shell branch flips TO Map tab '
      '(#473 / #498 / #709 — IndexedStack offstage-mount workaround)',
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

        // The outermost KeyedSubtree under MapScreen carries the
        // ValueKey<int>(_mapIncarnation). Pre-order traversal returns
        // the highest match first, so .first is ours; flutter_map
        // internal KeyedSubtrees sit deeper in the tree.
        int currentIncarnation() {
          final subtree = tester
              .widgetList<KeyedSubtree>(
                find.descendant(
                  of: find.byType(MapScreen),
                  matching: find.byType(KeyedSubtree),
                ),
              )
              .firstWhere((w) => w.key is ValueKey<int>);
          return (subtree.key as ValueKey<int>).value;
        }

        final initial = currentIncarnation();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MapScreen)),
        );

        // Simulate ShellScreen publishing "Map tab is now visible" (branch 1).
        // _mapIncarnation increments via a post-frame callback then setState,
        // so two pumps are needed to settle.
        container.read(currentShellBranchProvider.notifier).set(1);
        await tester.pump();
        await tester.pump();

        expect(
          currentIncarnation(),
          greaterThan(initial),
          reason:
              'MapScreen must rebuild the FlutterMap subtree when the Map '
              'branch becomes visible. Without the rebuild, TileLayer keeps '
              'the offstage zero-sized viewport it captured at app start '
              'and the map stays gray until manual pan/zoom (#709). The '
              'RetryNetworkTileProvider added in #757 cannot fix this — it '
              'retries failed HTTP fetches, but here the fetch is never '
              'issued.',
        );

        final afterMapEntry = currentIncarnation();

        // Flipping AWAY from the Map tab must NOT bump the incarnation —
        // only entering the Map tab does. Otherwise we'd cancel in-flight
        // tile fetches whenever the user navigates away (the #709
        // regression that originally killed the search-state listener).
        container.read(currentShellBranchProvider.notifier).set(0);
        await tester.pump();
        await tester.pump();

        expect(
          currentIncarnation(),
          equals(afterMapEntry),
          reason:
              'Branch changes that leave the Map tab must not rebuild — '
              'rebuilding cancels in-flight tile HTTP requests (#709).',
        );
      },
    );
  });
}
