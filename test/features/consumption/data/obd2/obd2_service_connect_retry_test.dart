import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// Transport that throws on a configurable subset of commands and
/// returns canned responses on the rest. Used to drive the connect-
/// time retry: the first attempt at the targeted command(s) throws,
/// the retry attempt succeeds (#1916).
class _FlakyTransport implements Obd2Transport {
  _FlakyTransport({
    required this.responses,
    this.throwOnceFor = const <String>{},
  });

  final Map<String, String> responses;

  /// Commands (trimmed) that should throw on their FIRST encounter.
  /// On the retry attempt they succeed and serve `responses`.
  final Set<String> throwOnceFor;

  final Map<String, int> attempts = <String, int>{};
  final List<String> log = <String>[];

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    final n = (attempts[cmd] ?? 0) + 1;
    attempts[cmd] = n;
    log.add(cmd);
    if (n == 1 && throwOnceFor.contains(cmd)) {
      throw StateError('simulated transient BLE blip on $cmd');
    }
    return responses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async => _connected = false;
}

void main() {
  // Pin the retry settle to near-zero so the suite runs in
  // milliseconds — we're verifying the retry happens, not the
  // wall-clock spacing.
  setUp(() {
    Obd2Service.connectRetryDelay = const Duration(milliseconds: 1);
  });
  tearDown(() {
    Obd2Service.connectRetryDelay = const Duration(milliseconds: 150);
  });

  group('Obd2Service.connect() one-shot retry (#1916)', () {
    test(
        'a single transient blip on an init-sequence command is absorbed '
        '— connect still returns true', () async {
      final transport = _FlakyTransport(
        responses: const {
          // Init sequence — values are not asserted; the service just
          // needs SOMETHING coming back that isn\'t a thrown exception.
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATS0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          'ATAT1': 'OK>',
          'ATI': 'ELM327 v1.5>',
        },
        // Make the FIRST attempt at ATE0 throw — the second attempt
        // (the retry) serves the canned `OK>`.
        throwOnceFor: const {'ATE0'},
      );
      final service = Obd2Service(transport);

      final ok = await service.connect();

      expect(ok, isTrue,
          reason: 'a single transient blip during the init handshake '
              'must be absorbed by the connect-time retry (#1916)');
      expect(transport.attempts['ATE0'], 2,
          reason: 'the failing command must be retried exactly once');
    });

    test(
        'a single transient blip on the ATI firmware probe does not '
        'fail the connect (ATI failures are already non-fatal, but the '
        'retry should still recover so the firmware string is captured)',
        () async {
      final transport = _FlakyTransport(
        responses: const {
          'ATZ': 'OK>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATS0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          'ATAT1': 'OK>',
          'ATI': 'ELM327 v2.2>',
        },
        throwOnceFor: const {'ATI'},
      );
      final service = Obd2Service(transport);

      final ok = await service.connect();

      expect(ok, isTrue);
      expect(transport.attempts['ATI'], 2,
          reason: 'ATI must be retried so the firmware tier detection '
              'can still complete after a transient blip');
      expect(service.adapterFirmware, 'ELM327 v2.2',
          reason: 'the retried ATI response is the one we should record');
    });

    test(
        'two consecutive transients on the same init command → no third '
        'attempt, connect returns false (one-shot retry, not a loop)',
        () async {
      var atE0Calls = 0;
      final transport = _AlwaysFailsAtE0(onAttempt: () => atE0Calls++);
      final service = Obd2Service(transport);

      final ok = await service.connect();

      expect(ok, isFalse,
          reason: 'a hard failure (not a transient blip) must still '
              'bubble up — the retry is bounded, not unlimited');
      expect(atE0Calls, 2,
          reason: 'ATE0 must be attempted exactly twice — once + one '
              'retry — before the connect bails');
    });
  });
}

/// Transport that always throws on `ATE0` — used to prove the retry
/// is **bounded** (one extra attempt, never two).
class _AlwaysFailsAtE0 implements Obd2Transport {
  _AlwaysFailsAtE0({required this.onAttempt});
  final void Function() onAttempt;
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
    if (cmd == 'ATE0') {
      onAttempt();
      throw StateError('hard ATE0 failure');
    }
    return 'OK>';
  }
}
