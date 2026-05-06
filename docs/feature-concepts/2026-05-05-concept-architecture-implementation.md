# Daily Feature Concept — 2026-05-05

## Detailed Architecture & Implementation Document

### Executive Summary

This document consolidates the 20 features proposed across the May 1–4 daily analyses into five implementation-ready concept architectures. Each concept is selected for its synergy with Tankstellen's existing codebase, its reuse of proven patterns, and its incremental complexity profile. The concepts are ordered by implementation priority and include exact file paths, class interfaces, provider wiring, persistence schemas, integration points, test strategies, and migration paths.

**Selected concepts for deep-dive:**

| # | Concept | Source | Effort | Rationale |
|---|---------|--------|--------|-----------|
| 1 | Smart Refuel Timing Advisor | May 1 #3 | Low | Extends existing prediction + alerts with minimal new code |
| 2 | Fuel Price Volatility Heatmap | May 4 #3 | Low | Entirely computed from existing 30-day price history, no APIs |
| 3 | Weather-Aware Fuel Efficiency Advisor | May 4 #1 | Medium | Open-Meteo is free/keyless, normalises driving score fairly |
| 4 | Insurance Telematics Data Export | May 4 #2 | Medium | Highest user-value feature; reporting layer over existing data |
| 5 | Trip Cost Sharing Calculator | May 4 #4 | Medium | Viral sharing mechanic, leverages existing trip/fill-up data |

---

## Concept 1: Smart Refuel Timing Advisor

### 1.1 Problem Statement

Tankstellen's `PricePredictionProvider` already analyses 30-day price history to identify the cheapest hour-of-day and day-of-week per station. The `best_time_banner` surfaces this passively on the station detail screen. But users must actively open the app and check — no proactive notification tells them "fill up now, prices are about to rise." Meanwhile, the consumption system tracks tank level through fill-up logs (`FillUp.isFullTank` plein-to-plein windows in `ConsumptionStats`). Connecting these two systems creates a personalised "fill up now" advisor that fires when the user's estimated fuel level is low AND prices are near a predicted trough.

### 1.2 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Background Service Pipeline                   │
│  (lib/core/background/background_service.dart)                   │
│                                                                   │
│  Step 1: _refreshPricesAndCheckAlerts()           [EXISTING]     │
│  Step 2: Per-station threshold alerts              [EXISTING]     │
│  Step 3: Velocity alert detection                  [EXISTING]     │
│  Step 4: Radius alert evaluation                   [EXISTING]     │
│  Step 5: ► Refuel timing evaluation ◄              [NEW]         │
│           │                                                       │
│           ├── TankLevelEstimator                                  │
│           │   └── reads: FillUp history + ConsumptionStats        │
│           │   └── reads: VehicleProfile.tankCapacityL             │
│           │   └── reads: trip odometer deltas since last fill     │
│           │                                                       │
│           ├── PricePredictionProvider (reused, isolate-safe)      │
│           │   └── reads: PriceHistoryRepository (30-day)          │
│           │                                                       │
│           └── RefuelTimingEvaluator                               │
│               └── combines tank level + price prediction          │
│               └── fires notification via LocalNotificationService │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Domain Entities

#### `lib/features/alerts/domain/entities/refuel_timing_config.dart`

```dart
@freezed
class RefuelTimingConfig with _$RefuelTimingConfig {
  const factory RefuelTimingConfig({
    /// Tank percentage below which the advisor activates. Default 25%.
    @Default(25) int tankThresholdPercent,

    /// Minimum predicted price drop (cents) to recommend waiting.
    /// If predicted drop < this, recommend filling now. Default 2 cents.
    @Default(0.02) double minPriceDrop,

    /// Maximum hours to look ahead for a price trough. Default 24h.
    @Default(24) int forecastHoursAhead,

    /// Stations to monitor — null = favorites + nearest. Default null.
    List<String>? monitoredStationIds,

    /// Cooldown between notifications. Default 6 hours.
    @Default(6) int cooldownHours,

    /// Whether the feature is enabled. Default false (opt-in).
    @Default(false) bool enabled,
  }) = _RefuelTimingConfig;

  factory RefuelTimingConfig.fromJson(Map<String, dynamic> json) =>
      _$RefuelTimingConfigFromJson(json);
}
```

#### `lib/features/alerts/domain/entities/refuel_timing_result.dart`

```dart
@freezed
class RefuelTimingResult with _$RefuelTimingResult {
  const factory RefuelTimingResult({
    required RefuelTimingAction action,
    required String stationId,
    required String stationName,
    required double currentPrice,
    required FuelType fuelType,
    double? predictedTroughPrice,
    DateTime? predictedTroughTime,
    double? estimatedSaving,
    required double estimatedTankPercent,
    required double confidenceScore,
  }) = _RefuelTimingResult;
}

enum RefuelTimingAction {
  fillNow,    // Price is near trough or predicted to rise
  waitFor,    // Predicted drop exceeds minPriceDrop threshold
}
```

### 1.4 Domain Services

#### `lib/features/alerts/domain/tank_level_estimator.dart`

Estimates current tank level from fill-up history and distance driven since last fill.

**Inputs:**
- `List<FillUp>` — fill-up history, sorted newest-first
- `ConsumptionStats` — provides `avgConsumptionL100km` from plein-to-plein windows
- `VehicleProfile` — provides `tankCapacityL`
- `double? odometerKm` — current odometer from OBD-II (if connected), else estimated from trips

**Algorithm:**
1. Find last `isFullTank == true` fill-up → `lastFullFillDate`, `lastFullFillOdometer`
2. Sum litres of all partial fills since that plein: `partialLitresSinceFullTank`
3. Estimate distance since last full: `distanceSinceFullTank = currentOdometer - lastFullFillOdometer`
   - If no odometer: estimate from daily average km (from trip history / calendar days)
4. Compute fuel consumed: `consumedL = distanceSinceFullTank * avgConsumptionL100km / 100`
5. Compute current litres: `currentLitres = tankCapacityL + partialLitresSinceFullTank - consumedL`
6. Clamp to `[0, tankCapacityL]`
7. Return `tankPercent = (currentLitres / tankCapacityL * 100).round()`

**Confidence:**
- High if `avgConsumptionL100km` based on ≥3 plein windows AND odometer from OBD-II
- Medium if consumption from ≥1 plein window AND odometer estimated from trips
- Low if no plein windows (uses vehicle default consumption)

```dart
class TankLevelEstimator {
  TankLevelEstimate estimate({
    required List<FillUp> fillUps,
    required ConsumptionStats stats,
    required VehicleProfile vehicle,
    double? currentOdometerKm,
  });
}

@freezed
class TankLevelEstimate with _$TankLevelEstimate {
  const factory TankLevelEstimate({
    required int tankPercent,
    required double estimatedLitres,
    required TankLevelConfidence confidence,
  }) = _TankLevelEstimate;
}

enum TankLevelConfidence { high, medium, low }
```

#### `lib/features/alerts/data/refuel_timing_evaluator.dart`

Core evaluation logic, designed to run in the background isolate.

**Algorithm:**
1. Load `RefuelTimingConfig` from Hive settings
2. If `!config.enabled` → return early
3. Check cooldown: `lastFiredAt + cooldownHours > now` → return early
4. Estimate tank level via `TankLevelEstimator`
5. If `tankPercent > config.tankThresholdPercent` → return early (tank not low enough)
6. Determine monitored stations:
   - If `config.monitoredStationIds` is set → use those
   - Else → favourite station IDs + 3 nearest (from last GPS position)
7. For each station, compute `PricePrediction` (reuse `PricePredictionProvider` logic extracted to pure function)
8. Find the station with the best opportunity:
   - `currentPrice` from latest price record
   - `predictedTroughPrice` from hourly averages (cheapest hour in next `forecastHoursAhead`)
   - `predictedDrop = currentPrice - predictedTroughPrice`
