# Tankstellen — Daily Market Analysis & Feature Proposals

**Date:** 2026-04-12 (Sunday)
**App Version:** 4.3.0+4060
**Markets Covered:** DE, FR, IT, ES, AT, BE, LU (+ 4 more via APIs)

---

## Market Context

The European fuel market is experiencing significant disruption in April 2026. Brent Crude has surpassed $120/barrel due to the Strait of Hormuz closure and energy infrastructure attacks, pushing the European average to €1.88/L — a 13.26% year-over-year increase. This high-price environment is driving record demand for fuel price comparison tools.

**Key regulatory change:** Since 1 April 2026, German petrol stations may only raise fuel prices once per day (at 12:00 noon). Price reductions remain unrestricted. This fundamentally changes the price-discovery pattern that apps rely on and creates new strategic opportunities.

**Competitive landscape:** Fillzz now covers 20+ countries, ADAC Drive has added HVO100 support and international prices, and clever-tanken v8 shipped a full UI modernization. EV charging apps (Chargeprice, Charge&Fuel) are converging with traditional fuel apps. Loyalty/gamification apps like FuelUp are gaining traction with leaderboards and points systems.

---

## Feature Proposals

### 1. Smart Noon Strategy Advisor (Germany-specific)

**Description:** A dedicated advisory feature that exploits the new German pricing regulation (prices rise only once at 12:00). The app analyzes pre-noon and post-noon price patterns, tracks how each station adjusts its pricing strategy under the new rules, and provides a personalized "fill now or wait" recommendation with estimated savings.

**Why this matters:** The regulation fundamentally changes the decades-old German pattern of ~22 daily price changes. No competitor has shipped a feature specifically designed around this regulation yet. First-mover advantage is significant because the regulation is only 12 days old.

**Implementation Concept:**

The existing `lib/features/price_history/` module already captures 30-day local price history with `PriceRecord` entities and computes `HourlyAverage` / `DayOfWeekAverage` via `PricePrediction`. This feature extends that foundation.

**New files and changes:**

- **`lib/features/price_history/domain/entities/noon_strategy.dart`** — New freezed model:
  ```dart
  @freezed
  class NoonStrategy {
    const factory NoonStrategy({
      required double preNoonPrice,      // Last observed price before 12:00
      required double postNoonPrice,     // Price at/after 12:00 increase
      required double avgDropAmount,     // Average afternoon drop in EUR/L
      required int avgDropDelayMinutes,  // How long after noon the first drop occurs
      required String recommendation,    // "Fill now" / "Wait until ~15:00"
      required double confidenceScore,   // 0.0-1.0 based on data sample size
    }) = _NoonStrategy;
  }
  ```

- **`lib/features/price_history/data/repositories/noon_strategy_repository.dart`** — Queries `PriceHistoryRepository` for records since April 1, 2026. Groups by station, segments into pre-noon (06:00–11:59) and post-noon (12:00–23:59) buckets. Computes average drop magnitude and timing per station. Only activates when `countryCode == 'DE'`.

- **`lib/features/price_history/providers/noon_strategy_provider.dart`** — `@riverpod` provider that depends on `priceHistoryProvider` and `selectedStationProvider`. Returns `AsyncValue<NoonStrategy?>` (null for non-DE stations).

- **`lib/features/price_history/presentation/widgets/noon_strategy_banner.dart`** — A prominent card shown on the station detail screen (below price tiles) and on the search screen for German results. Uses `AnimatedCrossFade` for the recommendation reveal. Traffic-light color coding: green = "fill now, prices about to rise", amber = "prices just went up, drops expected in ~2h", red = "peak pricing, wait if possible".

- **`lib/features/station_detail/presentation/widgets/station_info_section.dart`** — Add the `NoonStrategyBanner` widget conditionally when the country is Germany.

