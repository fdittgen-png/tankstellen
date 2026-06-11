// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'imu_sample.dart';

part 'imu_sensor_source.g.dart';

/// Wraps `sensors_plus` behind a testable, app-lifetime provider (#2760).
///
/// ## The single `sensors_plus` import site
///
/// This is the ONLY file in the codebase that imports `sensors_plus`, the
/// loosely-coupled-plugin idiom the project mandates (mirroring
/// `geolocator_wrapper.dart`): the platform plugin is touched in exactly one
/// place, never with an inline `if (Platform.isX)`, so the GPS+IMU pipeline
/// and its tests depend on the plain [ImuSample] value type rather than on
/// the plugin's event classes. Tests override [imuSensorSourceProvider] with
/// a fake emitting a fixed synthetic [ImuSample] stream.
///
/// `keepAlive` because a trip — and the sensor stream feeding its detector —
/// outlives widget rebuilds as the driver navigates the app mid-trip, exactly
/// like the geolocator wrapper.
@Riverpod(keepAlive: true)
ImuSensorSource imuSensorSource(Ref ref) {
  return ImuSensorSource();
}

class ImuSensorSource {
  /// A fused ~50 Hz stream of gravity-removed linear acceleration +
  /// yaw-rate samples.
  ///
  /// ## Why `userAccelerometerEventStream`, not `accelerometerEventStream`
  ///
  /// `userAccelerometerEventStream` reports **linear** acceleration with the
  /// gravity vector already removed on-device (Android's `TYPE_LINEAR_
  /// ACCELERATION` / iOS CoreMotion `userAcceleration`). A phone lying flat
  /// reads ~0 on every axis, so the harsh-accel / harsh-brake detector sees
  /// the genuine vehicle longitudinal acceleration directly — no fragile
  /// per-app low-pass gravity-removal filter, and no orientation bookkeeping
  /// to subtract a ~9.8 m/s² bias. The raw `accelerometerEventStream` would
  /// include gravity and is deliberately NOT used.
  ///
  /// ## Fusion
  ///
  /// The accelerometer drives the cadence: every accel event produces one
  /// [ImuSample] carrying the most-recent gyroscope Z reading (the yaw rate).
  /// Both are sampled at [SensorInterval.gameInterval] (~50 Hz). A gyro
  /// reading that has not arrived yet is carried as 0.0 — the detector's
  /// cornering gate additionally requires a lateral-accel threshold, so a
  /// missing yaw rate cannot manufacture a phantom corner.
  ///
  /// ## Aggregate-only contract
  ///
  /// The returned stream is consumed sample-by-sample by the pure detector
  /// and never collected into a persisted list — see [ImuSample].
  Stream<ImuSample> stream() {
    var lastGyroZ = 0.0;
    StreamSubscription<GyroscopeEvent>? gyroSub;
    StreamSubscription<UserAccelerometerEvent>? accelSub;

    // Closed in its own `onCancel` once the consumer detaches (alongside the
    // two upstream sensor subscriptions), so there is no leak — the analyzer
    // can't see across the closure, hence the ignore (same idiom as the
    // shared position source in geolocator_wrapper.dart).
    // ignore: close_sinks
    late final StreamController<ImuSample> out;
    out = StreamController<ImuSample>(
      onListen: () {
        // A device without an accelerometer / gyroscope, or a host without
        // the platform plugin bound (e.g. a unit-test process), makes the
        // sensor stream throw at subscribe time. Degrade gracefully to a
        // quiet stream that simply never emits — the GPS+IMU trip then
        // records off GPS alone rather than crashing. (Tests that exercise
        // the detector override this provider with a synthetic source.)
        try {
          gyroSub = gyroscopeEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen((e) => lastGyroZ = e.z, onError: (Object _) {});
          accelSub = userAccelerometerEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen(
            (e) {
              if (out.isClosed) return;
              out.add(ImuSample(
                t: DateTime.now(),
                axMps2: e.x,
                ayMps2: e.y,
                azMps2: e.z,
                gyroZRadPerSec: lastGyroZ,
              ));
            },
            onError: (Object err, StackTrace st) {
              if (!out.isClosed) out.addError(err, st);
            },
          );
        } catch (_) {
          // ignore: silent_catch — Sensors unavailable — leave the stream quiet.
        }
      },
      onCancel: () async {
        try {
          await accelSub?.cancel();
          await gyroSub?.cancel();
        } catch (_) {
          // ignore: silent_catch — A subscription that failed to set up cleanly may also throw on
          // cancel; nothing to recover.
        }
        if (!out.isClosed) await out.close();
      },
    );
    return out.stream;
  }
}