9. Decision logic:
   - If `predictedDrop >= config.minPriceDrop` AND trough is ≥2h away:
     → `RefuelTimingAction.waitFor` ("Wait — price predicted to drop X cents at [station] in Y hours")
   - If `predictedDrop < config.minPriceDrop` OR trough is within 1h OR price is currently at/near trough:
     → `RefuelTimingAction.fillNow` ("Tank at ~X% — current price at [station] is near its predicted low. Fill up now.")
   - If no prediction available (< 10 data points) → `fillNow` with lower confidence
10. Fire notification via `LocalNotificationService`
11. Record `lastFiredAt` timestamp

**Integration into background pipeline:**

In `lib/core/background/background_service.dart`, after the existing alert evaluations:

```dart
// Step 5: Refuel timing advisor (NEW)
await RefuelTimingEvaluator(
  fillUps: fillUpStore.all(),
  stats: ConsumptionStats.fromFillUps(fillUpStore.all()),
  vehicle: activeVehicle,
  priceHistory: priceHistoryStore,
  favorites: favoritesStore.favoriteIds,
  lastPosition: lastKnownPosition,
  config: refuelTimingConfig,
  notificationService: notificationService,
).evaluate();
```

### 1.5 Presentation Layer

#### `lib/features/alerts/presentation/widgets/refuel_timing_setup_tile.dart`

Settings tile on the alerts configuration screen. Shows:
- Enable/disable toggle
- Tank threshold slider (10%–50%, step 5%)
- Price sensitivity selector (1/2/3/5 cents)
- Monitored stations picker (favorites or custom)

#### `lib/features/alerts/presentation/widgets/refuel_timing_card.dart`

Card displayed on the alerts tab when a timing recommendation is active. Shows:
- Station name + current price
- Recommendation text ("Fill up now" or "Wait X hours")
- Predicted savings per tank
- Confidence indicator (based on sample count from `HourlyAverage.sampleCount`)
- One-tap navigate button (deep-links to station detail via `GoRouter`)

### 1.6 Persistence

- **Config storage:** `HiveBoxes.settings` under key `'refuel_timing_config'` (JSON)
- **Last-fired timestamp:** `HiveBoxes.settings` under key `'refuel_timing_last_fired'` (ISO 8601 string)
- **No new Hive boxes** — all data fits in existing boxes

### 1.7 Feature Flag Integration

Register in `FeatureManifest.defaultManifest`:
```dart
Feature.refuelTimingAdvisor: FeatureManifestEntry(
  feature: Feature.refuelTimingAdvisor,
  defaultEnabled: false,
  requires: {Feature.priceAlerts},
  displayName: 'Smart Refuel Timing',
  description: 'Proactive fill-up notifications based on price predictions and tank level',
),
```

### 1.8 Localisation

New ARB keys via fragment system (`lib/l10n/_fragments/refuel_timing_en.arb`):
- `refuelTimingTitle`, `refuelTimingDescription`
- `refuelTimingFillNow`, `refuelTimingWaitFor`
- `refuelTimingTankAt` (with `{percent}` placeholder)
- `refuelTimingPredictedDrop` (with `{cents}`, `{hours}` placeholders)
- `refuelTimingSavingPerTank` (with `{amount}` placeholder)

Minimum translations: en, de, fr (per `feedback_french_onboarding_enforced.md`).

### 1.9 Test Strategy

| Test | Type | Description |
|------|------|-------------|
| `tank_level_estimator_test.dart` | Unit | Full tank → 100%, half-consumed → ~50%, with/without partials, with/without OBD odometer |
| `refuel_timing_evaluator_test.dart` | Unit | Fires when tank low + price near trough; waits when drop predicted; respects cooldown; handles missing predictions |
| `refuel_timing_config_test.dart` | Unit | JSON round-trip, defaults, validation |
| `refuel_timing_card_test.dart` | Widget | Renders fillNow vs waitFor states, navigate button tap |
| `refuel_timing_setup_tile_test.dart` | Widget | Toggle, slider, persistence |

### 1.10 Estimated Scope

- **New files:** 8 (3 entities, 2 domain services, 1 evaluator, 2 widgets)
- **Modified files:** 3 (`background_service.dart`, `feature.dart` enum, `feature_manifest.dart`)
- **LOC estimate:** ~400 (lib) + ~300 (test)
- **Risk:** Low — all inputs are existing providers; no new APIs, no schema changes

---

## Concept 2: Fuel Price Volatility Heatmap

### 2.1 Problem Statement

Tankstellen stores 30-day price history per station across 11 countries in `PriceHistoryRepository` (Hive box `price_history`). Currently this data is only surfaced per-station as line charts on `PriceHistoryScreen`. But the data contains spatial intelligence: some regions have stable, predictable prices (low standard deviation) while others swing wildly. A heatmap overlay on the existing `flutter_map` transforms per-station data into a spatial volatility view, helping users decide where and when to fill up. This feature requires zero new API calls — it is entirely computed from locally cached data.

### 2.2 Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│  PriceHistoryRepository (EXISTING)                            │
│  └── 30-day per-station PriceRecord list                      │
│      └── getHistory(stationId, days: 30)                      │
│      └── getStats(stationId, fuelType, days: 30) → PriceStats │
└──────────────────────────┬───────────────────────────────────┘
                           │ reads
┌──────────────────────────▼───────────────────────────────────┐
│  VolatilityCalculator (NEW — pure Dart, isolate-safe)         │
│  └── Input: List<PriceRecord> per station                     │
│  └── Output: StationVolatility per station                    │
│      └── stdDev, coefficientOfVariation, maxDailySwing        │
│      └── volatilityTier: stable / moderate / volatile         │
└──────────────────────────┬───────────────────────────────────┘
                           │ feeds
┌──────────────────────────▼───────────────────────────────────┐
│  VolatilityGrid (NEW — spatial aggregation)                   │
│  └── Input: Map<stationId, StationVolatility> + map bounds    │
│  └── Algorithm: hexagonal grid, 2km cells, IDW interpolation  │
│  └── Output: List<VolatilityCell> with center, tier, colour   │
└──────────────────────────┬───────────────────────────────────┘
                           │ renders
┌──────────────────────────▼───────────────────────────────────┐
│  VolatilityHeatmapLayer (NEW — flutter_map PolygonLayer)      │
│  └── Semi-transparent filled hexagons on map                  │
│  └── Colour: green (stable) / amber (moderate) / red (vol.)  │
│  └── Toggle via map toolbar button                            │
└──────────────────────────────────────────────────────────────┘
```

### 2.3 Domain Entities

#### `lib/features/price_history/domain/entities/station_volatility.dart`

```dart
@freezed
class StationVolatility with _$StationVolatility {
  const factory StationVolatility({
    required String stationId,
    required FuelType fuelType,
    required double meanPrice,
    required double stdDev,
    required double coefficientOfVariation,
    required double maxDailySwing,
    required VolatilityTier tier,
    required int sampleDays,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) = _StationVolatility;
}

enum VolatilityTier {
  stable,    // CV < 0.02  (prices vary < 2% around mean)
  moderate,  // CV 0.02–0.05
  volatile,  // CV > 0.05  (prices swing > 5% around mean)
}
```

#### `lib/features/price_history/domain/entities/volatility_cell.dart`

```dart
@freezed
class VolatilityCell with _$VolatilityCell {
  const factory VolatilityCell({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    required double avgVolatilityCV,
    required VolatilityTier tier,
    required int stationCount,
    required int colorArgb,
  }) = _VolatilityCell;
}
```

### 2.4 Domain Services

#### `lib/features/price_history/domain/volatility_calculator.dart`

Pure-Dart, no Flutter imports, isolate-safe.

**Input:** `List<PriceRecord>` for a single station, filtered to one `FuelType`

**Algorithm:**
1. Group records by calendar date → daily prices
2. Require ≥7 days with data (else return null — insufficient sample)
3. For each day: compute daily mean price (average of all records that day)
4. Across all daily means:
   - `mean` = arithmetic mean
   - `stdDev` = population standard deviation
   - `CV` = stdDev / mean
   - `maxDailySwing` = max(|dayN_mean - dayN-1_mean|) across consecutive days
5. Classify tier:
   - CV < 0.02 → `stable`
   - 0.02 ≤ CV < 0.05 → `moderate`
   - CV ≥ 0.05 → `volatile`

```dart
class VolatilityCalculator {
  StationVolatility? compute({
    required String stationId,
    required FuelType fuelType,
    required List<PriceRecord> records,
  });

