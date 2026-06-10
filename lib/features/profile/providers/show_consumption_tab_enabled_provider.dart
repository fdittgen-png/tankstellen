// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';

part 'show_consumption_tab_enabled_provider.g.dart';

/// Visibility gate for the consumption analytics tab in the bottom
/// navigation (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showConsumptionTab].
/// The legacy `UserProfile.showConsumptionTab` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showConsumptionTabMigratedKey` flag in the settings
/// box) and promoted into the central set; subsequent reads/writes go
/// through here.
///
/// The manifest defaults [Feature.showConsumptionTab] to `true` with
/// `requires: {Feature.obd2TripRecording}`. Because `obd2TripRecording`
/// defaults to `false`, the consumption tab is effectively hidden on
/// fresh installs until the user enables trip recording — matching
/// the original user-facing shape where the legacy field defaulted to
/// `false`.
///
/// Consumers wrap their consumption-tab UI with:
/// ```dart
/// if (!ref.watch(showConsumptionTabEnabledProvider)) {
///   // hide the bottom-nav tab, route entry, etc.
/// }
/// ```
@Riverpod(keepAlive: true)
class ShowConsumptionTabEnabled extends _$ShowConsumptionTabEnabled
    with FeatureToggleNotifier {
  @override
  Feature get feature => Feature.showConsumptionTab;

  /// When `obd2TripRecording` (the parent) is off, the consumption tab
  /// is hidden from the bottom-nav regardless of the stored value; the
  /// user's tab-visibility preference is preserved so re-enabling trip
  /// recording restores the prior layout (#1447). Build + `set` live in
  /// [FeatureToggleNotifier] (#3175).
  @override
  bool build() => buildFromFeatureFlags();
}
