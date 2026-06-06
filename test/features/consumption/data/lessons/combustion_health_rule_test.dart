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
    test('sustained high LEAN trim (+18% total) over many warm samples → '
        'fires lean, marked', () {
      // STFT +6, LTFT +12 = +18% total on every warm sample.
      final signal =
          combustionHealthSignal(warmSamples(count: 14, stft: 6, ltft: 12));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.leanCompensation);
      expect(signal.marked, isTrue, reason: '18% >= marked threshold (15%)');
      expect(signal.magnitudePct, closeTo(18.0, 1e-9));
    });

    test('sustained NEGATIVE trim (-18% total) → fires rich, marked', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 14, stft: -6, ltft: -12));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.richCompensation);
      expect(signal.marked, isTrue);
      // Magnitude is reported as the |mean total trim|.
      expect(signal.magnitudePct, closeTo(18.0, 1e-9));
    });

    test('borderline lean trim (+11%, below the marked threshold) → fires '
        'lean but NOT marked', () {
      final signal =
          combustionHealthSignal(warmSamples(count: 12, stft: 5, ltft: 6));
      expect(signal.fired, isTrue);
      expect(signal.kind, CombustionHealthKind.leanCompensation);
      expect(signal.marked, isFalse, reason: '11% < marked threshold (15%)');
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
          rule.evaluate(ctx(warmSamples(count: 14, stft: 6, ltft: 12)), l);
      expect(lesson, isNotNull);
      expect(lesson!.id, combustionHealthLessonId);
      // Marked lean wording, with the 18% figure.
      expect(lesson.title, l.lessonCombustionHealthLeanMarked('18'));
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
          rule.evaluate(ctx(warmSamples(count: 14, stft: -6, ltft: -12)), l);
      expect(lesson, isNotNull);
      expect(lesson!.title, l.lessonCombustionHealthRichMarked('18'));
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
