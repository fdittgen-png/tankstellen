import '../../../core/storage/storage_keys.dart';
import '../domain/entities/reference_vehicle.dart';
import '../domain/entities/vehicle_profile.dart';
import 'vehicle_profile_catalog_matcher.dart';

/// Result of a catalog re-resolve check for a single profile (#1396).
///
/// Carries only the fields the snackbar host needs to render the
/// nudge — the full [VehicleProfile] is intentionally not exposed so
/// the detector stays a pure function on the data layer.
class CatalogReresolveCandidate {
  /// Profile identifier — used both for the Hive flag suffix and as
  /// the route extra when the user taps the snackbar.
  final String vehicleId;

  /// Marketing brand, e.g. "Dacia". Empty string when the underlying
  /// profile has no `make` (defensive — the detector skips those, but
  /// the field is non-null on the public type for ergonomics).
  final String make;

  /// Model name, e.g. "Duster". Same caveat as [make].
  final String model;

  /// Slug of the petrol catalog row the profile currently resolves to.
  /// Surfaced so the snackbar can tell the user which entry it found.
  final String resolvedReferenceVehicleId;

  /// Fuel type of the resolved catalog entry — typically "petrol", but
  /// the detector also flags "hybrid" mismatches, so this is exposed
  /// rather than hardcoded.
  final String resolvedFuelType;

  const CatalogReresolveCandidate({
    required this.vehicleId,
    required this.make,
    required this.model,
    required this.resolvedReferenceVehicleId,
    required this.resolvedFuelType,
  });
}

/// Pure detector for the #1396 one-time catalog-mismatch nudge.
///
/// Scans every [VehicleProfile] and surfaces those where the user
/// configured a diesel `preferredFuelType` but the profile's
/// `referenceVehicleId` resolves to a non-diesel catalog row — i.e.
/// the user has a diesel car but the matcher pinned them to a petrol
/// or hybrid entry, which causes the OBD-II fuel-rate pipeline to
/// inherit petrol AFR / density / displacement and undercount fuel
/// economy by 4-5x on MAF / speed-density branches.
///
/// The historical example: a 1.5 dCi Duster that shipped before this
/// PR's catalog split would resolve to `dacia-duster-ii-2017-`
/// (petrol TCe 130). Once the new diesel sibling lands, the nudge
/// invites the user to re-pick their catalog row.
///
/// Per-vehicle dedupe lives in Hive via [StorageKeys.vehicleCatalogReresolveSuggestedPrefix].
/// The detector itself is pure — callers feed in a flag-getter
/// closure and receive back the vehicles that should produce a
/// snackbar this launch. The corresponding flag-setter is invoked by
/// the snackbar host once the nudge has actually been surfaced.
class CatalogReresolveDetector {
  const CatalogReresolveDetector._();

  /// Builds the Hive flag key that gates the per-vehicle nudge.
  ///
  /// Exposed so the snackbar host (which writes the flag once it
  /// surfaces the snackbar) shares a single source of truth with the
  /// detector (which reads it).
  static String flagKeyFor(String vehicleId) =>
      '${StorageKeys.vehicleCatalogReresolveSuggestedPrefix}$vehicleId';

  /// Returns the list of profiles that need a re-resolve nudge.
  ///
  /// Inputs:
  ///
  ///   - [profiles]: every [VehicleProfile] currently stored. The
  ///     detector skips any without a populated `referenceVehicleId`
  ///     (no catalog match means there's nothing to "re-pick") and
  ///     any whose `preferredFuelType` is not diesel (only diesel
  ///     mismatches are interesting for #1396 — a petrol user who
  ///     resolved to a hybrid entry can be addressed in a follow-up).
  ///   - [catalog]: the bundled reference catalog list, typically
  ///     read from [referenceVehicleCatalogProvider].
  ///   - [hasFlagFor]: closure that returns true when the per-vehicle
  ///     "already nudged" Hive flag is set. The detector treats those
  ///     vehicles as already-handled and excludes them from the
  ///     output, so the nudge fires at most once per vehicle.
  ///
  /// Output ordering matches the input profile order so the caller
  /// can rely on a deterministic snackbar sequence in tests.
  static List<CatalogReresolveCandidate> findCandidates({
    required List<VehicleProfile> profiles,
    required List<ReferenceVehicle> catalog,
    required bool Function(String vehicleId) hasFlagFor,
  }) {
    final candidates = <CatalogReresolveCandidate>[];
    for (final profile in profiles) {
      final refId = profile.referenceVehicleId;
      if (refId == null || refId.isEmpty) continue;

      final fuel = profile.preferredFuelType?.toLowerCase() ?? '';
      if (!fuel.contains('diesel')) continue;

      // Already nudged this vehicle — skip even if the mismatch is
      // still present (the user dismissed the snackbar).
      if (hasFlagFor(profile.id)) continue;

      // Resolve the catalog entry by slug. Drop the profile if the
      // slug points at nothing — that's a catalog-rebuild stale-
      // pointer case, not a re-resolve case, and a follow-up
      // migrator should handle it.
      ReferenceVehicle? resolved;
      for (final entry in catalog) {
        if (VehicleProfileCatalogMatcher.slugFor(entry) == refId) {
          resolved = entry;
          break;
        }
      }
      if (resolved == null) continue;

      // The interesting case: user says diesel, catalog says
      // anything-but-diesel. Petrol is the dominant gap (#1396), but
      // a profile resolved to a hybrid or electric entry is also a
      // mismatch worth nudging.
      if (resolved.fuelType.toLowerCase() == 'diesel') continue;

      candidates.add(CatalogReresolveCandidate(
        vehicleId: profile.id,
        make: profile.make ?? '',
        model: profile.model ?? '',
        resolvedReferenceVehicleId: refId,
        resolvedFuelType: resolved.fuelType,
      ));
    }
    return candidates;
  }
}