- **Localization:** Add keys to `lib/l10n/app_de.arb` and `app_en.arb`: `noonStrategyTitle`, `noonStrategyFillNow`, `noonStrategyWait`, `noonStrategyConfidence`, `noonStrategyRegulationInfo`.

- **Testing:** Unit tests for the repository's bucket segmentation logic. Widget test for banner rendering with mock strategy data. Integration test confirming banner only appears for DE stations.

**Effort estimate:** Medium (4–6 hours). Mostly data analysis on top of existing infrastructure.

---

### 2. Community Price Verification & Gamification System

**Description:** A crowdsourced price verification layer where users earn points and badges for confirming or correcting reported prices. Includes leaderboards (regional/national), contributor tiers (Bronze → Platinum), and a "trust score" that weights community-verified prices higher in search results.

**Why this matters:** GasBuddy's entire business model is built on gamified crowdsourcing. FuelUp has just launched leaderboards and point systems. In Europe, no open-source, privacy-respecting alternative offers this. Tankstellen's existing `CommunityReportService` (Supabase-backed) is the perfect foundation — it already handles price report submission and retrieval.

**Implementation Concept:**

Extends the existing `lib/features/report/` module and TankSync backend.

**Backend (Supabase):**

- **New migration: `supabase/migrations/XXX_community_gamification.sql`** — New tables:
  - `contributor_stats`: `user_id`, `total_reports`, `verified_reports`, `current_streak`, `longest_streak`, `points`, `tier` (bronze/silver/gold/platinum), `region_code`
  - `price_verifications`: `report_id`, `verifier_id`, `agrees` (boolean), `verified_at`
  - `achievements`: `id`, `key`, `name_en`, `name_de`, `description`, `icon_key`, `points_value`, `criteria_json`
  - `user_achievements`: `user_id`, `achievement_id`, `earned_at`
  - View `regional_leaderboard`: aggregated by `region_code`, ranked by `points`

- **New Edge Function: `supabase/functions/verify-price/index.ts`** — Accepts a verification (report_id + agrees), updates `contributor_stats`, checks achievement criteria, returns newly unlocked achievements.

**App-side:**

- **`lib/features/report/domain/entities/contributor_profile.dart`** — Freezed model with points, tier, streak, achievements list.

- **`lib/features/report/domain/entities/achievement.dart`** — Freezed model: key, name, description, iconKey, pointsValue, earnedAt.

- **`lib/features/report/data/repositories/gamification_repository.dart`** — CRUD operations against Supabase tables. Falls back to local-only tracking via Hive when offline (syncs on reconnect).

- **`lib/features/report/providers/gamification_provider.dart`** — `@Riverpod(keepAlive: true)` provider exposing the user's `ContributorProfile`. Watches auth state to load/unload.

- **`lib/features/report/providers/leaderboard_provider.dart`** — `@riverpod` provider fetching regional leaderboard. Cached for 15 minutes via `CacheManager`.

- **`lib/features/report/presentation/screens/leaderboard_screen.dart`** — Tab view: "My Region" / "National" / "My Achievements". Each tab is a lazy-loaded list. Achievement cards use the existing `CommunityBadge` widget pattern from `community_badge.dart`.

- **`lib/features/report/presentation/widgets/verify_price_button.dart`** — Shown on `StationDetailScreen` when a community report exists for the station. Two buttons: "Confirm" (thumbs up) / "Disagree" (thumbs down). Triggers the verify-price Edge Function. Shows earned points with a brief confetti animation.

- **`lib/features/report/presentation/widgets/contributor_tier_badge.dart`** — Small badge widget showing the user's tier, used on the profile screen and in the community report card.

- **Modify `lib/features/station_detail/presentation/widgets/station_rating_section.dart`** — Add the `VerifyPriceButton` below existing community reports.

- **Modify `lib/features/profile/` screens** — Add "My Contributions" section showing points, tier, streak, and link to leaderboard.

