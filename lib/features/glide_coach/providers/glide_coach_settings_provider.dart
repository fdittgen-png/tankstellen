import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/traffic_signal_repository.dart';
import '../domain/entities/glide_coach_settings.dart';

part 'glide_coach_settings_provider.g.dart';

/// Persisted user toggle for the glide-coach feature (#1125 phase 3b).
///
/// Stored as a single boolean in `SharedPreferences` rather than Hive —
/// the value is device-local (not profile-bound), tiny, and read on
/// startup before any feature-bound Hive box is open. The pattern
/// mirrors `themeModeSettingProvider` (#752) — the closest sibling
/// notifier in this repo that backs a single device-local preference
/// onto SharedPreferences via async load + write-through `set`.
///
/// ### Layered gate (master flag + user toggle)
///
/// The feature has TWO independent off-switches that must both be true
/// before any haptic fires:
///
///   1. The compile-time master flag
///      [`kGlideCoachEnabled`](../data/traffic_signal_repository.dart) —
///      a hard kill-switch baked into the build. False in production
///      today; flipping requires a code change + ship cycle.
///   2. The user-facing toggle, surfaced as
///      [`GlideCoachSettings.enabled`] and persisted by this notifier.
///
/// This notifier respects the master flag: when `kGlideCoachEnabled`
/// is false, the resulting `enabled` value is forced to `false` even
/// if the persisted user toggle is `true`. That guarantees a stale
/// debug-build write (or a malicious / future schema change) cannot
/// leak the feature on in production. The user toggle is layered on
/// top of the master flag — never below it.
///
/// `setEnabled(true)` will still WRITE to SharedPreferences when
/// `kGlideCoachEnabled` is false (the value is preserved across builds
/// so a future master-flag flip does not silently lose the user's
/// historical opt-in), but the in-memory state stays gated.
///
/// `setThrottleThreshold` and `setCooldown` are deliberately
/// out-of-scope for this PR — the only UI surface in phase 3b is the
/// `enabled` toggle. The fields stay on the value type so future
/// phases can grow the notifier without a schema rewrite.
@Riverpod(keepAlive: true)
class GlideCoachSettingsNotifier extends _$GlideCoachSettingsNotifier {
  /// Versioned storage key. Versioned (`v1`) so a future schema
  /// change can introduce a v2 without colliding with stale values.
  @visibleForTesting
  static const String prefsKey = 'settings.glideCoach.enabled.v1';

  @override
  GlideCoachSettings build() {
    _load();
    return const GlideCoachSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(prefsKey) ?? false;
      // Master-flag wins over the persisted user toggle. See the class
      // doc for the layered-gate rationale.
      final effective = kGlideCoachEnabled ? stored : false;
      if (effective != state.enabled) {
        state = state.copyWith(enabled: effective);
      }
    } catch (e, st) {
      debugPrint('GlideCoachSettingsNotifier._load failed: $e\n$st');
    }
  }

  /// Flip the user-facing `enabled` toggle.
  ///
  /// Persists the requested value to SharedPreferences unconditionally
  /// — preserving the user's historical opt-in across master-flag
  /// flips — but the in-memory `enabled` is gated by
  /// [`kGlideCoachEnabled`]. With the master flag false (production
  /// today) `state.enabled` stays `false` even after `setEnabled(true)`,
  /// matching the layered-gate contract documented on the class.
  Future<void> setEnabled(bool value) async {
    final effective = kGlideCoachEnabled ? value : false;
    state = state.copyWith(enabled: effective);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (e, st) {
      debugPrint('GlideCoachSettingsNotifier.setEnabled failed: $e\n$st');
    }
  }
}
