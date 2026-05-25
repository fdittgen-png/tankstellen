// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/completion_step.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('CompletionStep', () {
    testWidgets('renders shield illustration and text', (tester) async {
      await pumpApp(tester, const CompletionStep());

      // #593: completion step renders the branded ShieldIllustration
      // (privacy shield + fuel drop) instead of the generic check-mark.
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.text('All set!'), findsOneWidget);
      expect(
        find.text('You can change these settings anytime in your profile.'),
        findsOneWidget,
      );
    });

    testWidgets('renders German text with de locale', (tester) async {
      await pumpApp(
        tester,
        const CompletionStep(),
        locale: const Locale('de'),
      );

      expect(find.text('Alles bereit!'), findsOneWidget);
    });

    testWidgets('content stays scrollable under large text scaling (#1698)',
        (tester) async {
      // A short viewport + 3x text scaling: the shield + headline +
      // body no longer fit. Before #1698 the centred Column overflowed
      // (a RenderFlex error fails the test); now the step scrolls.
      tester.view.physicalSize = const Size(400, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3.0)),
            child: const CompletionStep(),
          ),
        ),
      );

      // No overflow was thrown, and the step is genuinely scrollable —
      // the headline is reachable by scrolling.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.scrollUntilVisible(find.text('All set!'), 120);
      expect(find.text('All set!'), findsOneWidget);
    });
  });
}
