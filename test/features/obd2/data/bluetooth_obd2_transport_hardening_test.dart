// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';

/// #3276 / #3277 — transport hardening: the response buffer must not grow
/// unbounded on a never-prompting clone, and the #2889 desync-latch must keep
/// the command queue aligned when a slow link delivers a multi-frame reply
/// AFTER a short command's read-timeout fired.
///
/// Driven against a fully manual channel so the test controls every byte and
/// its timing — `write()` does nothing; the test injects replies via [emit].
class _ManualChannel implements ElmByteChannel {
  final StreamController<List<int>> _ctrl =
      StreamController<List<int>>.broadcast();
  final List<String> writes = [];
  bool _open = false;

  void emit(String s) {
    if (!_ctrl.isClosed) _ctrl.add(s.codeUnits);
  }

  @override
  Future<void> open() async => _open = true;

  @override
  Future<void> close() async {
    _open = false;
    await _ctrl.close();
  }

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> write(List<int> bytes) async =>
      writes.add(String.fromCharCodes(bytes));
}

void main() {
  group('BluetoothObd2Transport hardening', () {
    test(
        '#3276 a never-prompting flood is clamped — the command fails fast '
        'with a StateError (not OOM / not a 5 s timeout) and the queue stays '
        'aligned', () async {
      final ch = _ManualChannel();
      final transport = BluetoothObd2Transport(ch);
      await transport.connect();

      final flooded = transport.sendCommand('0100\r');
      // Let the queue run write() and arm `_pending` before the flood lands.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // Stream > 8 KB with NO '>' prompt — a runaway/garbage adapter.
      ch.emit('A' * 9000);

      await expectLater(flooded, throwsA(isA<StateError>()),
          reason: 'overflow fails fast via the buffer clamp, not the timeout');

      // The next command is unaffected — the clamp cleared the buffer and
      // armed the swallow latch, so the queue is realigned.
      final next = transport.sendCommand('010C\r');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      ch.emit('41 0C 1A F8>');
      expect(await next, contains('41 0C'),
          reason: 'next command receives its own reply after the clamp');
    });

    test(
        '#3277 a slow multi-frame reply arriving AFTER a short command timed '
        'out is swallowed, not mis-delivered to the next command (#2889 latch)',
        () async {
      // A tight read-timeout so the first command times out quickly; the
      // "slow link" then delivers its late reply in two frames.
      final ch = _ManualChannel();
      final transport = BluetoothObd2Transport(
        ch,
        readTimeout: const Duration(milliseconds: 100),
      );
      await transport.connect();

      // 1) Short command times out — no reply within 100 ms.
      await expectLater(
        transport.sendCommand('ATE0\r'),
        throwsA(isA<TimeoutException>()),
      );

      // 2) The slow link's LATE reply for ATE0 now dribbles in across frames
      //    (≥1 frame after the timeout). It must be SWALLOWED by the latch.
      ch.emit('OK');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      ch.emit('>'); // completes the stale frame — no pending → dropped
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 3) The next command must get ITS OWN reply, not the swallowed 'OK'.
      final next = transport.sendCommand('010C\r');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      ch.emit('41 0C 1A F8>');

      final reply = await next;
      expect(reply, contains('41 0C'),
          reason: 'the late stale ATE0 reply was swallowed; 010C stays aligned');
      expect(reply, isNot(contains('OK')));
    });
  });
}
