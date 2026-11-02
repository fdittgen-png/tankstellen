// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/diagnostics/diagnostic_health_plan.dart';

/// #4549 — the continuous health plan and its stated frequencies.
void main() {
  Map<String, double> rates(List<DiagnosticHealthCommand> plan) => {
    for (final c in plan) c.command: c.hz,
  };

  test('the named health set carries the #4549 rates', () {
    final r = rates(buildDiagnosticHealthPlan(alreadyPolled: const {}));
    expect(r['0142'], 2); // control-module voltage
    expect(r['01A4'], 2); // gear
    for (final command in [
      '0106',
      '0107',
      '0108',
      '0109',
      '010A',
      '010E',
      '010F',
      '0110',
    ]) {
      expect(r[command], 0.5, reason: command);
    }
    expect(r['0103'], 0.5); // fuel-system status
    expect(r['0114'], 0.5); // O2 narrowband
    expect(r['0132'], 0.5); // EVAP vapour pressure
    expect(r['0101'], 0.2); // MIL / DTC count
    expect(r['013C'], 0.2); // catalyst temperature
    expect(r['03'], closeTo(1 / 30, 1e-9)); // stored DTCs every 30 s
    expect(r['07'], closeTo(1 / 30, 1e-9)); // pending DTCs every 30 s
    expect(
      DiagnosticHealthRates.batteryVoltageInterval,
      const Duration(seconds: 1),
    );
  });

  test('already-polled commands are never subscribed twice', () {
    final r = rates(
      buildDiagnosticHealthPlan(alreadyPolled: const {'0142', '010C', '03'}),
    );
    expect(r.containsKey('0142'), isFalse);
    expect(r.containsKey('03'), isFalse);
    expect(r.containsKey('01A4'), isTrue);
  });

  test('other PIDs only when the bitmap advertises them, never the '
      'bitmap PIDs themselves', () {
    final none = rates(buildDiagnosticHealthPlan(alreadyPolled: const {}));
    expect(none.containsKey('015E'), isFalse);
    final advertised = {0x0C, 0x20, 0x5E, 0x62};
    final r = rates(
      buildDiagnosticHealthPlan(
        alreadyPolled: const {'010C'},
        advertised: advertised.contains,
      ),
    );
    expect(r['015E'], DiagnosticHealthRates.slow);
    expect(r['0162'], DiagnosticHealthRates.slow);
    expect(r.containsKey('0120'), isFalse);
    expect(r.containsKey('010C'), isFalse);
  });

  test('mode01Command pads and upper-cases', () {
    expect(mode01Command(0x42), '0142');
    expect(mode01Command(0x0a), '010A');
  });
}
