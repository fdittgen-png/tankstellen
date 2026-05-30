// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/landing_screen_step.dart';

import '../helpers/pump_app.dart';

/// Golden coverage for an OnboardingWizard step (#2352 — the wizard is
/// the first impression and had no golden). `LandingScreenStep` is the
/// most self-contained wizard step: it only reads the wizard-controller
/// provider (whose default `build()` is deterministic), so it pins the
/// step's header + the three landing-choice tiles without dragging in
/// services / router / Hive.
void main() {
  group('OnboardingWizard step golden (#2352)', () {
    testWidgets('landing-screen step — header + three choice tiles',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        const RepaintBoundary(child: LandingScreenStep()),
      );

      await expectLater(
        find.byType(LandingScreenStep),
        matchesGoldenFile('onboarding_landing_step.png'),
      );
    });
  });
}
