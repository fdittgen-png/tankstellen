// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';

part 'gamification_enabled_provider.g.dart';

/// Master gate for gamification surfaces (#1194).
///
/// As of #1373 phase 3b this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.gamification]. The legacy `UserProfile.gamificationEnabled`
/// field is read once by `legacyToggleMigrationProvider` on first
/// launch after upgrade (gated on a `gamificationMigratedKey` flag in
/// the settings box) and promoted into the central set; subsequent
/// reads/writes go through here.
///
/// The manifest defaults [Feature.gamification] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `gamificationEnabled = false` keep
/// their preference because the migrator preserves the explicit-false
/// value through the gate.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.
@Riverpod(keepAlive: true)
class GamificationEnabled extends _$GamificationEnabled
    with FeatureToggleNotifier {
  @override
  Feature get feature => Feature.gamification;

  /// Disabling the parent (`obd2TripRecording`) hides the gamification
  /// UI without touching the user's gamification preference;
  /// re-enabling the parent restores it (#1447). Build + `set` live in
  /// [FeatureToggleNotifier] (#3175).
  @override
  bool build() => buildFromFeatureFlags();
}
