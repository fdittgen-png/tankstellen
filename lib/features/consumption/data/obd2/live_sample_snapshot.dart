// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import 'elm327_protocol.dart';
import 'obd2_breadcrumb_collector.dart';
import 'obd2_service.dart';
import 'pid_scheduler.dart';

/// The "clock"-side snapshot extracted from [TripRecordingController]
/// (#1679): the per-PID latest-value scratch space, the scheduler
/// subscription wiring that fills it, and the tier-1/2/3 fuel-rate
/// derivation that reads it.
///
/// The controller keeps the emit timer + `_emit` itself — that path
/// entangles lifecycle flags, the recorder, and the fuel accumulators.
/// This collaborator is the safe core of the split: it owns the
/// values, the controller reads them once per emit tick.
///
/// Scheduler callbacks push high-priority parse outcomes back through
/// [_onHighPriorityParse] (the controller's silent-failure observer)
/// and vehicle-speed samples through [_onSpeedSample] (the controller's
/// virtual-odometer buffer), so this class carries no drop-detection
/// or distance state of its own.
class LiveSampleSnapshot {
  LiveSampleSnapshot({
    required Obd2Service service,
    VehicleProfile? vehicle,
    ReferenceVehicle? referenceVehicle,
    Obd2BreadcrumbRecorder? breadcrumbCollector,
    required void Function(Object? parsedValue) onHighPriorityParse,
    required void Function(double speedKmh) onSpeedSample,
  })  : _service = service,
        _vehicle = vehicle,
        _referenceVehicle = referenceVehicle,
        _breadcrumbCollector = breadcrumbCollector,
        _onHighPriorityParse = onHighPriorityParse,
        _onSpeedSample = onSpeedSample;

  final Obd2Service _service;
  final VehicleProfile? _vehicle;
  final ReferenceVehicle? _referenceVehicle;
  final Obd2BreadcrumbRecorder? _breadcrumbCollector;
  final void Function(Object? parsedValue) _onHighPriorityParse;
  final void Function(double speedKmh) _onSpeedSample;

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
  double? _latestThrottlePercent;
  double? _latestEngineLoadPercent;
  double? _latestCoolantTempC;
  double? _latestFuelLevelPercent;
  double? _latestStft;
  double? _latestLtft;
  double? _latestDirectFuelRate;

  // #1374 phase 1 — most recent GPS fix, pushed in by the provider
  // when the `Feature.gpsTripPath` flag is enabled. The controller
  // does NOT subscribe to Geolocator itself — that decision lives at
  // the provider layer. When the flag is off both fields stay null
  // and every persisted sample carries `latitude: null,
  // longitude: null` (matching pre-#1374 behaviour bit-for-bit).
  double? _latestLatitude;
  double? _latestLongitude;

  // #1935 child A — most recent GPS altitude (metres), pushed in
  // alongside the lat/lon fix. Feeds the road-grade calculator (#1941).
  double? _latestAltitudeM;

  // #1615 — most recent exact-litre OEM-PID fuel reading, pushed in by
  // the provider layer (`TripOemFuelLevelController`) when the
  // `experimentalOemPids` flag is on and an OEM-capable adapter
  // resolved a manufacturer table. The OEM read is a multi-command
  // async sequence that does NOT fit the per-PID scheduler, so this
  // class never issues it itself — it only holds the latch. When the
  // flag is off (or no OEM read ever lands) this stays null and `_emit`
  // produces a reading identical to pre-#1615 behaviour.
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
  double? get latestOemFuelLevelLitres => _latestOemFuelLevelLitres;

  /// Push the most recent GPS fix into the per-tick snapshot
  /// (#1374 phase 1; altitude added #1935 child A). Pass `null` for a
  /// field to clear that latch.
  void updateGpsFix({double? latitude, double? longitude, double? altitudeM}) {
    _latestLatitude = latitude;
    _latestLongitude = longitude;
    _latestAltitudeM = altitudeM;
  }

  /// Push the most recent exact-litre OEM-PID fuel reading into the
  /// per-tick snapshot (#1615). Pass `null` to clear the latch (e.g.
  /// the OEM read returned NO DATA). Called by the provider-layer
  /// `TripOemFuelLevelController`; the controller's `_emit` reads it
  /// back into `TripLiveReading.fuelLevelLitres`.
  void updateOemFuelLevelLitres(double? litres) {
    _latestOemFuelLevelLitres = litres;
  }

