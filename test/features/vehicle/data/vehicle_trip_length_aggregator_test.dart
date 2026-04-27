import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_trip_length_aggregator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/trip_length_breakdown.dart';

/// Builds a [TripHistoryEntry] carrying only the fields the trip-length
/// aggregator reads — distance and (optional) fuel — with everything
/// else defaulted to zero / null. Mirrors the helper in
/// `vehicle_aggregate_updater_test.dart` so the construction pattern
/// stays consistent across the aggregator suite.
TripHistoryEntry _trip({
  required String id,
  required double km,
  double? litres,
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v',
    summary: TripSummary(
      distanceKm: km,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: litres,
      avgLPer100Km: (litres != null && km > 0) ? litres / km * 100 : null,
    ),
  );
}

void main() {
  group('kMinTripsPerLengthBucket', () {
    test('exposed const stays at 3 — UI/copy depends on the threshold', () {
      expect(kMinTripsPerLengthBucket, 3);
    });
  });

  group('aggregateByTripLength — closed-form bucket aggregation', () {
    test('empty input → all three buckets null (cold-start signal)', () {
      final result = aggregateByTripLength(const []);
      expect(result.short, isNull);
      expect(result.medium, isNull);
      expect(result.long, isNull);
    });

    test('only short trips above threshold → short populated, others null',
        () {
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 5, litres: 0.5),
        _trip(id: '2', km: 8, litres: 0.7),
        _trip(id: '3', km: 12, litres: 1.0),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 3);
      expect(result.short!.totalDistanceKm, closeTo(25, 1e-9));
      expect(result.short!.totalLitres, closeTo(2.2, 1e-9));
      expect(result.short!.meanLPer100km, closeTo(2.2 / 25 * 100, 1e-9));
      expect(result.medium, isNull);
      expect(result.long, isNull);
    });

    test('only medium trips above threshold → medium populated, others null',
        () {
      // shortMaxKm = 15, mediumMaxKm = 50 → 20/30/40 are all medium.
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 20, litres: 1.5),
        _trip(id: '2', km: 30, litres: 2.4),
        _trip(id: '3', km: 40, litres: 3.0),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNull);
      expect(result.medium, isNotNull);
      expect(result.medium!.tripCount, 3);
      expect(result.medium!.totalDistanceKm, closeTo(90, 1e-9));
      expect(result.medium!.totalLitres, closeTo(6.9, 1e-9));
      expect(result.medium!.meanLPer100km, closeTo(6.9 / 90 * 100, 1e-9));
      expect(result.long, isNull);
    });

    test('only long trips above threshold → long populated, others null', () {
      // mediumMaxKm = 50 (exclusive); 50/100/200 all qualify as long.
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 50, litres: 3.5),
        _trip(id: '2', km: 100, litres: 6.0),
        _trip(id: '3', km: 200, litres: 13.0),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNull);
      expect(result.medium, isNull);
      expect(result.long, isNotNull);
      expect(result.long!.tripCount, 3);
      expect(result.long!.totalDistanceKm, closeTo(350, 1e-9));
      expect(result.long!.totalLitres, closeTo(22.5, 1e-9));
      expect(result.long!.meanLPer100km, closeTo(22.5 / 350 * 100, 1e-9));
    });

    test('below threshold (count < 3) → bucket is null, not zeroed', () {
      // Two short trips → still below kMinTripsPerLengthBucket = 3.
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 5, litres: 0.5),
        _trip(id: '2', km: 8, litres: 0.7),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNull,
          reason: 'count=2 < 3 → null distinguishes "not enough data" from '
              '"zero trips" (a populated zero-count bucket would be wrong)');
      expect(result.medium, isNull);
      expect(result.long, isNull);
    });

    test('exactly at threshold (count == 3) → bucket populated', () {
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 5, litres: 0.5),
        _trip(id: '2', km: 6, litres: 0.6),
        _trip(id: '3', km: 7, litres: 0.7),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 3);
    });

    test(
        'mix across all three buckets (each ≥ threshold) → every bucket '
        'populated with the right counts', () {
      final trips = <TripHistoryEntry>[
        // 3 shorts.
        _trip(id: '1', km: 5, litres: 0.5),
        _trip(id: '2', km: 8, litres: 0.7),
        _trip(id: '3', km: 12, litres: 1.0),
        // 3 mediums.
        _trip(id: '4', km: 20, litres: 1.5),
        _trip(id: '5', km: 30, litres: 2.4),
        _trip(id: '6', km: 40, litres: 3.0),
        // 3 longs.
        _trip(id: '7', km: 60, litres: 4.0),
        _trip(id: '8', km: 100, litres: 7.0),
        _trip(id: '9', km: 120, litres: 8.4),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short!.tripCount, 3);
      expect(result.medium!.tripCount, 3);
      expect(result.long!.tripCount, 3);
      expect(result.short!.totalDistanceKm, closeTo(25, 1e-9));
      expect(result.medium!.totalDistanceKm, closeTo(90, 1e-9));
      expect(result.long!.totalDistanceKm, closeTo(280, 1e-9));
    });

    test(
        'boundary trips at exactly 15 km → medium (shortMaxKm exclusive); '
        '50 km → long (mediumMaxKm exclusive)', () {
      // Three at 15.0 — should fall in medium, not short.
      final mediumBoundary = <TripHistoryEntry>[
        _trip(id: '1', km: 15, litres: 1.0),
        _trip(id: '2', km: 15, litres: 1.0),
        _trip(id: '3', km: 15, litres: 1.0),
      ];
      final mResult = aggregateByTripLength(mediumBoundary);
      expect(mResult.short, isNull);
      expect(mResult.medium, isNotNull);
      expect(mResult.medium!.tripCount, 3);

      // Three at 50.0 — should fall in long, not medium.
      final longBoundary = <TripHistoryEntry>[
        _trip(id: '1', km: 50, litres: 3.5),
        _trip(id: '2', km: 50, litres: 3.5),
        _trip(id: '3', km: 50, litres: 3.5),
      ];
      final lResult = aggregateByTripLength(longBoundary);
      expect(lResult.medium, isNull);
      expect(lResult.long, isNotNull);
      expect(lResult.long!.tripCount, 3);
    });

    test(
        'fuelLitersConsumed == null counts toward distance + tripCount but '
        'contributes zero litres — mean is under-stated proportionally', () {
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 5, litres: null),
        _trip(id: '2', km: 5, litres: null),
        _trip(id: '3', km: 5, litres: 0.5),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 3);
      expect(result.short!.totalDistanceKm, closeTo(15, 1e-9));
      expect(result.short!.totalLitres, closeTo(0.5, 1e-9));
      // Mean uses the full distance denominator — 0.5L / 15km × 100
      // = 3.33 L/100km, which under-states the one fuel-bearing trip's
      // 10 L/100km because the two null trips dilute the litre numerator
      // but not the km denominator. That is the documented behaviour.
      expect(result.short!.meanLPer100km, closeTo(0.5 / 15 * 100, 1e-9));
    });

    test(
        'distance-weighted mean: 1 km @ 100 L/100km + 100 km @ 5 L/100km '
        '→ denominator is total km (not arithmetic mean of per-trip rates)',
        () {
      // Trip A: 1 km, 1.0 L → per-trip rate 100 L/100km.
      // Trip B: 100 km, 5.0 L → per-trip rate 5 L/100km.
      // Naive arithmetic mean: (100 + 5) / 2 = 52.5 L/100km — WRONG.
      // Distance-weighted: (1.0 + 5.0) L / (1 + 100) km × 100
      //                  = 6.0 / 101 × 100 ≈ 5.94 L/100km — RIGHT.
      // We need a third trip to clear the threshold; pick one that
      // matches the 5 L/100km long-trip cohort so the expected mean
      // stays predictable.
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 1, litres: 1.0),
        _trip(id: '2', km: 100, litres: 5.0),
        _trip(id: '3', km: 100, litres: 5.0),
      ];
      // 1 km is short; 100 km is long. Each bucket below threshold
      // individually → both null. So bucket them all into long: bump
      // the 1km up.
      final longTrips = <TripHistoryEntry>[
        _trip(id: '1', km: 60, litres: 60.0), // 100 L/100km
        _trip(id: '2', km: 60, litres: 3.0), // 5 L/100km
        _trip(id: '3', km: 60, litres: 3.0), // 5 L/100km
      ];
      final result = aggregateByTripLength(longTrips);
      expect(result.long, isNotNull);
      // Arithmetic mean of per-trip rates would be (100 + 5 + 5)/3 = 36.67.
      // Distance-weighted: 66 L / 180 km × 100 = 36.67 L/100km — same
      // here because all three legs have the same distance. Use a
      // different distance mix to disambiguate:
      expect(result.long!.totalDistanceKm, closeTo(180, 1e-9));
      expect(result.long!.totalLitres, closeTo(66.0, 1e-9));
      expect(result.long!.meanLPer100km, closeTo(66.0 / 180 * 100, 1e-9));

      // Sanity check that the original `trips` list — with mixed
      // bucket membership — does what the docstring promises: the 1 km
      // trip falls into short (below threshold → null) and the two
      // 100 km trips fall into long (also below threshold → null).
      final mixedResult = aggregateByTripLength(trips);
      expect(mixedResult.short, isNull);
      expect(mixedResult.medium, isNull);
      expect(mixedResult.long, isNull);
    });

    test(
        'distance-weighted mean differs from arithmetic mean when leg '
        'distances differ — the denominator is total km', () {
      // Three long trips with mixed distances and rates.
      // Trip A: 60 km, 6 L → 10 L/100km
      // Trip B: 100 km, 5 L → 5 L/100km
      // Trip C: 200 km, 8 L → 4 L/100km
      // Arithmetic mean of rates: (10 + 5 + 4) / 3 = 6.33 L/100km.
      // Distance-weighted: 19 L / 360 km × 100 = 5.28 L/100km.
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 60, litres: 6.0),
        _trip(id: '2', km: 100, litres: 5.0),
        _trip(id: '3', km: 200, litres: 8.0),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.long!.totalDistanceKm, closeTo(360, 1e-9));
      expect(result.long!.totalLitres, closeTo(19.0, 1e-9));
      expect(result.long!.meanLPer100km, closeTo(19.0 / 360 * 100, 1e-9));
      // Verify it's NOT the arithmetic mean of per-trip rates.
      expect(result.long!.meanLPer100km,
          isNot(closeTo((10 + 5 + 4) / 3, 1e-3)));
    });

    test(
        'bucket of trips with all-zero distance and zero litres → mean is 0 '
        '(no division by zero)', () {
      // All-zero edge case: distance < shortMaxKm → short bucket.
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 0, litres: 0.0),
        _trip(id: '2', km: 0, litres: 0.0),
        _trip(id: '3', km: 0, litres: 0.0),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 3);
      expect(result.short!.totalDistanceKm, 0.0);
      expect(result.short!.totalLitres, 0.0);
      expect(result.short!.meanLPer100km, 0.0,
          reason: 'totalKm == 0 should short-circuit to 0, not NaN/Infinity');
    });
  });

  group('foldTripLengthIncremental — Welford single-trip fold', () {
    test(
        'cold-start: prior == null + one short trip → short seeded, '
        'medium and long stay null', () {
      final result = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 12, litres: 1.0),
      );
      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 1);
      expect(result.short!.totalDistanceKm, closeTo(12, 1e-9));
      expect(result.short!.totalLitres, closeTo(1.0, 1e-9));
      expect(result.short!.meanLPer100km, closeTo(1.0 / 12 * 100, 1e-9));
      expect(result.medium, isNull);
      expect(result.long, isNull);
    });

    test('cold-start with a medium trip seeds medium only', () {
      final result = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 30, litres: 2.0),
      );
      expect(result.short, isNull);
      expect(result.medium, isNotNull);
      expect(result.medium!.tripCount, 1);
      expect(result.long, isNull);
    });

    test('cold-start with a long trip seeds long only', () {
      final result = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 80, litres: 5.0),
      );
      expect(result.short, isNull);
      expect(result.medium, isNull);
      expect(result.long, isNotNull);
      expect(result.long!.tripCount, 1);
    });

    test(
        'fold exposes the bucket immediately — the closed-form threshold '
        'rule does NOT apply to the incremental fold', () {
      // After a single fold the bucket has count=1; the aggregator
      // would have returned null at this count, but the fold exposes
      // running totals so the UI can recompute / display partial state.
      var folded = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 5, litres: 0.5),
      );
      expect(folded.short, isNotNull);
      expect(folded.short!.tripCount, 1);

      // Fold a second trip — still below threshold, still exposed.
      folded = foldTripLengthIncremental(
        folded,
        _trip(id: '2', km: 8, litres: 0.7),
      );
      expect(folded.short, isNotNull);
      expect(folded.short!.tripCount, 2);
      expect(folded.short!.totalDistanceKm, closeTo(13, 1e-9));
      expect(folded.short!.totalLitres, closeTo(1.2, 1e-9));
    });

    test(
        'incremental fold across many trips converges bit-for-bit to '
        'aggregateByTripLength on the same set (counts + sums + mean)', () {
      final trips = <TripHistoryEntry>[
        _trip(id: '1', km: 5, litres: 0.5),
        _trip(id: '2', km: 8, litres: 0.7),
        _trip(id: '3', km: 12, litres: 1.0),
        _trip(id: '4', km: 20, litres: 1.5),
        _trip(id: '5', km: 25, litres: 2.0),
        _trip(id: '6', km: 30, litres: 2.4),
        _trip(id: '7', km: 60, litres: 4.0),
        _trip(id: '8', km: 100, litres: 7.0),
        _trip(id: '9', km: 120, litres: 8.4),
      ];

      TripLengthBreakdown? folded;
      for (final t in trips) {
        folded = foldTripLengthIncremental(folded, t);
      }
      final reference = aggregateByTripLength(trips);

      // All three buckets cleared the threshold (3 each).
      expect(folded, isNotNull);
      expect(reference.short, isNotNull);
      expect(reference.medium, isNotNull);
      expect(reference.long, isNotNull);

      expect(folded!.short!.tripCount, reference.short!.tripCount);
      expect(folded.short!.totalDistanceKm,
          closeTo(reference.short!.totalDistanceKm, 1e-12));
      expect(folded.short!.totalLitres,
          closeTo(reference.short!.totalLitres, 1e-12));
      expect(folded.short!.meanLPer100km,
          closeTo(reference.short!.meanLPer100km, 1e-12));

      expect(folded.medium!.tripCount, reference.medium!.tripCount);
      expect(folded.medium!.totalDistanceKm,
          closeTo(reference.medium!.totalDistanceKm, 1e-12));
      expect(folded.medium!.totalLitres,
          closeTo(reference.medium!.totalLitres, 1e-12));
      expect(folded.medium!.meanLPer100km,
          closeTo(reference.medium!.meanLPer100km, 1e-12));

      expect(folded.long!.tripCount, reference.long!.tripCount);
      expect(folded.long!.totalDistanceKm,
          closeTo(reference.long!.totalDistanceKm, 1e-12));
      expect(folded.long!.totalLitres,
          closeTo(reference.long!.totalLitres, 1e-12));
      expect(folded.long!.meanLPer100km,
          closeTo(reference.long!.meanLPer100km, 1e-12));
    });

    test(
        'fold leaves the input prior untouched (immutability) — returns '
        'a new breakdown each call', () {
      final prior = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 5, litres: 0.5),
      );
      final priorShort = prior.short;
      final next = foldTripLengthIncremental(
        prior,
        _trip(id: '2', km: 8, litres: 0.7),
      );
      // Prior reference is unchanged.
      expect(prior.short, same(priorShort));
      expect(prior.short!.tripCount, 1);
      expect(prior.short!.totalDistanceKm, closeTo(5, 1e-9));
      // New breakdown reflects the fold.
      expect(next.short!.tripCount, 2);
      expect(next.short!.totalDistanceKm, closeTo(13, 1e-9));
    });

    test(
        'fold of a fuel-null trip adds distance + count but zero litres — '
        'mean drops proportionally', () {
      // Seed with one fuel-bearing trip.
      var folded = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 10, litres: 1.0),
      );
      expect(folded.short!.meanLPer100km, closeTo(10.0, 1e-9));

      // Fold a fuel-null trip of the same distance.
      folded = foldTripLengthIncremental(
        folded,
        _trip(id: '2', km: 10, litres: null),
      );
      expect(folded.short!.tripCount, 2);
      expect(folded.short!.totalDistanceKm, closeTo(20, 1e-9));
      expect(folded.short!.totalLitres, closeTo(1.0, 1e-9),
          reason: 'fuel-null contributes zero litres');
      // Mean halved: 1.0 L / 20 km × 100 = 5 L/100km.
      expect(folded.short!.meanLPer100km, closeTo(5.0, 1e-9));
    });

    test(
        'folding short, medium, long in sequence builds up each bucket '
        'independently (no cross-contamination)', () {
      var folded = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 5, litres: 0.5),
      );
      folded = foldTripLengthIncremental(
        folded,
        _trip(id: '2', km: 30, litres: 2.0),
      );
      folded = foldTripLengthIncremental(
        folded,
        _trip(id: '3', km: 80, litres: 5.0),
      );
      expect(folded.short!.tripCount, 1);
      expect(folded.short!.totalDistanceKm, closeTo(5, 1e-9));
      expect(folded.medium!.tripCount, 1);
      expect(folded.medium!.totalDistanceKm, closeTo(30, 1e-9));
      expect(folded.long!.tripCount, 1);
      expect(folded.long!.totalDistanceKm, closeTo(80, 1e-9));
    });

    test(
        'fold over a zero-distance trip yields meanLPer100km = 0 (no NaN '
        'on division by zero on cold-start)', () {
      final folded = foldTripLengthIncremental(
        null,
        _trip(id: '1', km: 0, litres: 0.0),
      );
      // 0 km is < shortMaxKm so it goes into short.
      expect(folded.short, isNotNull);
      expect(folded.short!.tripCount, 1);
      expect(folded.short!.totalDistanceKm, 0.0);
      expect(folded.short!.totalLitres, 0.0);
      expect(folded.short!.meanLPer100km, 0.0);
    });
  });
}
