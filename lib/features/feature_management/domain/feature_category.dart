// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'feature.dart';

/// Presentation-only grouping of every [Feature] into an ordered set of
/// user-facing categories for the Settings → Feature management screen
/// (#2681).
///
/// This is a **presentation map, not an enum field** — the [Feature] enum
/// stays in its persistence/manifest order (renaming or reordering it
/// would break Hive keys). The settings screen consults [featureCategory]
/// to bucket the manifest-ordered groups under section headers, and
/// [categoryOrder] to render those sections top-to-bottom by user
/// value/frequency.
///
/// Behaviour-preserving: no feature is added or removed, no dependency
/// edge changes — this only governs which header a feature renders under
/// and in what order the headers appear.
enum FeatureCategory {
  /// Core finding/discovery: search, map visibility, routing, EV, calc.
  finding,

  /// Prices, alerts, history, reporting.
  prices,

  /// Fuel Station Radar — the in-trip approach overlay + voice (#2661).
  radar,

  /// Consumption tracking + trips + driving coach (the Conso card).
  consumption,

  /// Cross-device sync + backup.
  sync,

  /// Input / scanning helpers for logging fill-ups.
  input,

  /// Developer & experimental power-user tools (rendered last).
  developer,
}

/// Render order of the category sections, top-to-bottom, sequenced by
/// user value/frequency (#2681). Developer/experimental sits last.
const List<FeatureCategory> categoryOrder = <FeatureCategory>[
  FeatureCategory.finding,
  FeatureCategory.prices,
  FeatureCategory.radar,
  FeatureCategory.consumption,
  FeatureCategory.sync,
  FeatureCategory.input,
  FeatureCategory.developer,
];

/// Single source of truth mapping every [Feature] to the category section
/// it renders under (#2681). Every value in [Feature] MUST appear here
/// exactly once — [categoryOf] asserts completeness.
///
/// Note: the Conso-card-internal flags (`obd2TripRecording`,
/// `manualConsumption`, `showConsumptionTab`) and the Conso dependents
/// (`consumptionAnalytics`, `gamification`, `hapticEcoCoach`,
/// `glideCoach`, `gpsTripPath`, `autoRecord`, `experimentalOemPids`) all
/// map to [FeatureCategory.consumption] because the Conso card — pinned
/// to that section — owns their rendering. `obd2Optional` and
/// `carbonDashboard` also live in the consumption section.
const Map<Feature, FeatureCategory> featureCategory = <Feature, FeatureCategory>{
  // 1. Finding & map.
  Feature.showFuel: FeatureCategory.finding,
  Feature.showElectric: FeatureCategory.finding,
  Feature.evCharging: FeatureCategory.finding,
  Feature.routePlanning: FeatureCategory.finding,
  Feature.fuelCalculator: FeatureCategory.finding,

  // 2. Prices & alerts.
  Feature.priceAlerts: FeatureCategory.prices,
  Feature.priceHistory: FeatureCategory.prices,
  Feature.tflitePricePrediction: FeatureCategory.prices,
  Feature.communityPriceReports: FeatureCategory.prices,
  Feature.paymentQrScan: FeatureCategory.prices,

  // 3. Fuel Station Radar.
  Feature.approachOverlay: FeatureCategory.radar,
  Feature.voiceAnnouncements: FeatureCategory.radar,

  // 4. Consumption (Conso card + dependents + obd2Optional + carbon).
  Feature.obd2TripRecording: FeatureCategory.consumption,
  Feature.manualConsumption: FeatureCategory.consumption,
  Feature.showConsumptionTab: FeatureCategory.consumption,
  Feature.consumptionAnalytics: FeatureCategory.consumption,
  Feature.gamification: FeatureCategory.consumption,
  Feature.hapticEcoCoach: FeatureCategory.consumption,
  Feature.glideCoach: FeatureCategory.consumption,
  Feature.gpsTripPath: FeatureCategory.consumption,
  Feature.autoRecord: FeatureCategory.consumption,
  Feature.experimentalOemPids: FeatureCategory.consumption,
  Feature.obd2Optional: FeatureCategory.consumption,
  Feature.carbonDashboard: FeatureCategory.consumption,

  // 5. Sync & backup.
  Feature.tankSync: FeatureCategory.sync,
  Feature.baselineSync: FeatureCategory.sync,

  // 6. Input & scanning.
  Feature.addFillUpOcrReceipt: FeatureCategory.input,
  Feature.addFillUpOcrPump: FeatureCategory.input,
  Feature.addFillUpShareIntentReceipt: FeatureCategory.input,
  Feature.loyaltyCards: FeatureCategory.input,

  // 7. Developer & experimental (last).
  Feature.developerPatToken: FeatureCategory.developer,
  Feature.debugMode: FeatureCategory.developer,
  Feature.startupTrace: FeatureCategory.developer,
};

/// Returns the [FeatureCategory] for [feature]. Asserts the [feature] is
/// present in [featureCategory] — a missing mapping is a programmer error
/// (every Feature must be placed in exactly one category).
FeatureCategory categoryOf(Feature feature) {
  final category = featureCategory[feature];
  assert(
    category != null,
    'Feature $feature has no FeatureCategory mapping — add it to '
    'featureCategory in feature_category.dart.',
  );
  return category ?? FeatureCategory.developer;
}
