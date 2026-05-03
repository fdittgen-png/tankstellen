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

  /// Unified fuel + EV search results.
  unifiedSearchResults,

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
}
