// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'accel_event_gate.dart' show kHardBrakeThresholdMps2;
import 'road_grade_calculator.dart';
import 'road_load_episodes.dart';
import 'trip_sample.dart';

export 'road_load_episodes.dart';

/// Below this speed a sample is a standstill (1.8 km/h).
const double kRoadLoadStopSpeedMps = 0.5;

/// A fix less accurate than this contributes no altitude to the grade.
const double kGradeMaxAccuracyM = 25;

/// Distance without any altitude after which a grade is no longer trusted:
/// a tunnel or an altitude dropout must not keep reporting the grade from
/// before it (the calculator itself only knows its last point).
const double kGradeMaxAltitudeGapM = 150;

/// Bearing is meaningless at walking pace and from an inaccurate fix.
const double kCurveMinSpeedMps = 5;
const double kCurveMaxAccuracyM = 15;

/// Yaw rate (rad/s ≈ 4.6 °/s) above which a moment counts as turning.
const double kCurveYawRateRadPerS = 0.08;

/// A curve must turn for at least this long to be an episode.
const Duration kCurveMinDuration = Duration(seconds: 2);

/// Look-back / look-ahead windows around a curve.
const Duration kCurveApproachWindow = Duration(seconds: 8);
const Duration kCurveLateBrakeWindow = Duration(seconds: 2);
const Duration kCurveExitWindow = Duration(seconds: 5);

/// Late braking / hard exit thresholds (below the harsh-event gate: the
/// pattern, not an incident, is what matters).
const double kCurveLateBrakeMps2 = 2.5;
const double kCurveHardExitMps2 = 2.0;

/// Oscillation phases: sustained acceleration and braking (m/s²) within one
/// window, with no stop in between.
const double kOscillationAccelMps2 = 1.5;
const double kOscillationBrakeMps2 = 2.0;
const Duration kOscillationWindow = Duration(seconds: 20);

/// One timestamped derived sample, every value traceable to its quality.
@immutable
class RoadLoadPoint {
  const RoadLoadPoint({
    required this.timestamp,
    required this.speedMps,
    required this.accelMps2,
    required this.grade,
    required this.yawRateRadPerS,
    required this.stopped,
  });

  final DateTime timestamp;
  final double speedMps;

  /// 3-sample moving average of the speed derivative; null on the first.
  final double? accelMps2;

  /// Confidence-gated grade (flat + unconfident when not trustworthy).
  final RoadGrade grade;

  /// Signed yaw rate, or null when bearing / accuracy / speed make it
  /// meaningless — an unknown, never a straight road.
  final double? yawRateRadPerS;
  final bool stopped;

  /// Curve radius (m) while turning, null when straight or unknown.
  double? get curveRadiusM {
    final yaw = yawRateRadPerS;
    if (yaw == null || yaw.abs() < kCurveYawRateRadPerS) return null;
    return speedMps / yaw.abs();
  }
}

/// #4203 — ONE pass over a recording's samples into road / vehicle-dynamics
/// features with confidence, and the episodes consumption and driving
/// analysis both read, so neither re-derives them. Reuses
/// [RoadGradeCalculator] (smoothed altitude over a distance window, with
/// confidence) and the shared hard-brake threshold.
@immutable
class RoadLoadTrack {
  const RoadLoadTrack({
    required this.points,
    required this.stops,
    required this.curves,
    required this.oscillations,
  });

  final List<RoadLoadPoint> points;
  final List<StopEpisode> stops;
  final List<CurveEpisode> curves;
  final List<OscillationEpisode> oscillations;

  static const RoadLoadTrack empty =
      RoadLoadTrack(points: [], stops: [], curves: [], oscillations: []);

  /// Share of moving points whose grade is confident.
  double get gradeConfidenceShare => _share((p) => p.grade.confident);

  /// Share of moving points with a usable yaw rate.
  double get curvatureConfidenceShare =>
      _share((p) => p.yawRateRadPerS != null);

