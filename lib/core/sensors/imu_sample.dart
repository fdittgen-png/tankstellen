// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One fused inertial-measurement-unit sample (#2760): the gravity-removed
/// linear acceleration on the three device axes plus the yaw-axis angular
/// rate, stamped with a wall-clock time.
///
/// ## In-memory only — never persisted
///
/// This is a transient value carried from [ImuSensorSource] to the pure
/// [ImuEventDetector] and dropped immediately. The dongle-optional GPS+IMU
/// pipeline (#2760) is bound by a hard "aggregate-only, disk-efficient"
/// constraint: at ~50 Hz a raw sample list would saturate local disk, so
/// NOTHING here is ever buffered into a list for persistence or written to
/// JSON. The detector folds each sample into a handful of in-memory integer
/// counters in real time; on trip stop only those few scalars survive. There
/// is deliberately no `toJson` / `fromJson` on this type — adding one would
/// invite exactly the raw-sample persistence the issue forbids.
///
/// The accelerometer axes carry **linear** acceleration with gravity already
/// removed (sourced from `userAccelerometerEventStream`, not the raw
/// `accelerometerEventStream`), so a phone resting flat reads ~0 on every
/// axis. Units: m/s² for the accel axes, rad/s for the yaw rate.
class ImuSample {
  const ImuSample({
    required this.t,
    required this.axMps2,
    required this.ayMps2,
    required this.azMps2,
    required this.gyroZRadPerSec,
  });

  /// Wall-clock timestamp the fused sample was assembled at.
  final DateTime t;

  /// Linear (gravity-removed) acceleration on the device X axis, m/s².
  final double axMps2;

  /// Linear (gravity-removed) acceleration on the device Y axis, m/s².
  final double ayMps2;

  /// Linear (gravity-removed) acceleration on the device Z axis, m/s².
  final double azMps2;

  /// Angular rate about the device Z (yaw) axis, rad/s — the cornering
  /// signal: a sustained non-zero yaw rate at speed is a turn.
  final double gyroZRadPerSec;
}
