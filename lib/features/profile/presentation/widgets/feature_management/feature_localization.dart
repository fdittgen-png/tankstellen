// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/domain/feature.dart';
import '../../../../feature_management/domain/feature_manifest.dart';

// ---------------------------------------------------------------------------
// Localised-string lookup helpers for the Feature management section.
//
// `AppLocalizations` exposes one getter per key, so a per-feature switch
// is the simplest mapping that stays static-analysis-friendly (compile-
// time exhaustiveness over `Feature`). When the localisation lookup is
// null (test fixtures that omit `AppLocalizations`) the fallback reads the
// English string straight off `FeatureManifest.defaultManifest` — the
// single source of truth — instead of re-typing the same literal here
// (#2189). The two features whose manifest text intentionally differs from
// the toggle text keep a local literal, flagged inline below.
//
// Extracted from feature_management_section.dart for #2681 (file-length).
// ---------------------------------------------------------------------------

String featureLabel(AppLocalizations l, Feature f) {
  final m = FeatureManifest.defaultManifest.entryFor(f);
  switch (f) {
    case Feature.obd2TripRecording:
      return l.featureLabel_obd2TripRecording;
    case Feature.gamification:
      return l.featureLabel_gamification;
    case Feature.hapticEcoCoach:
      return l.featureLabel_hapticEcoCoach;
    case Feature.tankSync:
      return l.featureLabel_tankSync;
    case Feature.consumptionAnalytics:
      return l.featureLabel_consumptionAnalytics;
    case Feature.baselineSync:
      return l.featureLabel_baselineSync;
    case Feature.priceAlerts:
      return l.featureLabel_priceAlerts;
    case Feature.priceHistory:
      return l.featureLabel_priceHistory;
    case Feature.routePlanning:
      return l.featureLabel_routePlanning;
    case Feature.evCharging:
      return l.featureLabel_evCharging;
    case Feature.glideCoach:
      return l.featureLabel_glideCoach;
    case Feature.gpsTripPath:
      return l.featureLabel_gpsTripPath;
    case Feature.autoRecord:
      return l.featureLabel_autoRecord;
    case Feature.showFuel:
      return l.featureLabel_showFuel;
    case Feature.showElectric:
      return l.featureLabel_showElectric;
    case Feature.showConsumptionTab:
      return l.featureLabel_showConsumptionTab;
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189) so the toggle is readable.
      return m.displayName;
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189) so the toggle is readable.
      return m.displayName;
    case Feature.tflitePricePrediction:
      return l.featureLabel_tflitePricePrediction;
    case Feature.fuelCalculator:
      return l.featureLabel_fuelCalculator;
    case Feature.carbonDashboard:
      return l.featureLabel_carbonDashboard;
    case Feature.experimentalOemPids:
      return l.featureLabel_experimentalOemPids;
    case Feature.paymentQrScan:
      return l.featureLabel_paymentQrScan;
    case Feature.communityPriceReports:
      return l.featureLabel_communityPriceReports;
    case Feature.obd2Optional:
      return l.featureLabel_obd2Optional;
    case Feature.addFillUpOcrReceipt:
      return l.featureLabel_addFillUpOcrReceipt;
    case Feature.addFillUpOcrPump:
      return l.featureLabel_addFillUpOcrPump;
    case Feature.addFillUpShareIntentReceipt:
      return l.featureLabel_addFillUpShareIntentReceipt;
    case Feature.developerPatToken:
      return l.featureLabel_developerPatToken;
    case Feature.debugMode:
      return l.featureLabel_debugMode;
    case Feature.approachOverlay:
      // #2681 — renamed to "Fuel Station Radar"; the manifest displayName
      // fallback was renamed in lock-step so this stays the SSoT.
      return l.featureLabel_approachOverlay;
    case Feature.voiceAnnouncements:
      return l.featureLabel_voiceAnnouncements;
  }
}

