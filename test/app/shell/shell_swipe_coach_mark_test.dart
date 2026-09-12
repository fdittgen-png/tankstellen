// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bar_visibility.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_center_button.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:tankstellen/app/shell/shell_swipe_coach_mark.dart';
import 'package:tankstellen/core/navigation/search_fab_action_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/silence_error_logger.dart';

/// #4106 — the swipe-away gesture is introduced exactly once.
///
/// A gesture with no affordance is undiscoverable, and a hint that
/// returns is an annoyance. The pill therefore shows once ever, floats
/// in an overlay ABOVE the bar it explains rather than on top of the tab
/// labels, retires itself when ignored, and — the assertion that earns
/// its keep — never intercepts a tap meant for the button beneath it.
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


  group('#4106 — the gesture is introduced once', () {
    testWidgets('the coach mark shows when unseen and not while hidden',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
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
      // The harness has no settings box, so `build` treats it as SEEN —
      // a hint that cannot be remembered as dismissed must never show.
      expect(container.read(shellSwipeCoachSeenProvider), isTrue);
      expect(find.byType(ShellSwipeCoachMark), findsNothing);
    });

    /// The shipped default is "seen" when there is no settings box, so a
    /// test about the hint itself has to say it is unseen out loud.
    Future<ProviderContainer> pumpUnseen(WidgetTester tester) async {
      final container = ProviderContainer(overrides: [
        shellSwipeCoachSeenProvider.overrideWith(_UnseenCoach.new),
      ]);
      addTearDown(container.dispose);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return container;
    }

    testWidgets('an unseen hint names both gestures, in an overlay ABOVE '
        'the bar', (tester) async {
      await pumpUnseen(tester);
      final hint = find.text(
        AppLocalizations.of(tester.element(find.byType(ShellBottomBar)))
            .shellSwipeCoachMark,
      );
      expect(hint, findsOneWidget);
      // Above the bar, not on top of the tab labels it explains — the
      // whole reason it is an OverlayPortal child and not a Stack child.
      expect(tester.getBottomLeft(hint).dy,
          lessThan(tester.getTopLeft(find.text('Map')).dy));
    });

    testWidgets('it never blocks the button underneath — the reason it '
        'lives in the overlay and not the bar stack', (tester) async {
      final container = await pumpUnseen(tester);
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
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('an ignored hint retires itself', (tester) async {
      final container = await pumpUnseen(tester);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
      expect(container.read(shellSwipeCoachSeenProvider), isTrue);
      expect(find.byType(ShellSwipeCoachMark), findsNothing);
    });

    testWidgets('the Dismiss affordance retires it', (tester) async {
      final container = await pumpUnseen(tester);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(ShellBottomBar)));
      await tester.tap(find.text(l10n.dismiss));
      await tester.pumpAndSettle();
      expect(container.read(shellSwipeCoachSeenProvider), isTrue);
    });

    test('markSeen is permanent, and a fresh read is already seen without '
        'storage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(shellSwipeCoachSeenProvider), isTrue);
      await container.read(shellSwipeCoachSeenProvider.notifier).markSeen();
      expect(container.read(shellSwipeCoachSeenProvider), isTrue);
    });
  });
}

/// A coach-seen notifier that reports UNSEEN, so the hint actually
/// renders — the production default with no settings box is "seen".
class _UnseenCoach extends ShellSwipeCoachSeen {
  @override
  bool build() => false;
}
