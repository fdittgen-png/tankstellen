import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../profile/providers/profile_provider.dart';
import '../data/legacy_toggle_migrator.dart';
import 'feature_flags_provider.dart';

part 'legacy_toggle_migration_provider.g.dart';

/// Hive box name for the app `settings` store. Hard-coded here rather
/// than imported from `lib/core/storage/hive_boxes.dart` because the
/// coordinator's hot-file list flags `hive_boxes.dart` as off-limits
/// for #1373 phase-3 PRs — the value `'settings'` is stable since the
/// box was first introduced.
const String _settingsBoxName = 'settings';

/// One-shot Riverpod hook that runs the legacy-toggle migrators once
/// after app startup (#1373 phase 3a + 3b).
///
/// Returns a [Future] that completes when both migrations finish (or
/// resolves immediately to `null` when either the settings box or the
/// central feature-flags repository is not yet available — in tests
/// without Hive, or before [HiveBoxes.init] runs in production).
///
/// Two migrators run in sequence:
///   1. [migrateLegacyToggles] — settings-box-backed legacy keys
///      (currently `hapticEcoCoachEnabled`).
///   2. [migrateUserProfileToggles] — UserProfile-backed legacy fields
///      (currently `gamificationEnabled`). This migrator is a no-op
///      when the active profile has not loaded yet; it re-runs on
///      subsequent launches until a profile is available, and only
///      then writes the per-feature `*Migrated` gate flag.
///
/// Each migration is idempotent and gated on its own
/// `*Migrated` flag, so re-firing this provider in tests / hot-reload
/// is safe.
///
/// `keepAlive: true` so the migration runs at most once per app
/// lifetime — Riverpod will not rebuild the provider unless one of
/// its dependencies changes (in this case, `featureFlagsRepository`
/// or `activeProfile`, both of which are `keepAlive`).
///
/// Wiring: any provider / widget can `ref.watch(...)` this to
/// guarantee the migrations have run before they read
/// [featureFlagsProvider]. As of the post-#1421 follow-up, the
/// app-init path also kicks the provider's future in a post-first-frame
/// microtask (see `app_initializer.dart` — phase 4 deferred work) so
/// migrations run on every cold start instead of only the first time
/// the user navigates to the feature-flags screen.
@Riverpod(keepAlive: true)
Future<void> legacyToggleMigration(Ref ref) async {
  final featureFlags = ref.watch(featureFlagsRepositoryProvider);
  if (featureFlags == null) {
    // Hive not initialised → nothing to migrate. Tests that don't
    // open the feature_flags box take this path and the provider
    // resolves immediately.
    return;
  }
  if (!Hive.isBoxOpen(_settingsBoxName)) {
    // Settings box absent → can't read the legacy toggle. This is the
    // expected path in pre-Hive tests; production opens the box well
    // before any UI reads this provider.
    return;
  }
  final settings = Hive.box<dynamic>(_settingsBoxName);
  final manifest = ref.read(featureManifestProvider);
  final activeProfile = ref.watch(activeProfileProvider);

  // Defer the actual migration to the next microtask so this
  // provider's `build` returns fast and any synchronous reads of
  // [featureFlagsProvider] inside the same frame don't race the
  // promotion write.
  await Future<void>.microtask(() async {
    try {
      await migrateLegacyToggles(
        settings: settings,
        featureFlags: featureFlags,
        manifest: manifest,
      );
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: featureFlags,
        manifest: manifest,
        activeProfile: activeProfile,
      );
    } catch (e, st) {
      // Failure is non-fatal — the central state stays at manifest
      // defaults and the user can re-enable from the settings UI.
      debugPrint('legacyToggleMigration failed: $e\n$st');
    }
  });
}