  /// Wire every priority tier's PID subscriptions onto [scheduler].
  /// Each callback writes the latest parsed value into this snapshot;
  /// high-priority callbacks additionally feed the silent-failure
  /// observer, and the vehicle-speed callback feeds the virtual
  /// odometer.
  void subscribeAllTiers(PidScheduler scheduler) {
    // ---- 5 Hz tier (high priority) --------------------------------
    // RPM and speed are consumed directly by TripSample → TripRecorder
    // for distance/idle/harsh-accel accumulation, so they need the
    // highest refresh we can squeeze out of the adapter.
    scheduler.subscribe(
      Elm327Protocol.engineRpmCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseEngineRpm(r);
        if (v != null) _latestRpm = v;
        _onHighPriorityParse(v);
      },
    );
    scheduler.subscribe(
      Elm327Protocol.vehicleSpeedCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseVehicleSpeed(r);
        if (v != null) {
          _latestSpeedKmh = v.toDouble();
          _onSpeedSample(v.toDouble());
        }
        _onHighPriorityParse(v);
      },
    );
    // MAF and MAP are the two alternate air-mass inputs to the fuel-
    // rate derivation. Cheap cars (Peugeot 107) only have MAP+IAT;
    // modern cars expose MAF. We subscribe both and let the snapshot-
    // based derivation pick whichever landed most recently.
    if (_service.supportsPid(0x10)) {
      scheduler.subscribe(
        Elm327Protocol.mafCommand,
        ScheduledPid(hz: 5.0, priority: PidPriority.high),
        (r) {
          final v = Elm327Protocol.parseMafGramsPerSecond(r);
          if (v != null) _latestMaf = v;
          _onHighPriorityParse(v);
        },
      );
    }
    if (_service.supportsPid(0x0B)) {
      scheduler.subscribe(
        Elm327Protocol.intakeManifoldPressureCommand,
        ScheduledPid(hz: 5.0, priority: PidPriority.high),
        (r) {
          final v = Elm327Protocol.parseManifoldPressureKpa(r);
          if (v != null) _latestMapKpa = v;
          _onHighPriorityParse(v);
        },
      );
    }
    scheduler.subscribe(
      Elm327Protocol.throttlePositionCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseThrottlePercent(r);
        if (v != null) _latestThrottlePercent = v;
        _onHighPriorityParse(v);
      },
    );
    // PID 5E is only present on ~2014+ ECUs. Skip when #811 discovery
    // already proved the car rejects it, to save the 200 ms round-
    // trip of a guaranteed NO DATA.
    if (_service.supportsPid(0x5E)) {
      scheduler.subscribe(
        Elm327Protocol.engineFuelRateCommand,
        ScheduledPid(hz: 5.0, priority: PidPriority.high),
        (r) {
          final v = Elm327Protocol.parseFuelRateLPerHour(r);
          if (v != null) _latestDirectFuelRate = v;
          _onHighPriorityParse(v);
        },
      );
    }

    // ---- 1 Hz tier (medium priority) ------------------------------
    scheduler.subscribe(
      Elm327Protocol.engineLoadCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseEngineLoad(r);
        if (v != null) _latestEngineLoadPercent = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.intakeAirTempCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseIntakeAirTempCelsius(r);
        if (v != null) _latestIatCelsius = v;
      },
    );
    // Coolant temp drifts slowly — 1 Hz is more than enough resolution
    // for the cold-start surcharge heuristic (#1262 phase 2) to detect
    // whether the trip ever crossed operating temperature.
    scheduler.subscribe(
      Elm327Protocol.coolantTempCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseCoolantTempCelsius(r);
        if (v != null) _latestCoolantTempC = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.shortTermFuelTrimCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseShortTermFuelTrim(r);
        if (v != null) _latestStft = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.longTermFuelTrimCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseLongTermFuelTrim(r);
        if (v != null) _latestLtft = v;
      },
    );

    // ---- 0.1 Hz tier (low priority) -------------------------------
    scheduler.subscribe(
      Elm327Protocol.fuelTankLevelCommand,
      ScheduledPid(hz: 0.1, priority: PidPriority.low),
      (r) {
        final v = Elm327Protocol.parseFuelLevelPercent(r);
        if (v != null) _latestFuelLevelPercent = v;
      },
    );
  }

  /// #1858 — the branch [deriveFuelRateLPerHour] resolved on its most
  /// recent call. Lets the controller tell η_v-derived fuel (the
  /// [Obd2BranchTag.speedDensity] branch) from fuel that does not use
  /// η_v (PID 5E / MAF) so it can stamp the trip's recompute
  /// provenance. Null before the first call.
  Obd2BranchTag? _lastFuelRateBranch;
  Obd2BranchTag? get lastFuelRateBranch => _lastFuelRateBranch;

  /// #1858 — the volumetric efficiency applied on the most recent
  /// [deriveFuelRateLPerHour] call. Only meaningful when
  /// [lastFuelRateBranch] is [Obd2BranchTag.speedDensity]; null
  /// otherwise (PID 5E / MAF / no rate do not use η_v).
  double? _lastFuelRateVe;
  double? get lastFuelRateVe => _lastFuelRateVe;

  /// Derive the current fuel rate (L/h) from whatever snapshot
  /// values have landed so far. Mirrors the tier-1/2/3 fallback in
  /// [Obd2Service.readFuelRateLPerHour], but over snapshot values
  /// instead of live I/O — the scheduler has already done the
  /// reads. Returns null when not enough inputs have arrived yet
  /// (e.g. first 200 ms of a trip before MAP/IAT both land).
  ///
  /// AFR + density are chosen from the active vehicle's preferred
  /// fuel type via [resolveAfrDensity] (#800, #2432): diesel → 14.5 /
  /// 832 g/L, E85 → 9.8 / 785 g/L, LPG → 15.6 / 535 g/L, CNG → 17.2 /
  /// petrol-equivalent density, and null / unknown stays on the petrol
  /// defaults the pre-#800 path used. Manual AFR / density overrides
  /// win over the mapping.
  double? deriveFuelRateLPerHour() {
    // #1858 — provenance defaults; each branch below overrides them.
    _lastFuelRateBranch = Obd2BranchTag.none;
    _lastFuelRateVe = null;
    // #1397 / #2432 — single fuel-type lookup: manual AFR/density
    // overrides win, else the free-text fuel key maps to its
    // AFR/density (petrol/diesel/E85/LPG/CNG), else the petrol default.
    // Mirrors the resolution chain in
    // [Obd2Service.readFuelRateLPerHour] so the live integrator and the
    // pull-mode estimator agree on every scalar. `resolveAfrDensity` is
    // re-exported from `obd2_service.dart`.
    final afrDensity = resolveAfrDensity(_vehicle);
    final afr = afrDensity.afr;
    final density = afrDensity.densityGPerL;
    final displacement = _vehicle?.manualEngineDisplacementCcOverride
            ?.round() ??
        _vehicle?.engineDisplacementCc ??
        1000;
    // #1422 phase 1 — same precedence as Obd2Service.readFuelRateLPerHour:
    // manual override → stored profile (when learned or non-default) →
    // engine-tech helper on the reference catalog row → hard 0.85
    // fallback. The two paths must agree so the live integrator and
    // the pull-mode estimator produce identical numbers for the same
    // tick.
    final ve = _vehicle?.manualVolumetricEfficiencyOverride ??
        _resolveControllerProfileVe() ??
        (_referenceVehicle != null
            ? defaultVolumetricEfficiency(_referenceVehicle)
            : 0.85);
    final collector = _breadcrumbCollector;

    // Step 1: direct PID 5E. Already post-trim, no correction.
    final direct = _latestDirectFuelRate;
    if (direct != null) {
      // #1395 — sanity bound A: implausibly-low at non-idle RPM.
      // Same threshold as Obd2Service.readFuelRateLPerHour but evaluated
      // on the controller's most-recent RPM snapshot so this works
      // even when the trip is being driven by raw scheduler callbacks
      // rather than the readFuelRate API.
      String? lowFlag;
      String? lowDetail;
      final rpm = _latestRpm;
      if (direct < 0.3 && rpm != null && rpm > 1500) {
        lowFlag = Obd2BreadcrumbCollector.flagSuspiciousLow;
        lowDetail = 'directRate=${direct.toStringAsFixed(2)};'
            'rpm=${rpm.toStringAsFixed(0)}';
      }
      collector?.record(
        branch: Obd2BranchTag.pid5E,
        fuelRateLPerHour: direct,
        pid5ELPerHour: direct,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
        flag: lowFlag,
        flagDetail: lowDetail,
      );
      // Sanity bound B: 5E vs MAF cross-check on the controller's
      // cached MAF snapshot. Evaluated AFTER the breadcrumb is
      // pushed so [recordFlag] mutates the same row.
      final mafSnapshot = _latestMaf;
      if (mafSnapshot != null) {
        final mafDerived = mafSnapshot * 3600.0 / (afr * density);
        if (mafDerived > 0 &&
            (direct - mafDerived).abs() / mafDerived > 0.5) {
          collector?.recordFlag(
            Obd2BreadcrumbCollector.flag5eVsMafDivergent,
            'direct=${direct.toStringAsFixed(2)};'
                'mafDerived=${mafDerived.toStringAsFixed(2)};'
                'maf=${mafSnapshot.toStringAsFixed(2)}',
          );
        }
      }
      _lastFuelRateBranch = Obd2BranchTag.pid5E;
      return direct;
    }

    // Step 2: MAF-based. L/h = MAF × 3600 / (AFR × density).
    final maf = _latestMaf;
    if (maf != null) {
      final raw = maf * 3600.0 / (afr * density);
      final corrected = _applyTrim(raw);
      collector?.record(
        branch: Obd2BranchTag.maf,
        fuelRateLPerHour: corrected,
        mafGramsPerSecond: maf,
        rpm: _latestRpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      _lastFuelRateBranch = Obd2BranchTag.maf;
      return corrected;
    }

    // Step 3: speed-density from MAP+IAT+RPM. Feeds the pre-#810
    // estimator with the active vehicle's displacement + VE (#812).
    final mapKpa = _latestMapKpa;
    final iat = _latestIatCelsius;
    final rpm = _latestRpm;
    if (mapKpa == null || iat == null || rpm == null) {
      collector?.record(
        branch: Obd2BranchTag.none,
        mapKpa: mapKpa,
        iatCelsius: iat,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      return null;
    }
    final raw = Obd2Service.estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      engineDisplacementCc: displacement,
      volumetricEfficiency: ve,
      afr: afr,
      fuelDensityGPerL: density,
    );
    if (raw == null) {
      collector?.record(
        branch: Obd2BranchTag.none,
        mapKpa: mapKpa,
        iatCelsius: iat,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      return null;
    }
    final corrected = _applyTrim(raw);
    collector?.record(
      branch: Obd2BranchTag.speedDensity,
      fuelRateLPerHour: corrected,
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      afr: afr,
      fuelDensityGPerL: density,
      engineDisplacementCc: displacement.toDouble(),
      volumetricEfficiency: ve,
    );
    // #1858 — the only η_v-derived branch: record the η_v applied so
    // the controller can stamp the trip's recompute provenance.
    _lastFuelRateBranch = Obd2BranchTag.speedDensity;
    _lastFuelRateVe = ve;
    return corrected;
  }

  /// Returns the user profile's η_v that should beat the engine-tech
  /// helper, or null when the helper should kick in instead (#1422
  /// phase 1). Mirrors the rules in [_resolveProfileVolumetricEfficiency]
  /// in `obd2_service.dart` so both the live integrator and the
  /// pull-mode estimator agree on a per-tick basis.
  ///
  /// Profile null → null (caller will use the helper or hard fallback).
  /// Without a reference catalog row the stored profile value is the
  /// best we can do, even if it equals the legacy 0.85 default.
  /// Otherwise: keep the stored value when the VeLearner has logged at
  /// least one sample OR when the value differs from the legacy 0.85
  /// default. A cold-start profile sitting on 0.85 with zero samples
  /// returns null, letting the engine-tech helper provide a closer
  /// initial guess (e.g. 0.95 for a Dacia dCi VNT diesel).
  double? _resolveControllerProfileVe() {
    final v = _vehicle;
    if (v == null) return null;
    if (_referenceVehicle == null) return v.volumetricEfficiency;
    if (v.volumetricEfficiencySamples > 0) return v.volumetricEfficiency;
    if (v.volumetricEfficiency != 0.85) return v.volumetricEfficiency;
    return null;
  }

  /// Apply the STFT + LTFT correction used on the MAF / speed-density
  /// branches (#813). Returns [raw] unchanged when either trim hasn't
  /// landed yet — better an uncorrected estimate than one shifted by
  /// half the real signal.
  double _applyTrim(double raw) {
    final stft = _latestStft;
    final ltft = _latestLtft;
    if (stft == null || ltft == null) return raw;
    return Obd2Service.applyFuelTrimCorrection(raw, stft: stft, ltft: ltft);
  }
}
