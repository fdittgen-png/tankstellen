// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_bandwidth_governor.dart';
import 'package:tankstellen/features/consumption/data/obd2/scheduled_pid.dart';

/// Unit tests for the #2457 bandwidth governor in isolation from the
/// scheduler — driving it with synthetic read completions on a faked clock
/// so the demote / restore policy is exercised deterministically.
void main() {
  // A fast dynamics-tier read: stamp `count` completions `gapMs` apart so
  // the governor measures (count−1)/(span) reads/s for that PID.
  void feedReads(
    PidBandwidthGovernor g,
    String command, {
    required DateTime start,
    required int count,
    required int gapMs,
  }) {
    for (var i = 0; i < count; i++) {
      g.recordRead(command, start.add(Duration(milliseconds: gapMs * i)));
    }
  }

  group('PidBandwidthGovernor — tier ranking + demotion order', () {
    test(
        'a slow dynamics tier demotes the deepest tier first, sparing the '
        'dynamics tier entirely', () {
      var now = DateTime(2026, 1, 1, 12);
      final g = PidBandwidthGovernor(clock: () => now);
      g
        ..register('010C', tier: PidTier.dynamics, priority: PidPriority.high, hz: 5)
        ..register('0144', tier: PidTier.mixture, priority: PidPriority.medium, hz: 2)
        ..register('0106',
            tier: PidTier.slowCorrection, priority: PidPriority.medium, hz: 0.5)
        ..register('012F',
            tier: PidTier.thermalContext, priority: PidPriority.low, hz: 0.1);

      // Dynamics PID achieving only ~2 Hz (500 ms gaps) — below the 3 Hz
      // floor. Five reads → 4 intervals × 500 ms = 2 s span → 2 Hz.
      feedReads(g, '010C', start: now, count: 5, gapMs: 500);
      now = now.add(const Duration(seconds: 3)); // clear the cooldown
      g.evaluate();

      // Deepest tier (thermalContext) sheds load first; dynamics never.
      expect(g.state.demotedCommands, contains('012F'));
      expect(g.state.demotedCommands, isNot(contains('010C')),
          reason: 'the dynamics tier must never be demoted');
    });

    test(
        'persistent starvation walks demotions up the tiers, deepest first, '
        'but stops short of the dynamics tier', () {
      var now = DateTime(2026, 1, 1, 12);
      final g = PidBandwidthGovernor(clock: () => now);
      g
        ..register('010C', tier: PidTier.dynamics, priority: PidPriority.high, hz: 5)
        ..register('0144', tier: PidTier.mixture, priority: PidPriority.medium, hz: 2)
        ..register('012F',
            tier: PidTier.thermalContext, priority: PidPriority.low, hz: 0.1);

      // Keep the dynamics tier perpetually slow (2 Hz) and re-evaluate
      // across several cooldown windows.
      for (var round = 0; round < 3; round++) {
        feedReads(g, '010C', start: now, count: 5, gapMs: 500);
        now = now.add(const Duration(seconds: 3));
        g.evaluate();
      }

      // Both optional non-dynamics PIDs end up demoted (thermal before
      // mixture), but 010C stays at full cadence.
      expect(g.state.demotedCommands, containsAll(<String>{'012F', '0144'}));
      expect(g.state.demotedCommands, isNot(contains('010C')));
    });
  });

  group('PidBandwidthGovernor — restore on recovered headroom', () {
    test('a demoted PID is restored once the dynamics tier clears the ceiling',
        () {
      var now = DateTime(2026, 1, 1, 12);
      final g = PidBandwidthGovernor(clock: () => now);
      g
        ..register('010C', tier: PidTier.dynamics, priority: PidPriority.high, hz: 5)
        ..register('012F',
            tier: PidTier.thermalContext, priority: PidPriority.low, hz: 0.1);

      // 1) Slow link → demote.
      feedReads(g, '010C', start: now, count: 5, gapMs: 500); // 2 Hz
      now = now.add(const Duration(seconds: 3));
      g.evaluate();
      expect(g.state.demotedCommands, contains('012F'));

      // 2) Link recovers: dynamics PID now achieves 5 Hz (200 ms gaps) →
      // above the 4 Hz restore ceiling. The fresh window must contain only
      // the fast reads, so advance past the old slow stamps first.
      now = now.add(const Duration(seconds: 5));
      feedReads(g, '010C', start: now, count: 6, gapMs: 200); // 5 Hz
      now = now.add(const Duration(seconds: 3));
      g.evaluate();
      expect(g.state.demotedCommands, isEmpty,
          reason: 'headroom returned → the demoted PID is restored');
    });
  });

  group('PidBandwidthGovernor — exposed read-only state (#2468)', () {
    test('state surfaces achieved reads/s, dynamics hz and demotions', () {
      final now = DateTime(2026, 1, 1, 12);
      final g = PidBandwidthGovernor(clock: () => now);
      g.register('010C',
          tier: PidTier.dynamics, priority: PidPriority.high, hz: 5);

      // No reads yet → cold-start sentinels.
      expect(g.state.achievedReadsPerSecond, 0);
      expect(g.state.dynamicsEffectiveHz, double.infinity);
      expect(g.state.demotedCommands, isEmpty);

      // Two reads 200 ms apart → 5 Hz dynamics, 2 reads / 4 s window.
      feedReads(g, '010C', start: now, count: 2, gapMs: 200);
      expect(g.state.dynamicsEffectiveHz, closeTo(5.0, 0.001));
      expect(g.state.achievedReadsPerSecond, closeTo(2 / 4.0, 0.001));
    });

    test('unregister drops the demotion + clears it from state', () {
      var now = DateTime(2026, 1, 1, 12);
      final g = PidBandwidthGovernor(clock: () => now);
      g
        ..register('010C', tier: PidTier.dynamics, priority: PidPriority.high, hz: 5)
        ..register('012F',
            tier: PidTier.thermalContext, priority: PidPriority.low, hz: 0.1);
      feedReads(g, '010C', start: now, count: 5, gapMs: 500); // 2 Hz
      now = now.add(const Duration(seconds: 3));
      g.evaluate();
      expect(g.state.demotedCommands, contains('012F'));

      g.unregister('012F');
      expect(g.state.demotedCommands, isEmpty);
    });
  });
}
