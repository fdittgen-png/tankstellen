// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_connect_cooldown.dart';

/// #3421 — post-close cooldown unit tests. The clock and the wait are
/// injected (mirroring the Obd2ScanGovernor seams), so nothing here sleeps
/// real time.
void main() {
  group('ClassicConnectCooldown (#3421)', () {
    late int nowMs;
    late List<Duration> waits;
    late ClassicConnectCooldown cooldown;

    setUp(() {
      nowMs = 100000;
      waits = [];
      cooldown = ClassicConnectCooldown(
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
        wait: (d) async => waits.add(d),
      );
    });

    test('waits out the REMAINDER of the gap after a recent close', () async {
      cooldown.noteClosed('AA:BB');
      nowMs += 400; // 400 ms of the 1500 ms gap already elapsed
      final waited = await cooldown.awaitReadyToConnect('AA:BB');
      expect(waited, const Duration(milliseconds: 1100));
      expect(waits, [const Duration(milliseconds: 1100)]);
    });

    test('no wait once the gap has fully elapsed', () async {
      cooldown.noteClosed('AA:BB');
      nowMs += 1600;
      expect(await cooldown.awaitReadyToConnect('AA:BB'), Duration.zero);
      expect(waits, isEmpty);
    });

    test('no wait for a mac that never closed', () async {
      expect(await cooldown.awaitReadyToConnect('AA:BB'), Duration.zero);
      expect(waits, isEmpty);
    });

    test('the gap is per-mac — a close of X never delays Y', () async {
      cooldown.noteClosed('AA:BB');
      expect(await cooldown.awaitReadyToConnect('CC:DD'), Duration.zero);
      expect(waits, isEmpty);
    });

    test('mac keys are case-insensitive (Android reports upper-case)',
        () async {
      cooldown.noteClosed('aa:bb:cc:dd:ee:01');
      final waited = await cooldown.awaitReadyToConnect('AA:BB:CC:DD:EE:01');
      expect(waited, const Duration(milliseconds: 1500));
    });

    test('a LATER close stamp wins (drop then deliberate close)', () async {
      cooldown.noteClosed('AA:BB');
      nowMs += 1000;
      cooldown.noteClosed('AA:BB'); // re-stamped at +1000
      nowMs += 400; // only 400 ms since the LAST stamp
      final waited = await cooldown.awaitReadyToConnect('AA:BB');
      expect(waited, const Duration(milliseconds: 1100));
    });

    test('clock going BACKWARDS fails open to zero (no bogus long sleep)',
        () async {
      cooldown.noteClosed('AA:BB');
      nowMs -= 5000; // clock fault: now precedes the stamp
      expect(await cooldown.awaitReadyToConnect('AA:BB'), Duration.zero);
      expect(waits, isEmpty);
    });

    test('debugClear drops every stamp', () async {
      cooldown.noteClosed('AA:BB');
      cooldown.debugClear();
      expect(await cooldown.awaitReadyToConnect('AA:BB'), Duration.zero);
    });

    // Fault-injection for the documented never-throws contract (#2349): a
    // throwing wait seam must not abort the connect — the call completes
    // normally with Duration.zero (fail-open).
    test('never throws — a throwing wait seam fails open to zero', () async {
      final faulty = ClassicConnectCooldown(
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
        wait: (_) => Future<void>.error(StateError('wait seam fault')),
      );
      faulty.noteClosed('AA:BB');
      await expectLater(
        faulty.awaitReadyToConnect('AA:BB'),
        completion(Duration.zero),
      );
    });
  });
}
