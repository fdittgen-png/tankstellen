import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/storage_keys.dart';
import '../../profile/data/models/user_profile.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
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

/// Settings-box key written once after the legacy
/// `syncBaselinesEnabled` value has been promoted into the central
/// feature-flag set (#1373 phase 3e). Persisted in the same
/// `settings` Hive box as the legacy toggle itself so a single read
/// tells us whether the migration has already run.
const String syncBaselinesMigratedKey = 'syncBaselinesMigrated';

/// Settings-box key written once after the per-vehicle
/// `VehicleProfile.autoRecord` bools have been inspected for the
/// phase-3d wrap migration (#1373 phase 3d). Unlike previous phases
/// this is NOT a 1:1 promotion — the per-vehicle bool STAYS so each
/// vehicle keeps its individual opt-in. We only flip the new central
/// [Feature.autoRecord] master gate to `false` when EVERY existing
/// vehicle had the per-vehicle bool off (an explicit "the user
/// doesn't want auto-record at all" signal). Otherwise the central
/// feature stays at the manifest default of `true` and the per-
/// vehicle bools continue to gate per-vehicle behaviour as before.
const String autoRecordMigratedKey = 'autoRecordMigrated';

/// Settings-box key written once after the legacy
/// `UserProfile.showFuel` value has been promoted into the central
/// feature-flag set (#1373 phase 3c). Persisted in the same `settings`
/// Hive box as the other migration gates so a single read tells us
/// whether the migration has already run.
const String showFuelMigratedKey = 'showFuelMigrated';

/// Settings-box key written once after the legacy
/// `UserProfile.showElectric` value has been promoted into the
/// central feature-flag set (#1373 phase 3c).
const String showElectricMigratedKey = 'showElectricMigrated';

