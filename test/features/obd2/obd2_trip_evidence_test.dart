// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3824 — the trip-detail OBD2 card told a driver "No OBD2 session recorded —
// connect an adapter and record a trip with developer mode enabled" about a
// trip that had recorded 324 engine samples at 99.7% coverage over a named
// adapter, with fuel MEASURED rather than GPS-estimated.
//
// The numbers below are the real ones from driving-20260826T191343, so this
// fails against the old behaviour rather than against a hypothetical.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_session_diagnostic.dart';
import 'package:tankstellen/features/obd2/data/obd2_trip_evidence.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_diagnostics_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// The field trip that exposed the bug.
const fieldTrip = Obd2TripEvidence(
  engineSamples: 324,
  totalSamples: 325,
  coverageShare: 0.997,
  adapterName: 'vLinker FS 14884',
  adapterMac: 'D4:E9:5E:A8:CD:7E',
  protocolVerdict: 'answered',
  terminationReason: 'userStopped',
  duration: Duration(minutes: 5, seconds: 24),
  fuelMeasured: true,
);

Future<void> _pump(WidgetTester tester, Obd2TripEvidence? evidence) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        children: [
          // An empty diagnostic is exactly the state the field trip was in:
          // no per-PID instrumentation was captured for it.
          Obd2DiagnosticsCard(
            session: const Obd2SessionDiagnostic(),
            tripEvidence: evidence,
          ),
        ],
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Obd2TripEvidence (#3824)', () {
    test('one engine sample is enough to prove a session happened', () {
      expect(fieldTrip.hasObd2, isTrue);
      expect(fieldTrip.coveragePercent, 100); // 0.997 rounds to 100
    });

    test('a connected adapter that delivered NOTHING is not evidence', () {
      // The genuine "connected but silent ECU" case. The original empty
      // state describes this correctly, so it must keep showing.
      const silent = Obd2TripEvidence(
        engineSamples: 0,
        totalSamples: 325,
        coverageShare: 0,
        adapterName: 'vLinker FS 14884',
      );
      expect(silent.hasObd2, isFalse,
          reason: 'an adapter name alone must never be read as a working '
              'session — that would replace one false claim with another');
    });

    test('the MAC is redacted, never shown in full', () {
      expect(fieldTrip.redactedMac, '…CD7E');
      expect(fieldTrip.adapterLabel, 'vLinker FS 14884 (…CD7E)');
      expect(fieldTrip.adapterLabel, isNot(contains('D4:E9')));
    });

    test('adapter label degrades to whichever half was recorded', () {
      expect(
        const Obd2TripEvidence(
                engineSamples: 1, totalSamples: 1, coverageShare: 1,
                adapterMac: 'AA:BB:CC:DD:EE:FF')
            .adapterLabel,
        '…EEFF',
      );
      expect(
        const Obd2TripEvidence(
                engineSamples: 1, totalSamples: 1, coverageShare: 1)
            .adapterLabel,
        isNull,
      );
    });
  });

  group('card renders the truth (#3824)', () {
    testWidgets('a real session is NOT reported as "no session recorded"',
        (tester) async {
      await _pump(tester, fieldTrip);

      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsNothing,
          reason: 'this is the exact false claim the driver was shown');
      expect(
          find.byKey(const Key('obd2_diagnostics_trip_evidence')), findsOneWidget);
    });

    testWidgets('it states what the trip actually recorded', (tester) async {
      await _pump(tester, fieldTrip);
      await tester.tap(find.byKey(const Key('obd2_diagnostics_trip_evidence')));
      await tester.pumpAndSettle();

      for (final key in [
        'obd2_diag_trip_samples_line',
        'obd2_diag_trip_adapter_line',
        'obd2_diag_trip_protocol_line',
        'obd2_diag_trip_duration_line',
        'obd2_diag_trip_ended_line',
        'obd2_diag_trip_fuel_measured',
        // The honest replacement for the old blanket denial: only the
        // per-PID breakdown is missing, and that is what it says.
        'obd2_diag_trip_no_pid_detail',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: 'missing $key');
      }

      expect(find.textContaining('324'), findsWidgets);
      expect(find.textContaining('vLinker FS 14884'), findsWidgets);
      expect(find.textContaining('answered'), findsWidgets);
    });

    testWidgets('a trip with no OBD2 at all still shows the empty state',
        (tester) async {
      await _pump(
        tester,
        const Obd2TripEvidence(
            engineSamples: 0, totalSamples: 120, coverageShare: 0),
      );
      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsOneWidget);
      expect(find.byKey(const Key('obd2_diagnostics_trip_evidence')),
          findsNothing);
    });

    testWidgets('no evidence at all behaves exactly as before', (tester) async {
      await _pump(tester, null);
      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsOneWidget);
    });
  });
}
