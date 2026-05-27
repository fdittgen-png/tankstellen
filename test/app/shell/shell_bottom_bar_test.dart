// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';

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

    /// Returns the circular cradle Containers (#1885) — circular boxes
    /// in the bar's own surface colour.
    Iterable<Container> cradles(WidgetTester tester) {
      final ctx = tester.element(find.byType(ShellBottomBar));
      final barColor = Theme.of(ctx).colorScheme.surfaceContainerHighest;
      return tester.widgetList<Container>(find.byType(Container)).where((c) {
        final d = c.decoration;
        return d is BoxDecoration &&
            d.shape == BoxShape.circle &&
            d.color == barColor;
      });
    }

    testWidgets('portrait — the button is seated in a bar-coloured cradle',
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
      expect(cradles(tester), isNotEmpty,
          reason: '#1885 — the centre button sits in a circular cradle '
              'in the bar surface colour.');
    });

    testWidgets('landscape — no cradle (the bar is flat, no head-room)',
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
      expect(cradles(tester), isEmpty);
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
  });

  group('ShellBottomBar layout: portrait vs landscape', () {
    testWidgets('portrait: flat-tab labels rendered, bar Container is 64',
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

      final barContainer =
          tester.widget<Container>(find.byType(Container).first);
      expect(barContainer.constraints?.maxHeight, 64.0);
    });

    testWidgets('landscape: labels hidden, bar Container is 48',
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

      for (final item in items) {
        expect(find.text(item.label), findsNothing);
      }
      final barContainer =
          tester.widget<Container>(find.byType(Container).first);
      expect(barContainer.constraints?.maxHeight, 48.0);
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
}
