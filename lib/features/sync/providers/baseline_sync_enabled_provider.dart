// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';

part 'baseline_sync_enabled_provider.g.dart';

/// Persisted opt-in switch for per-vehicle driving-baseline sync via
/// TankSync (#780). As of #1373 phase 3e this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.baselineSync]. The legacy
/// [StorageKeys.syncBaselinesEnabled] Hive-settings key is read once
/// by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// [Feature.baselineSync] declares [Feature.tankSync] as a hard
/// prerequisite in the manifest, so a `set(true)` will fail unless
/// `tankSync` is already enabled (the migrator cascade-enables both).
/// The settings UI is expected to pre-check `canEnable` before invoking
/// the setter; the defensive `on StateError` catch below is a backstop
/// for programmatic callers that bypass that guard.
///
/// `keepAlive: true` so a flush at the end of a trip (which reads this
/// provider one-shot via `ref.read`) observes the same notifier as the
/// settings screen that flipped it.
@Riverpod(keepAlive: true)
class BaselineSyncEnabled extends _$BaselineSyncEnabled
    with FeatureToggleNotifier {
  @override
  Feature get feature => Feature.baselineSync;

  /// When `tankSync` (the parent) is off, this surfaces as `false`
  /// regardless of the stored value (#1447) — the trip-flush hook reads
  /// this via `ref.read` at flush time and skips the upload when the
  /// parent is gone. Build + `set` live in [FeatureToggleNotifier]
  /// (#3175).
  @override
  bool build() => buildFromFeatureFlags();
}
