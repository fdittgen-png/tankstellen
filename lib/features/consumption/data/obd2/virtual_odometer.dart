import 'package:flutter/foundation.dart';

/// One vehicle-speed observation captured during trip recording.
///
/// Paired timestamp + km/h is enough for the trapezoidal integrator
/// in [VirtualOdometer] to reconstruct distance travelled — no
/// odometer PID required.
@immutable
class VirtualOdometerSample {
  /// Wall-clock timestamp of the sample. The integrator uses
  /// `difference` between adjacent samples, so the absolute epoch
  /// doesn't matter — only the monotonic delta.
  final DateTime timestamp;

  /// Vehicle speed at [timestamp] in km/h. Must be ≥ 0; negative
  /// speeds are clamped to 0 by [VirtualOdometer.integrateKm].
  final double speedKmh;

  const VirtualOdometerSample({
    required this.timestamp,
    required this.speedKmh,
  });
}

/// Integrates a stream of `(timestamp, speedKmh)` samples into a
/// km-distance estimate (#800 Peugeot 107 path).
///
/// The car exposes Mode 01 PID 0D (vehicle speed) but not Mode 01 PID
/// A6 (odometer) or Mode 09 PID 02 (VIN's odometer). Without a real
/// odometer to bracket the trip, we reconstruct distance by
/// trapezoidal integration of speed × dt.
///
/// Typical error is ~1–3 % against a GPS ground truth — dominated by
/// speed-sensor quantisation (the car rounds to 1 km/h increments)
/// and the gaps between polling ticks. Still infinitely better than
/// the `—` the trip summary was showing on these cars.
class VirtualOdometer {
  /// Samples in chronological order. The integrator expects
  /// monotonically-increasing timestamps; out-of-order pairs are
  /// skipped in [integrateKm] to keep one late-arriving tick from
  /// poisoning the total.
  final List<VirtualOdometerSample> samples;

  const VirtualOdometer({required this.samples});

  /// Trapezoidal integration of speed × dt over the captured
  /// [samples]. For each adjacent pair `(t_i, v_i)`, `(t_{i+1},
  /// v_{i+1})` we add `((v_i + v_{i+1}) / 2) × (Δt_seconds / 3600)`
  /// kilometres to the running total. Speeds are clamped to ≥ 0 to
  /// guard against the occasional wraparound / negative artifact
  /// some transports produce on reconnect.
  ///
  /// Behaviour at edges:
  ///   - 0 or 1 samples → 0.0 (no intervals to integrate).
  ///   - Non-monotonic timestamps (Δt ≤ 0) → the offending pair is
  ///     skipped; the next valid pair picks up from the later
  ///     timestamp. Rationale: the BT transport occasionally delivers
  ///     a buffered tick out of order, and dropping the bad pair is
  ///     less damaging than negating a chunk of real distance.
  ///   - Samples with the same timestamp → skipped as above.
  double integrateKm() {
    if (samples.length < 2) return 0.0;
    var distanceKm = 0.0;
    for (var i = 1; i < samples.length; i++) {
      final prev = samples[i - 1];
      final curr = samples[i];
      final dtSeconds = curr.timestamp.difference(prev.timestamp).inMicroseconds
          / Duration.microsecondsPerSecond;
      if (dtSeconds <= 0) continue; // skip non-monotonic pair
      final v1 = prev.speedKmh < 0 ? 0.0 : prev.speedKmh;
      final v2 = curr.speedKmh < 0 ? 0.0 : curr.speedKmh;
      final avgKmh = (v1 + v2) / 2.0;
      distanceKm += avgKmh * dtSeconds / 3600.0;
    }
    return distanceKm;
  }
}
