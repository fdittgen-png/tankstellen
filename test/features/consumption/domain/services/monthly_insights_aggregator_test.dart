import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic coverage for `aggregateMonthlyInsights` (#1041 phase 4).
///
/// The aggregator is the data feed for `MonthlyInsightsCard`; the
/// widget tests pump fixed summaries, so the bucketing / fallback /
/// reliability logic MUST be locked down here. Tests are split into:
///   * empty / degenerate input — empty list, missing startedAt, no
///     trips in either month
///   * bucket boundaries — current/previous/older month classification,
///     wraparound from January to December of the prior year
///   * metric correctness — trip count, drive time, distance both via
///     samples and via summary fallback, consumption average via
///     samples
///   * reliability gate — `isComparisonReliable` only when both months
///     hit ≥ 3 trips, otherwise card hides delta arrows
///   * derived getters — deltas, `consumptionImproved`
void main() {
  group('aggregateMonthlyInsights — empty / degenerate input', () {
    test('returns the empty summary when trips is empty', () {
      final summary =
          aggregateMonthlyInsights(const [], DateTime(2026, 4, 27, 12));

      expect(summary.currentMonthTripCount, 0);
      expect(summary.previousMonthTripCount, 0);
      expect(summary.currentMonthDriveTime, Duration.zero);
      expect(summary.previousMonthDriveTime, Duration.zero);
      expect(summary.currentMonthDistanceKm, 0);
      expect(summary.previousMonthDistanceKm, 0);
      expect(summary.currentMonthAvgConsumptionLPer100km, isNull);
      expect(summary.previousMonthAvgConsumptionLPer100km, isNull);
      expect(summary.isComparisonReliable, isFalse);
    });

    test('skips trips whose startedAt is null', () {
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'no-start',
            startedAt: null,
            endedAt: DateTime(2026, 4, 10, 9, 30),
            distanceKm: 8.0,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );
      // Trip dropped from every counter; no reliability either way.
      expect(summary.currentMonthTripCount, 0);
      expect(summary.previousMonthTripCount, 0);
      expect(summary.isComparisonReliable, isFalse);
    });

    test('ignores trips older than the previous calendar month', () {
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'jan',
            startedAt: DateTime(2026, 1, 5, 9),
            endedAt: DateTime(2026, 1, 5, 9, 30),
            distanceKm: 10.0,
          ),
          _entry(
            id: 'feb',
            startedAt: DateTime(2026, 2, 5, 9),
            endedAt: DateTime(2026, 2, 5, 9, 30),
            distanceKm: 10.0,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );
      // April is current → previous is March → both January and
      // February are older and must be discarded.
      expect(summary.currentMonthTripCount, 0);
      expect(summary.previousMonthTripCount, 0);
      expect(summary.currentMonthDistanceKm, 0);
      expect(summary.previousMonthDistanceKm, 0);
    });
  });

  group('aggregateMonthlyInsights — bucket boundaries', () {
    test('classifies same-(year,month) as current and prior calendar '
        'month as previous', () {
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'cur',
            startedAt: DateTime(2026, 4, 10, 9),
            endedAt: DateTime(2026, 4, 10, 9, 30),
            distanceKm: 10,
          ),
          _entry(
            id: 'prev',
            startedAt: DateTime(2026, 3, 10, 9),
            endedAt: DateTime(2026, 3, 10, 9, 30),
            distanceKm: 10,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      expect(summary.currentMonthTripCount, 1);
      expect(summary.previousMonthTripCount, 1);
    });

    test('wraps January back to December of the prior year for the '
        'previous bucket', () {
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'jan-26',
            startedAt: DateTime(2026, 1, 5, 9),
            endedAt: DateTime(2026, 1, 5, 9, 30),
            distanceKm: 10,
          ),
          _entry(
            id: 'dec-25',
            startedAt: DateTime(2025, 12, 20, 9),
            endedAt: DateTime(2025, 12, 20, 9, 30),
            distanceKm: 10,
          ),
        ],
        DateTime(2026, 1, 15, 12),
      );

      expect(summary.currentMonthTripCount, 1);
      expect(summary.previousMonthTripCount, 1);
    });
  });

  group('aggregateMonthlyInsights — metric correctness', () {
    test('counts trips and sums drive time even when samples are empty',
        () {
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'a',
            startedAt: DateTime(2026, 4, 10, 9),
            endedAt: DateTime(2026, 4, 10, 9, 30), // 30 min
            distanceKm: 10,
          ),
          _entry(
            id: 'b',
            startedAt: DateTime(2026, 4, 11, 9),
            endedAt: DateTime(2026, 4, 11, 9, 45), // 45 min
            distanceKm: 12,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      expect(summary.currentMonthTripCount, 2);
      expect(summary.currentMonthDriveTime, const Duration(minutes: 75));
      // Sample-empty trips fall back to summary.distanceKm.
      expect(summary.currentMonthDistanceKm, 22);
      // No samples → no fuel litres → no consumption average.
      expect(summary.currentMonthAvgConsumptionLPer100km, isNull);
    });

    test('integrates distance + consumption from samples when present', () {
      // Build a trip with two minutes of samples at ~60 km/h carrying
      // a fuel rate of 6 L/h. Expected:
      //   distance = 60 km/h × 2 min = 2 km
      //   fuel    = 6 L/h × 2 min  = 0.2 L
      //   avg L/100km on 2 km is below the 5 km noise floor → null
      // So we use a longer trip below.
      final start = DateTime(2026, 4, 10, 9);
      final samples = <TripSample>[
        for (var i = 0; i <= 360; i++) // 6 minutes × 60 ticks
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 60.0,
            rpm: 1800,
            fuelRateLPerHour: 6.0,
          ),
      ];
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'a',
            startedAt: start,
            endedAt: start.add(const Duration(seconds: 360)),
            distanceKm: 0, // ignored when samples are present
            samples: samples,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      // 60 km/h × 360 s = 6 km
      expect(summary.currentMonthDistanceKm, closeTo(6.0, 0.05));
      // 6 L/h × (360/3600) h = 0.6 L
      // avg = 0.6 / 6 km × 100 = 10 L/100 km
      expect(summary.currentMonthAvgConsumptionLPer100km,
          closeTo(10.0, 0.1));
    });

    test('returns null avg consumption when bucket distance < 5 km', () {
      final start = DateTime(2026, 4, 10, 9);
      final samples = <TripSample>[
        for (var i = 0; i <= 60; i++) // 60 s × 60 km/h = 1 km
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 60.0,
            rpm: 1500,
            fuelRateLPerHour: 5.0,
          ),
      ];
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'a',
            startedAt: start,
            endedAt: start.add(const Duration(seconds: 60)),
            distanceKm: 0,
            samples: samples,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );
      expect(summary.currentMonthDistanceKm, closeTo(1.0, 0.05));
      expect(summary.currentMonthAvgConsumptionLPer100km, isNull);
    });

    test('drops trips without fuel-rate samples from the consumption '
        'average but keeps them in distance + count', () {
      final start = DateTime(2026, 4, 10, 9);
      // Trip A: long, no fuel rate.
      final samplesA = <TripSample>[
        for (var i = 0; i <= 600; i++) // 10 min × 60 km/h = 10 km
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 60.0,
            rpm: 1500,
            // no fuelRateLPerHour
          ),
      ];
      // Trip B: long, with fuel rate.
      final startB = DateTime(2026, 4, 11, 9);
      final samplesB = <TripSample>[
        for (var i = 0; i <= 600; i++) // 10 min × 60 km/h = 10 km, 6 L/h
          TripSample(
            timestamp: startB.add(Duration(seconds: i)),
            speedKmh: 60.0,
            rpm: 1500,
            fuelRateLPerHour: 6.0,
          ),
      ];
      final summary = aggregateMonthlyInsights(
        [
          _entry(
            id: 'a',
            startedAt: start,
            endedAt: start.add(const Duration(seconds: 600)),
            distanceKm: 0,
            samples: samplesA,
          ),
          _entry(
            id: 'b',
            startedAt: startB,
            endedAt: startB.add(const Duration(seconds: 600)),
            distanceKm: 0,
            samples: samplesB,
          ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      // Both trips count for the count + distance figures.
      expect(summary.currentMonthTripCount, 2);
      expect(summary.currentMonthDistanceKm, closeTo(20.0, 0.1));
      // Avg consumption derives ONLY from trip B (10 km / 1.0 L = 10
      // L/100 km). Mixing in trip A's distance with no fuel would
      // halve the figure and mislead.
      expect(summary.currentMonthAvgConsumptionLPer100km,
          closeTo(10.0, 0.2));
    });
  });

  group('aggregateMonthlyInsights — reliability gate', () {
    test('isComparisonReliable is false when previous month has < 3 trips',
        () {
      final summary = aggregateMonthlyInsights(
        [
          for (var i = 0; i < 5; i++)
            _entry(
              id: 'cur-$i',
              startedAt: DateTime(2026, 4, 10 + i, 9),
              endedAt: DateTime(2026, 4, 10 + i, 9, 30),
              distanceKm: 10,
            ),
          // Only 2 previous-month trips.
          for (var i = 0; i < 2; i++)
            _entry(
              id: 'prev-$i',
              startedAt: DateTime(2026, 3, 10 + i, 9),
              endedAt: DateTime(2026, 3, 10 + i, 9, 30),
              distanceKm: 10,
            ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      expect(summary.currentMonthTripCount, 5);
      expect(summary.previousMonthTripCount, 2);
      expect(summary.isComparisonReliable, isFalse);
    });

    test('isComparisonReliable is false when current month has < 3 trips',
        () {
      final summary = aggregateMonthlyInsights(
        [
          // Only 2 current-month trips.
          for (var i = 0; i < 2; i++)
            _entry(
              id: 'cur-$i',
              startedAt: DateTime(2026, 4, 10 + i, 9),
              endedAt: DateTime(2026, 4, 10 + i, 9, 30),
              distanceKm: 10,
            ),
          for (var i = 0; i < 5; i++)
            _entry(
              id: 'prev-$i',
              startedAt: DateTime(2026, 3, 10 + i, 9),
              endedAt: DateTime(2026, 3, 10 + i, 9, 30),
              distanceKm: 10,
            ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      expect(summary.currentMonthTripCount, 2);
      expect(summary.previousMonthTripCount, 5);
      expect(summary.isComparisonReliable, isFalse);
    });

    test('isComparisonReliable is true when both months have ≥ 3 trips', () {
      final summary = aggregateMonthlyInsights(
        [
          for (var i = 0; i < 3; i++)
            _entry(
              id: 'cur-$i',
              startedAt: DateTime(2026, 4, 10 + i, 9),
              endedAt: DateTime(2026, 4, 10 + i, 9, 30),
              distanceKm: 10,
            ),
          for (var i = 0; i < 3; i++)
            _entry(
              id: 'prev-$i',
              startedAt: DateTime(2026, 3, 10 + i, 9),
              endedAt: DateTime(2026, 3, 10 + i, 9, 30),
              distanceKm: 10,
            ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      expect(summary.isComparisonReliable, isTrue);
    });

    test('only-current-month trips: previous fields zero/null and not '
        'reliable', () {
      final summary = aggregateMonthlyInsights(
        [
          for (var i = 0; i < 5; i++)
            _entry(
              id: 'cur-$i',
              startedAt: DateTime(2026, 4, 10 + i, 9),
              endedAt: DateTime(2026, 4, 10 + i, 9, 30),
              distanceKm: 10,
            ),
        ],
        DateTime(2026, 4, 27, 12),
      );

      expect(summary.currentMonthTripCount, 5);
      expect(summary.previousMonthTripCount, 0);
      expect(summary.previousMonthDriveTime, Duration.zero);
      expect(summary.previousMonthDistanceKm, 0);
      expect(summary.previousMonthAvgConsumptionLPer100km, isNull);
      expect(summary.isComparisonReliable, isFalse);
    });
  });

  group('MonthlyInsightsSummary — derived getters', () {
    test('tripCountDelta and distanceKmDelta sign convention', () {
      const summary = MonthlyInsightsSummary(
        currentMonthTripCount: 8,
        previousMonthTripCount: 5,
        currentMonthDriveTime: Duration(hours: 4),
        previousMonthDriveTime: Duration(hours: 2),
        currentMonthDistanceKm: 120,
        previousMonthDistanceKm: 80,
        currentMonthAvgConsumptionLPer100km: 6.0,
        previousMonthAvgConsumptionLPer100km: 7.0,
        isComparisonReliable: true,
      );

      expect(summary.tripCountDelta, 3);
      expect(summary.driveTimeDelta, const Duration(hours: 2));
      expect(summary.distanceKmDelta, 40);
      expect(summary.consumptionDeltaLPer100km, -1.0);
      expect(summary.consumptionImproved, isTrue);
    });

    test('consumptionImproved is false when consumption rose', () {
      const summary = MonthlyInsightsSummary(
        currentMonthTripCount: 5,
        previousMonthTripCount: 5,
        currentMonthDriveTime: Duration.zero,
        previousMonthDriveTime: Duration.zero,
        currentMonthDistanceKm: 0,
        previousMonthDistanceKm: 0,
        currentMonthAvgConsumptionLPer100km: 8.5,
        previousMonthAvgConsumptionLPer100km: 7.0,
        isComparisonReliable: true,
      );

      expect(summary.consumptionDeltaLPer100km, closeTo(1.5, 0.001));
      expect(summary.consumptionImproved, isFalse);
    });

    test('consumptionImproved is false when delta is unknown', () {
      const summary = MonthlyInsightsSummary(
        currentMonthTripCount: 5,
        previousMonthTripCount: 5,
        currentMonthDriveTime: Duration.zero,
        previousMonthDriveTime: Duration.zero,
        currentMonthDistanceKm: 0,
        previousMonthDistanceKm: 0,
        currentMonthAvgConsumptionLPer100km: null,
        previousMonthAvgConsumptionLPer100km: 7.0,
        isComparisonReliable: true,
      );

      expect(summary.consumptionDeltaLPer100km, isNull);
      expect(summary.consumptionImproved, isFalse);
    });
  });
}

TripHistoryEntry _entry({
  required String id,
  String? vehicleId,
  required DateTime? startedAt,
  DateTime? endedAt,
  double distanceKm = 0,
  List<TripSample> samples = const [],
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: distanceKm,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      endedAt: endedAt,
    ),
    samples: samples,
  );
}
