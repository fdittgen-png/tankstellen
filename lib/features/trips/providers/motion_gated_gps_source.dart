// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/location/recording_location_settings.dart';
import '../../../core/logging/error_logger.dart';
import '../domain/services/motion_gate.dart';

/// #3319 — owns the recording GPS subscription and motion-gates its cadence:
/// full-rate ([GpsProfile.fine]) while moving, backed off
/// ([GpsProfile.coarse]) once the device has been stationary, re-fining on
/// resumed motion. The cadence only changes in FGS-approved builds — where
/// the recording stream actually runs in the background and the battery save
/// is real; otherwise this just relays fixes at the fine cadence (backing a
/// foreground-only stream off buys nothing and risks a trace gap).
///
/// Extracted from [GpsOnlyRecordingPipeline] so the gate + subscription
/// lifecycle is self-contained and independently testable, and so the
/// pipeline stays under the file-length cap.
class MotionGatedGpsSource {
  MotionGatedGpsSource({
    required Ref ref,
    required void Function(Position) onPosition,
    MotionGate? gate,
    bool? foregroundServiceEnabled,
  })  : _ref = ref,
        _onPosition = onPosition,
        _gate = gate ?? MotionGate(),
        _fgsEnabled =
            foregroundServiceEnabled ?? kGpsRecordingForegroundServiceEnabled;

  final Ref _ref;
  final void Function(Position) _onPosition;
  final MotionGate _gate;
  final bool _fgsEnabled;

  StreamSubscription<Position>? _sub;
  GpsProfile _profile = GpsProfile.fine;

  /// The cadence currently in effect (for diagnostics / tests).
  GpsProfile get profile => _profile;

  /// Open the fine-cadence recording stream.
  void start() {
    _sub = _open(coarse: false);
  }

  /// Feed the latest fix's ground speed (km/h) and the monotonic [elapsed]
  /// since recording start. Swaps the subscription cadence when the motion
  /// gate flips. No-op unless the recording FGS is enabled. Best-effort: a
  /// failed swap leaves the existing subscription running (new-before-cancel,
  /// so we never end up with no GPS).
  void onSpeed(double speedKmh, Duration elapsed) {
    if (!_fgsEnabled) return;
    final next = _gate.onFix(speedKmh: speedKmh, elapsed: elapsed);
    if (next == _profile) return;
    _profile = next;
    try {
      final old = _sub;
      _sub = _open(coarse: next == GpsProfile.coarse);
      unawaited(old?.cancel());
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'MotionGatedGpsSource: profile swap'}));
    }
  }

  /// Cancel the current subscription (end of trip).
  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
  }

  StreamSubscription<Position> _open({required bool coarse}) {
    return _ref
        .read(geolocatorWrapperProvider)
        .sharedPositionStream(
          recording: true,
          locationSettings:
              recordingLocationSettingsForRef(_ref, coarse: coarse),
        )
        .listen(
          _onPosition,
          onError: (Object e, StackTrace st) {
            unawaited(errorLogger.log(ErrorLayer.providers, e, st,
                context: const {'where': 'MotionGatedGpsSource: stream error'}));
          },
        );
  }
}
