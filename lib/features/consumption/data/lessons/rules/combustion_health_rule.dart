// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../../../domain/trip_recorder.dart';
import '../lesson_format.dart';

/// Lesson id for the combustion-health heuristic line (#2931). Stable,
/// non-localized.
const String combustionHealthLessonId = 'combustionHealth';

/// Coolant temperature (°C) at/above which the engine is considered warm
/// enough that the O2 sensors are active and the ECU runs **closed-loop**
/// (#2931). Canonical with `TripRecorder`'s cold-start warm threshold so
/// every surface agrees on "warmed up". Below this the trims are open-loop
/// guesses, not a mixture-error signal — we never coach on them.
const double kCombustionWarmCoolantC = 70.0;

/// Borderline total-fuel-trim magnitude (|STFT + LTFT|, percent) at/above
/// which the ECU is *noticeably* compensating to hit stoichiometry
/// (#2931). Below this the mixture is healthy; this is the floor for the
/// heuristic to consider a sample "compensating".
const double kCombustionTrimBorderlinePct = 10.0;

/// Marked total-fuel-trim magnitude (percent) at/above which the
/// compensation is large enough that a real mixture inefficiency is the
/// likely cause (#2931) — the wording escalates from "looks a little
/// off" to "looks rich/lean". Still a *heuristic*, never a diagnosis.
const double kCombustionTrimMarkedPct = 15.0;

/// Commanded equivalence ratio (λ, PID 0x44) at/below which the ECU is
/// deliberately running **rich** (#2931). 0.97 leaves a small dead-band
/// around stoichiometric (λ = 1.0) so sensor noise around stoich doesn't
/// read as enrichment; sustained values under it are real commanded
/// enrichment = wasted fuel.
const double kCombustionRichLambda = 0.97;

/// Minimum number of qualifying **warm, closed-loop** samples a signal
/// needs before the heuristic fires (#2931). A brief trim spike or one
/// enrichment tick must NOT trigger coaching — the line only appears when
/// the condition is *sustained* across enough of the warm engine window.
/// Kept deliberately conservative: an unvalidated health heuristic that
/// cried wolf would mislead more than it helps.
const int kCombustionMinSustainedSamples = 8;

/// The kind of combustion-health signal a trip exhibited (#2931).
enum CombustionHealthKind {
  /// Sustained large *positive* total trim — the ECU is adding fuel to
  /// compensate for a mixture reading lean (intake leak, weak delivery,
  /// under-reading sensor). Heuristic, not a diagnosis.
  leanCompensation,

  /// Sustained large *negative* total trim — the ECU is pulling fuel to
  /// compensate for a mixture reading rich (leaking injector,
  /// over-reading sensor). Heuristic, not a diagnosis.
  richCompensation,

  /// Sustained commanded enrichment (λ < ~0.97) under load — deliberate
  /// rich running that wastes fuel even on a healthy engine.
  commandedEnrichment,
}

/// Result of the combustion-health scan over a trip's samples (#2931).
///
/// [fired] is false for every honest "no signal" case — too few warm
/// closed-loop samples, a cold engine, unknown coolant, or normal trims.
/// When it fires, [kind] says which signal dominated and [magnitudePct]
/// carries the representative number (mean |LTFT|, the *sustained* trim, for
/// the trim kinds; the percent of the warm window spent enriched for the
/// enrichment kind) so the UI can render an honest figure. The firing gate
/// still uses the total trim (STFT + LTFT) — see [combustionHealthSignal].
class CombustionHealthSignal {
  const CombustionHealthSignal({
    required this.fired,
    this.kind,
    this.magnitudePct = 0,
    this.marked = false,
    this.sustainedSamples = 0,
  });

  /// The honest no-signal result.
  static const CombustionHealthSignal none =
      CombustionHealthSignal(fired: false);

  /// Whether the heuristic surfaced a combustion-health line at all.
  final bool fired;

  /// Which signal dominated. Null when [fired] is false.
  final CombustionHealthKind? kind;

  /// Representative magnitude in percent (see class doc). 0 when not fired.
  final double magnitudePct;

  /// True when a trim signal cleared the *marked* threshold (a likely real
  /// inefficiency) rather than just the borderline floor. Always false for
  /// the enrichment kind. Drives the stronger ARB wording.
  final bool marked;

  /// How many warm closed-loop samples sustained the firing condition.
  final int sustainedSamples;
}

