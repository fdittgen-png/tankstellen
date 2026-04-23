import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/widgets/animated_splash.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget coverage for the animated splash shipped by #795 phase 2.
///
/// The splash renders *before* Riverpod is wired, so these tests pump it
/// inside a bare-bones `MaterialApp` with the real `AppLocalizations`
/// delegates — no providers, no router. That mirrors the production
/// mount in `main.dart` where `runApp(SplashHost())` fires before
/// `AppInitializer.run()` resolves.
///
/// Source-level structural tests for the main.dart wiring live alongside
/// the existing `app_initializer_test.dart`; see the "#795 phase 2" group.
Future<void> _pumpSplash(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MediaQuery(
        data: MediaQueryData(platformBrightness: brightness),
        child: const Scaffold(body: AnimatedSplash()),
      ),
    ),
  );
  // Let the initial frame + fade-in start without waiting for the
  // indeterminate progress animation to settle (it never does).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('AnimatedSplash rendering', () {
    testWidgets('paints the brand glyph via CustomPaint', (tester) async {
      await _pumpSplash(tester);
      // The glyph is a CustomPaint child inside the fade/scale transitions.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders the Tankstellen wordmark', (tester) async {
      await _pumpSplash(tester);
      // `appTitle` resolves to "Fuel Prices" in the English locale — the
      // wordmark pulls the same localized string as the rest of the app,
      // so this asserts the localization hook works end-to-end.
      expect(find.text('Fuel Prices'), findsOneWidget);
    });

    testWidgets('renders an indeterminate progress indicator',
        (tester) async {
      await _pumpSplash(tester);
      final finder = find.byType(LinearProgressIndicator);
      expect(finder, findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(finder);
      // value=null means indeterminate — we want the progress bar to
      // keep moving while AppInitializer.run finishes its work.
      expect(indicator.value, isNull);
    });

    testWidgets('paints the brand green backdrop on light mode',
        (tester) async {
      await _pumpSplash(tester);
      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(AnimatedSplash),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, AnimatedSplash.brandBackground);
    });

    testWidgets('paints the same brand backdrop on dark mode', (tester) async {
      // The native splash drawable is identical on light + dark, so the
      // Flutter splash must not flip backgrounds on brightness change —
      // doing so would create a jarring colour pop at the handoff.
      await _pumpSplash(tester, brightness: Brightness.dark);
      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(AnimatedSplash),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, AnimatedSplash.brandBackground);
    });
  });

  group('AnimatedSplash accessibility', () {
    testWidgets('exposes a semantic label announcing the loading state',
        (tester) async {
      await _pumpSplash(tester);
      // The semantic label is rendered via a Semantics node with
      // liveRegion:true so TalkBack/VoiceOver announces it as the splash
      // appears. Assert on the raw label string for locale `en`.
      expect(find.bySemanticsLabel('Loading Tankstellen'), findsOneWidget);
    });
  });

  group('AnimatedSplash lifecycle', () {
    testWidgets('survives 1 second of simulated time without throwing',
        (tester) async {
      await _pumpSplash(tester);
      // Drive the animation controller through its full 650ms duration
      // plus the indeterminate progress bar cycle — any thrown exception
      // from dispose / animation listeners would surface here.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes cleanly when swapped out of the tree',
        (tester) async {
      await _pumpSplash(tester);
      // Replace the splash with a blank page — this is what happens when
      // `AppInitializer._launch` calls runApp(TankstellenApp) and the
      // splash host is unmounted. A leaked AnimationController would
      // raise a `LEAK` assertion when the test binding tears down.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      expect(tester.takeException(), isNull);
    });
  });

  group('SplashHost integration', () {
    testWidgets('SplashHost mounts an AnimatedSplash under a WidgetsApp',
        (tester) async {
      // The production wiring in `main.dart` does exactly this — call
      // runApp(SplashHost()) before AppInitializer.run resolves. Pump
      // the real host (no extra wrappers) so any regression in the
      // onGenerateRoute / locale delegates surfaces here.
      await tester.pumpWidget(const SplashHost());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AnimatedSplash), findsOneWidget);
      expect(find.byType(WidgetsApp), findsOneWidget);
    });
  });

  group('#795 phase 2 — main.dart splash wiring', () {
    late String mainSource;
    setUpAll(() {
      mainSource = File('lib/main.dart').readAsStringSync();
    });

    test('main.dart mounts SplashHost before AppInitializer.run', () {
      final runAppIdx = mainSource.indexOf('runApp(const SplashHost());');
      final initRunIdx = mainSource.indexOf('AppInitializer.run');
      expect(runAppIdx, isNonNegative,
          reason: 'main.dart must call runApp(SplashHost) to paint the '
              'animated splash immediately after the native splash fades');
      expect(initRunIdx, isNonNegative);
      expect(runAppIdx, lessThan(initRunIdx),
          reason: 'the splash must mount BEFORE AppInitializer.run so Dart '
              'init happens with the animated splash already on screen — '
              'not after it, which would defeat the whole point');
    });

    test('main.dart is still at most 30 lines', () {
      // The structural invariant set by #424 remains — phase 2 must not
      // cause main.dart to balloon. Splash wiring lives in
      // lib/app/widgets/animated_splash.dart.
      final lines = mainSource.split('\n').length;
      expect(lines, lessThanOrEqualTo(30));
    });
  });
}
