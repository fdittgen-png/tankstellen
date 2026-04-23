import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/virtual_odometer.dart';

// Shared epoch for the virtual-odometer tests. Top-level so the
// linter doesn't flag it as a const-declarable local.
DateTime get _t0 => DateTime.utc(2026, 4, 22, 10);

void main() {
  group('VirtualOdometer (#800)', () {
    test('empty sample list returns 0 km', () {
      const odo = VirtualOdometer(samples: []);
      expect(odo.integrateKm(), 0.0);
    });

    test('single sample returns 0 km — no interval to integrate', () {
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 60),
      ]);
      expect(odo.integrateKm(), 0.0);
    });

    test(
        'two samples at constant 60 km/h over 60 s → 1.0 km (trapezoid '
        'collapses to rectangle when both endpoints share a value)', () {
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 60),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 60)), speedKmh: 60),
      ]);
      expect(odo.integrateKm(), closeTo(1.0, 0.001));
    });

    test(
        'linear ramp 0 → 60 km/h over 60 s → 0.5 km (average of the '
        'trapezoid is 30 km/h over 1 minute)', () {
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 0),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 60)), speedKmh: 60),
      ]);
      expect(odo.integrateKm(), closeTo(0.5, 0.001));
    });

    test(
        'multi-segment ramp up + cruise + ramp down reproduces the '
        'hand-computed ground truth', () {
      // Segment 1: 0→60 km/h over 30 s → 0.25 km
      // Segment 2: 60 km/h for 300 s → 5.0 km
      // Segment 3: 60→0 km/h over 20 s → 0.1667 km
      // Total: ~5.4167 km.
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 0),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 30)), speedKmh: 60),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 330)), speedKmh: 60),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 350)), speedKmh: 0),
      ]);
      expect(odo.integrateKm(), closeTo(5.4167, 0.01));
    });

    test(
        'non-monotonic timestamps: the offending pair is skipped but '
        'subsequent valid pairs still contribute', () {
      // _t0    @ 60 km/h   — no interval with previous (first sample)
      // _t0+10 @ 60 km/h  → contributes 60 × 10 / 3600 ≈ 0.1667 km
      // _t0+5  @ 60 km/h  → Δt = −5 s → skipped
      // _t0+70 @ 60 km/h  → integrates against the skipped sample's
      //   carry-forward (prev = _t0+5): Δt = 65 s → 60 × 65 / 3600 ≈
      //   1.0833 km.
      // The contract is "skip the bad pair, keep walking" — losing
      // 5 s of distance is cheaper than discarding the late tick.
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 60),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 10)), speedKmh: 60),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 5)), speedKmh: 60),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 70)), speedKmh: 60),
      ]);
      expect(odo.integrateKm(), closeTo(1.25, 0.01));
    });

    test('duplicate timestamps are skipped without polluting the total',
        () {
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 60),
        VirtualOdometerSample(timestamp: _t0, speedKmh: 60), // Δt = 0
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 60)), speedKmh: 60),
      ]);
      // The Δt = 0 pair contributes 0, and the _t0 → _t0+60 pair is
      // reached via the skipped sample's carry-forward → effectively
      // 60 s at 60 km/h = 1.0 km.
      expect(odo.integrateKm(), closeTo(1.0, 0.01));
    });

    test(
        'negative speed values are clamped to 0 (defensive against '
        'transport wraparound artefacts on reconnect)', () {
      // 0 → −5 km/h over 60 s. With clamping, average = 0 → 0 km.
      // Without clamping (legacy bug), average = −2.5 → −0.0417 km.
      final odo = VirtualOdometer(samples: [
        VirtualOdometerSample(timestamp: _t0, speedKmh: 0),
        VirtualOdometerSample(
            timestamp: _t0.add(const Duration(seconds: 60)), speedKmh: -5),
      ]);
      expect(odo.integrateKm(), closeTo(0.0, 0.001));
    });
  });
}
