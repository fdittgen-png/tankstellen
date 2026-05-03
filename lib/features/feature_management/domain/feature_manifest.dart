import 'feature.dart';

/// Metadata for a single [Feature] in the manifest (#1373 phase 1).
///
/// Plain immutable class — the codebase prefers Dart 3 native sealed/enum
/// + plain classes over Freezed multi-constructor unions for this kind of
/// declarative descriptor (see #1377 PR notes).
class FeatureManifestEntry {
  /// The feature this entry describes.
  final Feature feature;

  /// Default state for fresh installs and migrated profiles. Mirrors the
  /// behaviour of the equivalent scattered toggle TODAY so flipping the
  /// new system on does not silently change anything.
  final bool defaultEnabled;

  /// Hard prerequisites — every feature here must be enabled before
  /// [feature] can be enabled. Cycles are rejected by
  /// `assertNoCycles` at provider construction.
  final Set<Feature> requires;

  /// Human-readable label used by Phase 2 settings UI. English only;
  /// localisation is Phase 2's concern.
  final String displayName;

  /// One-line description shown next to the toggle in Phase 2 UI.
  /// English only; localisation is Phase 2's concern.
  final String description;

  const FeatureManifestEntry({
    required this.feature,
    required this.defaultEnabled,
    required this.displayName,
    required this.description,
    this.requires = const {},
  });
}

/// Declarative registry of every [Feature] the app knows about.
///
/// Phase 1 of #1373 ships only [defaultManifest]. Phase 2 / 3 will read
/// from this manifest to render the settings UI and to migrate the
/// existing scattered toggles into the central provider.
class FeatureManifest {
  final Map<Feature, FeatureManifestEntry> entries;

  const FeatureManifest(this.entries);

  /// Look up a single entry. Throws [StateError] when [feature] has no
  /// entry — every value in [Feature] must be declared in the active
  /// manifest, so a missing entry is a programmer error.
  FeatureManifestEntry entryFor(Feature feature) {
    final entry = entries[feature];
    if (entry == null) {
      throw StateError(
        'FeatureManifest is missing an entry for $feature. '
        'Every Feature value must be declared in the manifest.',
      );
    }
    return entry;
  }

  /// The set of features whose [FeatureManifestEntry.defaultEnabled] is
  /// `true`. Used by the repository on first launch and as the fallback
  /// when the persisted set cannot be read.
  Set<Feature> defaultEnabledSet() {
    return {
      for (final e in entries.values)
        if (e.defaultEnabled) e.feature,
    };
  }

  /// Authoritative manifest used at runtime. Defaults match TODAY's
  /// scattered-toggle behaviour:
  /// - `obd2TripRecording`: false (matches `VehicleProfile.autoRecord`)
  /// - `gamification`: true (matches `UserProfile.gamificationEnabled`)
  /// - `hapticEcoCoach`: false (off by default; explicit opt-in)
  /// - `tankSync`: false (off until user signs in)
  /// - `consumptionAnalytics`: false (no trips → no tab)
  /// - `baselineSync`: false (off until TankSync is enabled)
  /// - `unifiedSearchResults`: false (kept off pending UX work)
  /// - `priceAlerts`, `priceHistory`, `routePlanning`, `evCharging`: true
  /// - `glideCoach`, `gpsTripPath`: false (future features, opt-in)
  static const FeatureManifest defaultManifest = FeatureManifest({
    Feature.obd2TripRecording: FeatureManifestEntry(
      feature: Feature.obd2TripRecording,
      defaultEnabled: false,
      displayName: 'OBD2 trip recording',
      description: 'Capture trips automatically over OBD2.',
    ),
    Feature.gamification: FeatureManifestEntry(
      feature: Feature.gamification,
      defaultEnabled: true,
      requires: {Feature.obd2TripRecording},
      displayName: 'Gamification',
      description: 'Driving scores and earned badges.',
    ),
    Feature.hapticEcoCoach: FeatureManifestEntry(
      feature: Feature.hapticEcoCoach,
      defaultEnabled: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Haptic eco-coach',
      description: 'Real-time haptic feedback during a trip.',
    ),
    Feature.tankSync: FeatureManifestEntry(
      feature: Feature.tankSync,
      defaultEnabled: false,
      displayName: 'TankSync',
      description: 'Cross-device sync via Supabase.',
    ),
    Feature.consumptionAnalytics: FeatureManifestEntry(
      feature: Feature.consumptionAnalytics,
      defaultEnabled: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Consumption analytics',
      description: 'Fill-up and trip analysis tab.',
    ),
    Feature.baselineSync: FeatureManifestEntry(
      feature: Feature.baselineSync,
      defaultEnabled: false,
      requires: {Feature.tankSync},
      displayName: 'Baseline sync',
      description: 'Sync driving baselines via TankSync.',
    ),
    Feature.unifiedSearchResults: FeatureManifestEntry(
      feature: Feature.unifiedSearchResults,
      defaultEnabled: false,
      displayName: 'Unified search results',
      description: 'Single result list combining fuel and EV stations.',
    ),
    Feature.priceAlerts: FeatureManifestEntry(
      feature: Feature.priceAlerts,
      defaultEnabled: true,
      displayName: 'Price alerts',
      description: 'Threshold-based price-drop notifications.',
    ),
    Feature.priceHistory: FeatureManifestEntry(
      feature: Feature.priceHistory,
      defaultEnabled: true,
      displayName: 'Price history',
      description: '30-day price charts on station details.',
    ),
    Feature.routePlanning: FeatureManifestEntry(
      feature: Feature.routePlanning,
      defaultEnabled: true,
      displayName: 'Route planning',
      description: 'Cheapest stop along your route.',
    ),
    Feature.evCharging: FeatureManifestEntry(
      feature: Feature.evCharging,
      defaultEnabled: true,
      displayName: 'EV charging',
      description: 'Charging stations via OpenChargeMap.',
    ),
    Feature.glideCoach: FeatureManifestEntry(
      feature: Feature.glideCoach,
      defaultEnabled: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Glide-coach',
      description: 'Hypermiling guidance using OSM traffic signals.',
    ),
    Feature.gpsTripPath: FeatureManifestEntry(
      feature: Feature.gpsTripPath,
      defaultEnabled: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'GPS trip path',
      description: 'Persist GPS path samples alongside each trip.',
    ),
  });
}
