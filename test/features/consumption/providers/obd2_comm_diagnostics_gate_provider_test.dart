// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/providers/obd2_comm_diagnostics_gate_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

void main() {
  setUp(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  ProviderContainer containerWith(Set<Feature> enabled) {
    final c = ProviderContainer(overrides: [
      enabledFeaturesProvider.overrideWithValue(enabled),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('obd2CommDiagnosticsGate (#2465)', () {
    test('arms the collector when Feature.debugMode is enabled', () {
      final c = containerWith({Feature.debugMode});
      expect(c.read(obd2CommDiagnosticsGateProvider), isTrue);
      expect(Obd2CommDiagnostics.instance.enabled, isTrue);
    });

    test('leaves the collector disarmed (no-op) when debugMode is off', () {
      final c = containerWith(<Feature>{});
      expect(c.read(obd2CommDiagnosticsGateProvider), isFalse);
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);
    });

    test('closing the gate resets any retained session ring', () {
      // Arm + accumulate a finished session.
      Obd2CommDiagnostics.instance.enabled = true;
      Obd2CommDiagnostics.instance.beginSession(linkKind: 'ble');
      Obd2CommDiagnostics.instance.endSession();
      expect(Obd2CommDiagnostics.instance.finishedSessions, isNotEmpty);

      // Reading the gate with debugMode off disarms AND clears.
      final c = containerWith(<Feature>{});
      expect(c.read(obd2CommDiagnosticsGateProvider), isFalse);
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);
      expect(Obd2CommDiagnostics.instance.finishedSessions, isEmpty);
    });
  });
}
