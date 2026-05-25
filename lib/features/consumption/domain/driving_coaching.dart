// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../data/obd2/trip_live_reading.dart';
import 'cold_start_baselines.dart';
import 'situation_classifier.dart';

/// Eco-driving coaching hint emitted from a live OBD2 reading (#2007).
///
/// Three conservative hints; everything else (silence) is the default
/// outcome of [coachingHint]. False suggestions are worse than missed
/// ones — the user is supposed to trust the chip when it shows.
enum DrivingCoachingHint {
  /// Engine is spinning much higher than needed for the cruising
  /// speed → next gear up would drop RPM into a more efficient range.
  shiftUp,

  /// Engine is bogging at very low RPM while the driver is asking for
  /// real torque — the car is in too high a gear under load.
  shiftDown,

  /// Throttle is wide open during an aggressive cruise / acceleration
  /// AND the live consumption band is already heavy. Backing off the
  /// pedal would cut burn rate without losing real progress.
  easePedal,
}

/// Speed-relative thresholds picked to keep [coachingHint] silent in
/// the vast majority of normal driving and only fire when the
/// reading is unambiguous. The numbers are conservative estimates
/// drawn from typical 4-cyl ICE behaviour; tighter per-vehicle
/// tuning can come later from the per-vehicle gear-ratio inference
/// (#1263) once that's wired into the live path.
@immutable
class DrivingCoachingThresholds {
  const DrivingCoachingThresholds({
    this.shiftUpRpm = 2800,
    this.shiftUpMaxThrottlePercent = 50,
    this.shiftUpMinSpeedKmh = 30,
    this.shiftDownRpm = 1300,
    this.shiftDownMinThrottlePercent = 55,
    this.easePedalThrottlePercent = 70,
    this.easePedalMinSpeedKmh = 40,
  });

  /// Above this RPM with moderate throttle and real cruising speed,
  /// the engine is sustaining a higher rotational rate than the
  /// powertrain needs — [DrivingCoachingHint.shiftUp].
  final double shiftUpRpm;

  /// Cap above which "shift up" is unsafe to suggest — the driver
  /// is actively asking for the engine to wind out (overtaking,
  /// merging). Anything above this means the high RPM is intentional.
  final double shiftUpMaxThrottlePercent;

  /// Below this speed, RPM is not a reliable gear-too-low signal
  /// (low-speed first-gear engine braking, traffic-light pull-away).
  final double shiftUpMinSpeedKmh;

  /// Below this RPM with the driver asking for torque, the engine is
  /// lugging — [DrivingCoachingHint.shiftDown].
  final double shiftDownRpm;

  /// Minimum throttle for "shift down" to fire. A low RPM with the
  /// pedal mostly off is just cruising / coasting — no coaching needed.
  final double shiftDownMinThrottlePercent;

  /// Above this throttle, the driver is asking for maximum burn.
  /// Combined with `hardAccel` and a heavy band, this is the prompt
  /// to back off — [DrivingCoachingHint.easePedal].
  final double easePedalThrottlePercent;

  /// Don't suggest easing the pedal under this speed — pull-away
  /// from a stop legitimately demands high throttle for a few seconds.
  final double easePedalMinSpeedKmh;
}

/// Classify a [TripLiveReading] into at most one [DrivingCoachingHint],
/// or `null` when nothing actionable is signalled.
///
/// Pure function — callable from any layer, no side effects, no
/// provider lookups. Easy to unit-test branch-by-branch.
///
/// Order of evaluation is deliberate: `easePedal` wins over `shiftUp`
/// when both could fire, because heavy-throttle aggressive accel is
/// the more user-visible waste signal (and the user can shift up
/// after easing off anyway).
DrivingCoachingHint? coachingHint(
  TripLiveReading reading, {
  DrivingSituation? situation,
  ConsumptionBand? band,
  DrivingCoachingThresholds thresholds = const DrivingCoachingThresholds(),
}) {
  final rpm = reading.rpm;
  final speed = reading.speedKmh;
  final throttle = reading.throttlePercent;

  // Hard-accel + wide-open throttle + heavy burn rate → ease off.
  if (throttle != null &&
      speed != null &&
      throttle >= thresholds.easePedalThrottlePercent &&
      speed >= thresholds.easePedalMinSpeedKmh &&
      situation == DrivingSituation.hardAccel &&
      (band == ConsumptionBand.heavy || band == ConsumptionBand.veryHeavy)) {
    return DrivingCoachingHint.easePedal;
  }

  // High RPM in cruise → shift up.
  if (rpm != null &&
      speed != null &&
      throttle != null &&
      rpm >= thresholds.shiftUpRpm &&
      speed >= thresholds.shiftUpMinSpeedKmh &&
      throttle < thresholds.shiftUpMaxThrottlePercent) {
    return DrivingCoachingHint.shiftUp;
  }

  // Low RPM under load → shift down.
  if (rpm != null &&
      throttle != null &&
      rpm < thresholds.shiftDownRpm &&
      throttle >= thresholds.shiftDownMinThrottlePercent) {
    return DrivingCoachingHint.shiftDown;
  }

  return null;
}

/// Format an instantaneous consumption number for the banner / PiP
/// tile (#2007). At a meaningful speed we surface L/100 km; near
/// standstill we fall back to L/h so the readout stays useful while
/// stopped in traffic.
///
/// Returns `null` when the OBD2 stream hasn't surfaced a fuel-rate
/// reading yet (the banner suppresses the value in that case rather
/// than rendering a placeholder).
String? formatInstantConsumption(TripLiveReading r) {
  final fuelRate = r.fuelRateLPerHour;
  if (fuelRate == null) return null;
  final speed = r.speedKmh ?? 0;
  // Below ~5 km/h the L/100 km figure explodes toward infinity and
  // stops being meaningful — fall back to the L/h value.
  if (speed < 5) {
    return '${fuelRate.toStringAsFixed(1)} L/h';
  }
  final lPer100 = fuelRate / speed * 100.0;
  return '${lPer100.toStringAsFixed(1)} L/100';
}
