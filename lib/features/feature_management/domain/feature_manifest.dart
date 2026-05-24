import 'build_channel.dart';
import 'feature.dart';

/// Metadata for a single [Feature] in the manifest (#1373 phase 1).
///
/// Plain immutable class — the codebase prefers Dart 3 native sealed/enum
/// + plain classes over Freezed multi-constructor unions for this kind of
/// declarative descriptor (see #1377 PR notes).
class FeatureManifestEntry {
  /// The feature this entry describes.
  final Feature feature;

  /// Build channels this feature exists in (#1670 / #1673). A feature
  /// absent from a channel is completely unavailable there — force-off
  /// and hidden from that channel's feature-management UI.
  final Set<BuildChannel> availableChannels;

  /// Build channels where the feature defaults ON (opt-out). In an
  /// available channel NOT listed here the feature defaults OFF
  /// (opt-in). Always a subset of [availableChannels].
  final Set<BuildChannel> defaultEnabledChannels;

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
    required this.availableChannels,
    this.defaultEnabledChannels = const {},
    required this.displayName,
    required this.description,
    this.requires = const {},
  });

  /// Convenience for a feature available in every build channel — the
  /// shape of every feature that predates the channel model (#1673).
  /// [defaultOn] sets opt-out (on) vs opt-in (off) uniformly across
  /// channels, mirroring the old single `defaultEnabled` bool.
  const FeatureManifestEntry.allChannels({
    required this.feature,
    required bool defaultOn,
    required this.displayName,
    required this.description,
    this.requires = const {},
  })  : availableChannels = const {
          BuildChannel.production,
          BuildChannel.beta,
        },
        defaultEnabledChannels = defaultOn
            ? const {BuildChannel.production, BuildChannel.beta}
            : const {};

  /// Whether [feature] exists at all in [channel].
  bool isAvailableIn(BuildChannel channel) =>
      availableChannels.contains(channel);

  /// Whether [feature] defaults enabled in [channel]. Always `false`
  /// for a channel the feature is not available in.
  bool defaultEnabledIn(BuildChannel channel) =>
      defaultEnabledChannels.contains(channel);
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

  /// The set of features that default ON in [channel]. Used by the
  /// repository on first launch and as the fallback when the persisted
  /// set cannot be read. Defaults to [BuildChannel.production] so
  /// callers predating the live channel resolver (#1674) keep
  /// production behaviour.
  Set<Feature> defaultEnabledSet([
    BuildChannel channel = BuildChannel.production,
  ]) {
    return {
      for (final e in entries.values)
        if (e.defaultEnabledIn(channel)) e.feature,
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
  /// - `priceAlerts`, `priceHistory`, `routePlanning`, `evCharging`: true
  /// - `glideCoach`: false (future feature, opt-in)
  /// - `gpsTripPath`: true (#1981 — a GPS track is true road distance,
  ///   which makes the consumption figure accurate; #1979)
  /// - `showFuel`, `showElectric`: true (#1373 phase 3c — both
  ///   surfaces visible by default; mirrors the historical
  ///   `UserProfile.showFuel` / `showElectric` defaults so existing
  ///   users see no behaviour change post-migration)
  /// - `showConsumptionTab`: true with `requires: {obd2TripRecording}`
  ///   (#1373 phase 3c — the consumption analytics tab has nothing
  ///   to render without trip data, so the dependency edge guards
  ///   against an empty surface; default-true mirrors the wrap-not-
  ///   replace shape used for `autoRecord` in phase 3d)
  static const FeatureManifest defaultManifest = FeatureManifest({
    Feature.obd2TripRecording: FeatureManifestEntry.allChannels(
      feature: Feature.obd2TripRecording,
      defaultOn: false,
      displayName: 'OBD2 trip recording',
      description: 'Capture trips automatically over OBD2.',
    ),
    Feature.gamification: FeatureManifestEntry.allChannels(
      feature: Feature.gamification,
      defaultOn: true,
      requires: {Feature.obd2TripRecording},
      displayName: 'Gamification',
      description: 'Driving scores and earned badges.',
    ),
    Feature.hapticEcoCoach: FeatureManifestEntry.allChannels(
      feature: Feature.hapticEcoCoach,
      defaultOn: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Haptic eco-coach',
      description: 'Real-time haptic feedback during a trip.',
    ),
    Feature.tankSync: FeatureManifestEntry.allChannels(
      feature: Feature.tankSync,
      defaultOn: false,
      displayName: 'TankSync',
      description: 'Cross-device sync via Supabase.',
    ),
    Feature.consumptionAnalytics: FeatureManifestEntry.allChannels(
      feature: Feature.consumptionAnalytics,
      defaultOn: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Consumption analytics',
      description: 'Fill-up and trip analysis tab.',
    ),
    Feature.baselineSync: FeatureManifestEntry.allChannels(
      feature: Feature.baselineSync,
      defaultOn: false,
      requires: {Feature.tankSync},
      displayName: 'Baseline sync',
      description: 'Sync driving baselines via TankSync.',
    ),
    Feature.priceAlerts: FeatureManifestEntry.allChannels(
      feature: Feature.priceAlerts,
      defaultOn: true,
      displayName: 'Price alerts',
      description: 'Threshold-based price-drop notifications.',
    ),
    Feature.priceHistory: FeatureManifestEntry.allChannels(
      feature: Feature.priceHistory,
      defaultOn: true,
      displayName: 'Price history',
      description: '30-day price charts on station details.',
    ),
    Feature.routePlanning: FeatureManifestEntry.allChannels(
      feature: Feature.routePlanning,
      defaultOn: true,
      displayName: 'Route planning',
      description: 'Cheapest stop along your route.',
    ),
    Feature.evCharging: FeatureManifestEntry.allChannels(
      feature: Feature.evCharging,
      defaultOn: true,
      displayName: 'EV charging',
      description: 'Charging stations via OpenChargeMap.',
    ),
    Feature.glideCoach: FeatureManifestEntry.allChannels(
      feature: Feature.glideCoach,
      defaultOn: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Glide-coach',
      description: 'Hypermiling guidance using OSM traffic signals.',
    ),
    Feature.gpsTripPath: FeatureManifestEntry.allChannels(
      feature: Feature.gpsTripPath,
      // #1981 — default-on: the GPS track is true road distance, which
      // makes the consumption figure accurate (the OBD speed sensor
      // over-reads — #1979). `requires: obd2TripRecording` scopes it to
      // users who actually record trips; it is foreground-only and can
      // still be turned off from Feature management.
      defaultOn: true,
      requires: {Feature.obd2TripRecording},
      displayName: 'GPS trip path',
      description: 'Persist GPS path samples alongside each trip.',
    ),
    Feature.autoRecord: FeatureManifestEntry.allChannels(
      feature: Feature.autoRecord,
      // Default-true to mirror today's behaviour: vehicles that have
      // explicitly opted in to per-vehicle `autoRecord: true` keep
      // recording. Users can disable the master gate from the central
      // settings UI; the migrator (phase 3d) flips this to false only
      // when EVERY existing vehicle had the per-vehicle bool off.
      defaultOn: true,
      requires: {Feature.obd2TripRecording},
      displayName: 'Auto-record',
      description:
          'Automatically start a trip when the OBD2 adapter connects to a moving vehicle.',
    ),
    Feature.showFuel: FeatureManifestEntry.allChannels(
      feature: Feature.showFuel,
      // Default-true mirrors the historical `UserProfile.showFuel`
      // default; existing users see no behaviour change after the
      // phase-3c migration.
      defaultOn: true,
      displayName: 'Show fuel stations',
      description:
          'Display petrol/diesel station results in search and on the map.',
    ),
    Feature.showElectric: FeatureManifestEntry.allChannels(
      feature: Feature.showElectric,
      // Default-true mirrors the historical `UserProfile.showElectric`
      // default; existing users see no behaviour change after the
      // phase-3c migration.
      defaultOn: true,
      displayName: 'Show charging stations',
      description:
          'Display EV charging stations in search and on the map.',
    ),
    Feature.showConsumptionTab: FeatureManifestEntry.allChannels(
      feature: Feature.showConsumptionTab,
      // Default-true with `requires: {obd2TripRecording}` — the
      // consumption analytics tab has nothing to render without trip
      // data, so the dependency edge guards against an empty surface.
      // The legacy `UserProfile.showConsumptionTab` field defaulted to
      // `false`; the phase-3c migrator preserves explicit-true (rare,
      // user has to have flipped it on) and respects the manifest
      // default-true otherwise — the dependency on `obd2TripRecording`
      // (default-off) means the surface stays effectively hidden until
      // the user enables trip recording, matching the original
      // user-facing shape.
      //
      // For the Medium use-mode profile (#1517), the consumption-tab
      // visibility is OR-extended programmatically at the bottom-nav
      // render site so `manualConsumption` (no OBD2 prereq) also
      // surfaces the tab. That OR check lives outside the manifest
      // because `requires` is AND-only.
      defaultOn: true,
      requires: {Feature.obd2TripRecording},
      displayName: 'Consumption tab',
      description:
          'Show the consumption analytics tab in the bottom navigation.',
    ),
    Feature.manualConsumption: FeatureManifestEntry.allChannels(
      feature: Feature.manualConsumption,
      // Default-off; the `AppProfile.medium` and `AppProfile.full`
      // presets flip it on. No prerequisite — the Medium tier should
      // work without an OBD2 adapter or any vehicle hardware.
      defaultOn: false,
      displayName: 'Manual consumption logging',
      description:
          'Track fuel fill-ups and EV charging sessions by hand (no OBD2 adapter required).',
    ),
    Feature.loyaltyCards: FeatureManifestEntry.allChannels(
      feature: Feature.loyaltyCards,
      // Default-off; only the `AppProfile.full` preset flips it on.
      defaultOn: false,
      displayName: 'Loyalty cards',
      description:
          'Fuel-club / loyalty program cards with per-litre discounts in price comparisons.',
    ),
    Feature.tflitePricePrediction: FeatureManifestEntry.allChannels(
      feature: Feature.tflitePricePrediction,
      // Default-off and double-gated. The compile-time
      // `kTflitePredictorEnabled` const in
      // `lib/features/price_history/data/tflite_price_predictor.dart`
      // stays false until the trained `.tflite` artifact ships under
      // `assets/models/`. With either gate off, the heuristic
      // `pricePredictionProvider` renders unchanged.
      defaultOn: false,
      requires: {Feature.priceHistory},
      displayName: 'TFLite price prediction',
      description:
          'On-device price forecast model — inference runs locally; '
              'features and predictions never leave the device.',
    ),
    Feature.fuelCalculator: FeatureManifestEntry.allChannels(
      feature: Feature.fuelCalculator,
      // Default-on (#1613): the fuel-cost Calculator is a finished,
      // self-contained, harmless utility — exposing it is the whole
      // point of the gate. No `requires` edge: it depends on nothing.
      defaultOn: true,
      displayName: 'Fuel calculator',
      description: 'Reachable fuel-cost calculator from the search results.',
    ),
    Feature.carbonDashboard: FeatureManifestEntry.allChannels(
      feature: Feature.carbonDashboard,
      // Default-on (#1613): the Carbon dashboard already shipped live
      // and reachable — default-on preserves current behaviour while
      // bringing it under central feature management. No prerequisites.
      defaultOn: true,
      displayName: 'Carbon dashboard',
      description: 'CO2 footprint dashboard reachable from the Consumption '
          'tab.',
    ),
    Feature.experimentalOemPids: FeatureManifestEntry.allChannels(
      feature: Feature.experimentalOemPids,
      // Default-off (#1615): an opt-in experiment. Even when enabled it
      // is a no-op unless the connected adapter is OEM-PID-capable, so
      // the flag-off path is the existing percent×capacity conversion
      // bit-for-bit. `requires: {obd2TripRecording}` — an OEM fuel read
      // only happens inside the trip-recording fuel sampler.
      defaultOn: false,
      requires: {Feature.obd2TripRecording},
      displayName: 'Experimental OEM PIDs',
      description:
          'Read exact tank litres via manufacturer-specific PIDs on '
          'supported adapters.',
    ),
    Feature.paymentQrScan: FeatureManifestEntry.allChannels(
      feature: Feature.paymentQrScan,
      // Default-on (#1638): the scan-payment-QR action already shipped
      // live on the station-detail AppBar — default-on preserves current
      // behaviour while bringing it under central management. No
      // prerequisites: the scanner depends on nothing else.
      defaultOn: true,
      displayName: 'Scan payment QR',
      description: 'Scan-to-pay QR reader on the station detail screen.',
    ),
    Feature.communityPriceReports: FeatureManifestEntry.allChannels(
      feature: Feature.communityPriceReports,
      // Default-on (#1638): the report-price action already shipped live
      // on the station-detail AppBar — default-on preserves current
      // behaviour while bringing it under central management. No
      // prerequisites.
      defaultOn: true,
      displayName: 'Community price reports',
      description: 'Report a station price from the station detail screen.',
    ),
    Feature.obd2Optional: FeatureManifestEntry.allChannels(
      feature: Feature.obd2Optional,
      // Default-on (#2024): the trip recorder has always required an
      // OBD2 adapter. Flipping this flag off enables GPS-only trajets
      // (kind = gpsOnly) and unlocks the minimal recording-screen
      // layout (#2026). No prerequisites — this flag IS the
      // prerequisite-removal.
      defaultOn: true,
      displayName: 'Require OBD2 for trip recording',
      description:
          'When off, the app records GPS-only trajets without needing an '
              'OBD2 adapter. Coaching is reduced — no instant L/100 km, '
              'fewer engine-derived signals. Calibration drops to '
              'confidence tier A until you add fuel-ups.',
    ),
  });
}
