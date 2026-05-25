<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Daily Feature Analysis — 2026-05-03

## Market Context

The fuel and mobility app market in May 2026 continues its shift toward AI-driven personalisation, energy-mix optimisation, and community trust signals. Key market signals this week: AI-powered dynamic fuel pricing tools (Kalibrate, PriceEasy's Fuel IQ, RapidPricer) are now standard for station operators, meaning price volatility is algorithmically driven — consumer apps that can reverse-engineer or predict these patterns gain a decisive edge. Ultra-fast EV charging (350 kW+) is going mainstream across European corridors, and Charging-as-a-Service (CaaS) subscription models are reshaping how drivers think about energy costs. Community-driven EV apps report 94% accuracy on crowdsourced charger status, setting user expectations for real-time reliability data across all fuel types. Meanwhile, Clever Tanken leads Germany with 5M+ users but remains single-country; TankPilot covers three countries with ML-based price predictions; GasBuddy dominates North America with crowdsourced data and cashback rewards but still lacks in-car integration.

**Tankstellen's current positioning:** 11 countries (17 station services), 23 languages, OBD-II driving insights, EV charging (OpenChargeMap), achievements/gamification, loyalty cards, privacy-first (no Firebase/tracking/ads), price predictions (day-of-week + hour-of-day model), route search with strategies, glide coach, consumption tracking with driving score, CO₂ dashboard, CarDataBridge for Android Auto/CarPlay, home-screen widget.

**Previously proposed features (May 1–2):** CarPlay/Android Auto template screens, Crowdsourced Price OCR, Smart Refuel Timing, Community Leaderboard, Wearable Companion, Voice-First In-Car AI Copilot, Hybrid & EV Energy Cost Optimizer, Station Queue & Availability Intelligence, Social Carpooling Cost-Split, Multi-Modal Journey Cost Comparison.

**Today's focus:** Five new feature gaps identified from fresh market intelligence — predictive price arbitrage alerts, station amenity & review ecosystem, fleet/family group management, maintenance-aware refuel routing, and personalised savings dashboard with goal tracking.

---

## Feature 1: Predictive Price Arbitrage Alerts

### Description

Goes beyond the existing `PricePredictionProvider` (which analyses local hour-of-day and day-of-week averages for a single station) by building a cross-station, cross-country arbitrage engine. When the app detects that a station 5 km from the user's daily commute route is about to enter its historically cheapest window while the user's favourite station is in its peak window, it proactively sends a "save €X by filling at Station Y in 45 minutes" notification. Competitors like Clever Tanken offer static price history charts; TankPilot has ML predictions but only for a single selected station. No app currently offers proactive cross-station timing arbitrage on the user's actual route. This directly serves Layer 1 ("buy fuel for less money") and gives Tankstellen an AI-driven edge that is extremely hard for single-country competitors to replicate across 11 countries.

### Detailed Implementation Concept

**Architecture:**

New sub-module under `lib/features/alerts/` extending the existing alert system, plus a new domain service in `lib/features/price_history/domain/`.

**Key files to create:**

- `lib/features/price_history/domain/arbitrage_engine.dart` — Pure-Dart domain logic (no Flutter imports, isolate-safe). Takes as input: (a) the user's recent GPS commute corridor (from `lib/core/location/`), (b) stations within a configurable radius of that corridor (from `lib/features/search/`), (c) 30-day price history for each candidate station (from `PriceHistoryRepository`). For each station, it computes the per-hour-of-day price distribution (reusing the bucketing logic already in `price_prediction_provider.dart`), then ranks stations by predicted price at the user's typical fill-up times. Output: `List<ArbitrageOpportunity>` sorted by potential saving.

- `lib/features/price_history/domain/entities/arbitrage_opportunity.dart` — Freezed entity: `stationId`, `stationName`, `predictedPrice`, `comparedToFavoritePrice`, `savingPerLitre`, `savingPerTank` (using vehicle's tank capacity from `lib/features/vehicle/`), `optimalWindowStart` (DateTime), `optimalWindowEnd`, `confidenceScore` (0.0–1.0 based on sample count from `HourlyAverage.sampleCount`), `detourKm` (extra distance vs. direct commute).

- `lib/features/alerts/domain/entities/arbitrage_alert.dart` — Freezed entity extending the existing alert model: `opportunity` (ArbitrageOpportunity), `triggeredAt`, `acknowledged` flag. Stored in Hive alongside existing price alerts.

- `lib/features/alerts/data/arbitrage_alert_evaluator.dart` — Invoked by the existing `BackgroundPriceFetcher` (`lib/core/background/`). During each background check cycle (already runs every 30 min via WorkManager), it: (1) loads the user's commute corridor from stored GPS history, (2) identifies candidate stations, (3) runs `ArbitrageEngine`, (4) fires a notification via `lib/core/notifications/` if saving exceeds a user-configurable threshold (default: €0.03/L, ≈ €1.50 per 50L tank).

- `lib/features/alerts/presentation/widgets/arbitrage_alert_card.dart` — Rich notification card shown on the alerts tab. Displays: station name, price comparison bar chart (favourite vs. recommended), saving amount, optimal fill window countdown, one-tap navigate button (launches external maps or the existing driving mode).

- `lib/features/alerts/providers/arbitrage_alert_provider.dart` — Riverpod provider that watches `ArbitrageAlertEvaluator` results and the existing `priceAlertProvider` to present a unified alert feed.

**Integration points:**

- Extends `lib/core/background/background_price_fetcher.dart` — adds arbitrage evaluation step after existing threshold-alert checks.
- Reuses `PriceHistoryRepository` (already stores 30-day per-station history).
- Reuses `price_prediction_provider.dart` bucketing logic (extracted into shared utility).
- Uses vehicle tank capacity from `lib/features/vehicle/domain/entities/` for saving calculation.
- Uses `lib/core/location/location_service.dart` + stored trip GPS paths from `lib/features/consumption/` to derive commute corridor.
- Notifications via existing `flutter_local_notifications` integration.

**Privacy alignment:**

- Commute corridor computed on-device from locally stored trip data — never uploaded.
- No new network calls; relies entirely on already-fetched price history.
- User can disable arbitrage alerts independently of threshold alerts in settings.

---

## Feature 2: Station Amenity & Review Ecosystem

### Description

The `station_detail` screen currently shows prices, brand, and basic info, but lacks structured amenity data (shop, car wash, restrooms, air pump, ATM, food, EV chargers co-located) and user reviews. GasBuddy's biggest retention lever is its user review system — drivers check reviews before visiting unfamiliar stations. Clever Tanken shows basic opening hours but no amenities or reviews. For Tankstellen's 11-country footprint, building a lightweight, privacy-first review and amenity system would dramatically increase station detail page stickiness and give users a reason to open the app even when they're not actively looking for prices. This serves Layer 1 indirectly (quality signals help choose between similarly priced stations) and creates a moat through user-generated content that API-only apps cannot replicate.

### Detailed Implementation Concept

**Architecture:**

New sub-module `lib/features/station_detail/domain/` for amenity and review models, extending the existing station detail presentation layer. Reviews stored locally (Hive) with optional sync via TankSync (Supabase).

**Key files to create:**

- `lib/features/station_detail/domain/entities/station_amenity.dart` — Freezed enum-like sealed class with variants: `Shop`, `CarWash`, `Restroom`, `AirPump`, `ATM`, `Food`, `WiFi`, `EvCharger`, `Hydrogen`, `TruckParking`, `Accessibility`. Each variant carries an optional `quality` rating (1–5) and `lastConfirmedAt` timestamp.

- `lib/features/station_detail/domain/entities/station_review.dart` — Freezed entity: `reviewId` (UUID), `stationId`, `overallRating` (1–5), `amenityRatings` (Map<StationAmenity, int>), `comment` (optional, max 280 chars), `createdAt`, `updatedAt`, `profileId` (references existing profile system). No real names or photos — privacy-first design using the existing anonymous profile model.

- `lib/features/station_detail/data/review_repository.dart` — Hive-backed storage for reviews. CRUD operations with optimistic local-first writes. Implements `SyncableRepository` interface (from `lib/core/sync/`) so reviews sync to TankSync when enabled, letting cross-device users see their own reviews everywhere.

- `lib/features/station_detail/data/amenity_repository.dart` — Aggregates amenity confirmations from reviews. When 3+ independent reviews confirm an amenity, it's flagged as "verified." Stores aggregated amenity state per station in a lightweight Hive box.

- `lib/features/station_detail/presentation/widgets/amenity_chips_row.dart` — Horizontal chip row below the price section on the station detail screen. Each chip shows the amenity icon + verification badge. Taps expand to show rating distribution. Integrates into existing `station_detail_screen.dart` layout.

- `lib/features/station_detail/presentation/widgets/review_section.dart` — Expandable section below amenities: shows aggregate rating (stars), review count, and latest 3 reviews with "see all" button. Includes a "Write review" FAB that opens a bottom sheet with star rating, amenity checkboxes, and optional comment field.

- `lib/features/station_detail/presentation/widgets/write_review_sheet.dart` — Modal bottom sheet: overall star rating (required), amenity toggles with per-amenity rating (optional), text comment (optional, 280 char limit). Validates that the user has visited the station (checks fill-up log or GPS proximity within last 7 days) to prevent spam.

- `lib/features/station_detail/providers/review_provider.dart` — Riverpod provider: fetches reviews from `ReviewRepository`, computes aggregate stats (avg rating, amenity verification status), exposes write/update/delete mutations.

**Integration points:**

- Extends `station_detail_screen.dart` — inserts `AmenityChipsRow` and `ReviewSection` widgets between existing `StationPricesSection` and `StationRatingSection` (which currently handles the simpler price-report rating).
- Syncs via existing `lib/core/sync/` TankSync infrastructure (Supabase) — reviews become a new sync category alongside favorites and fill-ups.
- Spam prevention: cross-references `lib/features/consumption/data/` fill-up log and `lib/core/location/` GPS history.
- Search results can surface aggregate rating as a secondary sort criterion (extends `lib/features/search/domain/entities/`).

**Privacy alignment:**

- Reviews are anonymous — tied to profile UUID, no personal data exposed.
- Review content never leaves the device unless TankSync is explicitly enabled.
- No photos (avoids facial recognition / license plate concerns).
- Location-based visit verification uses only on-device GPS history.

---

## Feature 3: Fleet & Family Group Management

### Description

Multi-vehicle households and small business fleets (delivery drivers, sales teams, family cars) currently manage each vehicle independently. No fuel app in the German market offers a "group" view where a family or small fleet can see combined fuel spend, compare vehicle efficiency, and identify which vehicle or driver is costing the most. Fuelio has basic multi-vehicle support but no aggregation or comparison. Tankstellen already supports vehicle profiles (`lib/features/vehicle/`) and optional TankSync cloud backend — adding a group layer on top lets families share a fuel budget, fleet managers see per-vehicle cost breakdowns, and parents monitor teen driver efficiency. This extends Layer 3 ("see what you're really spending") into the multi-user dimension.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/group/` with clean architecture layers. Uses TankSync (Supabase) as the sync backbone — groups are a new Supabase table with row-level security. Works offline-first: each member's local data is authoritative; the group view aggregates synced snapshots.

**Key files to create:**

- `lib/features/group/domain/entities/vehicle_group.dart` — Freezed entity: `groupId` (UUID), `name` ("Dittgen Family" or "Sales Fleet"), `createdBy` (profile UUID), `memberIds` (List), `inviteCode` (6-char alphanumeric, expires in 7 days), `createdAt`. No personal data beyond profile UUIDs.

- `lib/features/group/domain/entities/group_member.dart` — Freezed entity: `profileId`, `displayName` (user-chosen alias, not real name), `vehicleIds` (which of their vehicles they share with the group), `role` (owner / member), `joinedAt`.

- `lib/features/group/domain/entities/group_summary.dart` — Freezed entity computed from aggregated sync data: `totalSpendThisMonth`, `totalLitresThisMonth`, `totalKmThisMonth`, `avgCostPerKm`, `vehicleBreakdowns` (List of per-vehicle stats: spend, litres, km, cost/km, driving score avg), `bestPerformer` (vehicle with lowest cost/km), `savingsVsFavorite` (how much the group saved vs. always filling at the nearest station).

- `lib/features/group/data/group_repository.dart` — Supabase-backed CRUD for groups. Uses existing `lib/core/data/impl/supabase_sync_repository.dart` patterns. Invite code generation and validation. Row-level security: only group members can read group data. Falls back gracefully when offline (shows last-synced snapshot).

- `lib/features/group/data/group_aggregator.dart` — Pulls synced fill-up logs, trip data, and consumption stats for all group members' shared vehicles. Computes `GroupSummary`. Runs on-device — raw member data is never stored on other members' devices, only the aggregated summary.

- `lib/features/group/presentation/screens/group_dashboard_screen.dart` — Main group view: monthly spend chart (stacked bar per vehicle), cost-per-km leaderboard, fuel budget progress bar (if budget set), "top saver" badge. Accessible from a new tab or from the profile/settings screen.

- `lib/features/group/presentation/screens/group_invite_screen.dart` — QR code (using existing `qr_flutter` dependency) + shareable text invite code. Recipient scans or enters code in their Tankstellen app to join.

- `lib/features/group/presentation/widgets/vehicle_comparison_card.dart` — Side-by-side comparison widget: two vehicles' cost/km, driving score, and consumption trend over the last 30 days. Uses existing chart components from `lib/features/price_history/presentation/`.

- `lib/features/group/providers/group_provider.dart` — Riverpod provider family keyed by `groupId`. Watches `GroupRepository` for membership changes and `GroupAggregator` for summary updates.

**Integration points:**

- Extends Supabase schema (new `groups` and `group_members` tables) — migration via existing `supabase/migrations/` directory.
- Reuses `lib/core/sync/` infrastructure for syncing fill-ups and trip data to Supabase.
- Reuses `qr_flutter` (already in pubspec.yaml) for invite code QR generation.
- Vehicle profiles from `lib/features/vehicle/` — users select which vehicles to share.
- Fill-up and consumption data from `lib/features/consumption/` — aggregated for group view.
- Driving score from `lib/features/consumption/domain/driving_score.dart` — averaged per vehicle for leaderboard.

**Privacy alignment:**

- Members choose which vehicles to share — not all-or-nothing.
- Display names are user-chosen aliases, not real names.
- Raw trip GPS data is never shared — only aggregated metrics (km, litres, cost).
- Group data lives in Supabase with row-level security; self-hostable.
- Any member can leave a group at any time; their data stops syncing immediately.

---

## Feature 4: Maintenance-Aware Refuel Routing

### Description

Tankstellen already has a maintenance suggestion engine that watches consumption drift over time (`lib/features/consumption/domain/entities/maintenance_suggestion.dart`). This feature connects maintenance awareness to refuel routing: when the app detects that a vehicle's fuel consumption has drifted upward (suggesting overdue service, degraded air filter, or tyre pressure issues), it factors the increased per-km cost into route search decisions. A station 3 km further away but €0.04/L cheaper might normally save money — but if the vehicle's consumption is 15% above baseline, that extra detour actually costs more in wasted fuel than the price saving. No competitor considers vehicle condition in routing decisions. This bridges Layer 2 ("burn less fuel") and Layer 1 ("buy cheaper") with Layer 3 ("know what you spend") in a way that is unique to apps with OBD-II integration.

### Detailed Implementation Concept

**Architecture:**

New domain service in `lib/features/route_search/domain/` that wraps the existing `RouteSearchStrategy` with a maintenance-aware cost model. No new feature module — this extends the existing route search and consumption features.

**Key files to create:**

- `lib/features/route_search/domain/maintenance_cost_adjuster.dart` — Pure-Dart domain service. Takes: (a) the vehicle's baseline consumption (from `ConsumptionStats`), (b) the current rolling average consumption (last 5 trips), (c) detour distance for each candidate station. Computes: `adjustedTotalCost = (stationPrice × estimatedLitres) + (detourKm × currentConsumption × avgFuelPrice / 100)`. When consumption drift exceeds a configurable threshold (default: 10%), the adjusted model penalises longer detours more heavily, nudging the routing toward closer stations even if slightly more expensive.

- `lib/features/route_search/domain/entities/maintenance_cost_context.dart` — Freezed entity: `baselineConsumption` (L/100km), `currentConsumption` (L/100km), `driftPercentage`, `driftSeverity` (enum: `normal`, `elevated`, `critical`), `suggestedAction` (string, e.g., "Consider checking tyre pressure — consumption is 12% above baseline").

- `lib/features/route_search/domain/maintenance_aware_strategy.dart` — Decorator around existing `RouteSearchStrategy`. Implements the same interface but wraps the scoring function to use `MaintenanceCostAdjuster` when drift data is available. Falls back to standard strategy when no consumption data exists (new users, vehicles without fill-up history).

- `lib/features/route_search/presentation/widgets/maintenance_drift_banner.dart` — Small info banner shown above route search results when consumption drift is detected. Shows: "Your fuel consumption is X% above normal — factoring this into route recommendations." Tappable to see maintenance suggestions. Uses existing `MaintenanceSuggestion` entity.

- `lib/features/route_search/providers/maintenance_aware_route_provider.dart` — Riverpod provider that composes: `RouteSearchStrategyFactory` (existing), `ConsumptionStatsProvider` (existing), and `MaintenanceCostAdjuster` (new). Provides the maintenance-aware strategy to the route search UI.

**Integration points:**

- Wraps existing `lib/features/route_search/domain/route_search_strategy.dart` and `route_search_strategy_factory.dart` — no breaking changes, the maintenance-aware strategy is a decorator.
- Reads consumption stats from `lib/features/consumption/domain/entities/consumption_stats.dart`.
- Reads maintenance suggestions from `lib/features/consumption/domain/entities/maintenance_suggestion.dart`.
- Surfaces in `lib/features/route_search/presentation/` results screen as an additional banner.
- Optional: surfaces drift warning in driving mode (`lib/features/driving/presentation/`) as a persistent chip.

**Privacy alignment:**

- All computation on-device using locally stored consumption data.
- No vehicle diagnostic data leaves the device.
- Maintenance suggestions are advisory, not prescriptive — never triggers external service bookings.

---

## Feature 5: Personalised Savings Dashboard with Goal Tracking

### Description

Tankstellen tells users what fuel costs, but doesn't help them visualise how much they've actually saved by using the app, nor does it let them set savings goals. GasBuddy prominently shows "You've saved $X this year" — a powerful retention mechanic. Tankstellen can go further: combining fill-up log data, price history, route search choices, and driving score improvements into a comprehensive "your savings story" dashboard. Users set a monthly fuel budget or a savings target, and the app tracks progress with actionable tips ("You saved €12 this month by filling at off-peak times, but lost €8 to aggressive driving — net saving: €4"). This serves Layer 3 ("see what you spend") and creates an emotional feedback loop that drives daily engagement.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/savings/` with clean architecture layers. Computes savings by comparing actual user behaviour against counterfactual baselines (what they would have spent without optimisation).

**Key files to create:**

- `lib/features/savings/domain/entities/savings_goal.dart` — Freezed entity: `goalId` (UUID), `type` (enum: `monthlyBudget`, `annualTarget`, `costPerKmTarget`), `targetAmount` (double, in user's currency), `currency`, `startDate`, `endDate` (null for rolling monthly), `vehicleId` (optional, null = all vehicles).

- `lib/features/savings/domain/entities/savings_breakdown.dart` — Freezed entity: `period` (month/week), `actualSpend`, `baselineSpend` (what user would have spent at nearest station at fill-up time), `priceSaving` (from choosing cheaper stations), `timingSaving` (from filling at predicted cheap windows), `drivingSaving` (from improved driving score reducing consumption), `routeSaving` (from route-optimised stops), `totalSaving`, `co2Avoided` (kg, from efficiency improvements).

- `lib/features/savings/domain/savings_calculator.dart` — Pure-Dart service. For each fill-up in the period: (1) looks up the price at the user's nearest station at the time of fill-up (from `PriceHistoryRepository`), (2) compares against the price they actually paid, (3) difference × litres = price saving. For driving savings: compares current period's avg consumption against the 90-day rolling baseline, multiplied by litres driven. For route savings: sums detour-adjusted savings from route search selections (requires storing which route suggestion was followed — new field on fill-up entity).

- `lib/features/savings/data/savings_repository.dart` — Hive-backed storage for goals and computed breakdowns. Breakdowns are recomputed on demand (not cached) to reflect any fill-up log edits. Goals persist across sessions.

- `lib/features/savings/presentation/screens/savings_dashboard_screen.dart` — Main dashboard: (1) hero card with "You've saved €X this month" in large type, (2) progress ring toward savings goal (if set), (3) breakdown cards (price, timing, driving, route) with mini bar charts, (4) "this month vs. last month" comparison, (5) tips section ("Fill up on Tuesdays around 6 AM to save an additional €3/month" — sourced from `PricePredictionProvider`).

- `lib/features/savings/presentation/screens/savings_goal_setup_screen.dart` — Goal creation flow: pick goal type (budget/target/cost-per-km), enter amount, select vehicle(s) or all, set period. Clean, focused UI with no clutter.

- `lib/features/savings/presentation/widgets/savings_hero_card.dart` — Animated card (uses existing `flex_color_scheme` theming) showing total savings with a celebratory animation when milestones are hit (€10, €50, €100 saved). Optionally shareable as PNG (using existing `share_plus` dependency).

- `lib/features/savings/presentation/widgets/savings_tip_card.dart` — Contextual tip derived from the user's own data: e.g., "You filled up 3 times on Fridays — Fridays are the most expensive day at your stations. Switching to Tuesdays could save €4.20/month." Sources data from `PricePredictionProvider` and `ConsumptionStatsProvider`.

- `lib/features/savings/providers/savings_provider.dart` — Riverpod provider composing: `SavingsCalculator`, `SavingsRepository`, fill-up data from `ConsumptionProviders`, price history, and vehicle profiles. Exposes current-period breakdown and goal progress.

**Integration points:**

- Reads fill-up log from `lib/features/consumption/data/` and `lib/features/consumption/domain/entities/fill_up.dart`.
- Reads price history from `lib/features/price_history/data/` via `PriceHistoryRepository`.
- Reads driving score from `lib/features/consumption/domain/driving_score.dart` for efficiency saving calculation.
- Reads vehicle profiles from `lib/features/vehicle/` for tank capacity and baseline consumption.
- Extends `lib/features/consumption/domain/entities/fill_up.dart` — adds optional `routeSuggestionFollowed` boolean field to track whether the user followed a route search recommendation.
- Accessible via new navigation destination in `lib/app/shell/shell_destinations.dart` or as a card on the existing profile screen.
- Shareable via existing `share_plus` (already in pubspec.yaml).
- Syncs goals via TankSync (Supabase) when enabled — extends `lib/core/sync/`.

**Privacy alignment:**

- All savings computation is on-device using locally stored data.
- Shared savings cards (PNG) contain only aggregate numbers, no station names or GPS data.
- Goals and breakdowns sync only if TankSync is explicitly enabled.
- No comparison with other users — this is a personal savings tracker, not a leaderboard.

---

## Summary & Prioritisation

| # | Feature | Layer | Effort | Impact | Priority |
|---|---------|-------|--------|--------|----------|
| 1 | Predictive Price Arbitrage Alerts | L1 | Medium | High | **P0** |
| 2 | Station Amenity & Review Ecosystem | L1/L3 | High | High | **P1** |
| 3 | Fleet & Family Group Management | L3 | High | Medium | **P2** |
| 4 | Maintenance-Aware Refuel Routing | L1/L2 | Low | Medium | **P1** |
| 5 | Personalised Savings Dashboard | L3 | Medium | High | **P0** |

**Rationale:**

- **Arbitrage Alerts (P0):** Low-to-medium effort (reuses existing price history + prediction infrastructure), high impact (proactive notifications drive daily engagement and directly save users money — the app's core promise). Leverages the unique 11-country price history dataset no competitor has.

- **Savings Dashboard (P0):** Medium effort, but enormous retention impact. GasBuddy's "you saved $X" is their stickiest feature. Tankstellen can go deeper with breakdown by saving source (price, timing, driving) — a genuine differentiator for the OBD-II-equipped user segment.

- **Maintenance-Aware Routing (P1):** Smallest implementation scope (decorator pattern over existing route search), medium impact but highly unique — no competitor considers vehicle condition in routing. Makes the OBD-II investment pay off in a new way.

- **Station Reviews (P1):** High effort (community data + sync + spam prevention), but high long-term impact. User-generated content creates a moat. Deliberately kept lightweight (no photos, 280-char limit) to align with privacy-first values.

- **Fleet/Family Groups (P2):** Highest effort (Supabase schema changes, multi-user sync complexity), medium impact (smaller target audience). But strong differentiation — no fuel app in the DACH market offers this. Naturally follows once TankSync is mature.
