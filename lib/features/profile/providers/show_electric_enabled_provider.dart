// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';

part 'show_electric_enabled_provider.g.dart';

/// Visibility gate for EV charging-station results in search and on
/// the map (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showElectric]. The
/// legacy `UserProfile.showElectric` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showElectricMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showElectric] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `showElectric = false` keep their
/// preference because the migrator preserves the explicit-false value
/// through the gate.
///
/// Consumers wrap their EV-station UI with:
/// ```dart
/// if (!ref.watch(showElectricEnabledProvider)) {
///   // hide EV chips, charging-station results, map markers …
/// }
/// ```
@Riverpod(keepAlive: true)
class ShowElectricEnabled extends _$ShowElectricEnabled
    with FeatureToggleNotifier {
  @override
  Feature get feature => Feature.showElectric;

  /// `Feature.showElectric` has no `requires` today so the effective
  /// gate short-circuits to a plain `contains` check. Build + `set`
  /// live in [FeatureToggleNotifier] (#3175).
  @override
  bool build() => buildFromFeatureFlags();
}
