/// Bridge layer: every value of the legacy `Feature` enum gets a
/// paired `FeatureClass` const here.
///
/// The `id` of each const **MUST** match the enum value's `.name` so
/// the persisted feature-flags Hive box reads identically whether
/// code looks up by the old enum or the new class — no migration
/// required. The legacy v1 manifest in
/// `lib/features/feature_management/domain/feature_manifest.dart` is
/// the source of `defaultEnabled` + dependency edges; this file
/// transcribes that into the v2 model.
///
/// Phase 1 (this file) only mirrors the existing 20 features. New
/// features post-phase-1 should be declared in their own module file
/// (`lib/features/<area>/feature.dart`) and added to
/// `feature_registry.dart`'s import list. Old features migrate one
/// per PR over time — see `docs/design/feature-management-v2.md` for
/// the multi-phase plan.
///
/// Presentation hierarchy (`parent:`) is set per-feature based on
/// where the existing Settings UI groups the tile, even when it
/// differs from the `requires:` activation edge. See the inline
/// comments for each non-trivial choice.
library;

import 'feature_class.dart';

// ----------------------------------------------------------------------------
// Top-level (no parent in either presentation or activation)
// ----------------------------------------------------------------------------

const kFeatureObd2TripRecording = FeatureClass(
  id: 'obd2TripRecording',
  parent: _none,
  requires: _empty,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_obd2TripRecording',
  displayName: 'OBD2 trip recording',
  descriptionKey: 'featureDescription_obd2TripRecording',
  description: 'Capture trips automatically over OBD2.',
);

const kFeatureTankSync = FeatureClass(
  id: 'tankSync',
  parent: _none,
  requires: _empty,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_tankSync',
  displayName: 'TankSync',
  descriptionKey: 'featureDescription_tankSync',
  description: 'Cross-device sync via Supabase.',
);

const kFeatureUnifiedSearchResults = FeatureClass(
  id: 'unifiedSearchResults',
  parent: _none,
  requires: _empty,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_unifiedSearchResults',
  displayName: 'Unified search results',
  descriptionKey: 'featureDescription_unifiedSearchResults',
  description: 'Single result list combining fuel and EV stations.',
);

const kFeaturePriceAlerts = FeatureClass(
  id: 'priceAlerts',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_priceAlerts',
  displayName: 'Price alerts',
  descriptionKey: 'featureDescription_priceAlerts',
  description: 'Threshold-based price-drop notifications.',
);

const kFeaturePriceHistory = FeatureClass(
  id: 'priceHistory',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_priceHistory',
  displayName: 'Price history',
  descriptionKey: 'featureDescription_priceHistory',
  description: '30-day price charts on station details.',
);

const kFeatureRoutePlanning = FeatureClass(
  id: 'routePlanning',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_routePlanning',
  displayName: 'Route planning',
  descriptionKey: 'featureDescription_routePlanning',
  description: 'Cheapest stop along your route.',
);

const kFeatureEvCharging = FeatureClass(
  id: 'evCharging',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_evCharging',
  displayName: 'EV charging',
  descriptionKey: 'featureDescription_evCharging',
  description: 'Charging stations via OpenChargeMap.',
);

const kFeatureShowFuel = FeatureClass(
  id: 'showFuel',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_showFuel',
  displayName: 'Show fuel stations',
  descriptionKey: 'featureDescription_showFuel',
  description: 'Display petrol/diesel station results in search and on the '
      'map.',
);

const kFeatureShowElectric = FeatureClass(
  id: 'showElectric',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_showElectric',
  displayName: 'Show charging stations',
  descriptionKey: 'featureDescription_showElectric',
  description: 'Display EV charging stations in search and on the map.',
);

const kFeatureManualConsumption = FeatureClass(
  id: 'manualConsumption',
  parent: _none,
  requires: _empty,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_manualConsumption',
  displayName: 'Manual consumption logging',
  descriptionKey: 'featureDescription_manualConsumption',
  description: 'Track fuel fill-ups and EV charging sessions by hand (no OBD2 '
      'adapter required).',
);

const kFeatureLoyaltyCards = FeatureClass(
  id: 'loyaltyCards',
  parent: _none,
  requires: _empty,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_loyaltyCards',
  displayName: 'Loyalty cards',
  descriptionKey: 'featureDescription_loyaltyCards',
  description: 'Fuel-club / loyalty program cards with per-litre discounts in '
      'price comparisons.',
);

const kFeatureFuelCalculator = FeatureClass(
  id: 'fuelCalculator',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_fuelCalculator',
  displayName: 'Fuel calculator',
  descriptionKey: 'featureDescription_fuelCalculator',
  description: 'Reachable fuel-cost calculator from the search results.',
);

const kFeatureCarbonDashboard = FeatureClass(
  id: 'carbonDashboard',
  parent: _none,
  requires: _empty,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_carbonDashboard',
  displayName: 'Carbon dashboard',
  descriptionKey: 'featureDescription_carbonDashboard',
  description: 'CO2 footprint dashboard reachable from the Consumption tab.',
);

// ----------------------------------------------------------------------------
// Children of obd2TripRecording
// ----------------------------------------------------------------------------