/// Settings-box key written once after the legacy
/// `UserProfile.showConsumptionTab` value has been promoted into the
/// central feature-flag set (#1373 phase 3c). The manifest declares
/// [Feature.showConsumptionTab] as requiring [Feature.obd2TripRecording],
/// so a legacy `true` cascades the prerequisite as well.
const String showConsumptionTabMigratedKey = 'showConsumptionTabMigrated';

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
/// Phase 3f adds [_migrateUnifiedSearchResults] for the
/// settings-box-backed `unifiedSearchResultsEnabled` toggle. It
/// follows the same shape as [_migrateHapticEcoCoach] but with no
/// prerequisites to cascade-enable (the manifest declares no
/// `requires:` for [Feature.unifiedSearchResults]).
///
/// Phase 3e adds [_migrateSyncBaselines] for the
/// settings-box-backed `syncBaselinesEnabled` toggle. The manifest
/// declares [Feature.tankSync] as a hard prerequisite of
/// [Feature.baselineSync], so the cascade promotes BOTH on a legacy
/// `true` (mirroring the haptic precedent's
/// `obd2TripRecording → hapticEcoCoach` cascade).
///
/// Phase 3d (this PR) adds [_migrateAutoRecord] — the FIRST
/// "wrap, not replace" migration. The per-vehicle
/// [VehicleProfile.autoRecord] bool stays: each vehicle keeps its
/// own opt-in. The new [Feature.autoRecord] central feature is a
/// MASTER gate consulted before the per-vehicle bool. The migrator
/// only flips the central feature OFF when EVERY existing vehicle
/// had the per-vehicle bool off (explicit "no auto-record at all"
/// intent); otherwise the central feature stays at the manifest
/// default of `true` and the per-vehicle bools continue to govern
/// per-vehicle behaviour exactly as before. This shape is
/// deliberately NOT the haptic / unified-search precedent — there
/// the legacy field was 1:1 replaced by the central feature, and
/// the legacy field was deprecated. Here the legacy field is the
/// authoritative per-vehicle state and the central feature is a
/// new, additional layer on top.
///
/// Phase status:
///   - 3a hapticEcoCoach (settings-box, default-false) ✅
///   - 3b gamification (UserProfile, default-true) ✅ via
///     [migrateUserProfileToggles]
///   - 3f unifiedSearchResults (settings-box, default-false) ✅
///   - 3e syncBaselines (settings-box, default-false) ✅
///   - 3d autoRecord (per-vehicle, default-true, WRAP not replace) ✅
///   - 3c showFuel + showElectric + showConsumptionTab (UserProfile,
///     bundled phase, default-true) ✅ via [migrateUserProfileToggles]
///
/// Future phases extend this migrator with additional scattered
/// toggles. Each new migration follows the same shape: read the
/// legacy value, gate on a `<featureName>Migrated` flag, force-
/// enable prerequisites first, persist, then write the gate flag.
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
  await _migrateSyncBaselines(
    settings: settings,
    featureFlags: featureFlags,
    manifest: manifest,
  );
  await _migrateAutoRecord(
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
  await _migrateShowFuel(
    settings: settings,
    featureFlags: featureFlags,
    manifest: manifest,
    activeProfile: activeProfile,
  );
  await _migrateShowElectric(
    settings: settings,
    featureFlags: featureFlags,
    manifest: manifest,
    activeProfile: activeProfile,
  );
  await _migrateShowConsumptionTab(
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

Future<void> _migrateSyncBaselines({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
}) async {
  // Already migrated → idempotent no-op. The user may have toggled
  // syncBaselines OFF after a previous migration; we must not
  // re-promote the legacy `true` value.
  if (settings.get(syncBaselinesMigratedKey) == true) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = settings.get(StorageKeys.syncBaselinesEnabled);

  if (legacyValue == true) {
    try {
      final current = await featureFlags.loadEnabled();
      // Force-enable the prerequisite first per the manifest's
      // dependency graph — [Feature.baselineSync] requires
      // [Feature.tankSync], so the cascade promotes both. Without
      // this the central system would refuse the baselineSync enable
      // on its first toggle attempt.
      final entry = manifest.entryFor(Feature.baselineSync);
      final next = <Feature>{
        ...current,
        ...entry.requires,
        Feature.baselineSync,
      };
      await featureFlags.saveEnabled(next);
    } catch (e, st) {
      // Don't block startup on a migration failure — the user can
      // re-toggle from settings if the central state is missing.
      debugPrint(
        'migrateLegacyToggles: syncBaselines promote failed: $e\n$st',
      );
    }
  }

  // Always set the flag (even when legacyValue is false / null) so we
  // never re-read the legacy key on subsequent launches.
  try {
    await settings.put(syncBaselinesMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateLegacyToggles: writing $syncBaselinesMigratedKey failed: $e\n$st',
    );
  }
}

/// Phase-3d wrap migration for the per-vehicle
/// [VehicleProfile.autoRecord] bool (#1373 phase 3d).
///
/// Shape — and the reason it differs from the haptic / unified-search
/// precedent: this migration WRAPS the legacy field rather than
/// replacing it. The per-vehicle bool stays, each vehicle keeps its
/// own opt-in, and the new [Feature.autoRecord] central feature is a
/// master gate consulted before the per-vehicle check. We only flip
/// the central feature OFF when EVERY existing vehicle had the per-
/// vehicle bool off — that's the only signal we can read at migration
/// time that means "user doesn't want auto-record at all". When at
/// least one vehicle has the bool on (or there are no vehicles at
/// all — fresh installs), the central feature stays at the manifest
/// default of `true` so the wrapping is transparent.
///
/// Read path: [VehicleProfileRepository] persists profiles as a List
/// in the same `settings` Hive box under
/// [StorageKeys.vehicleProfiles] (keep this read in lockstep with
/// that repository — if the storage shape ever moves to a dedicated
/// box, this migrator must follow). Each list entry is a
/// JSON-serialised [VehicleProfile] map; we decode it via
/// [VehicleProfile.fromJson] so a future schema bump rides through
/// freezed's `@Default` values without us having to mirror the
/// schema here.
///
/// Idempotent: gated on [autoRecordMigratedKey]. The flag is set on
/// every code path (success, failure, no-vehicles, all-on, all-off,
/// mixed) so a subsequent launch is always a no-op.
Future<void> _migrateAutoRecord({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
}) async {
  // Already migrated → idempotent no-op. Subsequent runs must not
  // re-inspect the per-vehicle bools (the user may have flipped the
  // central feature back on after the initial migration disabled it,
  // and that choice must survive).
  if (settings.get(autoRecordMigratedKey) == true) {
    return;
  }

  bool? allVehiclesAutoRecordFalse;
  try {
    final raw = settings.get(StorageKeys.vehicleProfiles);
    if (raw is List && raw.isNotEmpty) {
      var allFalse = true;
      var anyDecoded = false;
      for (final item in raw) {
        if (item is! Map) continue;
        // VehicleProfile.fromJson expects Map<String, dynamic>; Hive
        // round-trips Map<dynamic, dynamic>, so coerce here.
        final asMap = <String, dynamic>{};
        item.forEach((k, v) {
          if (k is String) asMap[k] = v;
        });
        try {
          final profile = VehicleProfile.fromJson(asMap);
          anyDecoded = true;
          if (profile.autoRecord) {
            allFalse = false;
            break;
          }
        } catch (e, st) {
          // A single malformed row must not block the migration. If
          // every row is malformed [anyDecoded] stays false and we
          // treat it like "no vehicles" (manifest default wins).
          debugPrint(
            'migrateLegacyToggles: skipping malformed vehicle profile '
            'during autoRecord migration: $e\n$st',
          );
        }
      }
      if (anyDecoded) {
        allVehiclesAutoRecordFalse = allFalse;
      }
    }
  } catch (e, st) {
    debugPrint(
      'migrateLegacyToggles: reading vehicle profiles for autoRecord '
      'migration failed: $e\n$st',
    );
  }

  if (allVehiclesAutoRecordFalse == true) {
    // Every existing vehicle had the per-vehicle bool off → user
    // intent is "no auto-record at all". Flip the central master
    // gate off so a future vehicle added with the per-vehicle
    // default-on bool does NOT silently start recording.
    try {
      final current = await featureFlags.loadEnabled();
      final next = {...current}..remove(Feature.autoRecord);
      await featureFlags.saveEnabled(next);
    } catch (e, st) {
      // Don't block startup on a migration failure — the user can
      // re-toggle from settings if the central state is missing.
      debugPrint(
        'migrateLegacyToggles: autoRecord disable failed: $e\n$st',
      );
    }
  }
  // else: allVehiclesAutoRecordFalse == false (at least one vehicle
  // had the bool on — preserve the manifest default-true) OR null
  // (no vehicles or all malformed — manifest default wins; if /
  // when the user adds a vehicle they can flip the central feature
  // off explicitly).

  // Always set the flag so subsequent launches are no-ops.
  try {
    await settings.put(autoRecordMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateLegacyToggles: writing $autoRecordMigratedKey failed: $e\n$st',
    );
  }
}

/// Phase-3c migration for the legacy [UserProfile.showFuel] bool
/// (#1373 phase 3c).
///
/// Mirrors [_migrateGamification]: the manifest defaults
/// [Feature.showFuel] to `true`, so a no-op (no write) on legacy=true
/// would land at the same state. The legacy=false branch is the one
/// that needs an explicit central write — without it the manifest
/// default would silently restore the fuel-stations surface for users
/// who had explicitly turned it off. The migration is gated on
/// [showFuelMigratedKey] and skipped when the active profile is
/// null (next launch retries), preserving the same idempotency
/// contract as the gamification precedent.
Future<void> _migrateShowFuel({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
  required UserProfile? activeProfile,
}) async {
  if (settings.get(showFuelMigratedKey) == true) {
    return;
  }
  if (activeProfile == null) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = activeProfile.showFuel;

  try {
    final current = await featureFlags.loadEnabled();
    if (legacyValue == true) {
      // Manifest default is true — but the persisted set may have been
      // mutated by a previous launch / migration. Re-add to be safe;
      // [Feature.showFuel] has no prerequisites so no cascade needed.
      final next = <Feature>{...current, Feature.showFuel};
      await featureFlags.saveEnabled(next);
    } else {
      // Legacy explicit-false. Without an explicit write the manifest
      // default-true would silently restore the surface for users who
      // deliberately turned it off.
      final next = {...current}..remove(Feature.showFuel);
      await featureFlags.saveEnabled(next);
    }
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: showFuel promote failed: $e\n$st',
    );
  }

  try {
    await settings.put(showFuelMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: writing $showFuelMigratedKey failed: $e\n$st',
    );
  }
}

/// Phase-3c migration for the legacy [UserProfile.showElectric] bool
/// (#1373 phase 3c). Mirrors [_migrateShowFuel] verbatim — same
/// default-true semantics, no manifest prerequisites.
Future<void> _migrateShowElectric({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
  required UserProfile? activeProfile,
}) async {
  if (settings.get(showElectricMigratedKey) == true) {
    return;
  }
  if (activeProfile == null) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = activeProfile.showElectric;

  try {
    final current = await featureFlags.loadEnabled();
    if (legacyValue == true) {
      final next = <Feature>{...current, Feature.showElectric};
      await featureFlags.saveEnabled(next);
    } else {
      final next = {...current}..remove(Feature.showElectric);
      await featureFlags.saveEnabled(next);
    }
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: showElectric promote failed: $e\n$st',
    );
  }

  try {
    await settings.put(showElectricMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: writing $showElectricMigratedKey failed: $e\n$st',
    );
  }
}

