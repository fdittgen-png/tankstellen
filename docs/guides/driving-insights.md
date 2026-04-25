# Driving insights — counterfactual model

Phase 1 of #1041 introduces an analytical layer that turns a trip's raw OBD2
samples into "Top-3 cost lines" — quantified bullets such as
"12% of trip above 3000 RPM: +0.6 L wasted". This file documents the
model so future contributors can refine the formulas without spelunking
through the analyzer.

## Inputs

The analyzer (`lib/features/consumption/data/driving_insights_analyzer.dart`)
is a pure function that consumes a `List<TripSample>` produced by
`TripRecorder` (`lib/features/consumption/domain/trip_recorder.dart`).

Each `TripSample` exposes:

- `timestamp` — sample wall-clock time
- `speedKmh`
- `rpm`
- `fuelRateLPerHour` (nullable — many cars don't expose PID 5E)

Phase 1 deliberately ignores throttle, MAF, coolant temp, and elevation
even when present. Those feed Cards C/D/E in later phases (#1041 phase 3).

## Categories

### High-RPM cost (`labelKey: insightHighRpm`)

Waste accumulates whenever a sample's RPM exceeds 3 000. Per interval:

```
wastedLiters += (measuredRate − counterfactualRate) × Δt / 3600
counterfactualRate = measuredRate × 0.6
```

The 0.6 ratio approximates "the same speed at moderate RPM would have
used ~60% of the fuel". When no `fuelRateLPerHour` samples are
available during the high-RPM windows, the analyzer falls back to a
synthetic 6 L/h baseline so the cost line still surfaces — flagged in
metadata so phase 2 UI can label it as an estimate.

### Hard-acceleration cost (`labelKey: insightHardAccel`)

Counts intervals where Δspeed/Δt ≥ 3.0 m/s². Each event adds a
documented constant of **0.05 L** (≈ 50 mL) of wasted fuel — the
order-of-magnitude figure cited in fleet-telematics literature for
"punching the throttle vs smooth acceleration to the same target
speed". Phase 3 will refine this with throttle-position data.

### Idling cost (`labelKey: insightIdling`)

Counts intervals where `speedKmh <= 0.5` AND `rpm > 0`. Idle is
attributed 100% wasteful — every drop is avoidable by switching the
engine off. Wasted liters = idle_time × idle_fuel_rate. The rate
defaults to **0.6 L/h** (typical petrol passenger-car warm idle at
700-900 RPM) when measured fuel-rate samples are unavailable.

## Noise floor

Categories below **0.05 L** are dropped — they're indistinguishable
from sensor noise and would clutter the UI without coaching value.

## Top-N

The analyzer sorts candidates by `litersWasted` descending and returns
at most **3** entries. This is the focused list the UI renders as the
"Top-3 cost lines" card (#1041 phase 2 — not yet implemented).

## Output shape

Each cost line is a `DrivingInsight`
(`lib/features/consumption/domain/driving_insight.dart`):

| Field | Meaning |
| --- | --- |
| `labelKey` | Stable l10n key — phase 2 maps to the user's locale |
| `litersWasted` | Estimated litres above the counterfactual |
| `percentOfTrip` | Time/distance share relevant to this category |
| `metadata` | Per-category supporting numbers (e.g. `aboveRpm: 3000`, `eventCount: 4`) |

## What's deferred

Phase 1 is the **pure analytical layer only**. The following are
explicitly out of scope and tracked under #1041 phases 2-5:

- **Phase 2** — Trip-detail Insights tab UI consuming `DrivingInsight`
  values, ARB strings for each label key, and integration with the
  existing baseline store.
- **Phase 3** — Card A (driving score), Card C (throttle/RPM
  histograms), Card D (cold-start cost), Card E (elevation-adjusted
  score).
- **Phase 4** — Aggregates surface ("this month vs last month") on the
  consumption tab landing screen.
- **Phase 5** — Achievement hooks (`smoothDriver`, `coldStartAware`,
  `highwayMaster`) tied into #781.

When refining the model, please add a test fixture that captures the
behaviour you're correcting before changing the formula — the analyzer
is plain Dart, fully unit-testable, and the existing tests live in
`test/features/consumption/data/driving_insights_analyzer_test.dart`.
