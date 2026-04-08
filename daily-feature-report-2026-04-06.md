# Daily Market Analysis & Feature Report

**Date:** 2026-04-06
**App:** Tankstellen v4.3.0
**Countries Live:** 11 (DE, FR, AT, ES, IT, DK, AR, PT, GB, AU, MX)
**Analyst:** Automated Market Intelligence

---

## Executive Summary

Today's analysis identifies **6 high-impact features** that competitors (clever-tanken, mehr-tanken, GasBuddy, Waze, Fillzz) are shipping or that represent untapped market gaps. Tankstellen's open-source, privacy-first, multi-country positioning is strong, but several feature gaps risk losing users to apps that now combine fuel pricing with EV charging, carbon tracking, and community engagement. The features below are ranked by competitive urgency and implementation feasibility.

---

## Feature 1: EV Charging Station Integration ("Hybrid Energy Finder")

### Description

Clever-tanken has launched "clever-laden" (in partnership with Bosch) that allows users to find EV charging stations alongside traditional fuel stations. Mehr-tanken now lets users select "electricity" as a fuel type during onboarding. As Europe accelerates EV adoption (25%+ of new car sales in 2025/2026), a fuel app without charging integration loses relevance for the growing hybrid/BEV audience.

This feature adds EV charging station discovery alongside existing fuel stations — search, map, and favorites all become "energy points" rather than just "gas stations."

### Competitive Gap

| App | EV Charging? | Notes |
|-----|-------------|-------|
| clever-tanken | Yes | "clever-laden" — full charging search, plug filters, session control |
| mehr-tanken | Yes | Electricity as fuel type, plug preference in profile |
| Fillzz | Partial | Multi-fuel including hydrogen, no charging sessions |
| GasBuddy | No | US-only, no EV |
| **Tankstellen** | **No** | **Critical gap** |

### Implementation Concept

**Data Sources (free/open):**
- **OpenChargeMap API** (ocm.org) — global open database with 500K+ charging points, free API, CC-BY-SA license (MIT-compatible). Covers all 11 supported countries.
- **NOBIL** (Norway/Nordics) — for future Nordic expansion.
- Country-specific open data where available (e.g., Bundesnetzagentur Ladesäulenregister for DE).

**Architecture:**

1. **New model** `lib/features/search/domain/entities/charging_station.dart`:
   ```dart
   @freezed
   abstract class ChargingStation with _$ChargingStation {
     const factory ChargingStation({
       required String id,
       required String name,
       required String operatorName,
       required double lat,
       required double lng,
       required String address,
       required List<Connector> connectors,  // Type2, CCS, CHAdeMO, etc.
       double? maxPowerKw,
       bool? isFastCharger,
       String? statusType,  // Available, Occupied, Unknown
       double? dist,
       String? usageCost,
     }) = _ChargingStation;
   }

   @freezed
   abstract class Connector with _$Connector {
     const factory Connector({
       required String type,       // "Type 2", "CCS", "CHAdeMO"
       required double powerKw,
       String? currentType,        // AC / DC
       int? quantity,
     }) = _Connector;
   }
   ```

2. **New service** `lib/core/services/impl/openchargemap_service.dart`:
   - Implements a new `ChargingService` abstract interface in `lib/core/services/charging_service.dart`
   - Uses existing `DioFactory` for HTTP, `CacheManager` with 30min TTL
   - Endpoint: `https://api.openchargemap.io/v3/poi/?latitude=X&longitude=Y&distance=10&maxresults=50`
   - Falls back to cached data when offline (same `ServiceResult<T>` pattern)

3. **Profile extension** in `lib/features/profile/`:
   - Add `vehicleType` enum: `combustion`, `hybrid`, `electric`
   - Add `preferredConnectors` list (Type2, CCS, CHAdeMO)
   - Stored in existing `UserProfile` Hive box

4. **UI integration:**
   - Add toggle in search/map screens: "Fuel" / "Charging" / "Both"
   - Charging stations rendered with distinct green markers on `flutter_map`
   - New `ChargingStationDetailScreen` showing connectors, power, cost, operator
   - Favorites system extended to support `ChargingStation` entities

5. **Providers:**
   - `chargingStationsProvider(lat, lng)` — `@riverpod` scoped, returns `AsyncValue<List<ChargingStation>>`
   - `vehicleTypeProvider` — `@Riverpod(keepAlive: true)`, reads from profile

