import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../../consumption/data/trip_history_repository.dart';
import '../../consumption/domain/trip_recorder.dart';
import '../domain/entities/speed_consumption_histogram.dart';
import '../domain/entities/trip_length_breakdown.dart';
import 'repositories/vehicle_profile_repository.dart';
import 'vehicle_speed_consumption_aggregator.dart';
import 'vehicle_trip_length_aggregator.dart';

/// Per-vehicle minimum trip count below which ALL aggregate fields are
/// nulled on the profile (matches the issue's "hide section when below
/// threshold" UI rule from #1193 phase 3).
const int kMinTripsForAggregates = 5;

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
///
/// Pure aggregator passes live in sibling files:
///   * `vehicle_trip_length_aggregator.dart` — [aggregateByTripLength],
///     [foldTripLengthIncremental], [kMinTripsPerLengthBucket].
///   * `vehicle_speed_consumption_aggregator.dart` —
///     [aggregateSpeedConsumption], [foldSpeedConsumptionIncremental],
///     [kMinSamplesPerSpeedBand].
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