String featureDescription(AppLocalizations l, Feature f) {
  final m = FeatureManifest.defaultManifest.entryFor(f);
  switch (f) {
    case Feature.obd2TripRecording:
      return l.featureDescription_obd2TripRecording;
    case Feature.gamification:
      return l.featureDescription_gamification;
    case Feature.hapticEcoCoach:
      return l.featureDescription_hapticEcoCoach;
    case Feature.tankSync:
      return l.featureDescription_tankSync;
    case Feature.consumptionAnalytics:
      return l.featureDescription_consumptionAnalytics;
    case Feature.baselineSync:
      return l.featureDescription_baselineSync;
    case Feature.priceAlerts:
      return l.featureDescription_priceAlerts;
    case Feature.priceHistory:
      return l.featureDescription_priceHistory;
    case Feature.routePlanning:
      return l.featureDescription_routePlanning;
    case Feature.evCharging:
      return l.featureDescription_evCharging;
    case Feature.glideCoach:
      return l.featureDescription_glideCoach;
    case Feature.gpsTripPath:
      return l.featureDescription_gpsTripPath;
    case Feature.autoRecord:
      return l.featureDescription_autoRecord;
    case Feature.showFuel:
      return l.featureDescription_showFuel;
    case Feature.showElectric:
      return l.featureDescription_showElectric;
    case Feature.showConsumptionTab:
      return l.featureDescription_showConsumptionTab;
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189).
      return m.description;
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189).
      return m.description;
    case Feature.tflitePricePrediction:
      return l.featureDescription_tflitePricePrediction;
    case Feature.fuelCalculator:
      return l.featureDescription_fuelCalculator;
    case Feature.carbonDashboard:
      return l.featureDescription_carbonDashboard;
    case Feature.experimentalOemPids:
      return l.featureDescription_experimentalOemPids;
    case Feature.paymentQrScan:
      return l.featureDescription_paymentQrScan;
    case Feature.communityPriceReports:
      return l.featureDescription_communityPriceReports;
    case Feature.obd2Optional:
      // note: manifest differs — the manifest description carries an extra
      // "Calibration drops to confidence tier A…" sentence the toggle
      // subtitle intentionally omits, so keep the local literal here to
      // preserve the existing user-facing text (#2189).
      return l.featureDescription_obd2Optional;
    case Feature.addFillUpOcrReceipt:
      return l.featureDescription_addFillUpOcrReceipt;
    case Feature.addFillUpOcrPump:
      return l.featureDescription_addFillUpOcrPump;
    case Feature.addFillUpShareIntentReceipt:
      return l.featureDescription_addFillUpShareIntentReceipt;
    case Feature.developerPatToken:
      // note: manifest differs — this subtitle adds a "Power-user /
      // contributor feature." sentence absent from the manifest
      // description, so keep the local literal to preserve the existing
      // user-facing text (#2189).
      return l.featureDescription_developerPatToken;
    case Feature.debugMode:
      return l.featureDescription_debugMode;
    case Feature.approachOverlay:
      return l.featureDescription_approachOverlay;
    case Feature.voiceAnnouncements:
      return l.featureDescription_voiceAnnouncements;
  }
}

String blockedEnableMessage(AppLocalizations l, Feature f) {
  switch (f) {
    case Feature.gamification:
      return l.featureBlockedEnable_gamification;
    case Feature.hapticEcoCoach:
      return l.featureBlockedEnable_hapticEcoCoach;
    case Feature.consumptionAnalytics:
      return l.featureBlockedEnable_consumptionAnalytics;
    case Feature.baselineSync:
      return l.featureBlockedEnable_baselineSync;
    case Feature.glideCoach:
      return l.featureBlockedEnable_glideCoach;
    case Feature.gpsTripPath:
      return l.featureBlockedEnable_gpsTripPath;
    case Feature.autoRecord:
      return l.featureBlockedEnable_autoRecord;
    case Feature.showConsumptionTab:
      return l.featureBlockedEnable_showConsumptionTab;
    case Feature.experimentalOemPids:
      return l.featureBlockedEnable_experimentalOemPids;
    case Feature.tflitePricePrediction:
      return l.featureBlockedEnable_tflitePricePrediction;
    case Feature.voiceAnnouncements:
      // #2681 — renamed prerequisite from "approach overlay" to "Fuel
      // Station Radar" to match the renamed parent toggle.
      return l.featureBlockedEnable_voiceAnnouncements;
    // Features without prerequisites can never reach this branch — the
    // dependency-graph helpers short-circuit. Return a generic fallback
    // so the function is total in case the manifest changes.
    case Feature.obd2TripRecording:
    case Feature.tankSync:
    case Feature.priceAlerts:
    case Feature.priceHistory:
    case Feature.routePlanning:
    case Feature.evCharging:
    case Feature.showFuel:
    case Feature.showElectric:
    case Feature.manualConsumption:
    case Feature.loyaltyCards:
    case Feature.fuelCalculator:
    case Feature.carbonDashboard:
    case Feature.paymentQrScan:
    case Feature.communityPriceReports:
    case Feature.obd2Optional:
    case Feature.addFillUpOcrReceipt:
    case Feature.addFillUpOcrPump:
    case Feature.addFillUpShareIntentReceipt:
    case Feature.developerPatToken:
    case Feature.debugMode:
    case Feature.approachOverlay:
      return 'Prerequisites not met';
  }
}
