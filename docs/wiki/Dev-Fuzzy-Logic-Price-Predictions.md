# Fuzzy Logic Price Predictions

> **Naming disclosure:** the feature is marketed as "fuzzy learning" because the thresholds are soft and the recommendation is hedged ("prices *typically* drop ..."). The **actual implementation is statistical, not fuzzy logic in the academic sense**: no membership functions, no rule base, no defuzzification. This page documents what the code really does.

## Goal

Tell the user *"at this station, prices are typically cheapest on Tuesday between 18:00 and 20:00"* once enough data has accumulated locally. No server round-trips. No prediction of the future — only summarisation of the recent past.

## Data pipeline

```
(search / background task fires)
       │
       ▼
PriceRecord { stationId, recordedAt, e5, e10, e98, diesel, lpg, cng, ... }
       │
       ▼ (60-min dedup per station)
PriceHistoryHiveStore                           30-day rolling window
       │
       ▼ (pricePredictionProvider)
Bucket by hour-of-day AND weekday
       │
       ▼
PricePrediction { bestHour, bestDayOfWeek, potentialSaving, recommendation }
       │
       ▼
BestTimeBanner + HourlyPriceChart
```

## Data model

### `PriceRecord`
`lib/features/price_history/data/models/price_record.dart:6`

Freezed, one record per station per recording event:

```dart
@freezed
class PriceRecord with _$PriceRecord {
  const factory PriceRecord({
    required String stationId,
    required DateTime recordedAt,
    double? e5, double? e10, double? e98,
    double? diesel, double? dieselPremium, double? e85, double? lpg, double? cng,
  }) = _PriceRecord;
}
```

Partial-availability tolerant (nullable per fuel type).

### `PricePrediction`
`lib/features/price_history/data/models/price_prediction.dart:27–55`

```dart
class PricePrediction {
  final String recommendation;          // "Prices typically drop Tuesday 18-20"
  final double? potentialSaving;        // in currency units / L, null if < 0.001
  final int bestHour;                   // 0-23
  final int bestDayOfWeek;              // 1 = Mon … 7 = Sun (ISO weekday)
  final List<HourlyAverage> hourlyAverages;
  final List<DayOfWeekAverage> dailyAverages;
}
```

`HourlyAverage { hour, avgPrice, sampleCount }` and `DayOfWeekAverage { dayOfWeek, avgPrice, sampleCount }` preserve the raw bucket data so the chart widgets can render.

### `PriceStats` (separate, for summary)
`lib/features/price_history/domain/entities/price_stats.dart:1–22`

```dart
class PriceStats { double? min, max, avg, current; PriceTrend trend; }
```

`PriceTrend`: `up` if current − avg > 0.5 ¢/L, `down` if < −0.5 ¢/L, else `stable`.

## Recording pipeline

### Write site 1 — search results
`lib/features/price_history/providers/price_recorder.dart:10–31`

After every successful station search, `recordSearchResults(stations)` iterates and fires non-awaited `repo.recordPrice(record)` calls. Fire-and-forget so the search UI is not blocked.

### Write site 2 — manual refresh on station detail
`station_detail/presentation/widgets/price_history_section.dart:42–55`

Refresh button → `repo.recordPrice()`.

### Write site 3 — background task
`lib/core/background/background_service.dart:181–220`

Every 30 min (charging) or 60 min (battery) the WorkManager job:

1. Fetches batch prices for all favorites + alert stations.
2. Builds a `PriceRecord` per station with the current timestamp.
3. Writes via dedup-aware `repo.recordPrice()`.
4. Trims records older than 30 days on the same save (lines 211–215).

### Deduplication

`price_history_repository.dart:23–35`

```
records = storage.load(stationId)    // newest first
if records.isNotEmpty &&
   now - records.first.recordedAt < 60 min:
  return   // drop silently
else:
  insert at head, save
```

Hardcoded 60-minute window. This is why a station visited 5× in 10 min produces exactly one new record.

## Bucketing & aggregation

`lib/features/price_history/providers/price_prediction_provider.dart:48–76`

Two independent buckets, populated in a single pass:

```dart
final hourBuckets = <int, List<double>>{};   // 0..23
final dayBuckets  = <int, List<double>>{};   // 1..7
for (final p in pairs) {
  hourBuckets.putIfAbsent(p.time.hour, () => []).add(p.price);
  dayBuckets.putIfAbsent(p.time.weekday, () => []).add(p.price);
}
```

Per-bucket rollup = **arithmetic mean only**, rounded to 4 decimals:

```dart
final avg = values.reduce((a, b) => a + b) / values.length;
```

No median, no percentiles, no recency weighting. An hour with 2 samples counts the same as an hour with 50.

