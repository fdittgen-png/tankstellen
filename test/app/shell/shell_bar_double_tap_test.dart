// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bar_visibility.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_center_button.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:tankstellen/core/navigation/search_fab_action_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/silence_error_logger.dart';

/// #4107 — a double-tap toggles the chrome, without costing the primary
/// action its instant tap.
///
/// The detector deliberately does NOT use `GestureDetector.onDoubleTap`:
/// a `DoubleTapGestureRecognizer` holds the gesture arena for the whole
/// double-tap window, so every tap beneath it — the nav tabs, and for
/// one commit the round search button — fires ~300 ms late. The last
/// test in this file is the one that matters; it fails the moment anyone
/// puts an `onDoubleTap` back on an ancestor of the button.
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

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
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
              isLandscape: false,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('#4107 — double-tap the bar toggles it', () {
    // The detector reads `PointerDownEvent.timeStamp` — the embedder's
    // own clock, the same source Flutter's recognizers use — so the
    // gesture is measured rather than inferred from frame pumping.
    // `tester.tapAt` stamps every event zero, which would make any two
    // taps look simultaneous; these spell the timestamps out.
    Future<void> tapAtTime(
        WidgetTester tester, Offset at, Duration when) async {
      final gesture = await tester.createGesture();
      await gesture.down(at, timeStamp: when);
      await gesture.up(timeStamp: when + const Duration(milliseconds: 20));
      await tester.pump();
    }

    testWidgets('two quick taps on a tab hide the bar', (tester) async {
      final container = await pump(tester);
      final tab = tester.getCenter(find.text('Map'));
      await tapAtTime(tester, tab, const Duration(milliseconds: 100));
      await tapAtTime(tester, tab, const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isTrue);
    });

    testWidgets('two SLOW taps are two taps, not a toggle', (tester) async {
      final container = await pump(tester);
      final tab = tester.getCenter(find.text('Map'));
      await tapAtTime(tester, tab, const Duration(milliseconds: 100));
      await tapAtTime(tester, tab, const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });

    testWidgets('two quick taps far APART are not a toggle', (tester) async {
      final container = await pump(tester);
      await tapAtTime(tester, tester.getCenter(find.text('Map')),
          const Duration(milliseconds: 100));
      await tapAtTime(tester, tester.getCenter(find.text('Favorites')),
          const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });

    testWidgets('the double-tap does NOT delay the search button — a tap '
        'fires within the frame, never after a 300 ms arena hold',
        (tester) async {
      final container = await pump(tester);
      var fired = 0;
      container.read(searchFabActionControllerProvider.notifier).set(
            SearchFabAction(
              icon: Icons.bolt,
              tooltip: 'Run',
              onTap: () => fired++,
            ),
          );
      await tester.pump();

      await tester.tap(find.byType(ShellCenterButton));
      // ONE frame, no clock advance past it: this is the assertion that
      // matters. `GestureDetector(onDoubleTap:)` on any ancestor of the
      // button holds the arena for kDoubleTapTimeout and `fired` would
      // still be 0 here.
      await tester.pump();
      expect(fired, 1,
          reason: 'the primary action must never wait on a double-tap window');
      expect(container.read(shellBarHiddenProvider), isFalse,
          reason: 'and a single tap is not a toggle');
    });
  });
}
