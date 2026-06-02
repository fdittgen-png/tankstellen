// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'build_channel.dart';
import 'feature.dart';
import 'feature_manifest_entry.dart';

export 'feature_manifest_entry.dart';

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

  /// Authoritative manifest used at runtime. Each entry's `defaultOn`
  /// argument is the source of truth; the inline comments on each
  /// entry below carry the rationale + issue references.
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
      // #1543 — this flag now drives the no-ML, on-device "best time to
      // fill up?" heuristic (`fillUpGuidanceProvider`) instead of the
      // dormant TFLite path. Kept default-off and opt-in (it is in no
      // AppProfile preset bundle — see app_profile.dart) so users
      // deliberately turn it on from Feature management; `requires:
      // {priceHistory}` scopes it to users who collect the local
      // history it reads. The original TFLite path stays dormant behind
      // its own compile-time `kTflitePredictorEnabled` const, unaffected
      // by this flag.
      defaultOn: false,
      requires: {Feature.priceHistory},
      displayName: 'Best time to fill up',
      description:
          'On-device guidance on when to fill up, computed from your '
              'local price history — nothing leaves the device.',
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
    Feature.addFillUpOcrReceipt: FeatureManifestEntry.allChannels(
      feature: Feature.addFillUpOcrReceipt,
      // Default-on (#2110): receipt OCR works reliably enough in
      // production to ship enabled. No prerequisites.
      defaultOn: true,
      displayName: 'Receipt OCR',
      description:
          'Scan a printed receipt on the Add fill-up screen to pre-fill '
              'date, litres, total, and station.',
    ),
    Feature.addFillUpOcrPump: FeatureManifestEntry.allChannels(
      feature: Feature.addFillUpOcrPump,
      // Default-off (#2110): pump-display OCR doesn't read pump LEDs
      // reliably yet. The button hides until the user opts in from
      // Feature management. No prerequisites.
      defaultOn: false,
      displayName: 'Pump display OCR (experimental)',
      description:
          'Scan a fuel pump display to pre-fill the form. Recognition '
              'is unreliable today — opt in only if you want to test.',
    ),
    Feature.addFillUpShareIntentReceipt: FeatureManifestEntry.allChannels(
      feature: Feature.addFillUpShareIntentReceipt,
      // Default-off (#2735): opt-in. When on, Sparkilo appears in the OS
      // share sheet for images and a shared receipt prefills the Add
      // fill-up form via on-device OCR. No prerequisites.
      defaultOn: false,
      displayName: 'Share receipt to import',
      description:
          'Share a receipt photo from another app to pre-fill a fill-up '
              '— date, litres, total, and station are read on-device.',
    ),
    // Default-off (#2116-6): the PAT entry is power-user / contributor
    // territory. SharePlus fallback covers everyone else.
    Feature.developerPatToken: FeatureManifestEntry.allChannels(
      feature: Feature.developerPatToken,
      defaultOn: false,
      displayName: 'Developer feedback (GitHub PAT)',
      description:
          'Enable the bad-scan feedback panel that auto-files GitHub '
              'issues with a Personal Access Token.',
    ),
    // Default-off (#2248): gates the Developer tools section. No prereqs.
    Feature.debugMode: FeatureManifestEntry.allChannels(
      feature: Feature.debugMode,
      defaultOn: false,
      displayName: 'Developer / Debug mode',
      description: 'Surface a Developer tools section in Settings with '
          'diagnostics: error-log export, test notifications, a test-alert '
          'pipeline run, a feature-flag dump, clear caches, and diagnostics.',
    ),
    // Default-off in the manifest baseline (#2382); the `AppProfile.medium`
    // and `AppProfile.full` presets flip it ON so the in-trip approach
    // overlay is opt-out for the active driving tiers. No prerequisite —
    // the live detector only runs while a trip is recording and degrades
    // gracefully on GPS-only trajets.
    Feature.approachOverlay: FeatureManifestEntry.allChannels(
      feature: Feature.approachOverlay,
      defaultOn: false,
      // #2681 — renamed "Approach overlay" → "Fuel Station Radar" to match
      // the #2661 trip-radar wording (value-only; the enum value + Hive
      // persistence key `approachOverlay` are unchanged).
      displayName: 'Fuel Station Radar',
      description:
          'Turn the floating trip tile into a live Fuel Station Radar — '
              'as you near a fuel station it flips to the fuel type\'s '
              'colour and shows the price.',
    ),
    // Default-off on every channel (#2569) — speaking aloud while driving
    // is strictly opt-in and is in no AppProfile preset bundle.
    // `requires: {approachOverlay}` because the announcement consumes the
    // same live geofence stream (`approachStateProvider`) the overlay
    // drives: without the overlay the detector never starts, so there is
    // nothing to announce.
    Feature.voiceAnnouncements: FeatureManifestEntry.allChannels(
      feature: Feature.voiceAnnouncements,
      defaultOn: false,
      requires: {Feature.approachOverlay},
      displayName: 'Voice announcements',
      description:
          'Speak nearby cheap fuel stations aloud as you drive, so you '
              'can keep your eyes on the road.',
    ),
  });
}
