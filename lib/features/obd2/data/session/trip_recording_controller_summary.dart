// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Trip-end summary finalisation for [TripRecordingController], a `part`
/// mixin because it assembles the summary out of the controller's own
/// accumulated state (sanctioned #3760 decomposition — move-only,
/// behaviour preserved).
///
/// #4034 (epic #4032) — the #1263 gear-inference metric it used to carry
/// left the library entirely: it reads a vehicle profile and a sample
/// list and nothing else, so it is the pure
/// [computeGearCoachingMetric] function now.
mixin _TripRecordingSummary on _TripRecordingTelemetryIngest {
  /// Build the trip's final [TripSummary] from the recorder's
  /// in-flight accumulator plus the controller-owned distance
  /// provenance (#800). The recorder still owns distance integration
  /// for live UI reads; the controller overrides at finalisation only
  /// when a real odometer delta beats the virtual estimate.
  ///
  /// #1263 phase 2 — when the active vehicle is combustion / hybrid
  /// AND there are enough captured samples to drive [inferGears], the
  /// gear-inference metric `secondsBelowOptimalGear` is computed and
  /// stamped onto the returned summary. EVs (and any vehicle whose
  /// type resolves to [VehicleType.ev]) bypass the inference entirely
  /// — no gears, no coaching. Failures inside the pure-logic helpers
  /// fall back to a null metric rather than throw, so a degenerate
  /// fixture never derails the trip-stop flow.
  TripSummary _finaliseSummary() {
    final base = _recorder.buildSummary();
    final distanceKm = currentDistanceKm;
    final source = distanceSource;
    // Recompute avgLPer100Km against the swapped distance. #2835 —
    // re-apply the tiny-distance floor (ratio blows up below it; the
    // measured litres are kept). Sparse-cadence trips already arrive
    // with `base.fuelLitersConsumed == null` from the recorder.
    final avg = (base.fuelLitersConsumed != null &&
            isDistanceReliableForRatio(distanceKm))
        ? base.fuelLitersConsumed! / distanceKm * 100.0
        : null;
    // #1395 — roll the running breadcrumb flag-counts into a single
    // suspect bit on the trip summary. Threshold matches the spec:
    // when more than 30 % of fuel-rate samples tripped a sanity flag
    // (suspicious-low at cruise OR 5E-vs-MAF divergent > 50 %), the
    // resulting L/100 km is unreliable and a downstream UI chip
    // (#1395 phase 4) will warn the user. The snapshot resets the
    // running counters so a subsequent recording starts clean.
    var fuelRateSuspect = false;
    final collector = _breadcrumbCollector;
    if (collector != null) {
      final snapshot = collector.snapshotAndResetCounters();
      if (snapshot.total > 0 &&
          snapshot.suspicious / snapshot.total > 0.3) {
        fuelRateSuspect = true;
      }
    }
    // #2509 — GPS start/end fallback. When the OBD2 link was dead the
    // recorder never saw a sample, so `base.startedAt` / `base.endedAt`
    // are null even though GPS fixes were buffered into the distance
    // resolver and produced a real distance. Without a `startedAt` the
    // persist guard discards the whole drive (silent data loss). Fall
    // back to the first/last GPS-fix timestamp captured in [updateGpsFix]
    // ONLY when the recorder did not supply its own — a healthy OBD2 trip
    // keeps the recorder's authoritative timestamps untouched.
    final startedAt = base.startedAt ?? _gpsStartedAt;
    final endedAt = base.endedAt ?? _gpsEndedAt;
    // #2895 / #3029 — harsh-count parity with the GPS-only pipeline (which
    // runs an IMU detector + the #2895 `imuActive ? imuCount : recorder`
    // veto). This OBD2 path runs NO inertial detector, so the veto collapses
    // to "use the recorder value": after #3029 the recorder suppresses harsh
    // scoring on the `gps`/`virtual` source in `onSample`, so base.harsh* is
    // 0 for a no-speed-PID GPS trip (no phantom) and reflects the direct OBD2
    // speed PID on a `real` trip (preserved). Pass-through is correct here.
    // #3576 — persist the live GPS-physics estimate the user watched all
    // drive (the #2506 overlay) when NO measured fuel exists: the field
    // trip showed ~2.01 L / ~11.0 L/100 km live and dashes after save.
    // Measured data always wins — a single real fuel-rate sample keeps
    // the estimate fields null.
    final estimateFolder = _gpsEstimateFolder;
    final stampEstimates =
        base.fuelLitersConsumed == null && !_fuel.fuelRateSeen;
    return TripSummary(
      distanceKm: distanceKm,
      maxRpm: base.maxRpm,
      highRpmSeconds: base.highRpmSeconds,
      idleSeconds: base.idleSeconds,
      harshBrakes: base.harshBrakes,
      harshAccelerations: base.harshAccelerations,
      avgLPer100Km: avg,
      fuelLitersConsumed: base.fuelLitersConsumed,
      estimatedAvgLPer100Km:
          stampEstimates ? estimateFolder?.finalAvgLPer100Km : null,
      estimatedFuelLitersConsumed:
          stampEstimates ? estimateFolder?.finalFuelLiters : null,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceSource: source,
      secondsBelowOptimalGear: computeGearCoachingMetric(
        vehicle: _vehicle,
        // #3878 — the ring holds only the live window; the stop path
        // hands the whole trip in.
        capturedSamples:
            _allSamplesForFinalise ?? _sampleBuffer.capturedSamples,
      ),
      fuelRateSuspect: fuelRateSuspect,
      volumetricEfficiencyUsed: _fuel.volumetricEfficiencyUsed,
      // #3887 — the pump-anchored gain the estimated fuel carried.
      // #3918 — the RESOLVED gain (per-fuel / scalar) the live chain
      // actually multiplied by; the scalar only when nothing was derived.
      pumpGainApplied:
          _liveSampleSnapshot.lastPumpGainResolution?.gain ?? _vehicle?.pumpGain,
    );
  }
}
