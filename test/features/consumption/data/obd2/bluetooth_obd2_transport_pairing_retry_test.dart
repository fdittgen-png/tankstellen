// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_errors.dart';

/// #3181 — the open-retry loop must NOT tear down + re-dial through an
/// in-flight/failed PAIRING: the inter-attempt `close()` would dismiss an
/// OS pairing dialog still on screen, and re-dialling burns the OBDLink
/// CX's 5-minute bond-acceptance window. A pairing failure rethrows after
/// attempt 1, with NO inter-attempt close; an ordinary transient keeps
/// the #2906 3-attempt retry.
class _FakeChannel implements ElmByteChannel {
  _FakeChannel(this.fault);

  final Object fault;
  int openAttempts = 0;
  int closeCalls = 0;
  final _controller = StreamController<List<int>>.broadcast();

  @override
  bool get isOpen => false;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> open() async {
    openAttempts++;
    throw fault;
  }

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> close() async {
    closeCalls++;
  }
}

void main() {
  group('BluetoothObd2Transport.connect — pairing retry suppression (#3181)',
      () {
    test('an Obd2PairingRequired open failure is NOT retried and the channel '
        'is NOT closed between attempts (RED on master: 3 attempts with '
        'inter-attempt close)', () async {
      final ch = _FakeChannel(const Obd2PairingRequired());
      final transport = BluetoothObd2Transport(ch);

      await expectLater(
          transport.connect(), throwsA(isA<Obd2PairingRequired>()));

      expect(ch.openAttempts, 1,
          reason: 'no re-dial through a pairing failure');
      expect(ch.closeCalls, 0,
          reason: 'the inter-attempt teardown must be suppressed — it would '
              'dismiss the OS pairing dialog');
    });

    test('CONTROL: an ordinary recoverable transient still gets the #2906 '
        '3-attempt retry with inter-attempt teardown', () async {
      final ch = _FakeChannel(TimeoutException('Timed out after 4s'));
      final transport = BluetoothObd2Transport(ch);

      await expectLater(transport.connect(), throwsA(isA<TimeoutException>()));

      expect(ch.openAttempts, 3);
      expect(ch.closeCalls, 2,
          reason: 'best-effort teardown between each of the 3 attempts');
    });
  });
}
