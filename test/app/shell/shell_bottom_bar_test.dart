import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';

/// Widget tests for [ShellBottomBar].
///
/// The bar is a thin shell over a row of [InkWell] slots that delegates
/// icon rendering to [ShellBounceIcon]. The interesting behaviour is in
/// the wiring:
///   * one slot per `items[]` entry, with the *outlined* icon for
///     non-selected and *filled* icon for the selected slot;
///   * the visible slot index `i` indexes into `iconControllers` via
///     `branchForSlot[i]` so a non-identity `branchForSlot` (e.g. when
///     the Conso branch is hidden, see #893) still wires the right
///     controller to each slot;
///   * the bar height is 64 in portrait and 48 in landscape and the
///     label row is omitted in landscape;
///   * tapping the slot fires `onTap(i)`.
///
/// Tests use [TestVSync] so animation controllers are cheap to spin up
/// and tear down without a real ticker provider.
void main() {
  /// All controllers spawned during a single test, so `tearDown` can
  /// dispose them deterministically. Mirrors the
  /// `shell_nav_item_test.dart` style of registering disposers.
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

  /// Builds an [AnimationController] under [TestVSync] and registers it
  /// for `tearDown`.
  AnimationController newController() {
    final c = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 100),
    );
    spawned.add(c);
    return c;
  }

  /// Pumps the bar inside a minimal MaterialApp so [Theme.of] resolves
  /// without pulling in app-wide Material l10n delegates.
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
      MaterialApp(
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
    );
  }

  const items = <ShellNavItem>[
    ShellNavItem(Icons.map_outlined, Icons.map, 'Map'),
    ShellNavItem(Icons.search_outlined, Icons.search, 'Search'),
    ShellNavItem(Icons.favorite_outline, Icons.favorite, 'Favorites'),
  ];

  group('ShellBottomBar slot rendering', () {
    testWidgets('renders one slot per items[] entry', (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        isLandscape: false,
        onTap: (_) {},
      );

      // One InkWell per slot.
      expect(find.byType(InkWell), findsNWidgets(items.length));
    });

    testWidgets(
      'selected slot uses filledIcon, others use outlinedIcon',
      (tester) async {
        final controllers = [
          newController(),
          newController(),
          newController(),
        ];

        await pumpBar(
          tester,
          items: items,
          branchForSlot: const [0, 1, 2],
          currentIndex: 1,
          iconControllers: controllers,
          isLandscape: false,
          onTap: (_) {},
        );

        // Selected (index 1) -> filled icon present.
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.search_outlined), findsNothing);

        // Unselected slots -> outlined icons present, filled absent.
        expect(find.byIcon(Icons.map_outlined), findsOneWidget);
        expect(find.byIcon(Icons.map), findsNothing);
        expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsNothing);
      },
    );
  });

  group('ShellBottomBar onTap', () {
    testWidgets('tapping slot i fires onTap(i)', (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];
      final taps = <int>[];

      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        isLandscape: false,
        onTap: taps.add,
      );

      // Tap each slot in turn; each tap targets the corresponding
      // outlined icon (slot 0 happens to be selected so its filled icon
      // is what's actually on screen — tap that instead).
      await tester.tap(find.byIcon(Icons.map)); // selected slot 0
      await tester.tap(find.byIcon(Icons.search_outlined)); // slot 1
      await tester.tap(find.byIcon(Icons.favorite_outline)); // slot 2
      await tester.pump();

      expect(taps, [0, 1, 2]);
    });
  });

  group('ShellBottomBar layout: portrait vs landscape', () {
    testWidgets('portrait: label Text is rendered, height is 64',
        (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        isLandscape: false,
        onTap: (_) {},
      );

      // Each slot's label is rendered as Text in portrait.
      for (final item in items) {
        expect(find.text(item.label), findsOneWidget);
      }

      // The bar's outer Container has height 64 in portrait.
      final barContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(barContainer.constraints?.maxHeight, 64.0);
    });

    testWidgets('landscape: label Text is hidden, height is 48',
        (tester) async {
      final controllers = [
        newController(),
        newController(),
        newController(),
      ];

      await pumpBar(
        tester,
        items: items,
        branchForSlot: const [0, 1, 2],
        currentIndex: 0,
        iconControllers: controllers,
        isLandscape: true,
        onTap: (_) {},
      );

      // No label texts in landscape — the row is dropped entirely to
      // shrink the bar.
      for (final item in items) {
        expect(find.text(item.label), findsNothing);
      }

      // Outer Container is 48dp tall in landscape.
      final barContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(barContainer.constraints?.maxHeight, 48.0);
    });
  });

  group('ShellBottomBar branchForSlot indirection', () {
    testWidgets(
      'non-identity branchForSlot wires the matching iconControllers',
      (tester) async {
        // Build a 5-controller list, then pass a 3-slot bar that maps
        // visible slot -> branch index = [0, 2, 4]. Slots 1 and 3
        // (Search + Conso, by analogy with the real shell) are hidden.
        final controllers = List<AnimationController>.generate(
          5,
          (_) => newController(),
        );

        await pumpBar(
          tester,
          items: items,
          branchForSlot: const [0, 2, 4],
          currentIndex: 0,
          iconControllers: controllers,
          isLandscape: false,
          onTap: (_) {},
        );

        // Find every ShellBounceIcon — there are exactly items.length of
        // them — and confirm the controllers wired to them match the
        // controllers at positions 0, 2, 4 of the input list.
        final bounceIcons =
            tester.widgetList<ShellBounceIcon>(find.byType(ShellBounceIcon))
                .toList();
        expect(bounceIcons, hasLength(items.length));

        // Order in the row matches construction order from List.generate.
        expect(identical(bounceIcons[0].controller, controllers[0]), isTrue);
        expect(identical(bounceIcons[1].controller, controllers[2]), isTrue);
        expect(identical(bounceIcons[2].controller, controllers[4]), isTrue);

        // And NOT the controllers at positions 1 and 3 (which are
        // skipped by the indirection).
        expect(
          bounceIcons.any((b) => identical(b.controller, controllers[1])),
          isFalse,
        );
        expect(
          bounceIcons.any((b) => identical(b.controller, controllers[3])),
          isFalse,
        );
      },
    );
  });
}
