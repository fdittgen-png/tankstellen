/// Central catalogue of toggleable application features (#1373 phase 1).
///
/// This enum is the manifest other systems consult — it does NOT yet drive
/// runtime behaviour for the existing scattered toggles (`autoRecord`,
/// `gamificationEnabled`, etc.). Phase 3 migrations of issue #1373 will
/// route those legacy paths through this enum one feature at a time.
///
/// Add a one-line dartdoc above each value naming the issue or area it
/// gates. Persistence keys use [Enum.name], so values may be reordered or
/// inserted but MUST NOT be renamed without a migration.
enum Feature {
  /// OBD2-driven trip capture (foundation for gamification, eco-coach,
  /// consumption analytics, glide-coach, GPS path).
  obd2TripRecording,

  /// Driving scores + badges (#781). Requires [obd2TripRecording].
  gamification,

  /// Real-time haptic eco-coach feedback during recording (#1194).
  /// Requires [obd2TripRecording].
  hapticEcoCoach,

  /// Cross-device sync via Supabase (TankSync).
  tankSync,

  /// Fill-up / trip analysis tab (#769). Requires [obd2TripRecording].
  consumptionAnalytics,

  /// Driving-baseline sync over TankSync (#769). Requires [tankSync].
  baselineSync,

  /// Threshold-based price-drop notifications.
  priceAlerts,

  /// 30-day price history charts.
  priceHistory,

  /// Along-route cheapest-stop planner.
  routePlanning,

  /// EV charging stations via OpenChargeMap.
  evCharging,

  /// Hypermiling glide-coach (#1125, future). Requires [obd2TripRecording].
  glideCoach,

  /// GPS path persistence on trips (#1374 phase 1, future). Requires
  /// [obd2TripRecording].
  gpsTripPath,

  /// Master gate for hands-free trip auto-record (#1004). Wraps the
  /// per-vehicle [VehicleProfile.autoRecord] bool — the per-vehicle
  /// field STAYS so each vehicle keeps its own opt-in, but this central
  /// flag is consulted FIRST: when off, no vehicle auto-records
  /// regardless of its bool. Requires [obd2TripRecording] (auto-record
  /// without trip-capture is a contradiction).
  autoRecord,

  /// Visibility of fuel-station results in search and on the map
  /// (#1373 phase 3c). Wraps the legacy `UserProfile.showFuel` bool —
  /// the central flag is the single source of truth post-migration;
  /// the legacy field stays for the one-shot migration read.
  showFuel,

  /// Visibility of EV charging-station results in search and on the
  /// map (#1373 phase 3c). Wraps the legacy `UserProfile.showElectric`
  /// bool — the central flag is the single source of truth post-
  /// migration; the legacy field stays for the one-shot migration read.
  showElectric,

  /// Visibility of the consumption analytics tab in the bottom
  /// navigation (#1373 phase 3c). Wraps the legacy
  /// `UserProfile.showConsumptionTab` bool. Requires
  /// [obd2TripRecording] — the consumption analytics tab has nothing
  /// to render without trip data, so the dependency edge guards
  /// against an empty surface in the UI.
  showConsumptionTab,

  /// Manual fuel fill-up + manual EV charging logs without OBD2
  /// (#1517 — Medium use-mode profile). Surfaces the Fuel and
  /// Charging tabs of the consumption screen for users who track
  /// their consumption by hand. Default-off; flipped on by the
  /// `AppProfile.medium` and `AppProfile.full` presets.
  manualConsumption,

  /// Loyalty / fuel-club discount cards (e.g. TotalEnergies pilot)
  /// (#1517 — Full use-mode profile). Surfaces the "Fuel club cards"
  /// section in Settings → Consumption and applies per-litre
  /// discounts in price comparisons. Default-off; flipped on only
  /// by the `AppProfile.full` preset.
  loyaltyCards,

  /// On-device TFLite price-prediction model (#1543, future). Requires
  /// [priceHistory] — the predictor consumes the same 30-day window the
  /// history feature already collects. Default-off and gated by a
  /// compile-time `kTflitePredictorEnabled` const so the toggle is a
  /// no-op until a trained `.tflite` artifact is committed and the
  /// const is flipped. Heuristic fallback always covers the gap.
  tflitePricePrediction,

  /// The fuel-cost Calculator (#1613). The screen + logic already exist
  /// and are tested; this flag gates the navigation entry point that
  /// makes its `/calculator` route reachable. Default-on.
  fuelCalculator,

  /// The Carbon dashboard (#1613). Gates the Consumption-tab AppBar eco
  /// action and the `/carbon` route. Default-on — the dashboard already
  /// shipped reachable, so the flag preserves current behaviour while
  /// bringing it under central feature management.
  carbonDashboard,

  /// Experimental OEM-PID exact-fuel-level path (#1615). When on and the
  /// connected adapter is OEM-PID-capable, the trip-recording fuel
  /// sampler reads exact litres-in-tank via [OemPidRegistry] instead of
  /// the coarse `percent × tank capacity` conversion. Default-off — an
  /// opt-in experiment gated additionally on the adapter capability tier.
  /// Requires [obd2TripRecording].
  experimentalOemPids,

  /// Scan-to-pay QR reader on the station-detail screen (#1638). Gates
  /// the "Scan payment QR" AppBar action. Default-on — the action
  /// already shipped reachable, so the flag preserves current behaviour
  /// while bringing it under central feature management. No prerequisites.
  paymentQrScan,

  /// Community price reporting from the station-detail screen (#1638).
  /// Gates the "Report price" AppBar action that opens the `/report/:id`
  /// flow. Default-on — the action already shipped reachable, so the
  /// flag preserves current behaviour while bringing it under central
  /// feature management. No prerequisites.
  communityPriceReports,

  /// Whether the trip recorder should require an OBD2 adapter at all
  /// (#2024). Default-on — every existing user has OBD2 set up and the
  /// recorder workflow assumes a dongle. Toggling this flag off lets
  /// users record GPS-only trajets (kind = `gpsOnly`) without ever
  /// pairing a dongle; the recording screen falls back to the minimal
  /// instant-consumption + coaching-symbols layout (#2026) and the
  /// vehicle calibration drops to confidence tier A (#2027). Soft-
  /// requires nothing — the flag is the prerequisite-removal itself.
  obd2Optional,
}
