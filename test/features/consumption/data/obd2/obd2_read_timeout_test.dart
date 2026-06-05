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

    test(
        'an AT echo inside the early-init window gets the wake grace (#2889)',
        () {
      // RED before #2889: ATE0 as the SECOND command (index 1) — no longer
      // firstCommandOnFreshLink — used to fall to trivialAt (1 s), which a
      // slow clone answering in 2.3 s could not beat. It must now be `wake`.
      for (var idx = 0; idx < earlyInitGraceCount; idx++) {
        expect(
          classifyReadTimeout('ATE0\r', atCommandsSinceOpen: idx),
          Obd2ReadTimeoutClass.wake,
          reason: 'AT command #$idx is inside the early-init grace window',
        );
      }
    });

    test(
        'an AT echo PAST the early-init window falls back to trivialAt (#2889)',
        () {
      expect(
        classifyReadTimeout('ATL0\r',
            atCommandsSinceOpen: earlyInitGraceCount),
        Obd2ReadTimeoutClass.trivialAt,
      );
      expect(
        classifyReadTimeout('ATL0\r',
            atCommandsSinceOpen: earlyInitGraceCount + 5),
        Obd2ReadTimeoutClass.trivialAt,
      );
    });

    test('omitting the AT counter preserves the legacy trivialAt default',
        () {
      // No counter → defaults past the window, so behaviour matches the
      // pre-#2889 single-command grace exactly.
      expect(classifyReadTimeout('ATE0\r'), Obd2ReadTimeoutClass.trivialAt);
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
      // #2889 — the first [earlyInitGraceCount] AT echoes now get the
      // longer wake grace, so prime PAST that window with answered AT
      // commands first, then assert the trivialAt (~1 s) class applies to
      // a LATER trivial AT echo that never answers.
      final channel = _PrimeThenSilentChannel(
        answered: {'ATZ\r', 'ATE0\r', 'ATL0\r'},
      );
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // ATZ (idx 0, wake), ATE0 (idx 1, early-init wake), ATL0 (idx 2,
      // early-init wake) — all answered instantly, so they cost ~0 ms and
      // advance the AT counter to 3 (past the early-init window).
      await _safeSend(transport, 'ATZ\r');
      await _safeSend(transport, 'ATE0\r');
      await _safeSend(transport, 'ATL0\r');

      // Now a trivial AT (idx 3, past the early-init window) that never
      // answers should time out near 1 s, well under the old flat 5 s.
      final sw2 = Stopwatch()..start();
      await expectLater(
        transport.sendCommand('ATH0\r'),
        throwsA(isA<TimeoutException>()),
      );
      sw2.stop();
      expect(sw2.elapsed.inMilliseconds, lessThan(2000),
          reason: 'a trivial AT echo past the early-init window must time '
              'out near its ~1 s class, not the old flat 5 s');
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

/// #2889 — answers a known set of priming commands instantly with `OK>`
/// (so they cost ~0 ms and advance the early-init AT counter), and stays
/// SILENT for every other command (so it times out at its class budget).
class _PrimeThenSilentChannel implements ElmByteChannel {
  _PrimeThenSilentChannel({required this.answered});
  final Set<String> answered;
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
  Future<void> write(List<int> bytes) async {
    final command = String.fromCharCodes(bytes);
    if (answered.contains(command)) {
      await Future<void>.delayed(Duration.zero);
      _c.add('OK>'.codeUnits);
    }
    // Otherwise stay silent → the read hits its per-class timeout.
  }
}
