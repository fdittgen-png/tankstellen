// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3575 — [Obd2Service.recoverVehicleProtocol]: the in-session recovery
/// for the ELM UNABLE-TO-CONNECT livelock (adapter connected before
/// ignition-on → failed auto search → every command errs instantly).
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  test('re-establishes the protocol on an answering bus and reports true',
      () async {
    final transport = FakeObd2Transport({
      'ATSP0': 'OK',
      // Engine now running: the uninterrupted 0100 search converges.
      '0100': '41 00 BE 3E B8 11',
      'ATDPN': 'A6',
    });
    final service = Obd2Service(transport);
    await service.connect();
    transport.sentCommands.clear();

    final recovered = await service.recoverVehicleProtocol();

    expect(recovered, isTrue);
    expect(transport.sentCommands.first, 'ATSP0',
        reason: 'recovery must reset the failed auto search first');
    expect(transport.sentCommands, contains('0100'),
        reason: 'recovery must re-run the supported-PID discovery');
    expect(service.busProbe, Obd2BusProbeResult.answered);
  });

  test('a still-silent bus reports false (engine genuinely off)', () async {
    final transport = FakeObd2Transport({
      'ATSP0': 'OK',
      '0100': 'UNABLE TO CONNECT',
    });
    final service = Obd2Service(transport);
    await service.connect();

    final recovered = await service.recoverVehicleProtocol();

    expect(recovered, isFalse);
  });

  test('a disconnected transport reports false without sending', () async {
    final transport = FakeObd2Transport();
    final service = Obd2Service(transport);
    // Never connected.
    final recovered = await service.recoverVehicleProtocol();
    expect(recovered, isFalse);
    expect(transport.sentCommands, isEmpty);
  });
}
