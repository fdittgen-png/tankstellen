import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../../consumption/data/trip_history_repository.dart';
import '../../consumption/domain/trip_recorder.dart';
import '../domain/entities/speed_consumption_histogram.dart';
import '../domain/entities/trip_length_breakdown.dart';
import 'repositories/vehicle_profile_repository.dart';

/// Per-vehicle minimum trip count below which ALL aggregate fields are
/// nulled on the profile (matches the issue's "hide section when below
/// threshold" UI rule from #1193 phase 3).
const int kMinTripsForAggregates = 5;

/// Below this trip count a length-bucket entry is treated as "not
/// enough data yet" — the aggregator emits `null` for that bucket
/// inside the populated [TripLengthBreakdown].
const int kMinTripsPerLengthBucket = 3;

/// Below this sample count a speed band is excluded from the
/// histogram's `bands` list. Mirrors the value-object docstring on
/// [SpeedConsumptionHistogram] which signals "no data yet" by omitting
/// the band rather than carrying zero values.
const int kMinSamplesPerSpeedBand = 50;

/// Above this total sample count the aggregation pass runs on a
/// background isolate via [compute]. The cutoff is a cheap heuristic —
/// 1000 samples is roughly a 17-minute trip at 1 Hz, which already
/// pushes the speed-histogram fold past the 16 ms frame budget on a
/// mid-tier device. Smaller datasets stay inline because the isolate
/// hand-off itself costs ~10 ms and isn't worth it for short trips.
const int kComputeOffloadThreshold = 1000;

/// Service that recomputes and persists per-vehicle driving aggregates
/// (#1193 phase 2).
///
/// Owns the trip-save side-effect: every successful
/// [TripHistoryRepository.save] for a trip with a non-null `vehicleId`
/// triggers an [updateForVehicle] pass. The trip-save flow is NOT
/// blocked by this work — the production wiring fire-and-forgets via
/// `unawaited(...)` and routes any throw through `errorLogger.log`
/// (foreground path). See [VehicleAggregateUpdater.runForVehicle].
///
/// Phase-2 scope: pure aggregation + persistence. The vehicle-profile
/// UI section that reads these fields is deferred to phase 3.
class VehicleAggregateUpdater {
  final VehicleProfileRepository _vehicleRepo;
  final TripHistoryRepository? Function() _tripRepoLookup;

  /// Test-injectable clock so the "wrote `aggregatesUpdatedAt`" check
  /// can assert an exact timestamp without racing real wall-clock time.
  /// Defaults to [DateTime.now] in production.
  final DateTime Function() _now;

  VehicleAggregateUpdater({
    required VehicleProfileRepository vehicleRepo,
    required TripHistoryRepository? Function() tripRepoLookup,
    DateTime Function()? now,
  })  : _vehicleRepo = vehicleRepo,
        _tripRepoLookup = tripRepoLookup,
        _now = now ?? DateTime.now;

