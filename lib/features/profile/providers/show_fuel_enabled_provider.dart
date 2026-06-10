// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';

part 'show_fuel_enabled_provider.g.dart';

/// Visibility gate for fuel-station results in search and on the map
/// (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showFuel]. The legacy
/// `UserProfile.showFuel` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showFuelMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showFuel] to `true`, so fresh-install
/// users see the same behaviour they had before this migration. Users
/// who had toggled `showFuel = false` keep their preference because
/// the migrator preserves the explicit-false value through the gate.
///
/// Consumers wrap their fuel-station UI with:
/// ```dart
/// if (!ref.watch(showFuelEnabledProvider)) {
///   // hide fuel station chips, results, map markers …
/// }
/// ```
@Riverpod(keepAlive: true)
class ShowFuelEnabled extends _$ShowFuelEnabled with FeatureToggleNotifier {
  @override
  Feature get feature => Feature.showFuel;

  /// `Feature.showFuel` has no `requires` today so the effective gate
  /// short-circuits to a plain `contains` check. Build + `set` live in
  /// [FeatureToggleNotifier] (#3175).
  @override
  bool build() => buildFromFeatureFlags();
}
