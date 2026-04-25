import '../domain/entities/reference_vehicle.dart';
import '../domain/entities/vehicle_profile.dart';

/// Pure utility for matching a [VehicleProfile] against the
/// [ReferenceVehicle] catalog (#950 phase 4).
///
/// The match is best-effort and tiered so a partial profile (e.g. a
/// VIN-decoded entry that knows the make + model but the year is wrong
/// or out of range) can still benefit from catalog-driven defaults.
///
/// Tiers, in priority order:
///
///   1. **Exact** — make, model, AND year all match. The catalog entry's
///      production window covers the profile year.
///   2. **Make + model** — same make + model regardless of year. Returns
///      the first catalog row that matches.
///   3. **Make only** — same make, any model. Returns the first catalog
///      row for the brand. Better than nothing for OBD-II PID strategy
///      dispatch since most quirks (e.g. PSA UDS, VAG UDS) are make-wide.
///
/// Returns `null` when no tier matches — the migrator persists the null
/// `referenceVehicleId` and the OBD-II layer falls back to its generic
/// behaviour.
class VehicleProfileCatalogMatcher {
  const VehicleProfileCatalogMatcher._();

  /// Returns the best [ReferenceVehicle] for [profile] using the catalog
  /// in [catalog], or `null` when nothing matches.
  ///
  /// Match is case-insensitive on `make` and `model`. A profile without
  /// a `make` field (e.g. an EV-only profile that never went through
  /// the VIN flow) returns `null` immediately — there's nothing to
  /// match on.
  static ReferenceVehicle? bestMatch({
    required VehicleProfile profile,
    required List<ReferenceVehicle> catalog,
  }) {
    final make = profile.make?.trim();
    if (make == null || make.isEmpty) return null;

    final model = profile.model?.trim();
    final year = profile.year;
    final lcMake = make.toLowerCase();
    final lcModel = model?.toLowerCase();

    // Tier 1 — exact make + model + year (when both model and year are
    // populated).
    if (lcModel != null && lcModel.isNotEmpty && year != null) {
      for (final entry in catalog) {
        if (entry.make.toLowerCase() == lcMake &&
            entry.model.toLowerCase() == lcModel &&
            entry.coversYear(year)) {
          return entry;
        }
      }
    }

    // Tier 2 — make + model, any year. Falls through when the year is
    // outside the production window or the user didn't enter one.
    if (lcModel != null && lcModel.isNotEmpty) {
      for (final entry in catalog) {
        if (entry.make.toLowerCase() == lcMake &&
            entry.model.toLowerCase() == lcModel) {
          return entry;
        }
      }
    }

    // Tier 3 — make only. The OBD-II layer dispatches by
    // `odometerPidStrategy`, which is brand-wide for the families we
    // ship (PSA, VAG, BMW, Toyota etc.), so a make-only fallback still
    // gives the consumer a useful strategy.
    for (final entry in catalog) {
      if (entry.make.toLowerCase() == lcMake) return entry;
    }

    return null;
  }

  /// Builds the persistent slug for a catalog entry. Stored on the
  /// profile as [VehicleProfile.referenceVehicleId] so subsequent app
  /// launches can resolve the same row without re-running the matcher.
  ///
  /// Format: `<make>-<model>-<generation>` lowercased, with every
  /// non-alphanumeric character collapsed to a single dash, edges
  /// trimmed. Stable across app launches because the inputs come from
  /// the bundled JSON asset, not from user-typed strings.
  ///
  /// Examples:
  ///   - Peugeot 208 II (2019-)        → `peugeot-208-ii-2019`
  ///   - Volkswagen Golf VIII (2019-)  → `volkswagen-golf-viii-2019`
  ///   - Citroen C5 Aircross I (2018-) → `citroen-c5-aircross-i-2018`
  static String slugFor(ReferenceVehicle entry) {
    final raw = '${entry.make}-${entry.model}-${entry.generation}';
    final lowered = raw.toLowerCase();
    final dashed = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    // Collapse runs of dashes and trim leading/trailing dashes.
    final collapsed = dashed.replaceAll(RegExp(r'-+'), '-');
    return collapsed.replaceAll(RegExp(r'^-|-$'), '');
  }
}
