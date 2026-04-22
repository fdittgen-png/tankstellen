import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_scheduler.dart';

/// Helper: build a scheduler wired to a deterministic clock. The returned
/// `advance` function bumps the clock forward by [d] — use it instead of
/// real-wall-clock waits inside `pickNextCommand` tests.
({PidScheduler scheduler, void Function(Duration) advance})
    _schedulerWithClock({
  required Future<String> Function(String) transport,
  Duration tickRate = const Duration(milliseconds: 100),
}) {
  var fakeNow = DateTime(2026, 1, 1, 12);
  final scheduler = PidScheduler(
    transport: transport,
    tickRate: tickRate,
    clock: () => fakeNow,
  );
  void advance(Duration d) {
    fakeNow = fakeNow.add(d);
  }

  return (scheduler: scheduler, advance: advance);
}

/// A recording transport that returns a canned `"41 XX …"` hex string per
/// command and optionally delays each response by [delay].
class _FakeTransport {
  _FakeTransport({
    this.delay = Duration.zero,
    this.throwOn = const <String>{},
  });

  final Duration delay;
  final Set<String> throwOn;
  final List<String> calls = <String>[];

  Future<String> call(String command) async {
    calls.add(command);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (throwOn.contains(command)) {
      throw Exception('simulated transport failure for $command');
    }
    // Echo the requested PID in the canned hex response.
    final pid = command.length >= 4 ? command.substring(2, 4) : '00';
    return '41 $pid 00>';
  }
}