  Map<String, StationVolatility> computeBatch({
    required FuelType fuelType,
    required Map<String, List<PriceRecord>> recordsByStation,
  });
}
```

#### `lib/features/price_history/domain/volatility_grid.dart`

Spatial aggregation into hexagonal cells.

**Input:**
- `Map<String, StationVolatility>` — per-station volatility
- `Map<String, LatLng>` — station coordinates (from cached search results)
- `LatLngBounds` — visible map bounds
- `double cellRadiusKm` — default 2.0

**Algorithm:**
1. Compute hex grid covering the visible bounds:
   - Hex width = `cellRadiusKm * 2 * cos(30°)` in km
   - Hex height = `cellRadiusKm * 1.5` in km
   - Convert to lat/lng offsets using local mercator approximation
   - Generate grid centres, offset every other row (pointy-top hexagons)
2. For each cell, find stations within `cellRadiusKm`:
   - Compute inverse-distance-weighted (IDW) average of CV values
   - Weight = `1 / distance²` (capped at 0.1 km minimum distance)
   - Skip cells with 0 stations
3. Classify each cell's tier from weighted-average CV
4. Assign colour:
   - Stable: `Color(0x4D4CAF50)` (green, 30% opacity)
   - Moderate: `Color(0x4DFFC107)` (amber, 30% opacity)
   - Volatile: `Color(0x4DF44336)` (red, 30% opacity)
   - Opacity scales with `min(stationCount / 5, 1.0)` — more stations = more opaque

```dart
class VolatilityGrid {
  List<VolatilityCell> compute({
    required Map<String, StationVolatility> volatilities,
    required Map<String, LatLng> stationPositions,
    required LatLngBounds bounds,
    double cellRadiusKm = 2.0,
  });
}
```

### 2.5 Presentation Layer

#### `lib/features/map/presentation/widgets/volatility_heatmap_layer.dart`

Renders `List<VolatilityCell>` as a `PolygonLayer` on the existing `flutter_map`.

Each cell is a 6-vertex polygon computed from `(centerLat, centerLng, radiusKm)`:
```dart
List<LatLng> hexVertices(double lat, double lng, double radiusKm) {
  return List.generate(6, (i) {
    final angle = (60 * i - 30) * pi / 180; // pointy-top hex
    final dLat = radiusKm / 111.32 * cos(angle);
    final dLng = radiusKm / (111.32 * cos(lat * pi / 180)) * sin(angle);
    return LatLng(lat + dLat, lng + dLng);
  });
}
```

Layer is conditionally included in the `FlutterMap.children` list:
```dart
if (showVolatilityOverlay) ...[
  PolygonLayer(
    polygons: volatilityCells.map((cell) => Polygon(
      points: hexVertices(cell.centerLat, cell.centerLng, cell.radiusKm),
      color: Color(cell.colorArgb),
      borderColor: Color(cell.colorArgb).withAlpha(80),
      borderStrokeWidth: 1.0,
      isFilled: true,
    )).toList(),
  ),
],
```

#### `lib/features/map/presentation/widgets/volatility_toggle_button.dart`

Toolbar button alongside the existing EV overlay toggle. Uses the existing map toolbar pattern from `map_screen.dart`:
- Icon: `Icons.show_chart` (or `Icons.heatmap` if available in the icon set)
- Tooltip: localised "Price Volatility"
- Active state: highlighted with `primaryContainer` colour
- Toggles `volatilityOverlayEnabledProvider`

#### `lib/features/map/presentation/widgets/volatility_legend.dart`

Bottom-left overlay (positioned to avoid the existing price legend):
- Three coloured dots with labels: "Stable", "Moderate", "Volatile"
- Compact card with `Theme.of(context).cardTheme` styling
- Only visible when volatility overlay is active

#### `lib/features/map/presentation/widgets/volatility_info_sheet.dart`

Bottom sheet triggered by tapping a volatility cell:
- Cell's average CV and tier label
- List of stations within the cell, sorted by stability (most stable first)
- Per-station: name, CV value, max daily swing in €
- Recommendation text:
  - Stable: "Prices here are predictable — fill up whenever convenient."
  - Moderate: "Moderate price swings — check the price prediction for best timing."
  - Volatile: "High price volatility — use price alerts to catch drops."
- "See price prediction" button → navigates to most stable station's detail screen

### 2.6 Providers

#### `lib/features/map/providers/volatility_heatmap_provider.dart`

```dart
@riverpod
class VolatilityHeatmapEnabled extends _$VolatilityHeatmapEnabled {
  @override
  bool build() => false; // Off by default