## Prediction decision

`price_prediction_provider.dart:81–99`

```dart
final cheapestHour     = hourlyAverages.reduce((a, b) => a.avgPrice <= b.avgPrice ? a : b);
final mostExpensiveHour = hourlyAverages.reduce((a, b) => a.avgPrice >= b.avgPrice ? a : b);
final cheapestDay      = dailyAverages.reduce((a, b) => a.avgPrice <= b.avgPrice ? a : b);

final hourlySaving = mostExpensiveHour.avgPrice - cheapestHour.avgPrice;
final potentialSaving = hourlySaving > 0.001
  ? double.parse(hourlySaving.toStringAsFixed(3))
  : null;

final recommendation =
  "Prices typically drop ${dayName(cheapestDay)} $bestHour-${bestHour+2}";
```

Emits a recommendation iff `potentialSaving` exceeds ~0.1 ¢/L. Below that, the banner stays hidden (a 0.05 ¢/L saving is within noise).

## The learning phase

Three early-exit gates, any of which returns `null` and hides the banner:

```dart
// 1. 30-day window
final history = await repo.getHistory(stationId, days: 30);
if (history.length < 10) return null;

// 2. fuel-type-filtered pairs
final pairs = history
    .where((r) => r.priceFor(fuelType) != null)
    .map((r) => (time: r.recordedAt, price: r.priceFor(fuelType)!))
    .toList();
if (pairs.length < 10) return null;

// 3. bucketing produced anything
if (hourBuckets.isEmpty || dayBuckets.isEmpty) return null;
```

**The "fuzzy learning phase" is the period during which gate 1 or 2 returns `null`.** There is no percentage bar, no progress indicator — the UI simply omits the banner until the threshold is crossed.

### Expected warmup times

| Access pattern | Records / day | Days to 10 |
|---|---|---|
| User opens app and searches this station daily | 1 | 10 |
| Station is favorite (background fetch every 1 h) | ~12 | ~1 |
| Station is alert target (background fetch every 30 min on charging) | up to 24 | < 1 |
| Station rarely searched | <1 | can exceed 30 days → never reach threshold |

## TTL / staleness

- **Window**: hardcoded 30 days.
- **Retention**: background task prunes records older than 30 days on every save.
- **Oldest usable data**: at most 30 days.
- **No recency weighting**: a 29-day-old data point and a 1-hour-old one count equally.
- **No "prediction stale" flag**: once gates pass, the banner shows. If the station stops being searched, the banner uses increasingly old data until records expire.

## UX surfaces

### `BestTimeBanner`
`lib/features/price_history/presentation/widgets/best_time_banner.dart`

Rendered on station detail, above the chart. `SizedBox.shrink()` when `prediction == null`. Content: lightbulb icon, recommendation string, and the saving in currency if `potentialSaving > 0`.

### `HourlyPriceChart`
`hourly_price_chart.dart`

140 dp bar chart, 24 bars. Cheapest bar green, most-expensive red, others primary-color at 60 % alpha. X-axis labels every 3 hours. Empty state: "No hourly data".

### `PriceStatsCard`
Min/max/avg/current + trend arrow. Uses `PriceStats`, separate from `PricePrediction`.

## Limitations & honest caveats

1. **Not a forecast.** This is descriptive statistics on your local history. No ML, no oil-market signal, no day-ahead prediction.
2. **No confidence interval.** Two samples in a bucket carry the same weight as fifty. Very low sample counts per bucket are noise.
3. **No outlier detection.** One anomalous price (a data source glitch) can skew a bucket average for a month.
4. **Per-station, per-fuel.** There is no cross-station learning and no cross-user learning.
5. **Weekly seasonality only.** No quarterly, holiday, or crude-oil correlation.
6. **Deterministic, not probabilistic.** `reduce(min)` / `reduce(max)` always selects the extreme bucket, regardless of variance.

## Possible future work

| Improvement | Effort | Payoff |
|---|---|---|
| Sample-count weighting (require ≥3 samples per bucket before use) | small | fewer false-positive banners |
| Trimmed mean or median per bucket | small | outlier robustness |
| Recency decay (half-life ~14 days) | small | faster adaptation to structural changes |
| Confidence labelling ("High confidence" / "Low confidence") | medium | honest UX |
| Per-country seasonality priors (wholesale calendar) | medium-high | forecasting, not just summarisation |

If you want to attempt any of these, open an issue labelled `area/predictions` and link back to this page.

## Related

- [Storage & Sync](Dev-Storage-Hive-Sync) — where PriceHistoryHiveStore fits in the Hive layer
- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — how search results flow to the recorder
