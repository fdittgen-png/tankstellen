// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3528 integration (Epic #3527) — a successful `Obd2Service.connect`
// attaches an ElmSession over the transport: every service send runs the
// classify-before-you-kill ladder, a session death flows into the
// app-wide Obd2LinkDropSignal (the supervisor's recycle trigger), and a
// DELIBERATE disconnect never reads as a death.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

/// Transport with scripted replies whose behavior a test can flip
/// mid-session: [garbageMode] answers every OBD command with line noise,
/// [timeoutMode] throws [TimeoutException] on every send.
class _FlippableTransport implements Obd2Transport {
  _FlippableTransport(this._responses);

  final Map<String, String> _responses;
  final List<String> sent = [];
  bool _connected = false;
  bool garbageMode = false;
  bool timeoutMode = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    final cmd = command.trim();
    sent.add(cmd);
    if (timeoutMode) {
      throw TimeoutException('scripted timeout for $cmd');
    }
    final isAt = cmd.toUpperCase().startsWith('AT');
    if (garbageMode && !isAt) return r'~~<>##$garbage';
    return _responses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async => _connected = false;
}

void main() {
  silenceErrorLoggerSpool();

  test('two garbage replies through the service send path fire the ATWS '
      'warm-start rung — the ladder is live on production reads', () async {
    final transport = _FlippableTransport({..._initResponses});
    final service = Obd2Service(transport);
    await service.connect();

    transport.garbageMode = true;
    await service.readRpm();
    await service.readRpm();
    // The recovery is fire-and-forget inside the session — give the
    // microtask a beat to dispatch the ATWS.
    await Future<void>.delayed(Duration.zero);

    expect(transport.sent, contains('ATWS'),
        reason: 'repeated garbage must trigger the ELM warm start '
            '(research rule 6) on the SERVICE read path, proving the '
            'session ladder is wired into production sends');
    await service.disconnect();
  });

  test('a session death (consecutive timeouts) flows into the app-wide '
      'drop signal with the session cause', () async {
    final transport = _FlippableTransport({..._initResponses});
    final service = Obd2Service(transport)
      ..linkKind = 'ble'
      ..adapterMac = 'AA:BB';
    final drops = <Obd2LinkDropEvent>[];
    final sub = Obd2LinkDropSignal.instance.drops.listen(drops.add);
    addTearDown(sub.cancel);

    await service.connect();
    transport.timeoutMode = true;
    for (var i = 0; i < 3; i++) {
      try {
        await service.sendCommand('010C');
      } on TimeoutException {
        // expected — the scripted transport times out every send
      }
    }
    await Future<void>.delayed(Duration.zero);

    expect(drops, isNotEmpty,
        reason: 'the third consecutive timeout must declare the session '
            'dead and notify the one reconnect owner via the drop signal');
    expect(drops.single.reason, 'session:consecutiveTimeouts');
    expect(drops.single.transportKind, 'ble');
    expect(drops.single.mac, 'AA:BB');
    await service.disconnect();
  });

  test('a deliberate disconnect never reads as a session death — no drop '
      'event fires', () async {
    final transport = _FlippableTransport({..._initResponses});
    final service = Obd2Service(transport);
    final drops = <Obd2LinkDropEvent>[];
    final sub = Obd2LinkDropSignal.instance.drops.listen(drops.add);
    addTearDown(sub.cancel);

    await service.connect();
    await service.disconnect();
    await Future<void>.delayed(Duration.zero);

    expect(drops, isEmpty,
        reason: 'user intent is not a drop (research rule 7) — the '
            'session is disposed before the transport teardown');
  });
}
