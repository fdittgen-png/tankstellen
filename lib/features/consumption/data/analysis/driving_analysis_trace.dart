// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import '../../domain/driving_score.dart';
import '../../domain/gps_driving_features.dart';
import '../../domain/lessons/driving_lesson.dart';
import '../../domain/trip_summary.dart';

/// A self-contained, JSON-serialisable snapshot of a single trip's
/// driving-analysis inputs + outputs, for offline threshold calibration
/// (#2804, Epic #2789 C6).
///
/// Mirrors the OCR trace package (#2517): pure Dart, hand-written `toJson`,
/// `schema` versioned. The maintainer exports this from the trip-detail screen
/// (dev-mode), writes their subjective verdict into [comment] (e.g. "calm
/// motorway cruise — felt smooth"), and shares the JSON back, giving labelled
/// real-trip data to fine-tune the GPS-efficiency KPI verdict bands (RPA / PKE
/// / VAPOS / coasting) and the IMU/score thresholds against reality — instead
/// of guessing cutoffs that could contradict the smooth-driving lesson.
class DrivingAnalysisTrace {
  /// Serialisation schema version. Bump when a field's meaning changes.
  static const int schema = 1;

  final DateTime capturedAt;

  /// The maintainer's free-text verdict + notes. Defaults to a prompt so the
  /// exported file invites annotation; the maintainer overwrites it.
  final String comment;

  final TripSummary summary;
  final GpsDrivingFeatures? gpsFeatures;
  final DrivingScore score;
  final List<DrivingLesson> lessons;

  const DrivingAnalysisTrace({
    required this.capturedAt,
    required this.summary,
    required this.score,
    required this.lessons,
    this.gpsFeatures,
    this.comment = kDrivingAnalysisCommentPrompt,
  });

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'kind': 'drivingAnalysis',
        'capturedAt': capturedAt.toIso8601String(),
        // The annotation slot — first so it is obvious in the shared file.
        'comment': comment,
        'summary': {
          'tripKind': summary.kind.name,
          'distanceKm': _round(summary.distanceKm, 3),
          'durationSec': _durationSec(summary),
          'avgLPer100Km': _roundN(summary.avgLPer100Km, 2),
          'distanceSource': summary.distanceSource,
        },
        'imu': {
          // #2895 — whether the inertial sensor ran. A genuine IMU zero with
          // active=true VETOES a noisy GPS over-count in the score; active=false
          // means the (clamped) GPS-derived counts were used.
          'active': summary.imuActive,
          'hardAccelCount': summary.imuHardAccelCount,
          'hardBrakeCount': summary.imuHardBrakeCount,
          'sharpCornerCount': summary.sharpCornerCount,
          'hardAccelPerKm': _round(summary.imuHardAccelPerKm, 3),
          'hardBrakePerKm': _round(summary.imuHardBrakePerKm, 3),
          'sharpCornersPerKm': _round(summary.sharpCornersPerKm, 3),
        },
        'gpsFeatures': gpsFeatures == null
            ? null
            : {
                'rpa': _round(gpsFeatures!.relativePositiveAcceleration, 4),
                'pke': _round(gpsFeatures!.positiveKineticEnergy, 4),
                'vapos': _round(gpsFeatures!.meanPositiveVa, 4),
                'coastShare': _round(gpsFeatures!.coastShare, 4),
                'climbEnergyPerKm': _round(gpsFeatures!.climbEnergyPerKm, 2),
                'accelEvents': gpsFeatures!.accelEvents,
                'brakeEvents': gpsFeatures!.brakeEvents,
                'sharpCornerEvents': gpsFeatures!.sharpCornerEvents,
                'maxAccelG': _round(gpsFeatures!.maxAccelG, 3),
                'meanSpeedKmh': _round(gpsFeatures!.meanSpeedKmh, 1),
                'speedBandSeconds': {
                  'idle': _round(gpsFeatures!.idleSeconds, 0),
                  'low': _round(gpsFeatures!.lowSpeedSeconds, 0),
                  'cruise': _round(gpsFeatures!.cruiseSeconds, 0),
                  'high': _round(gpsFeatures!.highSpeedSeconds, 0),
                },
              },
        'score': {
          'overall': score.score,
          'styleClass': score.styleClass.name,
          // #3029 — the harsh counts that ACTUALLY drive the penalties
          // (`summary.harshAccelerations`/`harshBrakes` — IMU when it ran,
          // else the now-suppressed direct-speed value), so a non-zero
          // penalty always has a visible matching count. The `imu.*Count`
          // block above stays the inertial-sensor truth; before this, a
          // GPS-sourced trip could show a penalty>0 while `imu.*Count==0`,
          // reading as a phantom with no source.
          'hardAccelCount': summary.harshAccelerations,
          'hardBrakeCount': summary.harshBrakes,
          'hardAccelPenalty': _round(score.hardAccelPenalty, 2),
          'hardBrakePenalty': _round(score.hardBrakePenalty, 2),
          'idlingPenalty': _round(score.idlingPenalty, 2),
          'highRpmPenalty': _round(score.highRpmPenalty, 2),
          'luggingPenalty': _round(score.luggingPenalty, 2),
        },
        // What the app currently TELLS the user — so an annotation that
        // disagrees pinpoints exactly which judgment to retune.
        'lessons': [
          for (final l in lessons)
            {'id': l.id, 'polarity': l.polarity.name, 'title': l.title},
        ],
      };

  static double _round(double v, int places) {
    final f = _pow10(places);
    return (v * f).round() / f;
  }

  static double? _roundN(double? v, int places) =>
      v == null ? null : _round(v, places);

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  static double? _durationSec(TripSummary s) {
    final start = s.startedAt, end = s.endedAt;
    if (start == null || end == null) return null;
    return end.difference(start).inSeconds.toDouble();
  }
}

/// Default [DrivingAnalysisTrace.comment] — a prompt inviting the maintainer to
/// label the trip so the export is self-explanatory when shared back.
const String kDrivingAnalysisCommentPrompt =
    'YOUR VERDICT HERE → how did this trip actually feel? '
    '(smooth / moderate / aggressive) + any notable hard accel/brake/corner '
    'moments, so the RPA/PKE/VAPOS/coasting bands can be calibrated to match.';

/// Pretty-prints a [DrivingAnalysisTrace] as indented JSON (mirrors
/// `formatOcrTracePackageJson`).
String formatDrivingAnalysisTraceJson(DrivingAnalysisTrace trace) =>
    const JsonEncoder.withIndent('  ').convert(trace.toJson());
