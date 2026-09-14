// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_bar_visibility.dart';
import 'package:tankstellen/app/shell/shell_bottom_bar.dart';
import 'package:tankstellen/app/shell/shell_center_button.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/silence_error_logger.dart';

/// #4168 — the centre button is the anchor the eye follows.
///
/// The endpoints of this animation were always right, and every existing
/// test asserted them. The bug lived entirely in the MIDDLE: a plain
/// `Align` flipped between `topCenter` and `bottomCenter`, so the button
/// jumped its whole travel on the first frame and then sat still while
/// the surface animated for the remaining 219 ms.
///
/// So these tests sample the transition rather than its ends. A test
/// that only checks where things start and stop cannot see a
/// discontinuity between them — which is exactly how this shipped.
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
      {bool hidden = false}) async {
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

  /// Every position the button occupies across a full transition, one
  /// sample per frame.
  Future<List<double>> track(
    WidgetTester tester,
    ProviderContainer container, {
    required bool toHidden,
  }) async {
    final samples = <double>[
      tester.getCenter(find.byType(ShellCenterButton)).dy,
    ];
    await container.read(shellBarHiddenProvider.notifier).set(toHidden);
    // One frame past the declared duration, so the settle is included.
    const step = Duration(milliseconds: 16);
    final frames = kShellBarHideDuration.inMilliseconds ~/ 16 + 2;
    for (var i = 0; i < frames; i++) {
      await tester.pump(step);
      samples.add(tester.getCenter(find.byType(ShellCenterButton)).dy);
    }
    return samples;
  }

  double biggestStep(List<double> samples) {
    var worst = 0.0;
    for (var i = 1; i < samples.length; i++) {
      final d = (samples[i] - samples[i - 1]).abs();
      if (d > worst) worst = d;
    }
    return worst;
  }

  group('the button never teleports', () {
    testWidgets('hiding moves it in trackable steps, not one jump',
        (tester) async {
      final container = await pump(tester);
      final samples = await track(tester, container, toHidden: true);

      // The old `Align` flip put the ENTIRE travel into a single frame.
      // Anything near the total distance here means the snap is back.
      expect(biggestStep(samples), lessThan(3.0),
          reason: 'a per-frame jump the eye cannot follow is the whole '
              'defect — the endpoints were never wrong');
    });

    testWidgets('showing it again is equally continuous', (tester) async {
      final container = await pump(tester, hidden: true);
      final samples = await track(tester, container, toHidden: false);
      expect(biggestStep(samples), lessThan(3.0));
    });

    testWidgets('and it barely has to move at all', (tester) async {
      // The anchor should be nearly stationary: the surface contracts
      // around it. A large total travel would mean the button is being
      // re-homed rather than kept.
      final container = await pump(tester);
      final samples = await track(tester, container, toHidden: true);
      final travel = (samples.last - samples.first).abs();
      expect(travel, greaterThan(0.0),
          reason: 'it does move — a frozen button would mean the box '
              'stopped collapsing');
      expect(travel, lessThan(16.0));
    });

    testWidgets('the travel is monotonic — no overshoot, no backtrack',
        (tester) async {
      // Bounce or elasticity would read as playful. This control is
      // meant to read as physical and restrained.
      final container = await pump(tester);
      final samples = await track(tester, container, toHidden: true);
      final descending = samples.last > samples.first;
      for (var i = 1; i < samples.length; i++) {
        final delta = samples[i] - samples[i - 1];
        expect(descending ? delta : -delta, greaterThanOrEqualTo(-0.01),
            reason: 'frame $i reversed direction');
      }
    });
  });

  group('the shadow says what the button is sitting on', () {
    BoxShadow glow(WidgetTester tester) {
      final boxes = tester
          .widgetList<DecoratedBox>(find.descendant(
            of: find.byType(ShellCenterButton),
            matching: find.byType(DecoratedBox),
          ))
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .where((d) => (d.boxShadow ?? const []).isNotEmpty);
      return boxes.first.boxShadow!.first;
    }

    testWidgets('docked it is tight, floating it is soft and wide',
        (tester) async {
      await pump(tester);
      final docked = glow(tester);
      await pump(tester, hidden: true);
      final floating = glow(tester);

      expect(floating.blurRadius, greaterThan(docked.blurRadius),
          reason: 'over a map it needs an atmospheric shadow, not the '
              'tight one a surface beneath it justified');
      expect(floating.offset.dy, greaterThan(docked.offset.dy));
    });

    testWidgets('and it gets there gradually', (tester) async {
      final container = await pump(tester);
      final start = glow(tester).blurRadius;
      await container.read(shellBarHiddenProvider.notifier).set(true);
      // The first pump rebuilds with the new target and STARTS the
      // tween; it does not advance it. Sampling here instead of after a
      // real elapsed frame is what made this test lie the first time.
      await tester.pump();
      final samples = <double>[];
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(glow(tester).blurRadius);
      }
      await tester.pumpAndSettle();
      final end = glow(tester).blurRadius;

      expect(samples.first, greaterThan(start));
      expect(samples.any((v) => v > start && v < end), isTrue,
          reason: 'a shadow that arrives at its final value on frame one '
              'is the same discontinuity in a different property');
      for (var i = 1; i < samples.length; i++) {
        expect(samples[i], greaterThanOrEqualTo(samples[i - 1]),
            reason: 'frame $i went backwards');
      }
    });
  });
}