**Privacy consideration:** All gamification data is tied to the anonymous Supabase user ID. No email or personal data required. Leaderboard shows anonymized usernames (e.g., "Tanker_4821").

**Effort estimate:** Large (2–3 days). Backend schema + Edge Function + 3 new screens + integration.

---

### 3. HVO100 / Alternative Fuel Type Support

**Description:** Add support for tracking HVO100 (hydrotreated vegetable oil) prices alongside existing fuel types (E5, E10, Diesel, LPG, CNG). HVO100 is a drop-in diesel replacement with up to 90% lower CO2 emissions, and ADAC Drive already tracks it in Germany and Austria. Also prepare the data model for future fuel types like E85 and hydrogen.

**Why this matters:** HVO100 availability is expanding rapidly across Germany in 2026, with major chains (Aral, Shell, HEM) adding it. ADAC Drive has already added HVO100 tracking. Not supporting it makes the app look behind the curve to environmentally conscious users — a growing segment.

**Implementation Concept:**

The fuel type system is used across the entire codebase. Changes touch the core data layer.

- **`lib/core/types/fuel_type.dart`** (or wherever the fuel type enum lives) — Add `hvo100`, `e85`, `hydrogen` to the `FuelType` enum. Each needs a `label`, `shortLabel`, `unit` (L or kg for hydrogen), and `co2FactorGPerL` for the carbon module.

- **`lib/core/services/`** — Extend each country's `StationService` implementation:
  - **Germany (Tankerkoenig):** Tankerkoenig may not yet report HVO100. Add a mapping for the new MTS fuel type code if available; otherwise, fall back to community reports.
  - **Austria:** The Spritpreisrechner API already reports some alternative fuels — map them.
  - **France:** prix-carburants.gouv.fr supports E85; map it.

- **`lib/features/search/providers/search_provider.dart`** — The fuel type filter dropdown must include the new types. Only show fuel types that are available in the user's selected country (derived from the country service capabilities).

- **`lib/features/carbon/`** — Update the CO2 calculation in `carbon_dashboard_screen.dart` to use the fuel-type-specific `co2FactorGPerL`. HVO100 has ~0.46 kg CO2/L vs. diesel's ~2.65 kg CO2/L. This makes the existing carbon dashboard significantly more useful.

- **`lib/features/vehicle/domain/entities/vehicle_profile.dart`** — Extend the `preferredFuelType` field to support the new enum values. Add migration logic in `VehicleProfileRepository` for existing profiles.

- **Localization:** Add ARB keys for each new fuel type in all 23 language files. `fuelTypeHvo100`, `fuelTypeE85`, `fuelTypeHydrogen`, `fuelTypeHvo100Desc` (brief explanation).

- **Station detail screen** — Show HVO100 price alongside diesel when available. Use a green leaf icon to visually distinguish low-emission fuels.

**Effort estimate:** Medium (6–8 hours). Mostly enum extension + per-country API mapping + UI adjustments.

---

### 4. Savings Tracker & Monthly Fuel Budget

**Description:** A personal finance feature that tracks how much money the user has saved by using the app (compared to the local average price) and provides monthly fuel budget management. Includes a running "lifetime savings" counter, monthly spending reports, and budget alerts.

**Why this matters:** With EU fuel prices at record highs (€1.88/L average), users are more cost-conscious than ever. GasBuddy prominently features a "savings" counter as a key engagement metric. No European competitor offers a privacy-respecting, local-first savings tracker. This feature turns passive price comparison into active financial awareness.

**Implementation Concept:**

Builds on the existing `lib/features/consumption/` module (fill-up logging) and `lib/features/price_history/` (local price records).

- **`lib/features/consumption/domain/entities/savings_record.dart`** — New freezed model:
  ```dart
  @freezed
  class SavingsRecord {
    const factory SavingsRecord({
      required DateTime fillUpDate,
      required double pricePaid,          // EUR/L
      required double localAveragePrice,  // EUR/L at time of fill-up
      required double liters,
      required double savedAmount,        // (avgPrice - pricePaid) * liters
      required String stationId,
    }) = _SavingsRecord;
  }
  ```

