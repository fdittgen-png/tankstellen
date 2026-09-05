// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_auto_reset.dart';

import '../../../../helpers/pump_app.dart';

/// #3963 — the OBD2 reset must not wait for a tap: the banners that offer
/// it appear while the user is DRIVING. With no provider graph wired the
/// guarded run degrades to "no link" and reports it in a snackbar, which
/// is exactly the observable proof that it ran.
const _ranSnack = 'Adapter reset — reconnecting in the background';

void main() {
  group('Obd2AutoReset (#3963)', () {
    testWidgets('runs the reset by itself after the delay, once', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Obd2AutoReset(
          armed: true,
          delay: Duration(milliseconds: 300),
        ),
        settle: false,
      );

      // Before the delay: the pending line, and nothing has run.
      expect(find.byKey(const Key('obd2AutoResetPending')), findsOneWidget);
      expect(find.text(_ranSnack), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text(_ranSnack), findsOneWidget);
      // Having fired, the pending line is gone — the episode is spent.
      expect(find.byKey(const Key('obd2AutoResetPending')), findsNothing);

      // It does NOT loop: the supervisor owns the retries from here.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(_ranSnack), findsOneWidget);
    });

    testWidgets('disarmed, it neither shows a line nor runs', (tester) async {
      await pumpApp(
        tester,
        const Obd2AutoReset(
          armed: false,
          delay: Duration(milliseconds: 100),
        ),
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('obd2AutoResetPending')), findsNothing);
      expect(find.text(_ranSnack), findsNothing);
    });

    testWidgets('a link that heals before the delay never triggers a reset', (
      tester,
    ) async {
      final armed = ValueNotifier<bool>(true);
      addTearDown(armed.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: armed,
          builder: (_, value, _) => Obd2AutoReset(
            armed: value,
            delay: const Duration(milliseconds: 300),
          ),
        ),
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 150));
      armed.value = false; // recovered
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_ranSnack), findsNothing);
    });

    testWidgets('the NEXT drop re-arms it', (tester) async {
      final armed = ValueNotifier<bool>(true);
      addTearDown(armed.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: armed,
          builder: (_, value, _) => Obd2AutoReset(
            armed: value,
            delay: const Duration(milliseconds: 200),
          ),
        ),
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.text(_ranSnack), findsOneWidget);

      // Episode over, then a fresh drop.
      armed.value = false;
      await tester.pump();
      armed.value = true;
      await tester.pump();
      expect(find.byKey(const Key('obd2AutoResetPending')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      // The second run reports again (the first snack may still be up).
      expect(find.text(_ranSnack), findsWidgets);
    });
  });
}
