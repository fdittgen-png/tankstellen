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

String featureLabel(AppLocalizations? l, Feature f) {
  final m = FeatureManifest.defaultManifest.entryFor(f);
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureLabel_obd2TripRecording ?? m.displayName;
    case Feature.gamification:
      return l?.featureLabel_gamification ?? m.displayName;
    case Feature.hapticEcoCoach:
      return l?.featureLabel_hapticEcoCoach ?? m.displayName;
    case Feature.tankSync:
      return l?.featureLabel_tankSync ?? m.displayName;
    case Feature.consumptionAnalytics:
      return l?.featureLabel_consumptionAnalytics ?? m.displayName;
    case Feature.baselineSync:
      return l?.featureLabel_baselineSync ?? m.displayName;
    case Feature.priceAlerts:
      return l?.featureLabel_priceAlerts ?? m.displayName;
    case Feature.priceHistory:
      return l?.featureLabel_priceHistory ?? m.displayName;
    case Feature.routePlanning:
      return l?.featureLabel_routePlanning ?? m.displayName;
    case Feature.evCharging:
      return l?.featureLabel_evCharging ?? m.displayName;
    case Feature.glideCoach:
      return l?.featureLabel_glideCoach ?? m.displayName;
    case Feature.gpsTripPath:
      return l?.featureLabel_gpsTripPath ?? m.displayName;
    case Feature.autoRecord:
      return l?.featureLabel_autoRecord ?? m.displayName;
    case Feature.showFuel:
      return l?.featureLabel_showFuel ?? m.displayName;
    case Feature.showElectric:
      return l?.featureLabel_showElectric ?? m.displayName;
    case Feature.showConsumptionTab:
      return l?.featureLabel_showConsumptionTab ?? m.displayName;
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189) so the toggle is readable.
      return m.displayName;
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189) so the toggle is readable.
      return m.displayName;
    case Feature.tflitePricePrediction:
      return l?.featureLabel_tflitePricePrediction ?? m.displayName;
    case Feature.fuelCalculator:
      return l?.featureLabel_fuelCalculator ?? m.displayName;
    case Feature.carbonDashboard:
      return l?.featureLabel_carbonDashboard ?? m.displayName;
    case Feature.experimentalOemPids:
      return l?.featureLabel_experimentalOemPids ?? m.displayName;
    case Feature.paymentQrScan:
      return l?.featureLabel_paymentQrScan ?? m.displayName;
    case Feature.communityPriceReports:
      return l?.featureLabel_communityPriceReports ?? m.displayName;
    case Feature.obd2Optional:
      return l?.featureLabel_obd2Optional ?? m.displayName;
    case Feature.addFillUpOcrReceipt:
      return l?.featureLabel_addFillUpOcrReceipt ?? m.displayName;
    case Feature.addFillUpOcrPump:
      return l?.featureLabel_addFillUpOcrPump ?? m.displayName;
    case Feature.developerPatToken:
      return l?.featureLabel_developerPatToken ?? m.displayName;
    case Feature.debugMode:
      return l?.featureLabel_debugMode ?? m.displayName;
    case Feature.approachOverlay:
      // #2681 — renamed to "Fuel Station Radar"; the manifest displayName
      // fallback was renamed in lock-step so this stays the SSoT.
      return l?.featureLabel_approachOverlay ?? m.displayName;
    case Feature.voiceAnnouncements:
      return l?.featureLabel_voiceAnnouncements ?? m.displayName;
  }
}

