import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_length_aggregator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic coverage for `aggregateByTripLength` (#1191).
///
/// The aggregator drives `TripLengthBreakdownCard` on the Carbon
/// dashboard; the widget tests pump pre-built [TripLengthBreakdown]
/// values, so the bucket boundary + filter + null-handling logic must
/// be locked down here. Tests cover:
///   * empty + degenerate input → all-zero breakdown
///   * one trip per bucket → trip count + total + average per bucket
///   * boundary at exactly 5.0 km → MEDIUM (lower edge inclusive)
///   * boundary at exactly 25.0 km → MEDIUM (upper edge inclusive)
///   * vehicleId filter — other vehicle excluded, legacy null included
///   * skip when fuelLitersConsumed is null
///   * average computation correctness over multiple trips per bucket
void main() {
  group('aggregateByTripLength — empty / degenerate input', () {
    test('returns the empty breakdown when trips is empty', () {
      final breakdown = aggregateByTripLength(const []);

      expect(breakdown.short.tripCount, 0);
      expect(breakdown.medium.tripCount, 0);
      expect(breakdown.long.tripCount, 0);
      expect(breakdown.short.avgLPer100Km, isNull);
      expect(breakdown.medium.avgLPer100Km, isNull);
      expect(breakdown.long.avgLPer100Km, isNull);
      expect(breakdown.isEmpty, isTrue);
    });

    test('skips trips whose fuelLitersConsumed is null', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 't1', distanceKm: 3.0, fuelLitersConsumed: null),
        _entry(id: 't2', distanceKm: 12.0, fuelLitersConsumed: null),
        _entry(id: 't3', distanceKm: 40.0, fuelLitersConsumed: null),
      ]);

      // Every trip dropped — breakdown is all-zero / empty.
      expect(breakdown.short.tripCount, 0);
      expect(breakdown.medium.tripCount, 0);
      expect(breakdown.long.tripCount, 0);
      expect(breakdown.isEmpty, isTrue);
    });
  });

  group('aggregateByTripLength — bucketing', () {
    test('one trip per bucket lands in the expected slot', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 'short', distanceKm: 3.0, fuelLitersConsumed: 0.4),
        _entry(id: 'medium', distanceKm: 12.0, fuelLitersConsumed: 0.9),
        _entry(id: 'long', distanceKm: 40.0, fuelLitersConsumed: 2.4),
      ]);

      expect(breakdown.short.tripCount, 1);
      expect(breakdown.medium.tripCount, 1);
      expect(breakdown.long.tripCount, 1);

      // Average L/100 km: 0.4 / 3.0 * 100 = 13.333...
      expect(breakdown.short.avgLPer100Km!, closeTo(13.333, 0.01));
      // 0.9 / 12.0 * 100 = 7.5
      expect(breakdown.medium.avgLPer100Km!, closeTo(7.5, 0.01));
      // 2.4 / 40.0 * 100 = 6.0
      expect(breakdown.long.avgLPer100Km!, closeTo(6.0, 0.01));
      expect(breakdown.isEmpty, isFalse);
    });

    test('boundary at exactly 5.0 km lands in MEDIUM (lower edge)', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 'edge-low', distanceKm: 5.0, fuelLitersConsumed: 0.5),
      ]);

      expect(breakdown.short.tripCount, 0);
      expect(breakdown.medium.tripCount, 1);
      expect(breakdown.long.tripCount, 0);
    });

    test('boundary at exactly 25.0 km lands in MEDIUM (upper edge)', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 'edge-high', distanceKm: 25.0, fuelLitersConsumed: 1.5),
      ]);

      expect(breakdown.short.tripCount, 0);
      expect(breakdown.medium.tripCount, 1);
      expect(breakdown.long.tripCount, 0);
    });

    test('a value just past 25.0 km lands in LONG', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 'just-long', distanceKm: 25.001, fuelLitersConsumed: 1.5),
      ]);

      expect(breakdown.medium.tripCount, 0);
      expect(breakdown.long.tripCount, 1);
    });

    test('a value just under 5.0 km lands in SHORT', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 'just-short', distanceKm: 4.999, fuelLitersConsumed: 0.5),
      ]);

      expect(breakdown.short.tripCount, 1);
      expect(breakdown.medium.tripCount, 0);
    });

    test('the boundary constants are 5 km and 25 km', () {
      // Locks down the public constants imported by the widget so a
      // future tweak in the aggregator surfaces here AND in the widget
      // tests, not just on the dashboard at runtime.
      expect(tripLengthShortUpperKm, 5.0);
      expect(tripLengthMediumUpperKm, 25.0);
    });
  });

  group('aggregateByTripLength — vehicleId filter', () {
    test('passing a vehicleId excludes trips for other vehicles', () {
      final breakdown = aggregateByTripLength(
        [
          _entry(
            id: 'mine',
            vehicleId: 'car-a',
            distanceKm: 12.0,
            fuelLitersConsumed: 0.9,
          ),
          _entry(
            id: 'theirs',
            vehicleId: 'car-b',
            distanceKm: 18.0,
            fuelLitersConsumed: 1.4,
          ),
        ],
        vehicleId: 'car-a',
      );

      // Only the matching trip counted.
      expect(breakdown.medium.tripCount, 1);
      expect(breakdown.medium.totalDistanceKm, 12.0);
    });

    test('passing a vehicleId still includes legacy null-vehicleId trips', () {
      final breakdown = aggregateByTripLength(
        [
          _entry(
            id: 'tagged',
            vehicleId: 'car-a',
            distanceKm: 10.0,
            fuelLitersConsumed: 0.7,
          ),
          _entry(
            id: 'legacy',
            vehicleId: null,
            distanceKm: 14.0,
            fuelLitersConsumed: 1.0,
          ),
        ],
        vehicleId: 'car-a',
      );

      // Both trips count — legacy null-vehicleId is treated as "could
      // be this vehicle" per the trajets-tab convention.
      expect(breakdown.medium.tripCount, 2);
      expect(breakdown.medium.totalDistanceKm, closeTo(24.0, 0.001));
    });

    test('null vehicleId includes every trip regardless of tag', () {
      final breakdown = aggregateByTripLength([
        _entry(
          id: 'a',
          vehicleId: 'car-a',
          distanceKm: 10.0,
          fuelLitersConsumed: 0.7,
        ),
        _entry(
          id: 'b',
          vehicleId: 'car-b',
          distanceKm: 14.0,
          fuelLitersConsumed: 1.0,
        ),
        _entry(
          id: 'legacy',
          vehicleId: null,
          distanceKm: 12.0,
          fuelLitersConsumed: 0.9,
        ),
      ]);

      // No filter — every trip lands in medium.
      expect(breakdown.medium.tripCount, 3);
    });
  });

  group('aggregateByTripLength — average correctness', () {
    test('two medium trips combine into one weighted average', () {
      final breakdown = aggregateByTripLength([
        _entry(id: 't1', distanceKm: 10.0, fuelLitersConsumed: 0.5),
        _entry(id: 't2', distanceKm: 20.0, fuelLitersConsumed: 1.5),
      ]);

      // Combined: 30 km / 2 L → 6.667 L/100 km.
      expect(breakdown.medium.tripCount, 2);
      expect(breakdown.medium.totalDistanceKm, closeTo(30.0, 0.001));
      expect(breakdown.medium.totalLitres, closeTo(2.0, 0.001));
      expect(breakdown.medium.avgLPer100Km!, closeTo(6.667, 0.01));
    });

    test('mixed buckets in one call — no cross-bucket bleed', () {
      final breakdown = aggregateByTripLength([
        // Two short trips
        _entry(id: 's1', distanceKm: 2.0, fuelLitersConsumed: 0.3),
        _entry(id: 's2', distanceKm: 4.0, fuelLitersConsumed: 0.5),
        // One long trip
        _entry(id: 'l1', distanceKm: 100.0, fuelLitersConsumed: 5.0),
      ]);

      expect(breakdown.short.tripCount, 2);
      expect(breakdown.short.totalDistanceKm, closeTo(6.0, 0.001));
      expect(breakdown.short.totalLitres, closeTo(0.8, 0.001));
      // 0.8 / 6.0 * 100 = 13.333
      expect(breakdown.short.avgLPer100Km!, closeTo(13.333, 0.01));

      // Medium left empty — short trips MUST not bleed into medium.
      expect(breakdown.medium.tripCount, 0);
      expect(breakdown.medium.avgLPer100Km, isNull);

      expect(breakdown.long.tripCount, 1);
      expect(breakdown.long.avgLPer100Km!, closeTo(5.0, 0.001));
    });
  });
}

/// Convenience constructor for a [TripHistoryEntry] in this file's
/// tests. Only fields the aggregator reads are exposed; everything
/// else gets a sensible default that makes the trip parse without
/// being meaningful for these assertions.
TripHistoryEntry _entry({
  required String id,
  String? vehicleId,
  required double distanceKm,
  required double? fuelLitersConsumed,
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
      fuelLitersConsumed: fuelLitersConsumed,
    ),
  );
}
