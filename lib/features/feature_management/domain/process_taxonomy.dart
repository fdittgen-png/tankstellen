// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The process vocabulary from #4223, as code (#4224).
///
/// #4224's required hierarchy is
/// `Process → Subprocess → Workflow → Capability → implementation`.
/// This file owns the top two levels; [capability_ownership.dart] binds
/// each [Feature] to them.
///
/// ## Why this is not [FeatureCategory]
///
/// `feature_category.dart` says so itself: it "only governs which header
/// a feature renders under and in what order the headers appear" — a
/// presentation map, deliberately not a dependency concept. Process
/// ownership answers a different question ("what is the user trying to
/// accomplish"), and the two coexist until #4226 replaces the
/// category-driven UI. Renaming one into the other would lose the
/// render order the settings screen depends on.
///
/// ## Verbatim, on purpose
///
/// The names and subprocess lists below are copied from #4223's
/// taxonomy rather than paraphrased. #4226 renders these as process
/// cards and #4227 assigns every existing setting an owner among them;
/// if this file drifts from the issue, those two stop agreeing about
/// what a process IS.
library;

/// The nine process domains (#4223).
///
/// "These are process domains, not necessarily navigation tabs" — the
/// taxonomy is about what the user is doing, and navigation stays
/// task-oriented (#4218 owns that separately).
enum SparkiloProcess {
  findAndBuyEnergy,
  recordAndUnderstandDriving,
  improveEfficiencyAndCost,
  manageVehicle,
  manageExpensesAndDocuments,
  manageFleet,
  stayInformedAndAct,
  accountPrivacyAndData,
  administrationAndDeveloper,
}

/// A subprocess — the second level, still in the user's language.
///
/// Flat rather than nested per process: a Dart enum cannot be
/// parameterised by another enum's value, and a flat list with an
/// [owner] keeps the "exactly one owner" rule checkable
/// ([subprocessesOf] is derived, never hand-maintained).
enum SparkiloSubprocess {
  // 1. Find and buy energy
  findCheaperEnergy(SparkiloProcess.findAndBuyEnergy),
  compareStations(SparkiloProcess.findAndBuyEnergy),
  planRefuellingStop(SparkiloProcess.findAndBuyEnergy),
  navigateToStation(SparkiloProcess.findAndBuyEnergy),
  recordFillUp(SparkiloProcess.findAndBuyEnergy),

  // 2. Record and understand driving
  recordTrip(SparkiloProcess.recordAndUnderstandDriving),
  recoverRecording(SparkiloProcess.recordAndUnderstandDriving),
  useObd2(SparkiloProcess.recordAndUnderstandDriving),
  understandConsumption(SparkiloProcess.recordAndUnderstandDriving),
  understandDrivingBehaviour(SparkiloProcess.recordAndUnderstandDriving),
  reviewTripHistory(SparkiloProcess.recordAndUnderstandDriving),

  // 3. Improve efficiency and cost
  learnFromFillUps(SparkiloProcess.improveEfficiencyAndCost),
  compareActualVsExpected(SparkiloProcess.improveEfficiencyAndCost),
  identifyEcoOpportunities(SparkiloProcess.improveEfficiencyAndCost),
  trackCostPerKmAndSavings(SparkiloProcess.improveEfficiencyAndCost),
  compareVehiclesForJourney(SparkiloProcess.improveEfficiencyAndCost),

  // 4. Manage vehicle
  addOrIdentifyVehicle(SparkiloProcess.manageVehicle),
  switchCurrentVehicle(SparkiloProcess.manageVehicle),
  maintainVehicleInformation(SparkiloProcess.manageVehicle),
  pairObd2Adapter(SparkiloProcess.manageVehicle),
  vehicleFuelAndCalibrationContext(SparkiloProcess.manageVehicle),

  // 5. Manage expenses and documents
  captureReceipt(SparkiloProcess.manageExpensesAndDocuments),
  reviewExtractedValues(SparkiloProcess.manageExpensesAndDocuments),
  attachToFillUp(SparkiloProcess.manageExpensesAndDocuments),
  submitExpense(SparkiloProcess.manageExpensesAndDocuments),
  trackApprovalStatus(SparkiloProcess.manageExpensesAndDocuments),

  // 6. Manage fleet
  assignVehicles(SparkiloProcess.manageFleet),
  helpEmployeesSelectVehicle(SparkiloProcess.manageFleet),
  monitorAggregateCosts(SparkiloProcess.manageFleet),
  reviewFleetExpenses(SparkiloProcess.manageFleet),
  produceReportingOutputs(SparkiloProcess.manageFleet),

  // 7. Stay informed and act
  fuelPriceOpportunities(SparkiloProcess.stayInformedAndAct),
  personalOpportunityFeed(SparkiloProcess.stayInformedAndAct),
  pushNotifications(SparkiloProcess.stayInformedAndAct),
  favouritesAndWatchAreas(SparkiloProcess.stayInformedAndAct),
  alertsWithAttentionBudget(SparkiloProcess.stayInformedAndAct),

  // 8. Account, privacy and data
  accountAndProfile(SparkiloProcess.accountPrivacyAndData),
  privacyAndPermissions(SparkiloProcess.accountPrivacyAndData),
  syncAndBackup(SparkiloProcess.accountPrivacyAndData),
  dataExportAndDeletion(SparkiloProcess.accountPrivacyAndData),
  dataRetention(SparkiloProcess.accountPrivacyAndData),

  // 9. Administration / developer
  dataSources(SparkiloProcess.administrationAndDeveloper),
  diagnostics(SparkiloProcess.administrationAndDeveloper),
  developerTools(SparkiloProcess.administrationAndDeveloper),
  cacheAndMaintenance(SparkiloProcess.administrationAndDeveloper),
  advancedImportExport(SparkiloProcess.administrationAndDeveloper);

  const SparkiloSubprocess(this.owner);

  /// The process this subprocess belongs to. Exactly one, always —
  /// #4227's "no duplicate process ownership" starts here.
  final SparkiloProcess owner;
}

/// The subprocesses of [process], in declaration order.
Iterable<SparkiloSubprocess> subprocessesOf(SparkiloProcess process) =>
    SparkiloSubprocess.values.where((s) => s.owner == process);