/// Combustion-health **heuristic** lesson (#2931).
///
/// A coarse, clearly-labelled health *signal* — NOT a per-cylinder
/// diagnosis and NOT a diagnostic certainty. It is built entirely from
/// signals the app already reads (no new transport): the ECU's sustained
/// fuel trims (STFT 0x06 + LTFT 0x07) and its commanded mixture (λ, PID
/// 0x44). It deliberately does NOT attempt Mode 06 per-cylinder misfire or
/// DTC reading — both are unreliable on clone ELM327 hardware (out of
/// scope, future follow-ups).
///
/// How it reads the trip:
///   * Only **warm** (coolant ≥ [kCombustionWarmCoolantC]) **running**
///     (rpm > 0) samples count — cold / O2-inactive open-loop trims are
///     not a mixture-error signal, so they never trigger coaching. When
///     coolant is unknown for the whole trip we cannot confirm closed
///     loop and the trim signal stays silent (no false positive).
///   * The signal must be **sustained** over at least
///     [kCombustionMinSustainedSamples] qualifying samples — a brief spike
///     never fires it.
///   * **Trim signal** (primary, the most reliable): a sample counts as
///     "compensating" when total trim |STFT + LTFT| ≥
///     [kCombustionTrimBorderlinePct] (the active mixture fight). Positive
///     total = compensating for a lean read, negative = for a rich read. The
///     *reported* magnitude, though, is the mean SUSTAINED trim (|LTFT|) over
///     those samples — STFT oscillates ± so summing it overstated the
///     "sustained fuel addition" figure; ≥ [kCombustionTrimMarkedPct] |LTFT|
///     escalates the wording.
///   * **Enrichment signal** (secondary, always available because λ is
///     stamped on every sample): a large share of the warm window spent
///     with commanded λ < [kCombustionRichLambda] = sustained deliberate
///     rich running = wasted fuel.
///
/// The trim signal wins when both fire (it is the more reliable mixture
/// indicator). The lesson is [LessonPolarity.info] — a neutral health
/// heads-up, never painted as waste-red or praise-green — and ranks below
/// any real waste lesson.
class CombustionHealthRule implements DrivingLessonRule {
  const CombustionHealthRule();

  /// Fixed low ranking weight — a heuristic health note should appear in
  /// the lesson list but never outrank an actual quantified-waste lesson.
  /// Slightly above the smooth-driving praise so a fired health note sorts
  /// just under the waste lines and above pure praise.
  static const double _healthImpact = 0.002;

  @override
  String get id => combustionHealthLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final signal = combustionHealthSignal(context.samples);
    if (!signal.fired) return null;

    final pct = formatLessonPercent(signal.magnitudePct);
    final (String title, String advice) = switch (signal.kind!) {
      CombustionHealthKind.leanCompensation => (
          signal.marked
              ? l.lessonCombustionHealthLeanMarked(pct)
              : l.lessonCombustionHealthLeanBorderline(pct),
          l.lessonAdviceCombustionHealthLean,
        ),
      CombustionHealthKind.richCompensation => (
          signal.marked
              ? l.lessonCombustionHealthRichMarked(pct)
              : l.lessonCombustionHealthRichBorderline(pct),
          l.lessonAdviceCombustionHealthRich,
        ),
      CombustionHealthKind.commandedEnrichment => (
          l.lessonCombustionHealthEnrichment(pct),
          l.lessonAdviceCombustionHealthEnrichment,
        ),
    };

    return DrivingLesson(
      id: id,
      impact: _healthImpact,
      metricValue: signal.magnitudePct,
      title: title,
      advice: advice,
      subtitle: l.lessonCombustionHealthSubtitle,
      // A neutral heuristic heads-up — not quantified waste, not praise.
      polarity: LessonPolarity.info,
    );
  }
}

