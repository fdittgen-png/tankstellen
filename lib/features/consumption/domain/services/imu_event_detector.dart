// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../../../core/sensors/imu_sample.dart';
import '../accel_event_gate.dart';
import '../gps_driving_features.dart'
    show kSharpCornerThresholdMps2, kSharpCornerYawRateRadPerSec;
import '../harsh_event.dart';

/// Pure, plugin-free harsh-accel / harsh-brake / sharp-corner detector for
/// the dongle-optional GPS+IMU pipeline (#2760).
///
/// ## What it is
///
/// Fed one [ImuSample] at a time (~50 Hz) via [onSample], plus the live GPS
/// ground speed via [currentSpeedKmh], it folds the inertial signal into a
/// handful of in-memory integer counters: [hardAccelCount], [hardBrakeCount],
/// [sharpCornerCount]. It NEVER retains the samples — the binding
/// aggregate-only constraint (#2760). On trip stop the pipeline reads the
/// three counters and drops the detector.
///
/// ## Why it mirrors `accel_event_gate.dart`
///
/// The accel/brake event semantics are deliberately identical to the
/// canonical [countAccelEvents] gate the GPS-speed path uses: the SAME
/// thresholds ([kHardAccelThresholdMps2] = 3.0, [kHardBrakeThresholdMps2] =
/// 3.5), the SAME sustained-window floor ([kAccelEventMinSustainedSec] =
/// 1.0 s), the SAME min-speed gate ([kAccelEventMinSpeedKmh] = 5 km/h), and
/// the SAME one-event-per-*episode* latch/re-arm — a 4-second hard brake is
/// ONE brake, not 80 samples. The only difference is the *source* of the
/// acceleration: a direct inertial reading rather than the noisy
/// speed-derivative, which is more accurate and is why the dongle becomes
/// optional.
///
/// ## Accel vs brake direction
///
/// The accelerometer is orientation-agnostic, so the detector uses the
/// horizontal linear-accel magnitude `sqrt(ax² + ay²)` as the manoeuvre
/// strength and the *sign of the GPS-speed change* to classify it: a
/// strong horizontal acceleration while ground speed is rising is a hard
/// accel; while falling, a hard brake. A near-constant speed with a strong
/// horizontal accel and a high yaw rate is a corner instead.
///
/// ## Cornering
///
/// A sharp corner needs all three: the lateral (horizontal) accel ≥
/// [kSharpCornerThresholdMps2] (3.5 m/s²), the gyroscope yaw rate |gyroZ| ≥
/// [kSharpCornerYawRateRadPerSec] (0.30 rad/s), AND a roughly constant GPS
/// speed (so a hard brake into a bend is counted as a brake, not a corner),
/// sustained ≥ [_cornerMinSustainedSec] (2.0 s). The yaw-rate gate is what
/// keeps a straight-line bump or a longitudinal jolt from registering as a
/// corner.
class ImuEventDetector {
  ImuEventDetector({this.onEvent});

  /// Optional live callback, fired the instant a confirmed accel/brake
  /// episode is detected — matches [HarshEventDetector.onEvent] so the
  /// GPS+IMU pipeline can feed the SAME `LiveHarshEventBus` the OBD2 /
  /// GPS-speed paths use, and dongle-less spoken coaching fires (#2760).
  /// Corners are not [HarshEvent]s (no type), so they do not fire it.
  void Function(HarshEvent event)? onEvent;

  /// The latest GPS ground speed (km/h), fed by the pipeline from each GPS
  /// fix. Drives the min-speed gate and the accel-vs-brake direction. A
  /// near-standstill (< [kAccelEventMinSpeedKmh]) suppresses scoring so
  /// parked-phone jitter manufactures nothing.
  double currentSpeedKmh = 0;

  /// Confirmed hard-acceleration episodes so far.
  int get hardAccelCount => _hardAccelCount;

  /// Confirmed hard-braking episodes so far.
  int get hardBrakeCount => _hardBrakeCount;

  /// Confirmed sharp-cornering episodes so far.
  int get sharpCornerCount => _sharpCornerCount;

  /// Whether the inertial sensor actually ran for this trip (#2895). True
  /// once at least one real sample has been folded in (i.e. past the seed),
  /// false when the device has no accelerometer/gyroscope or the platform
  /// plugin never bound (a quiet stream that never emits). Lets the pipeline
  /// distinguish a genuine IMU zero ("you drove smoothly") from
  /// "no IMU signal" — so an IMU count of 0 can VETO a noisy GPS-derived
  /// over-count rather than being indistinguishable from "no reading".
  bool get isActive => _sampleCount > 1;

  int _hardAccelCount = 0;
  int _hardBrakeCount = 0;
  int _sharpCornerCount = 0;

