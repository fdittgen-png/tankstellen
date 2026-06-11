// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/pid_scheduler.dart';
import '../../../helpers/silence_error_logger.dart';

/// Captures every `errorLogger.log` call routed through the foreground
/// recorder seam, without standing up Hive / Riverpod (#2379). Mirrors
/// the fake in `test/core/logging/error_logger_test.dart`.
class _CaptureRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

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
  silenceErrorLoggerSpool();
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

  // ── #2671 — drop-awareness: pause gates dispatch, resume re-enables ──
  //
  // On a detected drop the DroppedSessionManager pauses the scheduler so it
  // stops dispatching PIDs into a dead/flapping link (the field bug spammed
  // PlatformException(not connected) while the adapter flapped). The timer
  // may still be running, but a paused tick must NOT reach the transport.
  group('PidScheduler — pause/resume drop-awareness (#2671)', () {
    test(
        'a paused scheduler does NOT dispatch even with the timer running '
        '(no transport call)', () async {
      final transport = _FakeTransport();
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 10),
      );
      scheduler.subscribe('010C', ScheduledPid(hz: 5.0), (_) {});
      scheduler
        ..start()
        ..pause();

      // Let many ticks fire while paused.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await Future<void>.delayed(Duration.zero);

      expect(transport.calls, isEmpty,
          reason: 'a paused tick must short-circuit before dispatch');
      expect(scheduler.inFlightCommand, isNull);

      scheduler.stop();
    });

    test('resume() re-enables dispatch after a pause', () async {
      final transport = _FakeTransport();
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 10),
      );
      scheduler.subscribe('010C', ScheduledPid(hz: 5.0), (_) {});
      scheduler
        ..start()
        ..pause();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(transport.calls, isEmpty);

      scheduler.resume();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await Future<void>.delayed(Duration.zero);
      scheduler.stop();
      await Future<void>.delayed(Duration.zero);

      expect(transport.calls, isNotEmpty,
          reason: 'resume() must re-open dispatch');
    });

    test(
        'resume() resets failure / backoff counters so a recovered link '
        'starts clean', () async {
      var fakeNow = DateTime(2026, 1, 1, 12);
      var failing = true;
      Future<String> transport(String command) async {
        if (failing) throw Exception('timeout');
        return '41 0C 00>';
      }

      final scheduler = PidScheduler(
        transport: transport,
        tickRate: const Duration(milliseconds: 5),
        clock: () => fakeNow,
      );
      scheduler.subscribe('010C', ScheduledPid(hz: 5.0), (_) {});
      scheduler.start();

      // Drive the PID into backoff.
      for (var i = 0; i < 8 && scheduler.backedOffCount == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 8));
        await Future<void>.delayed(Duration.zero);
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      expect(scheduler.backedOffCount, 1,
          reason: 'consecutive failures must engage backoff first');

      // Drop → pause; reconnect → resume. resume() must wipe the failure
      // streak so the recovered link does not start already-backed-off.
      failing = false;
      scheduler
        ..pause()
        ..resume();
      expect(scheduler.backedOffCount, 0,
          reason: 'resume() must reset the per-PID failure/backoff state');

      scheduler.stop();
      await Future<void>.delayed(Duration.zero);
    });
  });

  // ── #2379 — transient-failure handling ──────────────────────────────
  //
  // These tests bind a capture recorder so they assert on what reached
  // `errorLogger.log`. They run with a deterministic clock so backoff /
  // rate-limit windows are advanced precisely rather than waited out.
  group('PidScheduler — transient per-PID transport failures (#2379)', () {
    late _CaptureRecorder recorder;

    setUp(() {
      errorLogger.resetForTest();
      recorder = _CaptureRecorder();
      errorLogger.testRecorderOverride = recorder;
    });

    tearDown(() {
      // Re-install the file-wide spool silencer that setUpAll wired, so
      // the selection-math group above keeps passing after these tests.
      errorLogger.resetForTest();
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {};
    });

    /// Lets at least one real periodic tick fire (the scheduler's
    /// `tickRate` is a real-wall-clock [Timer], even when the *weight*
    /// clock is faked) and then drains the microtask queue so the
    /// in-flight transport future + its catch/onResult settle before the
    /// assertion runs.
    Future<void> pump([Duration d = const Duration(milliseconds: 12)]) async {
      await Future<void>.delayed(d);
      await Future<void>.delayed(Duration.zero);
    }

    test(
        'a single per-PID timeout logs NO error trace (no flood) but the '
        'loop keeps advancing', () async {
      // 010C times out every read; 010D is healthy. With one failure the
      // PID is NOT yet backed off and — critically — nothing is logged.
      final transport = _FakeTransport(throwOn: {'010C'});
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 20),
      );
      var goodReads = 0;
      scheduler
        ..subscribe('010C', ScheduledPid(hz: 5.0), (_) {})
        ..subscribe('010D', ScheduledPid(hz: 5.0), (_) => goodReads++)
        ..start();

      // Just long enough for a couple of ticks — one or two 010C failures.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      scheduler.stop();
      await pump();

      expect(transport.calls, contains('010C'),
          reason: 'the failing PID was actually attempted');
      expect(goodReads, greaterThanOrEqualTo(1),
          reason: 'the healthy PID kept being polled');
      // THE fix: a transient per-PID transport failure produces zero
      // error traces (it used to log one per PID per tick).
      expect(recorder.calls, isEmpty,
          reason: 'transient per-PID failures must not be error-logged');
    });

    test(
        'an onResult handler bug IS still logged — under ErrorLayer.other, '
        'never storage', () async {
      final transport = _FakeTransport();
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 20),
      );
      scheduler
        ..subscribe('010C', ScheduledPid(hz: 5.0),
            (_) => throw StateError('handler bug'))
        ..start();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      scheduler.stop();
      await pump();

      expect(recorder.calls, isNotEmpty,
          reason: 'a real handler bug must stay visible in triage');
      final logged = recorder.calls.whereType<ContextualError>().toList();
      expect(logged, isNotEmpty);
      expect(logged.every((e) => e.layer == ErrorLayer.other), isTrue,
          reason: 'OBD2/BLE diagnostics must not carry the storage layer');
      expect(logged.any((e) => e.inner is StateError), isTrue);
    });

    test(
        'a PID backs off after N consecutive failures and resumes full '
        'cadence on the next success', () async {
      // `failing` gates the transport: while true the PID times out, when
      // flipped false it answers. This makes the test robust to tick
      // jitter — we assert the STATE transition, not an exact tick count.
      var fakeNow = DateTime(2026, 1, 1, 12);
      var failing = true;
      Future<String> transport(String command) async {
        if (failing) throw Exception('timeout');
        return '41 0C 00>';
      }

      final scheduler = PidScheduler(
        transport: transport,
        tickRate: const Duration(milliseconds: 5),
        clock: () => fakeNow,
      );
      var reads = 0;
      scheduler.subscribe('010C', ScheduledPid(hz: 5.0), (_) => reads++);
      scheduler.start();

      // Pump until the PID has accumulated ≥ N consecutive failures and
      // engaged backoff. (Advancing fakeNow keeps successive reads
      // distinct so the single PID keeps winning selection.)
      for (var i = 0; i < 6 && scheduler.backedOffCount == 0; i++) {
        await pump();
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      expect(scheduler.backedOffCount, 1,
          reason: 'N consecutive failures must engage backoff');
      expect(reads, 0, reason: 'nothing answered yet');

      // Adapter recovers. While backed off the PID polls at ~1/30 Hz, so
      // a sub-window gap would NOT select it — but a 31 s gap clears its
      // backoff weight and it is retried, succeeds, and resets.
      failing = false;
      fakeNow = fakeNow.add(const Duration(seconds: 31));
      await pump();
      expect(reads, greaterThanOrEqualTo(1),
          reason: 'a backed-off PID is still retried, just rarely');
      expect(scheduler.backedOffCount, 0,
          reason: 'a single success resets the failure streak → full cadence');

      scheduler.stop();
      await pump();
      expect(recorder.calls, isEmpty,
          reason: 'one dead PID (< threshold) never error-logs');
    });

    test(
        'healthy PIDs are NOT starved while one PID is permanently dead',
        () async {
      // 010C always fails; 010D + 0111 are healthy. The dead PID must not
      // crowd out the healthy ones once it is backed off.
      final transport = _FakeTransport(throwOn: {'010C'});
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 10),
      );
      final reads = <String, int>{'010D': 0, '0111': 0};
      scheduler
        ..subscribe('010C', ScheduledPid(hz: 5.0), (_) {})
        ..subscribe('010D', ScheduledPid(hz: 5.0),
            (_) => reads['010D'] = reads['010D']! + 1)
        ..subscribe('0111', ScheduledPid(hz: 5.0),
            (_) => reads['0111'] = reads['0111']! + 1)
        ..start();

      await Future<void>.delayed(const Duration(milliseconds: 600));
      scheduler.stop();
      await pump();

      for (final entry in reads.entries) {
        expect(entry.value, greaterThanOrEqualTo(3),
            reason: '${entry.key} starved by the dead 010C — backoff failed');
      }
    });

    test(
        'the aggregated "adapter unresponsive" diagnostic logs at most ONE '
        'ERROR per unresponsive EPISODE — not per tick, not per window (#2524)',
        () async {
      // #2524 — reclassification: a known-unresponsive adapter must NOT
      // spool a per-tick ERROR. At most one real ERROR is logged on the
      // TRANSITION into the unresponsive state; while it persists, the
      // aggregate is a debugPrint breadcrumb only. The errorlog_9 field
      // report showed 39× TimeoutException + 6× StateError flooding the
      // user error log from this single site after an in-trip reconnect.
      var fakeNow = DateTime(2026, 1, 1, 12);
      Future<String> transport(String command) async {
        throw Exception('timeout');
      }

      final scheduler = PidScheduler(
        transport: transport,
        tickRate: const Duration(milliseconds: 5),
        clock: () => fakeNow,
      );
      for (final pid in ['010C', '010D', '0105', '0106']) {
        scheduler.subscribe(pid, ScheduledPid(hz: 5.0), (_) {});
      }
      scheduler.start();

      // Pump ~40 ticks across ~10 s of simulated time. All four PIDs back
      // off and STAY backed off (one continuous episode). The old per-tick
      // flood would log dozens of ERROR traces here.
      for (var i = 0; i < 40; i++) {
        await pump();
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      scheduler.stop();
      await pump();

      final diagnostics = recorder.calls
          .whereType<ContextualError>()
          .where((e) => e.toString().contains('adapter unresponsive'))
          .toList();
      expect(diagnostics, hasLength(1),
          reason: 'one continuous unresponsive episode logs exactly one '
              'ERROR — on the transition in, never per-tick');
      expect(diagnostics.single.layer, ErrorLayer.other);

      // Cross the 30 s window WITHOUT recovering. Because the episode never
      // closed (the adapter stayed dead), NO second ERROR may fire — the
      // gate is now the episode transition, not the wall-clock window.
      fakeNow = fakeNow.add(const Duration(seconds: 31));
      scheduler.start();
      for (var i = 0; i < 8; i++) {
        await pump();
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      scheduler.stop();
      await pump();
      final stillSameEpisode = recorder.calls
          .whereType<ContextualError>()
          .where((e) => e.toString().contains('adapter unresponsive'))
          .toList();
      expect(stillSameEpisode, hasLength(1),
          reason: 'a still-open episode never re-logs, even across the '
              'diagnostic window — no per-tick flood (#2524)');
    });

    test(
        'a NEW unresponsive episode (after recovery) logs a fresh ERROR '
        '(#2524)', () async {
      // The episode latch closes when enough PIDs recover; a genuinely new
      // outage afterwards is still surfaced exactly once.
      var fakeNow = DateTime(2026, 1, 1, 12);
      var failing = true;
      Future<String> transport(String command) async {
        if (failing) throw Exception('timeout');
        return '41 ${command.substring(2, 4)} 00>';
      }

      final scheduler = PidScheduler(
        transport: transport,
        tickRate: const Duration(milliseconds: 5),
        clock: () => fakeNow,
      );
      for (final pid in ['010C', '010D', '0105', '0106']) {
        scheduler.subscribe(pid, ScheduledPid(hz: 5.0), (_) {});
      }
      scheduler.start();

      // Episode 1 — all PIDs dead → one ERROR.
      for (var i = 0; i < 30; i++) {
        await pump();
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      final afterEpisode1 = recorder.calls
          .whereType<ContextualError>()
          .where((e) => e.toString().contains('adapter unresponsive'))
          .length;
      expect(afterEpisode1, 1, reason: 'episode 1 logs exactly one ERROR');

      // Recover — every PID answers, so backedOffCount drops below the
      // threshold and the episode latch closes. Pump generously so the
      // round-robin reaches every PID at least once.
      failing = false;
      for (var i = 0; i < 80; i++) {
        await pump();
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      expect(scheduler.backedOffCount, lessThan(3),
          reason: 'a stretch of successes must drop the backed-off count '
              'below the threshold so the unresponsive episode latch closes');

      // Episode 2 — the adapter dies again well past the 30 s window. A
      // genuinely new outage must surface a second ERROR.
      failing = true;
      fakeNow = fakeNow.add(const Duration(seconds: 31));
      for (var i = 0; i < 30; i++) {
        await pump();
        fakeNow = fakeNow.add(const Duration(milliseconds: 250));
      }
      scheduler.stop();
      await pump();

      final total = recorder.calls
          .whereType<ContextualError>()
          .where((e) => e.toString().contains('adapter unresponsive'))
          .length;
      expect(total, 2,
          reason: 'a fresh unresponsive episode after recovery logs a '
              'second ERROR — one per episode, not per tick (#2524)');
    });
  });

  // ── #2457 — 4-tier cadence + bandwidth governor ─────────────────────
  group('PidScheduler — cadence tiers + weight (#2457)', () {
    test('the RR weight scales with the configured hz across all four tiers',
        () {
      // One PID per tier, all read the same 1 s ago → weight = elapsed ×
      // hz, so the order is purely the hz ranking. This proves the four
      // tiers ride the same weighted-RR and a deeper tier never out-
      // competes a shallower one in steady state.
      final setup = _schedulerWithClock(transport: _FakeTransport().call);
      final scheduler = setup.scheduler;
      final base = DateTime(2026, 1, 1, 12);
      final readAt = base.subtract(const Duration(seconds: 1));
      scheduler.subscribe(
          '010C',
          ScheduledPid(hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics)
            ..lastReadAt = readAt,
          (_) {});
      scheduler.subscribe(
          '0144',
          ScheduledPid(hz: 2.0, tier: PidTier.mixture)..lastReadAt = readAt,
          (_) {});
      scheduler.subscribe(
          '0106',
          ScheduledPid(hz: 0.5, tier: PidTier.slowCorrection)
            ..lastReadAt = readAt,
          (_) {});
      scheduler.subscribe(
          '012F',
          ScheduledPid(hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext)
            ..lastReadAt = readAt,
          (_) {});

      // Dynamics (5 Hz) has the largest weight → wins.
      expect(scheduler.pickNextCommand(base), '010C');
    });

    test('a tier default does not gate selection — only weight does', () {
      // A high-priority thermal PID (deep tier) still loses to a medium
      // dynamics PID, proving the tier is metadata, not a hard override.
      final setup = _schedulerWithClock(transport: _FakeTransport().call);
      final scheduler = setup.scheduler;
      final base = DateTime(2026, 1, 1, 12);
      final readAt = base.subtract(const Duration(seconds: 1));
      scheduler.subscribe(
          '0105',
          ScheduledPid(hz: 0.1, priority: PidPriority.high, tier: PidTier.thermalContext)
            ..lastReadAt = readAt,
          (_) {});
      scheduler.subscribe(
          '010C',
          ScheduledPid(hz: 5.0, tier: PidTier.dynamics)..lastReadAt = readAt,
          (_) {});
      expect(scheduler.pickNextCommand(base), '010C');
    });
  });

  group('PidScheduler — bandwidth governor end-to-end (#2457)', () {
    test(
        'a slow link demotes the lowest tier while RPM / speed keep their '
        'effective-hz, restored once headroom returns', () async {
      // Per-read transport delay is the slow-link knob. `slow` (200 ms per
      // read) means even the two 5 Hz dynamics PIDs can only share ~5
      // reads/s total — ~2.5 Hz each, below the 3 Hz floor — so the
      // governor must demote an expendable PID. Flipping to fast (0 ms)
      // gives ample headroom and the demotion is unwound.
      var slow = true;
      Future<String> transport(String command) async {
        if (slow) await Future<void>.delayed(const Duration(milliseconds: 200));
        final pid = command.substring(2, 4);
        return '41 $pid 00>';
      }

      final scheduler = PidScheduler(
        transport: transport,
        tickRate: const Duration(milliseconds: 5),
      );
      final reads = <String, int>{'010C': 0, '010D': 0, '012F': 0, '0105': 0};
      scheduler
        ..subscribe('010C',
            ScheduledPid(hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics),
            (_) => reads['010C'] = reads['010C']! + 1)
        ..subscribe('010D',
            ScheduledPid(hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics),
            (_) => reads['010D'] = reads['010D']! + 1)
        ..subscribe('0105',
            ScheduledPid(hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext),
            (_) => reads['0105'] = reads['0105']! + 1)
        ..subscribe('012F',
            ScheduledPid(hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext),
            (_) => reads['012F'] = reads['012F']! + 1)
        ..start();

      // Run the slow link long enough for the governor's 4 s window +
      // 2 s cooldown to fire at least once.
      await Future<void>.delayed(const Duration(seconds: 8));
      // A thermal-tier PID is demoted to protect the dynamics tier; the
      // dynamics PIDs are never demoted.
      expect(scheduler.demotedCommands, isNotEmpty,
          reason: 'the slow link should have demoted an expendable PID');
      expect(scheduler.demotedCommands.any((c) => c == '012F' || c == '0105'),
          isTrue,
          reason: 'only thermal-tier PIDs are demoted on a slow link');
      expect(scheduler.demotedCommands, isNot(contains('010C')));
      expect(scheduler.demotedCommands, isNot(contains('010D')));

      // Dynamics PIDs still got the lion's share of the budget.
      final dynamicsReads = reads['010C']! + reads['010D']!;
      final thermalReads = reads['0105']! + reads['012F']!;
      expect(dynamicsReads, greaterThan(thermalReads),
          reason: 'RPM / speed must out-poll the demoted thermal tier');

      // Link recovers → the governor restores the demoted PID.
      slow = false;
      await Future<void>.delayed(const Duration(seconds: 8));
      scheduler.stop();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(scheduler.demotedCommands, isEmpty,
          reason: 'headroom returned → demotions are unwound');
    });
  });
}
