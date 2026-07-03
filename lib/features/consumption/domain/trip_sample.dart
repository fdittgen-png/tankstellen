// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One OBD2 sample tick — captured by the polling loop and fed into
/// [TripRecorder] for metric accumulation.
///
/// Extracted from `trip_recorder.dart` (#2459 — keeps that file under the
/// 400-line guard once six optional signals + the diagnostic-capture raw
/// mixture inputs joined the per-tick schema) and re-exported from it so
/// existing importers see it as one unit.
class TripSample {
  final DateTime timestamp;
  final double speedKmh;

  /// Engine RPM (PID 0x0C). **Null** for a GPS-only / degraded sample
  /// where no engine signal exists (#2692 C4-G) — previously GPS-only
  /// samples fabricated `rpm: 0`, which the idle / high-RPM / hard-shift
  /// analytics misread as a stationary running engine. OBD2 samples
  /// always carry a real value; consumers treat null as "no engine
  /// signal", never as zero.
  final double? rpm;
  final double? fuelRateLPerHour;

  /// GPS-physics **estimated** fuel rate in L/h (#2431). Populated ONLY
  /// for OBD2/hybrid trips whose adapter+ECU supported none of the fuel
  /// PIDs (PID 5E / MAF 0110 / speed-density MAP 010B), so
  /// [fuelRateLPerHour] is null on every sample. It is the per-sample
  /// distribution of the trip's GPS-physics L/100 km estimate over the
  /// sample's speed (`L/100 km / 100 × speedKmh`), letting the
  /// trip-detail fuel-rate chart render a clearly-marked *estimated*
  /// series instead of "Keine Messwerte". Deliberately a SEPARATE field
  /// from [fuelRateLPerHour] so a measured value and an estimate are
  /// never confused — when a real fuel PID was seen this stays null and
  /// the chart shows the measured series. Null for legacy trips, for
  /// trips that DID get a real fuel signal, and at a standstill (no
  /// per-distance figure is meaningful at v ≈ 0).
  final double? estimatedFuelRateLPerHour;

  /// Throttle position in percent (PID 0x11), if available. Cars
  /// without PID 11 report null — the trip-detail throttle / RPM
  /// histogram falls back to the RPM axis only in that case (#1261).
  final double? throttlePercent;

  /// Calculated engine load in percent (PID 0x04). Null when the car
  /// doesn't surface the PID. Persisted so post-trip insights can
  /// distinguish "uphill at 60 km/h" (high load) from "flat at 60 km/h"
  /// (low load) instead of inferring from RPM alone (#1262).
  final double? engineLoadPercent;

  /// Engine coolant temperature in °C (PID 0x05). Null when the car
  /// doesn't surface the PID. Persisted so the cold-start surcharge
  /// heuristic (#1262 phase 2) can flag trips whose ECT never reached
  /// operating temperature — those burn proportionally more fuel for
  /// warm-up.
  final double? coolantTempC;

  /// GPS latitude in degrees (#1374 phase 1). Null when the
  /// `Feature.gpsTripPath` flag is disabled (default), when no fix has
  /// landed yet (cold-start indoors), or when the user revoked the
  /// location permission. Persisted so a future map overlay (Phase 2)
  /// and a per-segment heatmap (Phase 3) can render the recorded
  /// trip's path. Legacy samples from trips recorded before this PR
  /// deserialise with `latitude: null`.
  final double? latitude;

  /// GPS longitude in degrees (#1374 phase 1). Same null-semantics as
  /// [latitude]; the two fields are always written and read together
  /// — a half-set fix is meaningless on a map.
  final double? longitude;

  /// GPS altitude in metres (#1935 child A — epic #1935). Same
  /// null-semantics as [latitude]/[longitude]: null when the
  /// `Feature.gpsTripPath` flag is off, before the first fix, or when
  /// the platform reports no altitude. Captured so the road-grade
  /// calculator (#1941) can derive the trip's slope.
  final double? altitudeM;

  /// Reported horizontal accuracy of the GPS fix in metres (#2019).
  /// Lets downstream filters reject jittery fixes from urban-canyon
  /// readings before they feed the speed-derivative accel pipeline
  /// (#2022) or the post-trip map polyline. Null with the same
  /// semantics as [latitude] — no fix means no accuracy.
  final double? hAccuracyM;

  /// Bearing in degrees from true north (#2019). Populated when the
  /// platform supplies it; null otherwise. The trip-detail map can
  /// render directional arrowheads off this, and the gear-inference
  /// heuristic (#2023) uses bearing-stability to gate "is this
  /// straight-line cruise" decisions.
  final double? bearingDeg;

  /// Acceleration magnitude in g (#2019). Populated by the
  /// speed-derivative low-pass pipeline (#2022) when no real
  /// accelerometer feed is wired up; future hardware integrations may
  /// overwrite this from raw sensor data. Null on legacy samples and
  /// when the speed series is too short to differentiate.
  final double? accelG;

  // ---- #2459 — consumed-but-previously-unstored signals -------------
  // All optional; null on cars that don't expose the PID and on legacy
  // trips. Each persists with an `if(!=null)` compact-key guard so a car
  // without the PID adds zero bytes (see `trip_sample_codec.dart`).

