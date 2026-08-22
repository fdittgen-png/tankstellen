// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'live_sample_snapshot.dart';

/// The per-PID latest-value latches extracted from [LiveSampleSnapshot]
/// as a `part` mixin so they keep private-member access while
/// `live_sample_snapshot.dart` stays under the #1680 file-length cap
/// (sanctioned #3760 decomposition — move-only, behaviour preserved):
/// the latch fields, their public getters, and the provider-pushed
/// GPS / OEM-fuel update entry points.
mixin _LiveSampleSnapshotLatches {
  // Constructor-owned collaborators — the class owns the fields; the
  // mixin chain reaches them through these library-private getters.
  Obd2Service get _service;
  VehicleProfile? get _vehicle;
  ReferenceVehicle? get _referenceVehicle;
  Obd2BreadcrumbRecorder? get _breadcrumbCollector;
  void Function(Object? parsedValue) get _onHighPriorityParse;
  void Function(double speedKmh) get _onSpeedSample;
  DateTime Function() get _clock; // #2505 — IAT-staleness clock (test seam).
  PrecisionPidLatches get _precision;

  /// The ECU's own fuel-type answer (PID 0x51) read ONCE at comm-session
  /// start (#3429) — runtime truth that beats the free-text profile fuel
  /// key for this session's AFR/density resolution (manual overrides
  /// still win). Null when the ECU doesn't answer 0x51; the resolution
  /// then falls back to the profile exactly as before.
  String? sessionFuelTypeKey;

  // Latest parsed values, keyed by PID command. Written by scheduler
  // callbacks, read by the controller's `_emit` when assembling a
  // TripLiveReading. Not a typed struct because most fields are
  // optional doubles and a freezed class for this scratch space buys
  // nothing.
  double? _latestSpeedKmh;
  double? _latestRpm;
  double? _latestMaf;
  double? _latestMapKpa;
  double? _latestIatCelsius;
  // #2505 — when [_latestIatCelsius] last landed. Lets the speed-density
  // branch reuse a slightly-stale IAT (see [_freshIatCelsius]).
  DateTime? _latestIatAt;
  double? _latestThrottlePercent;
  double? _latestEngineLoadPercent;
  double? _latestCoolantTempC;
  double? _latestFuelLevelPercent;
  double? _latestStft;
  double? _latestLtft;
  double? _latestDirectFuelRate;

  // #2456 — commanded fuel–air equivalence ratio φ (PID 0x44 — SAE
  // convention verified #3426: φ > 1 rich, φ < 1 lean, λ = 1/φ) and
  // absolute barometric pressure (PID 0x33). Both refine the MAF /
  // speed-density fuel derivation when the car exposes them and stay
  // null (today's behaviour, bit-for-bit) on cars that don't. φ is
  // sampled fast (it tracks the mixture under load); baro is sampled
  // slowly (it only changes with altitude / weather).
  double? _latestCommandedPhi;
  double? _latestBaroKpa;

  // #2458 — bank-2 fuel trims (PIDs 0x08 / 0x09). Fold into the MAF /
  // speed-density trim correction on dual-bank (V / boxer) engines;
  // null on inline engines, where the correction stays bank-1-only.
  double? _latestStftBank2;
  double? _latestLtftBank2;

  // #2458 — absolute load (PID 0x43, a boosted-engine high-load proxy
  // that can exceed 100 %) and accelerator-pedal position (PIDs 0x49 /
  // 0x4A / 0x4B; the snapshot stores the max of whichever channels the
  // car exposes). Both acquired + persisted here; the driving-style
  // consumption of pedal is #2460.
  double? _latestAbsLoadPercent;
  // Per-channel pedal latches (PIDs 0x49 / 0x4A / 0x4B). The three track
  // the same physical pedal; `latestPedalPercent` returns the max of the
  // most-recent non-null channels (the least-damped reading) rather than
  // a running max across callbacks, which could never decrease.
  double? _latestPedalD;
  double? _latestPedalE;
  double? _latestPedalF;

  // #2459 — optional diagnostic-context thermal signals: engine oil
  // temperature (PID 0x5C) and ambient air temperature (PID 0x46). Null
  // on cars that don't expose them.
  double? _latestOilTempC;
  double? _latestAmbientTempC;

  /// #3692 — ignition timing advance (PID 0x0E), latest value.
  double? _latestTimingAdvanceDeg;

  // #1374 phase 1 — most recent GPS fix, pushed in by the provider when
  // the `Feature.gpsTripPath` flag is enabled (the controller never
  // subscribes to Geolocator itself — that lives at the provider layer).
  // Flag off → both stay null and every sample carries lat/lon null
  // (matching pre-#1374 behaviour bit-for-bit).
  double? _latestLatitude;
  double? _latestLongitude;

  // #1935 child A — most recent GPS altitude (metres), pushed in
  // alongside the lat/lon fix. Feeds the road-grade calculator (#1941).
  double? _latestAltitudeM;

  // #2648 — most recent GPS horizontal accuracy (metres) + bearing
  // (compass degrees), pushed in alongside the lat/lon fix. The
  // `Position` already carries both, but the OBD2 / degraded recording
  // paths used to drop them (only the GPS-only pipeline kept them), so
  // they reached only 0.3 % of samples. Latched here so every emitted
  // [TripSample] carries them — reviving the cornering analytic
  // (bearing) and the harsh-event accuracy-gate (accuracy). Null when
  // the provider hasn't pushed a fix (matching pre-#2648 behaviour).
  double? _latestHAccuracyM;
  double? _latestBearingDeg;

  // #1615 — most recent exact-litre OEM-PID fuel reading, pushed in by
  // the provider layer (`TripOemFuelLevelController`) when the
  // `experimentalOemPids` flag is on and an OEM-capable adapter resolved
  // a manufacturer table. The multi-command OEM read does NOT fit the
  // per-PID scheduler, so this class only holds the latch; flag off (or
  // no read) → null and `_emit` matches pre-#1615 behaviour.
  double? _latestOemFuelLevelLitres;

  double? get latestSpeedKmh => _latestSpeedKmh;
  double? get latestRpm => _latestRpm;
  double? get latestThrottlePercent => _latestThrottlePercent;
  double? get latestEngineLoadPercent => _latestEngineLoadPercent;
  double? get latestCoolantTempC => _latestCoolantTempC;
  double? get latestFuelLevelPercent => _latestFuelLevelPercent;
  double? get latestLatitude => _latestLatitude;
  double? get latestLongitude => _latestLongitude;
  double? get latestAltitudeM => _latestAltitudeM;
  // #2648 — GPS horizontal accuracy + bearing latches (see field doc).
  double? get latestHAccuracyM => _latestHAccuracyM;
  double? get latestBearingDeg => _latestBearingDeg;
  double? get latestOemFuelLevelLitres => _latestOemFuelLevelLitres;

  // #2456 / #2458 / #2459 — latest-value getters for the signals the
  // controller's `_emit` persists onto each TripSample (#2459). The
  // raw mixture inputs (MAF / MAP / STFT / LTFT) are read here too so the
  // diagnostic-capture path can stamp them for post-hoc re-derivation.
  // (Named λ pre-#3426; the PID 0x44 wire value is the SAE fuel–air
  // equivalence ratio φ — see `effectiveAfrForPhi`.)
  double? get latestCommandedPhi => _latestCommandedPhi;
  double? get latestBaroKpa => _latestBaroKpa;
  double? get latestAbsLoadPercent => _latestAbsLoadPercent;

  /// Freshest MEASURED wideband φ (PIDs 0x24–0x2B / 0x34–0x3B, #3427),
  /// bank-1-sensor-1 priority. Null on cars without a wideband sensor or
  /// when the last reading went stale.
  double? get latestMeasuredPhi => _precision.measuredPhi();

  /// Measured ethanol fuel % (PID 0x52, #3429). Null when unsupported.
  double? get latestEthanolPercent => _precision.ethanolPercent;

  /// Accelerator-pedal position (%) — the max of whichever of the three
  /// channels (D / E / F, PIDs 0x49 / 0x4A / 0x4B) have landed (#2458).
  /// Null until at least one channel reports.
  double? get latestPedalPercent {
    double? best;
    for (final v in [_latestPedalD, _latestPedalE, _latestPedalF]) {
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }
  double? get latestOilTempC => _latestOilTempC;
  double? get latestAmbientTempC => _latestAmbientTempC;

  /// #3692 — the persisted-signal getters: IAT was latched since #2505
  /// but never exposed for recording; timing advance is new.
  double? get latestIatCelsius => _latestIatCelsius;
  double? get latestTimingAdvanceDeg => _latestTimingAdvanceDeg;
  double? get latestMaf => _latestMaf;
  double? get latestMapKpa => _latestMapKpa;
  double? get latestStft => _latestStft;
  double? get latestLtft => _latestLtft;

  /// Push the most recent GPS fix into the per-tick snapshot
  /// (#1374 phase 1; altitude added #1935 child A; horizontal accuracy +
  /// bearing added #2648). Pass `null` for a field to clear that latch.
  void updateGpsFix({
    double? latitude,
    double? longitude,
    double? altitudeM,
    double? hAccuracyM,
    double? bearingDeg,
  }) {
    _latestLatitude = latitude;
    _latestLongitude = longitude;
    // #2692 C4-B — chokepoint isFinite guard (NaN altitude poisoned grade math).
    _latestAltitudeM = (altitudeM != null && altitudeM.isFinite) ? altitudeM : null;
    _latestHAccuracyM = hAccuracyM;
    _latestBearingDeg = bearingDeg;
  }

  /// Push the most recent exact-litre OEM-PID fuel reading into the
  /// per-tick snapshot (#1615). Pass `null` to clear the latch (e.g.
  /// the OEM read returned NO DATA). Called by the provider-layer
  /// `TripOemFuelLevelController`; the controller's `_emit` reads it
  /// back into `TripLiveReading.fuelLevelLitres`.
  void updateOemFuelLevelLitres(double? litres) {
    _latestOemFuelLevelLitres = litres;
  }
}
