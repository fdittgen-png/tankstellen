// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

/// #3364 — tilt-compensated compass azimuth from raw accelerometer (gravity)
/// + magnetometer vectors. Pure math (no sensors_plus) so it is unit-testable
/// without a device.
///
/// Mirrors Android `SensorManager.getRotationMatrix` + `getOrientation`:
/// the cross products build the device→world rotation and the azimuth is
/// `atan2(R[1], R[4])` — the angle, clockwise from magnetic north, that the
/// device's +Y axis (its "top") points toward. Returns degrees in `[0, 360)`,
/// or `null` when the vectors are degenerate (free-fall / no usable field).
///
/// [ax]/[ay]/[az] is the RAW accelerometer (gravity included, m/s²) — NOT the
/// gravity-removed `userAccelerometer` the harsh-event detector uses.
double? azimuthFromVectors(
  double ax,
  double ay,
  double az,
  double mx,
  double my,
  double mz,
) {
  // H = M × A  (points device-east), then normalise.
  final hx = my * az - mz * ay;
  final hy = mz * ax - mx * az;
  final hz = mx * ay - my * ax;
  final normH = sqrt(hx * hx + hy * hy + hz * hz);
  if (normH < 0.1) return null; // device tilted into the field / free-fall
  final invH = 1 / normH;
  final ehx = hx * invH;
  final ehy = hy * invH;
  final ehz = hz * invH;

  final normA = sqrt(ax * ax + ay * ay + az * az);
  if (normA < 0.1) return null;
  final invA = 1 / normA;
  final eax = ax * invA;
  final eaz = az * invA;

  // M (device-north) = A × H, using the normalised vectors; only the
  // Y component feeds the azimuth.
  final my2 = eaz * ehx - eax * ehz;

  // azimuth = atan2(R[1], R[4]) = atan2(Hy, My).
  final deg = atan2(ehy, my2) * 180 / pi;
  return (deg + 360) % 360;
}

/// #3364 — exponential low-pass smoother for a *circular* heading (deg), so a
/// noisy magnetometer doesn't make the scope jitter and the 359°→0° wrap is
/// handled (filtering the unit vector, not the raw angle). [alpha] in (0,1];
/// higher = snappier, lower = smoother.
class CompassSmoother {
  CompassSmoother({this.alpha = 0.18});

  final double alpha;
  double? _x;
  double? _y;

  /// Fold [headingDeg] in and return the smoothed heading in `[0, 360)`.
  double add(double headingDeg) {
    final r = headingDeg * pi / 180;
    final cx = cos(r);
    final cy = sin(r);
    _x = _x == null ? cx : _x! + alpha * (cx - _x!);
    _y = _y == null ? cy : _y! + alpha * (cy - _y!);
    final out = atan2(_y!, _x!) * 180 / pi;
    return (out + 360) % 360;
  }

  /// Smallest absolute difference between two headings, in `[0, 180]`.
  static double delta(double a, double b) {
    final d = ((a - b) % 360 + 540) % 360 - 180;
    return d.abs();
  }
}
