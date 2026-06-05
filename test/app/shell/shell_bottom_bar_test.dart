// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/routes/shell_branches.dart';
import 'package:tankstellen/app/shell/notched_bar_border.dart';
import 'package:tankstellen/app/shell/search_fab_action_provider.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../fixtures/stations.dart';

/// #2553 — a SearchState seeded with one result so the default FAB tap
/// takes the push-free "other tab WITH results → jump to Search" branch
/// (proves the disabled-action FALLBACK without building the criteria
/// modal, which needs Hive boxes the bare test container lacks).
class _SeededSearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [FuelStationResult(testStation)],
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026),
    ));
  }
}

/// Widget tests for [ShellBottomBar] after the #1874 redesign.
///
/// The bar now renders the `isPrimary` item — Search — as a raised,
/// circular centre button, with the other destinations as flat tabs
/// flanking it. The interesting behaviour:
///   * one tappable [InkWell] per `items[]` entry (flat tabs + the
///     centre button);
///   * the selected slot uses the *filled* icon, others the *outlined*;
///   * flat tabs carry a visible text label in portrait; the centre
///     button never does (icon only, like the reference design);
///   * `branchForSlot[i]` selects which controller drives slot `i`;
///   * `currentIndex == -1` highlights nothing (Settings is open).
void main() {
  late List<AnimationController> spawned;

  setUp(() => spawned = []);
  tearDown(() {
    for (final c in spawned) {
      c.dispose();
    }
    spawned = [];
  });

  AnimationController newController() {
    final c = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 100),
    );
    spawned.add(c);
    return c;
  }

  List<AnimationController> controllers(int n) =>
      List.generate(n, (_) => newController());

  Future<void> pumpBar(
    WidgetTester tester, {
    required List<ShellNavItem> items,
    required List<int> branchForSlot,
    required int currentIndex,
    required List<AnimationController> iconControllers,
    required bool isLandscape,
    required ValueChanged<int> onTap,
  }) {
    return tester.pumpWidget(
      // #2113 — ShellBottomBar became a ConsumerWidget; needs a
      // ProviderScope ancestor even when no overrides are needed.
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ShellBottomBar(
                items: items,
                branchForSlot: branchForSlot,
                currentIndex: currentIndex,
                iconControllers: iconControllers,
                isLandscape: isLandscape,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Real-shape fixture: Search is the centre (primary) slot.
  const items = <ShellNavItem>[
    ShellNavItem(Icons.map_outlined, Icons.map, 'Map'),
    ShellNavItem(Icons.search_outlined, Icons.search, 'Search',
        isPrimary: true),
    ShellNavItem(Icons.favorite_outline, Icons.favorite, 'Favorites'),
  ];

  group('ShellBottomBar slot rendering', () {
    testWidgets('renders one tappable InkWell per items[] entry',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );
      expect(find.byType(InkWell), findsNWidgets(items.length));
    });

    testWidgets('selected slot uses filledIcon, others use outlinedIcon',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 1, // Search (the centre button) selected
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsNothing);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    });

    testWidgets('currentIndex == -1 highlights nothing (Settings open)',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: -1,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );
      // Every slot shows its outlined icon — no filled (selected) icon.
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      expect(find.byIcon(Icons.map), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });

  group('ShellBottomBar centre button', () {
    testWidgets('the primary item is a raised Material circle, not a label',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );

      // The centre (Search) button shows no visible text label —
      // only the two flat tabs do.
      expect(find.text('Search'), findsNothing);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // It is a raised, circular Material.
      final material = tester.widget<Material>(
        find.ancestor(
          of: find.byIcon(Icons.search_outlined),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.shape, isA<CircleBorder>());
      expect(material.elevation, greaterThan(0));
    });

    /// The bar's host [Material] — the one whose `shape` is the
    /// [NotchedBarBorder] (#2552), as opposed to the circular FAB Material.
    NotchedBarBorder barBorder(WidgetTester tester) {
      final material = tester
          .widgetList<Material>(find.byType(Material))
          .firstWhere((m) => m.shape is NotchedBarBorder);
      return material.shape as NotchedBarBorder;
    }

    testWidgets('portrait — the button docks into a notched bar (#2552)',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );
      // #2552 — the bar Material carries a concave notch the FAB docks
      // into: notchRadius = 56/2 + 6 = 34.
      expect(barBorder(tester).notchRadius, 34.0,
          reason: '#2552 — portrait carves a 34dp concave notch into the '
              'bar top edge for the FAB to dock into.');
    });

    testWidgets('landscape — flat bar, no notch (#2552)', (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: true,
        onTap: (_) {},
      );
      // Landscape stays flat: notchRadius 0 → the border degenerates to a
      // plain rectangle.
      expect(barBorder(tester).notchRadius, 0.0);
    });
  });

  group('ShellBottomBar onTap', () {
    testWidgets('tapping a flat tab fires onTap(i) (#1874 + #2113)',
        (tester) async {
      // #2113 — the centre FAB no longer always fires onTap; on a
      // non-Search tab with no live results it opens the criteria
      // modal instead. This test pins the *flat-tab* contract (the
      // one the user relies on for plain navigation). The FAB's
      // new branching is covered separately by the test below.
      final taps = <int>[];
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: taps.add,
      );

      await tester.tap(find.byIcon(Icons.map)); // slot 0, selected
      await tester.tap(find.byIcon(Icons.favorite_outline)); // slot 2
      await tester.pump();

      expect(taps, [0, 2]);
    });

    testWidgets(
        'no branch nav: the FAB degrades to onTap and never root-pushes a '
        'fullscreen route over the shell (#2811)', (tester) async {
      // The branch navigator key is not mounted in this isolated harness
      // (searchBranchNavigatorKey.currentState == null). The OLD fallback
      // root-pushed a fullscreen SearchCriteriaScreen onto the local
      // Navigator — covering the whole shell incl. the bottom bar, which
      // could strand the bar until an app restart. It must now degrade to a
      // branch jump instead.
      final taps = <int>[];
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 1, // Search selected → onSearchBranch → opens criteria
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: taps.add,
      );

      await tester.tap(find.byIcon(Icons.search)); // the centre FAB
      await tester.pump();

      expect(taps, contains(1),
          reason: '#2811 — degrades to a branch jump (onTap), not a push');
      expect(find.byType(SearchCriteriaScreen), findsNothing,
          reason: '#2811 — must NOT root-push a fullscreen route over the '
              'shell when the branch nav is unmounted');
    });

    testWidgets(
        're-tapping the FAB while criteria is current records a breadcrumb, '
        'not a UI ERROR trace, and pushes no duplicate (#2810 + #2874)',
        (tester) async {
      // Mount the search-branch navigator the bar reaches via the global key,
      // with the criteria route already current → the #2810 guard fires.
      final taps = <int>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Stack(
              children: [
                Navigator(
                  key: searchBranchNavigatorKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    settings:
                        const RouteSettings(name: kSearchCriteriaRouteName),
                    builder: (_) => const Scaffold(body: Text('criteria')),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ShellBottomBar(
                    items: items,
                    branchForSlot: const [0, 1, 2],
                    currentIndex: 1, // Search selected → onSearchBranch path
                    iconControllers: controllers(3),
                    isLandscape: false,
                    onTap: taps.add,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      BreadcrumbCollector.clear();
      await tester.tap(find.byIcon(Icons.search)); // the centre FAB
      await tester.pump();

      // #2810 — the guard refuses to stack a second criteria modal: the real
      // SearchCriteriaScreen is never pushed (it would also need Hive).
      expect(find.byType(SearchCriteriaScreen), findsNothing);
      // #2874 — the suppression is a diagnostic breadcrumb, NOT an
      // ErrorLayer.ui trace that would surface in the user-facing error log.
      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(1));
      expect(crumbs.single.action, contains('re-open suppressed'));
    });
  });

  group('ShellBottomBar layout: portrait vs landscape', () {
    /// The bar's height comes from the [SizedBox] under the notched-bar
    /// [Material] (#2552 — the bar is no longer a Container).
    double barHeight(WidgetTester tester) {
      final barMaterial = find.byWidgetPredicate(
        (w) => w is Material && w.shape is NotchedBarBorder,
      );
      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(of: barMaterial, matching: find.byType(SizedBox))
            .first,
      );
      return sizedBox.height!;
    }

    testWidgets('portrait: flat-tab labels rendered, bar is 64 tall',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );

      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      expect(barHeight(tester), 64.0);
    });

    testWidgets('landscape: labels hidden, bar is 48 tall', (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: true,
        onTap: (_) {},
      );

      for (final item in items) {
        expect(find.text(item.label), findsNothing);
      }
      expect(barHeight(tester), 48.0);
    });
  });

  group('ShellBottomBar accessibility', () {
    testWidgets('flat-tab labels use the themed labelMedium size',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );

      final ctx = tester.element(find.byType(ShellBottomBar));
      final themed = Theme.of(ctx).textTheme.labelMedium?.fontSize;
      expect(themed, isNotNull);
      // Each flat-tab label sits under an AnimatedDefaultTextStyle
      // carrying the themed size. (The centre button has no label.)
      for (final label in ['Map', 'Favorites']) {
        final ads = tester.widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        );
        expect(ads.style.fontSize, themed);
      }
    });

    testWidgets('every slot carries a Tooltip with the destination name',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: true,
        onTap: (_) {},
      );

      final tooltips =
          tester.widgetList<Tooltip>(find.byType(Tooltip)).toList();
      expect(tooltips, hasLength(items.length));
      expect(
        tooltips.map((t) => t.message).toSet(),
        items.map((i) => i.label).toSet(),
      );
    });

    testWidgets('meets the Android 48dp tap-target guideline (portrait)',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('renders under RTL directionality without overflow',
        (tester) async {
      await tester.pumpWidget(
        // #2113 — ShellBottomBar became a ConsumerWidget; needs a
        // ProviderScope ancestor.
        ProviderScope(
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: ShellBottomBar(
                    items: items,
                    branchForSlot: const [0, 1, 2],
                    currentIndex: 0,
                    iconControllers: controllers(3),
                    isLandscape: false,
                    onTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(InkWell), findsNWidgets(items.length));
      expect(find.text('Map'), findsOneWidget);
    });
  });

  group('ShellBottomBar SearchFabAction override (#2131)', () {
    Future<ProviderContainer> pumpBarWithContainer(
      WidgetTester tester, {
      SearchFabAction? initialAction,
      ValueChanged<int>? onTap,
      List<Override> overrides = const [],
    }) async {
      final container = ProviderContainer(
        overrides: overrides,
      );
      addTearDown(container.dispose);
      if (initialAction != null) {
        container
            .read(searchFabActionControllerProvider.notifier)
            .set(initialAction);
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ShellBottomBar(
                  items: items,
                  branchForSlot: const [0, 1, 2],
                  currentIndex: 0,
                  iconControllers: controllers(3),
                  isLandscape: false,
                  onTap: onTap ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('enabled action: icon comes from the override, taps fire it',
        (tester) async {
      var fired = 0;
      await pumpBarWithContainer(
        tester,
        initialAction: SearchFabAction(
          icon: Icons.bolt,
          tooltip: 'Run',
          onTap: () => fired++,
        ),
      );
      // The override icon replaces the default Search icon on the FAB.
      expect(find.byIcon(Icons.bolt), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bolt));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets(
        'disabled action: tap FALLS BACK to default (never a dead no-op) '
        '+ surface still dims (#2553)', (tester) async {
      // #2553 — regression: previously a registered-but-disabled action
      // produced a literal `() {}` dead handler with NO fallback, so the
      // central FAB became a permanent no-op the moment a disabled action
      // outlived its screen (offstage criteria modal + no shell reset).
      // The disabled action's own onTap must NOT fire — but the FAB must
      // fall back to the default branch behaviour instead of doing
      // nothing. With Search at slot 1, currentIndex 0 and live results
      // seeded, the default path jumps to the Search branch (onTap(1)).
      var registeredFired = 0;
      final taps = <int>[];
      await pumpBarWithContainer(
        tester,
        onTap: taps.add,
        overrides: [searchStateProvider.overrideWith(_SeededSearchState.new)],
        initialAction: SearchFabAction(
          icon: Icons.bolt,
          tooltip: 'Run',
          enabled: false,
          onTap: () => registeredFired++,
        ),
      );

      await tester.tap(find.byIcon(Icons.bolt));
      await tester.pump();

      // The DISABLED action's own onTap is never invoked...
      expect(registeredFired, 0,
          reason: '#2131 — a disabled action must not fire its own onTap.');
      // ...but the FAB is NOT dead: it fell back to the default
      // branch-switch (onTap(1) → jump to the Search slot).
      expect(taps, contains(1),
          reason: '#2553 — a disabled action must FALL BACK to default, '
              'never become a permanent dead no-op.');

      // KEEP the dim-styling affordance: the button's Material colour is
      // the primary alpha-reduced (matches the [_centerButton] disabled
      // branch). Only the tap *behaviour* changed, not the visual.
      final ctx = tester.element(find.byType(ShellBottomBar));
      final primary = Theme.of(ctx).colorScheme.primary;
      final dimmed = primary.withValues(alpha: 0.38);
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.byIcon(Icons.bolt),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, dimmed);
    });

    testWidgets(
        'a stale/disabled action never yields a dead no-op handler (#2553)',
        (tester) async {
      // Belt-and-braces: whatever a registrant left behind, a disabled
      // action with a do-nothing onTap can never swallow the tap into
      // nothing — the default always runs (here the seeded-results
      // branch-jump fallback).
      final taps = <int>[];
      await pumpBarWithContainer(
        tester,
        onTap: taps.add,
        overrides: [searchStateProvider.overrideWith(_SeededSearchState.new)],
        initialAction: SearchFabAction(
          icon: Icons.bolt,
          tooltip: 'Stale',
          enabled: false,
          onTap: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.bolt));
      await tester.pump();

      expect(taps, isNotEmpty,
          reason: '#2553 — the FAB must always do *something* (default '
              'branch behaviour); it can never be a permanent no-op.');
    });
  });

  group('ShellBottomBar narrow-width label hiding (#2117 item 3)', () {
    Future<void> pumpBarWithWidth(
      WidgetTester tester, {
      required double width,
      required int currentIndex,
    }) {
      // MediaQueryData wrap is more reliable than setSurfaceSize in
      // test mode — the latter doesn't always propagate into
      // MaterialApp's MediaQuery scope.
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 800)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: ShellBottomBar(
                    items: items,
                    branchForSlot: const [0, 1, 2],
                    currentIndex: currentIndex,
                    iconControllers: controllers(3),
                    isLandscape: false,
                    onTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('inactive tabs hide their label when width < 360dp',
        (tester) async {
      await pumpBarWithWidth(
        tester,
        width: 320,
        currentIndex: 0, // Map selected; Favorites inactive
      );

      // Active tab keeps its label; inactive tab drops it on narrow
      // screens.
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('all inactive labels remain when width >= 360dp',
        (tester) async {
      await pumpBarWithWidth(
        tester,
        width: 411,
        currentIndex: 0,
      );

      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });
  });

  group('ShellBottomBar branchForSlot indirection', () {
    testWidgets('each slot is wired to iconControllers[branchForSlot[i]]',
        (tester) async {
      // 5-controller list; a 3-slot bar mapping slot -> branch [0, 2, 4].
      final ctrls = controllers(5);
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 2, 4],
        currentIndex: 0,
        iconControllers: ctrls,
        isLandscape: false,
        onTap: (_) {},
      );

      final bounceIcons = tester
          .widgetList<ShellBounceIcon>(find.byType(ShellBounceIcon))
          .toList();
      expect(bounceIcons, hasLength(items.length));

      // Slots 0/1/2 must be wired to controllers 0/2/4 — checked as a
      // set so this does not depend on tree-traversal order.
      final wired = bounceIcons.map((b) => b.controller).toSet();
      expect(wired, {ctrls[0], ctrls[2], ctrls[4]});
      expect(wired, isNot(contains(ctrls[1])));
      expect(wired, isNot(contains(ctrls[3])));
    });
  });

  group('ShellBottomBar notch (#2552)', () {
    /// The bar's host [Material] — the one whose `shape` is the
    /// [NotchedBarBorder], as opposed to the circular FAB Material.
    Material barMaterial(WidgetTester tester) => tester
        .widgetList<Material>(find.byType(Material))
        .firstWhere((m) => m.shape is NotchedBarBorder);

    /// The circular FAB [Material] wrapping the centre button.
    Material fabMaterial(WidgetTester tester, IconData icon) =>
        tester.widget<Material>(
          find
              .ancestor(of: find.byIcon(icon), matching: find.byType(Material))
              .first,
        );

    testWidgets('portrait paints a notched shape with the FAB centred',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: false,
        onTap: (_) {},
      );

      // The bar carries a concave notch (FAB radius 28 + 6 margin = 34).
      final border = barMaterial(tester).shape as NotchedBarBorder;
      expect(border.notchRadius, 34.0);

      // The FAB is still a raised circle, centred over the notch.
      final fab = fabMaterial(tester, Icons.search_outlined);
      expect(fab.shape, isA<CircleBorder>());
      expect(fab.elevation, greaterThan(0));

      final fabCentre =
          tester.getCenter(find.byIcon(Icons.search_outlined)).dx;
      final barCentre =
          tester.getCenter(find.byType(ShellBottomBar)).dx;
      expect((fabCentre - barCentre).abs(), lessThan(1.0),
          reason: 'the FAB docks in the centre of the notch.');
    });

    testWidgets('portrait — the notch clip does not eat the FAB hit-test',
        (tester) async {
      // Reuse the SearchFabAction harness: register an action, tap the
      // FAB, assert it fired once — proves the antialias clip on the bar
      // Material did not swallow the centred FAB's tap.
      var fired = 0;
      final container = ProviderContainer(overrides: const []);
      addTearDown(container.dispose);
      container.read(searchFabActionControllerProvider.notifier).set(
            SearchFabAction(
              icon: Icons.bolt,
              tooltip: 'Run',
              onTap: () => fired++,
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ShellBottomBar(
                  items: items,
                  branchForSlot: const [0, 1, 2],
                  currentIndex: 0,
                  iconControllers: controllers(3),
                  isLandscape: false,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.bolt));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('landscape — flat bar (notchRadius 0), FAB still present',
        (tester) async {
      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers(3),
        isLandscape: true,
        onTap: (_) {},
      );

      final border = barMaterial(tester).shape as NotchedBarBorder;
      expect(border.notchRadius, 0.0);

      final fab = fabMaterial(tester, Icons.search_outlined);
      expect(fab.shape, isA<CircleBorder>());
    });
  });
}
