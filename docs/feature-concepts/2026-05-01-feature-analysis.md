<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Daily Feature Analysis — 2026-05-01

## Market Context

The German fuel station app market in 2026 shows clear trends: declining petrol station count (5,720 businesses, -1.4% CAGR), growing EV infrastructure demand, and consolidation around a few dominant apps (clever-tanken with 5M+ users, ADAC Drive with multi-country routing, TankPilot with AI price prediction). Emerging US apps like FuelUp introduce gamification leaderboards and crowdsourced photo verification, while CarPlay/Android Auto integration is becoming table-stakes for any serious fuel app.

**Current app strengths already covering:** price comparison (11 countries), EV charging (OCM integration), OBD2 trip recording, price alerts (single station + radius), achievements/gamification, loyalty card discounts, route search, price history with prediction, carbon tracking, driving mode, consumption logging, home-screen widget, cross-border suggestions.

**Gaps identified from competitor analysis:**

---

## Feature 1: CarPlay & Android Auto Companion

### Description

A lightweight in-car interface that surfaces the app's core value (nearest cheapest station, active price alerts, trip recording status) directly on the vehicle's head unit via Apple CarPlay and Android Auto. Competitors like Fuelio, Fillzz and ADAC Drive already ship this — its absence is a visible gap in the 2026 market.

### Detailed Implementation Concept

**Architecture:**

Create a new feature module at `lib/features/car_companion/` following the existing clean-architecture pattern (data / domain / presentation / providers).

**Key files to create:**

- `lib/features/car_companion/presentation/car_companion_screen.dart` — Simplified single-screen UI optimized for the restricted CarPlay/AA layout (large tap targets, high contrast, minimal text). Shows: current fuel type price at 3 nearest stations, one-tap navigation to cheapest, active alert status indicator.
- `lib/features/car_companion/providers/car_companion_provider.dart` — Riverpod provider that composes `search_provider` results (from `lib/features/search/providers/`) with `location_service` (from `lib/core/location/location_service.dart`) to produce a simplified station list sorted by price within 5 km.
- `lib/features/car_companion/data/car_companion_channel.dart` — Platform channel bridge to native CarPlay (CPTemplateApplicationScene) and Android Auto (Session/Screen) SDKs.

**Native side:**

- `android/app/src/main/java/.../CarCompanionService.java` — Extends `CarAppService`, registers a `ListTemplate` with price rows that deep-link back into the Flutter app.
- `ios/Runner/CarPlaySceneDelegate.swift` — Implements `CPTemplateApplicationSceneDelegate`, builds a `CPListTemplate` with station items.

**Integration points:**

- Reuse `StationService` (existing in `lib/features/search/data/services/`) for price data.
- Reuse `LocationService` (existing `lib/core/location/location_service.dart`) for user position.
- Reuse `FuelType` preference from `lib/features/profile/providers/effective_fuel_type_provider.dart`.

**Dependencies to add in `pubspec.yaml`:** None — CarPlay and Android Auto require native code only; the Flutter side communicates via MethodChannel already established for `home_widget`.

---

## Feature 2: Crowdsourced Price Verification with Photo OCR

### Description

Allow users to snap a photo of a fuel price sign at a station, automatically OCR the price, and submit it as a community-verified data point. This mirrors FuelUp's "earn points for price reports" and The Gas Index's photo-submission model. Differentiator: privacy-first (no account required, photo discarded after OCR, only extracted price stored).

### Detailed Implementation Concept

**Architecture:**

Extend the existing `lib/features/report/` feature module (already has station-report infrastructure) with a new "price report" sub-flow.

**Key files to create/modify:**

