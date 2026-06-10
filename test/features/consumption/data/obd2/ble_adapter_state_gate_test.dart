// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'ble_adapter_state_gate.dart';

/// #3182 — the bounded poweredOn gate run before every BLE scan / connect
/// dispatch. FBP's darwin side creates the CBCentralManager lazily and
/// instantly rejects the first scan/connect with state `unknown`; the gate
/// waits for `adapterState == on` but must FALL THROUGH (never throw, never
/// hang) when the adapter is genuinely off or the probe fails, so the
/// existing typed-error mapping (Obd2BluetoothOff) still owns those cases.
void main() {
  group('waitForAdapterOn (#3182)', () {
    test('completes as soon as the adapter reports on', () async {
      final states = StreamController<BluetoothAdapterState>();
      final sw = Stopwatch()..start();
      final wait = waitForAdapterOn(
        states: states.stream,
        timeout: const Duration(seconds: 3),
      );
      states.add(BluetoothAdapterState.unknown);
      states.add(BluetoothAdapterState.on);

      await wait;
      sw.stop();
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)),
          reason: 'the gate must resolve on the `on` edge, not the timeout');
      await states.close();
    });

    test(
        'falls through (returns normally) at the timeout when the adapter '
        'never reports on — a genuinely-off radio keeps its existing '
        'Obd2BluetoothOff surfacing', () async {
      final states = StreamController<BluetoothAdapterState>();
      final wait = waitForAdapterOn(
        states: states.stream,
        timeout: const Duration(milliseconds: 50),
      );
      states.add(BluetoothAdapterState.off);

      await expectLater(wait, completes,
          reason: 'the gate is best-effort: it must never throw the '
              'TimeoutException at the caller');
      await states.close();
    });

    test('falls through when the state stream ends without an on', () async {
      final states = Stream<BluetoothAdapterState>.fromIterable(
        const [BluetoothAdapterState.unknown],
      );
      await expectLater(
        waitForAdapterOn(
            states: states, timeout: const Duration(seconds: 3)),
        completes,
      );
    });

    test('falls through when the state probe errors', () async {
      final states = Stream<BluetoothAdapterState>.error(
        StateError('platform channel unavailable'),
      );
      await expectLater(
        waitForAdapterOn(
            states: states, timeout: const Duration(seconds: 3)),
        completes,
        reason: 'a failing probe must never block or fail the scan/connect '
            'that follows',
      );
    });
  });
}
