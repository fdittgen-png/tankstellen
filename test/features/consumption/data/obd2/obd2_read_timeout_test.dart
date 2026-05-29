// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_read_timeout.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2261 concern 5 — adaptive per-class read timeouts.
void main() {
  silenceErrorLoggerSpool();

  group('classifyReadTimeout (#2261 concern 5)', () {
    test('ATZ / ATWS → wake class', () {
      expect(classifyReadTimeout('ATZ\r'), Obd2ReadTimeoutClass.wake);
      expect(classifyReadTimeout('ATWS'), Obd2ReadTimeoutClass.wake);
    });

    test('ATSP0 → protocol-search class (the longest wait)', () {
      expect(classifyReadTimeout('ATSP0\r'),
          Obd2ReadTimeoutClass.protocolSearch);
    });

    test('a pinned ATSP{n} is a trivial AT, NOT a protocol search', () {
      expect(classifyReadTimeout('ATSP6\r'), Obd2ReadTimeoutClass.trivialAt);
    });

    test('trivial AT echoes → trivialAt class', () {
      for (final c in ['ATE0\r', 'ATL0\r', 'ATH0\r', 'ATAT1\r', 'ATI\r',
        'ATDPN\r']) {
        expect(classifyReadTimeout(c), Obd2ReadTimeoutClass.trivialAt,
            reason: '$c should be a trivial AT echo');
      }
    });

    test('the first command on a fresh link gets the wake grace', () {
      // A trivial AT that would normally be trivialAt is upgraded to
      // wake when it is the very first thing on a fresh link.
      expect(
        classifyReadTimeout('ATE0\r', firstCommandOnFreshLink: true),
        Obd2ReadTimeoutClass.wake,
      );
    });

    test('an OBD request: protocolSearch first, wake thereafter', () {
      expect(
        classifyReadTimeout('0100\r', firstCommandOnFreshLink: true),
        Obd2ReadTimeoutClass.protocolSearch,
      );
      expect(classifyReadTimeout('010C\r'), Obd2ReadTimeoutClass.wake);
    });

    test('the timeout durations are ordered trivial < wake < protocol', () {
      expect(
          Obd2ReadTimeoutClass.trivialAt.timeout <
              Obd2ReadTimeoutClass.wake.timeout,
          isTrue);
      expect(
          Obd2ReadTimeoutClass.wake.timeout <
              Obd2ReadTimeoutClass.protocolSearch.timeout,
          isTrue);
    });
  });

  group('BluetoothObd2Transport applies the per-class timeout (#2261)', () {
    test(
        'a trivial AT echo that never answers times out at ~1 s, not 5 s',
        () async {
      final channel = _SilentChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // The FIRST command would get the wake grace, so prime the link
      // with one cheap command first (it also never answers, but we only
      // care that the SECOND — a trivial AT — uses the trivialAt class).
      final sw = Stopwatch()..start();
      // ATE0 is the first command → wake class (~2.5 s). We assert the
      // trivialAt path on a LATER command instead: send a successful one
      // first to clear _firstCommandPending.
      await _safeSend(transport, 'ATZ\r'); // first cmd, answered below
      sw.stop();

      // Now a trivial AT that never answers should time out near 1 s,
      // well under the old flat 5 s.
      final sw2 = Stopwatch()..start();
      await expectLater(
        transport.sendCommand('ATE0\r'),
        throwsA(isA<TimeoutException>()),
      );
      sw2.stop();
      expect(sw2.elapsed.inMilliseconds, lessThan(2000),
          reason: 'a trivial AT echo must time out near its ~1 s class, '
              'not the old flat 5 s');
      expect(sw2.elapsed.inMilliseconds, greaterThanOrEqualTo(800),
          reason: 'and not faster than its ~1 s class either');
    });
  });

  group('Obd2Service.connect inter-command sleep trim (#2261 concern 5)', () {
    test(
        'a settle delay is applied ONLY after the reset command (ATZ), not '
        'between trivial AT echoes', () async {
      // An adapter with a LARGE inter-command delay and a tiny post-reset
      // delay: the old code slept interCommandDelay between every command
      // (~5 × 400 ms ≈ 2 s). The new code sleeps ONLY postResetDelay
      // after ATZ, so the connect completes near-instantly.
      final adapter = _SlowInterCommandAdapter();
      final t = _AnsweringTransport();
      final service = Obd2Service(t);

      final sw = Stopwatch()..start();
      final ok = await service.connect(adapter: adapter);
      sw.stop();

      expect(ok, isTrue);
      expect(sw.elapsed.inMilliseconds, lessThan(300),
          reason: 'no fixed inter-command sleep between trivial AT echoes — '
              'the large interCommandDelay must NOT be paid 5×');
    });
  });
}

/// Adapter whose interCommandDelay is huge (would dominate connect time
/// if it were still applied between every command) and whose
/// postResetDelay is tiny (the only sleep the new code keeps).
class _SlowInterCommandAdapter implements Elm327Adapter {
  @override
  String get id => 'slow-test';
  @override
  List<String> get initSequence =>
      const ['ATZ\r', 'ATE0\r', 'ATL0\r', 'ATH0\r', 'ATSP0\r', 'ATAT1\r'];
  @override
  Duration get postResetDelay => const Duration(milliseconds: 5);
  @override
  Duration get interCommandDelay => const Duration(milliseconds: 400);
  @override
  List<String> get extraInitCommands => const [];
  @override
  String preParse(String raw) => raw;
  @override
  WakePolicy get wakePolicy => const WakePolicy.noop();
}

/// Transport that answers every command instantly with OK.
class _AnsweringTransport implements Obd2Transport {
  bool _connected = false;
  @override
  bool get isConnected => _connected;
  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  Future<String> sendCommand(String command) async => 'OK>';
}

/// Send and swallow a timeout (used only to advance link state).
Future<void> _safeSend(BluetoothObd2Transport t, String cmd) async {
  try {
    await t.sendCommand(cmd);
  } catch (_) {/* expected timeout */}
}

/// Channel that opens but never emits a reply — every read times out.
class _SilentChannel implements ElmByteChannel {
  // ignore: close_sinks
  final StreamController<List<int>> _c =
      StreamController<List<int>>.broadcast();
  bool _open = false;
  @override
  Future<void> open() async => _open = true;
  @override
  Future<void> close() async => _open = false;
  @override
  bool get isOpen => _open;
  @override
  Stream<List<int>> get incoming => _c.stream;
  @override
  Future<void> write(List<int> bytes) async {}
}
