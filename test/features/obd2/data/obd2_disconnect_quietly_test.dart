// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_disconnect_quietly.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3420 — fault-injection contract test for [Obd2DisconnectQuietly]: the
/// wrapper's "Never throws" doc is load-bearing, because every call site is
/// `unawaited(...)` — a rethrow there is an UNHANDLED zone error (the
/// 2026-07-02 field log's `PlatformDispatcher.onError` PlatformException).
void main() {
  silenceErrorLoggerSpool();

  test('disconnectQuietly completes when the transport disconnect throws',
      () async {
    final svc = Obd2Service(_ThrowingDisconnectTransport());
    await svc.connect();
    await expectLater(svc.disconnectQuietly(), completes);
  });

  test('disconnectQuietly still performs a clean disconnect', () async {
    final transport = FakeObd2Transport(const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    });
    final svc = Obd2Service(transport);
    await svc.connect();
    await expectLater(svc.disconnectQuietly(), completes);
    expect(transport.isConnected, isFalse,
        reason: 'the quiet wrapper must still close a healthy link');
  });
}

/// The fault seam: a transport whose teardown throws the way a dying
/// platform channel does mid-drop.
class _ThrowingDisconnectTransport extends FakeObd2Transport {
  _ThrowingDisconnectTransport()
      : super(const {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
        });

  @override
  Future<void> disconnect() async {
    throw StateError('bt socket closed, read return: -1');
  }
}
