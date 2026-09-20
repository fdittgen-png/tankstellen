// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/location/recording_location_settings.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../domain/services/motion_gate.dart';
import 'recording_gps_fix_provider.dart';

/// #3319 — owns the recording GPS subscription and evaluates the motion gate
/// against every fix.
///
/// #4353 — the trip runs ONE stable, actually-applied profile
/// ([GpsProfile.fine]) from start to stop. Adaptive sampling is deliberately
/// disabled; see [onSpeed] for why, and [wouldBeProfile] for the gate's
/// verdict, which is still computed for the recording journal.
///
/// Extracted from [GpsOnlyRecordingPipeline] so the gate + subscription
/// lifecycle is self-contained and independently testable, and so the
/// pipeline stays under the file-length cap.
class MotionGatedGpsSource {
  MotionGatedGpsSource({
    required this._ref,
    required this._onPosition,
    MotionGate? gate,
    bool? foregroundServiceEnabled,
  })  : _gate = gate ?? MotionGate(),
        _fgsEnabled =
            foregroundServiceEnabled ?? kGpsRecordingForegroundServiceEnabled;

  final Ref _ref;
  final void Function(Position) _onPosition;
  final MotionGate _gate;
  final bool _fgsEnabled;

  StreamSubscription<Position>? _sub;
  GpsProfile _wouldBeProfile = GpsProfile.fine;

  /// The cadence actually APPLIED to the recording stream. #4353 pins it to
  /// [GpsProfile.fine] for the whole trip, so this reports what the platform
  /// stream is really running — never a request dressed up as an outcome.
  GpsProfile get profile => GpsProfile.fine;

  /// #4353 — what the motion gate WOULD select right now, had adaptive
  /// sampling been enabled. Journal-only: it never moves [profile].
  GpsProfile get wouldBeProfile => _wouldBeProfile;

  /// Whether this build could apply a coarse profile at all: the recording
  /// foreground service is the un-throttle lever, so without it a backed-off
  /// stream saves nothing. Journal context for [wouldBeProfile].
  bool get adaptiveSamplingSupported => _fgsEnabled;

  /// Open the fine-cadence recording stream.
  void start() {
    _sub = _open();
  }

  /// Feed the latest fix's ground speed (km/h) and the monotonic [elapsed]
  /// since recording start, and record the gate's verdict in
  /// [wouldBeProfile].
  ///
  /// #4353 — adaptive sampling is DELIBERATELY DISABLED; this no longer
  /// swaps the subscription. The swap opened the new stream before
  /// cancelling the old one, and `geolocator_android` hands back its cached
  /// `_positionStream` until the LAST listener cancels, so the new settings
  /// were silently discarded: the cadence never changed and `profile`
  /// reported a battery saving that never happened. A swap that DID take
  /// effect would be worse — it tears the recording foreground service down
  /// and re-promotes it mid-trip, a background start Android may refuse,
  /// losing the trip's protection outright.
  ///
  /// So a trip keeps one stable, actually-applied profile from start to
  /// stop — the documented stable-profile option #4353 blesses. The gate is
  /// still evaluated so the journal can show what adaptive sampling would
  /// have done and the battery cost can be measured before it returns, and
  /// it returns only through a verified transition API (a reconfiguration
  /// the platform acknowledges), never by swapping streams.
  void onSpeed(double speedKmh, Duration elapsed) {
    _wouldBeProfile = _gate.onFix(speedKmh: speedKmh, elapsed: elapsed);
  }

  /// Cancel the current subscription (end of trip).
  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// #3916 — every fix also feeds the recording screen's live GPS status
  /// (accuracy + cadence) before the pipeline's own handler runs.
  void _dispatch(Position pos) {
    teeRecordingGpsFix(
      _ref,
      fixAt: pos.timestamp,
      accuracyM: pos.accuracy.isFinite ? pos.accuracy : null,
      where: 'MotionGatedGpsSource: GPS fix seam',
    );
    _onPosition(pos);
  }

  StreamSubscription<Position> _open() {
    return _ref
        .read(geolocatorWrapperProvider)
        .sharedPositionStream(
          recording: true,
          locationSettings: recordingLocationSettingsForRef(_ref),
        )
        .listen(
          _dispatch,
          onError: (Object e, StackTrace st) {
            log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'MotionGatedGpsSource: stream error'});
          },
        );
  }
}
