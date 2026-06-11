// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_connect_trace_card.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/obd2_health_screen.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../../helpers/pump_app.dart';

/// #2969 — the OBD2 health screen surfaces a FAILED connect (the literal
/// complaint) in a "Recent connect attempts" section that is NON-EMPTY even
/// when the comm-health session never began, plus a per-trace + all-traces
/// download via the same never-throws sink.
void main() {
  setUp(() {
    Obd2ConnectTraceLog.clear();
    Obd2ConnectTraceLog.onTraceAdded = null;
  });
  tearDown(() {
    Obd2ConnectTraceLog.clear();
    Obd2ConnectTraceLog.onTraceAdded = null;
    debugPublicFileExporterOverride = null;
  });

  List<Object> overrides() => [
        enabledFeaturesProvider.overrideWithValue({Feature.debugMode}),
        vehicleProfileListProvider.overrideWith(_NoVehicles.new),
        activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
      ];

  ({List<({String text, String fileName, String mimeType})> downloads})
      wireExport(WidgetTester tester) {
    final downloads = <({String text, String fileName, String mimeType})>[];
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      downloads
          .add((text: String.fromCharCodes(bytes), fileName: fileName, mimeType: mimeType));
      return '/Downloads/$fileName';
    };
    return (downloads: downloads);
  }

  /// Seed a FAILED connect trace directly into the log (modelling a connect
  /// that died before any session could begin).
  void seedFailedTrace({
    Obd2ConnectOutcome outcome = Obd2ConnectOutcome.gattTimeout,
  }) {
    final h = Obd2ConnectTraceLog.beginTrace(
      origin: Obd2ConnectOrigin.liveReconnect,
      mac: 'AA:BB:CC:DD:EE:FF',
      requestedTransport: Obd2ConnectTransport.ble,
    );
    h
      ..setResolvedTransport(Obd2ConnectTransport.ble)
      ..addStep(
          label: 'channel-open',
          status: Obd2ConnectStepStatus.fail,
          detail: 'Timed out after 4s')
      ..setOutcome(outcome, failureDetail: 'Timed out after 4s');
    Obd2ConnectTraceLog.endTrace(h);
  }

  testWidgets('renders the connect-attempts section empty placeholder',
      (tester) async {
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());
    expect(
      find.byKey(const Key('obd2_health_connect_attempts_section')),
      findsOneWidget,
    );
    expect(find.text('No connect attempts recorded yet.'), findsOneWidget);
  });

  testWidgets(
      'a FAILED connect trace renders a NON-EMPTY card + download button '
      '(#2969 — the literal complaint)', (tester) async {
    seedFailedTrace();
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());

    expect(find.byType(Obd2ConnectTraceCard), findsOneWidget);
    expect(find.byKey(const Key('obd2_health_connect_trace_card_0')),
        findsOneWidget);
    expect(find.byKey(const Key('obd2_health_download_connect_trace_0')),
        findsOneWidget);
    expect(find.byKey(const Key('obd2_health_download_all_connect_traces')),
        findsOneWidget);
    // The bold outcome is shown.
    expect(find.textContaining('gattTimeout'), findsOneWidget);
  });

  testWidgets(
      'staleness: a trace landing while the screen is OPEN appears WITHOUT '
      're-navigating (#2969)', (tester) async {
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());
    // Initially empty.
    expect(find.byType(Obd2ConnectTraceCard), findsNothing);

    // A live reconnect fails while the screen is open — the static log bumps
    // the revision provider, which rebuilds the screen.
    seedFailedTrace();
    await tester.pump();

    expect(find.byType(Obd2ConnectTraceCard), findsOneWidget);
  });

  testWidgets('Download connect trace writes non-empty JSON with the outcome',
      (tester) async {
    seedFailedTrace();
    final captured = wireExport(tester);
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());

    await tester
        .tap(find.byKey(const Key('obd2_health_download_connect_trace_0')));
    await tester.pumpAndSettle();

    expect(captured.downloads, hasLength(1));
    final dl = captured.downloads.single;
    expect(dl.mimeType, 'application/json');
    expect(dl.fileName, startsWith('tankstellen-obd2-connect-trace-'));
    // Non-empty payload carrying the outcome + steps.
    expect(dl.text, contains('"oc"'));
    expect(dl.text, contains('gattTimeout'));
    expect(dl.text, contains('"steps"'));
    expect(dl.text, contains('channel-open'));
  });

  testWidgets('Download ALL connect traces writes a JSON array', (tester) async {
    seedFailedTrace(outcome: Obd2ConnectOutcome.gatt133);
    seedFailedTrace(outcome: Obd2ConnectOutcome.rfcommOpenFail);
    final captured = wireExport(tester);
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());

    final allButton =
        find.byKey(const Key('obd2_health_download_all_connect_traces'));
    await tester.scrollUntilVisible(allButton, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(allButton);
    await tester.pumpAndSettle();

    expect(captured.downloads, hasLength(1));
    final dl = captured.downloads.single;
    expect(dl.fileName, startsWith('tankstellen-obd2-connect-traces-'));
    expect(dl.text, startsWith('['));
    expect(dl.text, contains('gatt133'));
    expect(dl.text, contains('rfcommOpenFail'));
  });
}

class _NoVehicles extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}
