<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# ADR 0022: One consumption contract — provenance, versions and the pump-gain rule travel with the number (#4230)

**Status:** Accepted
**Date:** 2026-09-16
**Issue:** #4230 (Epic #4222, absorbs #4207's contract part)
**Related:** ADR 0012 (GPS-only live estimator), ADR 0020 (pump-anchored fuel gain), #4160 (`DataValue`)

## Context

Epic #4222 makes fuzzy inference the single production estimation mode.
Its technical-lead contract requires a **mandatory pre-implementation
review**: inspect every current fuel producer and every consumer of
`TripFuelSourceKind`, `FuelConsumptionFigure`, `CalibratedTripFigures`,
`PumpGainResolution`, the ECU fuel-rate/MAF paths, `GpsLiveFuelEstimator`,
`GpsFuelEstimator`, `gps_trip_fuel_backfill` and
`obd2_gps_estimate_fallback`, and produce a producer → contract →
consumer map. This ADR is that map, and the boundary it justifies.

### What already exists

Four contracts, each owning a genuinely different axis:

| contract | axis it owns | where |
|---|---|---|
| `TripFuelSourceKind` | which branch produced the litres | `features/trips/domain/trip_fuel_source.dart` |
| `DataValue<T>` (#4160) | how far a number may be trusted, app-wide | `core/domain/data_value.dart` |
| `PumpGainResolution` | which calibration was applied, from where | `core/domain/pump_gain_resolution.dart` |
| `CalibratedTripFigures` | re-expression at today's gain | `features/trips/domain/calibrated_trip_figures.dart` |

`FuelConsumptionFigure` adds a fifth, narrower one (per-fuel measured vs
modelled) and already bridges to `DataValue` via `asDataValue`.

#4230's merged-in #4207 content is explicit that a **fifth provenance
type must not be added** beside these.

### The producer → contract → consumer map

**Producers** — every place a fuel figure is created:

| producer | what it emits | provenance stamp | gain applied? |
|---|---|---|---|
| `live_sample_snapshot_fuel_rate.dart` | per-sample L/h from PID 9D / A2 / 5E | `pid9D` / `pidA2` / `pid5E` | **never** |
| `live_sample_snapshot_fuel_rate.dart` | per-sample L/h from MAF / speed-density | `maf66` / `maf` / `speedDensity` | **yes, once** (`:254`) |
| `obd2_gps_estimate_fallback.dart` (#2431) | per-sample estimated L/h + trip figures when no fuel PID | GPS-physics | no |
| `gps_trip_fuel_backfill.dart` (#3576) | trip `avgLPer100Km` / litres for gpsOnly trips, batch then live-folder | GPS-physics | no |
| `GpsFuelEstimator` / `GpsLiveFuelEstimator` | the road-load model behind both GPS paths | GPS-physics | no |
| `PhysicsScaleCalibrator`, `GpsMatrixReconciler` | learn `physicsScale` / the GPS matrix | — | learns from trips that already carry `pumpGainApplied` |

**Contract** — `ConsumptionEstimate` (`core/domain/consumption_estimate.dart`):
value as a `DataValue<double>`, `ConsumptionSourceClass`,
`ConsumptionModelVersion`, confidence, the applied gain, and
time/recording identity. The trip vocabulary reaches it through
`TripFuelSourceKindMapping.asConsumptionSourceClass`
(`features/trips/domain/trip_consumption_source_class.dart`).

**Consumers** — who reads a figure today:

| contract | consumers |
|---|---|
| `TripFuelSourceKind` | `fill_up_validation`, `calibrated_trip_figures`, `trip_summary_card`, `fuel_source_chip` |
| `FuelConsumptionFigure` | `fuel_consumption_estimator`, `all_prices_table_provider`, `all_prices_comparison_model`, `data_value` |
| `PumpGainResolution` | `trip_recording_controller_summary`, `live_sample_snapshot_fuel_rate`, `calibrated_trip_figures` |
| `CalibratedTripFigures` | `tank_report`, `monthly_insights_aggregator`, `trip_summary_card`, `fuel_source_chip`, `trajet_row` |

`CalibratedTripFigures.of()` is already the single choke point its own
docstring claims: *"the one helper every surface goes through, so they can
never disagree on a number."*

### What was missing

**Versions.** Nothing in `lib/features/trips`, `lib/core/domain` or
`lib/features/fill_ups` carried a model, rule or calibration version.
`GpsCalibrationMatrix` tracks maturity through
`fillUpReconciliationCount` + `residualVariance` + `lastReconciledAt`
instead. `consumption_source_class_gates_test.dart` records the gap and
assigns it to #4230.

## Decision

**1. One consumer-facing contract, composed rather than invented.**
`ConsumptionEstimate` adds no provenance vocabulary. It composes
`DataValue` (trust), a restated four-case source class (branch),
`ConsumptionModelVersion` (versions) and the applied gain into the single
object the epic requires a consumer to receive.

**2. The source class carries the pump-gain rule.**
`ConsumptionSourceClass.pumpGainApplies` is true for **exactly**
`estimated`. Measured ECU fuel was never multiplied by a gain, and a
GPS-only figure comes from the road-load model the gain does not
calibrate. `ConsumptionEstimate.isConsistent` is false if a gain rides on
either. This is Epic #4222's binding *Source semantics*, expressed as a
property of the domain rather than as an `if` at each call site.

**3. The source classes are restated across the boundary, not shared.**
`feature_boundary_test` pins **core → feature at zero** (#3129), so
`core/domain` cannot import the trip vocabulary. The canonical enum
therefore restates the four cases and the translation lives on the
feature side, with an exhaustive `switch` — a fifth trip kind is a
compile error, not a silent mis-mapping — plus a parity test asserting
equal arity and a total, collision-free mapping in both directions.

**4. Versions are three ordered numbers, not one opaque string.**
Model, rules and calibration move independently. `isOlderThan` orders on
model then rules and **ignores** calibration, which advances per vehicle
and says nothing about which build produced a figure. An unversioned
persisted record decodes to `null` rather than a fabricated `model: 1`.

**5. Absence is stated.** `ConsumptionEstimate.unavailable` requires a
`DataUnknownReason`; `DataValue.map` cannot launder an unknown into a
value. Trust rule 1 — a missing input is stated, never defaulted.

**6. No consumer can select an estimator.** The contract exposes no
`estimator` parameter, strategy enum or `useFuzzy` flag. The producer
decides, stamps what it did, and the consumer reads.

## Consequences

- A figure crossing into a rendering path arrives with its provenance,
  so the `≈` of `docs/specs/refuel-economics.md` trust rule 2 is a
  property of the type rather than of the widget author remembering.
- The pump-gain invariant is now assertable at a boundary
  (`isConsistent`) instead of only inside `CalibratedTripFigures`.
- Stored figures become comparable to what the current build would
  produce, which is what #4234's "historical persisted values remain
  reproducible through version metadata" needs.
- Two enums now describe the same four classes. That is a real cost,
  accepted because the alternative is a core → feature import the
  ratchet pins at zero. The parity test is what makes it safe.
- Nothing is wired yet. This is a contract; #4233 integrates it.

### Explicitly NOT in scope

Removing the legacy paths is **#4234** ("retire legacy estimator
paths"), which depends on #4233 and is gated by the epic's binding
**validation gate**: until #4231's replay shows the fuzzy path is not
worse for a source class, the existing path keeps producing that class's
figure. Deleting a path now would breach that gate.

`VehicleProfile.calibrationMode` (`rule | fuzzy`) is **not** a
consumption-estimator switch and is left alone. Its two branches —
`trip_baseline_recorder.dart:158` and
`calibration_mode_providers.dart:117` — select how a driving-*situation*
baseline vote is recorded (one bucket vs seven weighted memberships,
#894 / #1426 / #779), feeding `FuzzyClassifier` into the Welford
`BaselineStore`. Epic #4222 flags the fate of those situation baselines
as undefined; conflating them with fuel estimation would remove a
working feature under the wrong issue.

## Alternatives Considered

- **Extend `FuelConsumptionFigure` instead.** Rejected: it is the
  per-fuel *comparison* figure (ADR 0015 buckets), keyed by grade over
  plein-to-plein windows — not a per-trip figure with a recording
  identity. Overloading it would conflate two questions.
- **Put the canonical enum in `features/trips` and import it from
  `core`.** Rejected: that is precisely the core → feature import
  #3129 pins at zero.
- **One opaque `modelHash` instead of three integers.** Rejected: a
  hash cannot answer "is this older than mine", which is the question a
  replay and a re-expression both ask.
- **A `ConsumptionEstimate.fromTripSummary` factory in `core`.**
  Rejected for the same boundary reason; the seam belongs on the feature
  side, where the trip vocabulary lives.
- **Defaulting an unversioned record to `model: 1`.** Rejected: it
  claims a provenance the record does not have. Same reasoning
  `TankBlendState` applies to its own `modelVersion`.
