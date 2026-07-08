// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3528 (Epic #3527) — ElmSession protocol core: init clone-tolerance,
// the classify-before-you-kill error ladder, consecutive-timeout death,
// staleness watchdog and ATRV keepalive. All driven through a scripted
// fake transport with FakeAsync-controlled time.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_commands.dart';
import 'package:tankstellen/features/obd2/data/elm_session.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

/// Scripted transport: maps command → reply like [FakeObd2Transport] but
/// can also throw [TimeoutException] on selected commands and records
/// every send.
class _ScriptedTransport implements Obd2Transport {
  _ScriptedTransport(this.responses);

  final Map<String, String> responses;
  final Set<String> timeoutCommands = {};

  /// Commands whose reply never arrives at all — the true zombie socket:
  /// no error, no timeout, just silence.
  final Set<String> hangCommands = {};
  final List<String> sent = [];
  bool connected = true;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<void> disconnect() async => connected = false;

  @override
  bool get isConnected => connected;

  @override
  Future<String> sendCommand(String command) async {
    final cmd = command.trim();
    sent.add(cmd);
    if (hangCommands.contains(cmd)) {
      return Completer<String>().future; // never completes
    }
    if (timeoutCommands.contains(cmd)) {
      throw TimeoutException('scripted timeout', const Duration(seconds: 1));
    }
    return responses[cmd] ?? 'OK';
  }
}

/// The default init replies a healthy adapter gives.
Map<String, String> _healthyInitReplies() => {
      'ATZ': 'ELM327 v1.5',
      'ATE0': 'OK',
      'ATL0': 'OK',
      'ATH0': 'OK',
      'ATSP0': 'OK',
      'ATAT1': 'OK',
    };