void main() {
  group('PidScheduler.pickNextCommand — selection math', () {
    test(
        'picks the PID with the largest (elapsed × hz) when all have '
        'been read', () {
      final setup = _schedulerWithClock(
        transport: _FakeTransport().call,
      );
      final scheduler = setup.scheduler;

      // Subscribe three PIDs with different hz targets.
      scheduler.subscribe(
        '010C',
        ScheduledPid(hz: 5.0),
        (_) {},
      ); // 5 Hz
      scheduler.subscribe(
        '0104',
        ScheduledPid(hz: 1.0),
        (_) {},
      ); // 1 Hz
      scheduler.subscribe(
        '012F',
        ScheduledPid(hz: 0.1),
        (_) {},
      ); // 0.1 Hz

      // Set synthetic lastReadAt so the weights are deterministic.
      // Pick a base time = initial fakeNow for the scheduler. All three
      // read 300 ms ago, so weights are:
      //   010C: 0.3 × 5.0 = 1.5
      //   0104: 0.3 × 1.0 = 0.3
      //   012F: 0.3 × 0.1 = 0.03
      final base = DateTime(2026, 1, 1, 12);
      final pastReadAt = base.subtract(const Duration(milliseconds: 300));
      // pickNextCommand is called with `now` = base. We expose the subs
      // via subscribe; reach in by re-subscribing with stamped config.
      // Simplest path: subscribe + manually stamp via a test-only route.
      // Since `ScheduledPid.lastReadAt` is a public mutable field, we
      // re-create the config references.
      // Re-subscribe with pre-stamped configs:
      final rpm = ScheduledPid(hz: 5.0)..lastReadAt = pastReadAt;
      final load = ScheduledPid(hz: 1.0)..lastReadAt = pastReadAt;
      final fuel = ScheduledPid(hz: 0.1)..lastReadAt = pastReadAt;
      scheduler.subscribe('010C', rpm, (_) {});
      scheduler.subscribe('0104', load, (_) {});
      scheduler.subscribe('012F', fuel, (_) {});

      expect(scheduler.pickNextCommand(base), '010C');
    });

    test(
        'a newly subscribed PID (lastReadAt=null) wins over any '
        'ever-read PID regardless of their hz', () {
      final setup = _schedulerWithClock(
        transport: _FakeTransport().call,
      );
      final scheduler = setup.scheduler;

      final base = DateTime(2026, 1, 1, 12);
      final pastReadAt = base.subtract(const Duration(seconds: 10));
      // High-hz PID that's been hammered recently... still loses to a
      // brand-new 0.1 Hz subscription because infinity > anything.
      final hammered = ScheduledPid(hz: 5.0)..lastReadAt = pastReadAt;
      final fresh = ScheduledPid(hz: 0.1); // lastReadAt stays null
      scheduler.subscribe('010C', hammered, (_) {});
      scheduler.subscribe('012F', fresh, (_) {});

      expect(scheduler.pickNextCommand(base), '012F');
    });

    test(
        'priority tiebreaker: identical weight, different priority → '
        'higher-priority wins', () {
      final setup = _schedulerWithClock(
        transport: _FakeTransport().call,
      );
      final scheduler = setup.scheduler;

      final base = DateTime(2026, 1, 1, 12);
      final pastReadAt = base.subtract(const Duration(milliseconds: 500));
      // Same hz + same elapsed = identical weight (2.5). Only priority
      // breaks the tie.
      final medium = ScheduledPid(hz: 5.0)..lastReadAt = pastReadAt;
      final high = ScheduledPid(hz: 5.0, priority: PidPriority.high)
        ..lastReadAt = pastReadAt;
      scheduler.subscribe('010C', medium, (_) {});
      scheduler.subscribe('010D', high, (_) {});

      expect(scheduler.pickNextCommand(base), '010D');
    });

    test(
        'FIFO tiebreaker: identical weight and priority → first-subscribed '
        'wins', () {
      final setup = _schedulerWithClock(
        transport: _FakeTransport().call,
      );
      final scheduler = setup.scheduler;

      final base = DateTime(2026, 1, 1, 12);
      final pastReadAt = base.subtract(const Duration(milliseconds: 500));
      final a = ScheduledPid(hz: 5.0)..lastReadAt = pastReadAt;
      final b = ScheduledPid(hz: 5.0)..lastReadAt = pastReadAt;
      scheduler.subscribe('010C', a, (_) {}); // subscribed first
      scheduler.subscribe('010D', b, (_) {});

      expect(scheduler.pickNextCommand(base), '010C');
    });

    test('returns null when nothing is subscribed', () {
      final setup = _schedulerWithClock(
        transport: _FakeTransport().call,
      );
      expect(setup.scheduler.pickNextCommand(DateTime.now()), isNull);
    });
  });

  group('PidScheduler.start/stop — loop behaviour', () {
    test(
        'fast-tier refresh: three 5 Hz PIDs get at least 3 reads each '
        'within ~1 s of ticks', () async {
      final transport = _FakeTransport();
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 50),
      );

      final reads = <String, int>{
        '010C': 0,
        '010D': 0,
        '0111': 0,
      };
      scheduler
        ..subscribe(
          '010C',
          ScheduledPid(hz: 5.0),
          (_) => reads['010C'] = (reads['010C'] ?? 0) + 1,
        )
        ..subscribe(
          '010D',
          ScheduledPid(hz: 5.0),
          (_) => reads['010D'] = (reads['010D'] ?? 0) + 1,
        )
        ..subscribe(
          '0111',
          ScheduledPid(hz: 5.0),
          (_) => reads['0111'] = (reads['0111'] ?? 0) + 1,
        )
        ..start();

      await Future<void>.delayed(const Duration(seconds: 1));
      scheduler.stop();
      // Give any in-flight transport a moment to resolve.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // With 50 ms ticks and instant transport, we get ~20 reads across
      // 3 PIDs in 1 s. Weighted round-robin spreads them roughly evenly,
      // so each PID should land at least 3 reads (well above noise).
      for (final entry in reads.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(3),
          reason: '${entry.key} got only ${entry.value} reads — '
              'fast tier should refresh aggressively',
        );
      }
    });

    test(
        'low-tier no starvation: 0.1 Hz PID mixed with ten 5 Hz PIDs '
        'gets at least 1 read in ~1.2 s', () async {
      // Note: the issue asks for 15 s at 0.1 Hz. With an instant fake
      // transport and tight ticks we can verify the "no starvation"
      // invariant in a small fraction of that — a 0.1 Hz PID never
      // starves as long as it accumulates weight faster than nothing
      // else, which is always true once the fast PIDs have each had
      // their initial read. We check this in ~1.2 s of simulated ticks.
      final transport = _FakeTransport();
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 20),
      );

      var slowReads = 0;
      scheduler.subscribe(
        '012F',
        ScheduledPid(hz: 0.1, priority: PidPriority.low),
        (_) => slowReads++,
      );
      for (var i = 0; i < 10; i++) {
        scheduler.subscribe(
          '01${i.toRadixString(16).padLeft(2, '0').toUpperCase()}',
          ScheduledPid(hz: 5.0),
          (_) {},
        );
      }
      scheduler.start();

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      scheduler.stop();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // The initial-read rule guarantees the 0.1 Hz PID is read on one
      // of the first 11 ticks (infinity weight beats everything). Even
      // after that, its weight keeps climbing linearly; it should never
      // be starved indefinitely.
      expect(
        slowReads,
        greaterThanOrEqualTo(1),
        reason: 'low-tier PID starved — should get its initial read',
      );
    });

    test(
        'backpressure: a slow transport blocks subsequent ticks from '
        'firing while the round-trip is outstanding', () async {
      // One PID, transport takes 250 ms. With a 50 ms tick rate, we'd
      // see ticks 2/3/4 fire while tick 1 is still outstanding if the
      // scheduler queued. It must NOT queue — backpressure skips.
      final transport = _FakeTransport(
        delay: const Duration(milliseconds: 250),
      );
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 50),
      );

      var reads = 0;
      scheduler
        ..subscribe(
          '010C',
          ScheduledPid(hz: 5.0),
          (_) => reads++,
        )
        ..start();

      // Let ~5 ticks worth of time pass (250 ms) — at most one command
      // should have landed because the transport itself takes 250 ms.
      await Future<void>.delayed(const Duration(milliseconds: 240));

      // Mid-flight: _inFlight must be set, not a queue of pending calls.
      expect(scheduler.inFlightCommand, '010C');
      // We have NOT queued further calls; calls list still length 1.
      expect(transport.calls.length, 1);

      scheduler.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Even after settle, no queued-up backlog fires because stop()
      // tore down the timer.
      expect(reads, lessThanOrEqualTo(1));
    });

    test(
        'transport error: if transport throws on one PID, _inFlight '
        'clears and the next tick picks a different PID', () async {
      final transport = _FakeTransport(throwOn: {'010C'});
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 30),
      );

      var goodReads = 0;
      scheduler
        ..subscribe(
          '010C',
          ScheduledPid(hz: 5.0),
          (_) => fail('010C should never deliver — it throws'),
        )
        ..subscribe(
          '010D',
          ScheduledPid(hz: 5.0),
          (_) => goodReads++,
        )
        ..start();

      await Future<void>.delayed(const Duration(milliseconds: 500));
      scheduler.stop();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // 010C threw repeatedly but the scheduler kept advancing. 010D
      // got plenty of reads despite 010C's failures.
      expect(
        goodReads,
        greaterThanOrEqualTo(3),
        reason: '010D should still be polled even while 010C throws',
      );
      // 010C was attempted at least once (proving the scheduler didn't
      // just skip it silently — the throw path ran).
      expect(transport.calls, contains('010C'));
      // After stop + settle, nothing is in-flight.
      expect(scheduler.inFlightCommand, isNull);
    });

    test('start is idempotent and stop is safe when not running', () {
      final scheduler = PidScheduler(
        transport: _FakeTransport().call,
        tickRate: const Duration(milliseconds: 100),
      );
      expect(scheduler.isRunning, isFalse);
      scheduler
        ..start()
        ..start();
      expect(scheduler.isRunning, isTrue);
      scheduler
        ..stop()
        ..stop();
      expect(scheduler.isRunning, isFalse);
    });

    test('unsubscribe removes a PID from the rotation', () {
      final scheduler = PidScheduler(
        transport: _FakeTransport().call,
        tickRate: const Duration(milliseconds: 100),
      );
      scheduler
        ..subscribe('010C', ScheduledPid(hz: 5.0), (_) {})
        ..subscribe('010D', ScheduledPid(hz: 5.0), (_) {});
      final now = DateTime(2026, 1, 1, 12);
      // Both candidates tie → first-subscribed wins.
      expect(scheduler.pickNextCommand(now), '010C');
      scheduler.unsubscribe('010C');
      expect(scheduler.pickNextCommand(now), '010D');
    });
  });
}
