// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/combustion_health_rule.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson_rule.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';

/// Real-path coverage for the #2931 combustion-health HEURISTIC. Drives
/// the actual `CombustionHealthRule.evaluate` + its pure
/// `combustionHealthSignal` scan with trip fixtures — the same lesson path
/// the trip-detail Insights card runs — and asserts the honesty
/// constraints: it fires ONLY on a SUSTAINED trim/enrichment over enough
/// WARM (O2-active, closed-loop) samples, never on transient spikes, a
/// cold engine, unknown coolant, or normal trims.
void main() {
  final AppLocalizations l = AppLocalizationsEn();
  final start = DateTime.utc(2026);

  TripSummary summary({double distanceKm = 30}) => TripSummary(
        distanceKm: distanceKm,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
      );

  LessonContext ctx(List<TripSample> samples) => LessonContext(
        summary: summary(),
        samples: samples,
        score: DrivingScore.perfect,
        insights: const <DrivingInsight>[],
      );

  /// Build [count] warm, running samples 1 s apart, each carrying the
  /// given trims and/or commanded lambda.
  List<TripSample> warmSamples({
    int count = 12,
    double coolantC = 90,
    double? stft,
    double? ltft,
    double? lambda,
    double rpm = 2200,
  }) =>
      <TripSample>[
        for (var i = 0; i < count; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 80,
            rpm: rpm,
            coolantTempC: coolantC,
            stft: stft,
            ltft: ltft,
            lambda: lambda,
          ),
      ];

  group('combustionHealthSignal scan (#2931)', () {
    test('sustained high LEAN trim (LTFT +16%) over many warm samples → '
        'fires lean, marked, magnitude is the SUSTAINED (LTFT) trim', () {
      // STFT +6, LTFT +16 = +22% total → clears the firing gate; the REPORTED
      // magnitude is the sustained LTFT (16%), NOT the +22% sum (#2931).
      final signal =
          combustionHealthSignal(warmSamples(count: 14, stft: 6, ltft: 16));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.leanCompensation);
      expect(signal.marked, isTrue, reason: '16% >= marked threshold (15%)');
      expect(signal.magnitudePct, closeTo(16.0, 1e-9),
          reason: 'reported magnitude is mean |LTFT|, not |STFT + LTFT|');
    });

    test('sustained NEGATIVE trim (LTFT -16%) → fires rich, marked, magnitude '
        'is the sustained (LTFT) trim', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 14, stft: -6, ltft: -16));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.richCompensation);
      expect(signal.marked, isTrue);
      // Magnitude is reported as the sustained |mean LTFT|, not |total trim|.
      expect(signal.magnitudePct, closeTo(16.0, 1e-9));
    });

    test('borderline lean trim (LTFT +6%, total +11%) → fires lean but NOT '
        'marked (sustained trim is below the marked threshold)', () {
      // Total +11% clears the borderline gate; LTFT +6% is below marked (15%).
      final signal =
          combustionHealthSignal(warmSamples(count: 12, stft: 5, ltft: 6));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.leanCompensation);
      expect(signal.marked, isFalse,
          reason: 'sustained LTFT 6% < marked threshold (15%)');
      expect(signal.magnitudePct, closeTo(6.0, 1e-9));
    });

    test('STFT oscillates ± while LTFT is sustained +15% → reported magnitude '
        'tracks the SUSTAINED trim (~15), not the STFT+LTFT sum (#2931)', () {
      // The over-alarm bug: averaging |STFT + LTFT| reported ~30% (and "lean
      // — 30% fuel addition") on a trip whose sustained correction was ~15%.
      // With STFT swinging ±15 around a sustained LTFT of +15, the per-sample
      // total alternates 0 / +30, so the old sum-based mean was ~15–30 and
      // over-stated the sustained figure; the LTFT-based magnitude is ~15.
      final samples = <TripSample>[
        // 18 samples → 9 even ticks (total +30) clear the gate (≥ 8 needed),
        // 9 odd ticks (total 0) do not; compensating*2 ≥ trimSamples holds.
        for (var i = 0; i < 18; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 80,
            rpm: 2200,
            coolantTempC: 90,
            // STFT oscillates +15 / -15; only the +15 ticks clear the gate.
            stft: i.isEven ? 15.0 : -15.0,
            ltft: 15.0, // sustained lean correction
          ),
      ];
      final signal = combustionHealthSignal(samples);
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.leanCompensation);
      expect(signal.magnitudePct, closeTo(15.0, 1e-9),
          reason: 'reported magnitude reflects the sustained LTFT (~15), '
              'NOT the STFT+LTFT sum (~30) the old rule reported');
    });

    test('normal trims (±3% total) → does NOT fire', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 14, stft: 1, ltft: 2));
      expect(signal.fired, isFalse);
    });

    test('too few warm samples (sustained, but only 4) → does NOT fire', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 4, stft: 6, ltft: 12));
      expect(signal.fired, isFalse,
          reason: 'below the minimum sustained-sample count');
    });

    test('COLD engine (coolant 40 °C, O2 inactive) with a big trim → does '
        'NOT fire (no false positive)', () {
      final signal = combustionHealthSignal(
          warmSamples(count: 14, coolantC: 40, stft: 6, ltft: 12));
      expect(signal.fired, isFalse,
          reason: 'cold / open-loop trims are not a mixture-error signal');
    });

    test('UNKNOWN coolant (all null) with a big trim → does NOT fire', () {
      final samples = <TripSample>[
        for (var i = 0; i < 14; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 80,
            rpm: 2200,
            // coolantTempC null → cannot confirm closed loop.
            stft: 6,
            ltft: 12,
          ),
      ];
      expect(combustionHealthSignal(samples).fired, isFalse);
    });

    test('a single transient trim SPIKE among healthy warm samples → does '
        'NOT fire', () {
      final samples = <TripSample>[
        for (var i = 0; i < 20; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 80,
            rpm: 2200,
            coolantTempC: 90,
            // One big spike at i==10, healthy everywhere else.
            stft: i == 10 ? 12.0 : 1.0,
            ltft: i == 10 ? 12.0 : 2.0,
          ),
      ];
      expect(combustionHealthSignal(samples).fired, isFalse,
          reason: 'one spike is not sustained');
    });

    test('sustained commanded ENRICHMENT (lambda 0.88) with no trims → '
        'fires enrichment', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 12, lambda: 0.88));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.commandedEnrichment);
      // 100% of the warm window was enriched.
      expect(signal.magnitudePct, closeTo(100.0, 1e-9));
    });

    test('healthy stoich lambda (1.0) with no trims → does NOT fire', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 12, lambda: 1.0));
      expect(signal.fired, isFalse);
    });

    test('trim signal WINS over enrichment when both fire', () {
      final signal = combustionHealthSignal(
          warmSamples(count: 14, stft: 6, ltft: 12, lambda: 0.88));
      expect(signal.kind, CombustionHealthKind.leanCompensation,
          reason: 'the trim signal is the more reliable mixture indicator');
    });
  });

  group('CombustionHealthRule (#2931)', () {
    const rule = CombustionHealthRule();

    test('fires the lean-compensation lesson on sustained high LTFT', () {
      final lesson =
          rule.evaluate(ctx(warmSamples(count: 14, stft: 6, ltft: 16)), l);
      expect(lesson, isNotNull);
      expect(lesson!.id, combustionHealthLessonId);
      // Marked lean wording, with the SUSTAINED (LTFT) 16% figure — not the
      // +22% STFT+LTFT sum (#2931).
      expect(lesson.title, l.lessonCombustionHealthLeanMarked('16'));
      expect(lesson.advice, l.lessonAdviceCombustionHealthLean);
      // Honesty: subtitle explicitly labels it a heuristic, not a diagnosis.
      expect(lesson.subtitle, l.lessonCombustionHealthSubtitle);
      // A neutral health note — not waste-red, not praise-green.
      expect(lesson.polarity, LessonPolarity.info);
      // Ranks below any quantified-waste lesson.
      expect(lesson.impact, lessThan(0.01));
    });

    test('fires the rich-compensation lesson on sustained negative trim', () {
      final lesson =
          rule.evaluate(ctx(warmSamples(count: 14, stft: -6, ltft: -16)), l);
      expect(lesson, isNotNull);
      // Sustained (LTFT) 16% figure, not the -22% STFT+LTFT sum (#2931).
      expect(lesson!.title, l.lessonCombustionHealthRichMarked('16'));
      expect(lesson.advice, l.lessonAdviceCombustionHealthRich);
    });

    test('does NOT fire on normal trims (±3%)', () {
      expect(
        rule.evaluate(ctx(warmSamples(count: 14, stft: 1, ltft: 2)), l),
        isNull,
      );
    });

    test('does NOT fire on a cold engine (O2 inactive)', () {
      expect(
        rule.evaluate(
            ctx(warmSamples(count: 14, coolantC: 40, stft: 6, ltft: 12)), l),
        isNull,
      );
    });

    test('does NOT fire with too few warm samples', () {
      expect(
        rule.evaluate(ctx(warmSamples(count: 4, stft: 6, ltft: 12)), l),
        isNull,
      );
    });

    test('fires the enrichment lesson on sustained commanded rich running', () {
      final lesson =
          rule.evaluate(ctx(warmSamples(count: 12, lambda: 0.88)), l);
      expect(lesson, isNotNull);
      expect(lesson!.title, l.lessonCombustionHealthEnrichment('100'));
      expect(lesson.advice, l.lessonAdviceCombustionHealthEnrichment);
    });
  });
}
