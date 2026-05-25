<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Daily Feature Analysis — 2026-05-04

## Market Context

The fuel and mobility app landscape in early May 2026 is shaped by three converging forces: the insurance industry's accelerating shift toward Usage-Based Insurance (UBI) with telematics-verified driving data (the global connected insurance telematics market reached $3.8B in 2024, projected to nearly 1B active premiums by 2031); a 40% jump in carpooling activity driven by fuel price volatility and return-to-office mandates (Scoop reported a 40% ride increase from Feb to Mar 2026); and growing consumer demand for carbon accountability beyond passive dashboards — carbon offset apps like Klima and Capture are mainstreaming the concept of "neutralise what you can't avoid." Meanwhile, weather-aware routing is becoming table stakes in logistics (Google Maps, Waze, Upper all factor conditions into fuel-efficient routing), but no consumer fuel price app connects weather forecasts to personal fuel consumption predictions. Clever Tanken remains Germany's largest with 5M+ users but offers no OBD-II integration, no multi-country coverage, and no driving insights. ADAC Drive covers multiple European countries and includes EV charging with 120K+ stations, but lacks consumption tracking, driving coaching, or any telematics integration.

**Tankstellen's current positioning:** 11 countries (17 station services), 23 languages, OBD-II driving insights with auto-record and driving score, EV charging (OpenChargeMap), achievements/gamification, loyalty cards, privacy-first (no Firebase/tracking/ads), price predictions (day-of-week + hour-of-day model), route search with strategies, glide coach with traffic signal anticipation, consumption tracking, CO2 dashboard, CarDataBridge for Android Auto/CarPlay, home-screen widget, receipt OCR, maintenance suggestion engine.

**Previously proposed features (May 1–3):** CarPlay/Android Auto template screens, Crowdsourced Price OCR, Smart Refuel Timing, Community Leaderboard, Wearable Companion, Voice-First In-Car AI Copilot, Hybrid & EV Energy Cost Optimizer, Station Queue & Availability Intelligence, Social Carpooling Cost-Split (concept only), Multi-Modal Journey Cost Comparison, AI-Powered Maintenance Cost Predictor, Predictive Price Arbitrage Alerts, Station Amenity & Review Ecosystem, Fleet/Family Group Management, Maintenance-Aware Refuel Routing, Personalised Savings Dashboard with Goal Tracking.

**Today's focus:** Five new feature gaps identified from fresh market intelligence — weather-aware fuel efficiency advisor, insurance telematics data export for UBI discounts, fuel price volatility heatmap, trip cost sharing calculator for carpoolers, and carbon offset marketplace integration.

---

## Feature 1: Weather-Aware Fuel Efficiency Advisor

### Description

Weather conditions have a measurable and significant impact on fuel consumption that no consumer fuel price app currently accounts for. Cold temperatures increase fuel consumption by 12–20% for short trips (engine warm-up, denser air, winter-grade fuel blends), headwinds at highway speeds can add 10–20% to consumption, rain increases rolling resistance by 20–30%, and air conditioning in summer heat adds 5–15%. Tankstellen already tracks per-trip consumption via OBD-II and has a driving score system, but treats all trips equally regardless of conditions. By integrating weather forecast data, the app can: (a) adjust driving score expectations so users aren't penalised for unavoidable weather-driven consumption increases, (b) warn before a trip that conditions will cost extra fuel and suggest timing alternatives, (c) provide weather-normalised consumption trends so users can distinguish genuine vehicle degradation from seasonal effects, and (d) recommend optimal departure windows that balance fuel price predictions with weather-efficiency forecasts. No competitor — not Clever Tanken, ADAC Drive, TankPilot, Fuelio, or GasBuddy — offers weather-consumption correlation. This uniquely extends Layer 2 ("burn less fuel") with environmental intelligence.

### Detailed Implementation Concept

**Architecture:**

New domain service under `lib/core/weather/` for weather data fetching and caching, plus integration points in the consumption, driving, and route search features. Uses Open-Meteo API (free, no API key required, covers all 11 supported countries).

**Key files to create:**

- `lib/core/weather/weather_service.dart` — Abstract interface defining `Future<WeatherForecast> getForecast(double lat, double lng, {int hoursAhead = 24})` and `Future<WeatherCondition> getCurrentConditions(double lat, double lng)`. Follows the existing service abstraction pattern used in `lib/features/station_services/`.

- `lib/core/weather/open_meteo_weather_service.dart` — Implementation using the Open-Meteo free API (`https://api.open-meteo.com/v1/forecast`). Fetches: temperature, precipitation probability, wind speed + direction, humidity. Uses the existing `Dio` HTTP client with interceptors from `lib/core/constants/api_constants.dart`. Response parsed into domain entities.

