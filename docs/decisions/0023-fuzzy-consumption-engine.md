<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# ADR 0023: The fuzzy consumption engine — physics as input, measured passes through, neutral priors until the corpus is real (#4232)

**Status:** Accepted
**Date:** 2026-09-16
**Issue:** #4232 (Epic #4222, absorbs #4204 and #4228)
**Related:** ADR 0012 (GPS-only live estimator), ADR 0020 (pump-anchored fuel gain), ADR 0022 (canonical consumption contract), #4231 (replay harness), #4233 (integration)

## Context

Epic #4222 makes fuzzy inference the single production estimator for every
figure that is not directly measured. #4232 is the engine: linguistic
variables, membership functions, a rule base and defuzzification, with
bounded output, a confidence and an evidence record.

Three facts shaped it:

1. **The corpus is empty.** #4231 shipped the replay harness but no trace —
   real traces need a car, an adapter and full-to-full fills. So no rule
   consequent or membership parameter can be *fitted*, and any "tuned" number
   would be invented.
2. **The physics is exact given its inputs.** The MAF / speed-density
   arithmetic (`live_sample_snapshot_fuel_rate.dart`: AFR, density, η_v, the
   ethanol / trim rules of #3888) and `GpsLiveFuelEstimator`'s road-load force
   balance are not approximations a fuzzy system should replace. Replacing
   them would *add* error (#4222 audit).
3. **Native ECU fuel is a measurement.** A valid 9D / A2 / 5E reading is
   measured provenance and is never replaced (#4222 *Source semantics*).

## Decision

### 1. A zero-order Takagi–Sugeno residual model over the physics estimate

`FuzzyConsumptionEngine.infer(FuzzyConsumptionInput)` in
`lib/features/trips/domain/fuzzy_consumption/`:

```
strength_i = min over antecedents μ            (AND = min, NOT = 1 − μ)
default    = 1 − max_i strength_i              (implicit physics-prior rule)
multiplier = (default · 1 + Σ s_i · m_i) / (default + Σ s_i)
residual   = (Σ s_i · r_i)               / (default + Σ s_i)
estimate   = clamp(physics · clamp(multiplier, 0.5, 2) + residual, 0, 100 L/h)
```

The physics fuel rate is an **input**. The engine never computes it and
imports no estimator — `fuzzy_engine_structure_test.dart` walks the real import
closure against an allowlist and is mutation-checked.

### 2. Measured passes through

A valid, fresh native reading is the sample's figure, bit-for-bit, whatever the
rule base says (`FuzzyOutputKind.measured`, confidence `null` per ADR 0022).
The fuzzy estimate is still computed when a physics input exists and is
reported beside it as evidence (`inferredFuelRateLPerHour`,
`nativeAgreementRatio`) — this is the per-second residual a future fit trains
on. A stale or invalid native reading is not a measurement; the sample falls to
the estimate.

### 3. The shipped consequents are neutral priors

`FuzzyRuleBase.neutral` (rules version 1) has **every consequent at multiplier
1.0, residual 0.0 L/h**, so it defuzzifies to the physics estimate unchanged for
every input. This is deliberate and pinned by a test. What ships is the
*structure* a fit needs — situations, antecedents, degraded variants, stable
rule ids — and the arithmetic, proven with a test-only non-neutral rule base.

**Fitting awaits #4231's native-fuel-rate traces.** A full-to-full fill yields
one L/100 km per window, which identifies a gain (#4233), not rule weights or
membership parameters (#4222 *Calibration constraint*). A fitted rule base ships
as a new `FuzzyRuleBase` with a bumped `rulesVersion`, compared against the
shipped path in the replay report, and adopted only through the epic's
validation gate.

### 4. Absence is stated; degraded rules are explicit

Every input is validated into `fresh / stale / missing / invalid`. Non-finite,
negative-where-impossible and out-of-domain values are **rejected**, never
clamped into a value that looks real. An unavailable input:

- closes every rule that reads it (listed in `unevaluableRuleIds`);
- opens the **degraded** rules gated on it (`onlyWhenUnavailable`);
- contributes 0 to coverage, lowering confidence.

Without a usable physics input and without a valid native reading the result is
`unavailable` with a `FuzzyUnavailableReason` — never a zero.

### 5. Confidence is an ordinal coverage score, not a probability

```
confidence = ceiling(basis) · freshness(physics) · (0.5 + 0.5 · coverage)
coverage   = mean over the 11 context variables of freshness (0 if not fresh)
freshness  = 1 − age / horizon
ceiling    = maf 1.0 · speedDensity 0.85 · gpsRoadLoad 0.7
```

Monotone in coverage and in freshness (tested). The ceilings follow the
accuracy *order* the corpus README states (air mass tightest, GPS road-load
loosest); they are ordinal priors, not measured accuracies, and calibrating
confidence against pump truth is corpus work.

### 6. Versions

`FuzzyConsumptionEngine.modelVersion = 1` and `FuzzyRuleBase.rulesVersion`
compose into the `ConsumptionModelVersion(model: 1, rules: 1)` every result
carries. Calibration stays `null` — the engine applies no pump gain; #4233
applies it exactly once when it stamps a `ConsumptionEstimate`. The legacy
paths carry no version at all (ADR 0022 decodes that as `null`), so model 1
cannot collide with them.

### 7. `FuzzyClassifier` and its situation baselines stay

`FuzzyClassifier` (`features/vehicle`) is **not** a consumption estimator. Its
only consumer is `trip_baseline_recorder.dart`: when
`VehicleProfile.calibrationMode == fuzzy` a live consumption sample is split
across driving-situation buckets as weighted votes into the Welford
`BaselineStore` (the vehicle baseline section, synced by
`Feature.baselineSync`). `rule` mode records one bucket instead.

That is a *situation-baseline* feature — "what does this car usually burn when
climbing" — and it survives unchanged. Removing it would delete a working,
synced feature under an issue that is about estimation. Whether the
`rule | fuzzy` baseline setting itself should go is a UI/settings decision for
#4234, which owns selection flags; this engine neither reads nor replaces it.

What the engine takes from the classifier is its **membership primitives and
breakpoints**: `trapezoid` / ramp shapes moved to
`core/domain/fuzzy_membership.dart` (the classifier now delegates to them, same
arithmetic), and the table below reuses its edges wherever the semantics match.

### 8. Replay: current vs fuzzy, side by side

`tool/replay_consumption.dart` now replays every eligible trace through the
engine (`tool/replay_consumption_fuzzy.dart`) and prints a second
per-source-class table (MAE / MAPE / signed bias) beside the shipped figure.
Still reporting only, never a gate. With the neutral rule base the fuzzy column
integrates the per-tick native / physics rates; a trace with any uncovered time
is listed as not replayable rather than integrated partially. Samples carry no
grade, yaw rate, stop count or mass, so those replay as missing.

## Linguistic variables

Ruspini partitions: the memberships sum to 1 everywhere in the domain, adjacent
terms overlap, edge terms are monotone. Out-of-domain = `invalid`.

| variable | unit | domain | horizon | terms (breakpoints) | origin |
|---|---|---|---|---|---|
| speed | km/h | 0–400 | 3 s | standstill ↘0–5 · urban 0/5–45\70 · rural 45/70\90 · highway ↗70–90 | `FuzzyClassifier` idle 0–5, urban to 45, highway 70–90; `rural` closes its 60–70 gap |
| accel | m/s² | −15–15 | 3 s | braking ↘−0.5–−0.1 · steady −0.5/−0.1–0.1\1.5 · accelerating ↗0.1–1.5 | classifier decel −0.5 / partial-decel −0.1; `kOscillationAccelMps2` 1.5 (#4203) |
| grade | % (confident only) | −40–40 | 10 s | downhill ↘−8–0 · flat −8/0\8 · uphill ↗0–8 | classifier grade ramp 0–8 %, mirrored |
| curvature | \|yaw\| rad/s | −5–5 | 3 s | straight ↘0.04–0.12 · curving ↗0.04–0.12 | centred on `kCurveYawRateRadPerS` 0.08 (#4203) |
| stops | stops/min | 0–60 | 10 s | flowing ↘0–2 · stopAndGo ↗0–2 | definitional (the classifier's stop-and-go flag is a caller-owned boolean) |
| rpm | rev/min | 0–12000 | 3 s | low ↘1500–2500 · mid 1500/2500\3500 · high ↗2500–3500 | classifier fuel-cut edge 1500 |
| load | % | 0–400 | 3 s | light ↘45–70 · heavy ↗45–70 | classifier load ramp 45–70 % |
| throttle | % | 0–100 | 3 s | closed ↘5–15 · open ↗5–15 | classifier closed-throttle edge 5 % |
| coolantTemp | °C | −50–150 | 60 s | cold ↘40–70 · warm ↗40–70 | classifier cold-start ramp |
| oilTemp | °C | −50–180 | 60 s | cold ↘30–60 · warm ↗30–60 | classifier oil fallback ramp |
| vehicleMass | kg | 300–10000 | static | light ↘1450–1600 · medium 1450/1600\1750 · heavy ↗1600–1750 | `VehicleRoadLoadParameters.compactMaxKg` / `midsizeMaxKg` (#4209) |

Restated constants are pinned to their owners by
`fuzzy_variables_test.dart`. Fuel-rate inputs (physics and native): 0–100 L/h,
horizon 3 s.

## Rule base (rules version 1, all consequents neutral)

| id | IF | degraded — fires only when unavailable |
|---|---|---|
| `idle` | speed standstill ∧ rpm low | |
| `idle-d` | speed standstill | rpm |
| `urban-cruise` | speed urban ∧ accel steady ∧ stops flowing | |
| `stop-and-go` | speed urban ∧ stops stopAndGo | |
| `rural-cruise` | speed rural ∧ accel steady ∧ grade flat | |
| `highway-cruise` | speed highway ∧ accel steady ∧ grade flat | |
| `highway-high-rpm` | speed highway ∧ rpm high | |
| `accel-loaded` | accel accelerating ∧ load heavy | |
| `accel-throttle-d` | accel accelerating ∧ throttle open | load |
| `accel-kinematic-d` | accel accelerating | load, throttle |
| `accel-heavy-vehicle` | accel accelerating ∧ mass heavy | |
| `climb-loaded` | grade uphill ∧ load heavy | |
| `climb-d` | grade uphill | load |
| `climb-heavy-vehicle` | grade uphill ∧ mass heavy | |
| `descent-overrun` | grade downhill ∧ throttle closed | |
| `overrun` | throttle closed ∧ ¬rpm low ∧ ¬speed standstill | |
| `braking-d` | accel braking | throttle, rpm |
| `curve-transient` | curvature curving ∧ ¬accel steady | |
| `cold-engine` | coolant cold | |
| `cold-engine-oil-d` | oil cold | coolant |

Every rule is proven reachable at full strength by `fuzzy_rule_base_test.dart`
(the #2513 dead-bucket lesson applied to rules).

## Consequences

- #4233 has a pure, deterministic engine to wire: build a
  `FuzzyConsumptionInput` per sample, take `fuelRateLPerHour` +
  `sourceClass` + `version`, apply the pump gain once to `estimated`.
- Shipping it changes no production figure: nothing calls it yet, and the
  neutral rule base reproduces the physics exactly.
- The replay report is ready to show current vs fuzzy the moment real traces
  land.
- Weather is not an input: no weather source exists and paid services are
  excluded (#4222 audit); OBD2 ambient / baro already reach the physics.

### Explicitly NOT in scope

- Wiring into producers or `ConsumptionEstimate` consumers — #4233.
- Retiring GPS matrix / physics-scale paths or the `rule | fuzzy` setting —
  #4234, behind the validation gate.
- Any fitted consequent, membership parameter or confidence calibration —
  needs #4231's real traces.

## Alternatives Considered

- **Mamdani inference with fuzzy output sets (centroid).** Rejected: the output
  is a correction to a physical quantity, and a Sugeno weighted mean keeps the
  neutral case exactly equal to the physics, is cheap per 1 Hz tick and trivially
  bounded.
- **Replace the physics with a fuzzy rate model.** Rejected: it discards exact
  arithmetic and adds approximation error (#4222 audit).
- **Seed consequents from engineering folklore (e.g. +15 % cold start).**
  Rejected: an unfitted number presented as a model is what the validation gate
  exists to refuse; the air-mass branches already see warm-up enrichment
  through commanded φ and the fuel trims.
- **Delete `FuzzyClassifier`.** Rejected — see §7.
- **Put the engine in `core/domain`.** Rejected: it is feature logic; only the
  membership primitives, shared by two features, belong in the kernel.
