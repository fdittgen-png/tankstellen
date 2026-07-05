// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/sensors/imu_sample.dart';
import '../../../core/sensors/imu_sensor_source.dart';
import '../domain/services/imu_event_detector.dart';
import '../domain/trip_summary.dart';

/// One per-trip IMU sensor-fusion lifecycle, shared by BOTH recording
/// pipelines (#3500, epic #3498).
///
/// The inertial harsh/corner detector (#2760) used to live inline in the
/// GPS-only pipeline ONLY — the OBD2 path ran no inertial detector at all
/// (the #2895/#3029 parity note), so every OBD2 trip reported
/// `imuActive: false`, harsh counts 0, and the live voice coach never fired.
/// This collaborator owns the start → feed-speed → harvest lifecycle in one
/// place so both pipelines get the SAME accurate inertial signal and the
/// SAME #2895 veto semantics.
///
/// Lifecycle:
///  * [start] subscribes the [ImuEventDetector] to the shared IMU source and
///    forwards confirmed accel/brake episodes to [onEvent] (production: the
///    live harsh-event bus, so spoken coaching fires either way).
///  * [feedSpeedKmh] keeps the detector's min-speed gate + direction
///    classification tracking the real vehicle speed.
///  * [stop] cancels the subscription; the counters stay readable for the
///    summary harvest.
///  * [applyTo] stamps the aggregate counts + the #2895
///    `imuActive ? imu : recorder` veto onto a built [TripSummary] —
///    exactly the copyWith the GPS-only pipeline shipped, now shared.
///
/// Sensor failure is non-fatal by design: the stream error is logged and the
/// trip records without an inertial signal ([isActive] stays false, so the
/// veto never fires and the recorder counts stand).
class TripImuFusion {
  TripImuFusion({
    required ImuSensorSource source,
    void Function(HarshEvent event)? onEvent,
    String where = 'TripImuFusion',
  })  : _source = source,
        _where = where,
        _detector = ImuEventDetector(onEvent: onEvent);

  final ImuSensorSource _source;
  final String _where;
  final ImuEventDetector _detector;
  StreamSubscription<ImuSample>? _sub;

  /// Whether the inertial sensor actually produced a usable signal this
  /// trip (see [ImuEventDetector.isActive] — a genuine IMU zero must be
  /// distinguishable from "no IMU signal").
  bool get isActive => _detector.isActive;

  int get hardAccelCount => _detector.hardAccelCount;
  int get hardBrakeCount => _detector.hardBrakeCount;
  int get sharpCornerCount => _detector.sharpCornerCount;

  /// Subscribe the detector to the inertial stream. Idempotent. A throwing
  /// sensor layer (no IMU hardware, plugin not bound, no services binding in
  /// a bare test harness) is logged and degrades to "no inertial signal" —
  /// it must never take the recording path down.
  void start() {
    if (_sub != null) return;
    try {
      _sub = _source.stream().listen(
        _detector.onSample,
        onError: (Object e, StackTrace st) {
          unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {
            'where': '$_where: IMU stream error',
          }));
        },
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {
        'where': '$_where: IMU stream open failed',
      }));
    }
  }

  /// Feed the latest ground speed (km/h) — from GPS fixes or the OBD2 live
  /// reading — so the min-speed gate and accel-vs-brake direction track the
  /// real vehicle.
  void feedSpeedKmh(double? kmh) {
    if (kmh == null || !kmh.isFinite) return;
    _detector.currentSpeedKmh = kmh;
  }

  /// Stop listening. The counters remain readable. Safe to call repeatedly.
  /// A throwing platform-channel teardown is logged and swallowed — the
  /// trip save this runs inside must never be lost to a sensor teardown.
  Future<void> stop() async {
    final sub = _sub;
    _sub = null;
    try {
      await sub?.cancel();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {
        'where': '$_where: IMU stream cancel failed',
      }));
    }
  }

  /// Stamp the aggregate IMU counts + the #2895 veto onto [summary]: when
  /// the sensor RAN, its direct inertial counts (including a genuine zero)
  /// replace the speed-derivative recorder counts; when it never ran, the
  /// recorder counts stand untouched (`copyWith` keeps them on null).
  TripSummary applyTo(TripSummary summary) => summary.copyWith(
        imuHardAccelCount: hardAccelCount,
        imuHardBrakeCount: hardBrakeCount,
        sharpCornerCount: sharpCornerCount,
        imuActive: isActive,
        harshAccelerations: isActive ? hardAccelCount : null,
        harshBrakes: isActive ? hardBrakeCount : null,
      );
}

/// Riverpod factory for a fresh per-trip [TripImuFusion] (#3500). A factory
/// (not a keepAlive singleton) because the fusion is a per-recording
/// lifecycle object — each `start()` builds its own.
TripImuFusion buildTripImuFusion(
  Ref ref, {
  void Function(HarshEvent event)? onEvent,
  required String where,
}) =>
    TripImuFusion(
      source: ref.read(imuSensorSourceProvider),
      onEvent: onEvent,
      where: where,
    );
