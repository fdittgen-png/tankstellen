// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';

/// #3856 (Epic #3855) — the fused vehicle power state.
///
/// The user's report, verbatim: OBD2 is reliable when the engine is on
/// from the beginning to the end; engine off at the start and/or the
/// end creates errors. These tests pin the evidence ladder that every
/// engine-off path now keys on, and — just as important — that with no
/// evidence the state is `unknown`, so every consumer behaves exactly
/// as it did before this epic.
void main() {
  late DateTime now;
  late Obd2VehiclePower power;

  setUp(() {
    now = DateTime(2026, 8, 29, 8);
    power = Obd2VehiclePower(now: () => now);
  });

  group('no evidence is the reliability floor', () {
    test('a fresh model is unknown, not asleep', () {
      expect(power.state, VehiclePowerState.unknown);
      expect(power.asleep, isFalse);
      expect(power.engineRunning, isFalse);
      expect(power.decidingSource, isNull);
    });
  });

  group('rpm is authoritative', () {
    test('rpm > 0 is engineRunning', () {
      power.noteRpm(850);
      expect(power.state, VehiclePowerState.engineRunning);
      expect(power.decidingSource, VehiclePowerSource.rpm);
    });

    test('rpm == 0 is ecuAwake — ignition on, engine off', () {
      power.noteRpm(0);
      expect(power.state, VehiclePowerState.ecuAwake);
    });

    test('a stop-start pause (rpm 0 after running) reads awake, not asleep',
        () {
      power.noteRpm(900);
      now = now.add(const Duration(seconds: 25)); // running stamp expired
      power.noteRpm(0);
      expect(power.state, VehiclePowerState.ecuAwake);
    });

    test('rpm evidence decays: running → awake (the parse still proves an '
        'awake ECU) → unknown', () {
      power.noteRpm(900);
      now = now.add(const Duration(seconds: 21));
      expect(power.state, VehiclePowerState.ecuAwake,
          reason: 'the running stamp expired but the bus answered 21 s ago');
      now = now.add(const Duration(seconds: 10));
      expect(power.state, VehiclePowerState.unknown);
    });
  });

  group('ATRV voltage — the signal that needs no bus traffic (#3857)', () {
    test('alternator voltage alone proves the engine runs', () {
      power.noteVoltage(14.1);
      expect(power.state, VehiclePowerState.engineRunning);
      expect(power.decidingSource, VehiclePowerSource.voltage);
      expect(power.alternatorOn, isTrue);
    });

    test('hysteresis: 13.0 V after 14 V is still on, 12.7 V is off', () {
      power.noteVoltage(14.1);
      power.noteVoltage(13.0);
      expect(power.alternatorOn, isTrue,
          reason: 'between the thresholds the previous verdict holds');
      power.noteVoltage(12.7);
      expect(power.alternatorOn, isFalse);
    });

    test('hysteresis: 13.0 V from cold is NOT on', () {
      power.noteVoltage(13.0);
      expect(power.alternatorOn, isFalse,
          reason: 'a tired battery on charge must not flap the verdict');
    });

    test('low voltage with a silent bus is asleep', () {
      power.noteVoltage(12.4);
      power.noteBusSilent();
      expect(power.state, VehiclePowerState.asleep);
    });

    test('low voltage and no bus evidence at all is asleep', () {
      // The adapter answers AT commands; the ECU never answered anything.
      power.noteVoltage(12.5);
      expect(power.state, VehiclePowerState.asleep);
    });

    test('silent bus + alternator voltage is the livelock, NOT asleep '
        '(#3780)', () {
      power.noteBusSilent();
      power.noteVoltage(14.0);
      expect(power.state, VehiclePowerState.engineRunning,
          reason: 'UNABLE TO CONNECT with the alternator charging is a '
              'failed protocol search with the engine running — parking '
              'here is the mid-drive catastrophe');
    });
  });

  group('bus probe', () {
    test('an answered bus is at least awake', () {
      power.noteBusAnswered();
      expect(power.state, VehiclePowerState.ecuAwake);
    });

    test('a silent bus with no voltage reading is asleep', () {
      power.noteBusSilent();
      expect(power.state, VehiclePowerState.asleep);
    });

    test('rpm outranks a stale silent-bus stamp', () {
      power.noteBusSilent();
      power.noteRpm(1200);
      expect(power.state, VehiclePowerState.engineRunning);
    });
  });

  group('hints that are not readings', () {
    test('an ACL engine-start hint sets the expectation, not the state', () {
      power.noteAclHint();
      expect(power.state, VehiclePowerState.unknown);
      expect(power.engineStartExpected, isTrue);
    });

    test('an ACL hint contradicted by a low-voltage silent bus expects '
        'nothing', () {
      power.noteAclHint();
      power.noteVoltage(12.3);
      power.noteBusSilent();
      expect(power.engineStartExpected, isFalse);
    });

    test('motion without engine evidence is a tow, never running', () {
      power.noteMotion();
      expect(power.state, VehiclePowerState.unknown);
      expect(power.movingWithoutEngine, isTrue);
    });
  });

  group('EVs and hybrids', () {
    test('rpm is ignored in EV mode', () {
      power.evMode = true;
      power.noteRpm(0);
      // noteRpm still counts as a bus answer.
      expect(power.state, VehiclePowerState.ecuAwake);
      power.noteRpm(3000);
      expect(power.state, VehiclePowerState.ecuAwake,
          reason: 'an EV has no rpm to trust');
    });

    test('READY and moving reads as running', () {
      power.evMode = true;
      power.noteBusAnswered();
      power.noteMotion();
      expect(power.state, VehiclePowerState.engineRunning);
    });

    test('DC-DC voltage in READY reads as running', () {
      power.evMode = true;
      power.noteVoltage(14.3);
      expect(power.state, VehiclePowerState.engineRunning);
    });
  });

  group('transitions are published once per change', () {
    test('states emits on change only', () async {
      final seen = <VehiclePowerState>[];
      final sub = power.states.listen(seen.add);
      power.noteVoltage(12.4);
      power.noteBusSilent();
      power.noteBusSilent(); // no change
      power.noteRpm(900);
      await Future<void>.delayed(Duration.zero);
      expect(seen, [
        VehiclePowerState.asleep,
        VehiclePowerState.engineRunning,
      ]);
      await sub.cancel();
    });

    test('tick publishes evidence decay', () async {
      final seen = <VehiclePowerState>[];
      final sub = power.states.listen(seen.add);
      power.noteRpm(900);
      now = now.add(const Duration(seconds: 30));
      power.tick();
      await Future<void>.delayed(Duration.zero);
      expect(seen, [
        VehiclePowerState.engineRunning,
        VehiclePowerState.unknown,
      ]);
      await sub.cancel();
    });
  });

  test('detail names the state, the source and the voltage', () {
    power.noteVoltage(14.2);
    expect(power.detail, 'engineRunning via voltage 14.2V');
  });
}