- **`lib/features/consumption/domain/entities/fuel_budget.dart`** — Monthly budget model:
  ```dart
  @freezed
  class FuelBudget {
    const factory FuelBudget({
      required double monthlyLimitEur,
      required double spentThisMonth,
      required int fillUpsThisMonth,
      required double projectedMonthlySpend,
      required double savingsThisMonth,
    }) = _FuelBudget;
  }
  ```

- **`lib/features/consumption/data/repositories/savings_repository.dart`** — On each fill-up log, computes the local average price from `PriceHistoryRepository` (average of all stations within 10km at the time of the fill-up). Stores the `SavingsRecord` in Hive. Syncs to Supabase if TankSync is connected.

- **`lib/features/consumption/providers/savings_provider.dart`** — `@Riverpod(keepAlive: true)` provider. Exposes: `lifetimeSavings`, `monthlySavings`, `savingsHistory` (list of records), `currentBudget`.

- **`lib/features/consumption/providers/budget_provider.dart`** — Manages the monthly budget limit (stored in `SharedPreferences`). Computes projected monthly spend from current pace. Triggers a local notification via `flutter_local_notifications` when spending exceeds 80% or 100% of budget.

- **`lib/features/consumption/presentation/screens/savings_screen.dart`** — New screen accessible from the consumption tab:
  - Hero counter: "You've saved €47.20 this month" with animated number
  - Monthly spending chart (bar chart, one bar per month) using the existing chart patterns from `monthly_bar_chart.dart` in the carbon module
  - Budget progress ring
  - List of recent savings records with per-fill-up breakdown

- **`lib/features/consumption/presentation/widgets/savings_summary_card.dart`** — Compact card for the main consumption screen showing lifetime and monthly savings at a glance.

- **`lib/features/widget/data/home_widget_service.dart`** — Extend the existing home widget to optionally show monthly savings alongside current prices.

- **Background integration:** Extend WorkManager task to check budget thresholds and send push notifications.

**Effort estimate:** Large (1.5–2 days). New data pipeline + screen + budget notifications + widget update.

---

### 5. Android Auto Fuel Finder

**Description:** A simplified, driving-optimized interface for Android Auto that shows nearby stations sorted by price, with one-tap navigation. Designed for hands-free, voice-controlled usage while driving.

**Why this matters:** Waze shows fuel prices on Android Auto/CarPlay, but dedicated fuel apps (even GasBuddy) still lack Android Auto support. Flutter has experimental Android Auto support via platform channels. Shipping this would make Tankstellen the first dedicated European fuel comparison app on Android Auto — a massive differentiator.

**Implementation Concept:**

Android Auto uses the `CarAppLibrary` (Jetpack) and requires native Android code. Flutter handles it via platform channels and a native Android module.

- **`android/app/src/main/java/com/tankstellen/auto/`** — New native Android module:
  - `FuelFinderCarAppService.java` — Extends `CarAppService`, registers the car app.
  - `FuelFinderSession.java` — Extends `Session`, creates the `FuelFinderScreen`.
  - `FuelFinderScreen.java` — Uses Car App Library's `ListTemplate` to show top 5 nearest stations sorted by price. Each row: station name, price, distance. Tap → opens navigation intent.
  - `StationDetailScreen.java` — `PaneTemplate` showing fuel prices, address, and "Navigate" action.

- **`android/app/src/main/AndroidManifest.xml`** — Add `<meta-data android:name="com.google.android.gms.car.application" android:resource="@xml/automotive_app_desc"/>` and the `CarAppService` declaration.

- **`android/app/src/main/res/xml/automotive_app_desc.xml`** — Declares the app as a fuel/parking category app.