**Estimated effort:** Large (3-5 days)
**Priority:** P0 — Critical competitive gap

---

## Feature 2: Community Price Verification & Gamification

### Description

GasBuddy's core moat is its community-driven price reporting with 70M+ downloads and gamified rewards. Mehr-tanken has price reports from users. Tankstellen currently has a `report` feature for flagging inaccuracies but lacks a positive feedback loop — users cannot confirm prices, earn points, or compete on a leaderboard. Adding lightweight gamification turns passive users into engaged contributors, improving data quality and retention.

### Competitive Gap

| App | Community Features | Gamification |
|-----|-------------------|-------------|
| GasBuddy | Price reporting, photo upload, reviews | Points, raffles, leaderboards |
| mehr-tanken | User price corrections | None |
| clever-tanken | Price alerts (passive) | None |
| **Tankstellen** | Error reports only | **None** |

### Implementation Concept

**Architecture:**

1. **New feature module** `lib/features/community/`:
   ```
   community/
   ├── domain/
   │   └── entities/
   │       ├── price_report.dart          # User-submitted price confirmation
   │       └── user_reputation.dart       # Points, level, badges
   ├── data/
   │   └── community_repository.dart      # Supabase backend
   ├── presentation/
   │   ├── screens/
   │   │   └── leaderboard_screen.dart
   │   └── widgets/
   │       ├── confirm_price_button.dart   # "Price correct?" thumbs up/down
   │       └── reputation_badge.dart
   └── providers/
       └── community_providers.dart
   ```

2. **Model** `price_report.dart`:
   ```dart
   @freezed
   abstract class PriceReport with _$PriceReport {
     const factory PriceReport({
       required String stationId,
       required String fuelType,
       required double reportedPrice,
       required DateTime reportedAt,
       required String userId,  // Anonymous Supabase auth ID
       @Default(false) bool isConfirmation,  // true = "price is correct"
     }) = _PriceReport;
   }
   ```

3. **Reputation model** `user_reputation.dart`:
   ```dart
   @freezed
   abstract class UserReputation with _$UserReputation {
     const factory UserReputation({
       required String userId,
       @Default(0) int points,
       @Default(1) int level,
       @Default([]) List<String> badges,
       @Default(0) int confirmationsCount,
       @Default(0) int reportsCount,
     }) = _UserReputation;
   }
   ```

4. **Backend (Supabase):**
   - New `price_reports` table: `id, station_id, fuel_type, reported_price, user_id, is_confirmation, created_at`
   - New `user_reputation` table: `user_id, points, level, badges`
   - Supabase Edge Function `calculate-reputation` — triggered on insert, awards points
   - RLS policies: users can insert their own reports, read aggregated reputation data
   - Privacy-first: no usernames exposed, only anonymous leaderboard ranks

5. **UI integration:**
   - `StationDetailScreen`: Add "Price correct?" confirmation button (1 tap)
   - Confirmation count badge on stations: "Verified by 3 users"
   - Profile tab: Show points, level, badges
   - Optional leaderboard (regional, monthly reset)

6. **Points system:**
   - Confirm a price: +5 points
   - Report an error (later validated): +15 points
   - Daily check-in: +2 points
   - Level thresholds: 0–50 (Starter), 51–200 (Contributor), 201–500 (Expert), 500+ (Champion)

**Estimated effort:** Large (4-5 days)
**Priority:** P1 — Strong retention and engagement driver

---

## Feature 3: Fuel Price Prediction & Best-Time-to-Fill Advisor

### Description

Mehr-tanken's "Flizzi" feature recommends the optimal refueling time based on regional price pattern analysis. Tankstellen already has `price_history` with 30-day local recording and basic statistical analysis, but it does not surface actionable predictions like "Wait 3 hours — prices typically drop 4ct at 18:00 on Mondays." Converting existing data into a proactive advisor creates a strong differentiator, especially since this works offline with local data.

### Competitive Gap

| App | Price History | Predictions | Proactive Advice |
|-----|-------------|-------------|-----------------|
| mehr-tanken | Yes | "Flizzi" optimal time | Yes — push notifications |
| clever-tanken | Price curves | Day-of-week patterns | Partial |
| GasBuddy | Yes | Basic trend | No |
| **Tankstellen** | **Yes (30 days)** | **Basic stats exist** | **No proactive advice** |