/// Phase-3c migration for the legacy [UserProfile.showConsumptionTab]
/// bool (#1373 phase 3c).
///
/// Distinct from [_migrateShowFuel] / [_migrateShowElectric] because
/// the manifest declares [Feature.obd2TripRecording] as a hard
/// prerequisite of [Feature.showConsumptionTab]. The legacy field
/// defaulted to `false` (the user had to explicitly opt in), so the
/// common case is legacy=false → remove the central feature. Legacy=
/// true is the rare case where the user previously enabled the tab;
/// we cascade-enable the OBD2 prerequisite alongside so the central
/// state is dependency-consistent.
Future<void> _migrateShowConsumptionTab({
  required Box<dynamic> settings,
  required FeatureFlagsRepository featureFlags,
  required FeatureManifest manifest,
  required UserProfile? activeProfile,
}) async {
  if (settings.get(showConsumptionTabMigratedKey) == true) {
    return;
  }
  if (activeProfile == null) {
    return;
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyValue = activeProfile.showConsumptionTab;

  try {
    final current = await featureFlags.loadEnabled();
    if (legacyValue == true) {
      // Force-enable the prerequisite first per the manifest's
      // dependency graph — [Feature.showConsumptionTab] requires
      // [Feature.obd2TripRecording], so the cascade promotes both.
      // Without this the persisted set would be in a contract-
      // violating shape (dependent enabled, prerequisite disabled).
      final entry = manifest.entryFor(Feature.showConsumptionTab);
      final next = <Feature>{
        ...current,
        ...entry.requires,
        Feature.showConsumptionTab,
      };
      await featureFlags.saveEnabled(next);
    } else {
      // Legacy explicit-false (the common case — the field defaulted
      // to false and most users never flipped it). Manifest default
      // is true, so a no-op write would silently SHOW the tab for
      // users who never had it on. Persist a state that excludes the
      // feature so the original user-facing shape (tab hidden) is
      // preserved.
      final next = {...current}..remove(Feature.showConsumptionTab);
      await featureFlags.saveEnabled(next);
    }
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: showConsumptionTab promote failed: $e\n$st',
    );
  }

  try {
    await settings.put(showConsumptionTabMigratedKey, true);
  } catch (e, st) {
    debugPrint(
      'migrateUserProfileToggles: writing $showConsumptionTabMigratedKey failed: $e\n$st',
    );
  }
}
