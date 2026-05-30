// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_session_diagnostic.dart';

/// Pure session-completeness summariser (#2469, Epic #2463) — the OBD2
/// analogue of the GPS sampling card.
///
/// Given a raw [Obd2SessionDiagnostic] (per-PID rows carrying [targetHz] +
/// [tier] + the ok count, and a [sessionActiveSeconds] term), it computes:
///
///   * `expectedReads = Σ(targetHz × activeSeconds)` across every PID;
///   * `achievedReads = Σ ok`;
///   * overall completeness% + per-tier completeness%;
///   * each PID's `effectiveHz = ok / activeSeconds` and (via the row's
///     [Obd2PidStat.targetHzAttainment] getter) its attainment ratio;
///   * `activeDutyCycle` = clamped achieved/expected;
///   * an emit-gap flag when any tier's attainment falls below
///     [Obd2CompletenessStats.emitGapThreshold].
///
/// Pure + framework-free: it takes a snapshot and returns a NEW snapshot
/// with the completeness fields + each row's [effectiveHz] filled in, so
/// it can be called from the collector on `snapshot()`/`endSession()` or
/// directly in a unit test. Re-entrant and side-effect-free.
///
/// When [sessionActiveSeconds] is 0 (a session that never polled) the
/// expected total is 0 and the percentages are 0 — never a divide-by-zero.
Obd2SessionDiagnostic summariseObd2Completeness(Obd2SessionDiagnostic raw) {
  final activeSeconds = raw.sessionActiveSeconds;
  if (raw.pidStats.isEmpty) {
    // No per-PID rows → nothing to summarise. Keep the snapshot but stamp
    // the (zero) completeness so callers always see a populated block.
    return raw.copyWith(
      expectedReads: 0,
      achievedReads: 0,
      completenessPercent: 0,
      completeness: const Obd2CompletenessStats(),
    );
  }

  var totalExpected = 0.0;
  var totalAchieved = 0;
  // Per-tier expected/achieved accumulators (keyed by the row's tier name;
  // un-tiered rows fold into the '' bucket but still count toward overall).
  final tierExpected = <String, double>{};
  final tierAchieved = <String, int>{};

  final filledRows = <String, Obd2PidStat>{};
  for (final entry in raw.pidStats.entries) {
    final row = entry.value;
    final expected = row.targetHz * activeSeconds;
    final effectiveHz =
        activeSeconds > 0 ? row.ok / activeSeconds : 0.0;
    filledRows[entry.key] = row.copyWith(effectiveHz: effectiveHz);

    totalExpected += expected;
    totalAchieved += row.ok;
    final tier = row.tier ?? '';
    tierExpected[tier] = (tierExpected[tier] ?? 0) + expected;
    tierAchieved[tier] = (tierAchieved[tier] ?? 0) + row.ok;
  }

  final overallPercent = _percent(totalAchieved, totalExpected);
  final perTierPercent = <String, double>{
    for (final tier in tierExpected.keys)
      if (tier.isNotEmpty)
        tier: _percent(tierAchieved[tier] ?? 0, tierExpected[tier] ?? 0),
  };

  // Active duty cycle: clamped achieved/expected (a session that hit every
  // target reads 1.0; a stalled link reads near 0). Clamp >1 over-polling
  // back to 1 — duty cycle is "was the link busy", not raw attainment.
  final dutyCycle = totalExpected <= 0
      ? 0.0
      : (totalAchieved / totalExpected).clamp(0.0, 1.0).toDouble();

  // Emit-gap: any TIER whose attainment dropped below the threshold means
  // the scheduler skipped a meaningful share of that tier's expected reads.
  final emitGap = perTierPercent.values.any(
    (pct) => pct < Obd2CompletenessStats.emitGapThreshold * 100,
  );

  return raw.copyWith(
    pidStats: filledRows,
    expectedReads: totalExpected.round(),
    achievedReads: totalAchieved,
    completenessPercent: overallPercent,
    completeness: Obd2CompletenessStats(
      overallPercent: overallPercent,
      perTierPercent: perTierPercent,
      activeDutyCycle: dutyCycle,
      emitGapDetected: emitGap,
    ),
  );
}

/// `achieved / expected` as a 0–100 percentage, 0 when nothing was
/// expected (never a divide-by-zero).
double _percent(int achieved, double expected) =>
    expected <= 0 ? 0.0 : (achieved / expected) * 100.0;
