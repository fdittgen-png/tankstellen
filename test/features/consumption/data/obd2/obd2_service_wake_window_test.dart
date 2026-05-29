// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_commands.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Adapter that opts into the bounded wake window (#2268 concern 2) —
/// stands in for the distinctive STN-/OBDLink-class adapters that are
/// the only ones meant to seed `maySleep: true`. Init sequence + timing
/// mirror the generic adapter so only the wake policy differs.
class _SleepyAdapter implements Elm327Adapter {
  const _SleepyAdapter({this.maxNudges = 1});

  final int maxNudges;

  @override
  String get id => 'sleepy-test';
  @override
  List<String> get initSequence => Elm327Commands.initCommands;
  @override
  Duration get postResetDelay => const Duration(milliseconds: 1);
  @override
  Duration get interCommandDelay => const Duration(milliseconds: 1);
  @override
  List<String> get extraInitCommands => const [];
  @override
  String preParse(String raw) => raw;
  @override
  WakePolicy get wakePolicy => WakePolicy(
        maySleep: true,
        wakeSettle: const Duration(milliseconds: 600),
        maxNudges: maxNudges,
      );
}

/// Transport that fails the FIRST command a configurable number of times
/// before answering, and counts attempts per command. Models a sleeping
/// adapter that ignores the first write(s) until it has woken.
class _SleepyTransport implements Obd2Transport {
  _SleepyTransport({
    this.failFirstCommandTimes = 0,
    Map<String, String>? responses,
  }) : _responses = responses ?? const {};

  /// How many times the very first command sent after connect should
  /// throw (a timeout) before it starts answering.
  final int failFirstCommandTimes;
  final Map<String, String> _responses;

  final List<String> log = <String>[];
  final Map<String, int> attempts = <String, int>{};
  String? _firstCommand;
  int _firstCommandFailures = 0;
  bool _connected = false;

  @override
  bool get isConnected => _connected;
  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    log.add(cmd);
    attempts[cmd] = (attempts[cmd] ?? 0) + 1;
    _firstCommand ??= cmd;
    if (cmd == _firstCommand &&
        _firstCommandFailures < failFirstCommandTimes) {
      _firstCommandFailures++;
      throw StateError('simulated sleeping-adapter timeout on $cmd');
    }
    return _responses[cmd] ?? 'OK>';
  }
}

void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    // Collapse the real 600 ms settle to ~near-zero so the suite runs in
    // milliseconds — we verify the window DID run, not its wall-clock.
    Obd2Service.wakeSettleScale = 0.0;
    Obd2Service.connectRetryDelay = const Duration(milliseconds: 1);
  });
  tearDown(() {
    Obd2Service.wakeSettleScale = 1.0;
    Obd2Service.connectRetryDelay = const Duration(milliseconds: 150);
  });

  group('Default GenericElm327Adapter — wake window NEVER runs (#2268)', () {
    test(
        'a generic connect leaves wakeObservation notRun and does NOT '
        'add an extra first-command send', () async {
      final transport = _SleepyTransport(responses: const {
        'ATZ': 'ELM327 v1.5>',
        'ATI': 'ELM327 v1.5>',
      });
      final service = Obd2Service(transport);

      final ok = await service.connect();

      expect(ok, isTrue);
      expect(service.wakeObservation, WakeObservation.notRun,
          reason: 'a no-op WakePolicy must never run the wake window');
      expect(transport.attempts['ATZ'], 1,
          reason: 'the first command must be sent exactly once for a '
              'generic adapter — no extra wake nudge');
    });
  });

  group('Active WakePolicy — bounded wake window (#2268 concern 2)', () {
    test(
        'first command answers immediately → answeredImmediately, no nudge',
        () async {
      final transport = _SleepyTransport(
        failFirstCommandTimes: 0,
        responses: const {'ATZ': 'ELM327 v1.5>', 'ATI': 'ELM327 v1.5>'},
      );
      final service = Obd2Service(transport);

      final ok = await service.connect(adapter: const _SleepyAdapter());

      expect(ok, isTrue);
      expect(service.wakeObservation, WakeObservation.answeredImmediately);
      expect(transport.attempts['ATZ'], 1,
          reason: 'an awake adapter answers on the first try — no re-send');
    });

    test(
        'first command times out once then a nudge succeeds → wokeAfterNudge '
        'with exactly ONE re-send', () async {
      final transport = _SleepyTransport(
        failFirstCommandTimes: 1,
        responses: const {'ATZ': 'ELM327 v1.5>', 'ATI': 'ELM327 v1.5>'},
      );
      final service = Obd2Service(transport);

      final ok = await service.connect(adapter: const _SleepyAdapter());

      expect(ok, isTrue);
      expect(service.wakeObservation, WakeObservation.wokeAfterNudge,
          reason: 'a first-command timeout recovered by a longer-settle '
              're-send is the observed wake outcome');
      expect(transport.attempts['ATZ'], 2,
          reason: 'original attempt + exactly one nudge');
    });

    test(
        'maxNudges is a hard cap — two timeouts with a single nudge fails '
        'the connect (bounded, not a loop)', () async {
      final transport = _SleepyTransport(
        // Fails twice, but the policy only grants one nudge.
        failFirstCommandTimes: 2,
        responses: const {'ATZ': 'ELM327 v1.5>'},
      );
      final service = Obd2Service(transport);

      final ok =
          await service.connect(adapter: const _SleepyAdapter(maxNudges: 1));

      expect(ok, isFalse,
          reason: 'when the single nudge also times out the connect must '
              'fail rather than re-send forever');
      expect(service.wakeObservation, WakeObservation.failed);
      expect(transport.attempts['ATZ'], 2,
          reason: 'original + one nudge = two attempts, then it bails');
    });

    test(
        'wakePolicyOverride no-op SUPPRESSES the window even for a sleepy '
        'adapter (cache says never-needed)', () async {
      final transport = _SleepyTransport(
        failFirstCommandTimes: 1,
        responses: const {'ATZ': 'ELM327 v1.5>', 'ATI': 'ELM327 v1.5>'},
      );
      final service = Obd2Service(transport);

      // The cache (concern 3) suppresses the window by passing a no-op
      // override. The first command then runs the steady-state retry only.
      final ok = await service.connect(
        adapter: const _SleepyAdapter(),
        wakePolicyOverride: const WakePolicy.noop(),
      );

      // With the window suppressed the single failure is still absorbed by
      // the steady-state one-shot retry, but the wake observation must stay
      // notRun so the cache is not updated from a suppressed connect.
      expect(ok, isTrue);
      expect(service.wakeObservation, WakeObservation.notRun,
          reason: 'a suppressed window must record no observation');
    });
  });
}
