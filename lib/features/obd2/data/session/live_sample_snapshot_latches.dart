// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'live_sample_snapshot.dart';

/// The latest-value facade extracted from [LiveSampleSnapshot]
/// as a `part` mixin so they keep private-member access while
/// `live_sample_snapshot.dart` stays under the #1680 file-length cap
/// (sanctioned #3760 decomposition — move-only, behaviour preserved):
/// the signal getters over the latch store, and the provider-pushed
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
  PrecisionPidLatches get _precision;
  DateTime Function() get _clock;
  SignalLatchStore get _signals; // #4159 — value + arrival per signal.

  /// The ECU's own fuel-type answer (PID 0x51) read ONCE at comm-session
  /// start (#3429) — runtime truth that beats the free-text profile fuel
  /// key for this session's AFR/density resolution (manual overrides
  /// still win). Null when the ECU doesn't answer 0x51; the resolution
  /// then falls back to the profile exactly as before.
  String? sessionFuelTypeKey;

  // #4159 — every OBD2 latch lives in [_signals]; the getters below are a
  // hold-last facade over it (per-signal history is on each subscription).

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

  double? _latest(VehicleSignal signal) => _signals.latest(signal);

  /// [signal] with unit, provenance and freshness (#4159); wideband φ by
  /// the [latestMeasuredPhi] sensor rule; φ and baro marked against the
  /// fuel math's clamp bands (wideband by this session's resolved fuel).
  SignalReading reading(VehicleSignal signal) => markPlausibility(
        signal == VehicleSignal.widebandPhi
            ? _precision.measuredPhiReading()
            : _signals.reading(signal),
        isDiesel: resolveMixtureConstants(_vehicle,
                    sessionFuelTypeKey: sessionFuelTypeKey,
                    measuredEthanolPercent: _precision.ethanolPercent)
                .kind ==
            ResolvedFuelKind.diesel,
      );

  double? get latestSpeedKmh => _latest(VehicleSignal.vehicleSpeed);
  double? get latestRpm => _latest(VehicleSignal.engineRpm);
  double? get latestThrottlePercent => _latest(VehicleSignal.throttle);
  double? get latestEngineLoadPercent => _latest(VehicleSignal.engineLoad);
  double? get latestCoolantTempC => _latest(VehicleSignal.coolantTemp);
  double? get latestFuelLevelPercent => _latest(VehicleSignal.fuelTankLevel);
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
  // (Named λ pre-#3426; the commanded wire value is the SAE fuel–air
  // equivalence ratio φ — see `effectiveAfrForPhi`.)
  double? get latestCommandedPhi => _latest(VehicleSignal.commandedPhi);
  double? get latestBaroKpa => _latest(VehicleSignal.baroPressure);
  double? get latestAbsLoadPercent => _latest(VehicleSignal.absoluteLoad);

  /// Freshest MEASURED wideband φ (#3427), bank-1-sensor-1 priority. Null
  /// on cars without a wideband sensor or when the last reading went
  /// stale.
  double? get latestMeasuredPhi => _precision.measuredPhi();

  /// Measured ethanol fuel % (#3429). Null when unsupported.
  double? get latestEthanolPercent => _precision.ethanolPercent;

  /// Accelerator-pedal position (%) — the max of whichever of the three
  /// channels (D / E / F) have landed (#2458): the least-damped reading,
  /// not a running max (which could never decrease). Null until at least
  /// one channel reports.
  double? get latestPedalPercent {
    double? best;
    for (final signal in const [
      VehicleSignal.pedalD,
      VehicleSignal.pedalE,
      VehicleSignal.pedalF,
    ]) {
      final v = _latest(signal);
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }
  double? get latestOilTempC => _latest(VehicleSignal.oilTemp);
  double? get latestAmbientTempC => _latest(VehicleSignal.ambientAirTemp);

  /// #3692 — the persisted-signal getters: IAT was latched since #2505
  /// but never exposed for recording; timing advance is new.
  double? get latestIatCelsius => _latest(VehicleSignal.intakeAirTemp);
  double? get latestTimingAdvanceDeg => _latest(VehicleSignal.timingAdvance);
  double? get latestMaf => _latest(VehicleSignal.maf);
  double? get latestMapKpa => _latest(VehicleSignal.manifoldPressure);
  double? get latestStft => _latest(VehicleSignal.stftBank1);
  double? get latestLtft => _latest(VehicleSignal.ltftBank1);

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
