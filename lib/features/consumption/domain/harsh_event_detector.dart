/// Counts harsh-braking / harsh-acceleration events from a stream of
/// speed samples, decoupled from the sample-feed cadence (#1922).
///
/// Extracted from [TripRecorder]: the recorder is fed a `TripSample`
/// every 250 ms, but the OBD speed PID (0x0D, integer km/h) refreshes
/// only ~1 Hz — so `speedKmh` arrives as a *staircase* of repeated
/// values. Differentiating that staircase over the 250 ms emit
/// interval divided a ~1 s speed delta by 0.25 s and inflated every
/// acceleration ~4x: a real device backup showed 428 "harsh brakes"
/// on a single 157 km motorway drive.
///
/// The fix is to re-sample speed at ~1 Hz before taking the
/// derivative: the threshold is evaluated only between samples at
/// least [_evalIntervalSec] apart, so Δt is always a real ~1 s window.
/// Genuine hard braking (a large Δspeed within ~1 s) still trips the
/// threshold; the staircase no longer does; and the count is
/// independent of how fast samples are fed.
class HarshEventDetector {
  HarshEventDetector({
    this.brakeThresholdMps2 = 3.5,
    this.accelThresholdMps2 = 3.0,
  });

  /// Deceleration magnitude (m/s², positive number) at or above which
  /// an interval counts as a harsh brake.
  final double brakeThresholdMps2;

  /// Acceleration (m/s²) at or above which an interval counts as a
  /// harsh acceleration.
  final double accelThresholdMps2;

  /// Minimum spacing (seconds) between two evaluated samples — this is
  /// what re-samples the speed signal at ~1 Hz. 0.9 rather than 1.0 so
  /// a nominally-1 Hz feed with minor jitter still evaluates every
  /// sample instead of skipping to a 2 s window.
  static const double _evalIntervalSec = 0.9;

  int _brakes = 0;
  int _accels = 0;

  // The last sample an evaluation was anchored on. Advances only when
  // an evaluation actually fires, so a burst of sub-second samples
  // cannot drag the anchor forward and starve the detector.
  double? _anchorSpeedKmh;
  DateTime? _anchorAt;

  /// Number of harsh-braking events counted so far.
  int get brakes => _brakes;

  /// Number of harsh-acceleration events counted so far.
  int get accelerations => _accels;

  /// Feed one speed sample. Safe to call at any cadence; samples
  /// closer together than [_evalIntervalSec] are folded into the next
  /// evaluated window rather than each producing a derivative.
  void onSample(double speedKmh, DateTime timestamp) {
    final anchorAt = _anchorAt;
    final anchorSpeed = _anchorSpeedKmh;
    if (anchorAt == null || anchorSpeed == null) {
      _anchorAt = timestamp;
      _anchorSpeedKmh = speedKmh;
      return;
    }
    final dt = timestamp.difference(anchorAt).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt < _evalIntervalSec) return;

    // Δspeed km/h → m/s by / 3.6, then / Δt for m/s².
    final accelMps2 = ((speedKmh - anchorSpeed) / 3.6) / dt;
    if (accelMps2 <= -brakeThresholdMps2) {
      _brakes++;
    } else if (accelMps2 >= accelThresholdMps2) {
      _accels++;
    }
    _anchorAt = timestamp;
    _anchorSpeedKmh = speedKmh;
  }

  /// Reset the counters and anchor — used before recording a fresh
  /// trip without discarding the detector instance.
  void reset() {
    _brakes = 0;
    _accels = 0;
    _anchorSpeedKmh = null;
    _anchorAt = null;
  }
}
