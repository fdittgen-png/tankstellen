// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'scheduled_pid.dart';

/// Read-only snapshot of the bandwidth governor's state (#2457), exposed
/// through `PidScheduler.governorState` so the comm-diagnostics overlay
/// (#2468) can surface it without taking a UI dependency. Purely
/// descriptive — nothing here feeds back into selection.
@immutable
class GovernorState {
  const GovernorState({
    required this.achievedReadsPerSecond,
    required this.dynamicsEffectiveHz,
    required this.demotedCommands,
  });

  /// Achieved total reads/second across all PIDs over the rolling window.
  /// 0 before any read completes.
  final double achievedReadsPerSecond;

  /// Effective refresh rate (reads/s) the slowest dynamics-tier PID is
  /// actually achieving over the window — the metric the governor floors.
  /// `double.infinity` when no dynamics PID has completed two reads yet
  /// (not enough data to judge, so it never trips a demotion prematurely).
  final double dynamicsEffectiveHz;

  /// Commands currently demoted (target hz halved) to claw back budget
  /// for the dynamics tier. Empty when the link has headroom. Unmodifiable.
  final Set<String> demotedCommands;
}

/// Bandwidth governor for the `PidScheduler`'s weighted round-robin
/// (#2457).
///
/// On a fast adapter the four cadence tiers all hit their target hz with
/// budget to spare. On a slow ELM327 clone the *total* reads/second the
/// link sustains is the binding constraint, and because selection weight
/// grows with staleness, low-tier PIDs would otherwise nibble ticks away
/// from RPM / speed. This governor measures the achieved per-PID hz over a
/// rolling window and, when the [PidTier.dynamics] tier drops below
/// [dynamicsFloorHz], **demotes** the most-expendable PID (deepest tier
/// first) by halving its target hz — freeing budget for the dynamics
/// tier — then **restores** it once the tier clears [_dynamicsRestoreHz]
/// with headroom (hysteresis prevents flapping). The dynamics tier is
/// never itself demoted, so RPM / speed effective-hz never starves.
///
/// It owns no transport and no timer: the scheduler feeds it
/// [recordRead] completions and calls [evaluate] each tick, reads
/// [isDemoted] when computing selection weight, and exposes [state]
/// verbatim. That keeps the scheduler's selection core small and this
/// policy independently unit-testable.
class PidBandwidthGovernor {
  PidBandwidthGovernor({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// Effective per-PID floor (reads/s) the dynamics tier must hold. If
  /// the slowest dynamics PID drops below this the governor demotes one
  /// expendable PID. 3 Hz keeps RPM / speed responsive for harsh-accel
  /// detection while leaving slack below the 5 Hz target for jitter.
  ///
  /// Exposed (read-only) so the comm-diagnostics scheduler tee (#2468) can
  /// flag a starvation event when the MEASURED dynamics rate falls below
  /// the same floor the governor defends.
  static const double dynamicsFloorHz = 3.0;

  /// Hysteresis ceiling: an expendable PID is only *restored* once the
  /// dynamics tier comfortably clears the floor, so the governor doesn't
  /// flap demote↔restore tick-by-tick around the threshold.
  static const double _dynamicsRestoreHz = 4.0;

  /// Rolling window over which achieved reads/s (total and per-PID) are
  /// measured. Long enough to smooth single-round-trip jitter, short
  /// enough that the governor reacts within a few seconds.
  static const Duration _governorWindow = Duration(seconds: 4);

  /// Minimum gap between governor adjustments. One demotion/restore per
  /// this interval lets the window re-measure the new steady state before
  /// the next move — prevents over-correcting on a single slow window.
  static const Duration _governorCooldown = Duration(seconds: 2);

  /// Factor a demoted PID's target hz is multiplied by. Halving roughly
  /// doubles its inter-read gap, handing the freed budget to faster tiers.
  static const double demotionFactor = 0.5;

  final DateTime Function() _clock;

  /// Per-command policy metadata, registered alongside the scheduler
  /// subscription so the governor can rank demotion candidates without a
  /// reverse map back into the scheduler.
  final Map<String, _PidMeta> _meta = <String, _PidMeta>{};

  /// Completion timestamps of every read (success OR failure) inside the
  /// rolling [_governorWindow], used to compute achieved total reads/s.
  /// Trimmed each completion. Oldest-first.
  final List<DateTime> _readTimestamps = <DateTime>[];

  /// Commands currently demoted (target hz × [demotionFactor]). Empty
  /// whenever the link has headroom.
  final Set<String> _demoted = <String>{};

  /// When the governor last demoted or restored a PID, to honour
  /// [_governorCooldown]. Null until the first adjustment.
  DateTime? _lastActionAt;

  /// Most recent achieved reads/s across all PIDs (rolling window).
  double _achievedReadsPerSecond = 0.0;

  /// Register (or replace) the policy metadata for [command]. Called from
  /// `PidScheduler.subscribe`.
  void register(
    String command, {
    required PidTier tier,
    required PidPriority priority,
    required double hz,
  }) {
    _meta[command] = _PidMeta(tier: tier, priority: priority, hz: hz);
  }

  /// Forget [command] entirely and drop any demotion held against it, so a
  /// re-subscribe starts clean. Called from `PidScheduler.unsubscribe`.
  void unregister(String command) {
    _meta.remove(command);
    _demoted.remove(command);
  }

  /// Whether [command] is currently demoted. The scheduler multiplies the
  /// PID's target hz by [demotionFactor] when this is true.
  bool isDemoted(String command) => _demoted.contains(command);

  /// Stamp a completed read (success OR failure) for [command] at [at]
  /// into the global + per-PID rolling windows, trimming anything older
  /// than [_governorWindow] and refreshing the cached total reads/s.
  void recordRead(String command, DateTime at) {
    _readTimestamps.add(at);
    _meta[command]?.readTimestamps.add(at);
    final cutoff = at.subtract(_governorWindow);
    _trimBefore(_readTimestamps, cutoff);
    final meta = _meta[command];
    if (meta != null) _trimBefore(meta.readTimestamps, cutoff);
    final span = _governorWindow.inMilliseconds / 1000.0;
    _achievedReadsPerSecond = _readTimestamps.length / span;
  }

  /// Core governor step, run after each completed read. On a slow link
  /// where the dynamics tier has dropped below [dynamicsFloorHz], demote
  /// the single most-expendable PID (deepest tier first). When the tier
  /// has recovered above [_dynamicsRestoreHz] with headroom, restore the
  /// least-expendable demoted PID. At most one move per [_governorCooldown]
  /// so the window can re-measure between adjustments. The dynamics tier
  /// is never itself eligible for demotion, so RPM / speed never starve.
  void evaluate() {
    if (_meta.isEmpty) return;
    final now = _clock();
    final last = _lastActionAt;
    if (last != null && now.difference(last) < _governorCooldown) return;

    final dynamicsHz = _dynamicsEffectiveHz();
    // No measurable dynamics rate yet (cold start) → nothing to protect.
    if (dynamicsHz == double.infinity) return;

    if (dynamicsHz < dynamicsFloorHz) {
      final victim = _nextDemotionCandidate();
      if (victim != null) {
        _demoted.add(victim);
        _lastActionAt = now;
      }
    } else if (dynamicsHz >= _dynamicsRestoreHz && _demoted.isNotEmpty) {
      final restore = _nextRestoreCandidate();
      if (restore != null) {
        _demoted.remove(restore);
        _lastActionAt = now;
      }
    }
  }

  /// Read-only snapshot for the comm-diagnostics overlay (#2468).
  GovernorState get state => GovernorState(
        achievedReadsPerSecond: _achievedReadsPerSecond,
        dynamicsEffectiveHz: _dynamicsEffectiveHz(),
        demotedCommands: Set<String>.unmodifiable(_demoted),
      );

  /// Effective hz the slowest dynamics-tier PID is achieving over the
  /// rolling window. The *slowest* (min) because if any one dynamics PID
  /// is being starved the whole tier is — flooring the worst case
  /// protects RPM and speed equally. Returns [double.infinity] when no
  /// dynamics PID has two timestamped reads yet (not enough data to judge,
  /// so the governor never demotes on a cold start).
  double _dynamicsEffectiveHz() {
    var slowest = double.infinity;
    for (final entry in _meta.entries) {
      if (entry.value.tier != PidTier.dynamics) continue;
      final hz = _achievedHzFor(entry.value);
      if (hz != null && hz < slowest) slowest = hz;
    }
    return slowest;
  }

  /// Achieved reads/s for [meta] over the window, or null when it has
  /// fewer than two timestamped reads (one read can't define a rate).
  double? _achievedHzFor(_PidMeta meta) {
    final stamps = meta.readTimestamps;
    if (stamps.length < 2) return null;
    final spanMs =
        stamps.last.difference(stamps.first).inMicroseconds / 1000.0;
    if (spanMs <= 0) return null;
    // (n − 1) intervals across the measured span.
    return (stamps.length - 1) / (spanMs / 1000.0);
  }

  /// The most-expendable not-yet-demoted, non-dynamics command, or null
  /// when nothing is left to demote. Ranking (descending expendability):
  /// deeper [PidTier], then lower [PidPriority], then larger configured hz.
  String? _nextDemotionCandidate() {
    String? best;
    _PidMeta? bestMeta;
    for (final entry in _meta.entries) {
      final m = entry.value;
      if (m.tier == PidTier.dynamics) continue;
      if (_demoted.contains(entry.key)) continue;
      if (bestMeta == null || _moreExpendable(m, bestMeta)) {
        best = entry.key;
        bestMeta = m;
      }
    }
    return best;
  }

  /// The least-expendable currently-demoted command (restored first so we
  /// unwind in reverse demotion order), or null when none are demoted.
  String? _nextRestoreCandidate() {
    String? best;
    _PidMeta? bestMeta;
    for (final entry in _meta.entries) {
      if (!_demoted.contains(entry.key)) continue;
      final m = entry.value;
      if (bestMeta == null || _moreExpendable(bestMeta, m)) {
        best = entry.key;
        bestMeta = m;
      }
    }
    return best;
  }

  /// True when [a] is more expendable than [b]: deeper tier, then lower
  /// priority, then faster configured hz (a faster optional PID costs the
  /// most budget, so it sheds load first).
  static bool _moreExpendable(_PidMeta a, _PidMeta b) {
    if (a.tier.index != b.tier.index) return a.tier.index > b.tier.index;
    if (a.priority.index != b.priority.index) {
      return a.priority.index > b.priority.index;
    }
    return a.hz > b.hz;
  }

  /// Drop leading entries in [stamps] strictly older than [cutoff]. The
  /// list is oldest-first so a single front-prefix scan suffices.
  static void _trimBefore(List<DateTime> stamps, DateTime cutoff) {
    var drop = 0;
    while (drop < stamps.length && stamps[drop].isBefore(cutoff)) {
      drop++;
    }
    if (drop > 0) stamps.removeRange(0, drop);
  }
}

/// Per-command policy + rolling read window the governor ranks on.
class _PidMeta {
  _PidMeta({required this.tier, required this.priority, required this.hz});

  final PidTier tier;
  final PidPriority priority;
  final double hz;

  /// Completion timestamps inside the rolling window (oldest-first).
  final List<DateTime> readTimestamps = <DateTime>[];
}
