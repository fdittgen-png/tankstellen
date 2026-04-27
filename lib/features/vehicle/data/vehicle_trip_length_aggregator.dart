import '../../consumption/data/trip_history_repository.dart';
import '../domain/entities/trip_length_breakdown.dart';

/// Below this trip count a length-bucket entry is treated as "not
/// enough data yet" — the aggregator emits `null` for that bucket
/// inside the populated [TripLengthBreakdown].
const int kMinTripsPerLengthBucket = 3;

/// Pure: classify [trips] by length into short / medium / long buckets
/// per the cutoffs on [TripLengthBreakdown] and emit the per-bucket
/// stats.
///
/// Distance-weighted mean is used for `meanLPer100km`:
///   `meanLPer100km = totalLitres / totalDistanceKm * 100`
///
/// That's the right denominator for "average consumption across these
/// trips" — a 1 km trip and a 100 km trip should not contribute equally
/// to the bucket's average (the longer one is more representative of
/// steady-state consumption).
///
/// Trips with `fuelLitersConsumed == null` (cars without PID 5E /
/// MAF) are still counted toward `tripCount` and `totalDistanceKm`
/// but contribute zero litres to the bucket — the resulting mean
/// under-states real consumption proportionally to the no-fuel-data
/// share. Documented here so a future PR that backs into per-vehicle
/// fuel-rate fallbacks (#812 / #874) can revise the rule explicitly.
///
/// Buckets with fewer than [kMinTripsPerLengthBucket] trips are
/// returned as `null` on the [TripLengthBreakdown] — the parent value
/// object distinguishes "not enough data" from "exactly zero" via that
/// nullability.
TripLengthBreakdown aggregateByTripLength(List<TripHistoryEntry> trips) {
  var shortCount = 0;
  var shortDist = 0.0;
  var shortLitres = 0.0;

  var mediumCount = 0;
  var mediumDist = 0.0;
  var mediumLitres = 0.0;

  var longCount = 0;
  var longDist = 0.0;
  var longLitres = 0.0;

  for (final trip in trips) {
    final km = trip.summary.distanceKm;
    final litres = trip.summary.fuelLitersConsumed ?? 0.0;
    if (km < TripLengthBreakdown.shortMaxKm) {
      shortCount++;
      shortDist += km;
      shortLitres += litres;
    } else if (km < TripLengthBreakdown.mediumMaxKm) {
      mediumCount++;
      mediumDist += km;
      mediumLitres += litres;
    } else {
      longCount++;
      longDist += km;
      longLitres += litres;
    }
  }

  return TripLengthBreakdown(
    short: _bucketOrNull(shortCount, shortDist, shortLitres),
    medium: _bucketOrNull(mediumCount, mediumDist, mediumLitres),
    long: _bucketOrNull(longCount, longDist, longLitres),
  );
}

TripLengthBucket? _bucketOrNull(
  int count,
  double totalKm,
  double totalLitres,
) {
  if (count < kMinTripsPerLengthBucket) return null;
  final mean = totalKm > 0 ? totalLitres / totalKm * 100.0 : 0.0;
  return TripLengthBucket(
    tripCount: count,
    meanLPer100km: mean,
    totalDistanceKm: totalKm,
    totalLitres: totalLitres,
  );
}

/// Welford-style fold of one new trip into an existing
/// [TripLengthBreakdown]. Exact for sums + counts; the per-bucket
/// `meanLPer100km` is rederived from the running totals each time, so
/// it tracks the closed-form aggregator output bit-for-bit when no
/// trips are dropped from the rolling log between folds.
///
/// Returns a new immutable breakdown — the input is left untouched.
/// `null` input is allowed (cold-start case): the new trip seeds its
/// own bucket and the other two stay null until they cross the
/// per-bucket threshold via subsequent folds.
TripLengthBreakdown foldTripLengthIncremental(
  TripLengthBreakdown? prior,
  TripHistoryEntry newTrip,
) {
  final base = prior ?? const TripLengthBreakdown();
  final km = newTrip.summary.distanceKm;
  final litres = newTrip.summary.fuelLitersConsumed ?? 0.0;

  if (km < TripLengthBreakdown.shortMaxKm) {
    return base.copyWith(
      short: _foldBucket(base.short, km, litres),
    );
  }
  if (km < TripLengthBreakdown.mediumMaxKm) {
    return base.copyWith(
      medium: _foldBucket(base.medium, km, litres),
    );
  }
  return base.copyWith(
    long: _foldBucket(base.long, km, litres),
  );
}

TripLengthBucket _foldBucket(
  TripLengthBucket? prior,
  double km,
  double litres,
) {
  final priorCount = prior?.tripCount ?? 0;
  final priorKm = prior?.totalDistanceKm ?? 0.0;
  final priorLitres = prior?.totalLitres ?? 0.0;
  final newCount = priorCount + 1;
  final newKm = priorKm + km;
  final newLitres = priorLitres + litres;
  final newMean = newKm > 0 ? newLitres / newKm * 100.0 : 0.0;
  return TripLengthBucket(
    tripCount: newCount,
    meanLPer100km: newMean,
    totalDistanceKm: newKm,
    totalLitres: newLitres,
  );
}
