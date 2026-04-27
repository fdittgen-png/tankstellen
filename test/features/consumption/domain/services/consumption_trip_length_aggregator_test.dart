import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/services/consumption_trip_length_aggregator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Builds a finalised trip carrying just the fields the cold-start
/// aggregator needs — distance, fuel litres, vehicleId. Other summary
/// fields default to neutral values.
TripHistoryEntry _trip({
  required String id,
  required double distanceKm,
  double? fuelLitersConsumed,
  String? vehicleId,
}) {
  final summary = TripSummary(
    distanceKm: distanceKm,
    maxRpm: 0,
    highRpmSeconds: 0,
    idleSeconds: 0,
    harshBrakes: 0,
    harshAccelerations: 0,
    fuelLitersConsumed: fuelLitersConsumed,
    avgLPer100Km: (fuelLitersConsumed != null && distanceKm > 0)
        ? (fuelLitersConsumed / distanceKm) * 100.0
        : null,
  );
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: summary,
  );
}

void main() {
  group('aggregateConsumptionByTripLength', () {
    test('returns empty breakdown for an empty trip list', () {
      final out = aggregateConsumptionByTripLength(const []);
      expect(out, ConsumptionTripLengthBreakdown.empty);
      expect(out.isEmpty, isTrue);
      expect(out.overallAvgLPer100Km, isNull);
    });

    test('a single short trip lands only in the short bucket', () {
      final trips = [
        _trip(id: 't1', distanceKm: 3.0, fuelLitersConsumed: 0.4),
      ];
      final out = aggregateConsumptionByTripLength(trips);

      expect(out.short.tripCount, 1);
      expect(out.short.totalDistanceKm, closeTo(3.0, 1e-9));
      expect(out.short.totalLitres, closeTo(0.4, 1e-9));
      expect(out.short.avgLPer100Km, closeTo(0.4 / 3.0 * 100.0, 1e-9));

      expect(out.medium, ConsumptionTripLengthBucketStats.empty);
      expect(out.long, ConsumptionTripLengthBucketStats.empty);
    });

    test('all three buckets populate independently', () {
      // Two short trips: 2 km + 4 km, 0.3 + 0.5 L.
      // Two medium trips: 10 km + 20 km, 0.6 + 1.4 L.
      // One long trip: 60 km, 3.6 L.
      final trips = [
        _trip(id: 's1', distanceKm: 2.0, fuelLitersConsumed: 0.3),
        _trip(id: 's2', distanceKm: 4.0, fuelLitersConsumed: 0.5),
        _trip(id: 'm1', distanceKm: 10.0, fuelLitersConsumed: 0.6),
        _trip(id: 'm2', distanceKm: 20.0, fuelLitersConsumed: 1.4),
        _trip(id: 'l1', distanceKm: 60.0, fuelLitersConsumed: 3.6),
      ];
      final out = aggregateConsumptionByTripLength(trips);

      expect(out.short.tripCount, 2);
      expect(out.short.totalDistanceKm, closeTo(6.0, 1e-9));
      expect(out.short.totalLitres, closeTo(0.8, 1e-9));
      expect(
        out.short.avgLPer100Km,
        closeTo(0.8 / 6.0 * 100.0, 1e-9),
      );

      expect(out.medium.tripCount, 2);
      expect(out.medium.totalDistanceKm, closeTo(30.0, 1e-9));
      expect(out.medium.totalLitres, closeTo(2.0, 1e-9));
      expect(
        out.medium.avgLPer100Km,
        closeTo(2.0 / 30.0 * 100.0, 1e-9),
      );

      expect(out.long.tripCount, 1);
      expect(out.long.totalDistanceKm, closeTo(60.0, 1e-9));
      expect(out.long.totalLitres, closeTo(3.6, 1e-9));
      expect(
        out.long.avgLPer100Km,
        closeTo(3.6 / 60.0 * 100.0, 1e-9),
      );

      // Overall: 0.8 + 2.0 + 3.6 L over 96 km.
      expect(
        out.overallAvgLPer100Km,
        closeTo(6.4 / 96.0 * 100.0, 1e-9),
      );
    });

    test('vehicleId filter excludes other vehicles entirely', () {
      final trips = [
        _trip(
          id: 'a',
          distanceKm: 4.0,
          fuelLitersConsumed: 0.5,
          vehicleId: 'car-A',
        ),
        _trip(
          id: 'b',
          distanceKm: 30.0,
          fuelLitersConsumed: 2.0,
          vehicleId: 'car-B',
        ),
      ];
      final outA = aggregateConsumptionByTripLength(trips, vehicleId: 'car-A');

      expect(outA.short.tripCount, 1);
      expect(outA.long.tripCount, 0);
      expect(outA.medium.tripCount, 0);

      final outB = aggregateConsumptionByTripLength(trips, vehicleId: 'car-B');
      expect(outB.long.tripCount, 1);
      expect(outB.short.tripCount, 0);
    });

    test('boundary at exactly 5.0 km belongs to medium', () {
      final trips = [
        _trip(id: 'b5', distanceKm: 5.0, fuelLitersConsumed: 0.4),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.short.tripCount, 0);
      expect(out.medium.tripCount, 1);
      expect(out.long.tripCount, 0);
    });

    test('boundary at exactly 25.0 km belongs to long', () {
      final trips = [
        _trip(id: 'b25', distanceKm: 25.0, fuelLitersConsumed: 1.5),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.short.tripCount, 0);
      expect(out.medium.tripCount, 0);
      expect(out.long.tripCount, 1);
    });

    test('just-below boundary at 4.999 km stays in short', () {
      final trips = [
        _trip(id: 'b', distanceKm: 4.999, fuelLitersConsumed: 0.4),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.short.tripCount, 1);
      expect(out.medium.tripCount, 0);
    });

    test('just-below boundary at 24.999 km stays in medium', () {
      final trips = [
        _trip(id: 'b', distanceKm: 24.999, fuelLitersConsumed: 1.5),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.medium.tripCount, 1);
      expect(out.long.tripCount, 0);
    });

    test('trip with null fuelLitersConsumed is excluded from every bucket',
        () {
      final trips = [
        // Short distance but no fuel signal — must drop.
        _trip(id: 'no-fuel', distanceKm: 3.0, fuelLitersConsumed: null),
        // Valid trip in the same bucket so we can confirm only the
        // null-fuel one was dropped.
        _trip(id: 'ok', distanceKm: 4.0, fuelLitersConsumed: 0.5),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.short.tripCount, 1);
      expect(out.short.totalDistanceKm, closeTo(4.0, 1e-9));
      expect(out.short.totalLitres, closeTo(0.5, 1e-9));
    });

    test('trip with zero distance is excluded from every bucket', () {
      final trips = [
        _trip(id: 'zero', distanceKm: 0.0, fuelLitersConsumed: 0.5),
        _trip(id: 'neg', distanceKm: -1.0, fuelLitersConsumed: 0.2),
        _trip(id: 'ok', distanceKm: 6.0, fuelLitersConsumed: 0.5),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.short.tripCount, 0);
      expect(out.medium.tripCount, 1);
      expect(out.long.tripCount, 0);
    });

    test('empty bucket has avgLPer100Km == null', () {
      final trips = [
        _trip(id: 'l1', distanceKm: 50.0, fuelLitersConsumed: 3.0),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      expect(out.short.tripCount, 0);
      expect(out.short.avgLPer100Km, isNull);
      expect(out.medium.avgLPer100Km, isNull);
      expect(out.long.avgLPer100Km, isNotNull);
    });

    test(
        'overallAvgLPer100Km matches the union of qualifying trips '
        '(not a per-bucket average)', () {
      // Verify the overall is sum-of-litres / sum-of-km, not an
      // arithmetic mean of bucket averages — those would diverge when
      // bucket sizes differ.
      final trips = [
        _trip(id: 's', distanceKm: 2.0, fuelLitersConsumed: 0.4),
        _trip(id: 'm', distanceKm: 10.0, fuelLitersConsumed: 0.6),
        _trip(id: 'l', distanceKm: 100.0, fuelLitersConsumed: 5.0),
      ];
      final out = aggregateConsumptionByTripLength(trips);
      // 6.0 L / 112 km * 100 = 5.357 L/100 km
      expect(
        out.overallAvgLPer100Km,
        closeTo(6.0 / 112.0 * 100.0, 1e-9),
      );
    });
  });
}
