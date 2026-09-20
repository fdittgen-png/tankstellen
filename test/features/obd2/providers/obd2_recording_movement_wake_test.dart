// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';
import 'package:tankstellen/features/obd2/providers/obd2_recording_movement_wake.dart';

/// #4383 (Epic #4195) — the OBD2 recording's own movement evidence.
///
/// The collaborator itself: the throttle it inherits from
/// `GpsMovementWakeNudge`, the motion rung it stamps on every sustained
/// sample, and the never-throws contract of its production factory (a
/// wake must never take the recording path down).
void main() {
  late DateTime clock;
  DateTime now() => clock;

  setUp(() => clock = DateTime(2026, 9, 18, 8));

  test('sustained road speed nudges the owner once, then throttles', () {
    var wakes = 0;
    final power = Obd2VehiclePower(now: now);
    final wake = Obd2RecordingMovementWake(
      wake: () => wakes++,
      power: power,
      now: now,
    );

    for (var i = 0; i < 4; i++) {
      wake.onSpeed(95);
    }
    expect(wakes, 0, reason: 'four samples are not sustained movement');

    wake.onSpeed(95);
    expect(wakes, 1);
    expect(power.movingWithoutEngine, isTrue,
        reason: 'noteMotion() is stamped with the nudge');

    clock = clock.add(const Duration(seconds: 119));
    wake.onSpeed(95);
    expect(wakes, 1, reason: 'inside the 2 min interval — throttled');

    clock = clock.add(const Duration(seconds: 2));
    wake.onSpeed(95);
    expect(wakes, 2, reason: 'the interval elapsed — one more nudge');
  });

  test('the motion rung stays fresh between throttled nudges', () {
    final power = Obd2VehiclePower(now: now);
    final wake = Obd2RecordingMovementWake(
      wake: () {},
      power: power,
      now: now,
    );
    for (var i = 0; i < 5; i++) {
      wake.onSpeed(95);
    }
    // The power model's motion window is 30 s — shorter than the 2 min
    // nudge interval, so it must be re-stamped by every sample inside a
    // sustained window, not only by the throttled wake.
    clock = clock.add(const Duration(seconds: 29));
    wake.onSpeed(95);
    clock = clock.add(const Duration(seconds: 29));
    wake.onSpeed(95);
    expect(power.movingWithoutEngine, isTrue,
        reason: 'motion stays fresh across a whole drive, not 30 s of it');
  });

  test('a standstill breaks the run; a null reading is ignored', () {
    var wakes = 0;
    final wake = Obd2RecordingMovementWake(
      wake: () => wakes++,
      power: Obd2VehiclePower(now: now),
      now: now,
    );
    for (var i = 0; i < 4; i++) {
      wake.onSpeed(95);
    }
    wake.onSpeed(0);
    // A null reading (no speed PID, no GPS latch yet) must not reset the
    // run NOR count towards it — it is simply not a sample.
    for (var i = 0; i < 4; i++) {
      wake.onSpeed(null);
    }
    for (var i = 0; i < 4; i++) {
      wake.onSpeed(95);
    }
    expect(wakes, 0, reason: 'the standstill restarted the run');
    wake.onSpeed(95);
    expect(wakes, 1);
  });

  test(
      'never throws: a wake whose provider graph is gone is logged, and '
      'the recording path returns normally', () {
    final container = ProviderContainer();
    final wake = container.read(
      Provider((ref) => Obd2RecordingMovementWake.forRef(ref)),
    );
    // Fault injection: the graph the factory reads through is torn down
    // under it (a disposed container throws on `ref.read`), exactly as a
    // recording outliving its provider scope would.
    container.dispose();

    expect(() {
      for (var i = 0; i < 5; i++) {
        wake.onSpeed(95);
      }
    }, returnsNormally);
  });
}
