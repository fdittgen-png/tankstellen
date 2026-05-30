// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_diagnostics_summary.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_completeness.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_diagnostic.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_diagnostics_card.dart';

import '../../../../helpers/pump_app.dart';

/// Structural coverage for the OBD2 communication-health diagnostics card
/// (#2470, Epic #2463). No macOS goldens — pure find-by-key / find-by-text
/// assertions against a seeded [Obd2SessionDiagnostic].
void main() {
  // A richly-seeded session: two PIDs (one healthy, one mostly-failing),
  // a connection lifecycle with a drop + reconnects, scheduler counters,
  // a tri-state spread, and a fuel-downgrade rollup. Run through the
  // completeness summariser so the per-tier rollup is filled.
  Obd2SessionDiagnostic seededSession() {
    const raw = Obd2SessionDiagnostic(
      linkKind: 'ble',
      redactedMac: '···············E:FF',
      elmVersion: 'ELM327 v1.5',
      protocolDigit: '6',
      mtu: 247,
      warmStart: false,
      capabilityTier: 'standardOnly',
      sessionActiveSeconds: 100,
      pidStats: {
        // Healthy dynamics PID: 1 Hz target, fully achieved.
        '010C': Obd2PidStat(
          polled: 100,
          ok: 100,
          latencyP50Ms: 40,
          latencyP95Ms: 90,
          targetHz: 1.0,
          tier: 'dynamics',
        ),
        // Flaky thermal PID: mostly timeouts + errors.
        '0105': Obd2PidStat(
          polled: 50,
          ok: 5,
          noData: 10,
          timeout: 25,
          error: 10,
          latencyP50Ms: 800,
          latencyP95Ms: 2000,
          targetHz: 0.5,
          tier: 'thermalContext',
        ),
      },
      connection: Obd2ConnectionStats(
        attempts: 3,
        successes: 2,
        drops: 1,
        silentReconnects: 1,
        visibleReconnects: 1,
        timeToConnectP50Ms: 1200,
        timeToConnectP95Ms: 3400,
      ),
      scheduler: Obd2SchedulerStats(
        tickRateHz: 4.2,
        backpressureSkips: 7,
        demotions: 2,
        starved: true,
      ),
      framing: Obd2FramingStats(garbageReads: 3),
      fuelTierTicks: {'pid5E': 90, 'maf': 10},
      fuelDowngrade: Obd2FuelDowngradeStats(
        totalSamples: 100,
        suspiciousSamples: 12,
      ),
      discoveredSupported: {
        '010C': 'supported',
        '0105': 'supported',
        '015E': 'unsupported',
        '0142': 'unknown',
      },
    );
    return summariseObd2Completeness(raw);
  }

  group('computeObd2DiagnosticsSummary', () {
    test('empty const-default session is not presentable', () {
      expect(
        computeObd2DiagnosticsSummary(const Obd2SessionDiagnostic()),
        equals(Obd2DiagnosticsSummary.empty),
      );
    });

    test('seeded session rolls up tri-state, drops, top-failing PID', () {
      final summary = computeObd2DiagnosticsSummary(seededSession());

      expect(summary.presentable, isTrue);
      expect(summary.drops, 1);
      // 010C: 100 ok / (1.0*100=100 expected); 0105: 5/(0.5*100=50).
      // Overall = 105 / 150 = 70%.
      expect(summary.completenessPercent, 70);
      expect(summary.supportedCount, 2);
      expect(summary.unsupportedCount, 1);
      expect(summary.unknownCount, 1);
      // The flaky PID has the highest error+timeout weight.
      expect(summary.topFailingPid, '0105');
      // Worst-first ordering: 0105 (35 failures) before 010C (0).
      expect(summary.pidRows.first.pid, '0105');
      expect(summary.pidRows.last.pid, '010C');
    });

    test('per-tier completeness is rounded + present', () {
      final summary = computeObd2DiagnosticsSummary(seededSession());
      expect(summary.perTierPercent['dynamics'], 100);
      expect(summary.perTierPercent['thermalContext'], 10);
    });
  });

  group('Obd2DiagnosticsCard — empty / disabled', () {
    testWidgets('renders empty state when disabled', (tester) async {
      await pumpApp(
        tester,
        Obd2DiagnosticsCard(session: seededSession(), enabled: false),
      );

      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsOneWidget);
      expect(find.byKey(const Key('obd2_diagnostics_tile')), findsNothing);
    });

    testWidgets('renders empty state for an empty session', (tester) async {
      await pumpApp(
        tester,
        const Obd2DiagnosticsCard(session: Obd2SessionDiagnostic()),
      );

      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsOneWidget);
    });
  });

  group('Obd2DiagnosticsCard — populated', () {
    testWidgets('collapsed header shows completeness · duty · drops',
        (tester) async {
      await pumpApp(tester, Obd2DiagnosticsCard(session: seededSession()));

      expect(find.byKey(const Key('obd2_diagnostics_tile')), findsOneWidget);
      expect(find.text('OBD2 communication health'), findsOneWidget);
      expect(find.textContaining('70% complete'), findsOneWidget);
      expect(find.textContaining('1 drop'), findsOneWidget);
      // Body is collapsed by default — section detail is not built yet.
      expect(find.byKey(const Key('obd2_diag_pid_0105')), findsNothing);
    });

    testWidgets('expanded body renders every section', (tester) async {
      // The card is designed to live inside a scroll view (trip detail /
      // the dev-tools screen ListView); wrap it so the full expanded body
      // does not overflow the fixed test viewport.
      await pumpApp(
        tester,
        ListView(children: [Obd2DiagnosticsCard(session: seededSession())]),
      );

      await tester.tap(find.byKey(const Key('obd2_diagnostics_tile')));
      await tester.pumpAndSettle();

      // Adapter identity (redacted MAC + firmware + protocol + MTU).
      expect(find.byKey(const Key('obd2_diag_adapter_line')), findsOneWidget);
      expect(find.textContaining('ELM327 v1.5'), findsOneWidget);
      expect(find.textContaining('E:FF'), findsOneWidget);
      // Connection lifecycle.
      expect(
        find.byKey(const Key('obd2_diag_connection_line')),
        findsOneWidget,
      );
      // Per-PID rows (both seeded PIDs).
      expect(find.byKey(const Key('obd2_diag_pid_0105')), findsOneWidget);
      expect(find.byKey(const Key('obd2_diag_pid_010C')), findsOneWidget);
      // Scheduler + starvation warning.
      expect(find.byKey(const Key('obd2_diag_scheduler_line')), findsOneWidget);
      expect(find.byKey(const Key('obd2_diag_starved')), findsOneWidget);
      // Completeness overall + per-tier rows.
      expect(
        find.byKey(const Key('obd2_diag_completeness_line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('obd2_diag_tier_dynamics')),
        findsOneWidget,
      );
      // Discovered-supported tri-state.
      expect(find.byKey(const Key('obd2_diag_support_line')), findsOneWidget);
      expect(find.textContaining('2 supported'), findsOneWidget);
      // Fuel-tier rollup.
      expect(find.byKey(const Key('obd2_diag_fuel_line')), findsOneWidget);
      expect(find.textContaining('Suspicious 12 of 100'), findsOneWidget);
    });
  });
}
