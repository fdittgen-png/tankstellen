// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/elm327_precision_pids.dart';
import 'package:tankstellen/features/obd2/data/protocol/obd2_signal_pids.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_signal_support.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_signal.dart';

/// #4159 — the adapter's signal table. Every signal's request is the Mode
/// 01 spelling of its PID, no two signals share a PID, the strict set is
/// exactly the Epic #3416 precision families, and `supports` asks exactly
/// one question of the matching kind.

String _hex(int pid) => pid.toRadixString(16).toUpperCase().padLeft(2, '0');

class _Reads implements Obd2PidSupport {
  final List<String> asked = <String>[];

  @override
  bool isPidSupported(int pid) {
    asked.add('opt:${_hex(pid)}');
    return true;
  }

  @override
  bool isPidKnownSupported(int pid) {
    asked.add('strict:${_hex(pid)}');
    return false;
  }
}

void main() {
  test('every command is the Mode 01 request for its PID', () {
    for (final signal in VehicleSignal.values) {
      expect(
        Obd2SignalPids.commandOf(signal),
        '01${_hex(Obd2SignalPids.pidOf(signal))}\r',
        reason: signal.name,
      );
    }
  });

  test('no two signals share a PID', () {
    final pids = [for (final s in VehicleSignal.values) Obd2SignalPids.pidOf(s)];
    expect(pids.toSet(), hasLength(pids.length));
  });

  test('the strict gate is exactly the precision families', () {
    expect(
      {
        for (final s in VehicleSignal.values)
          if (Obd2SignalPids.gateOf(s) == SignalGate.strict) s,
      },
      {
        VehicleSignal.mafDual,
        VehicleSignal.fuelMassRate,
        VehicleSignal.cylinderFuelRate,
        VehicleSignal.ethanolPercent,
        VehicleSignal.widebandPhi,
      },
    );
  });

  test('wideband: sensor 1 of each family leads, voltage family first', () {
    expect(Elm327PrecisionPids.primaryWidebandPids, [
      Elm327PrecisionPids.widebandVoltagePids.first,
      Elm327PrecisionPids.widebandCurrentPids.first,
    ]);
    expect(Obd2SignalPids.pidOf(VehicleSignal.widebandPhi),
        Elm327PrecisionPids.primaryWidebandPids.first);
  });

  test('supports() asks one question, of the gate kind, for the PID', () {
    for (final signal in VehicleSignal.values) {
      final reads = _Reads();
      final answer = reads.supports(signal);
      final strict = Obd2SignalPids.gateOf(signal) == SignalGate.strict;
      final pid = _hex(Obd2SignalPids.pidOf(signal));
      expect(reads.asked, [strict ? 'strict:$pid' : 'opt:$pid'],
          reason: signal.name);
      expect(answer, !strict, reason: signal.name);
    }
  });

  test('units', () {
    expect(
      {for (final s in VehicleSignal.values) s.name: s.unit},
      {
        'engineRpm': SignalUnit.rpm,
        'vehicleSpeed': SignalUnit.kmh,
        'throttle': SignalUnit.percent,
        'pedalD': SignalUnit.percent,
        'pedalE': SignalUnit.percent,
        'pedalF': SignalUnit.percent,
        'fuelRate': SignalUnit.litresPerHour,
        'maf': SignalUnit.gramsPerSecond,
        'mafDual': SignalUnit.gramsPerSecond,
        'fuelMassRate': SignalUnit.gramsPerSecond,
        'cylinderFuelRate': SignalUnit.mgPerStroke,
        'manifoldPressure': SignalUnit.kPa,
        'commandedPhi': SignalUnit.equivalenceRatio,
        'engineLoad': SignalUnit.percent,
        'absoluteLoad': SignalUnit.percent,
        'widebandPhi': SignalUnit.equivalenceRatio,
        'stftBank1': SignalUnit.percent,
        'ltftBank1': SignalUnit.percent,
        'stftBank2': SignalUnit.percent,
        'ltftBank2': SignalUnit.percent,
        'intakeAirTemp': SignalUnit.celsius,
        'timingAdvance': SignalUnit.degreesBtdc,
        'baroPressure': SignalUnit.kPa,
        'ethanolPercent': SignalUnit.percent,
        'coolantTemp': SignalUnit.celsius,
        'fuelTankLevel': SignalUnit.percent,
        'oilTemp': SignalUnit.celsius,
        'ambientAirTemp': SignalUnit.celsius,
      },
    );
  });
}
