// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_response_class.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_diagnostics_card.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/obd2_health_screen.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../../helpers/pump_app.dart';

/// Structural coverage for the OBD2 communication-health dev-tools screen
/// (#2471, Epic #2463). No goldens — find-by-key / find-by-text only.
void main() {
  final collector = Obd2CommDiagnostics.instance;

  setUp(() => collector
    ..reset()
    ..enabled = false);
  tearDown(() {
    collector
      ..reset()
      ..enabled = false;
    debugPublicFileExporterOverride = null;
  });

  /// Capture the download via the public-file-exporter test seam + intercept
  /// the clipboard channel so a test can assert the export goes to a FILE,
  /// not the clipboard (#2938). Returns a getter for each captured value.
  ({
    List<({String text, String fileName, String mimeType})> downloads,
    List<String?> clipboard,
  }) wireExportCapture(WidgetTester tester) {
    final downloads = <({String text, String fileName, String mimeType})>[];
    final clipboard = <String?>[];
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      downloads.add((
        text: String.fromCharCodes(bytes),
        fileName: fileName,
        mimeType: mimeType,
      ));
      return '/Downloads/$fileName';
    };
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String?);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    return (downloads: downloads, clipboard: clipboard);
  }

  List<Object> overrides({required bool debugOn}) => [
        enabledFeaturesProvider.overrideWithValue(
          debugOn ? {Feature.debugMode} : <Feature>{},
        ),
        // The self-test panel reads the vehicle list/active vehicle for its
        // adapter choice (#2938); stub them so no Hive box is needed.
        vehicleProfileListProvider.overrideWith(_NoVehicles.new),
        activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
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

  testWidgets(
      'Download as JSON writes the session to Downloads, NOT the clipboard '
      '(#2938)', (tester) async {
    seedLiveSession();
    final captured = wireExportCapture(tester);

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    await tester.tap(find.byKey(const Key('obd2_health_copy_live')));
    await tester.pumpAndSettle();

    // The export went to a FILE via saveTextToDownloads, not the clipboard.
    expect(captured.clipboard, isEmpty);
    expect(captured.downloads, hasLength(1));
    final dl = captured.downloads.single;
    expect(dl.mimeType, 'application/json');
    expect(dl.fileName, endsWith('.json'));
    expect(dl.fileName, startsWith('tankstellen-obd2-session-'));
    // The compact JSON uses the model's short PID key.
    expect(dl.text, contains('"pid"'));
    expect(dl.text, contains('010C'));
    // The success snackbar surfaced the Downloads-folder confirmation.
    expect(find.text('Saved to your Downloads folder'), findsOneWidget);
  });

  testWidgets(
      'init-only download appears once a handshake is captured and exports '
      'just the handshake subset to Downloads (#2511/#2938)', (tester) async {
    seedLiveSession();
    // Capture a handshake line so the init-transcript export is offered.
    collector.recordHandshakeLine('ATZ', 'ELM327 v1.5', 120);
    final captured = wireExportCapture(tester);

    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(debugOn: true),
    );

    final initButton = find.byKey(const Key('obd2_health_copy_live_init'));
    expect(initButton, findsOneWidget);

    await tester.tap(initButton);
    await tester.pumpAndSettle();

    // Went to a file, not the clipboard, with the init-tagged filename.
    expect(captured.clipboard, isEmpty);
    expect(captured.downloads, hasLength(1));
    final dl = captured.downloads.single;
    expect(dl.fileName, startsWith('tankstellen-obd2-init-'));
    // Long human-readable keys for the focused subset, not the compact
    // session JSON — and it carries the captured handshake.
    expect(dl.text, contains('"initTranscript"'));
    expect(dl.text, contains('"elmVersion"'));
    expect(dl.text, contains('ATZ'));
    // It must NOT carry the full compact session payload — the per-PID
    // table ("pid") and connection block ("conn") short keys are absent.
    expect(dl.text, isNot(contains('"pid"')));
    expect(dl.text, isNot(contains('"conn"')));
  });

  testWidgets('init-only download is hidden when no handshake was captured',
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

/// No stored vehicle profiles — the self-test panel hides the adapter choice
/// and the run takes the legacy scan path.
class _NoVehicles extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}