### Implementation Concept

**Leverage existing infrastructure:**
- `lib/features/price_history/` already stores 30 days of `PriceRecord` data per station
- `lib/features/alerts/` already has push notification infrastructure via `workmanager` + `flutter_local_notifications`

1. **New service** `lib/features/price_history/data/price_predictor.dart`:
   ```dart
   class PricePredictor {
     /// Analyzes stored PriceRecords to find day-of-week and hour-of-day patterns
     PricePrediction predict({
       required List<PriceRecord> history,
       required String fuelType,
       required DateTime currentTime,
     });
   }

   @freezed
   abstract class PricePrediction with _$PricePrediction {
     const factory PricePrediction({
       required double currentPrice,
       required double predictedLowPrice,
       required DateTime predictedLowTime,
       required double confidence,        // 0.0–1.0
       required String advice,            // "Wait 3h — prices drop ~4ct"
       required PriceTrend trend,         // rising, falling, stable
       required Map<int, double> hourlyPattern,  // hour -> avg price
       required Map<int, double> weekdayPattern, // weekday -> avg price
     }) = _PricePrediction;
   }
   ```

2. **Algorithm:**
   - Group historical prices by hour-of-day and day-of-week
   - Calculate weighted moving average (recent data weighted 2x)
   - Identify cheapest daily window per station (typically 18:00–20:00 in DE)
   - Confidence score based on data density and pattern consistency (stddev)
   - Country-specific: DE has clear daily patterns (MTS-K mandated updates), FR/IT less so

3. **UI:**
   - **Search results**: Small badge "Best in 2h ↓4ct" on stations with high-confidence predictions
   - **Station detail**: New "Best Time" card with hourly price chart and recommendation
   - **Smart alerts**: Enhance existing `PriceAlert` to trigger on predicted price drops, not just thresholds

4. **Background task:**
   - Extend existing `WorkManager` periodic task to run predictions daily
   - Push notification: "Fuel at [Station] is expected to drop to €1.52 around 18:00"

**Estimated effort:** Medium (2-3 days) — leverages existing price_history + alerts infrastructure
**Priority:** P1 — Unique value proposition, works fully offline

---

## Feature 4: Carbon Footprint & Fuel Expense Tracker

### Description

Fleet management apps (Samsara, SimplyFleet) and consumer driving apps increasingly show CO2 emissions per trip and monthly fuel expense summaries. No major European fuel price app offers a personal carbon footprint tracker tied to actual fuel purchases. This positions Tankstellen as a "conscious driver's companion" — appealing to environmentally aware users and creating daily engagement through expense logging.

### Competitive Gap

No consumer fuel price comparison app in Europe currently integrates personal carbon tracking with fuel expense management. This is a whitespace opportunity.

### Implementation Concept

1. **New feature module** `lib/features/tracker/`:
   ```
   tracker/
   ├── domain/
   │   └── entities/
   │       ├── fuel_log.dart         # Individual fill-up record
   │       └── carbon_summary.dart   # Aggregated CO2 and cost stats
   ├── data/
   │   └── tracker_repository.dart   # Hive-backed local storage
   ├── presentation/
   │   ├── screens/
   │   │   ├── tracker_screen.dart        # List of fill-ups
   │   │   └── tracker_summary_screen.dart # Charts & insights
   │   └── widgets/
   │       ├── add_fillup_sheet.dart
   │       ├── monthly_chart.dart
   │       └── carbon_badge.dart
   └── providers/
       └── tracker_providers.dart
   ```

2. **Model** `fuel_log.dart`:
   ```dart
   @freezed
   abstract class FuelLog with _$FuelLog {
     const factory FuelLog({
       required String id,
       required DateTime date,
       required String stationId,
       required String fuelType,
       required double liters,
       required double pricePerLiter,
       required double totalCost,
       required double odometer,        // km reading
       double? co2Kg,                   // Calculated: liters × emission factor
       String? notes,
     }) = _FuelLog;
   }
   ```

3. **CO2 calculation** (well-to-wheel emission factors per liter):
   - E5/E10: 2.31 kg CO2/L
   - Diesel: 2.68 kg CO2/L
   - LPG: 1.51 kg CO2/L
   - CNG: 2.54 kg CO2/kg (convert from Nm³)
   - Factors stored as constants in `lib/core/constants/emission_factors.dart`

