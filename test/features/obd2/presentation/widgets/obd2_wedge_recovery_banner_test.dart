// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_recovery_natives.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_detector.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_recovery.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_wedge_recovery_banner.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Minimal fake natives — the banner only drives [openBluetoothSettings].
class _FakeNatives implements Obd2WedgeRecoveryNatives {
  int settingsOpens = 0;

  @override
  Future<bool> openBluetoothSettings() async {
    settingsOpens++;
    return true;
  }

  @override
  Future<bool> fetchUuidsWithSdp(String mac) async => false;
  @override
  Future<bool> removeBond(String mac) async => false;
  @override
  Future<bool> createBond(String mac) async => false;
  @override
  Future<bool> adapterEnabled() async => true;
  @override
  Future<bool> resolveBtIntent(String action) async => false;
  @override
  Future<bool> fireBtIntent(String action) async => false;
}

void main() {
  silenceErrorLoggerSpool();

  late _FakeNatives natives;
  late Obd2WedgeDetector detector;
  late Obd2WedgeRecovery recovery;

  setUp(() {
    natives = _FakeNatives();
    detector = Obd2WedgeDetector();
    recovery = Obd2WedgeRecovery(
      natives: natives,
      detector: detector,
      wait: (_) async {},
    );
  });

  Widget host() =>
      Column(children: [Obd2WedgeRecoveryBanner(recovery: recovery)]);

  group('Obd2WedgeRecoveryBanner (#3422 rung 4)', () {
    testWidgets('zero-height while no hint is pending', (tester) async {
      await pumpApp(tester, host());
      expect(find.byKey(const Key('obd2WedgeHintBanner')), findsNothing);
    });

    testWidgets('shows the localized hint + BT-settings button once the '
        'ladder raises it', (tester) async {
      recovery.hintPending.value = true;
      await pumpApp(tester, host());
      expect(find.byKey(const Key('obd2WedgeHintBanner')), findsOneWidget);
      expect(find.byKey(const Key('obd2WedgeHintBtSettingsButton')),
          findsOneWidget);
      // The localized copy names the physical recoveries.
      expect(find.textContaining('Bluetooth'), findsWidgets);
    });

    testWidgets('the button deep-links the system Bluetooth settings and '
        'keeps the hint up', (tester) async {
      recovery.hintPending.value = true;
      await pumpApp(tester, host());
      await tester
          .tap(find.byKey(const Key('obd2WedgeHintBtSettingsButton')));
      await tester.pumpAndSettle();
      expect(natives.settingsOpens, 1);
      expect(find.byKey(const Key('obd2WedgeHintBanner')), findsOneWidget);
    });

    testWidgets('dismiss hides the banner', (tester) async {
      recovery.hintPending.value = true;
      await pumpApp(tester, host());
      await tester.tap(find.byKey(const Key('obd2WedgeHintDismissButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('obd2WedgeHintBanner')), findsNothing);
      expect(recovery.hintPending.value, isFalse);
    });

    testWidgets('the banner retires by itself when the wedge clears '
        '(adapter reappeared / rung succeeded)', (tester) async {
      // Latch a real wedge, then run the ladder dry so IT raises the hint —
      // the one-time path the field will take.
      for (var i = 0; i < 3; i++) {
        detector.noteClassicConnectOutcome(
            mac: 'AA:BB', ok: false, strategy: 'exhausted');
      }
      await recovery.start('AA:BB');
      expect(recovery.hintPending.value, isTrue);

      await pumpApp(tester, host());
      expect(find.byKey(const Key('obd2WedgeHintBanner')), findsOneWidget);

      detector.noteRecovered('user-retry');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('obd2WedgeHintBanner')), findsNothing);
    });
  });
}