void main() {
  group('initialize', () {
    test('runs the full init burst and lands ready', () async {
      final transport = _ScriptedTransport(_healthyInitReplies());
      final session = ElmSession(transport);
      addTearDown(session.dispose);

      await session.initialize();

      expect(session.state, ElmSessionState.ready);
      expect(transport.sent,
          ['ATZ', 'ATE0', 'ATL0', 'ATH0', 'ATSP0', 'ATAT1']);
    });

    test('tolerates ? replies to OPTIONAL commands (clone, rule 12)',
        () async {
      final replies = _healthyInitReplies()
        ..['ATL0'] = '?'
        ..['ATAT1'] = '?';
      final session = ElmSession(_ScriptedTransport(replies));
      addTearDown(session.dispose);

      await session.initialize();

      expect(session.state, ElmSessionState.ready);
    });

    test('hard-fails when echo-off is refused', () async {
      final replies = _healthyInitReplies()..['ATE0'] = '?';
      final session = ElmSession(_ScriptedTransport(replies));
      addTearDown(session.dispose);

      await expectLater(session.initialize(), throwsStateError);
      expect(session.state, ElmSessionState.dead);
      expect(session.deathCause, ElmSessionDeathCause.transportError);
    });

    test('ATZ version banner is never treated as a failure', () async {
      // The banner classifies as garbage — the reset must not die on it.
      final replies = _healthyInitReplies()..['ATZ'] = 'ELM327 v2.1';
      final session = ElmSession(_ScriptedTransport(replies));
      addTearDown(session.dispose);

      await session.initialize();

      expect(session.state, ElmSessionState.ready);
    });
  });

  group('error ladder (classify before you kill)', () {
    late _ScriptedTransport transport;
    late ElmSession session;

    Future<void> boot() async {
      transport = _ScriptedTransport(_healthyInitReplies());
      session = ElmSession(transport,
          // Watchdog quiet during ladder tests — liveness has its own group.
          staleAfter: const Duration(days: 1),
          keepaliveIdle: const Duration(days: 1));
      addTearDown(session.dispose);
      await session.initialize();
      transport.sent.clear();
    }

    test('NO DATA is a live link — no recovery, no death', () async {
      await boot();
      transport.responses['010D'] = 'NO DATA';

      for (var i = 0; i < 10; i++) {
        await session.send('010D\r');
      }

      expect(session.state, ElmSessionState.ready);
      expect(transport.sent.where((c) => c == 'ATWS'), isEmpty);
      expect(transport.sent.where((c) => c == 'ATPC'), isEmpty);
    });

    test('two consecutive garbage replies trigger one ATWS warm start',
        () async {
      await boot();
      transport.responses['010D'] = 'corrupt';

      await session.send('010D\r');
      expect(transport.sent.contains('ATWS'), isFalse,
          reason: 'one garbage reply is not yet recovery fuel');
      await session.send('010D\r');
      // The recovery send is unawaited — let it run.
      await Future<void>.delayed(Duration.zero);

      expect(transport.sent.contains('ATWS'), isTrue);
      expect(session.state, ElmSessionState.ready,
          reason: 'recovery is transparent — session returns to ready');
    });

    test('CAN ERROR triggers ATPC protocol close', () async {
      await boot();
      transport.responses['010C'] = 'CAN ERROR';

      await session.send('010C\r');
      await Future<void>.delayed(Duration.zero);

      expect(transport.sent.contains('ATPC'), isTrue);
      expect(session.state, ElmSessionState.ready);
    });

    test('consecutive timeouts declare the session dead', () async {
      await boot();
      transport.timeoutCommands.add('010D');

      for (var i = 0; i < 3; i++) {
        await expectLater(
            session.send('010D\r'), throwsA(isA<TimeoutException>()));
      }

      expect(session.state, ElmSessionState.dead);
      expect(session.deathCause, ElmSessionDeathCause.consecutiveTimeouts);
      await expectLater(session.send('010D\r'), throwsStateError);
    });

    test('a framed reply between timeouts resets the death counter',
        () async {
      await boot();

      transport.timeoutCommands.add('010D');
      await expectLater(
          session.send('010D\r'), throwsA(isA<TimeoutException>()));
      await expectLater(
          session.send('010D\r'), throwsA(isA<TimeoutException>()));
      transport.timeoutCommands.clear();
      await session.send('010D\r'); // alive again
      transport.timeoutCommands.add('010D');
      await expectLater(
          session.send('010D\r'), throwsA(isA<TimeoutException>()));
      await expectLater(
          session.send('010D\r'), throwsA(isA<TimeoutException>()));

      expect(session.state, ElmSessionState.ready,
          reason: 'never 3 CONSECUTIVE timeouts — the counter reset');
    });
  });

  group('liveness (staleness watchdog + ATRV keepalive)', () {
    test('keepalive sends ATRV when the link idles', () {
      fakeAsync((async) {
        final transport = _ScriptedTransport(_healthyInitReplies());
        transport.responses['ATRV'] = '12.4V';
        var now = DateTime(2026, 7, 8);
        final session = ElmSession(
          transport,
          keepaliveIdle: const Duration(seconds: 7),
          staleAfter: const Duration(seconds: 15),
          now: () => now,
        );
        unawaited(session.initialize());
        async.flushMicrotasks();
        expect(session.state, ElmSessionState.ready);
        transport.sent.clear();

        // Idle past the keepalive threshold (watchdog ticks every 2.5 s;
        // the ATRV reply keeps refreshing lastAliveAt via the ladder).
        now = now.add(const Duration(seconds: 8));
        async.elapse(const Duration(seconds: 8));

        expect(transport.sent.contains('ATRV'), isTrue);
        expect(session.state, ElmSessionState.ready);
        session.dispose();
      });
    });

    test('staleness declares the session dead (zombie socket)', () {
      fakeAsync((async) {
        final transport = _ScriptedTransport(_healthyInitReplies());
        // The zombie: every post-init command times out, INCLUDING the
        // keepalive — nothing ever refreshes lastAliveAt.
        var now = DateTime(2026, 7, 8);
        final session = ElmSession(
          transport,
          keepaliveIdle: const Duration(seconds: 7),
          staleAfter: const Duration(seconds: 15),
          now: () => now,
        );
        unawaited(session.initialize());
        async.flushMicrotasks();
        transport.hangCommands
          ..add('ATRV')
          ..add('010D');

        final seen = <ElmSessionState>[];
        session.states.listen(seen.add);

        now = now.add(const Duration(seconds: 16));
        async.elapse(const Duration(seconds: 16));

        expect(session.state, ElmSessionState.dead);
        expect(session.deathCause, ElmSessionDeathCause.stale);
        expect(seen, contains(ElmSessionState.dead));
        session.dispose();
      });
    });
  });

  test('the ladder uses the shared command constants', () {
    // Guard the constants the ladder depends on — a rename must break
    // loudly here, not silently change wire behavior.
    expect(Elm327Commands.warmStartCommand, 'ATWS\r');
    expect(Elm327Commands.readVoltageCommand, 'ATRV\r');
    expect(Elm327Commands.protocolCloseCommand, 'ATPC\r');
  });
}
