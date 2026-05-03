import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/storage_keys.dart';
import '../../profile/data/models/user_profile.dart';
import '../domain/feature.dart';
import '../domain/feature_manifest.dart';
import 'feature_flags_repository.dart';

/// Settings-box key written once after the legacy `hapticEcoCoachEnabled`
/// value has been promoted into the central feature-flag set (#1373
/// phase 3a). Persisted in the same `settings` Hive box as the legacy
/// toggle itself so a single read tells us whether the migration has
/// already run.
const String hapticEcoCoachMigratedKey = 'hapticEcoCoachMigrated';

/// Settings-box key written once after the legacy
/// `UserProfile.gamificationEnabled` value has been promoted into the
/// central feature-flag set (#1373 phase 3b). Persisted in the same
/// `settings` Hive box as the haptic-eco-coach gate so a single read
/// tells us whether the gamification migration has already run.
const String gamificationMigratedKey = 'gamificationMigrated';

/// Settings-box key written once after the legacy
/// `unifiedSearchResultsEnabled` value has been promoted into the
/// central feature-flag set (#1373 phase 3f). Persisted in the same
/// `settings` Hive box as the legacy toggle itself so a single read
/// tells us whether the migration has already run.
const String unifiedSearchResultsMigratedKey = 'unifiedSearchResultsMigrated';

/// One-shot migrator that promotes legacy scattered toggles into the
/// central [FeatureFlagsRepository] (#1373 phase 3a).
///
/// Reads the legacy [StorageKeys.hapticEcoCoachEnabled] value from the
/// passed-in `settings` box. If it was `true` AND the migration has
/// not yet run, force-enables [Feature.obd2TripRecording] (the
/// manifest-declared prerequisite of [Feature.hapticEcoCoach]) and
/// then enables [Feature.hapticEcoCoach], persisting the resulting
/// set via [FeatureFlagsRepository.saveEnabled]. The
/// [hapticEcoCoachMigratedKey] flag is then written so subsequent
/// runs are no-ops.
///
/// Idempotent — re-running after the flag is set is a single Hive
/// read with no writes. Safe to call from a `Future.microtask` on
/// app-startup providers without blocking.
///
/// As of phase 3b a parallel entry point [migrateUserProfileToggles]
/// handles UserProfile-backed legacy toggles (the
/// `UserProfile.gamificationEnabled` field). The shape mirrors this
/// function but takes the active profile as an extra (nullable) input
/// because the legacy value lives on the profile entity rather than
/// the settings box.
///
/// Phase 3f (this PR) adds [_migrateUnifiedSearchResults] for the
/// settings-box-backed `unifiedSearchResultsEnabled` toggle. It
/// follows the same shape as [_migrateHapticEcoCoach] but with no
/// prerequisites to cascade-enable (the manifest declares no
/// `requires:` for [Feature.unifiedSearchResults]).
///
/// Phase status:
///   - 3a hapticEcoCoach (settings-box, default-false) ✅
///   - 3b gamification (UserProfile, default-true) ✅ via
///     [migrateUserProfileToggles]
///   - 3f unifiedSearchResults (settings-box, default-false) ✅
///
/// Future phases (3c, 3d, 3e) extend this migrator with additional
/// scattered toggles (`showFuel`, `autoRecord`, `syncBaselinesEnabled`,
/// etc.). Each new migration follows the same shape: read the legacy
/// value, gate on a `<featureName>Migrated` flag, force-enable
/// prerequisites first, persist, then write the gate flag.
Future<void> migrateLegacyToggles({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
}) async {
  await _migrateHapticEcoCoach(
    settings: settings,
    featureFlags: featureFlags,
    manifest: manifest,
  );
  await _migrateUnifiedSearchResults(
    settings: settings,
    featureFlags: featureFlags,
    manifest: manifest,
  );
}

/// One-shot migrator for UserProfile-backed legacy toggles (#1373
/// phase 3b).
///
/// Reads the legacy [UserProfile.gamificationEnabled] value from the
/// passed-in [activeProfile]. The migrator is a no-op when [activeProfile]
/// is null — the next launch will retry; idempotency is preserved by
/// NOT writing the migrated-key flag in that case.
///
/// When a profile is present and the [gamificationMigratedKey] flag has
/// not yet been written, the migrator promotes the legacy value into
/// the central feature-flag set:
///   - legacy true  → cascade-enable [Feature.obd2TripRecording]
///                    (the manifest prerequisite) and [Feature.gamification]
///   - legacy false → persist a state that EXCLUDES [Feature.gamification]
///                    so the user's explicit opt-out survives. Without
///                    this branch the manifest default (gamification=true)
///                    would silently restore the surfaces the user
///                    deliberately turned off.
/// In both cases the [gamificationMigratedKey] gate is then set so
/// subsequent runs are no-ops.
///
/// Safe to call alongside [migrateLegacyToggles] from the same provider
/// (see `legacyToggleMigrationProvider`). The two functions touch
/// disjoint settings-box keys.
Future<void> migrateUserProfileToggles({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
  required UserProfile? activeProfile,
}) async {
  await _migrateGamification(
    settings: settings,
    featureFlags: featureFlags,
    manifest: manifest,
    activeProfile: activeProfile,
  );
}

