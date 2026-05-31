// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_response_class.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_diagnostics_card.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/obd2_health_screen.dart';

import '../../../../../helpers/pump_app.dart';

/// Structural coverage for the OBD2 communication-health dev-tools screen
/// (#2471, Epic #2463). No goldens — find-by-key / find-by-text only.
void main() {
  final collector = Obd2CommDiagnostics.instance;

  setUp(() => collector
    ..reset()
    ..enabled = false);
  tearDown(() => collector
    ..reset()
    ..enabled = false);

  List<Object> overrides({required bool debugOn}) => [
        enabledFeaturesProvider.overrideWithValue(
          debugOn ? {Feature.debugMode} : <Feature>{},
        ),
      ];

  void seedLiveSession() {
    collector.enabled = true;
    collector
      ..beginSession(linkKind: 'ble', redactedMac: '···············E:FF')
      ..recordAdapterIdentity(elmVersion: 'ELM327 v1.5', protocolDigit: '6')
      ..noteDispatch('010C')
      ..noteResult('010C', ResponseClass.ok, rttMs: 40)
      ..noteConnectionEvent(attempt: true, success: true);
  }

  testWidgets('renders nothing when debugMode is OFF (defensive guard)',
      (tester) async {
    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: false),
    );

    expect(find.byKey(const Key('obd2_health_live_card')), findsNothing);
  });

  testWidgets('hosts the live card + copy affordance when debugMode is ON',
      (tester) async {
    seedLiveSession();

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    expect(find.text('OBD2 communication health'), findsWidgets);
    expect(find.byKey(const Key('obd2_health_live_card')), findsOneWidget);
    expect(find.byType(Obd2DiagnosticsCard), findsWidgets);
    expect(find.byKey(const Key('obd2_health_copy_live')), findsOneWidget);
  });

  testWidgets('renders a finished-session card after endSession',
      (tester) async {
    seedLiveSession();
    collector.endSession();

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    expect(
      find.byKey(const Key('obd2_health_finished_card_0')),
      findsOneWidget,
    );
  });

  testWidgets('Copy as JSON writes the session to the clipboard',
      (tester) async {
    seedLiveSession();

    // Intercept the clipboard channel so the copy is observable.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    await tester.tap(find.byKey(const Key('obd2_health_copy_live')));
    await tester.pumpAndSettle();

    expect(copied, isNotNull);
    // The compact JSON uses the model's short PID key.
    expect(copied, contains('"pid"'));
    expect(copied, contains('010C'));

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets(
      'init-only copy appears once a handshake is captured and exports just '
      'the handshake subset (#2511)', (tester) async {
    seedLiveSession();
    // Capture a handshake line so the init-transcript export is offered.
    collector.recordHandshakeLine('ATZ', 'ELM327 v1.5', 120);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    final initButton = find.byKey(const Key('obd2_health_copy_live_init'));
    expect(initButton, findsOneWidget);

    await tester.tap(initButton);
    await tester.pumpAndSettle();

    expect(copied, isNotNull);
    // Long human-readable keys for the focused subset, not the compact
    // session JSON — and it carries the captured handshake.
    expect(copied, contains('"initTranscript"'));
    expect(copied, contains('"elmVersion"'));
    expect(copied, contains('ATZ'));
    // It must NOT carry the full compact session payload — the per-PID
    // table ("pid") and connection block ("conn") short keys are absent.
    expect(copied, isNot(contains('"pid"')));
    expect(copied, isNot(contains('"conn"')));

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets('init-only copy is hidden when no handshake was captured',
      (tester) async {
    // Live session with a PID but no recorded handshake line.
    seedLiveSession();

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    expect(
      find.byKey(const Key('obd2_health_copy_live_init')),
      findsNothing,
    );
  });
}
