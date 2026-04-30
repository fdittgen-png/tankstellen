import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/current_shell_branch_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/ev/presentation/widgets/ev_map_overlay.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

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

    testWidgets('renders an AppBar with default toolbar metrics',
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

      // Carte uses the canonical PageScaffold AppBar — no compact-height
      // override. Title metrics match every other bottom-nav tab.
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

    testWidgets(
      'mounts FlutterMap with non-zero constraints on first open '
      '(#1164 bug 1 — gray-tile race)',
      (tester) async {
        // Wide-enough viewport so the LayoutBuilder gate opens.
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
            searchStateProvider.overrideWith(
              () => _LoadedSearchState(const [_seedStation]),
            ),
          ],
        );

        // FlutterMap must be in the tree — the LayoutBuilder gate
        // would have suppressed it if the constraints were degenerate
        // (zero width/height).
        expect(
          find.byType(FlutterMap),
          findsOneWidget,
          reason:
              'FlutterMap must render once the body has real constraints. '
              'A SizedBox.shrink() placeholder would mean the gate is '
              'closed and the user sees the gray-tile bug (#1164).',
        );

        // The FlutterMap has been laid out with non-zero size — this is
        // the precondition for TileLayer to fetch tiles, and the
        // explicit fix for bug 1: the offstage IndexedStack pre-mount
        // must NEVER reach FlutterMap with degenerate constraints.
        final mapBox = tester.renderObject<RenderBox>(find.byType(FlutterMap));
        expect(mapBox.size.width, greaterThan(0));
        expect(mapBox.size.height, greaterThan(0));
      },
    );

    testWidgets(
      'suppresses the FlutterMap subtree when wrapped in zero-sized '
      'constraints (offstage IndexedStack pre-mount, #1164 bug 1)',
      (tester) async {
        // Simulate the IndexedStack offstage-mount path: render
        // MapScreen inside a zero-sized container so its body's
        // LayoutBuilder receives degenerate constraints.
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          // SizedBox.shrink forces zero constraints on its child.
          const SizedBox.shrink(child: MapScreen()),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
            searchStateProvider.overrideWith(
              () => _LoadedSearchState(const [_seedStation]),
            ),
          ],
        );

        // With zero-sized constraints reaching the LayoutBuilder, the
        // FlutterMap subtree must NOT mount. If it did, its TileLayer
        // would capture the degenerate viewport and never re-issue
        // tile fetches when real constraints arrive — the #1164 bug 1
        // gray-tile regression.
        expect(
          find.byType(FlutterMap),
          findsNothing,
          reason:
              'LayoutBuilder gate must suppress FlutterMap when '
              'constraints are zero. Otherwise TileLayer captures the '
              'offstage viewport and stays gray (#1164 bug 1).',
        );
      },
    );

    testWidgets(
      'EvToggleButton is in AppBar.actions and title uses default styling',
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

        final appBar = tester.widget<AppBar>(
          find.descendant(
            of: find.byType(MapScreen),
            matching: find.byType(AppBar),
          ),
        );

        // Title styling: no custom titleTextStyle override — Carte tab
        // matches every other tab's title size and font.
        expect(
          appBar.titleTextStyle,
          isNull,
          reason: 'MapScreen no longer overrides titleTextStyle — title '
              'inherits the AppBarTheme default so all bottom-nav tabs '
              'render the same title metrics.',
        );
        expect(
          appBar.toolbarHeight,
          isNull,
          reason: 'MapScreen no longer overrides toolbarHeight — matches '
              'sibling tabs.',
        );

        // EvToggleButton lives in AppBar.actions (not floating in the body).
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(EvToggleButton),
          ),
          findsOneWidget,
          reason: 'EvToggleButton must render inside the AppBar actions slot.',
        );
        expect(
          find.descendant(
            of: find.byType(Positioned),
            matching: find.byType(EvToggleButton),
          ),
          findsNothing,
          reason: 'EvToggleButton must NOT render as a Positioned overlay '
              'inside the body Stack any more.',
        );
      },
    );

    testWidgets(
      'app-resume after >10s on Carte tab rebuilds FlutterMap subtree '
      '(#1268 — tile + chip refresh on resume)',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        // Inject a controllable clock so the test can simulate
        // "paused 30 s ago" without wall-clock sleeps.
        var fakeNow = DateTime(2026, 4, 28, 12);
        await pumpApp(
          tester,
          MapScreen(clockOverride: () => fakeNow),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

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

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MapScreen)),
        );
        // Carte tab is the active branch.
        container.read(currentShellBranchProvider.notifier).set(1);
        await tester.pump();
        await tester.pump();
        final initial = currentIncarnation();

        // Background → simulate 30 s passing → resume.
        final binding = tester.binding;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        fakeNow = fakeNow.add(const Duration(seconds: 30));
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();

        expect(
          currentIncarnation(),
          greaterThan(initial),
          reason:
              'Resuming the app after >10s with the Carte tab visible '
              'must rebuild the FlutterMap subtree (same fix as the '
              'tab-flip listener) so tile fetching restarts and the '
              'station data underlying the price chips refreshes (#1268).',
        );
      },
    );

    testWidgets(
      'app-resume after <10s does NOT rebuild FlutterMap subtree '
      '(#1268 — short blip ignored)',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        var fakeNow = DateTime(2026, 4, 28, 12);
        await pumpApp(
          tester,
          MapScreen(clockOverride: () => fakeNow),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

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

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MapScreen)),
        );
        container.read(currentShellBranchProvider.notifier).set(1);
        await tester.pump();
        await tester.pump();
        final initial = currentIncarnation();

        // Brief blip — notification shade swipe, lock-screen peek, etc.
        final binding = tester.binding;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();
        fakeNow = fakeNow.add(const Duration(seconds: 2));
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();

        expect(
          currentIncarnation(),
          equals(initial),
          reason:
              'Brief lifecycle bounces (<10s) must not pay the rebuild + '
              'search-refresh cost — only sustained backgrounding does '
              '(#1268 acceptance criterion).',
        );
      },
    );

    testWidgets(
      'app-resume on a non-Carte tab does NOT rebuild FlutterMap '
      '(#1268 — only refresh when Carte is visible)',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        var fakeNow = DateTime(2026, 4, 28, 12);
        await pumpApp(
          tester,
          MapScreen(clockOverride: () => fakeNow),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

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

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MapScreen)),
        );
        // User is on Search (branch 0), not Carte.
        container.read(currentShellBranchProvider.notifier).set(0);
        await tester.pump();
        await tester.pump();
        final initial = currentIncarnation();

        final binding = tester.binding;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        fakeNow = fakeNow.add(const Duration(seconds: 30));
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();

        expect(
          currentIncarnation(),
          equals(initial),
          reason:
              'Resume-driven refresh must only fire when Carte is the '
              'visible branch — pre-emptively rebuilding offstage maps '
              'would cancel any tile fetches that would otherwise be '
              'covered by the standard tab-flip listener when the user '
              'returns to Carte (#1268).',
        );
      },
    );
  });
}

class _LoadedSearchState extends SearchState {
  _LoadedSearchState(this._stations);
  final List<Station> _stations;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: _stations
              .map((s) => FuelStationResult(s) as SearchResultItem)
              .toList(),
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

const _seedStation = Station(
  id: 'seed-1',
  name: 'Seed Station',
  brand: 'JET',
  street: 'Berliner Str.',
  houseNumber: '1',
  postCode: '10178',
  place: 'Berlin',
  lat: 52.5210,
  lng: 13.4100,
  dist: 0.8,
  e5: 1.799,
  e10: 1.739,
  diesel: 1.599,
  isOpen: true,
);
