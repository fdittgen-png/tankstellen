// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_live_feedback_bar.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_shutter_button.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget coverage of the force-landscape pump-capture gate (#2477):
///
///  * the shutter is DISABLED while portrait and ENABLED while landscape;
///  * the highest-priority "turn your phone sideways" message shows in
///    portrait and overrides the glare / align states.
///
/// The full [PumpDisplayCameraScreen] needs a live camera, so the
/// portrait gate is split into two pure widgets ([PumpShutterButton],
/// [PumpLiveFeedbackBar]) that are driven directly here — no golden PNGs
/// (macOS goldens fail Linux CI per project memory).
void main() {
  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pumpHost(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('PumpShutterButton — portrait gate', () {
    testWidgets('disabled while portrait', (tester) async {
      var taps = 0;
      await pumpHost(
        tester,
        PumpShutterButton(
          isCapturing: false,
          isPortrait: true,
          onCapture: () => taps++,
        ),
      );
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull, reason: 'portrait must block capture');
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('enabled while landscape', (tester) async {
      var taps = 0;
      await pumpHost(
        tester,
        PumpShutterButton(
          isCapturing: false,
          isPortrait: false,
          onCapture: () => taps++,
        ),
      );
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNotNull, reason: 'landscape allows capture');
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });

    testWidgets('disabled while a capture is already running', (tester) async {
      await pumpHost(
        tester,
        PumpShutterButton(
          isCapturing: true,
          isPortrait: false,
          onCapture: () {},
        ),
      );
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
    });

    test('enabled getter is portrait- and capture-gated', () {
      bool e(bool cap, bool portrait) => PumpShutterButton(
            isCapturing: cap,
            isPortrait: portrait,
            onCapture: () {},
          ).enabled;
      expect(e(false, false), isTrue);
      expect(e(false, true), isFalse);
      expect(e(true, false), isFalse);
      expect(e(true, true), isFalse);
    });
  });

  group('PumpLiveFeedbackBar — rotate-to-landscape message', () {
    testWidgets('shows rotate prompt in portrait', (tester) async {
      await pumpHost(
        tester,
        const PumpLiveFeedbackBar(isOverGlared: false, isPortrait: true),
      );
      expect(find.text(en.pumpCameraRotateToLandscape), findsOneWidget);
    });

    testWidgets('rotate prompt overrides glare warning in portrait',
        (tester) async {
      await pumpHost(
        tester,
        // Both portrait AND glared — portrait wins (highest priority).
        const PumpLiveFeedbackBar(isOverGlared: true, isPortrait: true),
      );
      expect(find.text(en.pumpCameraRotateToLandscape), findsOneWidget);
      expect(find.text(en.pumpCameraGlareWarning), findsNothing);
    });

    testWidgets('shows glare warning in landscape when glared',
        (tester) async {
      await pumpHost(
        tester,
        const PumpLiveFeedbackBar(isOverGlared: true, isPortrait: false),
      );
      expect(find.text(en.pumpCameraGlareWarning), findsOneWidget);
      expect(find.text(en.pumpCameraRotateToLandscape), findsNothing);
    });

    testWidgets('shows align hint in landscape when clean', (tester) async {
      await pumpHost(
        tester,
        const PumpLiveFeedbackBar(isOverGlared: false, isPortrait: false),
      );
      expect(find.text(en.pumpCameraAlignHint), findsOneWidget);
      expect(find.text(en.pumpCameraRotateToLandscape), findsNothing);
    });

    testWidgets('hidden entirely while capturing', (tester) async {
      await pumpHost(
        tester,
        const PumpLiveFeedbackBar(
          isOverGlared: false,
          isPortrait: true,
          isCapturing: true,
        ),
      );
      expect(find.text(en.pumpCameraRotateToLandscape), findsNothing);
    });
  });
}
