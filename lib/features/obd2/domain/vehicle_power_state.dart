// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

/// The car's electrical state as far as the OBD2 link can tell (#3856,
/// Epic #3855).
///
/// The link reliability work (#3527 / #3775) made the *link* trustworthy;
/// what remained was that the app treated the car's power state as noise.
/// An engine that is off was indistinguishable, in most of the pipeline,
/// from a link that is broken — and every "broken link" path then did
/// exactly the wrong thing for a parked car (dial storms, "connection
/// dropped" verdicts, a Reset button). This enum names the states every
/// consumer keys on instead.
enum VehiclePowerState {
  /// No fresh evidence either way. Every consumer behaves exactly as it
  /// did before #3855 in this state — it is the reliability floor.
  unknown,

  /// Ignition off: the ECU is silent (or the adapter is asleep). The one
  /// state in which retrying costs battery and buys nothing.
  asleep,

  /// Ignition on, engine off: the ECU answers, rpm reads 0. Also the
  /// stop-start pause at a traffic light. Data flows; nothing is wrong.
  ecuAwake,

  /// The engine is turning (rpm > 0) or the alternator is charging.
  /// EVs / hybrids in READY map here too (their DC-DC converter lifts
  /// the 12 V bus the same way an alternator does).
  engineRunning,
}

/// Which measurement produced a stamp — kept on the fused snapshot so a
/// breadcrumb / export can say WHY the state is what it is.
enum VehiclePowerSource { rpm, voltage, busProbe, aclHint, motion }

/// Fused power-state evidence with per-source freshness (#3856).
///
/// Evidence ladder, highest wins:
///  1. **rpm PID** — authoritative. `> 0` running, `== 0` awake.
///  2. **`ATRV` battery voltage** (#3857) — the adapter measures it
///     itself, so it needs no vehicle-bus traffic and works while the ECU
///     is silent, mid protocol-search and through the UNABLE-TO-CONNECT
///     livelock (#3575). Alternator ≥ [alternatorOnV] = running, with
///     hysteresis: it must fall below [alternatorOffV] to count as off.
///  3. **Bus probe** — `answered` proves at least an awake ECU; `silent`
///     is `asleep` ONLY when the voltage agrees. Silent bus + alternator
///     voltage is the K-line livelock with the engine running (#3780),
///     never a parked car.
///  4. **BT-ACL engine-start hint** (#3699) — ignition just happened;
///     exposed as [engineStartExpected] rather than as a state, because a
///     phone linking to the car's audio is a strong hint, not a reading.
///  5. **GPS motion** — moving with no engine evidence is a tow (#3599),
///     never "connect harder"; exposed as [movingWithoutEngine].
///
/// Pure state — no timers, no I/O; the caller supplies the clock.
/// Process-wide [instance] for production wiring, injectable instances
/// for tests (the [Obd2EngineEvidence] convention).
class Obd2VehiclePower {
  Obd2VehiclePower({
    DateTime Function()? now,
    this.alternatorOnV = 13.2,
    this.alternatorOffV = 12.8,
    this.rpmWindow = const Duration(seconds: 20),
    this.voltageWindow = const Duration(seconds: 30),
    this.busWindow = const Duration(seconds: 30),
    this.aclHintWindow = const Duration(minutes: 2),
    this.motionWindow = const Duration(seconds: 30),
  }) : _now = now ?? DateTime.now;

  /// Process-wide default instance (production wiring).
  static final Obd2VehiclePower instance = Obd2VehiclePower();

  /// Alternator thresholds. A healthy 12 V lead-acid system reads
  /// ~12.2–12.7 V at rest and 13.5–14.5 V with the alternator charging;
  /// 13.2 / 12.8 sit in the gap on either side so a tired battery or a
  /// long crank cannot flap the verdict.
  final double alternatorOnV;
  final double alternatorOffV;

  final Duration rpmWindow;
  final Duration voltageWindow;
  final Duration busWindow;
  final Duration aclHintWindow;
  final Duration motionWindow;

  final DateTime Function() _now;

  DateTime? _rpmRunningAt;
  DateTime? _rpmZeroAt;
  DateTime? _voltageAt;
  double? _lastVoltageV;
  bool _alternatorOn = false;
  DateTime? _busAnsweredAt;
  DateTime? _busSilentAt;
  DateTime? _aclHintAt;
  DateTime? _motionAt;
  bool _evMode = false;

  final StreamController<VehiclePowerState> _states =
      StreamController<VehiclePowerState>.broadcast();
  VehiclePowerState _lastEmitted = VehiclePowerState.unknown;

  /// State transitions (only on change), for UI providers and the
  /// recording layer's engine-transition triggers.
  Stream<VehiclePowerState> get states => _states.stream;

  /// EVs / hybrids: rpm is meaningless, READY lifts the 12 V bus. Set by
  /// the recording layer from the active vehicle's type.
  bool get evMode => _evMode;
  set evMode(bool value) {
    _evMode = value;
    _emitIfChanged();
  }

  /// Most recent battery voltage read (any source), null before the
  /// first one.
  double? get lastVoltageV => _lastVoltageV;

  /// Alternator verdict with hysteresis, as of the last voltage read.
  bool get alternatorOn => _alternatorOn;

  // ---------------------------------------------------------------------
  // Stamps — each is one measurement from one source.
  // ---------------------------------------------------------------------

  /// An rpm PID parsed: `> 0` = the engine is literally turning; `0` =
  /// the ECU is awake with the engine off.
  void noteRpm(double rpm) {
    if (rpm > 0) {
      _rpmRunningAt = _now();
    } else {
      _rpmZeroAt = _now();
    }
    _busAnsweredAt = _now();
    _emitIfChanged();
  }

