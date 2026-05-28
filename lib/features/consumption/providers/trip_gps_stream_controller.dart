// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/geolocator_wrapper.dart';
import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../glide_coach/domain/entities/glide_coach_advice.dart';
import '../../glide_coach/providers/glide_coach_enabled_provider.dart';
import '../../glide_coach/providers/glide_coach_evaluator_provider.dart';
import '../../glide_coach/providers/glide_coach_settings_provider.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../../../core/logging/error_logger.dart';

/// Owns the #1374 / #1125 / #1458 GPS concern extracted from the
/// [TripRecording] notifier (#1679): the opt-in Geolocator position
/// stream, the per-fix cadence-diagnostic recording, and the
/// per-fix glide-coach evaluation hook.
///
/// The notifier delegates [start] / [stop] here. The collaborator
/// reads its Riverpod dependencies through [_ref] and the host app's
/// lifecycle state through the injected [_lifecycleState] getter so
/// the `_lifecycleState` field itself stays the notifier's.
class TripGpsStreamController {
  TripGpsStreamController({
    required Ref ref,
    required AppLifecycleState Function() lifecycleState,
  })  : _ref = ref,
        _lifecycleState = lifecycleState;

  final Ref _ref;
  final AppLifecycleState Function() _lifecycleState;

  /// #1374 phase 1 — Geolocator position stream feeding the
  /// controller's per-tick GPS latch. Only created when
  /// `Feature.gpsTripPath` is enabled at trip-start; the flag-off
  /// path leaves this null and never touches the plugin, so the
  /// battery / permission cost is exactly zero for users who haven't
  /// opted in.
  StreamSubscription<Position>? _gpsSub;

  /// Open a Geolocator position stream and route every fix through
  /// [TripRecordingController.updateGpsFix] (#1374 phase 1).
  ///
  /// No-op when [Feature.gpsTripPath] is disabled — the user can still
  /// turn it off from Feature management, and the flag-off path never
  /// touches the Geolocator plugin (zero battery cost). When the flag
  /// is on we open the stream at [LocationAccuracy.high] because the
  /// eventual heatmap (Phase 3) wants ~10 m precision.
  ///
  /// #1981 — before opening the stream we ensure foreground location
  /// permission: `getPositionStream` does not prompt, so without a
  /// grant it just errors. A denial is non-fatal — `start` returns and
  /// the recorder finalises on the virtual odometer.
  ///
  /// Stream errors are logged and swallowed: a permission revoke
  /// mid-trip, a temporary loss of fix, or the OS killing the
  /// position service must NOT derail the OBD2 trip recording. The
  /// controller's per-tick latch simply stops being refreshed and
  /// subsequent samples carry `latitude: null, longitude: null`.
  Future<void> start(TripRecordingController ctl) async {
    final flags = _ref.read(featureFlagsProvider.notifier);
    if (!flags.isEnabled(Feature.gpsTripPath)) return;
    final geolocator = _ref.read(geolocatorWrapperProvider);
    try {
      // #1981 — request foreground location permission up front.
      var permission = await geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      _gpsSub = geolocator
          .getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      )
          .listen(
        (pos) {
          ctl.updateGpsFix(
            latitude: pos.latitude,
            longitude: pos.longitude,
            // #1935 child A — altitude feeds the road-grade calculator.
            altitudeM: pos.altitude,
          );
          // #1458 phase 2 — record one cadence-diagnostic per fix so the
          // user can see, post-trip, whether the OS kept delivering
          // position updates while the phone was asleep / unpinned. The
          // call is cheap (one allocation + one list append, capped) so
          // it's safe on the hot path; the in-memory buffer is flushed
          // onto the persisted [TripHistoryEntry] at trip-stop time.
          ctl.recordGpsSampleDiagnostic(
            now: DateTime.now(),
            lifecycleState: _lifecycleState().name,
          );
          // #1125 phase 3b — opt-in glide-coach evaluation. The hook is
          // gated by:
          //   1. The central Feature.glideCoach flag (default-off in
          //      production), read via glideCoachEnabledProvider.
          //   2. The user-facing toggle GlideCoachSettings.enabled.
          //   3. The presence of a recent throttle reading (cars
          //      without PID 0x11 — or a freshly-started trip whose
          //      first sample hasn't landed — short-circuit to "do
          //      nothing").
          // Both flags must be true for the haptic to fire. See the
          // class doc on `GlideCoachEvaluator` for the 5-rule decision
          // flow that the evaluator itself runs.
          unawaited(_maybeFireGlideCoach(ctl, pos));
        },
        onError: (Object error) {
          debugPrint('TripRecording GPS stream error: $error');
        },
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording GPS subscribe failed'}));
    }
  }

