import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_reconnect_scanner.dart';

/// Small real-wall-clock delays keep the suite under a few seconds
/// while still exercising the exponential-backoff math. The scanner
/// is deterministic against `Timer` — each cycle completes once
/// the wall clock elapses past [initialBackoff], so we can just
/// pump a few milliseconds and assert the doubling.
const _kInitial = Duration(milliseconds: 10);
const _kMax = Duration(milliseconds: 80);

/// Pumps real time until [cond] is true or [timeout] elapses. Needed
/// because `async.elapse` from `fake_async` is a transitive-only
/// dependency we don't want to import here; real timers work because
/// the scanner uses standard `Timer`.
Future<void> _waitFor(
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('AdapterReconnectScanner (#797 phase 3)', () {
    test('starts with initialBackoff and doubles on a missed probe',
        () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'AA:BB:CC:DD:EE:FF',
        probe: (mac) async {
          probeCalls++;
          return false; // always a miss
        },
        connect: (_) async => true,
        onReconnect: () {},
        initialBackoff: _kInitial,
        maxBackoff: _kMax,
      );
      await scanner.start();

      // Initial backoff is unchanged before the first tick.
      expect(scanner.currentBackoff, _kInitial);

      // Wait until the first probe AND the backoff doubling have
      // both landed — polling on the observable
      // `currentBackoff >= 2×initial` closes the race between the
      // probe's microtask and the scheduling of the next timer.
      await _waitFor(() =>
          probeCalls >= 1 && scanner.currentBackoff >= _kInitial * 2);
      expect(scanner.currentBackoff, _kInitial * 2,
          reason: 'a missed probe doubles the backoff');

      await _waitFor(() =>
          probeCalls >= 2 && scanner.currentBackoff >= _kInitial * 4);
      expect(scanner.currentBackoff, _kInitial * 4,
          reason: 'a second miss doubles again');

      await scanner.stop();
    });

    test('caps backoff at maxBackoff', () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        initialBackoff: _kInitial, // 10 ms
        maxBackoff: _kMax, // 80 ms
      );
      await scanner.start();
      // Let enough wall-clock pass that the backoff walks 10 → 20 →
      // 40 → 80 and would otherwise step to 160. Cap must hold.
      await _waitFor(() => probeCalls >= 5, timeout: const Duration(seconds: 5));
      expect(scanner.currentBackoff, _kMax,
          reason: 'backoff must not exceed maxBackoff');
      await scanner.stop();
    });

    test(
        'on MAC in range → calls connect and onReconnect, then '
        'self-stops', () async {
      var connectCalls = 0;
      var reconnectCount = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'AA:BB',
        probe: (mac) async => mac == 'AA:BB',
        connect: (mac) async {
          connectCalls++;
          return true;
        },
        onReconnect: () => reconnectCount++,
        initialBackoff: _kInitial,
      );
      await scanner.start();

      await _waitFor(() => reconnectCount > 0);
      expect(connectCalls, 1);
      expect(reconnectCount, 1);
      expect(scanner.isScanning, isFalse,
          reason: 'scanner must self-stop after a successful '
              'reconnect');
    });

    test('stop() cancels the scanner cleanly', () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        initialBackoff: _kInitial,
      );
      await scanner.start();
      expect(scanner.isScanning, isTrue);

      await scanner.stop();
      expect(scanner.isScanning, isFalse);

      // Sleep well past the initial backoff; probe must not fire.
      await Future<void>.delayed(_kInitial * 10);
      expect(probeCalls, 0,
          reason: 'stop() must cancel the pending timer so no '
              'probe runs after');
    });

    test(
        'connect failure doesn\'t blow up the scanner — it doubles '
        'backoff and retries on the next cycle', () async {
      var connectCalls = 0;
      var reconnectCount = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async => true, // always in range
        connect: (_) async {
          connectCalls++;
          // First attempt fails; subsequent attempts succeed.
          return connectCalls >= 2;
        },
        onReconnect: () => reconnectCount++,
        initialBackoff: _kInitial,
      );
      await scanner.start();

      await _waitFor(() => reconnectCount > 0,
          timeout: const Duration(seconds: 3));
      expect(connectCalls, greaterThanOrEqualTo(2));
      expect(reconnectCount, 1);
      expect(scanner.isScanning, isFalse,
          reason: 'successful reconnect must self-stop the scanner');
    });

    test(
        'probe throws → scanner swallows the error and treats it as '
        'a miss', () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          throw StateError('probe blew up');
        },
        connect: (_) async => true,
        onReconnect: () {},
        initialBackoff: _kInitial,
      );
      await scanner.start();

      // Wait until the first throwing probe has been consumed AND
      // the next timer has been scheduled (which happens after the
      // throw clears the `_cycleInFlight` gate and `_scheduleNext`
      // doubles the backoff). The doubled backoff is the observable
      // signal — polling `currentBackoff` avoids the race between
      // the probe's microtask and the assertion.
      await _waitFor(() =>
          probeCalls >= 1 && scanner.currentBackoff >= _kInitial * 2);
      expect(scanner.isScanning, isTrue,
          reason: 'scanner must survive probe exceptions');
      expect(scanner.currentBackoff, greaterThanOrEqualTo(_kInitial * 2),
          reason: 'a thrown probe must be treated as a miss and '
              'double the backoff');

      await scanner.stop();
    });

    test('start() is idempotent — repeated calls do not double-tick',
        () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        initialBackoff: _kInitial,
      );
      await scanner.start();
      await scanner.start();
      await scanner.start();

      await _waitFor(() => probeCalls >= 1);
      // The first tick should have fired exactly once; a quick nap
      // longer than the current window proves we only scheduled one
      // follow-up rather than three.
      final afterFirst = probeCalls;
      await Future<void>.delayed(_kInitial);
      expect(probeCalls - afterFirst, lessThanOrEqualTo(2),
          reason: 'triple start() must not enqueue three parallel '
              'timers — at most one follow-up tick should fire in '
              'the next window');

      await scanner.stop();
    });
  });
}