  /// Commanded fuel–air equivalence ratio φ (PID 0x44, #2456 / persisted
  /// #2459). The ECU's real commanded mixture; feeds the effective-AFR
  /// fuel refinement. Null when the car doesn't expose PID 0x44.
  /// (Field name kept from the pre-#3426 λ naming for persistence
  /// compatibility — the stored value is φ, SAE convention: > 1 rich.)
  final double? lambda;

  /// MEASURED wideband fuel–air equivalence ratio φ (PIDs 0x24–0x2B /
  /// 0x34–0x3B, #3427). The real sensed mixture, preferred over the
  /// commanded [lambda] in the fuel math. Null when the car has no
  /// wideband sensor (or the reading went stale that tick).
  final double? measuredPhi;

  /// Measured ethanol fuel fraction in percent (PID 0x52, #3429).
  /// Drives the dynamic petrol↔E85 AFR/density blend. Null when
  /// unsupported.
  final double? ethanolPercent;

  /// Fuel-source provenance of this tick's [fuelRateLPerHour] — a
  /// `FuelRateSourceTag` name (`pid9D` / `pidA2` / `pid5E` / `maf66` /
  /// `maf` / `speedDensity`), #3428 / #3433. Stamped only when a rate was
  /// derived; the driving-analysis export aggregates it into the trip's
  /// dominant-branch figure. Null on legacy trips and rate-less ticks.
  final String? fuelSource;

  /// Absolute barometric pressure in kPa (PID 0x33, #2456 / persisted
  /// #2459). Measured ambient air pressure (altitude / weather). Null
  /// when the car doesn't expose PID 0x33.
  final double? baroKpa;

  /// Absolute load value in percent (PID 0x43, #2458). A boosted-engine
  /// high-load proxy that can exceed 100 %. Null when unsupported.
  final double? absLoadPercent;

  /// Accelerator-pedal position in percent (PIDs 0x49/0x4A/0x4B, #2458).
  /// The max of whichever pedal channels the car exposes — driver
  /// intent. Null when none is supported.
  final double? pedalPercent;

  /// Engine oil temperature in °C (PID 0x5C, #2459). Optional thermal
  /// context. Null when unsupported.
  final double? oilTempC;

  /// Ambient air temperature in °C (PID 0x46, #2459). Optional thermal
  /// context (true outside air, vs the warmer IAT). Null when unsupported.
  final double? ambientTempC;

  // ---- #2459 — diagnostic-capture raw mixture inputs ----------------
  // Stored ONLY when the per-trip 'diagnostic capture' flag is on
  // (default off) so the raw inputs that derived the fuel rate can be
  // re-derived post-hoc. Sampled at SLOW cadence (carried forward, not
  // every 250 ms) so storage doesn't balloon. Null whenever the flag is
  // off, on legacy trips, and on cars that don't expose the PID.

  /// Mass air flow in g/s (PID 0x10) — diagnostic-capture raw input.
  final double? mafGramsPerSecond;

  /// Intake manifold absolute pressure in kPa (PID 0x0B) —
  /// diagnostic-capture raw input.
  final double? mapKpa;

  /// Short-term fuel trim bank 1 in percent (PID 0x06) —
  /// diagnostic-capture raw input.
  final double? stft;

  /// Long-term fuel trim bank 1 in percent (PID 0x07) —
  /// diagnostic-capture raw input.
  final double? ltft;

  const TripSample({
    required this.timestamp,
    required this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.estimatedFuelRateLPerHour,
    this.throttlePercent,
    this.engineLoadPercent,
    this.coolantTempC,
    this.latitude,
    this.longitude,
    this.altitudeM,
    this.hAccuracyM,
    this.bearingDeg,
    this.accelG,
    this.lambda,
    this.measuredPhi,
    this.ethanolPercent,
    this.fuelSource,
    this.baroKpa,
    this.absLoadPercent,
    this.pedalPercent,
    this.oilTempC,
    this.ambientTempC,
    this.mafGramsPerSecond,
    this.mapKpa,
    this.stft,
    this.ltft,
  });

  /// Return a copy with [estimatedFuelRateLPerHour] replaced (#2431).
  /// The OBD2 GPS-estimate fallback uses it to stamp the per-sample
  /// estimated fuel-rate series onto an already-captured sample without
  /// disturbing its measured speed / RPM / GPS / diagnostic fields. Only
  /// the one field is overridable because that is the sole post-capture
  /// mutation the fallback performs.
  TripSample copyWithEstimatedFuelRate(double? estimatedFuelRateLPerHour) =>
      TripSample(
        timestamp: timestamp,
        speedKmh: speedKmh,
        rpm: rpm,
        fuelRateLPerHour: fuelRateLPerHour,
        estimatedFuelRateLPerHour: estimatedFuelRateLPerHour,
        throttlePercent: throttlePercent,
        engineLoadPercent: engineLoadPercent,
        coolantTempC: coolantTempC,
        latitude: latitude,
        longitude: longitude,
        altitudeM: altitudeM,
        hAccuracyM: hAccuracyM,
        bearingDeg: bearingDeg,
        accelG: accelG,
        lambda: lambda,
        measuredPhi: measuredPhi,
        ethanolPercent: ethanolPercent,
        fuelSource: fuelSource,
        baroKpa: baroKpa,
        absLoadPercent: absLoadPercent,
        pedalPercent: pedalPercent,
        oilTempC: oilTempC,
        ambientTempC: ambientTempC,
        mafGramsPerSecond: mafGramsPerSecond,
        mapKpa: mapKpa,
        stft: stft,
        ltft: ltft,
      );
}
