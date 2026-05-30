// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_diagnostic.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_scheduler.dart';
import '../../../../helpers/silence_error_logger.dart';

/// A transport that returns a canned reply per command, or NO DATA /
/// timeout for chosen commands, so the scheduler tee sees a mix of the
/// 5-way outcomes.
class _FakeTransport {
  _FakeTransport({this.noData = const {}, this.timeoutOn = const {}});

  final Set<String> noData;
  final Set<String> timeoutOn;
  final List<String> calls = <String>[];

  Future<String> call(String command) async {
    calls.add(command);
    if (timeoutOn.contains(command)) {
      throw TimeoutException('simulated timeout for $command');
    }
    if (noData.contains(command)) return 'NO DATA>';
    final pid = command.length >= 4 ? command.substring(2, 4) : '00';
    return '41 $pid 00 00>'; // positive hex line → ResponseClass.ok
  }
}

void main() {
  silenceErrorLoggerSpool();

  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  /// Run the scheduler against [transport] for [ticks] timer ticks at a
  /// short period, returning once it has settled.
  Future<void> runTicks(
    PidScheduler scheduler,
    int ticks, {
    Duration period = const Duration(milliseconds: 5),
  }) async {
    scheduler.start();
    // Each tick fires at most one command; wait long enough for the async
    // transport round-trips to land.
    await Future<void>.delayed(period * (ticks + 4));
    scheduler.stop();
    // Let any in-flight completion drain.
    await Future<void>.delayed(period * 2);
  }

  group('PidScheduler → comm-diagnostics tee (#2468)', () {
    test(
        'debugMode ON: per-PID 5-way + scheduler counters populate from a '
        'live mix of ok / NO-DATA', () async {
      Obd2CommDiagnostics.instance.enabled = true;
      Obd2CommDiagnostics.instance.beginSession(linkKind: 'ble');

      final transport = _FakeTransport(noData: {'0166'});
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 5),
      );
      // RPM (healthy, dynamics 5 Hz) + an unsupported PID (always NO DATA).
      scheduler.subscribe(
        '010C',
        ScheduledPid(hz: 5.0, tier: PidTier.dynamics),
        (_) {},
      );
      scheduler.subscribe(
        '0166',
        ScheduledPid(hz: 2.0, tier: PidTier.mixture),
        (_) {},
      );

      await runTicks(scheduler, 30);

      final snap = Obd2CommDiagnostics.instance.snapshot();
      // RPM resolved as OK at least once and carried its target Hz + tier.
      final rpm = snap.pidStats['010C']!;
      expect(rpm.ok, greaterThan(0));
      expect(rpm.targetHz, 5.0);
      expect(rpm.tier, 'dynamics');
      expect(rpm.latencyP50Ms, greaterThanOrEqualTo(0));
      // The unsupported PID NO-DATAs every time.
      final dead = snap.pidStats['0166']!;
      expect(dead.noData, greaterThan(0));
      expect(dead.ok, 0);
      // Scheduler health counters populated.
      expect(snap.scheduler.ticks, greaterThan(0));
      expect(snap.scheduler.tickRateHz, greaterThan(0));
    });

    test('debugMode ON: a timing-out PID accumulates timeout + backoff',
        () async {
      Obd2CommDiagnostics.instance.enabled = true;
      Obd2CommDiagnostics.instance.beginSession(linkKind: 'ble');

      final transport = _FakeTransport(timeoutOn: {'0105'});
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 5),
      );
      scheduler.subscribe(
        '0105',
        ScheduledPid(hz: 5.0, tier: PidTier.dynamics),
        (_) {},
      );

      await runTicks(scheduler, 40);

      final row = Obd2CommDiagnostics.instance.snapshot().pidStats['0105']!;
      expect(row.timeout, greaterThan(0));
      expect(row.ok, 0);
      // After ≥3 consecutive failures the PID is backed off + the streak is
      // reflected on the last result.
      expect(row.consecutiveFailures, greaterThanOrEqualTo(3));
      expect(row.backedOff, isTrue);
    });

    test(
        'debugMode OFF: the scheduler still polls but the collector stays '
        'the empty sentinel (pure no-op)', () async {
      // enabled defaults to false; begin a session anyway — disabled
      // beginSession is itself a no-op so there is no live session.
      Obd2CommDiagnostics.instance.beginSession(linkKind: 'ble');

      final transport = _FakeTransport();
      final scheduler = PidScheduler(
        transport: transport.call,
        tickRate: const Duration(milliseconds: 5),
      );
      scheduler.subscribe(
        '010C',
        ScheduledPid(hz: 5.0, tier: PidTier.dynamics),
        (_) {},
      );

      await runTicks(scheduler, 20);

      // The scheduler behaved normally — it polled the transport.
      expect(transport.calls, isNotEmpty);
      // …but nothing was recorded.
      expect(
        Obd2CommDiagnostics.instance.snapshot(),
        const Obd2SessionDiagnostic(),
      );
    });
  });
}