- `lib/features/report/presentation/screens/price_report_screen.dart` — Camera viewfinder with overlay guide ("point at price board"), capture button, OCR result confirmation dialog showing extracted prices per fuel type.
- `lib/features/report/data/price_ocr_service.dart` — Wraps the already-imported `google_mlkit_text_recognition` package (already in pubspec.yaml for receipt scanning in `lib/features/consumption/data/receipt_parser/`) to parse price-board layouts. Applies regex patterns like `\d[.,]\d{2,3}` to extract fuel prices.
- `lib/features/report/domain/entities/price_report.dart` — Freezed entity: `stationId`, `fuelType`, `reportedPrice`, `reportedAt`, `confidence` (OCR confidence score).
- `lib/features/report/data/repositories/price_report_repository.dart` — Submits verified prices to Supabase (table `price_reports`), integrating with existing `supabase_flutter` dependency. Implements throttle (max 3 reports/station/hour per user-hash).

**Integration with gamification:**

- Add new `AchievementId.firstPriceReport` and `AchievementId.tenPriceReports` to `lib/features/achievements/domain/achievement_id.dart` — rewards participation without requiring identity.
- The existing `AchievementsProvider` evaluation loop (in `lib/features/achievements/providers/achievements_provider.dart`) checks a new `priceReportCount` counter stored in Hive.

**Privacy alignment:**

- Photo never leaves device — processed locally by ML Kit (already on-device).
- Only numeric price + station ID + anonymous device-hash sent to backend.
- Aligns with existing GDPR consent flow in `lib/features/consent/`.

---

## Feature 3: Smart Refuel Timing Advisor ("Best Moment to Fill Up")

### Description

While the app already has `price_prediction` and `best_time_banner`, competitors like DrivstoffAppen and ADAC Drive offer proactive push notifications telling users the *optimal moment* to refuel based on predicted price curves. This feature combines the existing prediction engine with the consumption/tank-level tracking to push a personalized "fill up now" notification when the predicted price trough aligns with the user's estimated fuel level dropping below a configurable threshold.

### Detailed Implementation Concept

**Architecture:**

Extend `lib/features/alerts/` and connect it to `lib/features/consumption/providers/tank_level_provider.dart` and `lib/features/price_history/providers/price_prediction_provider.dart`.

**Key files to create/modify:**

- `lib/features/alerts/domain/entities/refuel_timing_alert.dart` — Freezed entity combining: `targetStation` (or radius), `tankThresholdPercent` (default 25%), `priceDropPercent` (predicted drop needed to trigger, default 2%).
- `lib/features/alerts/data/refuel_timing_evaluator.dart` — Background evaluator (called by existing `background_service.dart` via WorkManager) that: (1) reads current tank level from `TankLevelProvider` logic, (2) if below threshold, queries `PricePredictionProvider` for next 24h forecast, (3) if current price is within 1% of predicted trough OR predicted to rise, fires notification.
- Modify `lib/core/background/background_price_fetcher.dart` — Add a call to `RefuelTimingEvaluator.evaluate()` after existing price-fetch cycle completes.
- `lib/features/alerts/presentation/widgets/refuel_timing_setup_sheet.dart` — Bottom sheet allowing users to configure threshold + sensitivity. Accessible from the existing alerts screen.

**Notification delivery:**

- Uses existing `flutter_local_notifications` dependency.
- Notification text: "Tank at ~20% — E10 at [Station] is at €1.459 and predicted to rise 3ct in 4h. Fill up now?"
- Tap opens station detail screen via existing deep-link routing in `lib/app/router.dart`.

---

## Feature 4: Community Fuel Price Leaderboard

### Description

FuelUp's regional leaderboards (Bronze → Platinum tiers) and point-based rewards are driving engagement in the US market. This feature adds a privacy-preserving leaderboard where users earn points for verified price reports, streak achievements, and eco-driving milestones — competing within their configured country without revealing identity.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/leaderboard/` with Supabase backend aggregation.

**Key files to create:**