  /// Total samples handed to [onSample]. The first only seeds the dt anchor;
  /// `isActive` therefore requires > 1 so a single stray emit doesn't claim
  /// the sensor produced a usable signal.
  int _sampleCount = 0;

  /// Lateral (horizontal) accel must hold above 3.5 m/s² and the yaw rate
  /// above 0.30 rad/s for at least this long before a corner is confirmed —
  /// longer than the 1 s accel/brake floor because a bend is a slower,
  /// sustained manoeuvre and we want to reject transient jolts.
  static const double _cornerMinSustainedSec = 2.0;

  /// Speed change (km/h) between consecutive samples below which the speed is
  /// treated as "roughly constant" for the corner gate. Sampled per ~20 ms
  /// step; a real accel/brake moves speed far faster than this per step.
  static const double _constantSpeedDeltaKmh = 0.15;

  // Episode-latch state, mirroring `countAccelEvents`: accumulate the
  // sustained time above each threshold, count once on first crossing the
  // sustained floor, and re-arm only once the signal has stayed below the
  // threshold for a continuous refractory window (#2846) — so one
  // manoeuvre's transient dips can't fire a second event. `_*BelowDur`
  // tracks the continuous sub-threshold time while latched.
  double _maneuverDur = 0;
  double _cornerDur = 0;
  double _accelBelowDur = 0;
  double _brakeBelowDur = 0;
  bool _inAccel = false;
  bool _inBrake = false;
  bool _inCorner = false;

  DateTime? _lastT;

  /// GPS speed (km/h) captured at the instant a strong-longitudinal stretch
  /// began. Because GPS refreshes ~1 Hz while the IMU runs ~50 Hz, the
  /// per-sample speed delta is usually 0 — so accel-vs-brake direction is
  /// decided by the NET speed change since the manoeuvre started, not the
  /// (near-zero) sample-to-sample delta.
  double _maneuverStartSpeedKmh = 0;

  /// Fold one inertial sample into the counters. Pure: no I/O, no
  /// persistence, O(1) work and O(1) memory regardless of trip length.
  void onSample(ImuSample s) {
    final lastT = _lastT;
    final speedKmh = currentSpeedKmh;
    _lastT = s.t;
    _sampleCount++;
    if (lastT == null) return; // first sample seeds the dt anchor only.

    final dt = s.t.difference(lastT).inMicroseconds /
        Duration.microsecondsPerSecond;
    // A non-positive dt (duplicate / out-of-order) or a long gap (a sensor
    // dropout / paused trip) breaks every running episode so no integral
    // spans it — the same guard the speed-derivative gate uses.
    if (dt <= 0 || dt > kAccelEventMaxGapSec) {
      _breakEpisodes();
      return;
    }

    // Min-speed floor: a near-standstill is not a real manoeuvre. Parked /
    // walking-pace jitter is dropped and resets the latches.
    if (speedKmh < kAccelEventMinSpeedKmh) {
      _breakEpisodes();
      return;
    }

    // Horizontal linear-accel magnitude — orientation-agnostic manoeuvre
    // strength. The vertical (Z) axis is dropped so road bumps don't inflate
    // it. Gravity is already removed upstream (userAccelerometer), so a
    // steady cruise reads ~0. We use the same magnitude for the longitudinal
    // (accel/brake) gate and the lateral (corner) gate; the yaw rate + net
    // speed change disambiguate which manoeuvre it is.
    final horizMag = math.sqrt(s.axMps2 * s.axMps2 + s.ayMps2 * s.ayMps2);
    final yawRate = s.gyroZRadPerSec.abs();
    final highYaw = yawRate >= kSharpCornerYawRateRadPerSec;

    // A strong horizontal stretch is "in progress" while the magnitude holds
    // at/above the accel threshold (3.0). Capture the GPS speed at its start
    // so accel-vs-brake direction is decided by the NET speed change over the
    // stretch (robust to the ~1 Hz GPS vs ~50 Hz IMU rate mismatch).
    final strong = horizMag >= kHardAccelThresholdMps2;
    if (strong) {
      if (_maneuverDur == 0) _maneuverStartSpeedKmh = speedKmh;
      _maneuverDur += dt;
    } else {
      _maneuverDur = 0;
    }
    final netSpeedDeltaKmh = speedKmh - _maneuverStartSpeedKmh;
    final constantSpeed = netSpeedDeltaKmh.abs() <= _constantSpeedDeltaKmh;

    _scoreCorner(
      dt: dt,
      horizMag: horizMag,
      highYaw: highYaw,
      constantSpeed: constantSpeed,
      t: s.t,
      speedKmh: speedKmh,
    );
    _scoreAccelBrake(
      dt: dt,
      horizMag: horizMag,
      highYaw: highYaw,
      constantSpeed: constantSpeed,
      netSpeedDeltaKmh: netSpeedDeltaKmh,
      speedKmh: speedKmh,
      t: s.t,
    );
  }