/// Pure scan: derive the [CombustionHealthSignal] for [samples] (#2931).
///
/// Side-effect free + synchronous so the heuristic (warm-window gating,
/// sustained-sample counting, trim-vs-enrichment classification) is fully
/// unit-testable without a transport. Sorts defensively — sample order is
/// not guaranteed. Returns [CombustionHealthSignal.none] for every honest
/// no-signal case.
CombustionHealthSignal combustionHealthSignal(List<TripSample> samples) {
  if (samples.length < 2) return CombustionHealthSignal.none;
  final ordered = List<TripSample>.of(samples)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Warm, running, closed-loop samples only — the precondition for the
  // trims/λ to mean anything about the mixture.
  var warmSamples = 0;

  // Trim accumulators.
  var trimSamples = 0; // warm samples that carried both STFT + LTFT
  var compensatingSamples = 0; // |total trim| ≥ borderline
  var signedTrimSum = 0.0; // mean signed total trim over compensating
  // The user-facing "X% sustained fuel addition" magnitude is built from the
  // LONG-term trim (LTFT) alone — the SUSTAINED correction the copy speaks of
  // — NOT |STFT + LTFT|. The short-term trim (STFT) oscillates ±, so adding it
  // to LTFT overstated the reported "sustained" figure ~1.5–2× vs the
  // P0171/P0172 (~±10% LTFT) convention the wording evokes (#2931). STFT still
  // gates firing via the total below; only the reported number is LTFT-based.
  // Lean-vs-rich stays classified from the signed TOTAL trim (signedTrimSum),
  // so the firing direction is unchanged.
  var absLtftSum = 0.0; // mean |LTFT| over compensating

  // Enrichment accumulators.
  var lambdaSamples = 0; // warm samples that carried λ
  var enrichedSamples = 0; // λ < rich threshold

  for (final s in ordered) {
    final rpm = s.rpm;
    final coolant = s.coolantTempC;
    // Cold / unknown-coolant / engine-off samples are open-loop or have no
    // engine signal — never a closed-loop mixture indicator.
    if (rpm == null || rpm <= 0) continue;
    if (coolant == null || coolant < kCombustionWarmCoolantC) continue;
    warmSamples++;

    final stft = s.stft;
    final ltft = s.ltft;
    if (stft != null && ltft != null) {
      trimSamples++;
      // Firing gate stays on the TOTAL trim (STFT + LTFT) so which trips
      // surface is unchanged — STFT legitimately signals the engine is
      // actively compensating right now.
      final total = stft + ltft;
      if (total.abs() >= kCombustionTrimBorderlinePct) {
        compensatingSamples++;
        signedTrimSum += total;
        // …but the REPORTED magnitude is the sustained (LTFT) correction only.
        absLtftSum += ltft.abs();
      }
    }

    final lambda = s.lambda;
    if (lambda != null && lambda > 0) {
      lambdaSamples++;
      if (lambda < kCombustionRichLambda) enrichedSamples++;
    }
  }

  if (warmSamples < kCombustionMinSustainedSamples) {
    return CombustionHealthSignal.none;
  }

  // --- Trim signal (primary) ------------------------------------------
  // Fires only when MOST of the warm window is compensating hard — a
  // sustained mixture fight, not a handful of transient spikes among
  // healthy samples.
  if (trimSamples >= kCombustionMinSustainedSamples &&
      compensatingSamples >= kCombustionMinSustainedSamples &&
      compensatingSamples * 2 >= trimSamples) {
    // Reported magnitude + the marked escalation reflect the SUSTAINED
    // correction (mean |LTFT|), matching the "sustained fuel addition" copy
    // and the P0171/P0172 LTFT convention (#2931). Lean-vs-rich is still
    // classified from the signed TOTAL trim (the active mixture direction).
    final meanAbsLtft = absLtftSum / compensatingSamples;
    final meanSigned = signedTrimSum / compensatingSamples;
    final marked = meanAbsLtft >= kCombustionTrimMarkedPct;
    return CombustionHealthSignal(
      fired: true,
      kind: meanSigned >= 0
          ? CombustionHealthKind.leanCompensation
          : CombustionHealthKind.richCompensation,
      magnitudePct: meanAbsLtft,
      marked: marked,
      sustainedSamples: compensatingSamples,
    );
  }

  // --- Enrichment signal (secondary) ----------------------------------
  // The ECU spent a large, sustained share of the warm window commanding
  // a rich mixture — wasted fuel even on a healthy engine.
  if (lambdaSamples >= kCombustionMinSustainedSamples &&
      enrichedSamples >= kCombustionMinSustainedSamples &&
      enrichedSamples * 2 >= lambdaSamples) {
    final enrichedShare = enrichedSamples / lambdaSamples * 100.0;
    return CombustionHealthSignal(
      fired: true,
      kind: CombustionHealthKind.commandedEnrichment,
      magnitudePct: enrichedShare,
      sustainedSamples: enrichedSamples,
    );
  }

  return CombustionHealthSignal.none;
}
