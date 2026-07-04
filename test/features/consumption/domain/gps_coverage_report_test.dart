// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/recording_lifecycle_mark.dart';
import 'package:tankstellen/features/consumption/domain/gps_coverage_report.dart';
import 'package:tankstellen/features/consumption/domain/gps_track_distance.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';

/// #3465 — GpsCoverageReport: coverage math + one constructed fixture per
/// attribution class, so a field trace's holes get the RIGHT verdict:
///   * backgroundThrottle — backgrounded gap on a no-FGS build (the
///     acceptance criterion / the field answer);
///   * osBatching — a late burst whose fixes backfill ≥60% of the gap;
///   * gateRejected — the #3253 tally budget covers the missing fixes;
///   * signalLoss — foregrounded, no burst, no rejections;
///   * unknown — legacy trip without lifecycle marks.
void main() {
  final t0 = DateTime(2026, 7, 1, 8);
  const oneSecond = Duration(seconds: 1);

  TripSample fix(Duration offset, {double? hAccuracyM}) => TripSample(
        timestamp: t0.add(offset),
        speedKmh: 50,
        latitude: 43.4 + offset.inMilliseconds * 1e-7,
        longitude: 3.5,
        hAccuracyM: hAccuracyM,
      );

  /// N fixes at a steady 1 Hz cadence starting at [from].
  List<TripSample> cadence(Duration from, int count) => [
        for (var i = 0; i < count; i++) fix(from + Duration(seconds: i)),
      ];

  /// Like [cadence] but each sample carries OBD2 RPM (a linked stretch).
  List<TripSample> obd2Cadence(Duration from, int count) => [
        for (var i = 0; i < count; i++)
          TripSample(
            timestamp: t0.add(from + Duration(seconds: i)),
            speedKmh: 50,
            rpm: 1800,
            latitude:
                43.4 + (from + Duration(seconds: i)).inMilliseconds * 1e-7,
            longitude: 3.5,
          ),
      ];

  RecordingLifecycleMark mark(Duration offset, {required bool bg}) =>
      RecordingLifecycleMark(at: t0.add(offset), backgrounded: bg);

  group('coverage math', () {
    test('a steady 1 Hz track has full coverage and no gaps', () {
      final report = GpsCoverageReport.fromSamples(
        cadence(Duration.zero, 11),
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.coverageRatio, 1.0);
      expect(report.expectedFixCount, 11);
      expect(report.actualFixCount, 11);
      expect(report.gaps, isEmpty);
      expect(report.longestGap, isNull);
    });

    test('a 4 s hole in a 10 s span yields 0.6 coverage and one gap', () {
      // Fixes at 0..3 s and 7..10 s → intervals 6×1 s + one 4 s gap.
      final samples = [
        ...cadence(Duration.zero, 4),
        ...cadence(const Duration(seconds: 7), 4),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.coverageRatio, closeTo(0.6, 1e-9));
      expect(report.expectedFixCount, 11);
      expect(report.actualFixCount, 8);
      expect(report.gaps, hasLength(1));
      expect(report.gaps.single.start, t0.add(const Duration(seconds: 3)));
      expect(report.gaps.single.duration, const Duration(seconds: 4));
      expect(report.longestGap, same(report.gaps.single));
    });

    test('an interval at exactly 2× the expected cadence is NOT a gap', () {
      final samples = [
        fix(Duration.zero),
        fix(const Duration(seconds: 2)),
        fix(const Duration(seconds: 3)),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.gaps, isEmpty);
      expect(report.coverageRatio, 1.0);
    });

    test('engine-only samples (no lat/lon) are transparent to the track',
        () {
      final samples = [
        ...cadence(Duration.zero, 3),
        // An OBD2 tick without a fix inside what would otherwise be a gap
        // must NOT count as coverage.
        TripSample(
            timestamp: t0.add(const Duration(seconds: 5)),
            speedKmh: 60,
            rpm: 2000),
        ...cadence(const Duration(seconds: 8), 3),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.actualFixCount, 6);
      expect(report.gaps, hasLength(1));
      expect(report.gaps.single.duration, const Duration(seconds: 6));
    });

    test('fewer than two fixes degrades to the empty report', () {
      final report = GpsCoverageReport.fromSamples(
        [fix(Duration.zero)],
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.coverageRatio, 0);
      expect(report.expectedFixCount, 1);
      expect(report.actualFixCount, 1);
      expect(report.gaps, isEmpty);
      expect(report.backgroundShare, isNull);
    });
  });

  group('attribution', () {
    test(
        'backgroundThrottle — a backgrounded gap on a no-FGS build gets the '
        'field answer (#3465 acceptance)', () {
      // 1 Hz until t=5, backgrounded at t=6, nothing until t=35, resumed
      // at t=34, 1 Hz again from t=35.
      final samples = [
        ...cadence(Duration.zero, 6),
        ...cadence(const Duration(seconds: 35), 6),
      ];
      final marks = [
        mark(Duration.zero, bg: false),
        mark(const Duration(seconds: 6), bg: true),
        mark(const Duration(seconds: 34), bg: false),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: marks,
        fgsEnabled: false,
      );
      expect(report.gaps, hasLength(1));
      expect(report.gaps.single.attribution,
          GpsGapAttribution.backgroundThrottle);
      expect(report.longestGap!.attribution,
          GpsGapAttribution.backgroundThrottle);
      // 28 s of the 40 s span were backgrounded.
      expect(report.backgroundShare, closeTo(28 / 40, 1e-9));
    });

    test('the same backgrounded gap on an FGS build is NOT throttle — the '
        'FGS should have kept the stream alive, so it stays unknown', () {
      final samples = [
        ...cadence(Duration.zero, 6),
        ...cadence(const Duration(seconds: 35), 6),
      ];
      final marks = [
        mark(Duration.zero, bg: false),
        mark(const Duration(seconds: 6), bg: true),
        mark(const Duration(seconds: 34), bg: false),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: marks,
        fgsEnabled: true,
      );
      expect(report.gaps.single.attribution, GpsGapAttribution.unknown);
    });

    test('osBatching — a burst backfilling ≥60% of the gap window', () {
      // 1 Hz to t=5, a 10 s gap, then 8 fixes 200 ms apart (a queued-batch
      // flush: 8 × 1 s expected cadence ≥ 60% of the 10 s gap).
      final samples = [
        ...cadence(Duration.zero, 6),
        for (var i = 0; i < 8; i++)
          fix(Duration(milliseconds: 15000 + i * 200)),
        ...cadence(const Duration(seconds: 18), 3),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [mark(Duration.zero, bg: false)], // provably foreground
        fgsEnabled: false,
      );
      final gap = report.gaps
          .firstWhere((g) => g.duration == const Duration(seconds: 10));
      expect(gap.attribution, GpsGapAttribution.osBatching);
    });

    test('a too-small post-gap burst does NOT read as batching', () {
      // Same 10 s gap but only 3 tight fixes after it (3 s expected-cadence
      // worth < 60% of 10 s) → falls through to signalLoss (foreground).
      final samples = [
        ...cadence(Duration.zero, 6),
        for (var i = 0; i < 3; i++)
          fix(Duration(milliseconds: 15000 + i * 200)),
        ...cadence(const Duration(seconds: 17), 3),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [mark(Duration.zero, bg: false)],
        fgsEnabled: false,
      );
      final gap = report.gaps
          .firstWhere((g) => g.duration == const Duration(seconds: 10));
      expect(gap.attribution, GpsGapAttribution.signalLoss);
    });

    test('gateRejected — the tally budget covers the missing fixes, and '
        'DEPLETES so one small tally cannot explain every hole', () {
      // Two 5 s gaps (4 missing fixes each); the tally carries only 5
      // rejected units → the first gap is explained, the second is not.
      final samples = [
        ...cadence(Duration.zero, 3),
        ...cadence(const Duration(seconds: 7), 3),
        ...cadence(const Duration(seconds: 14), 3),
      ];
      final tally = GpsGateRejectionTally()..accuracyRejectedSegments = 5;
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        tally: tally,
        marks: [mark(Duration.zero, bg: false)],
        fgsEnabled: false,
      );
      expect(report.gaps, hasLength(2));
      expect(report.gaps[0].attribution, GpsGapAttribution.gateRejected);
      expect(report.gaps[1].attribution, GpsGapAttribution.signalLoss,
          reason: 'the 5-unit budget was spent on gap 1 (4 missing fixes); '
              '1 unit cannot cover gap 2\'s 4 missing fixes');
    });

    test('signalLoss — foregrounded, no burst, no tally', () {
      final samples = [
        ...cadence(Duration.zero, 4),
        ...cadence(const Duration(seconds: 12), 4),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [mark(Duration.zero, bg: false)],
        fgsEnabled: false,
      );
      expect(report.gaps.single.attribution, GpsGapAttribution.signalLoss);
    });

    test('unknown — a legacy trip with no lifecycle marks at all', () {
      final samples = [
        ...cadence(Duration.zero, 4),
        ...cadence(const Duration(seconds: 12), 4),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.gaps.single.attribution, GpsGapAttribution.unknown,
          reason: 'without marks, "foregrounded" is not provable, so '
              'signalLoss must not be claimed');
      expect(report.backgroundShare, isNull);
    });
  });

  group('forTrip', () {
    test('returns null under two fixes (the card self-hides)', () {
      expect(GpsCoverageReport.forTrip(const []), isNull);
      expect(GpsCoverageReport.forTrip([fix(Duration.zero)]), isNull);
    });

    test('labels a backgrounded gap backgroundThrottle on the default '
        '(no-FGS) build — the #3465 field answer end to end', () {
      // kGpsRecordingForegroundServiceEnabled is false unless the
      // FGS_FORM_APPROVED dart-define is set, which test runs never do.
      final samples = [
        ...cadence(Duration.zero, 6),
        ...cadence(const Duration(seconds: 35), 6),
      ];
      final report = GpsCoverageReport.forTrip(
        samples,
        marks: [
          mark(Duration.zero, bg: false),
          mark(const Duration(seconds: 6), bg: true),
          mark(const Duration(seconds: 34), bg: false),
        ],
      );
      expect(report, isNotNull);
      expect(report!.longestGap!.attribution,
          GpsGapAttribution.backgroundThrottle);
    });

    test('reuses the #2963 accuracy gate for its tally (no duplicate gate '
        'logic): rejected-segment counts flow into the budget', () {
      // A run with poor-accuracy endpoints raises the accuracy tally; the
      // report is still produced without throwing.
      final samples = [
        ...cadence(Duration.zero, 3),
        fix(const Duration(seconds: 3), hAccuracyM: 120),
        ...cadence(const Duration(seconds: 10), 3),
      ];
      final report = GpsCoverageReport.forTrip(samples);
      expect(report, isNotNull);
      expect(report!.actualFixCount, 7);
    });
  });

  group('serialisation', () {
    test('toJson exports the full block and round-trips through JSON', () {
      final samples = [
        ...cadence(Duration.zero, 6),
        ...cadence(const Duration(seconds: 35), 6),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [
          mark(Duration.zero, bg: false),
          mark(const Duration(seconds: 6), bg: true),
          mark(const Duration(seconds: 34), bg: false),
        ],
        fgsEnabled: false,
      );
      final json = report.toJson();
      expect(json['coverageRatio'], closeTo(10 / 40, 1e-9));
      expect(json['expectedFixCount'], 41);
      expect(json['actualFixCount'], 12);
      expect(json['expectedFixIntervalMs'], 1000);
      expect(json['fgsEnabled'], false);
      expect(json['backgroundShare'], closeTo(0.7, 1e-9));
      expect(json['gapCount'], 1);
      final longest = json['longestGap'] as Map<String, dynamic>;
      expect(longest['durationMs'], 30000);
      expect(longest['attribution'], 'backgroundThrottle');
      // Wire-safe: encodes + decodes back to the same map.
      expect(jsonDecode(jsonEncode(json)), equals(json));
    });

    test('the exported gap list is capped at 20 entries', () {
      // 25 gaps: 26 pairs of fixes with 5 s holes between pairs.
      final samples = <TripSample>[];
      for (var i = 0; i < 26; i++) {
        samples.add(fix(Duration(seconds: i * 6)));
        samples.add(fix(Duration(seconds: i * 6 + 1)));
      }
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        fgsEnabled: false,
      );
      expect(report.gaps, hasLength(25));
      final json = report.toJson();
      expect(json['gapCount'], 25);
      expect(json['gaps'], hasLength(GpsCoverageReport.kExportGapCap));
      expect(json['gapsTruncated'], isTrue);
    });
  });

  group('malformed input (the documented never-throws contract)', () {
    test('unsorted samples, duplicate timestamps, a zero interval and an '
        'empty list all return normally', () {
      final shuffled = [
        fix(const Duration(seconds: 9)),
        fix(Duration.zero),
        fix(const Duration(seconds: 9)), // duplicate timestamp
        fix(const Duration(seconds: 4)),
      ];
      expect(
        () => GpsCoverageReport.fromSamples(
          shuffled,
          expectedFixInterval: Duration.zero, // falls back to 1 s
          fgsEnabled: false,
        ),
        returnsNormally,
      );
      expect(
        () => GpsCoverageReport.fromSamples(
          const [],
          expectedFixInterval: oneSecond,
          fgsEnabled: false,
        ),
        returnsNormally,
      );
      final report = GpsCoverageReport.fromSamples(
        shuffled,
        expectedFixInterval: Duration.zero,
        fgsEnabled: false,
      );
      // The defensive sort makes the shuffled input analysable.
      expect(report.actualFixCount, 4);
      expect(report.coverageRatio, inInclusiveRange(0.0, 1.0));
    });
  });

  group('linkRecovery attribution (#3465, field 2026-07-03)', () {
    test('a foreground gap flanked by link-down samples on an OBD2 trip '
        'reads linkRecovery', () {
      // 30 s linked driving, link drops (rpm null), a 12 s GPS gap while
      // the reconnect episode runs, then link-down fixes resume.
      final samples = [
        ...obd2Cadence(Duration.zero, 30),
        fix(const Duration(seconds: 30)),
        fix(const Duration(seconds: 42)),
        ...cadence(const Duration(seconds: 43), 5),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [RecordingLifecycleMark(at: t0, backgrounded: false)],
        fgsEnabled: false,
      );
      expect(report.gaps, hasLength(1));
      expect(report.gaps.single.attribution, GpsGapAttribution.linkRecovery,
          reason: 'OBD2-heavy trip + rpm-null flanks = the reconnect '
              'episode stalled GPS ingest (the pinned-foreground field '
              'case)');
    });

    test('the same gap with a HEALTHY link on both flanks does NOT read '
        'linkRecovery', () {
      final samples = [
        ...obd2Cadence(Duration.zero, 31),
        ...obd2Cadence(const Duration(seconds: 42), 6),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [RecordingLifecycleMark(at: t0, backgrounded: false)],
        fgsEnabled: false,
      );
      expect(report.gaps, hasLength(1));
      expect(report.gaps.single.attribution,
          isNot(GpsGapAttribution.linkRecovery));
    });

    test('a GPS-only trip (no rpm anywhere) never reads linkRecovery', () {
      final samples = [
        ...cadence(Duration.zero, 31),
        ...cadence(const Duration(seconds: 42), 6),
      ];
      final report = GpsCoverageReport.fromSamples(
        samples,
        expectedFixInterval: oneSecond,
        marks: [RecordingLifecycleMark(at: t0, backgrounded: false)],
        fgsEnabled: false,
      );
      expect(report.gaps.single.attribution,
          isNot(GpsGapAttribution.linkRecovery));
    });
  });
}