  /// An `ATRV` reply parsed (#3857). Applies the alternator hysteresis.
  void noteVoltage(double volts) {
    _lastVoltageV = volts;
    _voltageAt = _now();
    if (volts >= alternatorOnV) {
      _alternatorOn = true;
    } else if (volts < alternatorOffV) {
      _alternatorOn = false;
    }
    _emitIfChanged();
  }

  /// Any parsed OBD reply (speed, coolant, a real `41 00` bitmap …) —
  /// proof the ECU is awake, nothing more.
  void noteBusAnswered() {
    _busAnsweredAt = _now();
    _emitIfChanged();
  }

  /// The bus probe stayed silent through its window
  /// (`Obd2BusProbeResult.probedSilent`).
  void noteBusSilent() {
    _busSilentAt = _now();
    _emitIfChanged();
  }

  /// A BT-ACL engine-start hint arrived (#3699).
  void noteAclHint() {
    _aclHintAt = _now();
    _emitIfChanged();
  }

  /// Sustained GPS movement observed (the #3570 nudge's threshold).
  void noteMotion() {
    _motionAt = _now();
    _emitIfChanged();
  }

  // ---------------------------------------------------------------------
  // Fused verdicts.
  // ---------------------------------------------------------------------

  bool _fresh(DateTime? at, Duration window) =>
      at != null && _now().difference(at) < window;

  /// The fused state, evaluated now.
  VehiclePowerState get state {
    final rpmRunning = !_evMode && _fresh(_rpmRunningAt, rpmWindow);
    final rpmZero = !_evMode && _fresh(_rpmZeroAt, rpmWindow);
    final voltageFresh = _fresh(_voltageAt, voltageWindow);
    final busAnswered = _fresh(_busAnsweredAt, busWindow);
    final busSilent = _fresh(_busSilentAt, busWindow);

    if (rpmRunning) return VehiclePowerState.engineRunning;
    if (voltageFresh && _alternatorOn) return VehiclePowerState.engineRunning;
    if (_evMode && busAnswered && _fresh(_motionAt, motionWindow)) {
      // An EV in READY that is moving: the closest thing to "running".
      return VehiclePowerState.engineRunning;
    }
    if (rpmZero) return VehiclePowerState.ecuAwake;
    if (busAnswered) return VehiclePowerState.ecuAwake;
    if (busSilent && (!voltageFresh || !_alternatorOn)) {
      return VehiclePowerState.asleep;
    }
    if (voltageFresh && !_alternatorOn && !busAnswered) {
      // Low voltage and nothing from the bus: a parked car whose adapter
      // still answers AT commands.
      return VehiclePowerState.asleep;
    }
    return VehiclePowerState.unknown;
  }

  /// The source that decided [state] — for breadcrumbs.
  VehiclePowerSource? get decidingSource {
    if (!_evMode && _fresh(_rpmRunningAt, rpmWindow)) return VehiclePowerSource.rpm;
    if (_fresh(_voltageAt, voltageWindow) && _alternatorOn) {
      return VehiclePowerSource.voltage;
    }
    if (!_evMode && _fresh(_rpmZeroAt, rpmWindow)) return VehiclePowerSource.rpm;
    if (_fresh(_busAnsweredAt, busWindow)) return VehiclePowerSource.busProbe;
    if (_fresh(_busSilentAt, busWindow)) return VehiclePowerSource.busProbe;
    if (_fresh(_voltageAt, voltageWindow)) return VehiclePowerSource.voltage;
    return null;
  }

  /// True while the engine is demonstrably running — the ONLY condition
  /// under which a retry-with-reset is worth its cost (#3860).
  bool get engineRunning => state == VehiclePowerState.engineRunning;

  /// True while the car is asleep: zero dials, zero `0100`s (#3858/#3859).
  bool get asleep => state == VehiclePowerState.asleep;

  /// An engine start is expected within seconds (BT-ACL hint, #3699) and
  /// no reading has contradicted it yet. Lets the start path prepare
  /// (hold the link, arm the protocol establishment) without dialing on
  /// a hunch.
  bool get engineStartExpected =>
      _fresh(_aclHintAt, aclHintWindow) && state != VehiclePowerState.asleep;

  /// Moving with no engine evidence at all (#3599 transport shape).
  bool get movingWithoutEngine =>
      _fresh(_motionAt, motionWindow) &&
      state != VehiclePowerState.engineRunning &&
      !_evMode;

  /// One-line diagnostic payload for breadcrumbs / exports.
  String get detail {
    final v = _lastVoltageV;
    return '${state.name}'
        '${decidingSource == null ? '' : ' via ${decidingSource!.name}'}'
        '${v == null ? '' : ' ${v.toStringAsFixed(1)}V'}'
        '${_evMode ? ' ev' : ''}';
  }

  void _emitIfChanged() {
    final next = state;
    if (next == _lastEmitted) return;
    _lastEmitted = next;
    if (!_states.isClosed) _states.add(next);
  }

  /// Re-evaluate against the clock (freshness windows expire silently;
  /// a periodic caller — the recording tick — uses this to publish the
  /// decay of evidence into `unknown` / `asleep`).
  void tick() => _emitIfChanged();

  /// Test hygiene — clear every stamp between cases.
  @visibleForTesting
  void reset() {
    _rpmRunningAt = null;
    _rpmZeroAt = null;
    _voltageAt = null;
    _lastVoltageV = null;
    _alternatorOn = false;
    _busAnsweredAt = null;
    _busSilentAt = null;
    _aclHintAt = null;
    _motionAt = null;
    _evMode = false;
    _lastEmitted = VehiclePowerState.unknown;
  }
}
