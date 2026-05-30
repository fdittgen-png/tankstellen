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

  // #2456 — commanded equivalence ratio λ (PID 0x44) and absolute
  // barometric pressure (PID 0x33). Both refine the MAF / speed-density
  // fuel derivation when the car exposes them and stay null (today's
  // behaviour, bit-for-bit) on cars that don't. λ is sampled fast (it
  // tracks the mixture under load); baro is sampled slowly (it only
  // changes with altitude / weather).
  double? _latestLambda;
  double? _latestBaroKpa;

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

  /// Wire the four cadence tiers' PID subscriptions onto [scheduler]
  /// (#2457). Each callback writes the latest parsed value into this
  /// snapshot; dynamics-tier callbacks also feed the silent-failure
  /// observer, and the vehicle-speed callback feeds the virtual odometer.
  ///
  /// **Cadence tiers** (re-expressing the previous 3-tier layout on the
  /// same weighted round-robin; the governor demotes deepest tiers first,
  /// never [PidTier.dynamics], so RPM / speed never starve):
  ///   - [PidTier.dynamics] ~5 Hz — RPM 010C, speed 010D, throttle 0111,
  ///     + the fuel-rate driver (015E → MAF 0110 → MAP 010B speed-density).
  ///   - [PidTier.mixture] ~2 Hz — λ 0144, engine load 0104.
  ///   - [PidTier.slowCorrection] ~0.5 Hz — STFT 0106, LTFT 0107, IAT
  ///     010F, baro 0133.
  ///   - [PidTier.thermalContext] ~0.1 Hz — coolant 0105, fuel tank 012F.
  /// (#2458 adds pedal to dynamics, abs-load/bank-2 to mixture, and
  /// oil/ambient/voltage to thermal — slots are commented inline below.)
  ///
  /// **Discover-all ∩ target-set:** the live set is this target table ∩
  /// the #811-discovered supported set. The unconditional core (RPM,
  /// speed, throttle, load, IAT, coolant, STFT, LTFT, tank) carries no
  /// gate — `isPidSupported` is don't-reject-blind so a probe-less clone
  /// still rotates it. Optional PIDs (MAF, MAP, 015E, λ, baro) pass an
  /// `optionalPid` gate, so a car supporting only {010C,010D,0104,0111}
  /// subscribes exactly those plus the core. Adding a PID is a one-line
  /// [_sub] call — the gate, tier, hz and priority travel together.
  void subscribeAllTiers(PidScheduler scheduler) {
    // ---- DYNAMICS tier (~5 Hz, high priority) ----------------------
    // RPM and speed feed TripSample → TripRecorder for distance / idle /
    // harsh-accel accumulation, so they need the highest refresh we can
    // squeeze out of the adapter — and the governor's floor guards them.
    _sub(scheduler, Elm327Protocol.engineRpmCommand,
        hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics, (r) {
      final v = Elm327Protocol.parseEngineRpm(r);
      if (v != null) _latestRpm = v;
      _onHighPriorityParse(v);
    });
    _sub(scheduler, Elm327Protocol.vehicleSpeedCommand,
        hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics, (r) {
      final v = Elm327Protocol.parseVehicleSpeed(r);
      if (v != null) {
        _latestSpeedKmh = v.toDouble();
        _onSpeedSample(v.toDouble());
      }
      _onHighPriorityParse(v);
    });
    _sub(scheduler, Elm327Protocol.throttlePositionCommand,
        hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics, (r) {
      final v = Elm327Protocol.parseThrottlePercent(r);
      if (v != null) _latestThrottlePercent = v;
      _onHighPriorityParse(v);
    });
    // #2458 slot: accelerator-pedal (0149/014A/014B) — driver intent, 5 Hz.
    //
    // The fuel-rate driver: subscribe whichever the car exposes (015E
    // direct → MAF → MAP speed-density) and let the snapshot derivation
    // pick the richest branch that landed. All three optionalPid-gated.
    _sub(scheduler, Elm327Protocol.engineFuelRateCommand,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optionalPid: 0x5E, (r) {
      final v = Elm327Protocol.parseFuelRateLPerHour(r);
      if (v != null) _latestDirectFuelRate = v;
      _onHighPriorityParse(v);
    });
    _sub(scheduler, Elm327Protocol.mafCommand,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optionalPid: 0x10, (r) {
      final v = Elm327Protocol.parseMafGramsPerSecond(r);
      if (v != null) _latestMaf = v;
      _onHighPriorityParse(v);
    });
    _sub(scheduler, Elm327Protocol.intakeManifoldPressureCommand,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optionalPid: 0x0B, (r) {
      final v = Elm327Protocol.parseManifoldPressureKpa(r);
      if (v != null) _latestMapKpa = v;
      _onHighPriorityParse(v);
    });

    // ---- MIXTURE tier (~2 Hz, medium priority) ---------------------
    // The mixture swings on the timescale of throttle inputs, so 2 Hz
    // keeps the effective-AFR refinement current without stealing the
    // dynamics budget. #2456 — commanded λ (0x44), optionalPid-gated:
    // absent → the derivation falls back to the assumed stoich AFR.
    _sub(scheduler, Elm327Protocol.commandedEquivalenceRatioCommand,
        hz: 2.0, tier: PidTier.mixture, optionalPid: 0x44, (r) {
      final v = Elm327Protocol.parseCommandedEquivalenceRatio(r);
      if (v != null) _latestLambda = v;
    });
    _sub(scheduler, Elm327Protocol.engineLoadCommand,
        hz: 2.0, tier: PidTier.mixture, (r) {
      final v = Elm327Protocol.parseEngineLoad(r);
      if (v != null) _latestEngineLoadPercent = v;
    });
    // #2458 slot: absolute load (0143), bank-2 fuel trims (0108/0109).

    // ---- SLOW-CORRECTION tier (~0.5 Hz, medium priority) -----------
    // Fuel trims + IAT drift slowly; the corrections only matter at the
    // half-Hz scale of the fuel-rate integration.
    _sub(scheduler, Elm327Protocol.shortTermFuelTrimCommand,
        hz: 0.5, tier: PidTier.slowCorrection, (r) {
      final v = Elm327Protocol.parseShortTermFuelTrim(r);
      if (v != null) _latestStft = v;
    });
    _sub(scheduler, Elm327Protocol.longTermFuelTrimCommand,
        hz: 0.5, tier: PidTier.slowCorrection, (r) {
      final v = Elm327Protocol.parseLongTermFuelTrim(r);
      if (v != null) _latestLtft = v;
    });
    _sub(scheduler, Elm327Protocol.intakeAirTempCommand,
        hz: 0.5, tier: PidTier.slowCorrection, (r) {
      final v = Elm327Protocol.parseIntakeAirTempCelsius(r);
      if (v != null) _latestIatCelsius = v;
    });
    // #2456 — absolute baro (0x33). Ambient pressure changes only with
    // altitude / weather, so 0.5 Hz is ample. optionalPid-gated: absent →
    // the speed-density air-mass keeps its sea-level assumption.
    _sub(scheduler, Elm327Protocol.baroPressureCommand,
        hz: 0.5, tier: PidTier.slowCorrection, optionalPid: 0x33, (r) {
      final v = Elm327Protocol.parseBaroPressureKpa(r);
      if (v != null) _latestBaroKpa = v;
    });

    // ---- THERMAL/CONTEXT tier (~0.1 Hz, low priority) --------------
    // These change over minutes; first to be demoted under bandwidth
    // pressure. 0.1 Hz coolant is ample for the cold-start surcharge
    // heuristic (#1262 phase 2) to tell if the trip reached temperature.
    _sub(scheduler, Elm327Protocol.coolantTempCommand,
        hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext,
        (r) {
      final v = Elm327Protocol.parseCoolantTempCelsius(r);
      if (v != null) _latestCoolantTempC = v;
    });
    _sub(scheduler, Elm327Protocol.fuelTankLevelCommand,
        hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext,
        (r) {
      final v = Elm327Protocol.parseFuelLevelPercent(r);
      if (v != null) _latestFuelLevelPercent = v;
    });
    // #2458 slot: oil temp (015C), ambient air (0146), control-module
    // voltage (0142) — all thermal/context, all 0.1 Hz.
  }

  /// Register one tier subscription on [scheduler] (#2457). Centralises
  /// the discover-all ∩ target-set gate so each PID above is a single
  /// line carrying its [hz], [tier], [priority] and optional [optionalPid]
  /// gate together.
  ///
  /// When [optionalPid] is null the command is part of the unconditional
  /// core and is always subscribed (relying on `isPidSupported`'s
  /// don't-reject-blind semantics + the #2379 backoff to self-evict if
  /// the car NO-DATAs it). When [optionalPid] is set, the command is only
  /// subscribed if `_service.supportsPid(optionalPid)` — i.e. the target
  /// PID intersected the car's discovered-supported set.
  void _sub(
    PidScheduler scheduler,
    String command,
    void Function(String response) onResult, {
    required double hz,
    required PidTier tier,
    PidPriority priority = PidPriority.medium,
    int? optionalPid,
  }) {
    if (optionalPid != null && !_service.supportsPid(optionalPid)) return;
    scheduler.subscribe(
      command,
      ScheduledPid(hz: hz, priority: priority, tier: tier),
      onResult,
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

    // Step 2: MAF-based. L/h = MAF × 3600 / (effectiveAFR × density).
    // #2456 — when commanded λ (PID 0x44) has landed, the assumed stoich
    // AFR is replaced with the ECU's effective AFR (richer mixture →
    // more fuel). Null λ → `effectiveAfr == afr`, i.e. unchanged.
    final maf = _latestMaf;
    if (maf != null) {
      final effectiveAfr = effectiveAfrForLambda(afr, _latestLambda);
      final raw = maf * 3600.0 / (effectiveAfr * density);
      final corrected = _applyTrim(raw);
      collector?.record(
        branch: Obd2BranchTag.maf,
        fuelRateLPerHour: corrected,
        mafGramsPerSecond: maf,
        rpm: _latestRpm,
        afr: effectiveAfr,
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
    // #2456 — feed the measured baro (PID 0x33) + commanded λ (PID 0x44)
    // into the speed-density math when available: baro scales the air
    // charge for altitude / weather, λ replaces the assumed stoich AFR.
    // Both null → byte-for-byte the pre-#2456 result. The effective AFR
    // is recorded in the breadcrumb so diagnostics reflect the real
    // denominator.
    final lambda = _latestLambda;
    final baroKpa = _latestBaroKpa;
    final effectiveAfr = effectiveAfrForLambda(afr, lambda);
    final raw = Obd2Service.estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      engineDisplacementCc: displacement,
      volumetricEfficiency: ve,
      afr: afr,
      fuelDensityGPerL: density,
      baroKpa: baroKpa,
      lambda: lambda,
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
      afr: effectiveAfr,
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
