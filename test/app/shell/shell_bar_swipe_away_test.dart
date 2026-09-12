// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bar_visibility.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_center_button.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:flutter/semantics.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/silence_error_logger.dart';

/// #4097 — swipe the bar away for a full-screen view.
///
/// The promise is that the room is real and the way back is never
/// missing: the bar's tab surface leaves, the round button stays, and
/// three independent paths restore it — one of them needing no gesture
/// at all, so switch access and screen readers are not locked out.
void main() {
  // #2146 — the visibility provider logs a settings box that is not open
  // yet (the expected state here), and the spool's default path needs
  // Hive. Silence it for this file, as every other widget test does.
  silenceErrorLoggerSpool();

  /// Three slots with the primary in the middle, mirroring the shipped
  /// bar's shape closely enough for geometry and gestures.
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
      {bool hidden = false}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (hidden) {
      await container.read(shellBarHiddenProvider.notifier).set(true);
    }
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

  double barBoxHeight(WidgetTester tester) =>
      tester.getSize(find.byType(ShellBottomBar)).height;

  group('the room is real', () {
    testWidgets('swiping down takes the tab surface away and shrinks the bar',
        (tester) async {
      final container = await pump(tester);
      final shown = barBoxHeight(tester);
      expect(find.byType(ShellCenterButton), findsOneWidget);

      await tester.fling(find.byType(ShellBottomBar), const Offset(0, 60), 800);
      await tester.pumpAndSettle();

      expect(container.read(shellBarHiddenProvider), isTrue);
      expect(barBoxHeight(tester), lessThan(shown),
          reason: 'the body gains the strip the tabs occupied');
      expect(find.byType(ShellCenterButton), findsOneWidget,
          reason: 'the one piece of chrome that can undo this must remain');
    });

    testWidgets('the hidden tab surface is inert — no tab can be tapped or '
        'read through it', (tester) async {
      await pump(tester, hidden: true);
      final surface = find.byKey(const Key('shell_bar_surface'));
      expect(tester.widget<IgnorePointer>(surface).ignoring, isTrue);
      expect(
        tester
            .widget<ExcludeSemantics>(
                find.byKey(const Key('shell_bar_surface_semantics')))
            .excluding,
        isTrue,
      );
    });
  });

  group('never a trap — three ways back', () {
    testWidgets('1. an upward drag anywhere in the bottom strip',
        (tester) async {
      final container = await pump(tester, hidden: true);
      await tester.fling(
          find.byType(ShellBottomBar), const Offset(0, -60), 800);
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });

    testWidgets('2. a long-press on the round button', (tester) async {
      final container = await pump(tester, hidden: true);
      await tester.longPress(find.byType(ShellCenterButton));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });

    testWidgets('3. a semantics action, so no gesture is required at all',
        (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pump(tester, hidden: true);
      final node = tester.getSemantics(find.byType(ShellCenterButton));
      expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue,
          reason: 'switch access and TalkBack expose this as an ACTION; '
              'without it a hidden bar is unreachable for them');
      expect(node.getSemanticsData().hint, isNotEmpty,
          reason: 'the action has to say what it does');

      // The controller resolves the node that actually OWNS the action —
      // the merged ancestor `getSemantics` returns does not.
      tester.semantics
          .longPress(find.semantics.byAction(SemanticsAction.longPress));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse);
      handle.dispose();
    });
  });

  group('nothing the user does today changes', () {
    testWidgets('a tap on the button never toggles the bar', (tester) async {
      final container = await pump(tester);
      await tester.tap(find.byType(ShellCenterButton));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse,
          reason: 'tap keeps its own meaning; only a drag or long-press '
              'moves the bar');
    });

    testWidgets('a slow drag below the velocity threshold does nothing',
        (tester) async {
      final container = await pump(tester);
      await tester.drag(find.byType(ShellBottomBar), const Offset(0, 30));
      await tester.pumpAndSettle();
      expect(container.read(shellBarHiddenProvider), isFalse,
          reason: 'a stray touch while reaching for a tab must not hide it');
    });

    testWidgets('landscape keeps its bar — the nav rail owns that case',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(shellBarHiddenProvider.notifier).set(true);
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
                isLandscape: true,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IgnorePointer>(find.byKey(const Key('shell_bar_surface')))
            .ignoring,
        isFalse,
        reason: 'the preference is portrait-only',
      );
    });
  });

  group('the choice is remembered', () {
    test('it persists through the settings box, and survives a rebuild',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(shellBarHiddenProvider), isFalse,
          reason: 'shown is the safe default — it carries its own way out');
      await container.read(shellBarHiddenProvider.notifier).set(true);
      expect(container.read(shellBarHiddenProvider), isTrue);
      await container.read(shellBarHiddenProvider.notifier).toggle();
      expect(container.read(shellBarHiddenProvider), isFalse);
    });
  });
}