- `lib/core/weather/weather_cache.dart` — Extends the existing `CacheManager` pattern from `lib/core/cache/cache_manager.dart`. Weather data cached with 1-hour TTL for current conditions, 6-hour TTL for forecasts. Hive-backed for offline access.

- `lib/core/weather/entities/weather_forecast.dart` — Freezed entity: `hourlyEntries` (List of `WeatherHour`), `locationLat`, `locationLng`, `fetchedAt`. Each `WeatherHour`: `dateTime`, `temperatureCelsius`, `precipitationMm`, `windSpeedKmh`, `windDirectionDeg`, `humidity`, `weatherCode` (WMO standard codes used by Open-Meteo).

- `lib/core/weather/entities/fuel_efficiency_impact.dart` — Freezed entity: `temperatureImpactPercent` (estimated consumption change from temperature vs. 20°C baseline), `windImpactPercent` (headwind/tailwind effect based on trip bearing vs. wind direction), `precipitationImpactPercent` (wet road rolling resistance), `hvacImpactPercent` (estimated A/C or heater load), `totalImpactPercent` (combined), `adjustedBaselineConsumption` (L/100km, the user's baseline adjusted for conditions), `humanSummary` (localised string, e.g. "Cold weather and headwind may increase consumption by ~14%").

- `lib/core/weather/fuel_weather_correlator.dart` — Pure-Dart domain service. Takes: the user's baseline consumption (from `ConsumptionStats`), current or forecast `WeatherCondition`, and optionally the trip bearing (from route or GPS). Computes `FuelEfficiencyImpact` using published engineering models: temperature factor = piecewise linear (below 0°C: +15–20%, 0–10°C: +8–12%, 10–20°C: +2–5%, 20–25°C: baseline, 25°C+: +3–8% for A/C), wind factor = `0.5 * airDensity * dragCoeff * frontalArea * (headwindComponent^2)` simplified to a lookup table indexed by headwind speed, precipitation factor = +3% per mm/h of rain. Conservative estimates — always shows "estimated" to avoid false precision.

- `lib/features/consumption/domain/weather_normalised_stats.dart` — Service that wraps `ConsumptionStats` and adjusts historical trip consumption figures for the weather conditions at the time of each trip. Requires stored weather data per trip (see integration below). Exposes: `normalisedAvgConsumption` (what the user's consumption would be if every trip were at 20°C, dry, no wind), `weatherPenaltyThisMonth` (total extra litres burned due to weather), `trendExcludingWeather` (is the vehicle genuinely getting less efficient, or is it just winter?).

- `lib/features/consumption/presentation/widgets/weather_impact_chip.dart` — Small chip displayed on the trip detail screen next to the consumption figure. Shows: weather icon + "+X%" or "−X%" impact estimate. Tapping opens a tooltip explaining which conditions affected the trip. Integrates into existing trip detail view in `lib/features/consumption/presentation/`.

- `lib/features/driving/presentation/widgets/weather_advisory_banner.dart` — Banner shown at the top of the driving mode screen when conditions are expected to increase consumption by >10%. Shows: "Headwind + rain expected — consumption may be ~15% higher than usual. Consider delaying 2h for calmer conditions." Tappable to see hourly forecast breakdown.

- `lib/features/route_search/domain/weather_aware_cost_model.dart` — Extension of the route search cost model. When computing the true cost of a detour to a cheaper station, factors in current weather conditions: a 5 km detour into a headwind costs more fuel than a 5 km detour with a tailwind. Integrates as a decorator on the existing `RouteSearchStrategy` (same pattern as the maintenance-aware routing proposed on May 3).

**Integration points:**

- Trip recorder (`lib/features/consumption/domain/trip_recorder.dart`) — stores weather snapshot at trip start and end. Adds `weatherAtStart` and `weatherAtEnd` fields to the trip entity (extends `lib/features/consumption/domain/entities/`).
- Driving score (`lib/features/consumption/domain/driving_score.dart`) — adjusts scoring thresholds based on weather. A trip in heavy rain with 8.2 L/100km should score the same as a dry trip at 7.1 L/100km for the same vehicle.
- CO2 dashboard (`lib/features/carbon/`) — can show weather-normalised emissions trend alongside raw trend.
- Route search (`lib/features/route_search/`) — weather-aware cost model as an optional decorator.
- Price prediction (`lib/features/price_history/providers/price_prediction_provider.dart`) — combined "best time to fill" that balances cheapest price window with best weather window for the drive to that station.
- Existing `Dio` instance and `CacheManager` for API calls and caching.

**Privacy alignment:**

- Open-Meteo is a free, open-source weather API — no API key, no user tracking, no data sharing.
- Weather data is location-based (lat/lng) but uses the same GPS position the app already has for station search — no new permissions required.
- Weather snapshots stored locally in Hive alongside trip data — never uploaded unless TankSync is enabled.
- User can disable weather features entirely in settings.

---

## Feature 2: Insurance Telematics Data Export & UBI Portal

### Description

The insurance industry in 2026 is aggressively moving toward Usage-Based Insurance (UBI), where drivers who prove safe, efficient driving habits receive premium discounts of 10–25%. The global connected insurance telematics market is projected to grow from 278M active premiums in 2026 to nearly 1B by 2031. Traditionally, insurers require their own OBD-II dongle or a dedicated app to collect driving data. Tankstellen already collects exactly the data insurers need — trip distance, speed profiles, acceleration events, braking patterns, time-of-day driving, and the composite driving score — through its existing OBD-II integration. By offering a standardised, privacy-controlled telematics export, Tankstellen can become the neutral "driving passport" that users share with any insurer, eliminating the need for insurer-specific hardware. This is a massive value proposition: save money at the pump (Layer 1), drive more efficiently for a better score (Layer 2), and now save money on insurance too — all from the same app. No fuel price app currently offers insurance telematics export. This positions Tankstellen at the intersection of fuel savings and insurance savings, dramatically expanding its value per user.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/telematics_export/` with clean architecture layers. Generates standardised driving reports from existing trip and driving score data. Export formats: PDF report (human-readable for sharing with any insurer), JSON/CSV (machine-readable for API integration), and a QR-scannable summary for in-person agent meetings.

**Key files to create:**

- `lib/features/telematics_export/domain/entities/telematics_report.dart` — Freezed entity: `reportId` (UUID), `vehicleId`, `periodStart`, `periodEnd`, `totalTrips`, `totalKm`, `totalHours`, `avgDrivingScore`, `scoreTrend` (improving/stable/declining), `hardBrakingEventsPerKm`, `hardAccelEventsPerKm`, `speedingPercentage` (% of km driven >10% over posted limit, requires speed limit data from OSM — already partially available via glide coach's `osm_traffic_signal_client.dart`), `nightDrivingPercentage` (% of km between 23:00–05:00), `avgTripDistance`, `idleTimePercentage`, `fuelEfficiencyRating` (A–F based on vehicle class comparison), `generatedAt`, `appVersion`, `integrityHash` (SHA-256 of report contents to prevent tampering).

- `lib/features/telematics_export/domain/entities/telematics_summary.dart` — Freezed entity for the QR-scannable compact summary: `overallGrade` (A–F), `totalKm`, `avgScore`, `periodMonths`, `riskCategory` (low/medium/high derived from driving patterns), `verificationUrl` (optional deep link back into the app for the insurer to verify — requires TankSync).

- `lib/features/telematics_export/domain/telematics_report_generator.dart` — Pure-Dart service. Reads: all trips for a vehicle within a date range from `lib/features/consumption/data/`, driving scores from `driving_score.dart`, driving insights (hard accel, idle, cold start) from `driving_insight.dart`. Aggregates into `TelematicsReport`. Computes the integrity hash from deterministic JSON serialisation of all fields.

- `lib/features/telematics_export/domain/risk_classifier.dart` — Maps driving metrics to insurance risk categories using published actuarial guidelines. Conservative classification: only rates users as "low risk" when data strongly supports it. Uses: (a) hard braking frequency (< 2 per 100 km = low), (b) night driving (< 10% = low), (c) speeding (< 5% = low), (d) driving score trend (stable or improving = low). Any single "high" metric caps the overall category at "medium."

- `lib/features/telematics_export/data/report_exporter.dart` — Generates export files. PDF: uses the existing PDF generation pattern (the app already has `share_plus` for sharing). The PDF includes: cover page with vehicle info + overall grade, monthly trend charts (driving score, consumption, events), detailed metrics table, integrity hash + QR code at the bottom. JSON/CSV: machine-readable export following the emerging OICA (Organisation Internationale des Constructeurs d'Automobiles) connected vehicle data format where applicable.

- `lib/features/telematics_export/presentation/screens/telematics_export_screen.dart` — Main screen: (1) "Your Driving Profile" hero card with overall grade (A–F) and trend arrow, (2) key metrics displayed as a radar chart (safety, efficiency, consistency, time-of-day, mileage), (3) period selector (last 3/6/12 months), (4) "Generate Report" button with format picker (PDF/JSON/CSV), (5) "Share with Insurer" button that uses `share_plus` to send the file, (6) QR code display for in-person sharing.

- `lib/features/telematics_export/presentation/widgets/driving_profile_radar.dart` — Radar/spider chart widget showing 5 axes: safety (braking/accel events), efficiency (consumption vs. vehicle class average), consistency (score variance across trips), time-of-day (% daytime driving), experience (total km in reporting period). Built with `CustomPainter` using the existing theming from `lib/app/theme.dart`.

- `lib/features/telematics_export/presentation/widgets/integrity_badge.dart` — Small badge shown on the report and export screen indicating: "This report is integrity-verified — the hash can be independently validated." Explains to users why insurers can trust the data.

- `lib/features/telematics_export/providers/telematics_export_provider.dart` — Riverpod provider composing: `TelematicsReportGenerator`, trip data providers, driving score providers, vehicle profile provider. Caches the most recent report to avoid re-computation on screen revisits.

**Integration points:**

- Reads trip data from `lib/features/consumption/data/` repositories — fill-ups, trip history, consumption stats.
- Reads driving scores from `lib/features/consumption/domain/driving_score.dart` and `driving_insight.dart`.
- Reads vehicle profile from `lib/features/vehicle/domain/entities/` for vehicle class comparison.
- Uses `share_plus` (already in pubspec.yaml) for file sharing.
- Uses `qr_flutter` (already in pubspec.yaml) for QR code generation.
- Accessible from a new entry in `lib/features/profile/presentation/` settings screen or from the consumption/driving section.
- Optional: report metadata syncs via TankSync (Supabase) so cross-device users see the same export history.
- Glide coach's `osm_traffic_signal_client.dart` — could be extended to fetch speed limit data from OSM for speeding percentage calculation.

**Privacy alignment:**

- Reports are generated entirely on-device — no data sent to Tankstellen servers or any third party.
- The user explicitly chooses when and with whom to share the report — no automatic sharing.
- Reports contain aggregate statistics only — no raw GPS traces, no specific locations, no timestamps below daily granularity.
- Integrity hash allows verification without requiring the raw data to leave the device.
- Users can generate reports for specific date ranges, choosing how much history to reveal.
- No insurer partnerships or data-sharing agreements required — the user is the sole data controller.

---

## Feature 3: Fuel Price Volatility Heatmap

### Description

Current fuel price apps show today's prices as static lists or map pins, and price history as per-station line charts. But drivers also need to understand price volatility — which areas have stable, predictable prices (allowing planned fill-ups) and which swing wildly (creating both risk and opportunity). Tankstellen already stores 30-day price history per station across 11 countries, a dataset that can be transformed into a volatility heatmap. The heatmap overlays the existing map view with colour-coded zones: green zones have stable prices (low standard deviation), yellow zones have moderate swings, red zones have high volatility. This helps users in three ways: (a) when planning a fill-up days ahead, prefer green zones where the price you see today will still be similar, (b) in red zones, use the existing price prediction feature more aggressively to time the fill-up, (c) for cross-border users, identify which country's border region has the most predictable pricing. No competitor offers this — Clever Tanken and ADAC show per-station history but never aggregate it into spatial intelligence. This is a Layer 1 feature that makes the existing price data dramatically more actionable.

### Detailed Implementation Concept

**Architecture:**

New presentation layer in `lib/features/map/` leveraging existing price history data. The volatility computation lives in a new domain service under `lib/features/price_history/domain/`. Map rendering uses the existing `flutter_map` integration with a new tile overlay.

**Key files to create:**

- `lib/features/price_history/domain/volatility_calculator.dart` — Pure-Dart domain service. For each station with ≥7 days of price history: computes standard deviation of daily prices, coefficient of variation (CV = stddev / mean), max daily swing (largest single-day price change), and intra-day range (difference between daily high and low where data supports it). Output: `StationVolatility` entity per station.

- `lib/features/price_history/domain/entities/station_volatility.dart` — Freezed entity: `stationId`, `fuelType`, `meanPrice`, `stdDev`, `coefficientOfVariation`, `maxDailySwing`, `avgIntraDayRange`, `volatilityTier` (enum: `stable`, `moderate`, `volatile` — thresholds: CV < 0.02 = stable, 0.02–0.05 = moderate, > 0.05 = volatile), `sampleDays` (number of days with data), `periodStart`, `periodEnd`.

- `lib/features/price_history/domain/volatility_grid.dart` — Aggregates per-station volatility into a spatial grid. Divides the visible map area into hexagonal cells (approximately 2 km radius each). Each cell's volatility is the weighted average of stations within it (weighted by inverse distance from cell centre). Output: `List<VolatilityCell>` with centre lat/lng, radius, and aggregate volatility tier + colour.

- `lib/features/price_history/domain/entities/volatility_cell.dart` — Freezed entity: `centerLat`, `centerLng`, `radiusKm`, `avgVolatilityCV`, `tier` (stable/moderate/volatile), `stationCount` (stations contributing), `color` (ARGB int derived from tier: green/yellow/red with alpha for overlay transparency).

- `lib/features/map/presentation/widgets/volatility_heatmap_layer.dart` — `flutter_map` polygon layer that renders `VolatilityCell` entries as semi-transparent filled hexagons. Uses the existing `flutter_map` `PolygonLayer` — each hexagon is a 6-vertex polygon computed from centre + radius. Colour intensity scales with confidence (more stations = more opaque). Layer visibility toggled by a new control button on the map toolbar alongside the existing EV overlay toggle from `ev_map_overlay.dart`.

- `lib/features/map/presentation/widgets/volatility_legend.dart` — Compact legend overlay (bottom-left of map): three coloured circles with labels — "Stable," "Moderate," "Volatile." Includes a small "i" icon that opens a tooltip explaining what volatility means for fill-up timing.

- `lib/features/map/presentation/widgets/volatility_info_sheet.dart` — Bottom sheet shown when tapping a volatility cell on the map. Shows: cell's average volatility metrics, list of stations within the cell ranked by stability, recommendation text ("Prices here change by ±€0.04/L daily — use the price prediction feature to time your fill-up" or "Prices here are very stable — fill up whenever convenient").

- `lib/features/map/providers/volatility_heatmap_provider.dart` — Riverpod provider that watches: visible map bounds (from existing map state provider), selected fuel type (from existing fuel type picker), and price history data. Debounces map movement (300 ms) to avoid recomputing on every pan. Computes `VolatilityGrid` and exposes `List<VolatilityCell>` for the layer widget.

**Integration points:**

- Reads price history from `lib/features/price_history/data/` via `PriceHistoryRepository` — 30-day history per station.
- Extends the existing map view in `lib/features/map/presentation/` — adds `VolatilityHeatmapLayer` as an optional overlay alongside the existing EV overlay.
- Reuses the fuel type selection from `lib/core/country/fuel_type_picker_provider.dart` — volatility computed per fuel type.
- Map toolbar extension — adds a volatility toggle button alongside existing controls in `lib/features/map/presentation/widgets/`.
- Links to existing price prediction from the info sheet — "See best time to fill" button navigates to the station's price history screen.
- Cross-border insights — when the heatmap spans a border, users can visually compare volatility regimes between countries.

**Privacy alignment:**

- Entirely computed from publicly available price data already stored on-device.
- No new API calls, network requests, or data collection.
- No user location data is used in the computation — only station coordinates and their price histories.
- Overlay is opt-in (toggled via map button, off by default to keep the map clean for new users).

---

## Feature 4: Trip Cost Sharing Calculator for Carpoolers

### Description

Carpooling is surging in 2026 — Scoop reported a 40% jump in rides from February to March 2026, driven by fuel price volatility and return-to-office mandates. The global carpooling market is projected to grow at 15%+ CAGR through 2030. When people share rides, they need to split fuel costs fairly, but doing so accurately requires knowing the actual fuel consumed (not just distance), the price per litre at the time of fill-up, and each passenger's share of the route. Tankstellen uniquely has all this data: real fuel consumption from OBD-II, actual fuel prices from the fill-up log, and GPS trip routes. No fuel price app offers an integrated cost-sharing feature — drivers currently use separate calculator apps (Splitwise, Tricount) or rough mental estimates. Building a carpooling cost splitter directly into Tankstellen's trip detail screen turns every recorded trip into a shareable cost receipt. This extends Layer 3 ("see what you spend") into the multi-passenger dimension and gives Tankstellen a viral sharing mechanic: recipients of cost-split messages see the Tankstellen-branded receipt and are introduced to the app.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/cost_split/` with clean architecture layers. Integrates into the existing trip detail view and fill-up log. Generates shareable cost receipts.

**Key files to create:**

- `lib/features/cost_split/domain/entities/cost_split.dart` — Freezed entity: `splitId` (UUID), `tripId` (references existing trip entity, optional — can also be a manual entry), `fillUpId` (optional, links to the fill-up that covered this trip), `totalFuelCost` (computed from litres × price, or entered manually), `totalDistanceKm`, `participants` (List of `SplitParticipant`), `splitMethod` (enum: `equal`, `byDistance`, `byPickupOrder`), `createdAt`, `currency`.

- `lib/features/cost_split/domain/entities/split_participant.dart` — Freezed entity: `name` (user-entered, e.g. "Anna", "Tom"), `boardingKm` (km into the trip where they joined — 0 for full trip), `alightingKm` (km where they left — totalKm for full trip), `shareAmount` (computed), `sharePercentage`.

- `lib/features/cost_split/domain/cost_split_calculator.dart` — Pure-Dart service. Implements three split methods:
  - `equal`: totalCost / participantCount.
  - `byDistance`: each participant pays proportional to their segment distance. If total trip is 50 km, driver does full 50 km, passenger A joins at km 10 and leaves at km 40 (30 km), passenger B does full 50 km: shares are weighted by individual km / sum of all individual km.
  - `byPickupOrder`: simplified version of byDistance where participants are added at waypoints and the cost of each segment is split among whoever is in the car for that segment. More intuitive for commute carpools with fixed pickup points.

- `lib/features/cost_split/domain/cost_split_receipt_generator.dart` — Generates a shareable receipt. Formats: (a) plain text (for messaging apps), (b) styled PNG image (for WhatsApp/Instagram sharing, using the existing `share_plus` + `RenderRepaintBoundary` pattern), (c) deep link back to the split in Tankstellen (for users who have the app). Receipt shows: trip date, route summary (start → end), total cost, breakdown per participant with amount, and a Tankstellen watermark/branding.

- `lib/features/cost_split/data/cost_split_repository.dart` — Hive-backed storage for split history. Users can review past splits and resend receipts. Implements `SyncableRepository` for optional TankSync cross-device sync.

- `lib/features/cost_split/presentation/screens/cost_split_screen.dart` — Main screen, accessible from: (a) trip detail screen "Split cost" action button, (b) fill-up detail "Split this fill-up" option, (c) standalone from navigation for manual cost entry. Flow: (1) auto-populate total cost from trip/fill-up data (or enter manually), (2) add participants by name, (3) optionally set boarding/alighting points on a route map (if trip has GPS data), (4) select split method, (5) see computed shares, (6) share receipt.

- `lib/features/cost_split/presentation/widgets/participant_editor.dart` — List widget for adding/removing participants. Each row: name text field, optional distance slider (for byDistance method), computed share amount. "Add participant" button at bottom. Minimum 2 participants (driver + 1 passenger).

- `lib/features/cost_split/presentation/widgets/split_receipt_card.dart` — Styled card that serves as both the on-screen preview and the shareable image. Clean design with: Tankstellen logo, trip date, route, per-person breakdown, total. Uses existing theme colours from `lib/app/theme.dart`.

- `lib/features/cost_split/presentation/widgets/route_participant_overlay.dart` — When a trip has GPS data, shows the route on a mini flutter_map with coloured segments indicating which participants were aboard for each section. Boarding/alighting points shown as markers. Visual confirmation of the distance-based split.

- `lib/features/cost_split/providers/cost_split_provider.dart` — Riverpod provider composing: `CostSplitCalculator`, `CostSplitRepository`, and optionally trip/fill-up data from consumption providers. Manages the creation flow state.

**Integration points:**

- Trip detail screen (`lib/features/consumption/presentation/`) — adds a "Split Cost" action button to the app bar or as a floating action.
- Fill-up detail — adds a "Split" option to the fill-up entry's action menu.
- Uses trip GPS data from `lib/features/consumption/` for route visualisation and distance-based splitting.
- Uses fill-up price data from `lib/features/consumption/domain/entities/fill_up.dart` for accurate cost calculation.
- Uses `share_plus` (already in pubspec.yaml) for sharing receipts via messaging apps.
- Uses `flutter_map` (already in pubspec.yaml) for route participant overlay.
- Syncs via TankSync (optional) — split history available across devices.
- Receipts include a Tankstellen-branded watermark — organic app discovery for recipients.

**Privacy alignment:**

- Participant names are entered by the user and stored locally only — no accounts or contact access required.
- GPS route data in shared receipts is optional and can be excluded (receipt shows only start/end, not full trace).
- Shared receipts contain only cost and name data — no vehicle details, OBD-II data, or personal information.
- Split history stored in Hive; syncs only if TankSync is enabled.
- No payment processing — the app calculates amounts but doesn't handle money transfers (avoids financial regulation complexity).

---

## Feature 5: Carbon Offset Marketplace Integration

### Description

Tankstellen's CO2 dashboard (`lib/features/carbon/`) already tracks per-vehicle emissions with 30-day rolling charts, speed-consumption correlation, and trip length breakdowns. But the dashboard is purely informational — it tells users what they emit but offers no path to act on it beyond driving better. In 2026, carbon offset apps are mainstreaming: Klima, Capture, Aerial, and others let individuals purchase verified carbon credits (nature-based credits average $7–24/tCO2e, tech-based CDR credits $170–500). Tankstellen has a unique advantage: it knows the user's actual, measured emissions from OBD-II data and fill-up logs — far more accurate than the rough estimates other offset apps use. By integrating with carbon offset marketplaces, Tankstellen can offer a "neutralise your driving" feature: at the end of each month, see your exact emissions, and with one tap, purchase the precise amount of verified offsets. This extends the CO2 dashboard from passive awareness to active climate action, appealing to the growing segment of eco-conscious drivers who want to reduce and offset what they can't eliminate. No fuel price app currently offers integrated carbon offsetting.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/carbon_offset/` that extends the existing `lib/features/carbon/` dashboard. Integrates with one or more carbon offset APIs (starting with Cloverly or Patch, both of which offer REST APIs with per-transaction offset purchasing). The app acts as a facilitator — it calculates the offset amount and opens a web-based purchase flow, never handling payment directly.

**Key files to create:**

- `lib/features/carbon_offset/domain/entities/offset_quote.dart` — Freezed entity: `quoteId`, `co2Kg` (amount to offset), `providerName` (e.g. "Cloverly", "Patch"), `projectName` (e.g. "Brazilian Reforestation"), `projectType` (enum: `reforestation`, `renewableEnergy`, `methaneCapture`, `directAirCapture`, `oceanAlkalinity`), `pricePerTonne`, `totalPrice`, `currency`, `certificationStandard` (e.g. "Gold Standard", "Verra VCS"), `estimatedRetirementDate`, `expiresAt` (quote validity window).

- `lib/features/carbon_offset/domain/entities/offset_purchase.dart` — Freezed entity: `purchaseId`, `quoteId`, `co2Kg`, `totalPaid`, `currency`, `purchasedAt`, `certificateUrl` (link to the digital offset certificate), `providerTransactionId`, `vehicleId`, `period` (month/year the emissions cover).

- `lib/features/carbon_offset/domain/entities/offset_history.dart` — Freezed entity: `totalOffsetKg` (all-time), `totalSpent`, `monthlyEntries` (List of per-month summaries: emitted, offset, net), `currentStreak` (consecutive months fully offset), `percentageOffset` (what fraction of total emissions has been offset).

- `lib/features/carbon_offset/domain/offset_calculator.dart` — Pure-Dart service. Takes: monthly CO2 emissions from `lib/features/carbon/domain/monthly_summary.dart`. Computes: exact kg of CO2 to offset for the selected period. Applies any credit from driving efficiency improvements (if user reduced emissions by 5% through better driving, only the remaining 95% needs offsetting — the efficiency gain is its own offset). Output: `OffsetRequirement` with `co2Kg`, `adjustedCo2Kg` (after efficiency credit), `efficiencyCredit`.

- `lib/features/carbon_offset/data/offset_provider_service.dart` — Abstract interface: `Future<List<OffsetQuote>> getQuotes(double co2Kg, String currency)`. Allows multiple provider implementations.

- `lib/features/carbon_offset/data/cloverly_offset_service.dart` — Implementation for Cloverly API (REST, JSON). Fetches available offset projects and pricing for the given CO2 amount. No payment processing in-app — returns a purchase URL that opens in the system browser for the user to complete the transaction. After completion, the user confirms in-app and enters the transaction ID (or the app detects the redirect if using a deep link callback).

- `lib/features/carbon_offset/data/offset_repository.dart` — Hive-backed storage for offset purchase history and provider API keys (stored securely using the existing Android Keystore pattern from `lib/features/setup/`).

- `lib/features/carbon_offset/presentation/screens/carbon_offset_screen.dart` — Main screen, accessible from the existing CO2 dashboard via a "Offset your emissions" CTA button. Shows: (1) monthly emissions summary (reuses existing `monthly_bar_chart.dart`), (2) "Your driving footprint this month: X kg CO2" hero card, (3) efficiency credit callout ("Your improved driving saved Y kg — only Z kg needs offsetting"), (4) available offset projects as cards (project name, type icon, price, certification badge), (5) "Offset now" button per project that opens the purchase flow.

- `lib/features/carbon_offset/presentation/screens/offset_history_screen.dart` — Timeline view of past offset purchases. Shows: monthly emitted vs. offset bar chart, all-time total offset badge, certificates list (tappable to open certificate URLs), streak counter ("You've been carbon-neutral for 4 months").

- `lib/features/carbon_offset/presentation/widgets/offset_project_card.dart` — Card widget for each available offset project: project photo placeholder (or icon for project type), name, location, certification standard badge, price per tonne, total price for the user's emissions, "Select" button.

- `lib/features/carbon_offset/presentation/widgets/emissions_vs_offset_chart.dart` — Stacked bar chart showing monthly emissions (red) and offsets (green) side by side. Months where offsets ≥ emissions get a "neutral" badge. Uses the existing chart styling from the carbon dashboard.

- `lib/features/carbon_offset/presentation/widgets/efficiency_credit_explainer.dart` — Small explainer card: "By improving your driving score from 62 to 71 this month, you avoided X kg of CO2. This means you only need to offset Y kg instead of Z kg — your efficiency is its own offset." Encourages continued driving improvement.

- `lib/features/carbon_offset/providers/carbon_offset_provider.dart` — Riverpod provider composing: `OffsetCalculator`, `OffsetProviderService`, `OffsetRepository`, and carbon emission data from existing providers. Manages quote fetching, purchase flow state, and history.

**Integration points:**

- Extends `lib/features/carbon/presentation/screens/carbon_dashboard_screen.dart` — adds an "Offset" tab or CTA button linking to the offset screen.
- Reads monthly CO2 data from `lib/features/carbon/domain/monthly_summary.dart`.
- Reads driving score improvements from `lib/features/consumption/domain/driving_score.dart` for efficiency credit calculation.
- Reads vehicle profile from `lib/features/vehicle/` for emissions factor per fuel type.
- Uses `url_launcher` (already in pubspec.yaml) to open offset purchase URLs in the system browser.
- Offset purchase history syncs via TankSync (optional) — offset achievements visible across devices.
- Achievement integration: new achievement badges in `lib/features/achievements/` — "First Offset", "Carbon Neutral Month", "6-Month Streak", "1 Tonne Offset".
- Home-screen widget (`lib/features/widget/`) — could show "This month: X kg emitted, Y kg offset" alongside price data.

**Privacy alignment:**

- Offset API calls contain only the CO2 amount to offset and currency — no personal data, no vehicle data, no location.
- Payment happens entirely in the external provider's website/app — Tankstellen never handles payment data.
- Offset purchase history stored locally; syncs only via TankSync if enabled.
- Provider API keys stored in Android Keystore (existing secure storage pattern).
- Users opt-in to offset features — no nagging or guilt-tripping in the CO2 dashboard. The CTA is informational: "Want to offset?" not "You should offset."
- No commission or referral fees from offset providers — the feature exists purely to add user value.

---

## Summary & Prioritisation

| # | Feature | Layer | Effort | Impact | Priority |
|---|---------|-------|--------|--------|----------|
| 1 | Weather-Aware Fuel Efficiency Advisor | L2 | Medium | High | **P0** |
| 2 | Insurance Telematics Data Export & UBI Portal | L2/L3 | Medium | Very High | **P0** |
| 3 | Fuel Price Volatility Heatmap | L1 | Low | Medium | **P1** |
| 4 | Trip Cost Sharing Calculator | L3 | Medium | High | **P1** |
| 5 | Carbon Offset Marketplace Integration | L3 | High | Medium | **P2** |

**Rationale:**

- **Insurance Telematics Export (P0):** This is potentially the highest-value feature proposed to date. Insurance premium savings of 10–25% dwarf fuel price savings for most drivers — a driver spending €1,800/year on insurance could save €180–450, compared to perhaps €50–100/year from better fuel timing. Tankstellen already collects all the required data; the feature is primarily a reporting and export layer. The UBI market is projected to grow 3.5x by 2031, meaning this feature becomes more valuable every year. It also creates a powerful retention loop: users need months of driving data to generate a credible report, incentivising daily use.

- **Weather-Aware Efficiency Advisor (P0):** Medium implementation effort (Open-Meteo is free, no-key, and covers all 11 countries), high impact on the OBD-II user segment. Weather is the largest uncontrolled variable in fuel consumption — accounting for it makes the driving score fairer, the consumption trend more actionable, and the route search smarter. It's the kind of feature that makes users think "this app actually understands my car," deepening engagement.

- **Fuel Price Volatility Heatmap (P1):** Lowest implementation effort of today's batch (entirely computed from existing data, no new APIs), medium impact. It transforms the existing price history from per-station data into spatial intelligence. Particularly valuable for cross-border users near volatile pricing zones. The visual impact on the map screen creates a "wow" moment that aids word-of-mouth.

- **Trip Cost Sharing Calculator (P1):** Medium effort, high topical relevance given the 2026 carpooling surge. The viral sharing mechanic (branded receipts shared via WhatsApp) is a rare organic growth channel for a privacy-first app that doesn't do traditional marketing. Cost-splitting turns Tankstellen from a solo-driver tool into a social utility.

- **Carbon Offset Marketplace (P2):** Highest effort (external API integration, purchase flow complexity, provider selection), medium impact (smaller target audience of eco-conscious drivers). But strategically important: it completes the CO2 dashboard's story from awareness to action, and positions Tankstellen in the growing sustainability-tech space. Deliberately designed to never handle payments directly, keeping the implementation clean and the regulatory burden zero.

---

*Generated 2026-05-04. Market signals sourced from: Tank-Pilot 2026 comparison, Sia Partners energy station loyalty study, Damoov daily carbon score, DQ Connected Insurance Guide 2026, High-Mobility OBD telematics analysis, Scoop carpooling growth data, Capterra fuel management software rankings, Open-Meteo weather API documentation.*
