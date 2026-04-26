import 'package:flutter/foundation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/entities/reference_vehicle.dart';
import '../domain/entities/vehicle_profile.dart';
import 'repositories/vehicle_profile_repository.dart';
import 'vehicle_profile_catalog_matcher.dart';

/// One-shot migrator that backfills [VehicleProfile.referenceVehicleId]
/// for profiles created before the catalog existed (#950 phase 4).
///
/// Runs at app startup, after Hive opens and the reference catalog
/// asset is loaded. Once successful, the [StorageKeys.vehicleCatalogMigrationDone]
/// flag is flipped so subsequent launches skip straight through.
///
/// Failure modes are swallowed and `debugPrint`ed: this migrator must
/// never block startup. A profile that fails to match is left with a
/// `null` `referenceVehicleId` and the OBD-II layer falls back to its
/// generic behaviour — exactly the pre-#950 path.
class VehicleProfileCatalogMigrator {
  final VehicleProfileRepository _repository;
  final SettingsStorage _settings;

  VehicleProfileCatalogMigrator({
    required VehicleProfileRepository repository,
    required SettingsStorage settings,
  })  : _repository = repository,
        _settings = settings;

  /// True when the migration flag has been persisted in settings.
  bool get hasRun =>
      (_settings.getSetting(StorageKeys.vehicleCatalogMigrationDone)
              as bool?) ==
          true;

  /// Run the migration once and mark it as done.
  ///
  /// Returns the number of profiles that received a non-null
  /// `referenceVehicleId`. Profiles that already had a value (e.g.
  /// from a prior run, a sync, or a user edit) are left alone.
  Future<int> run({required List<ReferenceVehicle> catalog}) async {
    if (hasRun) {
      return 0;
    }

    var matched = 0;
    try {
      final profiles = _repository.getAll();
      for (final profile in profiles) {
        // Already pinned to a catalog entry — nothing to do.
        if (profile.referenceVehicleId != null &&
            profile.referenceVehicleId!.isNotEmpty) {
          continue;
        }

        final match = VehicleProfileCatalogMatcher.bestMatch(
          profile: profile,
          catalog: catalog,
        );
        if (match == null) continue;

        final slug = VehicleProfileCatalogMatcher.slugFor(match);
        final updated = profile.copyWith(referenceVehicleId: slug);
        await _repository.save(updated);
        matched++;
      }
    } catch (e, st) {
      // Don't bubble — startup must keep going.
      debugPrint('VehicleProfileCatalogMigrator: run failed: $e\n$st');
    }

    // Always mark done, even if we matched zero. A user who has only
    // EV-only profiles (no make set) doesn't need to re-run this every
    // launch hoping they suddenly populate make/model.
    try {
      await _settings.putSetting(
        StorageKeys.vehicleCatalogMigrationDone,
        true,
      );
    } catch (e, st) {
      debugPrint('VehicleProfileCatalogMigrator: failed to set done flag: $e\n$st');
    }

    return matched;
  }
}