  double _share(bool Function(RoadLoadPoint) ok) {
    final moving = points.where((p) => !p.stopped).toList();
    if (moving.isEmpty) return 0;
    return moving.where(ok).length / moving.length;
  }

  /// The debug / export view of the derived features.
  Map<String, Object> toTrace() => {
        'points': points.length,
        'gradeConfidenceShare': gradeConfidenceShare,
        'curvatureConfidenceShare': curvatureConfidenceShare,
        'stops': stops.length,
        'stopSeconds':
            stops.fold<int>(0, (sum, s) => sum + s.duration.inSeconds),
        'curves': curves.length,
        'curvesLateBrakeHardExit': curves
            .where((c) => c.approach == CurveApproach.lateBrakeHardExit)
            .length,
        'oscillations': oscillations.length,
      };

  static RoadLoadTrack from(List<TripSample> samples) {
    if (samples.length < 2) return empty;
    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final gradeCalc = RoadGradeCalculator();
    final points = <RoadLoadPoint>[];
    final window = <double>[];
    var distanceM = 0.0;
    double? altitudeSeenAtM;
    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final v = math.max(0.0, s.speedKmh / 3.6);
      double? accel;
      double? yaw;
      if (i > 0) {
        final prev = sorted[i - 1];
        final dt = s.timestamp.difference(prev.timestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
        if (dt > 0) {
          final vPrev = math.max(0.0, prev.speedKmh / 3.6);
          distanceM += vPrev * dt;
          window.add((v - vPrev) / dt);
          if (window.length > 3) window.removeAt(0);
          accel = window.reduce((a, b) => a + b) / window.length;
          yaw = _yawRate(prev, s, v, dt);
        }
      }
      final accurate = (s.hAccuracyM ?? 0) <= kGradeMaxAccuracyM;
      if (v > kRoadLoadStopSpeedMps && s.altitudeM != null && accurate) {
        gradeCalc.addSample(
            cumulativeDistanceKm: distanceM / 1000, altitudeM: s.altitudeM);
        altitudeSeenAtM = distanceM;
      }
      final stale = altitudeSeenAtM == null ||
          distanceM - altitudeSeenAtM > kGradeMaxAltitudeGapM;
      points.add(RoadLoadPoint(
        timestamp: s.timestamp,
        speedMps: v,
        accelMps2: accel,
        grade: stale ? RoadGrade.flat : gradeCalc.current,
        yawRateRadPerS: yaw,
        stopped: v <= kRoadLoadStopSpeedMps,
      ));
    }
    return RoadLoadTrack(
      points: points,
      stops: _stops(points),
      curves: _curves(points),
      oscillations: _oscillations(points),
    );
  }

  static double? _yawRate(TripSample prev, TripSample cur, double v, double dt) {
    final pb = prev.bearingDeg, cb = cur.bearingDeg;
    if (pb == null || cb == null || v < kCurveMinSpeedMps) return null;
    if ((prev.hAccuracyM ?? double.infinity) > kCurveMaxAccuracyM ||
        (cur.hAccuracyM ?? double.infinity) > kCurveMaxAccuracyM) {
      return null;
    }
    final d = ((cb - pb + 540.0) % 360.0) - 180.0;
    return d * math.pi / 180.0 / dt;
  }

  static List<StopEpisode> _stops(List<RoadLoadPoint> points) {
    final out = <StopEpisode>[];
    DateTime? start;
    for (final p in points) {
      if (p.stopped) {
        start ??= p.timestamp;
      } else if (start != null) {
        out.add(StopEpisode(
            start: start, duration: p.timestamp.difference(start)));
        start = null;
      }
    }
    return out;
  }

