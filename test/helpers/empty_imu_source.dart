// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/sensors/imu_sample.dart';
import 'package:tankstellen/core/sensors/imu_sensor_source.dart';

// Re-export so a test importing this helper can write the override
// `imuSensorSourceProvider.overrideWithValue(EmptyImuSource())` with this one
// import.
export 'package:tankstellen/core/sensors/imu_sensor_source.dart'
    show imuSensorSourceProvider;

/// A stub [ImuSensorSource] that yields no samples (#2760).
///
/// The GPS-only recording pipeline now attaches IMU sensor fusion in
/// `start()`. Tests that drive the pipeline (directly or via the
/// `TripRecording` notifier) but are NOT exercising the IMU path override
/// `imuSensorSourceProvider` with this so they never touch the real
/// `sensors_plus` platform channel (which has no binding in a unit-test
/// process). Dedicated IMU coverage lives in
/// `gps_only_imu_fusion_test.dart` + `imu_event_detector_test.dart`.
class EmptyImuSource extends ImuSensorSource {
  @override
  Stream<ImuSample> stream() => const Stream<ImuSample>.empty();
}