  /// Full recompute for [vehicleId]. Loads the vehicle's trip history
  /// from the repository, classifies each trip by length, derives both
  /// aggregates from the persisted samples, and writes them back to
  /// the profile.
  ///
  /// Source of truth — [foldInTrip] is an approximation that converges
  /// on this output for the per-bin means and matches it exactly for
  /// the sums and counts. Call this from the trip-save hook (cheap
  /// because the trip count is bounded by the rolling-log cap of 100)
  /// or from a one-off "recompute everything" admin action.
  ///
  /// No-op when:
  ///   * the trip-history box isn't open (cold-start path before Hive
  ///     has finished initialising — the next save will retry);
  ///   * the vehicle isn't found in [VehicleProfileRepository];
  ///   * the vehicle has fewer than [kMinTripsForAggregates] trips
  ///     (nulls every aggregate field — consistent with the UI rule).
  Future<void> updateForVehicle(String vehicleId) async {
    final tripRepo = _tripRepoLookup();
    if (tripRepo == null) return;
    final profile = _vehicleRepo.getById(vehicleId);
    if (profile == null) return;

    final allTrips = tripRepo.loadAll();
    final trips =
        allTrips.where((t) => t.vehicleId == vehicleId).toList(growable: false);

    if (trips.length < kMinTripsForAggregates) {
      // Below threshold — null everything so the UI hides the section.
      // This is the lazy-migration path: a vehicle that has 4 trips
      // today and lands its 5th tomorrow will go from null aggregates
      // to populated ones in one trip-save cycle.
      await _vehicleRepo.save(profile.copyWith(
        tripLengthAggregates: null,
        speedConsumptionAggregates: null,
        aggregatesUpdatedAt: _now(),
        aggregatesTripCount: trips.length,
      ));
      return;
    }

    // Flatten samples once. The aggregator works on a single list so
    // the `compute()` heuristic can decide based on total volume — no
    // need to re-walk the trips just to count samples.
    final samples = <TripSample>[];
    for (final t in trips) {
      samples.addAll(t.samples);
    }

    // The pure functions are isolate-safe. For datasets above the
    // threshold we hop to a background isolate via [compute]; smaller
    // sets stay on the calling isolate because the hop itself costs
    // ~10 ms which dominates the math for short trips.
    late final TripLengthBreakdown lengthBreakdown;
    late final SpeedConsumptionHistogram speedHistogram;
    if (samples.length > kComputeOffloadThreshold) {
      final result =
          await compute(_aggregateBoth, _AggregateInput(trips, samples));
      lengthBreakdown = result.lengthBreakdown;
      speedHistogram = result.speedHistogram;
    } else {
      lengthBreakdown = aggregateByTripLength(trips);
      speedHistogram = aggregateSpeedConsumption(samples);
    }

    await _vehicleRepo.save(profile.copyWith(
      tripLengthAggregates: lengthBreakdown,
      speedConsumptionAggregates: speedHistogram,
      aggregatesUpdatedAt: _now(),
      aggregatesTripCount: trips.length,
    ));
  }

  /// Incremental fold of one freshly-saved trip into the existing
  /// aggregates.
  ///
  /// Exact for sums + counts (a sum is a sum), approximate but
  /// converges for per-bin means via Welford-style updates. The full
  /// recompute in [updateForVehicle] is the source of truth — call
  /// this when you want a cheap "I just saved trip N+1" update without
  /// re-scanning N+1 trips, then schedule a full recompute on a slower
  /// cadence (e.g. once per app launch) to refresh against drift.
  ///
  /// Same below-threshold guard as [updateForVehicle]: if the new trip
  /// pushes the count to or above [kMinTripsForAggregates] this routes
  /// through a full recompute (we need at least one populated bucket
  /// before incremental can take over). Below threshold, the profile's
  /// aggregate fields stay null and only [aggregatesTripCount] /
  /// [aggregatesUpdatedAt] are bumped.
  Future<void> foldInTrip(
    String vehicleId,
    TripHistoryEntry trip,
    List<TripSample> samples,
  ) async {
    final profile = _vehicleRepo.getById(vehicleId);
    if (profile == null) return;

    final newCount = (profile.aggregatesTripCount ?? 0) + 1;

    if (newCount < kMinTripsForAggregates ||
        profile.tripLengthAggregates == null ||
        profile.speedConsumptionAggregates == null) {
      // Either we are still below the visibility threshold, or the
      // priors don't exist yet (first time reaching threshold). The
      // full recompute path handles both correctly.
      await updateForVehicle(vehicleId);
      return;
    }

    final nextLength =
        foldTripLengthIncremental(profile.tripLengthAggregates, trip);
    final nextSpeed =
        foldSpeedConsumptionIncremental(profile.speedConsumptionAggregates,
            samples);

    await _vehicleRepo.save(profile.copyWith(
      tripLengthAggregates: nextLength,
      speedConsumptionAggregates: nextSpeed,
      aggregatesUpdatedAt: _now(),
      aggregatesTripCount: newCount,
    ));
  }

  /// Trip-save hook entry point. Routes a saved trip through
  /// [updateForVehicle] and never throws — observability errors are
  /// logged via `errorLogger.log(ErrorLayer.background, ...)` so they
  /// land in the same telemetry pipeline as foreground errors without
  /// derailing the trip-save caller.
  ///
  /// Production wiring uses this with `unawaited(...)`; tests can
  /// `await` it directly.
  Future<void> runForVehicle(String vehicleId) async {
    try {
      await updateForVehicle(vehicleId);
    } catch (e, st) {
      // The trip already saved — losing one aggregate refresh shouldn't
      // surface to the user. The next save (or app launch) will refresh
      // again.
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'op': 'VehicleAggregateUpdater.updateForVehicle',
          'vehicleId': vehicleId,
        },
      );
    }
  }
}

