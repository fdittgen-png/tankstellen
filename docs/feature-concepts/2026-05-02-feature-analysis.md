<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Daily Feature Analysis — 2026-05-02

## Market Context

The fuel app landscape in May 2026 shows accelerating convergence between traditional fuel-price apps and in-car AI assistants. The in-vehicle AI assistant market hit $3.46B in 2026 (+25.7% CAGR), with Ford, BMW, and others shipping conversational voice assistants directly in 2026 model-year vehicles. Meanwhile, fuel apps are racing to integrate: Fuelio dominates Android Auto, FuelUp ships CarPlay + Apple Watch complications, and GasBuddy still lacks in-car integration — a gap its users increasingly resent. On the EV front, Plug & Charge (ISO 15118) is going mainstream, Google/Apple Maps natively integrate charging payments, and V2G/V2H features appear in premium EV apps like ChargeHQ. AI-powered price prediction (FuelCast's "Cheap Fuel Near Me" app) is setting new user expectations for proactive refuel timing.

**Tankstellen's current positioning:** Strong multi-country price comparison (11 countries), OBD-II driving insights, EV charging via OpenChargeMap, achievements/gamification, loyalty card support, privacy-first philosophy, home-screen widget with predictive variant, existing price prediction engine (`best_time_banner`, `price_prediction_provider`), route search, consumption tracking.

**Yesterday's features proposed:** CarPlay/Android Auto, Crowdsourced Price OCR, Smart Refuel Timing, Community Leaderboard, Wearable Companion.

**Today's focus:** New gaps identified from the latest market signals — voice-first in-car AI interaction, hybrid/EV energy cost optimization, social carpooling cost-split, station availability/queue intelligence, and multi-modal journey cost comparison.

---

## Feature 1: Voice-First In-Car AI Copilot

### Description

A conversational voice interface that lets drivers interact with all core Tankstellen features hands-free while driving. Goes beyond simple CarPlay template screens (proposed yesterday) by adding natural-language queries like "Where's the cheapest E10 on my way home?", "Should I fill up now or wait?", and "How's my fuel consumption this trip compared to last week?". Leverages the $3.46B in-vehicle AI assistant trend — positions Tankstellen as the first open-source fuel app with an on-device voice copilot.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/voice_copilot/` following clean architecture. Uses the already-imported `flutter_tts` package (in pubspec.yaml) for speech output, plus adds `speech_to_text` for voice input.

**Key files to create:**

- `lib/features/voice_copilot/domain/intent_parser.dart` — Lightweight on-device intent classification. Maps spoken utterances to action intents: `FindCheapest`, `ShouldFillNow`, `TripSummary`, `SetAlert`, `NavigateToStation`. Uses keyword matching + pattern grammar (no cloud AI needed — privacy-first).
- `lib/features/voice_copilot/domain/entities/voice_intent.dart` — Freezed sealed class with variants per intent type, each carrying parsed parameters (fuel type, location reference, time frame).
- `lib/features/voice_copilot/domain/response_composer.dart` — Generates natural-language response strings from provider data. E.g., queries `PricePredictionProvider` and composes: "E10 is at €1.43 at Aral Hauptstraße, 800 meters away. Prices are predicted to drop 2 cents in 3 hours — you might want to wait."
- `lib/features/voice_copilot/data/speech_recognition_service.dart` — Wraps `speech_to_text` package with noise-cancellation hints and automotive-optimized recognition parameters. Implements continuous-listening mode with wake-word detection ("Hey Tank" or customizable).
- `lib/features/voice_copilot/data/tts_service.dart` — Wraps existing `flutter_tts` dependency. Provides queued utterance playback with priority (alerts interrupt trip summaries). Respects system volume and driving-mode context.
- `lib/features/voice_copilot/presentation/voice_copilot_overlay.dart` — Minimal floating overlay (small microphone FAB) shown during driving mode. Expands to show transcription + response text briefly, then auto-collapses. Integrates with existing driving mode screen (`lib/features/driving/presentation/`).
- `lib/features/voice_copilot/providers/voice_copilot_provider.dart` — Riverpod provider orchestrating the flow: listen → parse intent → query relevant providers → compose response → speak.

**Integration points:**

- Hooks into existing `lib/features/driving/presentation/` driving mode — adds voice FAB overlay.
- Queries `lib/features/search/providers/` for station data.
- Queries `lib/features/price_history/providers/price_prediction_provider.dart` for fill-now-or-wait logic.
- Queries `lib/features/consumption/providers/` for trip statistics.
- Uses existing `lib/core/location/location_service.dart` for position context.
- Reuses `flutter_tts` (already in pubspec.yaml); adds `speech_to_text: ^7.0.0` to pubspec.yaml.

**Privacy alignment:**

- All speech processing on-device (no cloud transcription).
- Intent parsing is rule-based, not LLM-dependent.
- No audio recordings stored — stream-processed and discarded.
- Aligns with existing GDPR consent flow in `lib/features/consent/`.

---

## Feature 2: Hybrid & EV Energy Cost Optimizer

### Description

For the growing hybrid and EV user segment, a unified "cost per km" optimizer that compares: (a) charging at home overnight vs. public charger en-route, (b) running on electric vs. switching to combustion (for PHEVs), (c) time-of-use electricity tariffs vs. current fuel price. Competitors like ChargeHQ optimize home charging against solar production; no fuel app yet unifies fossil + electric cost comparison for PHEVs in a single view. This extends Tankstellen's existing EV module (`lib/features/ev/`) and consumption tracking into true hybrid cost optimization.

### Detailed Implementation Concept

**Architecture:**

Extend `lib/features/ev/` with a new sub-module for cost optimization, connecting to the existing `lib/features/consumption/` and `lib/features/calculator/` features.

**Key files to create:**

- `lib/features/ev/domain/entities/energy_tariff.dart` — Freezed entity: `tariffName`, `pricePerKwh`, `validFrom`/`validTo` (time-of-use windows), `isGreenEnergy` (for carbon dashboard integration).
- `lib/features/ev/domain/energy_cost_optimizer.dart` — Pure domain logic that computes optimal energy mix: takes as input current fuel price (from `RefuelPrice`), electricity tariff (user-configured), battery SOC (from OBD-II via `lib/core/car/car_data_bridge.dart`), remaining range electric/combustion, and planned trip distance. Outputs recommendation: "Charge tonight (€0.04/km) vs. fuel now (€0.09/km) — save €3.75 on your commute."
- `lib/features/ev/data/tariff_repository.dart` — Stores user-configured electricity tariffs in Hive. Supports multiple tariffs (home day/night, workplace, public charger categories).
- `lib/features/ev/presentation/screens/energy_optimizer_screen.dart` — Dashboard showing: daily cost comparison chart (electric vs. fossil), recommended charging windows, monthly savings projection, and one-tap "set charging reminder" that schedules a notification during cheapest tariff window.
- `lib/features/ev/presentation/widgets/phev_mode_advisor_card.dart` — Widget for PHEV vehicles showing real-time recommendation: "Switch to EV mode — next 12 km are urban, saving €0.82." Shown on driving mode screen when vehicle type is hybrid.
- `lib/features/ev/providers/energy_optimizer_provider.dart` — Riverpod provider composing: vehicle profile (from `lib/features/vehicle/`), current fuel prices (from search providers), configured tariffs, and OBD battery SOC if available.

**Integration points:**

- Extends existing `lib/features/vehicle/` profiles — adds fields for battery capacity, typical home charging speed, and electricity tariff reference.
- Connects to `lib/features/ev/domain/charging_cost_calculator.dart` (already exists) for public charger cost computation.
- Integrates with `lib/features/carbon/` for emissions comparison between electric and fossil km.
- Uses `lib/core/car/car_data_bridge.dart` for real-time battery SOC from OBD-II (hybrid vehicles report this via PID 0x5B).
- Notification scheduling via existing `lib/core/notifications/notification_service.dart`.

**Differentiation:**

- Only app combining fuel prices + electricity tariffs + OBD-II data in one optimizer.
- Privacy-first: tariff data stays on-device, no smart-meter integration required.
- Works without OBD-II too (manual SOC input or estimate from last charge log).

---

## Feature 3: Station Queue & Availability Intelligence

### Description

FuelCast and Waze both hint at "busy times" for fuel stations, but no app provides real-time queue intelligence combining: historical visit patterns, current crowd density estimation (via anonymous ping aggregation from users near the station), and pump availability status from station APIs where available. This feature helps users avoid the 5-minute queue at peak hours — directly serving Layer 1 (time is cost) and differentiating against all competitors.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/station_availability/` with both local heuristic (no backend) and optional crowd-sourced mode (via Supabase).

**Key files to create:**

- `lib/features/station_availability/domain/entities/station_busyness.dart` — Freezed entity: `stationId`, `hourOfWeek` (0–167), `busynessScore` (0.0–1.0), `averageWaitMinutes`, `confidence` (how many data points).
- `lib/features/station_availability/domain/busyness_predictor.dart` — On-device prediction engine using historical fill-up timestamps (from existing consumption log in `lib/features/consumption/`). Aggregates the user's own visit patterns + crowd data (if opted in) to predict busyness by hour-of-week per station.
- `lib/features/station_availability/data/crowd_signal_service.dart` — Lightweight anonymous ping: when a user is within 50m of a station for >2 minutes, send an anonymous `{stationId, timestamp}` event to Supabase (no user ID, no device ID — just station + time). Aggregation happens server-side via Supabase function.
- `lib/features/station_availability/data/repositories/busyness_repository.dart` — Fetches aggregated busyness data from Supabase view `station_busyness_hourly`. Falls back to local-only prediction when offline or when user hasn't opted into crowd signals.
- `lib/features/station_availability/presentation/widgets/busyness_indicator.dart` — Small chip/bar shown on station detail screen (`lib/features/station_detail/`) and search results. Color-coded: green (quiet), amber (moderate), red (busy). Shows "Usually quiet at this time" or "Peak hour — expect 5 min wait."
- `lib/features/station_availability/presentation/widgets/best_visit_time_chart.dart` — Hourly bar chart (similar pattern to `lib/features/price_history/presentation/widgets/hourly_price_chart.dart`) showing predicted busyness across the day for a selected station.
- `lib/features/station_availability/providers/busyness_provider.dart` — Riverpod provider combining local predictions + crowd data, respecting the privacy opt-in toggle.

**Integration points:**

- Adds busyness indicator to `lib/features/station_detail/presentation/` screens.
- Adds "quiet now" badge to search result cards in `lib/features/search/presentation/`.
- Route search (`lib/features/route_search/`) can weight stations by both price AND predicted wait time — "cheapest quiet stop" strategy.
- Privacy: opt-in via existing consent flow (`lib/features/consent/`). Signal is fully anonymous — no user correlation possible.
- Uses existing `lib/core/location/location_service.dart` for geofence proximity detection.

---

## Feature 4: Multi-Modal Journey Cost Comparator

### Description

With rising fuel costs, more drivers consider alternatives for specific trips: train, e-scooter, carpool, or park-and-ride. No fuel app currently offers a "should I even drive?" comparison. This feature shows the total cost of a planned journey across modes (own car fuel + tolls + parking vs. public transit ticket vs. ride-share estimate), helping users make the cheapest choice per trip. Serves Tankstellen's core mission ("reduce what your car costs per km") by showing when *not* driving is the cheapest km.

### Detailed Implementation Concept

**Architecture:**

New feature module `lib/features/journey_compare/` integrating with existing route search and calculator.

**Key files to create:**

- `lib/features/journey_compare/domain/entities/journey_option.dart` — Freezed sealed class with variants: `DrivingOption` (fuel cost, toll, parking, time), `TransitOption` (ticket price, transfers, time), `RideShareOption` (estimated fare, time), `BikeOption` (time, calories — free cost).
- `lib/features/journey_compare/domain/journey_cost_calculator.dart` — Computes driving cost using: distance × (consumption from vehicle profile) × current fuel price + configurable per-km wear cost (insurance, depreciation — user-set). Extends existing `lib/features/calculator/` logic.
- `lib/features/journey_compare/data/transit_fare_service.dart` — Queries open transit APIs (EU: Deutsche Bahn, SNCF, Navitia, Rejseplanen per country) for fare estimates between origin/destination. Returns price + duration.
- `lib/features/journey_compare/data/ride_share_estimator.dart` — Simple fare model (base + per-km rate, configurable per city/country) without calling proprietary Uber/Bolt APIs — provides estimate range.
- `lib/features/journey_compare/presentation/screens/journey_compare_screen.dart` — Side-by-side cards showing cost, time, and CO₂ for each mode. Highlights cheapest and fastest. "Drive" card links to existing route search; "Transit" links to external transit app via `url_launcher`.
- `lib/features/journey_compare/presentation/widgets/mode_comparison_card.dart` — Individual card with icon, cost, duration, CO₂ badge. Tap expands to show cost breakdown.
- `lib/features/journey_compare/providers/journey_compare_provider.dart` — Orchestrates parallel cost calculations across modes. Uses `AsyncValue` pattern consistent with other providers.

**Integration points:**

- Accessible from route search (`lib/features/route_search/`) — "Compare alternatives" button below route results.
- Driving cost uses vehicle consumption data from `lib/features/vehicle/` and current prices from `lib/features/search/providers/`.
- CO₂ comparison extends `lib/features/carbon/` dashboard data.
- Reuses existing `url_launcher` dependency for deep-linking to transit/ride-share apps.
- Per-km wear cost configurable in vehicle profile (`lib/features/vehicle/`).

**Differentiation:**

- No fuel app offers this — positions Tankstellen as "mobility cost optimizer" rather than just "fuel price finder."
- Privacy-first: transit fare queries use no user data beyond origin/destination coordinates.
- Honest recommendation even when it means "don't drive" — builds trust.

---

## Feature 5: AI-Powered Maintenance Cost Predictor

### Description

The app already has a maintenance analyzer watching consumption drift (`lib/features/driving/`), but competitors are moving toward predictive maintenance *cost* estimation. BMW's AI assistant predicts maintenance needs; no independent app combines OBD-II diagnostic data + historical service costs to predict "your next €500 bill is likely in 3 months." This extends Layer 3 ("see what you're really spending") into the future — from tracking past costs to forecasting future ones.

### Detailed Implementation Concept

**Architecture:**

Extend existing maintenance/consumption infrastructure with a predictive cost layer at `lib/features/maintenance_forecast/`.

**Key files to create:**

- `lib/features/maintenance_forecast/domain/entities/maintenance_prediction.dart` — Freezed entity: `serviceType` (oil change, brake pads, timing belt, etc.), `predictedDate`, `predictedMileage`, `estimatedCostRange` (min/max in user's currency), `confidence`, `triggerReason` (mileage interval, consumption drift, OBD-II DTC code, time since last).
- `lib/features/maintenance_forecast/domain/maintenance_predictor.dart` — Core prediction engine. Inputs: vehicle profile (make/model/year from `lib/features/vehicle/`), current mileage, mileage accumulation rate (from trip history), last service dates (from existing service reminders), OBD-II diagnostic codes if available, consumption trend (from `lib/features/consumption/`). Outputs: sorted list of upcoming maintenance items with cost estimates.
- `lib/features/maintenance_forecast/data/service_cost_database.dart` — On-device reference database of average maintenance costs by vehicle segment (compact, SUV, premium) and country. Loaded from `assets/maintenance_costs/` JSON files. User can override with actual costs from their service history.
- `lib/features/maintenance_forecast/data/obd_diagnostic_interpreter.dart` — Maps OBD-II DTC (Diagnostic Trouble Codes) read via `lib/core/car/car_data_bridge.dart` to maintenance categories and urgency levels. E.g., P0171 (system too lean) → "Check MAF sensor — estimated €150–250."
- `lib/features/maintenance_forecast/presentation/screens/maintenance_forecast_screen.dart` — Timeline view showing predicted maintenance events on a scrollable calendar strip. Each item shows: service name, predicted date/mileage, cost range, and "I did this" button to log completion.
- `lib/features/maintenance_forecast/presentation/widgets/upcoming_cost_card.dart` — Summary card for profile/dashboard: "Next 6 months: estimated €780 in maintenance." Links to full forecast.
- `lib/features/maintenance_forecast/presentation/widgets/cost_projection_chart.dart` — 12-month rolling bar chart of predicted maintenance spending, similar in style to existing price charts in `lib/features/price_history/presentation/widgets/`.
- `lib/features/maintenance_forecast/providers/maintenance_forecast_provider.dart` — Riverpod provider composing vehicle data, trip history, service records, and OBD-II state into predictions.

**Integration points:**

- Extends vehicle profile screen (`lib/features/vehicle/`) with "Maintenance Forecast" card.
- Reads OBD-II diagnostic codes from `lib/core/car/car_data_bridge.dart` when adapter is connected.
- Connects to existing service reminders (already in vehicle profiles) for "last serviced" dates.
- Uses consumption trend data from `lib/features/consumption/providers/` to detect degradation patterns.
- Push notifications via existing `lib/core/notifications/notification_service.dart` for upcoming high-cost items.
- Feeds into existing cost calculator (`lib/features/calculator/`) for total-cost-of-ownership view.

**Data sources for cost estimates:**

- Bundled JSON asset with average costs per service type × vehicle segment × country.
- User's own logged costs (learning from their history).
- Community median (optional, via Supabase aggregation if user opts into anonymous cost sharing).

---

## Summary & Priority Recommendation

| # | Feature | Effort | Market Impact | Differentiation |
|---|---------|--------|---------------|-----------------|
| 1 | Voice-First AI Copilot | Medium | Very High | First open-source fuel app with voice | 
| 2 | Hybrid/EV Energy Optimizer | Medium | High | Unique PHEV cost unification |
| 3 | Station Queue Intelligence | Medium | High | No competitor offers this |
| 4 | Multi-Modal Journey Comparator | High | Very High | Repositions app as mobility optimizer |
| 5 | AI Maintenance Cost Predictor | Medium | Medium-High | Extends OBD-II into financial planning |

**Recommended next sprint:** Feature 3 (Station Queue Intelligence) — medium effort, leverages existing location + Supabase infrastructure, immediately visible on search results, and no competitor currently offers this. Follow with Feature 1 (Voice Copilot) which leverages the already-imported `flutter_tts` and creates a strong viral demo moment.

**Relationship to yesterday's features:** Today's list is complementary, not overlapping. Yesterday's CarPlay/Android Auto (Feature 1) is the *visual* in-car layer; today's Voice Copilot is the *conversational* layer — both can coexist. Yesterday's Smart Refuel Timing is a prerequisite input for today's Voice Copilot's "should I fill now?" query. Yesterday's Crowdsourced Price OCR feeds today's Queue Intelligence with presence signals.

---

*Generated: 2026-05-02 | Based on market analysis of in-car AI assistants (Ford, BMW, Cerence), ChargeHQ, FuelCast/Cheap Fuel Near Me, Fuelio (Android Auto), FuelUp (CarPlay + Watch), GasBuddy, clever-tanken, and EV charging market trends (Driivz, ChargePoint, EVgo).*
