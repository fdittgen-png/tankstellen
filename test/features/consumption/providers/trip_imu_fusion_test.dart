// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sensors/imu_sample.dart';
import 'package:tankstellen/core/sensors/imu_sensor_source.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/features/consumption/providers/trip_imu_fusion.dart';

/// #3500 (epic #3498) — the shared per-trip IMU fusion both recording
/// pipelines run. Covers the lifecycle (subscribe once, cancel on stop),
/// the event flow onto the injected sink, and the #2895
/// `imuActive ? imu : recorder` veto [TripImuFusion.applyTo] stamps.
void main() {
  TripSummary recorderSummary({int accel = 7, int brake = 9}) => TripSummary(
        distanceKm: 10,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: brake,
        harshAccelerations: accel,
        avgLPer100Km: 6.5,
        fuelLitersConsumed: 0.65,
        startedAt: DateTime(2026, 7, 5, 8),
        endedAt: DateTime(2026, 7, 5, 8, 30),
      );

  List<ImuSample> burst({required double mag, double seconds = 1.6}) {
    final out = <ImuSample>[];
    var t = DateTime(2026, 7, 5, 8, 10);
    for (var i = 0; i < (seconds / 0.05).round(); i++) {
      out.add(ImuSample(
        t: t,
        axMps2: mag,
        ayMps2: 0,
        azMps2: 0,
        gyroZRadPerSec: 0,
      ));
      t = t.add(const Duration(milliseconds: 50));
    }
    return out;
  }

  test('a sustained inertial burst is counted, fires the event sink, and '
      'applyTo VETOES the recorder counts (#2895 semantics)', () async {
    final source = _ScriptedImuSource();
    final events = <HarshEvent>[];
    final fusion = TripImuFusion(
      source: source,
      onEvent: events.add,
      where: 'test',
    )..start();
    expect(source.activeListeners, 1);

    // The stream delivers asynchronously, so interleave the burst halves
    // with speed bumps + pumps (same ordering the live ~1 Hz GPS vs ~50 Hz
    // IMU streams produce): net speed change over the strong stretch is
    // +18 km/h → classifies as a HARD ACCEL.
    fusion.feedSpeedKmh(72); // past the min-speed gate
    final samples = burst(mag: 4.0, seconds: 2.0);
    final half = samples.length ~/ 2;
    for (final s in samples.take(half)) {
      source.emit(s);
    }
    await Future<void>.delayed(Duration.zero);
    fusion.feedSpeedKmh(90);
    for (final s in samples.skip(half)) {
      source.emit(s);
    }
    await Future<void>.delayed(Duration.zero);

    expect(fusion.isActive, isTrue);
    expect(fusion.hardAccelCount, greaterThanOrEqualTo(1));
    expect(events, isNotEmpty,
        reason: 'confirmed episodes must reach the live bus sink — that is '
            'what makes spoken coaching fire on OBD2 trips (#3500)');

    final stamped = fusion.applyTo(recorderSummary());
    expect(stamped.imuActive, isTrue);
    expect(stamped.harshAccelerations, fusion.hardAccelCount,
        reason: 'the direct inertial count replaces the speed-derivative '
            'recorder count when the sensor ran');
    expect(stamped.harshBrakes, fusion.hardBrakeCount);

    await fusion.stop();
    expect(source.activeListeners, 0,
        reason: 'no inertial subscription may survive between trips');
  });

  test('a quiet sensor (never emitted) leaves the recorder counts standing',
      () async {
    final source = _ScriptedImuSource();
    final fusion = TripImuFusion(source: source, where: 'test')..start();
    await fusion.stop();

    expect(fusion.isActive, isFalse);
    final stamped = fusion.applyTo(recorderSummary());
    expect(stamped.imuActive, isFalse);
    expect(stamped.harshAccelerations, 7,
        reason: 'no inertial signal ⇒ the (clamped) recorder counts stand');
    expect(stamped.harshBrakes, 9);
  });

  test('stop() is idempotent and start() after start() is a no-op', () async {
    final source = _ScriptedImuSource();
    final fusion = TripImuFusion(source: source, where: 'test')
      ..start()
      ..start();
    expect(source.totalSubscriptions, 1);
    await fusion.stop();
    await fusion.stop();
    expect(source.activeListeners, 0);
  });
}

/// Hand-driven fake source: the test pushes samples explicitly.
class _ScriptedImuSource extends ImuSensorSource {
  int activeListeners = 0;
  int totalSubscriptions = 0;
  StreamController<ImuSample>? _ctl;

  @override
  Stream<ImuSample> stream() {
    // The fusion cancels this on stop; single-use per test.
    // ignore: close_sinks
    final ctl = StreamController<ImuSample>(
      onListen: () {
        activeListeners++;
        totalSubscriptions++;
      },
      onCancel: () => activeListeners--,
    );
    _ctl = ctl;
    return ctl.stream;
  }

  void emit(ImuSample s) {
    final ctl = _ctl;
    if (ctl != null && !ctl.isClosed) ctl.add(s);
  }
}