4. **Storage:** New Hive box `fuel_logs` — local-first, syncs to Supabase `fuel_logs` table via existing TankSync infrastructure

5. **UI:**
   - New bottom nav tab or sub-section in Profile
   - "Log Fill-up" bottom sheet: pre-populated from last viewed station, select fuel type, enter liters + odometer
   - Monthly summary: total cost (€), total liters, avg consumption (L/100km), total CO2 (kg)
   - Charts via `fl_chart` (already common in Flutter): monthly cost trend, CO2 trend
   - "You saved X kg CO2 vs. last month" motivational badge

6. **Integration with existing features:**
   - `StationDetailScreen`: "Log fill-up here" button
   - `Calculator` feature: auto-populate from tracker's avg consumption
   - `TankSync`: Sync fuel logs across devices

**Estimated effort:** Medium-Large (3-4 days)
**Priority:** P2 — Differentiation play, builds daily engagement habit

---

## Feature 5: UK Fuel Finder Open Data Integration (Government Mandate)

### Description

In February 2026, the UK Government launched the **Fuel Finder** scheme, mandating all UK fuel retailers to submit price updates within 30 minutes to a central open-data system managed by the CMA (Competition and Markets Authority). This is the most significant open-data fuel pricing initiative in Europe. Tankstellen already has `uk_station_service.dart` — but this new government feed provides near-real-time, comprehensive pricing for **every UK station**, far more accurate than previous voluntary schemes.

### Competitive Gap

Most European fuel apps have weak UK coverage. The new CMA Fuel Finder API gives Tankstellen an opportunity to have best-in-class UK data at zero cost — matching or beating established UK apps like PetrolPrices, Confused.com, and the AA.

### Implementation Concept

1. **Update existing service** `lib/core/services/impl/uk_station_service.dart`:
   - Migrate from current CMA data source to the new mandatory Fuel Finder open dataset
   - The Fuel Finder API provides structured JSON with: station ID, location, brand, fuel types (unleaded, super unleaded, diesel, premium diesel), and price updated within 30 min
   - Reduce cache TTL from current value to **5 minutes** (data now guaranteed fresh)

2. **Data mapping:**
   ```dart
   // Map UK fuel types to existing Station model fields:
   // "unleaded" → e5 (or a new field ukUnleaded)
   // "super_unleaded" → e98
   // "diesel" → diesel
   // "premium_diesel" → dieselPremium
   ```