  static List<CurveEpisode> _curves(List<RoadLoadPoint> points) {
    final out = <CurveEpisode>[];
    var i = 0;
    while (i < points.length) {
      final yaw = points[i].yawRateRadPerS;
      if (yaw == null || yaw.abs() < kCurveYawRateRadPerS) {
        i++;
        continue;
      }
      var j = i;
      while (j + 1 < points.length &&
          (points[j + 1].yawRateRadPerS?.abs() ?? 0) >= kCurveYawRateRadPerS) {
        j++;
      }
      final start = points[i].timestamp, end = points[j].timestamp;
      if (end.difference(start) >= kCurveMinDuration) {
        out.add(_curve(points, i, j));
      }
      i = j + 1;
    }
    return out;
  }

  static CurveEpisode _curve(List<RoadLoadPoint> points, int i, int j) {
    final start = points[i].timestamp, end = points[j].timestamp;
    Iterable<RoadLoadPoint> within(DateTime from, DateTime to) => points.where(
        (p) => !p.timestamp.isBefore(from) && !p.timestamp.isAfter(to));
    final approach = within(start.subtract(kCurveApproachWindow), start);
    final late = within(start.subtract(kCurveLateBrakeWindow), end);
    final exit = within(end, end.add(kCurveExitWindow));
    final entry = approach.map((p) => p.speedMps).fold(0.0, math.max);
    final minSpeed =
        points.sublist(i, j + 1).map((p) => p.speedMps).reduce(math.min);
    final peakDecel = late
        .map((p) => -(p.accelMps2 ?? 0))
        .fold(0.0, math.max);
    final exitAccel = exit.map((p) => p.accelMps2 ?? 0).fold(0.0, math.max);
    final CurveApproach kind;
    if (approach.length < 3 || exit.length < 2) {
      kind = CurveApproach.unknown;
    } else if (peakDecel >= kCurveLateBrakeMps2 &&
        exitAccel >= kCurveHardExitMps2) {
      kind = CurveApproach.lateBrakeHardExit;
    } else {
      kind = CurveApproach.smooth;
    }
    return CurveEpisode(
      start: start,
      end: end,
      entrySpeedMps: entry,
      minSpeedMps: minSpeed,
      peakDecelMps2: peakDecel,
      exitAccelMps2: exitAccel,
      approach: kind,
    );
  }

  static List<OscillationEpisode> _oscillations(List<RoadLoadPoint> points) {
    // Phase string over moving points: +1 accelerating, -1 braking.
    final phases = <({int sign, DateTime at, double magnitude})>[];
    for (final p in points) {
      final a = p.accelMps2;
      if (p.stopped) {
        phases.add((sign: 0, at: p.timestamp, magnitude: 0));
        continue;
      }
      if (a == null) continue;
      final sign = a >= kOscillationAccelMps2
          ? 1
          : a <= -kOscillationBrakeMps2
              ? -1
              : null;
      if (sign == null) continue;
      if (phases.isNotEmpty && phases.last.sign == sign) {
        final last = phases.removeLast();
        phases.add((
          sign: sign,
          at: last.at,
          magnitude: math.max(last.magnitude, a.abs()),
        ));
      } else {
        phases.add((sign: sign, at: p.timestamp, magnitude: a.abs()));
      }
    }
    final out = <OscillationEpisode>[];
    var k = 0;
    while (k + 2 < phases.length) {
      final a = phases[k], b = phases[k + 1], c = phases[k + 2];
      if (a.sign == 1 &&
          b.sign == -1 &&
          c.sign == 1 &&
          c.at.difference(a.at) <= kOscillationWindow) {
        out.add(OscillationEpisode(
          start: a.at,
          end: c.at,
          peakAccelMps2: math.max(a.magnitude, c.magnitude),
          peakDecelMps2: b.magnitude,
        ));
        k += 2; // the closing acceleration may open the next episode
      } else {
        k++;
      }
    }
    return out;
  }
}

/// Deceleration strong enough to be a harsh event on its own.
bool isHarshDecel(double decelMps2) => decelMps2 >= kHardBrakeThresholdMps2;
