import 'feature.dart';

/// User-facing tri-state for the Consumption feature (#1570).
///
/// Replaces the previous binary `obd2TripRecording` toggle in the
/// user-facing Feature management UI. The underlying [Feature] flags
/// stay — this enum is a *derivation*, not a new persisted value.
///
/// Mapping (read-side; see [consoModeFromFlags]):
/// - [off] — Conso tab + Conso settings section are hidden entirely.
/// - [fuel] — manual fill-ups only. Conso tab shows the fuel-log
///   surface (no Trajets sub-tab). Settings Conso section visible
///   with vehicle management; no Trajets-tier toggles.
/// - [fuelAndTrips] — full Conso with OBD2 trip recording. Adds the
///   Trajets sub-tab and the Trajets sub-section in Settings.
enum ConsoMode {
  off,
  fuel,
  fuelAndTrips,
}

/// Derive the user-facing [ConsoMode] from the current feature-flag set.
///
/// Authoritative rules:
/// - `fuelAndTrips` ⇔ `showConsumptionTab` AND `obd2TripRecording`
///   (manualConsumption is implied — the full mode is a superset).
/// - `fuel` ⇔ `showConsumptionTab` AND `manualConsumption` AND NOT
///   `obd2TripRecording`.
/// - Anything else ⇒ `off` (no Conso surface).
///
/// The function is pure and side-effect-free; callers can `.watch`
/// `featureFlagsProvider` and feed the result here without rebuild
/// concerns beyond the flag-set identity.
ConsoMode consoModeFromFlags(Set<Feature> enabled) {
  if (!enabled.contains(Feature.showConsumptionTab)) return ConsoMode.off;
  if (enabled.contains(Feature.obd2TripRecording)) {
    return ConsoMode.fuelAndTrips;
  }
  if (enabled.contains(Feature.manualConsumption)) return ConsoMode.fuel;
  return ConsoMode.off;
}

/// Compute the [Feature] set delta needed to *write* a target
/// [ConsoMode]. Returns `(toAdd, toRemove)` — callers union/diff into
/// the persisted flag set.
///
/// Other Conso-adjacent flags (`autoRecord`, `gpsTripPath`,
/// `hapticEcoCoach`, `glideCoach`, `consumptionAnalytics`,
/// `gamification`, `loyaltyCards`) are NOT touched here — they are
/// independent opt-ins inside the Trajets-tier. Switching modes only
/// rewrites the three flags that gate the surface itself.
({Set<Feature> toAdd, Set<Feature> toRemove}) consoModeFlagDelta(
  ConsoMode mode,
) {
  switch (mode) {
    case ConsoMode.off:
      return (
        toAdd: const <Feature>{},
        toRemove: const {
          Feature.showConsumptionTab,
          Feature.manualConsumption,
          Feature.obd2TripRecording,
        },
      );
    case ConsoMode.fuel:
      return (
        toAdd: const {
          Feature.showConsumptionTab,
          Feature.manualConsumption,
        },
        toRemove: const {Feature.obd2TripRecording},
      );
    case ConsoMode.fuelAndTrips:
      return (
        toAdd: const {
          Feature.showConsumptionTab,
          Feature.manualConsumption,
          Feature.obd2TripRecording,
        },
        toRemove: const <Feature>{},
      );
  }
}
