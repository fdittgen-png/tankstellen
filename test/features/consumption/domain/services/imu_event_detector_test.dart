// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sensors/imu_sample.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event.dart';
import 'package:tankstellen/features/consumption/domain/services/imu_event_detector.dart';

/// Reuse-fidelity tests for the pure [ImuEventDetector] (#2760). No
/// request-echoing fake: we replay a fixed synthetic [ImuSample] stream at a
/// 50 ms cadence and assert the in-memory episode counters — proving the
/// debounce (one event per sustained episode, NOT one per sample) the
/// aggregate-only design depends on.
void main() {
  const cadence = Duration(milliseconds: 50);
  final t0 = DateTime(2026, 6, 1, 8);

  /// Feed [det] a burst: [count] samples 50 ms apart starting at [start],
  /// each carrying horizontal accel magnitude [mag] (on the X axis) and yaw
  /// [yaw], with the GPS speed stepped by [speedStepKmh] per sample from
  /// [startSpeedKmh]. Returns the timestamp just after the last sample.
  DateTime feed(
    ImuEventDetector det, {
    required DateTime start,
    required int count,
    required double mag,
    double yaw = 0.0,
    required double startSpeedKmh,
    double speedStepKmh = 0.0,
  }) {
    var t = start;
    var speed = startSpeedKmh;
    for (var i = 0; i < count; i++) {
      det.currentSpeedKmh = speed;
      det.onSample(ImuSample(
        t: t,
        axMps2: mag,
        ayMps2: 0,
        azMps2: 0,
        gyroZRadPerSec: yaw,
      ));
      t = t.add(cadence);
      speed += speedStepKmh;
    }
    return t;
  }

  test('a sustained 1.5 s 4.0 m/s² burst with speed rising → ONE hard accel '
      '(episode debounce, not 30)', () {
    final det = ImuEventDetector();
    // 1.5 s at 50 ms = 30 samples. Speed climbs so the direction is "accel".
    feed(det,
        start: t0,
        count: 30,
        mag: 4.0,
        startSpeedKmh: 30,
        speedStepKmh: 0.5);
    expect(det.hardAccelCount, 1,
        reason: 'one sustained episode counts once, not per-sample');
    expect(det.hardBrakeCount, 0);
    expect(det.sharpCornerCount, 0);
  });

  test('a 4 s 4.0 m/s² burst with speed falling → ONE hard brake', () {
    final det = ImuEventDetector();
    // 4 s = 80 samples; speed falls so the direction is "brake".
    feed(det,
        start: t0,
        count: 80,
        mag: 4.0,
        startSpeedKmh: 100,
        speedStepKmh: -0.5);
    expect(det.hardBrakeCount, 1);
    expect(det.hardAccelCount, 0);
  });

  test('a 2.5 s lateral 4.0 m/s² + yaw 0.4 rad/s at ~constant speed → ONE '
      'sharp corner', () {
    final det = ImuEventDetector();
    // Constant speed (step 0) so the corner gate's constant-speed clause
    // holds; yaw above the 0.30 gate; 2.5 s > the 2.0 s sustained floor.
    feed(det,
        start: t0,
        count: 50,
        mag: 4.0,
        yaw: 0.4,
        startSpeedKmh: 60,
        speedStepKmh: 0.0);
    expect(det.sharpCornerCount, 1);
    expect(det.hardAccelCount, 0,
        reason: 'a constant-speed high-yaw bend is a corner, not an accel');
    expect(det.hardBrakeCount, 0);
  });

  test('a 0.5 s 4.0 m/s² spike → ZERO (below the 1 s sustained floor)', () {
    final det = ImuEventDetector();
    // 0.5 s = 10 samples — under the 1.0 s accel/brake floor.
    feed(det,
        start: t0,
        count: 10,
        mag: 4.0,
        startSpeedKmh: 50,
        speedStepKmh: 0.5);
    expect(det.hardAccelCount, 0);
    expect(det.hardBrakeCount, 0);
  });

  test('standstill (speed < 5 km/h) jitter → ZERO (min-speed gate)', () {
    final det = ImuEventDetector();
    // A long, strong inertial burst but at a near-standstill — the parked /
    // walking-pace gate must drop every sample.
    feed(det,
        start: t0,
        count: 80,
        mag: 5.0,
        yaw: 0.5,
        startSpeedKmh: 2.0,
        speedStepKmh: 0.0);
    expect(det.hardAccelCount, 0);
    expect(det.hardBrakeCount, 0);
    expect(det.sharpCornerCount, 0);
  });

  test('two separate 1.5 s accel bursts with a calm gap → TWO '
      '(re-arm past the refractory window)', () {
    final det = ImuEventDetector();
    var t = feed(det,
        start: t0,
        count: 30,
        mag: 4.0,
        startSpeedKmh: 30,
        speedStepKmh: 0.5);
    // A calm gap LONGER than the kAccelEventRefractorySec refractory window
    // (#2846) re-arms the latch — 60 samples × 50 ms = 3 s of below-threshold
    // cruise, the multi-second plateau that parts two genuinely distinct
    // manoeuvres (a sub-refractory ~1 s dip, the staircase hold-jitter inside
    // ONE manoeuvre, must NOT re-arm — that was the ~100× over-count).
    t = feed(det,
        start: t,
        count: 60,
        mag: 0.2,
        startSpeedKmh: 45,
        speedStepKmh: 0.0);
    feed(det,
        start: t,
        count: 30,
        mag: 4.0,
        startSpeedKmh: 45,
        speedStepKmh: 0.5);
    expect(det.hardAccelCount, 2,
        reason: 'the multi-second calm gap clears the refractory window, '
            'so the second burst counts again');
  });

  test('a 1 s sub-threshold dip INSIDE one manoeuvre → ONE '
      '(refractory window debounces, #2846)', () {
    // The smoking gun from the Skoda-diesel backup: ONE continuous hard
    // accel whose strong-magnitude stretch dips below the threshold for a
    // single ~1 s hold (the staircase a coarse signal inserts), then crosses
    // it again. The sub-refractory dip must NOT re-arm → ONE event, not two.
    final det = ImuEventDetector();
    var t = feed(det,
        start: t0,
        count: 30,
        mag: 4.0,
        startSpeedKmh: 30,
        speedStepKmh: 0.5);
    // 20 samples × 50 ms = 1 s below threshold — shorter than the 2 s
    // refractory window — while speed keeps climbing (still one manoeuvre).
    t = feed(det,
        start: t,
        count: 20,
        mag: 0.2,
        startSpeedKmh: 45,
        speedStepKmh: 0.5);
    feed(det,
        start: t,
        count: 30,
        mag: 4.0,
        startSpeedKmh: 55,
        speedStepKmh: 0.5);
    expect(det.hardAccelCount, 1,
        reason: 'a sub-refractory dip inside one manoeuvre does not re-arm');
  });

  test('one continuous 3 s accel stretch → ONE (latch holds)', () {
    final det = ImuEventDetector();
    feed(det,
        start: t0,
        count: 60,
        mag: 4.0,
        startSpeedKmh: 30,
        speedStepKmh: 0.4);
    expect(det.hardAccelCount, 1,
        reason: 'no sub-threshold gap → the latch holds → one episode');
  });

  test('onEvent fires once per confirmed accel/brake episode with the right '
      'type (bus wiring)', () {
    final fired = <HarshEvent>[];
    final det = ImuEventDetector(onEvent: fired.add);
    var t = feed(det,
        start: t0,
        count: 30,
        mag: 4.0,
        startSpeedKmh: 30,
        speedStepKmh: 0.5);
    // Calm gap LONGER than the refractory window (#2846), then a brake.
    t = feed(det,
        start: t,
        count: 60,
        mag: 0.2,
        startSpeedKmh: 45,
        speedStepKmh: 0.0);
    feed(det,
        start: t,
        count: 40,
        mag: 4.0,
        startSpeedKmh: 90,
        speedStepKmh: -0.5);
    expect(fired, hasLength(2));
    expect(fired[0].type, HarshEventType.acceleration);
    expect(fired[1].type, HarshEventType.brake);
    // Magnitude is reported in g, derived from the 4.0 m/s² horizontal mag.
    expect(fired[0].magnitudeG, closeTo(4.0 / standardGravityMps2, 1e-6));
  });
}
