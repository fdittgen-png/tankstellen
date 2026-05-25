import 'feature.dart';

/// User-facing "use mode" that bundles a curated set of [Feature] flags
/// (#1517).
///
/// The first-run wizard asks the user to pick one of these on its first
/// page; the same selector is exposed in Settings so the user can revisit
/// the choice. Picking a profile applies the corresponding bundle from
/// [appProfileBundles] via `applyProfile()` (see
/// `application/app_profile_provider.dart`).
///
/// [custom] is a sentinel — it means the user has manually toggled flags
/// outside the preset bundles and the active flag set no longer matches
/// any preset. Existing installs (already-onboarded users) land on
/// [custom] so the migration to this system never silently changes their
/// flags. New installs persist `null` (no choice yet) so the wizard's
/// profile-choice page is the gate.
///
/// Persistence keys use [Enum.name], so values may be reordered or
/// inserted but MUST NOT be renamed without a migration.
enum AppProfile {
  /// Fuel + EV price search, favorites, price alerts, price history,
  /// route planning. No vehicle, no consumption tracking, no OBD2.
  basic,

  /// Everything in [basic] plus manual fuel fill-ups + manual EV
  /// charging logs (still no OBD2). Vehicle wizard step is shown so
  /// fill-ups have a vehicle to attach to.
  medium,

  /// Everything in [medium] plus OBD2 trip recording, auto-record,
  /// gamification, consumption analytics tab, and loyalty cards.
  /// Vehicle + OBD2 wizard steps both shown.
  full,

  /// User has manually customised their feature set away from any
  /// preset (or migrated from a pre-#1517 install). The Settings
  /// selector still shows their choice but renders a fourth "Custom"
  /// card so they can return to a preset at any time.
  custom,
}

/// The set of Features each [AppProfile] enables when applied.
///
/// `applyProfile()` reads this map, then for every feature listed it
/// either enables (if in the set) or disables (if NOT in the set) the
/// flag — the bundles are exhaustive, not additive, so re-applying the
/// same profile is idempotent.
///
/// Bundle composition (revised post-#1517):
///
/// **Basic** — search / discovery + cross-device sync
/// - Visibility + discovery: `showFuel`, `showElectric`, `priceAlerts`,
///   `priceHistory`, `routePlanning`, `evCharging`
/// - Cross-device sync: `tankSync`, `baselineSync`
///   (baseline driving-stat sync requires `tankSync` per the manifest
///   `requires:` edge; both go in together so the requires graph stays
///   satisfied)
///
/// **Medium** — Basic + manual fill-up logging + GPS-only trajets
/// - All Basic features
/// - `manualConsumption` — fuel fill-ups + EV charging logged by hand
/// - `obd2TripRecording` + `consumptionAnalytics` + `showConsumptionTab`
///   — trajet recording feature surfaces, but the user is NOT required
///   to pair an OBD2 dongle: the absent `obd2Optional` flag means the
///   #2025 GPS-only path kicks in on Start
/// - `gpsTripPath` — GPS samples persisted so the post-trip map +
///   GPX export work for GPS-only trajets
///
/// **Full** — Medium + OBD2 required + ergonomics
/// - All Medium features
/// - `obd2Optional` — OBD2 is required to start a trip (no GPS-only
///   fallback). Full users are expected to have an adapter paired.
/// - OBD2 ergonomics: `autoRecord`, `gamification`, `loyaltyCards`,
///   `hapticEcoCoach`, `glideCoach` (the last two
///   `requires: {obd2TripRecording}` per the manifest)
///
/// Off in **every** preset (user opts in individually):
/// - `tflitePricePrediction` (model artifact still off-band; #1543)
const Map<AppProfile, Set<Feature>> appProfileBundles = {
  AppProfile.basic: {
    Feature.showFuel,
    Feature.showElectric,
    Feature.priceAlerts,
    Feature.priceHistory,
    Feature.routePlanning,
    Feature.evCharging,
    Feature.tankSync,
    Feature.baselineSync,
  },
  AppProfile.medium: {
    Feature.showFuel,
    Feature.showElectric,
    Feature.priceAlerts,
    Feature.priceHistory,
    Feature.routePlanning,
    Feature.evCharging,
    Feature.tankSync,
    Feature.baselineSync,
    Feature.manualConsumption,
    // #1568 — without this the `isConsumptionTabReachable` gate
    // short-circuits to false and the Conso settings section vanishes,
    // leaving Medium users no path to configure a vehicle for the
    // manual fill-up flow they just opted into.
    Feature.showConsumptionTab,
    // #2025 — Medium users get trajet recording but in the GPS-only
    // path: `obd2TripRecording` surfaces the Trajets tab + recording
    // CTA, `gpsTripPath` persists GPS samples for the post-trip map
    // and GPX export, and the deliberate ABSENCE of `obd2Optional`
    // tells `_onStartRecording` to skip the adapter picker and call
    // `startGpsOnly()` instead.
    Feature.obd2TripRecording,
    Feature.consumptionAnalytics,
    Feature.gpsTripPath,
  },
  AppProfile.full: {
    Feature.showFuel,
    Feature.showElectric,
    Feature.priceAlerts,
    Feature.priceHistory,
    Feature.routePlanning,
    Feature.evCharging,
    Feature.tankSync,
    Feature.baselineSync,
    Feature.manualConsumption,
    Feature.loyaltyCards,
    Feature.obd2TripRecording,
    Feature.autoRecord,
    Feature.consumptionAnalytics,
    Feature.gamification,
    Feature.showConsumptionTab,
    Feature.hapticEcoCoach,
    Feature.glideCoach,
    Feature.gpsTripPath,
    // #2025 — Full users require an OBD2 dongle. Including
    // `obd2Optional` in the preset preserves the historical default
    // (Start → adapter picker → OBD2-driven recording) for users who
    // pick Full from the wizard.
    Feature.obd2Optional,
  },
  // The custom sentinel has no bundle — the user's flag set is
  // whatever they last persisted, and re-selecting `custom` from the
  // Settings selector is a no-op on flags.
  AppProfile.custom: <Feature>{},
};

/// Returns the [AppProfile] whose bundle exactly matches [enabled], or
/// [AppProfile.custom] if no preset matches.
///
/// "Exactly matches" means the enabled set equals the bundle set —
/// extra-enabled flags or missing flags both flip the result to
/// [AppProfile.custom]. This is the function the runtime calls after
/// any feature-flag toggle to decide whether the user has drifted off
/// the active preset.
///
/// [AppProfile.custom] is never returned as a "match" — it is the
/// fallback when no preset fits.
AppProfile detectProfileFromFlags(Set<Feature> enabled) {
  for (final entry in appProfileBundles.entries) {
    if (entry.key == AppProfile.custom) continue;
    if (_setsEqual(entry.value, enabled)) return entry.key;
  }
  return AppProfile.custom;
}

bool _setsEqual(Set<Feature> a, Set<Feature> b) {
  if (a.length != b.length) return false;
  for (final f in a) {
    if (!b.contains(f)) return false;
  }
  return true;
}