- **`lib/core/services/android_auto_bridge.dart`** — Platform channel bridge (`MethodChannel('com.tankstellen/auto')`). Exposes methods: `getNearbyStations(lat, lng, fuelType, limit)`, `getStationDetail(stationId)`. Called from the native side to fetch data from the Dart/Riverpod layer.

- **Data flow:** Native Android Auto screen → platform channel → Dart isolate (not main) → `StationServiceChain` → returns JSON → native screen renders via Car App Library templates.

- **Voice integration:** Android Auto voice commands ("find cheap gas") trigger the `FuelFinderScreen` automatically via Car App Library's `SearchTemplate`.

- **Modify `pubspec.yaml`** — No new Flutter dependencies needed; this is purely native + platform channels.

- **Testing:** Android Auto Desktop Head Unit (DHU) emulator for development testing. Manual testing checklist for Android Auto guidelines compliance.

**Effort estimate:** Large (3–4 days). Requires native Android development alongside Flutter. Platform channel bridge + Car App Library screens + voice integration + compliance testing.

---

### 6. Collaborative Trip Fuel Planner (Social Sharing)

**Description:** Extend the existing route search and itinerary features to support sharing a fuel plan with co-travelers. A user plans a route, the app identifies optimal fuel stops, and generates a shareable link/QR code that others can open in their Tankstellen app or browser to see the plan with live-updating prices.

**Why this matters:** Road trips are social. No fuel app lets you share a fuel plan. The existing `lib/features/itinerary/` and `lib/features/route_search/` modules provide the data foundation. This feature turns a solo utility into a social tool, increasing viral distribution.

**Implementation Concept:**

Leverages existing modules: `lib/features/itinerary/` (saved itineraries), `lib/features/route_search/` (route planning), and `lib/core/sync/` (Supabase).

- **`lib/features/itinerary/domain/entities/shared_itinerary.dart`** — Extends `SavedItinerary` with:
  ```dart
  @freezed
  class SharedItinerary {
    const factory SharedItinerary({
      required String shareId,           // UUID, used in the share URL
      required SavedItinerary itinerary,
      required DateTime sharedAt,
      required DateTime expiresAt,       // Auto-expire after 48h
      @Default(false) bool isPublic,
    }) = _SharedItinerary;
  }
  ```

- **Supabase backend:**
  - New migration: `shared_itineraries` table with `share_id`, `itinerary_json`, `created_by`, `expires_at`, `access_count`.
  - New Edge Function `get-shared-itinerary`: Returns itinerary data + live prices for all stops (fetched server-side).

- **`lib/features/itinerary/data/repositories/share_repository.dart`** — Uploads the itinerary to Supabase, generates a share URL (`https://tankstellen.app/trip/{shareId}`), returns a shareable link.

- **`lib/features/itinerary/providers/share_provider.dart`** — Manages share creation, URL generation, QR code generation (using existing `qr_flutter` dependency).

- **`lib/features/itinerary/presentation/widgets/share_trip_sheet.dart`** — Bottom sheet with: QR code, copy-link button, share-via-system-share button. Uses the system share sheet (`url_launcher` or `share_plus`).

- **Deep link handling:** Add route in `go_router` configuration: `/trip/:shareId` → `SharedItineraryScreen` that loads the shared plan and displays the route with current prices.

- **`lib/features/itinerary/presentation/screens/shared_itinerary_screen.dart`** — Read-only view of the shared trip with live prices, map view, and "Import to My Trips" button.

- **Fallback for non-app users:** The share URL opens a server-rendered web page (Supabase Edge Function serving HTML) showing the trip plan with a "Get the App" banner.

**Effort estimate:** Medium-Large (1.5–2 days). Share infrastructure + deep linking + QR generation + web fallback.

---

### 7. Station Amenity Filters & "Road Trip Essentials" Mode

**Description:** Enrich station data with amenity information (restrooms, car wash, shop, restaurant, air pump, ATM, accessibility) and add a filter system that lets users search by amenities. A "Road Trip Essentials" mode highlights stations with restrooms + shop + affordable prices for family trips.