  void _scoreCorner({
    required double dt,
    required double horizMag,
    required bool highYaw,
    required bool constantSpeed,
    required DateTime t,
    required double speedKmh,
  }) {
    // A corner is a sustained lateral load: the (centripetal) horizontal
    // accel ≥ 3.5 m/s², the yaw rate above the gate, and a ~constant speed
    // (a hard brake INTO a bend is a brake, not a corner). The lateral floor
    // here is the harsher 3.5, matching the GPS corner threshold.
    final isCorner =
        horizMag >= kSharpCornerThresholdMps2 && highYaw && constantSpeed;
    if (isCorner) {
      _cornerDur += dt;
      if (!_inCorner && _cornerDur >= _cornerMinSustainedSec) {
        _sharpCornerCount++;
        _inCorner = true;
        // #3504 — the confirmed corner reaches the live bus too, so the
        // voice coach can cue cornering (brakes/accels already did).
        _emit(HarshEventType.corner, horizMag, t, speedKmh);
      }
    } else {
      _cornerDur = 0;
      _inCorner = false;
    }
  }

  void _scoreAccelBrake({
    required double dt,
    required double horizMag,
    required bool highYaw,
    required bool constantSpeed,
    required double netSpeedDeltaKmh,
    required double speedKmh,
    required DateTime t,
  }) {
    // A high-yaw, constant-speed manoeuvre is cornering geometry: the
    // horizontal accel is centripetal (lateral), not a longitudinal
    // accel/brake — so don't score it as one. When speed IS changing through
    // a bend, the net-speed classification below correctly takes over.
    // Treat the cornering interval as below-threshold for the refractory
    // accumulators so it counts toward re-arming rather than re-arming
    // instantly (#2846).
    if (highYaw && constantSpeed) {
      _decayAccelLatch(dt);
      _decayBrakeLatch(dt);
      return;
    }

    // The manoeuvre confirms once the strong-magnitude stretch has held for
    // the sustained floor. Direction is the sign of the net GPS-speed change
    // over the stretch: rising → hard accel, falling → hard brake. A purely
    // lateral jolt with no net speed change and no yaw is ignored.
    final confirmed = _maneuverDur >= kAccelEventMinSustainedSec;

    // Hard accel: the strong stretch (≥ 3.0 m/s²) held while speed rose.
    final isAccel = confirmed &&
        horizMag >= kHardAccelThresholdMps2 &&
        netSpeedDeltaKmh > _constantSpeedDeltaKmh;
    if (isAccel) {
      _accelBelowDur = 0;
      if (!_inAccel) {
        _hardAccelCount++;
        _inAccel = true;
        _emit(HarshEventType.acceleration, horizMag, t, speedKmh);
      }
    } else {
      _decayAccelLatch(dt);
    }

    // Hard brake: held while speed FELL, with the harder 3.5 m/s² magnitude
    // floor (the telematics convention — brake harder to trip than accel,
    // shared with the speed-derivative gate's kHardBrakeThresholdMps2).
    final isBrake = confirmed &&
        horizMag >= kHardBrakeThresholdMps2 &&
        netSpeedDeltaKmh < -_constantSpeedDeltaKmh;
    if (isBrake) {
      _brakeBelowDur = 0;
      if (!_inBrake) {
        _hardBrakeCount++;
        _inBrake = true;
        _emit(HarshEventType.brake, horizMag, t, speedKmh);
      }
    } else {
      _decayBrakeLatch(dt);
    }
  }

  /// Re-arm the accel latch only once the signal has stayed below the
  /// threshold for a continuous [kAccelEventRefractorySec] window (#2846),
  /// so one manoeuvre's transient dips don't fire a second event.
  void _decayAccelLatch(double dt) {
    if (!_inAccel) return;
    _accelBelowDur += dt;
    if (_accelBelowDur >= kAccelEventRefractorySec) {
      _inAccel = false;
      _accelBelowDur = 0;
    }
  }

  void _decayBrakeLatch(double dt) {
    if (!_inBrake) return;
    _brakeBelowDur += dt;
    if (_brakeBelowDur >= kAccelEventRefractorySec) {
      _inBrake = false;
      _brakeBelowDur = 0;
    }
  }

  void _emit(
    HarshEventType type,
    double magMps2,
    DateTime t,
    double speedKmh,
  ) {
    onEvent?.call(HarshEvent(
      timestamp: t,
      magnitudeG: magMps2 / standardGravityMps2,
      speedKmh: speedKmh,
      type: type,
    ));
  }

  void _breakEpisodes() {
    _maneuverDur = 0;
    _cornerDur = 0;
    _accelBelowDur = 0;
    _brakeBelowDur = 0;
    _inAccel = false;
    _inBrake = false;
    _inCorner = false;
  }
}
