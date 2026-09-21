// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bar_collapse.dart';
import 'package:tankstellen/app/shell/shell_bar_visibility.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_center_button.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/silence_error_logger.dart';

/// #4169 — the bar follows the finger.
///
/// The interaction it replaces was a flick: the user threw the bar and
/// it animated on its own. What makes this feel like a control rather
/// than a command is that the chrome moves WITH the finger and can be
/// stopped, reversed or abandoned halfway.
///
/// The second promise is the one nobody sees and everybody pays for.
/// `PageScaffold` watches the same preference and collapses the TOP app
/// bar with it on 44 screens, so a reserved height that followed the
/// finger would relayout map, lists and charts on every frame of every
/// swipe. Chrome is continuous; layout is quantised. A test that only
/// checked how it looked could not tell those apart, so one here counts
/// the layout values instead.
void main() {
  silenceErrorLoggerSpool();

  final items = <ShellNavItem>[
    const ShellNavItem(Icons.map_outlined, Icons.map, 'Map'),
    const ShellNavItem(Icons.search_outlined, Icons.search, 'Search',
        isPrimary: true),
    const ShellNavItem(Icons.favorite_outline, Icons.favorite, 'Favorites'),
  ];

  late List<AnimationController> controllers;

  setUp(() {
    controllers = [
      for (var i = 0; i < 3; i++)
        AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 1),
        ),
    ];
  });
  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
  });

  Future<ProviderContainer> pump(WidgetTester tester,
      {bool hidden = false, bool isLandscape = false}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (hidden) {
      await container.read(shellBarHiddenProvider.notifier).set(true);
    }
    await container.read(shellSwipeCoachSeenProvider.notifier).markSeen();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: ShellBottomBar(
              items: items,
              branchForSlot: List<int>.generate(items.length, (i) => i),
              currentIndex: 0,
              iconControllers: controllers,
              isLandscape: isLandscape,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Drag [dy] in realistic increments.
  ///
  /// A single `moveBy` is consumed entirely by touch slop —
  /// `DragStartBehavior.start` reports `onStart` at the recognition
  /// point and emits no update for the distance that got it there — so a
  /// one-shot move moves nothing. A real finger produces a stream of
  /// move events; this reproduces that, and the extra slop step at the
  /// front is what a real drag also pays.
  Future<TestGesture> dragBy(WidgetTester tester, double dy) async {
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(ShellBottomBar)));
    // Clear the slop first, in the direction of travel.
    await gesture.moveBy(Offset(0, dy.isNegative ? -20 : 20));
    await tester.pump();
    const steps = 8;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, dy / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    return gesture;
  }

  double buttonY(WidgetTester tester) =>
      tester.getCenter(find.byType(ShellCenterButton)).dy;
  double barHeight(WidgetTester tester) =>
      tester.getSize(find.byType(ShellBottomBar)).height;

  group('the chrome moves with the finger', () {
    testWidgets('a half pull leaves the bar half collapsed, not settled',
        (tester) async {
      final container = await pump(tester);
      final expanded = buttonY(tester);

      // The drag extent is the bar's own height (64 dp), so ~32 dp of
      // real travel is half the collapse.
      final gesture = await dragBy(tester, 12);

      expect(buttonY(tester), greaterThan(expanded),
          reason: 'the chrome must have moved before the finger lifted — '
              'that is the entire difference from the flick it replaces');
      expect(container.read(shellBarHiddenProvider), isFalse,
          reason: 'nothing is decided until the finger lifts');

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('abandoning below the threshold springs back', (tester) async {
      final container = await pump(tester);
      final expanded = buttonY(tester);

      // Released slowly, so velocity cannot decide it — the slop step
      // alone leaves progress well under the threshold.
      final gesture = await dragBy(tester, 4);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(container.read(shellBarHiddenProvider), isFalse);
      expect(buttonY(tester), moreOrLessEquals(expanded, epsilon: 0.5));
    });

    testWidgets('past the threshold it settles collapsed', (tester) async {
      final container = await pump(tester);
      final gesture = await dragBy(tester, 48);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(container.read(shellBarHiddenProvider), isTrue);
    });

    testWidgets('the flick people already have still works', (tester) async {
      // #4097 shipped a velocity gate and users learned it. Making the
      // bar draggable must not cost them the gesture they have.
      final container = await pump(tester);
      await tester.fling(find.byType(ShellBottomBar), const Offset(0, 60), 900);
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isTrue);

      await tester.fling(
          find.byType(ShellBottomBar), const Offset(0, -60), 900);
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });

    testWidgets('velocity beats position when the two disagree',
        (tester) async {
      // A fling cannot prove this: by the time it carries enough travel
      // to register a velocity at all, it has also moved far enough that
      // position alone would decide the same way. So this pulls WELL
      // past the threshold and then flicks back without returning below
      // it — position says collapse, the finger says otherwise.
      final container = await pump(tester);
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(ShellBottomBar)));
      await gesture.moveBy(const Offset(0, 20)); // slop
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(0, 4.75));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // ~0.90 of the way collapsed, then a short, fast reversal.
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -3));
        await tester.pump(const Duration(milliseconds: 1));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(container.read(shellBarHiddenProvider), isFalse,
          reason: 'released at ~0.8 — well past the 0.45 threshold — so '
              'only the upward velocity can explain expanding');
    });

    testWidgets('an upward pull from collapsed brings it back', (tester) async {
      final container = await pump(tester, hidden: true);
      final gesture = await dragBy(tester, -48);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(container.read(shellBarHiddenProvider), isFalse);
    });

    testWidgets('over-pulling is a no-op, never a rubber band', (tester) async {
      final container = await pump(tester);
      final gesture = await dragBy(tester, 80);
      final atEnd = buttonY(tester);
      await gesture.moveBy(const Offset(0, 400));
      await tester.pump();

      expect(buttonY(tester), moreOrLessEquals(atEnd, epsilon: 0.5),
          reason: 'there is nothing past collapsed to reveal');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isTrue);
    });
  });

  group('layout is quantised — the cost nobody sees', () {
    testWidgets('the reserved height takes two values across a whole drag, '
        'never a third', (tester) async {
      // This is the number every body in the app reads as
      // `MediaQuery.padding.bottom`. A third value means it started
      // following the finger, and 44 screens started relayouting at
      // 60 fps.
      await pump(tester);
      final seen = <double>{barHeight(tester)};

      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(ShellBottomBar)));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 4));
        await tester.pump(const Duration(milliseconds: 16));
        seen.add(barHeight(tester));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      seen.add(barHeight(tester));

      expect(seen.length, lessThanOrEqualTo(2),
          reason: 'saw ${seen.toList()..sort()} — chrome is continuous, '
              'layout is not');
    });

    testWidgets('the button still moves continuously while it does',
        (tester) async {
      // The other half of the split: quantising the LAYOUT must not
      // quantise what the user is looking at.
      await pump(tester);
      final ys = <double>[buttonY(tester)];

      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(ShellBottomBar)));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 4));
        await tester.pump(const Duration(milliseconds: 16));
        ys.add(buttonY(tester));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(ys.toSet().length, greaterThan(3),
          reason: 'the anchor should track the finger, not step');
    });
  });

  group('landscape is untouched', () {
    testWidgets('no drag recognizer is installed at all', (tester) async {
      // ShellNavRail owns that case and the bar never hides there.
      final container = await pump(tester, isLandscape: true);
      final collapse =
          tester.widget<ShellBarCollapse>(find.byType(ShellBarCollapse));
      expect(collapse.enabled, isFalse);

      await tester.fling(find.byType(ShellBottomBar), const Offset(0, 60), 900);
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });
  });
}
