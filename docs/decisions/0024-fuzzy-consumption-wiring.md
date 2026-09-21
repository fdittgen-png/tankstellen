<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# ADR 0024: Wiring the fuzzy engine — one per-sample stage, the gain once, the version on the trip (#4233)

**Status:** Accepted
**Date:** 2026-09-16
**Issue:** #4233 (Epic #4222)
**Related:** ADR 0020 (pump-anchored fuel gain), ADR 0022 (canonical consumption contract), ADR 0023 (the fuzzy engine), #4231 (replay harness), #4234 (legacy retirement), #4321 (measured trips carry an unapplied gain)

## Context

ADR 0023 shipped a pure fuzzy engine nothing called, and ADR 0022 a
`ConsumptionEstimate` contract nothing produced. #4233 connects them to the
producers and to the consumers without breaking three binding rules of Epic
#4222:

1. **Source semantics.** A valid native ECU reading (PID 9D / A2 / 5E) is
   measured: never refined, never scaled by the pump gain. Every other
   figure is the fuzzy estimate, with the per-fuel pump gain applied exactly
   once.
2. **Validation gate.** Until #4231's replay shows the fuzzy path is not
   worse than the shipped figure for a source class, the shipped path keeps
   producing that class's figure; only #4234 retires a path.
3. **No selector.** No user setting, `Feature` flag or runtime mode may pick
   between estimators.

The corpus is still empty, so the engine ships with the **neutral** rule
base: every consequent is multiplier 1.0, residual 0.0 L/h. For every
in-range physics input the engine returns that input unchanged.

## Decision

### 1. One pure per-sample stage, one production engine

`features/trips/domain/fuzzy_consumption/fuzzy_fuel_rate_stage.dart`:

- `refinedFuelRateLPerHour(physics, basis, {context})` builds the
  `FuzzyConsumptionInput`, runs the engine once and returns the refined L/h.
  It returns **the original double** when the engine declines (an input it
  rejects: above 100 L/h, negative or non-finite) or when its output `==` its
  input.
- `estimatedFuelRateLPerHour(physics, basis, {pumpGain, context})` is that
  times the pump gain. It is **the only place in `lib/` where a pump gain
  multiplies an estimate**. The engine sees the rate before the gain, so a
  fitted rule base can never compound with the calibration. GPS road-load
  refuses a gain (an assert; ADR 0022 §2).

`production_fuzzy_engine.dart` holds `const kProductionFuzzyEngine`, the
**only** construction site of an engine or a rule base outside the engine's
own declarations. The stage's `engine:` parameter defaults to it; only tests
pass another.

### 2. Where the stage runs — the live producers, once per sample

| producer | branch | through the stage | context passed |
|---|---|---|---|
| `live_sample_snapshot_fuel_rate.dart` | MAF 0x66 / 0x10 | `estimatedFuelRateLPerHour(…, maf)` | speed, rpm, load, throttle, coolant, oil with their **real latch ages** (#4159 `SignalLatchStore.arrivedAt`); curb weight as mass |
| same | speed-density | `…(…, speedDensity)` | same |
| same | 9D / A2 / 5E | **never** — returned before the stage | — |
| `gps_live_fuel_estimator.dart` | road-load | `refinedFuelRateLPerHour(ṁ·3600, gpsRoadLoad)` | speed and the low-passed accel of this tick (age 0), grade only when confident, mass only when the vehicle supplied it |

A pull-mode `obd2_fuel_rate_reader.dart` was wired the same way in #4233.
It had no caller in `lib/` and was deleted in #4315 (see the amendment
below).

The GPS seam feeds everything built on `GpsLiveFuelEstimator`: the live
folder, the no-fuel-PID OBD2 fallback and the `PhysicsScaleCalibrator`
replay. Its result is applied as `refined == physics ? ṁ : refined / 3600`,
so the L/s ↔ L/h round trip cannot move a bit.

**Summary time never calls the engine again.** A trip figure is a sum of
samples that already went through it; a second call would apply a fitted
rule base twice.

### 3. The pump gain, exactly once