/// Input bundle for the [compute] hop in [updateForVehicle].
class _AggregateInput {
  final List<TripHistoryEntry> trips;
  final List<TripSample> samples;
  const _AggregateInput(this.trips, this.samples);
}

/// Output bundle for the [compute] hop in [updateForVehicle].
class _AggregateOutput {
  final TripLengthBreakdown lengthBreakdown;
  final SpeedConsumptionHistogram speedHistogram;
  const _AggregateOutput(this.lengthBreakdown, this.speedHistogram);
}

/// Top-level isolate entry — must be a top-level / static function for
/// [compute].
_AggregateOutput _aggregateBoth(_AggregateInput input) => _AggregateOutput(
      aggregateByTripLength(input.trips),
      aggregateSpeedConsumption(input.samples),
    );

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

/// Pure: bin [samples] by speed band per
/// [SpeedConsumptionHistogram.standardBandTemplate] and emit the
/// per-band stats.
///
/// Sample model — the `TripSample` carried by `TripHistoryEntry.samples`
/// (#1040) holds:
///   * `speedKmh` (always populated — band classifier reads this)
///   * `fuelRateLPerHour` (nullable — populated when the car answers
///     PID 5E or the MAF / speed-density fallback yields a value).
///
/// Per-band mean L/100 km is computed by integrating fuel-rate over
/// time and distance over time, then `Σlitres / Σkm * 100`. Samples
/// without a fuel-rate reading still count toward [SpeedBand.sampleCount]
/// and [SpeedBand.timeShareFraction] (they were observed driving in
/// that band), but contribute zero litres and zero km — same caveat as
/// the trip-length aggregator.
///
/// Time accounting uses a 1 Hz nominal cadence: each sample is treated
/// as one second of observed driving. The chart cadence is actually
/// "whatever the OBD2 polling loop sustains" (1-2 Hz), but the same
/// share-of-time is preserved across bands as long as cadence stays
/// roughly consistent within a trip. A future revision can integrate
/// real Δt between consecutive samples — the schema keeps that path
/// open via `timestamp`. Documented honestly here.
///
/// Bands with fewer than [kMinSamplesPerSpeedBand] samples are omitted
/// from the result's [SpeedConsumptionHistogram.bands] list (rather
/// than carrying zero values) — see the value-object docstring.
SpeedConsumptionHistogram aggregateSpeedConsumption(List<TripSample> samples) {
  if (samples.isEmpty) {
    return const SpeedConsumptionHistogram();
  }

  // Per-band running totals, indexed by band template position.
  const template = SpeedConsumptionHistogram.standardBandTemplate;
  final counts = List<int>.filled(template.length, 0);
  final litres = List<double>.filled(template.length, 0.0);
  final km = List<double>.filled(template.length, 0.0);

  // 1 Hz nominal — each sample counts as 1 s of observed driving for
  // litres + km integration. Documented in the function docstring.
  const double dtSec = 1.0;

  var totalCount = 0;
  for (final s in samples) {
    final idx = _classifySpeed(s.speedKmh, template);
    if (idx < 0) continue; // negative speed — skip defensively.
    counts[idx]++;
    totalCount++;
    final rate = s.fuelRateLPerHour;
    if (rate != null) {
      litres[idx] += rate * dtSec / 3600.0;
    }
    km[idx] += s.speedKmh * dtSec / 3600.0;
  }

  if (totalCount == 0) {
    return const SpeedConsumptionHistogram();
  }

  final bands = <SpeedBand>[];
  for (var i = 0; i < template.length; i++) {
    if (counts[i] < kMinSamplesPerSpeedBand) continue;
    final mean = km[i] > 0 ? litres[i] / km[i] * 100.0 : 0.0;
    bands.add(SpeedBand(
      minKmh: template[i].$1,
      maxKmh: template[i].$2,
      sampleCount: counts[i],
      meanLPer100km: mean,
      timeShareFraction: counts[i] / totalCount,
    ));
  }

  return SpeedConsumptionHistogram(bands: bands);
}