**Why this matters:** Fillzz and Fuel Flash already show payment methods and opening hours. Clever-tanken includes amenity data. When fuel prices are similar across stations (especially under the new German regulation), amenities become the deciding factor. This is especially valuable for the route search feature.

**Implementation Concept:**

- **`lib/core/types/station_amenity.dart`** — New enum:
  ```dart
  enum StationAmenity {
    restroom, carWash, shop, restaurant, airPump, atm,
    wheelchair, truckParking, adBlue, lpg, cng, hvo100,
    evCharging, wifi, showers,
  }
  ```

- **Extend `Station` model** (in `lib/core/data/models/` or `lib/core/types/`) — Add `Set<StationAmenity> amenities` field. Provide a default empty set for backward compatibility. Update freezed model and JSON serialization.

- **Data sourcing strategy:**
  - **API-sourced:** Some country APIs include amenity data (Austria's Spritpreisrechner, France's prix-carburants.gouv.fr include service lists). Map these to `StationAmenity`.
  - **Community-sourced:** Extend the community report system (Feature #2) to allow amenity reports. New Supabase table `station_amenities` with crowd-verified data.
  - **OpenStreetMap fallback:** Query Overpass API for `amenity` and `shop` tags near the station coordinates. Cache results for 30 days.

- **`lib/features/search/presentation/widgets/amenity_filter_chips.dart`** — Horizontal scrollable chip row (similar to existing `EvFilterChips` pattern). Each chip is a toggleable `StationAmenity`. Filters are combined with AND logic.

- **`lib/features/search/providers/amenity_filter_provider.dart`** — `@riverpod` provider holding `Set<StationAmenity>` active filters. The `searchProvider` watches this and filters results client-side.

- **`lib/features/station_detail/presentation/widgets/amenity_grid.dart`** — Icon grid showing available amenities on the station detail screen. Uses consistent iconography (Material Icons or custom SVGs).

- **"Road Trip Essentials" preset:** A single-tap filter preset in route search that enables `restroom + shop` filters and sorts by a composite score of `(price * 0.7) + (amenityCount * 0.3)`.

- **Modify `lib/features/route_search/`** — The route stop selection algorithm should factor in amenities when the essentials mode is active, preferring stations with more amenities even if marginally more expensive.

**Effort estimate:** Large (2–3 days). Data sourcing from multiple sources + filter UI + route algorithm modification.

---

### 8. Weekly Price Intelligence Report (Push + In-App)

**Description:** An automated weekly report delivered via push notification and available in-app. Summarizes the user's local fuel market: average prices, price trends, cheapest days/times, comparison to national average, and a forecast for the coming week. Essentially a personalized "fuel market briefing."

**Why this matters:** ADAC publishes weekly fuel market reports, but they're generic. A personalized, hyperlocal report tied to the user's actual area and driving patterns creates a sticky habit loop (weekly app open). It also demonstrates the value of the app's data collection over time.

**Implementation Concept:**

Builds heavily on `lib/features/price_history/` (30-day local history) and the existing background task system (`workmanager`).

- **`lib/features/price_history/domain/entities/weekly_report.dart`** — Freezed model:
  ```dart
  @freezed
  class WeeklyReport {
    const factory WeeklyReport({
      required DateTime weekStart,
      required DateTime weekEnd,
      required double avgLocalPrice,
      required double avgNationalPrice,
      required double cheapestPriceThisWeek,
      required String cheapestStationName,
      required double priceChangePercent,  // vs. previous week
      required int bestHourThisWeek,
      required int bestDayThisWeek,
      required String trendSummary,        // "Prices rose 3.2% this week..."
      required String forecast,            // "Expect stable prices next week..."
      required double userSavings,         // If savings tracker is active
    }) = _WeeklyReport;
  }
  ```

- **`lib/features/price_history/data/repositories/weekly_report_repository.dart`** — Aggregates data from `PriceHistoryRepository` for the past 7 days. Computes all fields. The `forecast` uses a simple linear regression on the 30-day trend (extend the existing `PricePrediction` logic).

- **`lib/features/price_history/providers/weekly_report_provider.dart`** — `@riverpod` provider. Generates the report on demand and caches it for the week.

- **`lib/features/price_history/presentation/screens/weekly_report_screen.dart`** — Full-screen report with: trend chart (7-day line chart), comparison card (local vs. national), best times card, savings card, forecast card. Reuses chart widgets from `hourly_price_chart.dart` and `monthly_bar_chart.dart`.

- **Background generation:** Extend the WorkManager periodic task (runs every 15 minutes for alerts) to check if it's Monday morning and no report exists for this week. If so, generate the report and push a notification: "Your weekly fuel briefing is ready — you saved €X.XX last week."

- **`lib/core/notifications/`** — Add a new notification channel `weekly_report` with the appropriate Android notification channel configuration.

- **Share capability:** "Share my weekly savings" button generates a pre-formatted text for WhatsApp/social media: "I saved €12.50 on fuel this week with Tankstellen! Average local price: €1.85/L. 🚗⛽"

**Effort estimate:** Medium (6–8 hours). Mostly aggregation logic + one new screen + background trigger.

---

## Feature Priority Matrix

| # | Feature | Market Impact | Effort | Time Sensitivity | Recommendation |
|---|---------|:---:|:---:|:---:|---|
| 1 | Noon Strategy Advisor | High | Medium | **Urgent** (regulation is new) | Ship in v4.4 |
| 3 | HVO100 / Alt Fuels | High | Medium | High (ADAC already has it) | Ship in v4.4 |
| 4 | Savings Tracker | High | Large | Medium | Ship in v4.5 |
| 8 | Weekly Report | Medium | Medium | Medium | Ship in v4.5 |
| 2 | Gamification | High | Large | Low | Ship in v5.0-beta |
| 7 | Amenity Filters | Medium | Large | Low | Ship in v5.0-beta |
| 6 | Trip Sharing | Medium | Medium-Large | Low | Ship in v5.0-beta |
| 5 | Android Auto | Very High | Very Large | Low | Ship in v5.1 |

---

## Sources

- [New fuel rule from April 1, 2026 — basic-tutorials.com](https://basic-tutorials.com/news/new-fuel-rule-from-april-1-2026-prices-will-only-rise-once-a-day/)
- [Germany limits gas price rises — CNBC](https://www.cnbc.com/2026/04/01/germany-fuel-gas-price-limit-oil-iran-war.html)
- [ADAC Drive App — Spritpreise & HVO100](https://www.adac.de/services/apps/drive/)
- [Neue Preis-Regeln seit April 2026 — ADAC](https://www.adac.de/verkehr/tanken-kraftstoff-antrieb/tipps-zum-tanken/spritpreise-tagesverlauf/)
- [Fillzz — 20+ country coverage](https://play.google.com/store/apps/details?id=dev.nexyon.essenciel&hl=en)
- [EU Gasoline Prices April 2026 — Mappr](https://www.mappr.co/thematic-maps/fuel-prices-europe/)
- [GasBuddy Analysis 2026 — Intellectia](https://intellectia.ai/blog/gasbuddy-analysis-2026)
- [FuelUp gamification — App Store](https://apps.apple.com/au/app/fuelup-gas-prices-savings/id6757809517)
- [Fuel Prices in Europe — fuel-prices.eu](https://www.fuel-prices.eu/)
- [Best UK fuel price comparison apps 2026 — startrescue.co.uk](https://www.startrescue.co.uk/breakdown-cover/motoring-advice/motoring-developments-and-the-future/best-apps-in-2026-for-fuel-prices-fuel-tracking-navigation-and-traffic-alerts)