  /// Tear down the Geolocator subscription if one was opened (flag-on
  /// path only). Best-effort: a null sub is the common case (flag off)
  /// and a cancel that throws shouldn't block trip teardown.
  Future<void> stop() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  /// Per-GPS-fix glide-coach evaluator hook (#1125 phase 3b).
  ///
  /// Layered gate (in order — each rejects the next):
  ///   1. The central `Feature.glideCoach` flag (default-off in
  ///      production), read via `glideCoachEnabledProvider`.
  ///   2. User-facing toggle from `GlideCoachSettings`.
  ///   3. Latest throttle reading from the controller's captured-sample
  ///      buffer (cars without PID 0x11 → null → evaluator returns
  ///      `hold` per its rule 2; the haptic does not fire).
  ///   4. Provider returns null (Hive box closed in widget tests, etc.) —
  ///      treat as feature off.
  ///
  /// The evaluator's 5-rule flow then decides between
  /// `lift` / `hold` / `cooldown`. Only `lift` translates into a
  /// `HapticFeedback.lightImpact()` call — "subtle" per the issue body
  /// (#1125), distinct from the medium / heavy intensities used by the
  /// over-throttle eco-coach (#767).
  ///
  /// Errors are caught and logged: a permission revoke mid-trip, an
  /// Overpass timeout, or a stale Hive box must NOT derail the OBD2
  /// recording. Best-effort, non-blocking.
  Future<void> _maybeFireGlideCoach(
    TripRecordingController ctl,
    Position pos,
  ) async {
    // Rule 1 — the central Feature.glideCoach flag (#1824).
    if (!_ref.read(glideCoachEnabledProvider)) return;
    try {
      // Rule 2 — user toggle. Defaults to false; even with the master
      // flag flipped, an opt-in is required.
      final settings = _ref.read(glideCoachSettingsProvider);
      if (!settings.enabled) return;
      // Rule 4 — provider returns null when the feature is fully
      // unavailable (Hive box closed in tests). Resolved AFTER the
      // user-toggle gate so an off-by-default user pays no Hive read.
      final evaluator = _ref.read(glideCoachEvaluatorProvider);
      if (evaluator == null) return;
      // Rule 3 — pull the latest throttle from the controller's
      // captured-sample buffer. The buffer accumulates at 1 Hz (#1040);
      // the GPS listener cadence is set by `LocationAccuracy.high`
      // (typically also ~1 Hz). Cars without PID 0x11 carry
      // `throttlePercent == null` on every sample; the evaluator's
      // rule 2 short-circuits that to `hold` so this getter returning
      // null is fine.
      final samples = ctl.capturedSamples;
      final throttle = samples.isEmpty
          ? null
          : samples.last.throttlePercent;
      final reading = (
        latitude: pos.latitude,
        longitude: pos.longitude,
        headingDegrees: pos.heading,
      );
      final advice = await evaluator.evaluate(
        reading: reading,
        throttlePercent: throttle,
      );
      if (advice == GlideCoachAdvice.lift) {
        // Subtle on purpose — `lightImpact`, not `mediumImpact`. The
        // issue body explicitly calls out distraction risk; the haptic
        // is a hint, not a brake-warning.
        await HapticFeedback.lightImpact();
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording glide-coach evaluation failed'}));
    }
  }
}
