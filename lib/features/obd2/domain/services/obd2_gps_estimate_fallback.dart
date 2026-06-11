// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/gps_calibration_matrix.dart';
import '../../../../core/domain/vehicle_profile.dart';
// trip_recorder.dart re-exports trip_summary.dart (TripSample + TripSummary).
import '../../../consumption/domain/trip_recorder.dart';
import '../../../consumption/domain/services/gps_live_fuel_estimator.dart';

/// A trip summary paired with its (possibly estimate-stamped) samples —
/// the result of [Obd2GpsEstimateFallback.fillWhenNoFuelPid] (#2431).
class Obd2GpsEstimateFill {
  const Obd2GpsEstimateFill({required this.summary, required this.samples});

  final TripSummary summary;
  final List<TripSample> samples;
}

/// Result of the #2431 OBD2 GPS-estimate fallback: the per-sample
/// estimated fuel-rate series (stamped onto a copy of the captured
/// samples) plus the trip-level figures to write onto [TripSummary].
class Obd2GpsEstimateResult {
  const Obd2GpsEstimateResult({
    required this.samples,
    required this.avgLPer100Km,
    required this.fuelLitersConsumed,
  });

  /// The captured samples with [TripSample.estimatedFuelRateLPerHour]
  /// filled in per tick (null where the vehicle was stationary).
  final List<TripSample> samples;

  /// Trip-level GPS-physics estimate of average consumption (L/100 km),
  /// to back-fill [TripSummary.avgLPer100Km].
  final double avgLPer100Km;

  /// Trip-level GPS-physics estimate of total litres burned, to
  /// back-fill [TripSummary.fuelLitersConsumed].
  final double fuelLitersConsumed;
}

/// Derives a GPS-physics fuel estimate for an OBD2/hybrid trip whose
/// adapter+ECU supported NONE of the fuel PIDs (#2431).
///
/// The Peugeot + Generic ELM327 in the field report supports neither PID
/// 5E, MAF 0110, nor speed-density MAP 010B, so
/// `deriveFuelRateLPerHour()` returns null on every tick: the whole fuel
/// branch goes blank (Ø Verbrauch = "—", total Kraftstoff = "—",
/// fuel-rate chart = "Keine Messwerte"). OBD2 trips still GPS-stamp
/// speed/lat/long/alt on every sample, so the same calibrated
/// road-load physics the GPS-only pipeline uses (Epic #2385/#2387) can
/// reconstruct the consumption — clearly marked as an *estimate*.
///
/// Pure function — no I/O, no providers. The caller resolves the active
/// vehicle + its calibration matrix and decides WHEN to run this (only
/// when no real fuel-rate sample was ever seen — see the `_fuelRateSeen`
/// gate in `Obd2RecordingPipeline.stop`); this class only does the math.
///
/// Uses [GpsLiveFuelEstimator] (not the lean post-trip
/// [GpsFuelEstimator]) for two reasons:
///   1. it folds the speed stream tick-by-tick, so it yields a per-tick
///      instant L/100 km that becomes the chart's per-sample series, and
///   2. its energy→litres step is fuel-type-aware via the per-fuel
///      volumetric LHV (#2431), so an E85 trip's litres/Ø are correct
///      rather than ~20-25 % low under the old binary petrol assumption.
class Obd2GpsEstimateFallback {
  Obd2GpsEstimateFallback._();

  /// Back-fill [summary]'s consumption from the GPS-physics estimate
  /// when, and only when, the trip never saw a real fuel-rate sample
  /// (#2431). "Never saw a real fuel rate" ≡ every captured sample's
  /// [TripSample.fuelRateLPerHour] is null AND the recorder left
  /// [TripSummary.fuelLitersConsumed] null — exactly the signature of a
  /// trip whose adapter+ECU supported none of the fuel PIDs.
  ///
  /// A trip that DID get a real fuel signal (any non-null measured
  /// fuel rate, or a recorder-computed litres total) is returned
  /// UNCHANGED — no estimate override, no per-sample estimate stamp — so
  /// measured data is never silently replaced. Likewise when the
  /// estimate isn't meaningful ([estimate] returns null), the originals
  /// are returned untouched and the fuel fields stay null (honest "no
  /// data").
  static Obd2GpsEstimateFill fillWhenNoFuelPid({
    required TripSummary summary,
    required List<TripSample> samples,
    required VehicleProfile? vehicle,
  }) {
    final sawRealFuelRate = samples.any((s) => s.fuelRateLPerHour != null);
    if (sawRealFuelRate || summary.fuelLitersConsumed != null) {
      return Obd2GpsEstimateFill(summary: summary, samples: samples);
    }
    final est = estimate(samples: samples, vehicle: vehicle);
    if (est == null) {
      return Obd2GpsEstimateFill(summary: summary, samples: samples);
    }
    return Obd2GpsEstimateFill(
      summary: summary.copyWith(
        avgLPer100Km: est.avgLPer100Km,
        fuelLitersConsumed: est.fuelLitersConsumed,
      ),
      samples: est.samples,
    );
  }

  /// Run the fallback over [samples] for [vehicle] (+ its GPS
  /// calibration matrix). Returns null when the estimate is not
  /// meaningful — fewer than two samples, or the trip covered no
  /// distance (the running average never becomes defined) — in which
  /// case the caller leaves the summary's fuel fields null (honest "no
  /// data" rather than a fabricated figure).
  static Obd2GpsEstimateResult? estimate({
    required List<TripSample> samples,
    required VehicleProfile? vehicle,
  }) {
    if (samples.length < 2) return null;

    final matrix = vehicle?.gpsCalibration ?? GpsCalibrationMatrix.coldStart();
    final estimator = GpsLiveFuelEstimator.forVehicle(vehicle, matrix);

    final stamped = <TripSample>[];
    double? prevSpeedMps;
    DateTime? prevAt;
    for (final s in samples) {
      final speedMps = s.speedKmh / 3.6;
      double? instant;
      if (prevSpeedMps != null && prevAt != null) {
        final dt = s.timestamp.difference(prevAt).inMilliseconds / 1000.0;
        instant = estimator.onSample(
          speedMps: speedMps,
          prevSpeedMps: prevSpeedMps,
          dtSeconds: dt,
        );
      }
      // Distribute the instant L/100 km over the sample's speed to get an
      // estimated L/h for the chart: L/100 km / 100 × km/h = L/h. Null at
      // a standstill (instant is null) — no per-distance figure there.
      final estLPerH =
          instant == null ? null : instant / 100.0 * s.speedKmh;
      stamped.add(s.copyWithEstimatedFuelRate(estLPerH));
      prevSpeedMps = speedMps;
      prevAt = s.timestamp;
    }

    final avg = estimator.runningAvgLPer100Km;
    final liters = estimator.litersSoFar;
    if (avg == null || liters <= 0) return null;

    return Obd2GpsEstimateResult(
      samples: stamped,
      avgLPer100Km: avg,
      fuelLitersConsumed: liters,
    );
  }
}