Resolution is unchanged (`resolvePumpGain`, #3918 / #4220). The
multiplication moved into the stage. `lastPumpGainResolution` and the
`pumpGainApplied` stamp keep their meaning, so no lifecycle file changes.
The stage test proves 10 L/h × rule 1.25 × gain 0.8 = 10.0, not the 8.0 a
squared gain or a post-gain engine input would give. F2 — measured trips are
stamped with a gain they never carried, and the learner divides it back out
— changes calibration numbers, so it is its own fix (#4321), not part of
this refactor.

### 4. The validation gate is satisfied by identity

The rules are neutral, so the fuzzy output **is** the shipped figure, bit
for bit, for every sample: in range the engine returns its input, out of
range the stage keeps the input. `consumption_identity_goldens_test.dart`
captured float64 bit patterns of every stream **before** the wiring. That
covers the live snapshot over an 18-case × 4-vehicle raw-frame matrix, the
GPS estimator, folder, backfill, fallback and calibrator, and the recorder
summary. The test stays green and unedited across every #4233 commit. The
pull reader's 72 entries were removed later, deliberately, with the reader
itself (#4315); no other entry changed.

This is why no legacy path is retired here. The gate is met because nothing
moved, not because the fuzzy path was shown better. A fitted rule base must
pass #4231's replay before it replaces `kProductionFuzzyEngine`, and
retirement stays with #4234.

### 5. The version travels on the trip

`TripSummary.consumptionVersion` (`ConsumptionModelVersion?`), codec key
`cmv`, omitted when null. A legacy trip, or a malformed value, decodes to
null (ADR 0022 §4). The same codec serves the Hive history, the active WAL,
paused trips and TankSync. `trip_summaries.data` is JSONB, so **no Supabase
schema change** is needed: `schema_verifier` checks tables, not JSON keys,
and `kSupabaseSchemaVersion` stays 12.

The stamp comes from one pure function, `tripConsumptionVersion`
(`trips/domain/trip_consumption_provenance.dart`), called by the two
stop-time finalisers **outside** the lifecycle files, and only on the figure
each one produced:

- `Obd2GpsEstimateFallback.fillWhenNoFuelPid`, when it fills the trip;
- `backfillGpsTripFuel`, on the live-folder figure only. The batch
  `GpsFuelEstimator` fits a whole trip at once, has no per-sample inputs and
  never passes through the engine, so its figure stays **unversioned** until
  #4234 (F5).

**Calibration generation.** `calibration` is the resolved gain's `samples`
only when that gain is calibrated **and** equals the trip's
`pumpGainApplied`. Otherwise it is null, and this ADR amends ADR 0022's
reading of null from "never calibrated" to **"not attributable to a
fill-anchored generation"**. Both GPS finalisers therefore stamp a null
calibration: a road-load figure carries no pump gain.

### 6. The contract carries a possibly-absent version

`ConsumptionEstimate.version` becomes nullable, including on `unavailable`.
A figure from a path that never stamped one (legacy trips, the batch GPS
estimator, OBD2 trips finalised in the lifecycle files) says so instead of
inventing `model: 1`.

`tripConsumptionEstimate(summary, vehicle, {fuelKey, recordingId})`
(`trips/domain/trip_consumption_estimate.dart`) is the trip → contract
adapter, built on `CalibratedTripFigures.of`, so it can never disagree with
the tank report:

| trip kind | value | `pumpGain` | version |
|---|---|---|---|
| measured | `measured(stored)` | null, whatever `pg` says | stored |
| estimated | `estimated(re-expressed, derived)` | the gain the figure is expressed at | stored; calibration = current `samples` when re-expressed |
| gps | `estimated(avg ?? eAvg, derived)` | null | stored |
| none with a figure (F4) | `estimated(figure, derived)` | null | stored |
| none | `unknown(notMeasuredYet)` | null | stored (normally null) |

F4 is a known gap. An OBD2 trip whose car supports no fuel PID carries the
GPS fallback's figure, but `tripFuelSourceKind` classes it `none`. The
adapter reuses that single classification rather than inventing a second one.

### 7. Consumers read through the adapter, rendering unchanged

The trip summary card, the trip row and the driving-analysis trace read the
L/100 km through `tripConsumptionEstimate`. The adapter's value is exactly
the number shown before (`figures.lPer100Km ?? estimatedAvgLPer100Km`), and
the `~` prefix kept its old rule: only when there is no stored
`avgLPer100Km`.

A GPS-only trip's **batch** figure is classed `estimated`, so a DataValue-driven
renderer would add `≈`, and at the time of writing it rendered plain — a
visible change needing a product decision.

**Superseded by #4330:** the decision is taken. The card and the row render
through the contract's own provenance (`DataValue.qualify`), so every
estimated figure — GPS batch, GPS live, MAF / speed-density — carries the
one `≈` of `dataApproximate`, and only a measured figure is left bare. The
old rule marked a figure by the accident of a null stored `avgLPer100Km`,
which hid the estimate in exactly the cases the contract exists to name.
`trip_consumption_rendering_test.dart` pins the new rendering case by case.

The trace export gains `consumptionSource` and `consumptionVersion` beside
the unchanged `avgLPer100Km`. The change is additive, so the schema stays
5, as it did for #4203's and #4205's blocks.

### 8. No estimator can be selected — enforced

`test/lint/single_consumption_estimator_test.dart`, mutation-checked in
memory:

1. `FuzzyConsumptionEngine(` / `FuzzyRuleBase(` / `FuzzyRuleBase.neutral` in
   `lib/` appear only in the binding and the engine's own declarations, and
   every `engine:` argument is a same-name forward of a test seam;
2. the real import closure of the stage, the binding, the adapter, the
   provenance function and the GPS estimator reaches no feature flag,
   settings, provider or `calibrationMode` code;
3. no `Feature` value names an estimator;
4. `* pumpGain` appears only in the stage.

## Consequences

- Every estimated fuel rate the app produces now passes through the fuzzy
  engine, and a fitted rule base changes those figures in exactly one place.
- Nothing a user sees changed. The identity goldens prove it for every
  producer.
- GPS-fallback and live-folder trips carry `cmv`, so #4234 can tell a
  fuzzy-era figure from a legacy one.

### Deferred, with where they land

- **Stamp in `_finaliseSummary`** (`trip_recording_controller_summary.dart`).
  That covers OBD2 measured/estimated trips, the grace-window expiry, the
  recovered snapshot and the paused recovery. These lifecycle files are
  being rewritten by another agent, so they had zero edits here. The
  follow-up is one `tripConsumptionVersion(…)` call beside the existing
  `pumpGainApplied` stamp.
- **The live `TripLiveReading` estimate**: its emit code is lifecycle code.
- **Backup XML** (F8) already drops `pg` / `pgk` / `dfs`; `cmv` joins that
  follow-up.
- **Tank report, `PumpGainLearner`, `FillUpValidation`** keep reading
  `CalibratedTripFigures`. Their numbers are unchanged, and fill-up truth
  stays authoritative.
- **The replay tool** (F7) feeds the stored rate as the physics input. Once
  a fitted rule base ships, it must read the trip's `rules` version rather
  than refine `f` twice.
- **Retirement** of the batch GPS estimator, the matrix and the physics
  scale is #4234, behind the gate.

## Amendment (2026-09-16, #4315) — the live snapshot is the only speed-density implementation

`Obd2FuelRateReader` / `Obd2Service.readFuelRateLPerHour` had no caller in
`lib/` since #863. Its tests stayed green on behalf of a path no recorded
trip ever took. It was also the only user of the #1625 η_v(rpm) curve and
of the catalog displacement fallback. The live chain passes a flat η_v and
falls back to 1000 cc.

The maintainer chose deletion over porting the curve into the live branch:
porting would change fuel figures for speed-density-only cars, and that
belongs behind Epic #4222's validation gate. So:

- `LiveSampleSnapshot.deriveFuelRateLPerHour` is the only fuel-rate and
  speed-density implementation. Its figures did not change: every
  `live/`, GPS and summary identity golden is byte-identical, and only the
  72 `pull/` entries left the goldens.
- The reader, its diagnostics collaborator, its fuzzy context, its read
  port and the precision / mixture read primitives only it called were
  deleted. The older typed reads (`readRpm`, `readMafGramsPerSecond`, …)
  stay as the service's read API. The #1625 curve
  (`etaVCurveFor`, `interpolateEtaV`, the estimator's `etaVCurve` parameter)
  went with them.
- The #1625 η_v curve may return later as an input to the fuzzy engine,
  once #4231's replay corpus can show it improves the figure.
- The chain assertions that ran through the reader now run through the live
  snapshot (`live_sample_snapshot_fuel_chain_test.dart`).

## Alternatives Considered

- **Call the engine at summary time.** Rejected. Trip figures are sums of
  per-sample rates, so a second pass double-applies a fitted rule base.
- **Pass latch values at age 0.** Rejected. A hold-last value can be
  seconds old behind the 15 s engine fence, and ADR 0023 §4 says absence
  and staleness are stated. #4159 made the arrival times available, so
  real ages are passed.
- **Apply the gain inside the engine.** Rejected. The engine is
  calibration-free by design (ADR 0023 §6); the gain is a per-vehicle,
  per-fuel fact the producer resolves.
- **Stamp the version in the lifecycle files now.** Rejected for this
  change: those files are under concurrent rewrite. The pure provenance
  function makes the follow-up one call.
- **Render the adapter's `DataValue` directly.** Rejected for now. It would
  add `≈` to GPS batch figures, a visible change #4233 must not make on its
  own.