String featureDescription(AppLocalizations? l, Feature f) {
  final m = FeatureManifest.defaultManifest.entryFor(f);
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureDescription_obd2TripRecording ?? m.description;
    case Feature.gamification:
      return l?.featureDescription_gamification ?? m.description;
    case Feature.hapticEcoCoach:
      return l?.featureDescription_hapticEcoCoach ?? m.description;
    case Feature.tankSync:
      return l?.featureDescription_tankSync ?? m.description;
    case Feature.consumptionAnalytics:
      return l?.featureDescription_consumptionAnalytics ?? m.description;
    case Feature.baselineSync:
      return l?.featureDescription_baselineSync ?? m.description;
    case Feature.priceAlerts:
      return l?.featureDescription_priceAlerts ?? m.description;
    case Feature.priceHistory:
      return l?.featureDescription_priceHistory ?? m.description;
    case Feature.routePlanning:
      return l?.featureDescription_routePlanning ?? m.description;
    case Feature.evCharging:
      return l?.featureDescription_evCharging ?? m.description;
    case Feature.glideCoach:
      return l?.featureDescription_glideCoach ?? m.description;
    case Feature.gpsTripPath:
      return l?.featureDescription_gpsTripPath ?? m.description;
    case Feature.autoRecord:
      return l?.featureDescription_autoRecord ?? m.description;
    case Feature.showFuel:
      return l?.featureDescription_showFuel ?? m.description;
    case Feature.showElectric:
      return l?.featureDescription_showElectric ?? m.description;
    case Feature.showConsumptionTab:
      return l?.featureDescription_showConsumptionTab ?? m.description;
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189).
      return m.description;
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189).
      return m.description;
    case Feature.tflitePricePrediction:
      return l?.featureDescription_tflitePricePrediction ?? m.description;
    case Feature.fuelCalculator:
      return l?.featureDescription_fuelCalculator ?? m.description;
    case Feature.carbonDashboard:
      return l?.featureDescription_carbonDashboard ?? m.description;
    case Feature.experimentalOemPids:
      return l?.featureDescription_experimentalOemPids ?? m.description;
    case Feature.paymentQrScan:
      return l?.featureDescription_paymentQrScan ?? m.description;
    case Feature.communityPriceReports:
      return l?.featureDescription_communityPriceReports ?? m.description;
    case Feature.obd2Optional:
      // note: manifest differs — the manifest description carries an extra
      // "Calibration drops to confidence tier A…" sentence the toggle
      // subtitle intentionally omits, so keep the local literal here to
      // preserve the existing user-facing text (#2189).
      return l?.featureDescription_obd2Optional ??
          'When off, the app records GPS-only trajets without needing an '
              'OBD2 adapter. Coaching is reduced — no instant L/100 km, '
              'fewer engine-derived signals.';
    case Feature.addFillUpOcrReceipt:
      return l?.featureDescription_addFillUpOcrReceipt ?? m.description;
    case Feature.addFillUpOcrPump:
      return l?.featureDescription_addFillUpOcrPump ?? m.description;
    case Feature.developerPatToken:
      // note: manifest differs — this subtitle adds a "Power-user /
      // contributor feature." sentence absent from the manifest
      // description, so keep the local literal to preserve the existing
      // user-facing text (#2189).
      return l?.featureDescription_developerPatToken ??
          'Enable the bad-scan feedback panel that auto-files GitHub '
              'issues with a Personal Access Token. Power-user / '
              'contributor feature.';
    case Feature.debugMode:
      return l?.featureDescription_debugMode ?? m.description;
    case Feature.approachOverlay:
      return l?.featureDescription_approachOverlay ?? m.description;
    case Feature.voiceAnnouncements:
      return l?.featureDescription_voiceAnnouncements ?? m.description;
  }
}

String blockedEnableMessage(AppLocalizations? l, Feature f) {
  switch (f) {
    case Feature.gamification:
      return l?.featureBlockedEnable_gamification ??
          'Enable OBD2 trip recording first';
    case Feature.hapticEcoCoach:
      return l?.featureBlockedEnable_hapticEcoCoach ??
          'Enable OBD2 trip recording first';
    case Feature.consumptionAnalytics:
      return l?.featureBlockedEnable_consumptionAnalytics ??
          'Enable OBD2 trip recording first';
    case Feature.baselineSync:
      return l?.featureBlockedEnable_baselineSync ?? 'Enable TankSync first';
    case Feature.glideCoach:
      return l?.featureBlockedEnable_glideCoach ??
          'Enable OBD2 trip recording first';
    case Feature.gpsTripPath:
      return l?.featureBlockedEnable_gpsTripPath ??
          'Enable OBD2 trip recording first';
    case Feature.autoRecord:
      return l?.featureBlockedEnable_autoRecord ??
          'Enable OBD2 trip recording first';
    case Feature.showConsumptionTab:
      return l?.featureBlockedEnable_showConsumptionTab ??
          'Enable OBD2 trip recording first';
    case Feature.experimentalOemPids:
      return l?.featureBlockedEnable_experimentalOemPids ??
          'Enable OBD2 trip recording first';
    case Feature.tflitePricePrediction:
      return l?.featureBlockedEnable_tflitePricePrediction ??
          'Enable price history first';
    case Feature.voiceAnnouncements:
      // #2681 — renamed prerequisite from "approach overlay" to "Fuel
      // Station Radar" to match the renamed parent toggle.
      return l?.featureBlockedEnable_voiceAnnouncements ??
          'Enable the Fuel Station Radar first';
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
    case Feature.developerPatToken:
    case Feature.debugMode:
    case Feature.approachOverlay:
      return 'Prerequisites not met';
  }
}