Future<void> _migrateHapticEcoCoach({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
}) async {
  // Already migrated → idempotent no-op. The user may have toggled
  // hapticEcoCoach OFF after a previous migration; we must not
  // re-promote the legacy `true` value.
  if (settings.get(hapticEcoCoachMigratedKey) == true) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = settings.get(StorageKeys.hapticEcoCoachEnabled);

  if (legacyValue == true) {
    try {
      final current = await featureFlags.loadEnabled();
      // Force-enable the prerequisite first per the manifest's
      // dependency graph — otherwise the central system would refuse
      // the hapticEcoCoach enable on its first toggle attempt.
      final entry = manifest.entryFor(Feature.hapticEcoCoach);
      final next = <Feature>{
        ...current,
        ...entry.requires,
        Feature.hapticEcoCoach,
      };
      await featureFlags.saveEnabled(next);
    } catch (e, st) {
      // Don't block startup on a migration failure — the user can
      // re-toggle from settings if the central state is missing.
      debugPrint('migrateLegacyToggles: hapticEcoCoach promote failed: $e\n$st');
    }
  }

  // Always set the flag (even when legacyValue is false / null) so we
  // never re-read the legacy key on subsequent launches.
  try {
    await settings.put(hapticEcoCoachMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateLegacyToggles: writing $hapticEcoCoachMigratedKey failed: $e\n$st',
    );
  }
}

Future<void> _migrateGamification({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
  required UserProfile? activeProfile,
}) async {
  // Already migrated → idempotent no-op. The user may have toggled
  // gamification OFF after a previous migration; we must not re-promote
  // the legacy `true` value.
  if (settings.get(gamificationMigratedKey) == true) {
    return;
  }

  // No profile loaded yet → try again next launch. We deliberately do
  // NOT write the gate flag because that would lock in the manifest
  // default and silently discard any explicit `gamificationEnabled =
  // false` the user had set.
  if (activeProfile == null) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = activeProfile.gamificationEnabled;

  try {
    final current = await featureFlags.loadEnabled();
    if (legacyValue == true) {
      // Force-enable the prerequisite first per the manifest's
      // dependency graph — otherwise the central system would refuse
      // the gamification enable on its first toggle attempt.
      final entry = manifest.entryFor(Feature.gamification);
      final next = <Feature>{
        ...current,
        ...entry.requires,
        Feature.gamification,
      };
      await featureFlags.saveEnabled(next);
    } else {
      // Legacy explicit-false. Feature.gamification's manifest default
      // is `true`, so a no-op (no write) would silently RESTORE the
      // gamification surfaces for users who had explicitly opted out.
      // Persist the current set with gamification removed so the
      // user's preference survives the migration.
      final next = {...current}..remove(Feature.gamification);
      await featureFlags.saveEnabled(next);
    }
  } catch (e, st) {
    // Don't block startup on a migration failure — the user can
    // re-toggle from settings if the central state is missing.
    debugPrint(
      'migrateUserProfileToggles: gamification promote failed: $e\n$st',
    );
  }

  // Always set the flag (even when the persistence above failed) so we
  // never re-read the legacy field on subsequent launches.
  try {
    await settings.put(gamificationMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: writing $gamificationMigratedKey failed: $e\n$st',
    );
  }
}

Future<void> _migrateUnifiedSearchResults({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
}) async {
  // Already migrated → idempotent no-op. The user may have toggled
  // unifiedSearchResults OFF after a previous migration; we must not
  // re-promote the legacy `true` value.
  if (settings.get(unifiedSearchResultsMigratedKey) == true) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = settings.get(StorageKeys.unifiedSearchResultsEnabled);

  if (legacyValue == true) {
    try {
      final current = await featureFlags.loadEnabled();
      // Force-enable any manifest-declared prerequisites first per the
      // dependency graph. [Feature.unifiedSearchResults] currently has
      // none, so this reduces to {...current, Feature.unifiedSearchResults},
      // but we keep the spread for symmetry with the precedent — if the
      // manifest later adds a requirement it won't silently break.
      final entry = manifest.entryFor(Feature.unifiedSearchResults);
      final next = <Feature>{
        ...current,
        ...entry.requires,
        Feature.unifiedSearchResults,
      };
      await featureFlags.saveEnabled(next);
    } catch (e, st) {
      // Don't block startup on a migration failure — the user can
      // re-toggle from settings if the central state is missing.
      debugPrint(
        'migrateLegacyToggles: unifiedSearchResults promote failed: $e\n$st',
      );
    }
  }

  // Always set the flag (even when legacyValue is false / null) so we
  // never re-read the legacy key on subsequent launches.
  try {
    await settings.put(unifiedSearchResultsMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateLegacyToggles: writing $unifiedSearchResultsMigratedKey failed: $e\n$st',
    );
  }
}
