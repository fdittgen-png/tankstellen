// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/presentation/screens/obd2_diagnostic_report_screen.dart';
import 'package:tankstellen/features/obd2/providers/obd2_full_diagnostic_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #4552 — the report puts the worst system first and explains each
/// verdict in a sentence.
void main() {
  final recording = Obd2DiagnosticRecording(
    file: File('/nowhere/obd2-diagnostic-20261031T080000Z.ndjson'),
    startedAt: DateTime.utc(2026, 10, 31, 8),
    sizeBytes: 1,
  );

  const report = DiagnosticReport(
    duration: Duration(minutes: 42),
    readings: 18400,
    distinctValues: 37,
    electrical: ElectricalHealth(
      verdict: HealthVerdict.problem,
      runningAvgV: 13.9,
      runningMinV: 11.4,
      runningMaxV: 14.2,
      dipCount: 3,
    ),
    transmission: TransmissionHealth(
      verdict: HealthVerdict.check,
      gearReported: false,
      episodes: [
        DriveEpisode(
          at: Duration(minutes: 3, seconds: 12),
          duration: Duration(seconds: 2),
          speedKmh: 14,
          rpm: 780,
          voltageV: 11.6,
        ),
      ],
    ),
    engine: EngineHealth(verdict: HealthVerdict.good, coolantMaxC: 92),
    mixture: MixtureHealth(verdict: HealthVerdict.check, avgTrimPct: -14),
    emissions: EmissionsHealth(verdict: HealthVerdict.notReported),
    faults: FaultCodeHealth(
      verdict: HealthVerdict.problem,
      milOn: true,
      stored: ['P0730'],
    ),
    unanswered: ['01A4'],
  );

  Future<void> pump(WidgetTester tester) => pumpApp(
        tester,
        Obd2DiagnosticReportScreen(recording: recording),
        overrides: [
          obd2DiagnosticReportProvider(recording.file.path)
              .overrideWith((ref) async => report),
        ],
      );

  testWidgets('cards are ordered worst-first with readable sentences',
      (tester) async {
    // A 320 dp phone, tall enough that every card is laid out.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 5000);
    addTearDown(tester.view.reset);
    await pump(tester);
    await tester.pumpAndSettle();

    final electrical = tester.getTopLeft(find.byKey(const Key('obd2ReportElectrical'))).dy;
    final faults = tester.getTopLeft(find.byKey(const Key('obd2ReportFaults'))).dy;
    final drive = tester.getTopLeft(find.byKey(const Key('obd2ReportDrive'))).dy;
    final engine = tester.getTopLeft(find.byKey(const Key('obd2ReportEngine'))).dy;
    final emissions = tester.getTopLeft(find.byKey(const Key('obd2ReportEmissions'))).dy;
    expect(electrical, lessThan(drive)); // problem before check
    expect(faults, lessThan(drive));
    expect(drive, lessThan(engine)); // check before good
    expect(engine, lessThan(emissions)); // good before not reported

    expect(find.textContaining('42 min recorded'), findsOneWidget);
    expect(find.textContaining('dropped below 12 V 3 times'), findsOneWidget);
    expect(find.textContaining('1 moments where power did not reach'), findsOneWidget);
    expect(find.textContaining('03:12'), findsOneWidget);
    expect(find.textContaining('does not establish that the final mixture remains rich'), findsOneWidget);
    expect(find.textContaining('P0730 · transmission'), findsOneWidget);
    expect(find.textContaining('do not assess a robotized gearbox'), findsOneWidget);
    expect(find.textContaining('No usable gear reading was recorded'), findsOneWidget);
    expect(find.text('The engine warning light is ON.'), findsOneWidget);
    expect(find.textContaining('01A4'), findsOneWidget);
  });

  testWidgets('a broken recording says so instead of spinning', (tester) async {
    await pumpApp(
      tester,
      Obd2DiagnosticReportScreen(recording: recording),
      overrides: [
        obd2DiagnosticReportProvider(recording.file.path)
            .overrideWith((ref) async => throw const FileSystemException('x')),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not read this recording'), findsOneWidget);
  });
}
