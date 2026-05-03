import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/storage_keys.dart';
import '../domain/feature.dart';
import '../domain/feature_manifest.dart';
import 'feature_flags_repository.dart';

/// Settings-box key written once after the legacy `hapticEcoCoachEnabled`
/// value has been promoted into the central feature-flag set (#1373
/// phase 3a). Persisted in the same `settings` Hive box as the legacy
/// toggle itself so a single read tells us whether the migration has
/// already run.
const String hapticEcoCoachMigratedKey = 'hapticEcoCoachMigrated';

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
/// Future phases (3b, 3c, …) extend this migrator with additional
/// scattered toggles (`gamificationEnabled`, `showFuel`, `autoRecord`,
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