  void toggle() => state = !state;
}

@riverpod
Future<List<VolatilityCell>> volatilityHeatmap(
  Ref ref, {
  required LatLngBounds bounds,
  required FuelType fuelType,
}) async {
  final priceHistoryRepo = ref.watch(priceHistoryRepositoryProvider);
  final searchResults = ref.watch(fuelStationsProvider).valueOrNull ?? [];

  // Build station ID → position map from cached search results
  final stationPositions = <String, LatLng>{};
  for (final station in searchResults) {
    stationPositions[station.id] = LatLng(station.lat, station.lng);
  }

  // Compute per-station volatility
  final calculator = VolatilityCalculator();
  final volatilities = <String, StationVolatility>{};
  for (final stationId in stationPositions.keys) {
    final records = await priceHistoryRepo.getHistory(stationId, days: 30);
    final vol = calculator.compute(
      stationId: stationId,
      fuelType: fuelType,
      records: records,
    );
    if (vol != null) volatilities[stationId] = vol;
  }

  // Aggregate into spatial grid
  return VolatilityGrid().compute(
    volatilities: volatilities,
    stationPositions: stationPositions,
    bounds: bounds,
    cellRadiusKm: 2.0,
  );
}
```

**Debouncing:** The map screen debounces bound changes (300ms) before re-triggering this provider, consistent with the existing search debounce pattern.

### 2.7 Test Strategy

| Test | Type | Description |
|------|------|-------------|
| `volatility_calculator_test.dart` | Unit | Constant prices → stable tier; oscillating → volatile; boundary CV values; <7 days → null |
| `volatility_grid_test.dart` | Unit | Single station → single cell; IDW weights; empty grid returns []; edge stations at cell boundary |
| `volatility_heatmap_layer_test.dart` | Widget | Renders correct polygon count; colour matches tier; hidden when toggle off |
| `volatility_info_sheet_test.dart` | Widget | Shows station list; recommendation text per tier |

### 2.8 Estimated Scope

- **New files:** 9 (2 entities, 2 domain services, 4 widgets, 1 provider)
- **Modified files:** 2 (`map_screen.dart` — add layer + toggle, `feature.dart` enum)
- **LOC estimate:** ~500 (lib) + ~350 (test)
- **Risk:** Low — no API calls, no schema changes, purely additive UI overlay

---

## Concept 3: Weather-Aware Fuel Efficiency Advisor

### 3.1 Problem Statement

Weather conditions have a measurable impact on fuel consumption: cold temperatures (+12–20% for short trips), headwinds (+10–20% at highway speeds), rain (+3% per mm/h from rolling resistance), and HVAC load (+5–15%). Tankstellen's driving score and consumption stats treat all trips equally, which means:
- A winter trip scored 65 might be genuinely excellent given conditions
- A consumption uptrend might be seasonal, not mechanical degradation
- Route search detour cost calculations ignore wind direction

By integrating weather data from Open-Meteo (free, no API key, covers all 11 countries), the app can weather-normalise its analytics and provide fairer, more actionable insights.

### 3.2 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Open-Meteo API (free, no key)                               │
│  https://api.open-meteo.com/v1/forecast                      │
│  └── temperature, precipitation, wind speed/direction,       │
│      humidity, weather code (WMO)                            │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP (existing Dio client)
┌──────────────────────────▼──────────────────────────────────┐
│  WeatherService (NEW, lib/core/weather/)                     │
│  ├── OpenMeteoWeatherService (implementation)                │
│  ├── WeatherCache (1h/6h TTL, Hive-backed)                  │
│  └── WeatherForecast / WeatherCondition entities             │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐ ┌───────────────┐ ┌──────────────────┐
│ Trip Recorder │ │ Driving Score │ │ Route Search     │
│ (MODIFIED)    │ │ (MODIFIED)    │ │ (MODIFIED)       │
│               │ │               │ │                  │
│ Stores weather│ │ Adjusts score │ │ Weather-aware    │
│ snapshot per  │ │ thresholds    │ │ cost model for   │
│ trip start/end│ │ based on      │ │ detour decisions │
│               │ │ conditions    │ │                  │
└───────────────┘ └───────────────┘ └──────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ WeatherNormalisedStats (NEW)          │
│ └── Adjusts historical consumption   │
│     for conditions at time of trip    │
│ └── Separates weather effect from     │
│     vehicle degradation              │
└───────────────────────────────────────┘
```

### 3.3 Core Weather Service

#### `lib/core/weather/weather_service.dart`

```dart
abstract class WeatherService {
  Future<WeatherForecast> getForecast(
    double lat,
    double lng, {
    int hoursAhead = 24,
  });

  Future<WeatherCondition> getCurrentConditions(double lat, double lng);
}
```

#### `lib/core/weather/open_meteo_weather_service.dart`

```dart
class OpenMeteoWeatherService implements WeatherService {
  final Dio _dio; // Reuse existing Dio instance from provider

  @override
  Future<WeatherForecast> getForecast(double lat, double lng, {int hoursAhead = 24}) async {
    final response = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'hourly': 'temperature_2m,precipitation,wind_speed_10m,wind_direction_10m,relative_humidity_2m,weather_code',
        'forecast_hours': hoursAhead,
        'timezone': 'auto',
      },
    );
    return WeatherForecast.fromOpenMeteoJson(response.data);
  }

  @override
  Future<WeatherCondition> getCurrentConditions(double lat, double lng) async {
    final forecast = await getForecast(lat, lng, hoursAhead: 1);
    return forecast.hourlyEntries.first.toCondition();
  }
}
```

### 3.4 Weather Entities

#### `lib/core/weather/entities/weather_forecast.dart`

```dart
@freezed
class WeatherForecast with _$WeatherForecast {
  const factory WeatherForecast({
    required List<WeatherHour> hourlyEntries,
    required double locationLat,
    required double locationLng,
    required DateTime fetchedAt,
  }) = _WeatherForecast;

  factory WeatherForecast.fromOpenMeteoJson(Map<String, dynamic> json) => /* ... */;
}

@freezed
class WeatherHour with _$WeatherHour {
  const factory WeatherHour({
    required DateTime dateTime,
    required double temperatureCelsius,
    required double precipitationMm,
    required double windSpeedKmh,
    required int windDirectionDeg,
    required int humidityPercent,
    required int weatherCode, // WMO standard
  }) = _WeatherHour;
}

@freezed
class WeatherCondition with _$WeatherCondition {
  const factory WeatherCondition({
    required double temperatureCelsius,
    required double precipitationMm,
    required double windSpeedKmh,
    required int windDirectionDeg,
    required int humidityPercent,
    required int weatherCode,
    required DateTime observedAt,
  }) = _WeatherCondition;
}
```

### 3.5 Fuel-Weather Correlator

#### `lib/core/weather/fuel_weather_correlator.dart`

Pure-Dart service computing `FuelEfficiencyImpact`.

**Published engineering model (conservative estimates):**

```dart
class FuelWeatherCorrelator {
  FuelEfficiencyImpact compute({
    required double baselineConsumptionL100km,
    required WeatherCondition conditions,
    double? tripBearingDeg, // For headwind calculation
  }) {
    // Temperature factor (piecewise linear, baseline = 20°C)
    final tempImpact = _temperatureImpact(conditions.temperatureCelsius);
    // < 0°C  → +15% to +20%
    // 0–10°C → +8% to +12%
    // 10–20°C → +2% to +5%
    // 20–25°C → baseline (0%)
    // > 25°C → +3% to +8% (A/C load)

    // Wind factor (headwind component if bearing known)
    final windImpact = _windImpact(
      conditions.windSpeedKmh,
      conditions.windDirectionDeg,
      tripBearingDeg,
    );
    // Headwind 20 km/h → +5%
    // Headwind 40 km/h → +12%
    // Headwind 60 km/h → +20%
    // Tailwind → negative impact (savings)

    // Precipitation factor
    final precipImpact = _precipitationImpact(conditions.precipitationMm);
    // +3% per mm/h of rain (rolling resistance + wipers)

    // HVAC factor (derived from temperature)
    final hvacImpact = _hvacImpact(conditions.temperatureCelsius);
    // < 5°C → +5% (heater + defrost)
    // > 28°C → +5% to +10% (A/C)

    final totalImpact = tempImpact + windImpact + precipImpact + hvacImpact;
    final adjustedConsumption = baselineConsumptionL100km * (1 + totalImpact / 100);

    return FuelEfficiencyImpact(
      temperatureImpactPercent: tempImpact,
      windImpactPercent: windImpact,
      precipitationImpactPercent: precipImpact,
      hvacImpactPercent: hvacImpact,
      totalImpactPercent: totalImpact,
      adjustedBaselineConsumption: adjustedConsumption,
      humanSummary: _composeSummary(tempImpact, windImpact, precipImpact, totalImpact),
    );
  }
}
```

#### `lib/core/weather/entities/fuel_efficiency_impact.dart`

```dart
@freezed
class FuelEfficiencyImpact with _$FuelEfficiencyImpact {
  const factory FuelEfficiencyImpact({
    required double temperatureImpactPercent,
    required double windImpactPercent,
    required double precipitationImpactPercent,
    required double hvacImpactPercent,
    required double totalImpactPercent,
    required double adjustedBaselineConsumption,
    required String humanSummary,
  }) = _FuelEfficiencyImpact;
}
```

### 3.6 Integration Points

#### Trip Recording — Store Weather Snapshot

Modify `lib/features/consumption/domain/entities/trip.dart` (or the relevant trip entity):
```dart
// Add to Trip entity (Freezed):
WeatherCondition? weatherAtStart,
WeatherCondition? weatherAtEnd,
```

In the trip recorder, when a trip starts:
```dart
final weather = await weatherService.getCurrentConditions(lat, lng);
trip = trip.copyWith(weatherAtStart: weather);
```

And when a trip ends:
```dart
final weather = await weatherService.getCurrentConditions(lat, lng);
trip = trip.copyWith(weatherAtEnd: weather);
```

#### Driving Score — Weather-Adjusted Thresholds

In `DrivingScoreCalculator`, when weather data is available for a trip:
```dart
final impact = FuelWeatherCorrelator().compute(
  baselineConsumptionL100km: vehicleBaseline,
  conditions: trip.weatherAtStart ?? defaultConditions,
);

// Relax consumption thresholds proportionally
final adjustedExpectedConsumption = vehicleBaseline * (1 + impact.totalImpactPercent / 100);
// Score consumption component against adjusted expectation, not raw baseline
```

This means a trip at 8.2 L/100km in cold rain scores the same as 7.1 L/100km in dry 20°C weather.

#### Route Search — Weather-Aware Detour Cost

New decorator following the same pattern as the maintenance-aware routing proposed May 3:

```dart
class WeatherAwareCostModel {
  double adjustedDetourCost({
    required double detourKm,
    required double avgConsumption,
    required double fuelPrice,
    required WeatherCondition conditions,
    double? detourBearing,
  }) {
    final impact = FuelWeatherCorrelator().compute(
      baselineConsumptionL100km: avgConsumption,
      conditions: conditions,
      tripBearingDeg: detourBearing,
    );
    final adjustedConsumption = impact.adjustedBaselineConsumption;
    return detourKm * adjustedConsumption / 100 * fuelPrice;
  }
}
```

### 3.7 Presentation Widgets

#### `lib/features/consumption/presentation/widgets/weather_impact_chip.dart`

Small chip on trip detail screen:
- Weather icon (sun, cloud, rain, snow — from WMO weather code)
- "+X%" or "−X%" impact text
- Tappable tooltip with breakdown (temperature, wind, rain contributions)

#### `lib/features/driving/presentation/widgets/weather_advisory_banner.dart`

Banner on driving mode screen when expected impact > 10%:
- "Headwind + rain expected — consumption may be ~15% higher than usual"
- Tappable for hourly forecast breakdown
- Dismissable (persists for current driving session)

### 3.8 Weather Cache

#### `lib/core/weather/weather_cache.dart`

Follows existing `CacheManager` pattern:
```dart
class WeatherCache {
  static const currentConditionsTtl = Duration(hours: 1);
  static const forecastTtl = Duration(hours: 6);

  static String currentKey(double lat, double lng) =>
      'weather:current:${lat.toStringAsFixed(2)}:${lng.toStringAsFixed(2)}';

  static String forecastKey(double lat, double lng) =>
      'weather:forecast:${lat.toStringAsFixed(2)}:${lng.toStringAsFixed(2)}';
}
```

Coordinate rounding to 2 decimals (~1.1 km precision) ensures nearby requests share cache entries.

### 3.9 Test Strategy

| Test | Type | Description |
|------|------|-------------|
| `fuel_weather_correlator_test.dart` | Unit | 20°C dry → 0% impact; -10°C → +15–20%; 40 km/h headwind → +12%; rain 3mm → +9%; combined effects |
| `open_meteo_weather_service_test.dart` | Unit | JSON parsing, error handling, timezone conversion |
| `weather_cache_test.dart` | Unit | TTL expiry, coordinate rounding, cache key uniqueness |
| `weather_normalised_stats_test.dart` | Unit | Winter trips normalised down; summer trips unchanged; mixed seasons |
| `weather_impact_chip_test.dart` | Widget | Renders correct icon per WMO code; shows ±% text |
| `weather_advisory_banner_test.dart` | Widget | Shows when impact >10%; hidden when <10%; dismissable |

### 3.10 Estimated Scope

- **New files:** 12 (4 entities, 3 domain services, 1 cache, 2 widgets, 1 service impl, 1 provider)
- **Modified files:** 4 (trip entity, driving score calculator, route search strategy, `feature.dart`)
- **LOC estimate:** ~700 (lib) + ~500 (test)
- **Dependency:** `speech_to_text` NOT needed; Open-Meteo uses existing `Dio`
- **Risk:** Medium — new external API, but free/keyless with graceful degradation (feature works without weather data)

---

## Concept 4: Insurance Telematics Data Export (UBI Portal)

### 4.1 Problem Statement

Tankstellen's OBD-II integration already collects the exact data insurers need for Usage-Based Insurance (UBI) premium discounts (10–25%): trip distance, speed profiles, harsh braking/acceleration counts, time-of-day driving distribution, and a composite driving score. Currently this data is only visible within the app's consumption screens. By generating standardised, integrity-verified driving reports, Tankstellen becomes a neutral "driving passport" — users share one report with any insurer without needing insurer-specific hardware.

### 4.2 Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│  Existing Data Sources (read-only)                                │
│                                                                    │
│  ├── TripHistory         → distance, duration, start/end times    │
│  ├── TripSummary         → harsh events, idle, cold start, RPM   │
│  ├── DrivingScore        → 0–100 per-trip score                   │
│  ├── DrivingInsights     → acceleration patterns, throttle hist   │
│  ├── ConsumptionStats    → avg L/100km, total km                  │
│  ├── VehicleProfile      → make, model, year, engine class        │
│  └── MaintenanceSuggestion → vehicle health indicators            │
└──────────────────────────┬───────────────────────────────────────┘
                           │ reads
┌──────────────────────────▼───────────────────────────────────────┐
│  TelematicsReportGenerator (NEW — pure Dart)                      │
│  └── Aggregates all data for a vehicle within a date range        │
│  └── Computes risk classification                                 │
│  └── Generates integrity hash (SHA-256)                           │
│  └── Output: TelematicsReport entity                              │
└──────────────────────────┬───────────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ PDF      │ │ JSON/CSV │ │ QR Code  │
        │ Export   │ │ Export   │ │ Summary  │
        │ (human)  │ │ (machine)│ │ (agent)  │
        └──────────┘ └──────────┘ └──────────┘
              │            │            │
              └────────────┼────────────┘
                           │
                    share_plus / qr_flutter
```

### 4.3 Domain Entities

#### `lib/features/telematics_export/domain/entities/telematics_report.dart`

```dart
@freezed
class TelematicsReport with _$TelematicsReport {
  const factory TelematicsReport({
    required String reportId,
    required String vehicleId,
    required DateTime periodStart,
    required DateTime periodEnd,

    // Volume metrics
    required int totalTrips,
    required double totalKm,
    required double totalHours,
    required double avgTripDistanceKm,

    // Safety metrics
    required double avgDrivingScore,
    required ScoreTrend scoreTrend,
    required double hardBrakingEventsPerKm,
    required double hardAccelEventsPerKm,
    required double idleTimePercentage,

    // Time-of-day distribution
    required double nightDrivingPercentage, // % of km between 23:00–05:00
    required Map<int, double> hourlyKmDistribution, // hour → % of total km

    // Efficiency
    required double avgConsumptionL100km,
    required String fuelEfficiencyRating, // A–F based on vehicle class

    // Classification
    required RiskCategory riskCategory,
    required Map<RiskDimension, RiskLevel> dimensionRatings,

    // Integrity
    required DateTime generatedAt,
    required String appVersion,
    required String integrityHash, // SHA-256 of deterministic JSON
  }) = _TelematicsReport;
}

enum ScoreTrend { improving, stable, declining }
enum RiskCategory { low, medium, high }
enum RiskDimension { safety, efficiency, consistency, timeOfDay, experience }
enum RiskLevel { low, medium, high }
```

### 4.4 Risk Classifier

#### `lib/features/telematics_export/domain/risk_classifier.dart`

Conservative classification — only rates "low" when data strongly supports it.

```dart
class RiskClassifier {
  RiskCategory classify(TelematicsReport report) {
    final dimensions = <RiskDimension, RiskLevel>{
      RiskDimension.safety: _classifySafety(report),
      RiskDimension.efficiency: _classifyEfficiency(report),
      RiskDimension.consistency: _classifyConsistency(report),
      RiskDimension.timeOfDay: _classifyTimeOfDay(report),
      RiskDimension.experience: _classifyExperience(report),
    };

    // Any single "high" caps overall at "medium"
    if (dimensions.values.any((v) => v == RiskLevel.high)) {
      return RiskCategory.medium;
    }
    // All "low" → overall "low"
    if (dimensions.values.every((v) => v == RiskLevel.low)) {
      return RiskCategory.low;
    }
    return RiskCategory.medium;
  }

