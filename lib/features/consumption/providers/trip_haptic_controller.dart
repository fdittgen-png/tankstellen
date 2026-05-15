import 'package:flutter/services.dart';

import '../domain/cold_start_baselines.dart';
import 'haptic_feedback_policy.dart';

/// Owns the #767 band-transition haptic concern, extracted from the
/// [TripRecording] notifier (#1679).
///
/// Fires a short corrective vibration when the live consumption band
/// crosses *into* heavy territory. Positive improvements (e.g.
/// normal → eco) stay silent so the haptic is a nudge, not constant
/// feedback — the policy decision itself lives in the pure
/// [hapticForBandTransition] function.
///
/// The two counters are bumped alongside the real platform call so
/// tests can assert on haptic intent without hooking the platform
/// channel; counting here does not short-circuit the device vibration.
class TripHapticController {
  int _lightCount = 0;
  int _mediumCount = 0;

  /// Number of light-impact haptics fired since this controller was
  /// constructed. Surfaced through [TripRecording.hapticLightCount].
  int get lightCount => _lightCount;

  /// Number of medium-impact haptics fired since this controller was
  /// constructed. Surfaced through [TripRecording.hapticMediumCount].
  int get mediumCount => _mediumCount;

  /// Fire the haptic (if any) for a [previous] → [current] band
  /// transition. Equal bands and positive transitions are no-ops.
  void fireForBandTransition(
    ConsumptionBand previous,
    ConsumptionBand current,
  ) {
    switch (hapticForBandTransition(previous, current)) {
      case HapticIntensity.light:
        _lightCount++;
        HapticFeedback.lightImpact();
      case HapticIntensity.medium:
        _mediumCount++;
        HapticFeedback.mediumImpact();
      case HapticIntensity.none:
        break;
    }
  }
}