const kFeatureGamification = FeatureClass(
  id: 'gamification',
  parent: _obd2,
  requires: _obd2Set,
  // v1 manifest defaults gamification on — every vehicle with OBD2
  // trip recording gets badges + scores out of the box. Keep this in
  // lockstep with `feature_manifest.dart` while Phase 1 is the
  // active bridge.
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_gamification',
  displayName: 'Gamification',
  descriptionKey: 'featureDescription_gamification',
  description: 'Driving scores and earned badges.',
);

const kFeatureHapticEcoCoach = FeatureClass(
  id: 'hapticEcoCoach',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_hapticEcoCoach',
  displayName: 'Haptic eco-coach',
  descriptionKey: 'featureDescription_hapticEcoCoach',
  description: 'Real-time haptic feedback during a trip.',
);

const kFeatureConsumptionAnalytics = FeatureClass(
  id: 'consumptionAnalytics',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_consumptionAnalytics',
  displayName: 'Consumption analytics',
  descriptionKey: 'featureDescription_consumptionAnalytics',
  description: 'Fill-up and trip analysis tab.',
);

const kFeatureGlideCoach = FeatureClass(
  id: 'glideCoach',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: false,
  // Glide-coach is reserved for a future hypermiling guide; no
  // runtime implementation yet (see docs/guides/feature-flags.md
  // "Known gating gaps"). Stays beta until the surface lands.
  maturity: FeatureMaturity.beta,
  displayKey: 'featureLabel_glideCoach',
  displayName: 'Glide-coach',
  descriptionKey: 'featureDescription_glideCoach',
  description: 'Hypermiling guidance using OSM traffic signals.',
);

const kFeatureGpsTripPath = FeatureClass(
  id: 'gpsTripPath',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_gpsTripPath',
  displayName: 'GPS trip path',
  descriptionKey: 'featureDescription_gpsTripPath',
  description: 'Persist GPS path samples alongside each trip.',
);

const kFeatureAutoRecord = FeatureClass(
  id: 'autoRecord',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_autoRecord',
  displayName: 'Auto-record',
  descriptionKey: 'featureDescription_autoRecord',
  description: 'Automatically start a trip when the OBD2 adapter connects to '
      'a moving vehicle.',
);

const kFeatureShowConsumptionTab = FeatureClass(
  id: 'showConsumptionTab',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: true,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_showConsumptionTab',
  displayName: 'Consumption tab',
  descriptionKey: 'featureDescription_showConsumptionTab',
  description: 'Show the consumption analytics tab in the bottom navigation.',
);

const kFeatureExperimentalOemPids = FeatureClass(
  id: 'experimentalOemPids',
  parent: _obd2,
  requires: _obd2Set,
  defaultEnabled: false,
  // Experimental opt-in (#1615): the exact-litre OEM-PID fuel path has
  // a runtime implementation but is gated additionally on the adapter
  // capability tier. Beta keeps it out of the profile preset bundles.
  maturity: FeatureMaturity.beta,
  displayKey: 'featureLabel_experimentalOemPids',
  displayName: 'Experimental OEM PIDs',
  descriptionKey: 'featureDescription_experimentalOemPids',
  description: 'Read exact tank litres via manufacturer-specific PIDs on '
      'supported adapters.',
);

// ----------------------------------------------------------------------------
// Child of tankSync
// ----------------------------------------------------------------------------

const kFeatureBaselineSync = FeatureClass(
  id: 'baselineSync',
  parent: _tankSync,
  requires: _tankSyncSet,
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'featureLabel_baselineSync',
  displayName: 'Baseline sync',
  descriptionKey: 'featureDescription_baselineSync',
  description: 'Sync driving baselines via TankSync.',
);

// ----------------------------------------------------------------------------
// Child of priceHistory
// ----------------------------------------------------------------------------

const kFeatureTflitePricePrediction = FeatureClass(
  id: 'tflitePricePrediction',
  parent: _priceHistory,
  requires: _priceHistorySet,
  defaultEnabled: false,
  // Compile-time gate (`kTflitePredictorEnabled` const) stays false
  // until a trained `.tflite` artifact ships under `assets/models/`.
  // Beta reflects the artifact-pending state.
  maturity: FeatureMaturity.beta,
  displayKey: 'featureLabel_tflitePricePrediction',
  displayName: 'TFLite price prediction',
  descriptionKey: 'featureDescription_tflitePricePrediction',
  description: 'On-device price forecast model — inference runs locally; '
      'features and predictions never leave the device.',
);

// ----------------------------------------------------------------------------
// Late-binding helpers
//
// Top-level + leaf parents/requires are declared as functions so Dart's
// const evaluator can resolve forward references inside the same library.
// The functions are lazy; resolution happens when `parent` or `requires`
// is read at runtime, by which point every const in this file is fully
// initialised.
// ----------------------------------------------------------------------------

FeatureClass? _none() => null;
Set<FeatureClass> _empty() => const {};

FeatureClass _obd2() => kFeatureObd2TripRecording;
Set<FeatureClass> _obd2Set() => {kFeatureObd2TripRecording};

FeatureClass _tankSync() => kFeatureTankSync;
Set<FeatureClass> _tankSyncSet() => {kFeatureTankSync};

FeatureClass _priceHistory() => kFeaturePriceHistory;
Set<FeatureClass> _priceHistorySet() => {kFeaturePriceHistory};
