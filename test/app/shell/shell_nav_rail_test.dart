import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:tankstellen/app/shell/shell_nav_rail.dart';

/// Widget tests for [ShellNavRail].
///
/// The rail is a thin wrapper around Material's [NavigationRail] that
/// builds one [NavigationRailDestination] per `items[]` entry. Tests
/// focus on the wiring rather than the rail's internal layout:
///   * one destination per item;
///   * `extended: true` -> [NavigationRailLabelType.none];
///   * `extended: false` -> [NavigationRailLabelType.selected];
///   * tapping a destination fires `onTap(i)`;
///   * the selected slot uses the `filledIcon`, others use
///     `outlinedIcon`;
///   * the `branchForSlot[i]` indirection drives which controller a
///     given visible slot consumes (#893: Conso branch hidden ->
///     non-identity mapping).
///
/// Animation controllers use [TestVSync] and are torn down in
/// `tearDown` — same pattern as `shell_nav_item_test.dart`.
void main() {
  late List<AnimationController> spawned;

  setUp(() {
    spawned = [];
  });

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

  /// Pumps the rail in a Material/Scaffold/Row scaffolding. The
  /// [NavigationRail] insists on being a child of [Row]/[Column]/[Flex]
  /// because it does not size itself horizontally.
  Future<void> pumpRail(
    WidgetTester tester, {
    required List<ShellNavItem> items,
    required List<int> branchForSlot,
    required int currentIndex,
    required List<AnimationController> iconControllers,
    required bool extended,
    required ValueChanged<int> onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ShellNavRail(
                items: items,
                branchForSlot: branchForSlot,
                currentIndex: currentIndex,
                iconControllers: iconControllers,
                extended: extended,
                onTap: onTap,
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  const items = <ShellNavItem>[
    ShellNavItem(Icons.map_outlined, Icons.map, 'Map'),
    ShellNavItem(Icons.search_outlined, Icons.search, 'Search'),
    ShellNavItem(Icons.favorite_outline, Icons.favorite, 'Favorites'),
  ];

  group('ShellNavRail destinations', () {
    testWidgets('renders one NavigationRailDestination per items[] entry',
        (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpRail(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        extended: false,
        onTap: (_) {},
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(items.length));
      expect(rail.selectedIndex, 0);
    });

    testWidgets('selected slot renders filledIcon, others render outlinedIcon',
        (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpRail(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 1, // Search is selected
        iconControllers: controllers,
        extended: false,
        onTap: (_) {},
      );

      // The selected destination renders its `selectedIcon` (filled);
      // unselected destinations render `icon` (outlined). NavigationRail
      // hides the offscreen icons so we expect exactly the visible ones.
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsNothing);

      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.map), findsNothing);

      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });

  group('ShellNavRail labelType', () {
    testWidgets('extended: true -> labelType.none', (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpRail(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        extended: true,
        onTap: (_) {},
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(rail.labelType, NavigationRailLabelType.none);
    });

    testWidgets('extended: false -> labelType.selected', (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpRail(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        extended: false,
        onTap: (_) {},
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.labelType, NavigationRailLabelType.selected);
    });
  });

  group('ShellNavRail onTap', () {
    testWidgets('tapping a destination fires onTap(i)', (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];
      final taps = <int>[];

      await pumpRail(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        extended: false,
        onTap: taps.add,
      );

      // Tap by hitting the visible icon for each destination. Slot 0
      // is selected so its filled icon is on screen; the others render
      // their outlined icon.
      await tester.tap(find.byIcon(Icons.map));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pump();

      expect(taps, [0, 1, 2]);
    });
  });

  group('ShellNavRail branchForSlot indirection', () {
    testWidgets(
      'non-identity branchForSlot wires the matching iconControllers',
      (tester) async {
        // Build a 5-controller list, pass a 3-slot rail that maps
        // visible slot -> branch index = [0, 2, 4].
        final controllers = List<AnimationController>.generate(
          5,
          (_) => newController(),
        );

        await pumpRail(
          tester,
          items: items,
          branchForSlot: const [0, 2, 4],
          currentIndex: 0,
          iconControllers: controllers,
          extended: false,
          onTap: (_) {},
        );

        // Each destination produces two ShellBounceIcon instances —
        // one for `icon` (outlined) and one for `selectedIcon`
        // (filled). Both share the same controller per slot. Expect 2 *
        // items.length, even though the rail only paints one of the
        // pair per destination.
        final bounceIcons =
            tester.widgetList<ShellBounceIcon>(find.byType(ShellBounceIcon))
                .toList();

        // We don't assume how many of the offscreen variants the rail
        // builds — we just check that every painted ShellBounceIcon
        // uses a controller from {controllers[0], controllers[2],
        // controllers[4]} and never one from positions 1 or 3.
        final allowed = {
          controllers[0],
          controllers[2],
          controllers[4],
        };
        final forbidden = {
          controllers[1],
          controllers[3],
        };
        for (final b in bounceIcons) {
          expect(
            allowed.any((c) => identical(c, b.controller)),
            isTrue,
            reason: 'ShellBounceIcon used a controller outside [0, 2, 4]',
          );
          expect(
            forbidden.any((c) => identical(c, b.controller)),
            isFalse,
            reason: 'ShellBounceIcon used a forbidden controller',
          );
        }

        // Sanity: at least items.length painted bounce icons (could be
        // 2 * items.length depending on what the rail keeps in the tree
        // for the unselected variant).
        expect(bounceIcons.length, greaterThanOrEqualTo(items.length));
      },
    );
  });
}