  RiskLevel _classifySafety(TelematicsReport r) {
    // Hard braking < 2 per 100 km AND hard accel < 3 per 100 km → low
    if (r.hardBrakingEventsPerKm * 100 < 2 && r.hardAccelEventsPerKm * 100 < 3) {
      return RiskLevel.low;
    }
    if (r.hardBrakingEventsPerKm * 100 > 5 || r.hardAccelEventsPerKm * 100 > 7) {
      return RiskLevel.high;
    }
    return RiskLevel.medium;
  }

  RiskLevel _classifyTimeOfDay(TelematicsReport r) {
    // < 10% night driving → low; > 30% → high
    if (r.nightDrivingPercentage < 10) return RiskLevel.low;
    if (r.nightDrivingPercentage > 30) return RiskLevel.high;
    return RiskLevel.medium;
  }

  RiskLevel _classifyExperience(TelematicsReport r) {
    // > 5000 km in period → low; < 1000 km → high (insufficient data)
    if (r.totalKm > 5000) return RiskLevel.low;
    if (r.totalKm < 1000) return RiskLevel.high;
    return RiskLevel.medium;
  }
  // ... efficiency and consistency classifiers
}
```

### 4.5 Report Generator

#### `lib/features/telematics_export/domain/telematics_report_generator.dart`

```dart
class TelematicsReportGenerator {
  TelematicsReport generate({
    required String vehicleId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Trip> trips,
    required List<TripSummary> summaries,
    required Map<String, double> scoresByTripId,
    required ConsumptionStats stats,
    required VehicleProfile vehicle,
    required String appVersion,
  }) {
    // 1. Filter trips to period
    final periodTrips = trips.where((t) =>
      t.startedAt != null &&
      t.startedAt!.isAfter(periodStart) &&
      t.startedAt!.isBefore(periodEnd)
    ).toList();

    // 2. Aggregate metrics
    final totalKm = periodTrips.fold(0.0, (sum, t) => sum + t.distanceKm);
    final totalHours = periodTrips.fold(0.0, (sum, t) =>
      sum + (t.endedAt!.difference(t.startedAt!).inMinutes / 60));

    // 3. Compute harsh events per km
    final totalHarshBrakes = summaries.fold(0, (sum, s) => sum + s.harshBrakes);
    final totalHarshAccels = summaries.fold(0, (sum, s) => sum + s.harshAccelerations);

    // 4. Night driving analysis
    final nightKm = _computeNightKm(periodTrips); // 23:00–05:00 window

    // 5. Score trend (compare first-half vs second-half average score)
    final trend = _computeScoreTrend(periodTrips, scoresByTripId);

    // 6. Build report
    final report = TelematicsReport(/* ... all fields ... */);

    // 7. Compute integrity hash
    final jsonStr = const JsonEncoder().convert(report.toIntegrityJson());
    final hash = sha256.convert(utf8.encode(jsonStr)).toString();

    return report.copyWith(integrityHash: hash);
  }
}
```

### 4.6 Export Formats

#### PDF Report
Generated using `pdf` package (or existing PDF pattern if available):
- **Cover page:** Vehicle info, overall grade (A–F), period, Tankstellen branding
- **Page 2:** Radar chart (5 axes: safety, efficiency, consistency, time-of-day, experience)
- **Page 3:** Monthly trend charts (driving score, consumption, harsh events)
- **Page 4:** Detailed metrics table (all raw numbers)
- **Footer:** Integrity hash + QR code encoding `TelematicsSummary`

#### JSON/CSV Export
Machine-readable formats for API integration:
- JSON: Full `TelematicsReport` serialised
- CSV: Flat table with one row per trip (id, date, distance, score, harsh events)

#### QR Summary
Compact summary for in-person agent meetings using existing `qr_flutter`:
```dart
@freezed
class TelematicsSummary with _$TelematicsSummary {
  const factory TelematicsSummary({
    required String overallGrade,
    required double totalKm,
    required double avgScore,
    required int periodMonths,
    required RiskCategory riskCategory,
  }) = _TelematicsSummary;
}
```

### 4.7 Presentation Layer

#### `lib/features/telematics_export/presentation/screens/telematics_export_screen.dart`

- **Hero card:** Overall grade (A–F) with colour (A=green, F=red), trend arrow
- **Radar chart:** 5-axis `CustomPainter` widget (safety, efficiency, consistency, time-of-day, experience)
- **Period selector:** 3 / 6 / 12 months toggle
- **Key metrics grid:** Total km, trips, avg score, harsh events rate
- **"Generate Report" button:** Opens format picker (PDF / JSON / CSV)
- **"Share" button:** Uses `share_plus` to send file
- **QR display:** Expandable section showing QR code for in-person sharing

#### `lib/features/telematics_export/presentation/widgets/driving_profile_radar.dart`

5-axis radar chart using `CustomPainter`:
- Axes positioned at 72° intervals
- Filled polygon for user's scores (0–100 normalised per axis)
- Reference polygon for "average driver" baseline (50 on all axes)
- Themed colours from `lib/app/theme.dart`

### 4.8 Privacy Design

- Reports generated **entirely on-device** — no data sent to Tankstellen servers
- User explicitly chooses when and with whom to share
- Reports contain **aggregate statistics only** — no GPS traces, no specific locations
- Integrity hash allows verification without raw data leaving device
- Users select date range — they control how much history to reveal
- No insurer partnerships — user is sole data controller

### 4.9 Test Strategy

| Test | Type | Description |
|------|------|-------------|
| `telematics_report_generator_test.dart` | Unit | Correct aggregation of km, hours, harsh events; night driving calculation; score trend detection |
| `risk_classifier_test.dart` | Unit | Low/medium/high classification per dimension; single-high caps overall; boundary values |
| `integrity_hash_test.dart` | Unit | Deterministic: same input → same hash; different input → different hash |
| `telematics_export_screen_test.dart` | Widget | Period selector, generate button, format picker, QR display |
| `driving_profile_radar_test.dart` | Golden | Radar chart renders correctly with sample data |

### 4.10 Estimated Scope

- **New files:** 14 (4 entities, 2 domain services, 1 exporter, 4 widgets, 2 screens, 1 provider)
- **Modified files:** 1 (`feature.dart` enum)
- **LOC estimate:** ~900 (lib) + ~600 (test)
- **Dependencies:** `crypto` (for SHA-256, likely already transitive), `pdf` (if not already present)
- **Risk:** Medium — PDF generation is the most complex part; all data inputs are existing

---

## Concept 5: Trip Cost Sharing Calculator

### 5.1 Problem Statement

Carpooling surged 40% in early 2026. When sharing rides, accurate fuel cost splitting requires knowing actual consumption (not just distance), actual price paid, and each passenger's route segment. Tankstellen uniquely has all three from OBD-II trips and fill-up logs. Building an integrated cost splitter turns every recorded trip into a shareable receipt — and each shared receipt is a Tankstellen-branded viral touchpoint.

### 5.2 Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│  Existing Data (read-only)                                    │
│  ├── Trip entity         → distance, GPS path, duration       │
│  ├── FillUp entity       → litres, totalCost, pricePerLiter  │
│  └── VehicleProfile      → consumption rate (fallback)        │
└──────────────────────────┬───────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────┐
│  CostSplitCalculator (NEW — pure Dart)                        │
│  ├── equal:      totalCost / participantCount                 │
│  ├── byDistance:  proportional to individual km               │
│  └── bySegment:  per-segment cost split among aboard riders   │
└──────────────────────────┬───────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────┐
│  CostSplitReceiptGenerator (NEW)                              │
│  ├── Plain text (messaging apps)                              │
│  ├── Styled PNG (WhatsApp/Instagram via share_plus)           │
│  └── Deep link back to Tankstellen app                        │
└──────────────────────────────────────────────────────────────┘
```

### 5.3 Domain Entities

#### `lib/features/cost_split/domain/entities/cost_split.dart`

```dart
@freezed
class CostSplit with _$CostSplit {
  const factory CostSplit({
    required String splitId,
    String? tripId,
    String? fillUpId,
    required double totalFuelCost,
    required double totalDistanceKm,
    required List<SplitParticipant> participants,
    required SplitMethod splitMethod,
    required DateTime createdAt,
    required String currency,
  }) = _CostSplit;

  factory CostSplit.fromJson(Map<String, dynamic> json) =>
      _$CostSplitFromJson(json);
}

enum SplitMethod {
  equal,       // Simple: cost / headcount
  byDistance,  // Proportional to each person's km aboard
  bySegment,   // Per-segment division among passengers present
}
```

#### `lib/features/cost_split/domain/entities/split_participant.dart`

```dart
@freezed
class SplitParticipant with _$SplitParticipant {
  const factory SplitParticipant({
    required String name,
    @Default(0) double boardingKm,     // km into trip where they joined (0 = from start)
    double? alightingKm,               // km where they left (null = full trip)
    @Default(0) double shareAmount,    // computed
    @Default(0) double sharePercentage, // computed
  }) = _SplitParticipant;

  factory SplitParticipant.fromJson(Map<String, dynamic> json) =>
      _$SplitParticipantFromJson(json);
}
```

### 5.4 Cost Split Calculator

#### `lib/features/cost_split/domain/cost_split_calculator.dart`

```dart
class CostSplitCalculator {
  List<SplitParticipant> calculate({
    required double totalCost,
    required double totalDistanceKm,
    required List<SplitParticipant> participants,
    required SplitMethod method,
  }) {
    switch (method) {
      case SplitMethod.equal:
        return _equalSplit(totalCost, participants);
      case SplitMethod.byDistance:
        return _distanceSplit(totalCost, totalDistanceKm, participants);
      case SplitMethod.bySegment:
        return _segmentSplit(totalCost, totalDistanceKm, participants);
    }
  }

  List<SplitParticipant> _equalSplit(double totalCost, List<SplitParticipant> participants) {
    final share = totalCost / participants.length;
    final pct = 100.0 / participants.length;
    return participants.map((p) => p.copyWith(shareAmount: share, sharePercentage: pct)).toList();
  }

  List<SplitParticipant> _distanceSplit(
    double totalCost,
    double totalKm,
    List<SplitParticipant> participants,
  ) {
    // Each participant's individual km
    final individualKms = participants.map((p) {
      final alighting = p.alightingKm ?? totalKm;
      return (alighting - p.boardingKm).clamp(0.0, totalKm);
    }).toList();

    final sumIndividualKm = individualKms.fold(0.0, (a, b) => a + b);
    if (sumIndividualKm == 0) return _equalSplit(totalCost, participants);

    return List.generate(participants.length, (i) {
      final pct = individualKms[i] / sumIndividualKm * 100;
      final share = totalCost * individualKms[i] / sumIndividualKm;
      return participants[i].copyWith(shareAmount: share, sharePercentage: pct);
    });
  }

  List<SplitParticipant> _segmentSplit(
    double totalCost,
    double totalKm,
    List<SplitParticipant> participants,
  ) {
    // Build segment breakpoints from boarding/alighting points
    final breakpoints = <double>{0, totalKm};
    for (final p in participants) {
      breakpoints.add(p.boardingKm);
      if (p.alightingKm != null) breakpoints.add(p.alightingKm!);
    }
    final sorted = breakpoints.toList()..sort();

    // For each segment, determine who was aboard and split that segment's cost
    final shares = List.filled(participants.length, 0.0);
    for (int s = 0; s < sorted.length - 1; s++) {
      final segStart = sorted[s];
      final segEnd = sorted[s + 1];
      final segFraction = (segEnd - segStart) / totalKm;
      final segCost = totalCost * segFraction;

      // Who is aboard this segment?
      final aboard = <int>[];
      for (int i = 0; i < participants.length; i++) {
        final p = participants[i];
        final alighting = p.alightingKm ?? totalKm;
        if (p.boardingKm <= segStart && alighting >= segEnd) {
          aboard.add(i);
        }
      }

      if (aboard.isEmpty) continue;
      final perPerson = segCost / aboard.length;
      for (final i in aboard) {
        shares[i] += perPerson;
      }
    }

    return List.generate(participants.length, (i) {
      return participants[i].copyWith(
        shareAmount: shares[i],
        sharePercentage: shares[i] / totalCost * 100,
      );
    });
  }
}
```

### 5.5 Receipt Generator

#### `lib/features/cost_split/domain/cost_split_receipt_generator.dart`

Generates shareable receipts in three formats:

**Plain text** (for messaging apps):
```
🚗 Trip Cost Split — 2026-05-05
Route: Castelnau-de-Guers → Montpellier (42 km)
Total fuel cost: €4.82

💰 Cost per person:
• Franck: €2.41 (50%)
• Anna: €1.45 (30%)
• Tom: €0.96 (20%)

Split method: By distance
Calculated with Tankstellen
```

**Styled PNG** (for WhatsApp/Instagram):
Uses existing `WidgetShareRenderer` pattern from `lib/core/sharing/widget_share_renderer.dart`:
```dart
Future<File> generateReceiptImage(CostSplit split) async {
  final widget = SplitReceiptCard(split: split); // renders as RepaintBoundary
  return WidgetShareRenderer.shareWidgetAsImage(receiptKey, 'trip_split_receipt');
}
```

**Deep link** (for Tankstellen users):
`tankstellen://cost-split/${splitId}` — opens the split detail in the app.

### 5.6 Presentation Layer

#### `lib/features/cost_split/presentation/screens/cost_split_screen.dart`

Flow:
1. **Auto-populate** total cost from linked trip/fill-up (or enter manually)
2. **Add participants** — name text field per person, "+" button to add
3. **Optional:** Set boarding/alighting km (for byDistance/bySegment methods)
4. **Select split method** — three segmented buttons: Equal / By Distance / By Segment
5. **Preview** — computed shares displayed in `SplitReceiptCard`
6. **Share** — share_plus sheet with text/image/link options

#### `lib/features/cost_split/presentation/widgets/participant_editor.dart`

ListView of participant rows:
- Name `TextField` (required)
- Optional distance slider (visible only for byDistance/bySegment methods)
- Computed share amount (live-updating)
- Delete button (minimum 2 participants enforced)
- "Add participant" button at bottom

#### `lib/features/cost_split/presentation/widgets/split_receipt_card.dart`

Styled card serving as both preview and shareable image:
- Tankstellen logo (small, top-right)
- Trip date + route summary (start → end)
- Per-person breakdown with amount + percentage
- Total + split method label
- Themed with `Theme.of(context).cardTheme`

#### `lib/features/cost_split/presentation/widgets/route_participant_overlay.dart`

Mini `flutter_map` (when trip has GPS data):
- Route polyline
- Coloured segments showing who was aboard each section
- Boarding/alighting markers with participant names
- Compact card layout (200px height)

### 5.7 Integration Points

- **Trip detail screen** (`lib/features/consumption/presentation/`): "Split Cost" action button in app bar
- **Fill-up detail:** "Split" option in action menu
- **Standalone entry:** From navigation menu for manual cost entry (no trip/fill-up link)
- **GPS data:** From `lib/features/consumption/` trip recordings for route overlay
- **Fill-up price:** From `FillUp.totalCost` / `FillUp.liters` for accurate cost
- **Share:** Via `share_plus` (already in pubspec.yaml)
- **Map:** Via `flutter_map` (already in pubspec.yaml)
- **Storage:** Hive box for split history (optional `SyncableRepository` for TankSync)

### 5.8 Test Strategy

| Test | Type | Description |
|------|------|-------------|
| `cost_split_calculator_test.dart` | Unit | Equal: 3 people → 33.3% each; byDistance: partial riders get proportional share; bySegment: overlapping riders correctly split segments; edge cases: 0 km, 1 participant |
| `split_receipt_card_test.dart` | Widget | Renders all participants; amounts sum to total; currency formatting |
| `participant_editor_test.dart` | Widget | Add/remove participants; minimum 2 enforced; name validation |
| `cost_split_screen_test.dart` | Widget | Auto-populate from trip; manual entry; share button |

### 5.9 Estimated Scope

- **New files:** 11 (2 entities, 1 calculator, 1 receipt generator, 1 repository, 3 widgets, 2 screens, 1 provider)
- **Modified files:** 2 (trip detail screen — add action button, `feature.dart` enum)
- **LOC estimate:** ~700 (lib) + ~450 (test)
- **Risk:** Low — no external APIs, no schema migrations, purely additive

---

## Cross-Cutting Concerns

### Feature Flag Registration

All five concepts integrate with the central feature management engine (`lib/features/feature_management/`). Add to `Feature` enum and `FeatureManifest.defaultManifest`:

```dart
// New Feature enum values:
Feature.refuelTimingAdvisor,
Feature.volatilityHeatmap,
Feature.weatherAdvisor,
Feature.telematicsExport,
Feature.costSplit,
```

### ARB Fragment Strategy

Per `feedback_arb_fragment_pattern.md`, new i18n keys go in `lib/l10n/_fragments/<feature>_<locale>.arb`:
- `refuel_timing_en.arb`, `refuel_timing_de.arb`, `refuel_timing_fr.arb`
- `volatility_en.arb`, `volatility_de.arb`, `volatility_fr.arb`
- `weather_en.arb`, `weather_de.arb`, `weather_fr.arb`
- `telematics_en.arb`, `telematics_de.arb`, `telematics_fr.arb`
- `cost_split_en.arb`, `cost_split_de.arb`, `cost_split_fr.arb`

Then run `dart run tool/build_arb.dart` to merge into `app_*.arb`.

### Phased PR Strategy

Per `feedback_phased_pr_rubric.md`, issues >400 LOC split into phased PRs:

| Concept | Est. LOC | Phases |
|---------|----------|--------|
| 1. Refuel Timing | ~400 | 1 phase (just fits) |
| 2. Volatility Heatmap | ~500 | 2 phases: domain+provider → UI+tests |
| 3. Weather Advisor | ~700 | 3 phases: core service → trip integration → UI widgets |
| 4. Telematics Export | ~900 | 3 phases: generator+classifier → export formats → UI+radar |
| 5. Cost Split | ~700 | 2 phases: calculator+entities → UI+receipt+sharing |

### Implementation Priority & Dependencies

```
Phase 1: Refuel Timing Advisor (Concept 1)
  └── Prerequisite: none (extends existing alerts)
  └── Unblocks: nothing

Phase 2: Volatility Heatmap (Concept 2)  ← can run parallel with Phase 1
  └── Prerequisite: none (reads existing price history)
  └── Unblocks: nothing

Phase 3: Weather Advisor (Concept 3)
  └── Prerequisite: none (new core service)
  └── Unblocks: weather-normalised driving score (future)

Phase 4: Cost Split Calculator (Concept 5)  ← can run parallel with Phase 3
  └── Prerequisite: none (reads existing trips/fill-ups)
  └── Unblocks: nothing

Phase 5: Telematics Export (Concept 4)
  └── Prerequisite: sufficient driving data (not code-blocking)
  └── Unblocks: insurance partnerships (business)
```

### Total Scope Summary

| Concept | New Files | Modified Files | LOC (lib) | LOC (test) |
|---------|-----------|----------------|-----------|------------|
| 1. Refuel Timing | 8 | 3 | ~400 | ~300 |
| 2. Volatility Heatmap | 9 | 2 | ~500 | ~350 |
| 3. Weather Advisor | 12 | 4 | ~700 | ~500 |
| 4. Telematics Export | 14 | 1 | ~900 | ~600 |
| 5. Cost Split | 11 | 2 | ~700 | ~450 |
| **Total** | **54** | **12** | **~3,200** | **~2,200** |

---

## Appendix A: Existing Provider Dependency Map

For reference, these are the existing providers that the five concepts consume (read-only):

| Provider | Location | Consumed By |
|----------|----------|-------------|
| `priceHistoryRepositoryProvider` | `lib/features/price_history/` | Concepts 1, 2 |
| `pricePredictionProvider` | `lib/features/price_history/providers/` | Concept 1 |
| `fillUpHistoryProvider` | `lib/features/consumption/providers/` | Concepts 1, 4, 5 |
| `tripHistoryProvider` | `lib/features/consumption/providers/` | Concepts 3, 4, 5 |
| `consumptionStatsProvider` | `lib/features/consumption/providers/` | Concepts 1, 3, 4 |
| `activeVehicleProfileProvider` | `lib/features/vehicle/providers/` | Concepts 1, 3, 4, 5 |
| `drivingScoreProvider` | `lib/features/consumption/providers/` | Concept 4 |
| `userPositionProvider` | `lib/core/location/` | Concepts 1, 2, 3 |
| `fuelStationsProvider` | `lib/features/search/providers/` | Concept 2 |
| `featureFlagsProvider` | `lib/features/feature_management/` | All concepts |
| `notificationServiceProvider` | `lib/core/notifications/` | Concepts 1, 3 |

## Appendix B: Features Deferred from This Document

The following features from May 1–4 analyses are **not** covered here due to higher complexity, external API dependencies, or lower priority, but remain valid candidates for future concept documents:

| Feature | Source | Reason Deferred |
|---------|--------|-----------------|
| CarPlay & Android Auto | May 1 #1 | High effort, native-only code, platform-specific testing |
| Crowdsourced Price OCR | May 1 #2 | Requires Supabase schema + moderation pipeline |
| Community Leaderboard | May 1 #4 | Requires Supabase backend + privacy review |
| Wearable Companion | May 1 #5 | High effort, native watchOS/Wear OS targets |
| Voice-First AI Copilot | May 2 #1 | New dependency (speech_to_text), complex intent parsing |
| Hybrid/EV Energy Optimizer | May 2 #2 | Requires electricity tariff data sources |
| Station Queue Intelligence | May 2 #3 | Requires crowd-sourced Supabase pipeline |
| Multi-Modal Journey Compare | May 2 #4 | Multiple external transit APIs |
| AI Maintenance Predictor | May 2 #5 | Requires service cost database creation |
| Price Arbitrage Alerts | May 3 #1 | Builds on Concept 1; phase 2 candidate |
| Station Reviews | May 3 #2 | High effort (community data + sync + spam prevention) |
| Fleet/Family Groups | May 3 #3 | Supabase schema + multi-user sync complexity |
| Maintenance-Aware Routing | May 3 #4 | Depends on mature maintenance suggestion system |
| Savings Dashboard | May 3 #5 | Medium effort but lower urgency; phase 2 candidate |
| Carbon Offset Marketplace | May 4 #5 | External payment flow complexity |

---

*Generated: 2026-05-05 | Architecture based on Tankstellen v5.0.0 codebase analysis. All file paths verified against current project structure. Implementation estimates assume single developer working in the established branching workflow (GitHub Flow, squash-merge, conventional commits).*
