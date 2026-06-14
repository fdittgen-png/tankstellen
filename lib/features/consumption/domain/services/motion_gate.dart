// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The GPS request profile the recorder should use right now (#3319).
enum GpsProfile {
  /// Full-rate fixes (1 s / no distance filter) — the device is moving.
  fine,

  /// Coarse fixes (longer interval + distance filter) — the device has been
  /// stationary, so we back off the GPS receiver to save battery. A coarse
  /// stream still delivers the occasional fix, so resumed motion is detected
  /// and the profile snaps back to [fine] — no separate wake signal needed.
  coarse,
}

/// Pure stop-detection state machine that decides whether the recording GPS
/// stream should run [GpsProfile.fine] or [GpsProfile.coarse] (#3319).
///
/// Replicates the battery lesson of motion-gated trackers (full-rate GPS
/// while moving, backed off while parked) using ONLY signals the recorder
/// already has — per-fix GPS ground speed (both pipelines) and, when
/// available, the IMU horizontal-acceleration magnitude (GPS-only trips). No
/// activity-recognition dependency, no extra permission.
///
/// Deliberately time-injected (callers pass `elapsed`) and side-effect free
/// so the transitions are deterministically unit-testable. It never calls
/// `DateTime.now()` itself.
///
/// Transitions (hysteresis so a single stray fix never thrashes the GPS
/// receiver):
///   * a clearly-moving fix (speed >= [movingSpeedKmh], or an IMU magnitude
///     >= [imuMovingThreshold]) → [GpsProfile.fine] immediately;
///   * sustained slow-and-still — speed <= [stationarySpeedKmh] AND (no IMU,
///     or IMU < [imuStillThreshold]) — for at least [stationaryAfter] →
///     [GpsProfile.coarse];
///   * anything in between holds the current profile.
class MotionGate {
  MotionGate({
    this.stationarySpeedKmh = 3.0,
    this.movingSpeedKmh = 8.0,
    this.stationaryAfter = const Duration(seconds: 20),
    this.imuStillThreshold = 0.4,
    this.imuMovingThreshold = 1.5,
  });

  /// At or below this ground speed (km/h) a fix is a stationary candidate.
  final double stationarySpeedKmh;

  /// At or above this ground speed (km/h) the device is unambiguously moving.
  final double movingSpeedKmh;

  /// How long the device must stay slow-and-still before backing GPS off.
  final Duration stationaryAfter;

  /// Horizontal IMU acceleration magnitude (m/s²) below which the device is
  /// considered still. Ignored when no IMU sample is supplied.
  final double imuStillThreshold;

  /// Horizontal IMU acceleration magnitude (m/s²) at/above which the device
  /// is unambiguously moving (re-fines immediately, e.g. pulling away).
  final double imuMovingThreshold;

  GpsProfile _profile = GpsProfile.fine;
  Duration? _slowSince;

  /// The current GPS profile. Starts [GpsProfile.fine] so a trip records at
  /// full rate the moment it begins.
  GpsProfile get profile => _profile;

  /// Feed a recording fix. [speedKmh] is the per-fix ground speed;
  /// [imuMagnitude] is the optional horizontal IMU acceleration (m/s²),
  /// null when the trip has no IMU (OBD2/hybrid). [elapsed] is a monotonic
  /// time since recording start (any consistent clock). Returns the profile
  /// in effect after this fix.
  GpsProfile onFix({
    required double speedKmh,
    double? imuMagnitude,
    required Duration elapsed,
  }) {
    final imuMoving =
        imuMagnitude != null && imuMagnitude >= imuMovingThreshold;
    final imuStill = imuMagnitude == null || imuMagnitude < imuStillThreshold;

    if (speedKmh >= movingSpeedKmh || imuMoving) {
      // Unambiguously moving — fine, and reset the stillness timer.
      _slowSince = null;
      _profile = GpsProfile.fine;
      return _profile;
    }

    if (speedKmh <= stationarySpeedKmh && imuStill) {
      // Slow and still: arm / hold the stillness timer.
      _slowSince ??= elapsed;
      if (elapsed - _slowSince! >= stationaryAfter) {
        _profile = GpsProfile.coarse;
      }
      return _profile;
    }

    // Intermediate (rolling slowly, or IMU shows some motion): not a
    // stationary candidate, but not clearly moving either — break the
    // stillness timer and hold the current profile.
    _slowSince = null;
    return _profile;
  }

  /// Reset to the initial fine profile (e.g. on a new trip).
  void reset() {
    _profile = GpsProfile.fine;
    _slowSince = null;
  }
}