3. **New UK-specific features:**
   - **Price confidence indicator**: Since data is government-mandated within 30 min, show a "Government verified" badge on UK stations
   - **Retailer comparison**: Aggregate data to show avg price by brand (Tesco, Sainsbury's, BP, Shell) — unique insight

4. **Testing:**
   - Add UK fixture data to `test/fixtures/`
   - Update `uk_station_service_test.dart` with Fuel Finder response format

**Estimated effort:** Small-Medium (1-2 days)
**Priority:** P1 — Low effort, high impact for UK market expansion

---

## Feature 6: Android Auto / CarPlay-Ready Quick View

### Description

Apps like Waze and GasBuddy are optimized for in-car use. 2026's best fuel apps (per startrescue.co.uk) highlight navigation integration, speed limit display, and large-touch interfaces as key differentiators. Tankstellen currently has no car-optimized UI. A simplified "driving mode" or Android Auto integration would make the app usable while driving — critical for a fuel-finding app.

### Competitive Gap

| App | Android Auto | CarPlay | Driving Mode |
|-----|-------------|---------|-------------|
| Waze | Full | Full | Built-in |
| GasBuddy | Partial | No | No |
| clever-tanken | No | No | No |
| **Tankstellen** | **No** | **No** | **No** |

### Implementation Concept

**Phase 1: Driving Mode (in-app) — Achievable now**

1. **New screen** `lib/features/map/presentation/screens/driving_mode_screen.dart`:
   - Full-screen map with large, high-contrast station markers
   - Big price labels directly on map (no popup needed)
   - Large "cheapest nearby" card at bottom: station name, price, distance, one-tap navigation
   - Auto-refreshes based on GPS movement (debounced 2km threshold)
   - Dark theme forced for readability
   - Minimal touch targets: 56dp+ per Material accessibility guidelines

2. **Entry points:**
   - Floating "driving mode" button on map screen
   - Auto-suggest when app detects movement >30 km/h via `geolocator` speed property

3. **Voice feedback (optional):**
   - Use `flutter_tts` package to announce cheapest station: "Cheapest diesel at 1.47 at Shell, 800 meters ahead"
   - Triggered on proximity (within 2km of a station cheaper than threshold)

4. **Safety:**
   - Lock most interactions while speed >10 km/h
   - Show only essential info: price, distance, direction arrow
   - One-tap to open external navigation (Google Maps / Waze intent)

**Phase 2: Android Auto (future — requires Android Auto SDK)**

5. **Android Auto integration** (when Flutter plugin matures):
   - Register as a navigation/POI app in `AndroidManifest.xml`
   - Implement `CarAppService` with `PlaceListMapTemplate` showing nearby stations
   - Requires `androidx.car.app:app:1.4+` — currently limited Flutter support
   - Target: v5.0.0-beta milestone

**Estimated effort:** Phase 1: Medium (2-3 days), Phase 2: Large (5+ days, depends on Flutter AA plugin)
**Priority:** P2 (Phase 1), P3 (Phase 2)

---

## Priority Matrix

| Priority | Feature | Effort | Impact | Competitive Urgency |
|----------|---------|--------|--------|-------------------|
| **P0** | EV Charging Integration | Large (3-5d) | Very High | Critical — competitors already shipping |
| **P1** | UK Fuel Finder Open Data | Small (1-2d) | High | Time-sensitive — government data now live |
| **P1** | Price Prediction Advisor | Medium (2-3d) | High | Strong differentiator, leverages existing infra |
| **P1** | Community & Gamification | Large (4-5d) | High | Retention moat, requires Supabase backend |
| **P2** | Carbon & Expense Tracker | Medium-Large (3-4d) | Medium-High | Whitespace opportunity, daily engagement |
| **P2** | Driving Mode | Medium (2-3d) | Medium | UX polish, safety-first differentiation |

---

## Recommended Sprint Roadmap

**Sprint 1 (this week):** UK Fuel Finder update (P1, low effort) + Price Prediction Advisor (P1, leverages existing code)

**Sprint 2 (next week):** EV Charging Integration (P0, largest impact on market positioning)

**Sprint 3:** Community & Gamification (P1, requires backend planning) + Carbon Tracker (P2)

**Sprint 4:** Driving Mode Phase 1 (P2, UX polish for v5.0 beta)

---

## Sources

- [Best UK fuel price comparison apps 2026](https://www.webuyanycar.com/guides/car-ownership/best-fuel-price-comparison-apps/)
- [Best apps in 2026 for fuel prices, tracking, navigation](https://www.startrescue.co.uk/breakdown-cover/motoring-advice/motoring-developments-and-the-future/best-apps-in-2026-for-fuel-prices-fuel-tracking-navigation-and-traffic-alerts)
- [Fuel app comparison: The best apps for refuelling | NAVIT](https://www.navit.com/blog/best-fuel-apps-compared)
- [clever-tanken.de on Google Play](https://play.google.com/store/apps/details?id=de.mobilesoftwareag.clevertanken&hl=en)
- [mehr-tanken on Google Play](https://play.google.com/store/apps/details?id=de.msg&hl=en_US)
- [clever-laden by Mobile Software AG](https://www.mobile-software.de/showcase/clever-laden/)
- [GasBuddy Analysis 2026](https://intellectia.ai/blog/gasbuddy-analysis-2026)
- [Top 5 cheapest refueling apps in Germany | Rally](https://www.getrally.com/blog/top-5-cheapest-refueling-apps-in-germany-2025-edition)
- [Three apps to help drivers in Germany find the cheapest fuel | The Local](https://www.thelocal.de/20241008/three-apps-to-help-drivers-in-germany-find-the-cheapest-fuel)
- [Live Fuel Prices - Fillzz on Google Play](https://play.google.com/store/apps/details?id=dev.nexyon.essenciel&hl=en)
- [Best EV Charging Apps 2026 | Charge Rigs](https://chargerigs.com/articles/best-ev-charging-app)
- [Fleet fuel efficiency tips | FleetWorthy](https://fleetworthy.com/resources/blog/fleet-fuel-efficiency-tips/)
- [Fuel Prices in Europe 2026 | fuel-prices.eu](https://www.fuel-prices.eu/)