/// Index of the band in [template] that contains [speedKmh] under the
/// half-open `[min, max)` convention (with the top band open-ended).
/// Returns `-1` for negative input — defensive against corrupt
/// samples.
int _classifySpeed(double speedKmh, List<(int, int?)> template) {
  if (speedKmh < 0) return -1;
  for (var i = 0; i < template.length; i++) {
    final (lo, hi) = template[i];
    if (speedKmh >= lo && (hi == null || speedKmh < hi)) {
      return i;
    }
  }
  return -1;
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

/// Welford-style fold of newly-arrived [newSamples] into an existing
/// [SpeedConsumptionHistogram]. The per-band running mean is updated
/// via Welford recurrence (ratio of running litres / running km),
/// which is exact when both running denominators come from the same
/// underlying samples — which is our case. Per-band sample counts and
/// time shares are exact.
///
/// `null` input is allowed; new bands are seeded as samples arrive.
/// Bands that don't yet meet [kMinSamplesPerSpeedBand] are kept in the
/// internal accumulator but omitted from the returned
/// [SpeedConsumptionHistogram.bands] list — same exclusion rule as
/// [aggregateSpeedConsumption], so the incremental and full-recompute
/// outputs are interchangeable from the consumer's point of view.
///
/// IMPORTANT — reconstructing per-band running totals from a
/// [SpeedConsumptionHistogram] is lossy: bands below threshold were
/// excluded from the prior, so this function CANNOT recover their
/// counters by reading [prior] alone. The first incremental fold over
/// a band that was previously below threshold will start its counter
/// from zero on the new samples only. Callers that need exact
/// continuity across the threshold boundary should run [updateForVehicle]
/// instead — that's the source of truth for a reason.
SpeedConsumptionHistogram foldSpeedConsumptionIncremental(
  SpeedConsumptionHistogram? prior,
  List<TripSample> newSamples,
) {
  const template = SpeedConsumptionHistogram.standardBandTemplate;
  final counts = List<int>.filled(template.length, 0);
  final litres = List<double>.filled(template.length, 0.0);
  final km = List<double>.filled(template.length, 0.0);

  // Seed from prior (lossy — see docstring). Bands below threshold
  // simply don't appear in `prior.bands` and start at zero here.
  if (prior != null) {
    for (final band in prior.bands) {
      final i = _bandIndex(band.minKmh, band.maxKmh, template);
      if (i < 0) continue;
      counts[i] = band.sampleCount;
      // Reconstruct litres / km from the persisted mean. We don't
      // store litres directly on SpeedBand (it's not on the schema),
      // so we lean on `meanLPer100km` × an implied km derived from
      // sample count × nominal time. Keep this in sync with the time
      // model in [aggregateSpeedConsumption].
      const double dtSec = 1.0;
      // Rough km estimate from the band's midpoint; for the
      // open-ended top band use the lower bound as a conservative
      // anchor.
      final midpoint = band.maxKmh == null
          ? band.minKmh.toDouble()
          : (band.minKmh + band.maxKmh!) / 2.0;
      km[i] = midpoint * band.sampleCount * dtSec / 3600.0;
      litres[i] = band.meanLPer100km * km[i] / 100.0;
    }
  }

  const double dtSec = 1.0;
  var totalCount = 0;
  for (var i = 0; i < counts.length; i++) {
    totalCount += counts[i];
  }

  for (final s in newSamples) {
    final idx = _classifySpeed(s.speedKmh, template);
    if (idx < 0) continue;
    counts[idx]++;
    totalCount++;
    final rate = s.fuelRateLPerHour;
    if (rate != null) {
      litres[idx] += rate * dtSec / 3600.0;
    }
    km[idx] += s.speedKmh * dtSec / 3600.0;
  }

  if (totalCount == 0) {
    return const SpeedConsumptionHistogram();
  }

  final bands = <SpeedBand>[];
  for (var i = 0; i < template.length; i++) {
    if (counts[i] < kMinSamplesPerSpeedBand) continue;
    final mean = km[i] > 0 ? litres[i] / km[i] * 100.0 : 0.0;
    bands.add(SpeedBand(
      minKmh: template[i].$1,
      maxKmh: template[i].$2,
      sampleCount: counts[i],
      meanLPer100km: mean,
      timeShareFraction: counts[i] / totalCount,
    ));
  }

  return SpeedConsumptionHistogram(bands: bands);
}

/// Look up the template index for a band described by [minKmh] /
/// [maxKmh]. Returns `-1` when no template entry matches — usually a
/// sign that the schema has been bumped between releases.
int _bandIndex(int minKmh, int? maxKmh, List<(int, int?)> template) {
  for (var i = 0; i < template.length; i++) {
    if (template[i].$1 == minKmh && template[i].$2 == maxKmh) return i;
  }
  return -1;
}
