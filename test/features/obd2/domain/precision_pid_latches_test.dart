// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';
import 'package:tankstellen/features/obd2/domain/precision_pid_latches.dart';

/// #4159 — pins [PrecisionPidLatches] before its PID numbers move to the
/// adapter: the order of the support-gate questions, the exact subscribed
/// table, and the measured-φ priority rule (bank-1-sensor-1 first, then
/// the freshest other sensor, all inside a 10 s window whose edge is
/// inclusive).

typedef _Row = (String command, double hz, PidPriority priority, PidTier tier);

class _Rec extends PidScheduler {
  _Rec() : super(transport: (_) async => 'NO DATA');

  final List<_Row> rows = <_Row>[];
  final Map<String, void Function(String)> callbacks = {};

  @override
  void subscribe(
    String command,
    ScheduledPid config,
    void Function(String response) onResult,
  ) {
    rows.add((command, config.hz, config.priority, config.tier));
    callbacks[command] = onResult;
  }

  void deliver(String command, String response) =>
      callbacks[command]!(response);
}

class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
}

String _hex(int pid) =>
    '0x${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}';

const _allGates = [
  0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, //
  0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B,
  0x66, 0x9D, 0xA2, 0x52,
];

({_Rec scheduler, List<String> gates}) _subscribe(
  PrecisionPidLatches latches,
  Set<int> supported,
) {
  final scheduler = _Rec();
  final gates = <String>[];
  latches.subscribe(scheduler, isPidSupported: (pid) {
    gates.add(_hex(pid));
    return supported.contains(pid);
  });
  return (scheduler: scheduler, gates: gates);
}

void main() {
  test('asks the gate for every family in a fixed order', () {
    final r = _subscribe(PrecisionPidLatches(), const {});
    expect(r.gates, [for (final p in _allGates) _hex(p)]);
    expect(r.scheduler.rows, isEmpty);
  });

  test('subscribes exactly the supported families with their cadence', () {
    final r = _subscribe(
      PrecisionPidLatches(),
      {0x24, 0x2A, 0x34, 0x3B, 0x66, 0x9D, 0xA2, 0x52},
    );
    expect(r.gates, [for (final p in _allGates) _hex(p)]);
    expect(r.scheduler.rows, const <_Row>[
      ('0124\r', 2.0, PidPriority.medium, PidTier.mixture),
      ('012A\r', 2.0, PidPriority.medium, PidTier.mixture),
      ('0134\r', 2.0, PidPriority.medium, PidTier.mixture),
      ('013B\r', 2.0, PidPriority.medium, PidTier.mixture),
      ('0166\r', 5.0, PidPriority.high, PidTier.dynamics),
      ('019D\r', 5.0, PidPriority.high, PidTier.dynamics),
      ('01A2\r', 5.0, PidPriority.high, PidTier.dynamics),
      ('0152\r', 0.5, PidPriority.medium, PidTier.slowCorrection),
    ]);
  });

  test('each callback fills its own getter', () {
    final latches = PrecisionPidLatches();
    final r = _subscribe(latches, {0x66, 0x9D, 0xA2, 0x52});
    expect(latches.mafSensorGPerS, isNull);
    r.scheduler.deliver('0166\r', '41 66 01 05 40'); // sensor A 42 g/s
    r.scheduler.deliver('019D\r', '41 9D 01 F4 00 00'); // 10 g/s
    r.scheduler.deliver('01A2\r', '41 A2 02 80'); // 20 mg/stroke
    r.scheduler.deliver('0152\r', '41 52 D9'); // ≈ 85.1 %
    expect(latches.mafSensorGPerS, 42.0);
    expect(latches.engineFuelRate9dGPerS, closeTo(10.0, 1e-9));
    expect(latches.cylinderFuelRateMgPerStroke, 20.0);
    expect(latches.ethanolPercent, closeTo(217 * 100.0 / 255.0, 1e-9));
    // A NO DATA answer never clears a landed value.
    r.scheduler.deliver('019D\r', 'NO DATA');
    expect(latches.engineFuelRate9dGPerS, closeTo(10.0, 1e-9));
  });

  group('measured φ priority (#3427)', () {
    const phiA = '41 24 66 66 32 DD'; // 0x24 φ = 0x6666 / 32768
    const phiB = '41 2A 80 00 00 00'; // 0x2A φ = 1.0
    const phiC = '41 34 C0 00 00 00'; // 0x34 φ = 1.5
    const phiD = '41 25 40 00 00 00'; // 0x25 φ = 0.5
    const a = 0x6666 * 2.0 / 65536.0;

    late _Clock clock;
    late PrecisionPidLatches latches;
    late _Rec scheduler;

    setUp(() {
      clock = _Clock(DateTime.utc(2026, 9, 16, 12));
      latches = PrecisionPidLatches(clock: clock.call);
      scheduler = _subscribe(latches, {0x24, 0x25, 0x2A, 0x34}).scheduler;
    });

    test('null before anything lands', () {
      expect(latches.measuredPhi(), isNull);
    });

    test('a fresh 0x24 beats a NEWER 0x2A', () {
      scheduler.deliver('0124\r', phiA);
      clock.now = clock.now.add(const Duration(seconds: 5));
      scheduler.deliver('012A\r', phiB);
      expect(latches.measuredPhi(), a);
    });

    test('exactly 10 s old is still fresh; +1 ms falls through to the '
        'freshest other sensor', () {
      scheduler.deliver('0124\r', phiA);
      clock.now = clock.now.add(const Duration(seconds: 5));
      scheduler.deliver('012A\r', phiB);
      clock.now = clock.now.add(const Duration(seconds: 5));
      expect(latches.measuredPhi(), a, reason: 'age == 10 s is inclusive');
      clock.now = clock.now.add(const Duration(milliseconds: 1));
      expect(latches.measuredPhi(), 1.0);
    });

    test('0x24 beats a NEWER fresh 0x34 (voltage family first)', () {
      scheduler.deliver('0124\r', phiA);
      clock.now = clock.now.add(const Duration(seconds: 1));
      scheduler.deliver('0134\r', phiC);
      expect(latches.measuredPhi(), a);
    });

    test('0x34 wins when 0x24 is stale, over a newer other sensor', () {
      scheduler.deliver('0124\r', phiA);
      clock.now = clock.now.add(const Duration(seconds: 2));
      scheduler.deliver('0134\r', phiC);
      clock.now = clock.now.add(const Duration(seconds: 2));
      scheduler.deliver('012A\r', phiB);
      clock.now = clock.now.add(const Duration(seconds: 7)); // 0x24 at 11 s
      expect(latches.measuredPhi(), 1.5);
    });

    test('without sensor 1 the freshest other sensor wins', () {
      scheduler.deliver('012A\r', phiB);
      clock.now = clock.now.add(const Duration(seconds: 1));
      scheduler.deliver('0125\r', phiD);
      expect(latches.measuredPhi(), 0.5);
      clock.now = clock.now.add(const Duration(seconds: 10));
      expect(latches.measuredPhi(), 0.5, reason: '0x2A stale, 0x25 at 10 s');
      clock.now = clock.now.add(const Duration(milliseconds: 1));
      expect(latches.measuredPhi(), isNull);
    });
  });
}
