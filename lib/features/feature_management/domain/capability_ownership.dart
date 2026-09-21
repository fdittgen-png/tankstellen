// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'feature.dart';
import 'process_taxonomy.dart';

/// Which subprocess owns each capability (#4224).
///
/// The third level of #4224's hierarchy: every [Feature] belongs to
/// exactly one [SparkiloSubprocess], and therefore to exactly one
/// [SparkiloProcess]. #4227's migration matrix reads this to assign
/// every existing setting an owner; #4226 renders processes whose
/// contents come from here rather than from a hand-written card list.
///
/// ## One owner, not a category
///
/// `featureCategory` maps the same features to render headers. This maps
/// them to what the user is trying to DO. They disagree on purpose — the
/// Conso card owns the rendering of `glideCoach`, but
/// the user turning those on is improving efficiency, not "tracking
/// consumption". Keeping both means #4226 can move to process language
/// without breaking the settings screen mid-flight.
const Map<Feature, SparkiloSubprocess> capabilityOwner =
    <Feature, SparkiloSubprocess>{
  // ── 1. Find and buy energy ──────────────────────────────────────
  Feature.showFuel: SparkiloSubprocess.findCheaperEnergy,
  Feature.showElectric: SparkiloSubprocess.findCheaperEnergy,
  Feature.evCharging: SparkiloSubprocess.findCheaperEnergy,
  Feature.routePlanning: SparkiloSubprocess.planRefuellingStop,
  Feature.fuelCalculator: SparkiloSubprocess.compareStations,
  Feature.loyaltyCards: SparkiloSubprocess.compareStations,
  Feature.paymentQrScan: SparkiloSubprocess.recordFillUp,
  Feature.manualConsumption: SparkiloSubprocess.recordFillUp,

  // ── 2. Record and understand driving ────────────────────────────
  Feature.obd2TripRecording: SparkiloSubprocess.recordTrip,
  Feature.autoRecord: SparkiloSubprocess.recordTrip,
  Feature.gpsTripPath: SparkiloSubprocess.recordTrip,
  Feature.obd2Optional: SparkiloSubprocess.useObd2,
  Feature.experimentalOemPids: SparkiloSubprocess.useObd2,
  Feature.showConsumptionTab: SparkiloSubprocess.reviewTripHistory,
  Feature.consumptionAnalytics: SparkiloSubprocess.understandConsumption,

  // ── 3. Improve efficiency and cost ──────────────────────────────
  // Rendered under the Conso card, but the user enabling these is
  // chasing efficiency — see the class doc on why the two maps differ.
  Feature.hapticEcoCoach: SparkiloSubprocess.identifyEcoOpportunities,
  Feature.glideCoach: SparkiloSubprocess.identifyEcoOpportunities,
  Feature.carbonDashboard: SparkiloSubprocess.trackCostPerKmAndSavings,

  // ── 4. Manage vehicle ───────────────────────────────────────────
  // Vehicle identity and adapter pairing are screens, not flags. The
  // one flag here is #4212's fleet mode: what the employee turning it
  // on is doing is picking the right company car, so it is owned by
  // `switchCurrentVehicle` — not by the fleet process, which is the
  // manager's side of the same epic.
  Feature.fleetMode: SparkiloSubprocess.switchCurrentVehicle,

  // ── 5. Manage expenses and documents ────────────────────────────
  Feature.addFillUpOcrReceipt: SparkiloSubprocess.captureReceipt,
  Feature.addFillUpShareIntentReceipt: SparkiloSubprocess.captureReceipt,

  // ── 6. Manage fleet (#4212) ─────────────────────────────────────
  // The manager's side: watching the org's cost, never a person.
  Feature.fleetManagerTools: SparkiloSubprocess.monitorAggregateCosts,

  // ── 7. Stay informed and act ────────────────────────────────────
  Feature.priceAlerts: SparkiloSubprocess.alertsWithAttentionBudget,
  Feature.priceHistory: SparkiloSubprocess.fuelPriceOpportunities,
  Feature.tflitePricePrediction: SparkiloSubprocess.fuelPriceOpportunities,
  Feature.communityPriceReports: SparkiloSubprocess.fuelPriceOpportunities,
  Feature.approachOverlay: SparkiloSubprocess.favouritesAndWatchAreas,
  Feature.voiceAnnouncements: SparkiloSubprocess.pushNotifications,
  Feature.voiceFeedback: SparkiloSubprocess.pushNotifications,

  // ── 8. Account, privacy and data ────────────────────────────────
  Feature.tankSync: SparkiloSubprocess.syncAndBackup,
  Feature.baselineSync: SparkiloSubprocess.syncAndBackup,

  // ── 9. Administration / developer ───────────────────────────────
  Feature.debugMode: SparkiloSubprocess.diagnostics,
  Feature.startupTrace: SparkiloSubprocess.diagnostics,
  Feature.developerPatToken: SparkiloSubprocess.developerTools,
};

/// The subprocess that owns [feature].
///
/// Asserts rather than throws, mirroring `categoryOf`: a missing owner
/// is a programmer error caught in debug/tests, and production falls
/// back to diagnostics rather than crashing a settings screen.
SparkiloSubprocess ownerOf(Feature feature) {
  final owner = capabilityOwner[feature];
  assert(
    owner != null,
    'Feature $feature has no process owner — add it to capabilityOwner '
    'in capability_ownership.dart (#4224).',
  );
  return owner ?? SparkiloSubprocess.diagnostics;
}

/// The process that owns [feature].
SparkiloProcess processOf(Feature feature) => ownerOf(feature).owner;

/// Every capability owned by [process], in [Feature] declaration order.
Iterable<Feature> capabilitiesOf(SparkiloProcess process) =>
    Feature.values.where((f) => capabilityOwner[f]?.owner == process);

/// Features with no declared owner — the ratchet's working set.
Iterable<Feature> get unownedCapabilities =>
    Feature.values.where((f) => !capabilityOwner.containsKey(f));