- `lib/features/leaderboard/domain/entities/leaderboard_entry.dart` — Freezed: `rank`, `displayName` (user-chosen alias, not email), `points`, `tier` (enum: Bronze/Silver/Gold/Platinum), `country`.
- `lib/features/leaderboard/domain/services/points_calculator.dart` — Pure function mapping actions to points: price report verified (+10), achievement unlocked (+25), eco-week streak (+50), 30-day active streak (+100).
- `lib/features/leaderboard/data/repositories/leaderboard_repository.dart` — Reads from Supabase view `leaderboard_weekly` (aggregated server-side for privacy). Submits point-earning events via existing sync infrastructure in `lib/features/sync/`.
- `lib/features/leaderboard/presentation/screens/leaderboard_screen.dart` — Scrollable list with user's own rank highlighted, tier badge, country filter. Tabs: weekly / all-time.
- `lib/features/leaderboard/presentation/widgets/tier_progress_card.dart` — Shows points-to-next-tier progress bar, integrated into the profile screen alongside existing `gamification_settings_tile.dart`.

**Integration with existing gamification:**

- Hooks into `lib/features/achievements/providers/achievements_provider.dart` — each `EarnedAchievement` event also increments leaderboard points via `PointsCalculator`.
- The existing `gamification_enabled_provider.dart` toggle controls leaderboard visibility (opt-in only).

**Privacy model:**

- Leaderboard is anonymous (alias + country only).
- User can opt out entirely via existing gamification toggle.
- No social graph — pure score ranking with no follow/friend mechanics.

---

## Feature 5: Apple Watch & Wear OS Glanceable Companion

### Description

A wearable companion that shows the cheapest nearby fuel price at a glance without pulling out the phone. Competitors like FuelUp ship Apple Watch complications; no major European tank app offers Wear OS support yet — a differentiation opportunity.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/wearable/` for the Flutter-side data bridge, plus native watch app targets.

**Key files to create:**

- `lib/features/wearable/data/wearable_data_bridge.dart` — Sends simplified payload (cheapest price, station name, distance, fuel type) to the watch via platform channel. Reuses price data from `lib/features/search/providers/` and location from `lib/core/location/`.
- `lib/features/wearable/providers/wearable_sync_provider.dart` — Riverpod provider that listens to location changes (existing `MovementDetectionProvider`) and triggers wearable data refresh every 5 minutes or on significant movement (>500m).

**Native watchOS app (`watchos/TankstellenWatch/`):**

- `ComplicationController.swift` — CLKComplicationDataSource providing a `GraphicCircularView` complication showing price + fuel-type icon.
- `ContentView.swift` (SwiftUI) — Single screen: large price text, station name, distance, "Navigate" button that opens Maps.
- `WCSessionDelegate` — Receives data from phone app via WatchConnectivity framework.

**Native Wear OS app (`android/wear/`):**

- `WearTileService.kt` — Tile showing cheapest price (Wear OS Tiles API for always-on glanceable info).
- `WearMainActivity.kt` — Compose for Wear OS single-screen showing top 3 stations, tap to navigate.
- `WearDataLayerService.kt` — Receives data from phone app via Data Layer API.

**Data flow:**

Phone app (existing search/location providers) → `WearableDataBridge` → MethodChannel → Native watch communication layer → Watch UI.

**Dependency:** Add `wear` module to `android/settings.gradle`; add watchOS target to Xcode project. No new Flutter pubspec dependencies needed — all communication is native platform channels (same pattern as existing `home_widget` integration).

---

## Summary & Priority Recommendation

| # | Feature | Effort | Market Impact | Differentiation |
|---|---------|--------|---------------|-----------------|
| 1 | CarPlay & Android Auto | High | Very High | Catches up to Fuelio, ADAC |
| 2 | Crowdsourced Price OCR | Medium | High | Unique in EU privacy-first |
| 3 | Smart Refuel Timing | Low | High | Extends existing prediction |
| 4 | Community Leaderboard | Medium | Medium | Engagement & retention |
| 5 | Wearable Companion | High | Medium | First EU tank app on Wear OS |

**Recommended next sprint:** Feature 3 (lowest effort, builds on existing infrastructure) followed by Feature 2 (leverages already-imported ML Kit).

---

*Generated: 2026-05-01 | Based on market analysis of clever-tanken, ADAC Drive, TankPilot, FuelUp, DrivstoffAppen, The Gas Index, Fuelio, and Fillzz.*
