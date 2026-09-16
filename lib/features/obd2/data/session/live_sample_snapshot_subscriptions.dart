// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'live_sample_snapshot.dart';

/// The scheduler-subscription wiring extracted from [LiveSampleSnapshot]
/// as a `part` mixin so it keeps private-member access while
/// `live_sample_snapshot.dart` stays under the #1680 file-length cap
/// (sanctioned #3760 decomposition — move-only, behaviour preserved):
/// the four cadence tiers' PID subscriptions that fill the latches.
mixin _LiveSampleSnapshotSubscriptions on _LiveSampleSnapshotLatches {
  /// Wire the four cadence tiers' PID subscriptions onto [scheduler]
  /// (#2457). Each callback writes the latest parsed value into this
  /// snapshot; dynamics-tier callbacks also feed the silent-failure
  /// observer, and the vehicle-speed callback feeds the virtual odometer.
  ///
  /// **Cadence tiers** (weighted round-robin; the governor demotes deepest
  /// tiers first, never [PidTier.dynamics], so RPM / speed never starve):
  /// the tier sections below name each signal and its rate.
  ///
  /// **Discover-all ∩ target-set:** the live set is this target table ∩
  /// the #811-discovered supported set. The unconditional core carries no
  /// gate — `isPidSupported` is don't-reject-blind so a probe-less clone
  /// still rotates it; `optional` signals ask the adapter's support gate
  /// for that signal (#4159). Adding a signal is one [_sub] call.
  void subscribeAllTiers(PidScheduler scheduler) {
    // ---- DYNAMICS tier (~5 Hz, high priority) ----------------------
    // RPM and speed feed TripSample → TripRecorder for distance / idle /
    // harsh-accel accumulation, so they need the highest refresh we can
    // squeeze out of the adapter — and the governor's floor guards them.
    _sub(scheduler, VehicleSignal.engineRpm,
        hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics, (r) {
      final v = Elm327Protocol.parseEngineRpm(r);
      if (v != null) {
        _latestRpm = v;
        // #3856 — the recording loop's parses bypass the typed read
        // helpers, so the power model is stamped here: rpm is the
        // authoritative running/awake reading.
        Obd2VehiclePower.instance.noteRpm(v);
      }
      _onHighPriorityParse(v);
    });
    _sub(scheduler, VehicleSignal.vehicleSpeed,
        hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics, (r) {
      final v = Elm327Protocol.parseVehicleSpeed(r);
      if (v != null) {
        _latestSpeedKmh = v.toDouble();
        _onSpeedSample(v.toDouble());
        Obd2VehiclePower.instance.noteBusAnswered(); // #3856 — awake
      }
      _onHighPriorityParse(v);
    });
    _sub(scheduler, VehicleSignal.throttle,
        hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics, (r) {
      final v = Elm327Protocol.parseThrottlePercent(r);
      if (v != null) _latestThrottlePercent = v;
      _onHighPriorityParse(v);
    });
    // #2458 — accelerator-pedal (0149/014A/014B) — driver intent, 5 Hz.
    // Three channels track the same physical pedal; subscribe whichever
    // the car exposes and keep the running max (the least-damped reading).
    // All optionalPid-gated, so a car with none subscribes none and
    // _latestPedalPercent stays null. Pedal is acquired + persisted here;
    // the driving-style consumption is #2460.
    _sub(scheduler, VehicleSignal.pedalD,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optional: true, (r) {
      final v = Elm327Protocol.parseAcceleratorPedalD(r);
      if (v != null) _latestPedalD = v;
    });
    _sub(scheduler, VehicleSignal.pedalE,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optional: true, (r) {
      final v = Elm327Protocol.parseAcceleratorPedalE(r);
      if (v != null) _latestPedalE = v;
    });
    _sub(scheduler, VehicleSignal.pedalF,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optional: true, (r) {
      final v = Elm327Protocol.parseAcceleratorPedalF(r);
      if (v != null) _latestPedalF = v;
    });
    //
    // The fuel-rate driver: subscribe whichever the car exposes (015E
    // direct → MAF → MAP speed-density) and let the snapshot derivation
    // pick the richest branch that landed. All three optionalPid-gated.
    _sub(scheduler, VehicleSignal.fuelRate,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optional: true, (r) {
      final v = Elm327Protocol.parseFuelRateLPerHour(r);
      if (v != null) _latestDirectFuelRate = v;
      _onHighPriorityParse(v);
    });
    _sub(scheduler, VehicleSignal.maf,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optional: true, (r) {
      final v = Elm327Protocol.parseMafGramsPerSecond(r);
      if (v != null) _latestMaf = v;
      _onHighPriorityParse(v);
    });
    _sub(scheduler, VehicleSignal.manifoldPressure,
        hz: 5.0,
        priority: PidPriority.high,
        tier: PidTier.dynamics,
        optional: true, (r) {
      final v = Elm327Protocol.parseManifoldPressureKpa(r);
      if (v != null) _latestMapKpa = v;
      _onHighPriorityParse(v);
    });

    // ---- MIXTURE tier (~2 Hz, medium priority) ---------------------
    // The mixture swings on the timescale of throttle inputs, so 2 Hz
    // keeps the effective-AFR refinement current without stealing the
    // dynamics budget. #2456 — commanded φ (0x44), optionalPid-gated:
    // absent → the derivation falls back to the assumed stoich AFR.
    _sub(scheduler, VehicleSignal.commandedPhi,
        hz: 2.0, tier: PidTier.mixture, optional: true, (r) {
      final v = Elm327Protocol.parseCommandedEquivalenceRatio(r);
      if (v != null) _latestCommandedPhi = v;
    });
    _sub(scheduler, VehicleSignal.engineLoad,
        hz: 2.0, tier: PidTier.mixture, (r) {
      final v = Elm327Protocol.parseEngineLoad(r);
      if (v != null) _latestEngineLoadPercent = v;
    });
    // #2458 — absolute load (0143). High-load proxy (>100 % on boosted
    // engines); optionalPid-gated, acquired + persisted. Mixture tier.
    _sub(scheduler, VehicleSignal.absoluteLoad,
        hz: 2.0, tier: PidTier.mixture, optional: true, (r) {
      final v = Elm327Protocol.parseAbsoluteLoad(r);
      if (v != null) _latestAbsLoadPercent = v;
    });

    // ---- SLOW-CORRECTION tier (~0.5 Hz, medium priority) -----------
    // Fuel trims + IAT drift slowly; the corrections only matter at the
    // half-Hz scale of the fuel-rate integration.
    _sub(scheduler, VehicleSignal.stftBank1,
        hz: 0.5, tier: PidTier.slowCorrection, (r) {
      final v = Elm327Protocol.parseShortTermFuelTrim(r);
      if (v != null) _latestStft = v;
    });
    _sub(scheduler, VehicleSignal.ltftBank1,
        hz: 0.5, tier: PidTier.slowCorrection, (r) {
      final v = Elm327Protocol.parseLongTermFuelTrim(r);
      if (v != null) _latestLtft = v;
    });
    // #2458 — bank-2 fuel trims (0108/0109). Only dual-bank (V / boxer)
    // engines expose them; optionalPid-gated, so inline engines never
    // subscribe and the trim correction stays bank-1-only. Slow tier.
    _sub(scheduler, VehicleSignal.stftBank2,
        hz: 0.5, tier: PidTier.slowCorrection, optional: true, (r) {
      final v = Elm327Protocol.parseShortTermFuelTrimBank2(r);
      if (v != null) _latestStftBank2 = v;
    });
    _sub(scheduler, VehicleSignal.ltftBank2,
        hz: 0.5, tier: PidTier.slowCorrection, optional: true, (r) {
      final v = Elm327Protocol.parseLongTermFuelTrimBank2(r);
      if (v != null) _latestLtftBank2 = v;
    });
    _sub(scheduler, VehicleSignal.intakeAirTemp,
        hz: 0.5, tier: PidTier.slowCorrection, (r) {
      final v = Elm327Protocol.parseIntakeAirTempCelsius(r);
      if (v != null) {
        _latestIatCelsius = v;
        _latestIatAt = _clock(); // #2505 — latch for the staleness window.
      }
    });
    // #3692 — timing advance (0x0E): knock retard under boost is a
    // consumption signal. Slow tier; optionalPid-gated, absent → null.
    _sub(scheduler, VehicleSignal.timingAdvance,
        hz: 0.5, tier: PidTier.slowCorrection, optional: true, (r) {
      final v = Elm327Protocol.parseTimingAdvanceDeg(r);
      if (v != null) _latestTimingAdvanceDeg = v;
    });
    // #2456 — absolute baro (0x33). Ambient pressure changes only with
    // altitude / weather, so 0.5 Hz is ample. optionalPid-gated: absent →
    // the speed-density air-mass keeps its sea-level assumption.
    _sub(scheduler, VehicleSignal.baroPressure,
        hz: 0.5, tier: PidTier.slowCorrection, optional: true, (r) {
      final v = Elm327Protocol.parseBaroPressureKpa(r);
      if (v != null) _latestBaroKpa = v;
    });

    // ---- THERMAL/CONTEXT tier (~0.1 Hz, low priority) --------------
    // These change over minutes; first to be demoted under bandwidth
    // pressure. 0.1 Hz coolant is ample for the cold-start surcharge
    // heuristic (#1262 phase 2) to tell if the trip reached temperature.
    _sub(scheduler, VehicleSignal.coolantTemp,
        hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext,
        (r) {
      final v = Elm327Protocol.parseCoolantTempCelsius(r);
      if (v != null) _latestCoolantTempC = v;
    });
    _sub(scheduler, VehicleSignal.fuelTankLevel,
        hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext,
        (r) {
      final v = Elm327Protocol.parseFuelLevelPercent(r);
      if (v != null) _latestFuelLevelPercent = v;
    });
    // #2459 — oil temp (015C) + ambient air (0146): optional
    // diagnostic-context thermal signals. Both optionalPid-gated and
    // persisted only when present; thermal tier, 0.1 Hz.
    _sub(scheduler, VehicleSignal.oilTemp,
        hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext, (r) {
      final v = Elm327Protocol.parseEngineOilTempCelsius(r);
      if (v != null) _latestOilTempC = v;
    }, optional: true);
    _sub(scheduler, VehicleSignal.ambientAirTemp,
        hz: 0.1, priority: PidPriority.low, tier: PidTier.thermalContext, (r) {
      final v = Elm327Protocol.parseAmbientAirTempCelsius(r);
      if (v != null) _latestAmbientTempC = v;
    }, optional: true);

    // ---- Epic #3416 precision PIDs -------------------------------------
    // Wideband measured φ → mixture tier (#3427); MAF 0x66 / fuel-rate
    // 0x9D / 0xA2 → dynamics (#3428); ethanol 0x52 → slow (#3429). STRICT
    // support gate (resolved ∧ contains): rare modern PIDs are never
    // blind-subscribed, or an unresolved clone floods the round-robin
    // with NO DATA initial reads and starves the dynamics tier.
    // #3784 — closure, not a tearoff: a tearoff pins the service instance
    // at subscribe time, so after a mid-trip rebind the gate kept reading
    // the DEAD original's per-connection state.
    _precision.subscribe(scheduler,
        isPidSupported: (pid) => _service.isPidKnownSupported(pid));
  }

  /// Register one tier subscription on [scheduler] (#2457): each signal is
  /// a single call carrying its [hz], [tier], [priority] and whether it is
  /// [optional]. Core → always subscribed (don't-reject-blind + the #2379
  /// backoff self-evicts on NO DATA); [optional] → subscribed only if the
  /// adapter's gate for [signal] passes on this connection (#4159 — the
  /// PID, request and gate kind come from `Obd2SignalPids`).
  void _sub(
    PidScheduler scheduler,
    VehicleSignal signal,
    void Function(String response) onResult, {
    required double hz,
    required PidTier tier,
    PidPriority priority = PidPriority.medium,
    bool optional = false,
  }) {
    if (optional && !_service.supports(signal)) return;
    scheduler.subscribe(
      Obd2SignalPids.commandOf(signal),
      ScheduledPid(hz: hz, priority: priority, tier: tier),
      onResult,
    );
  }
}
