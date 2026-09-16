<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Consumption replay corpus (#4231, Epic #4222)

This directory holds recorded trips the replay harness
(`tool/replay_consumption.dart`) measures the consumption estimator
against. **It currently holds no traces** — only this document.

That is deliberate, and it is the honest state rather than an oversight.

## Why it is empty

#4231 requires *real* recordings: at least one per fuel-source branch
(native fuel rate, MAF, speed-density, GPS-only, mixed coverage), each
with a valid full-to-full fill-up for ground truth. Producing them needs
a vehicle, a paired OBD2 adapter, drives spanning each source class, and
fills at both ends of each window.

Synthetic traces would satisfy the letter of "a corpus exists" and
destroy its purpose: the epic's **validation gate** exists to arbitrate
the fuzzy path against *real pump truth*, and a corpus written by the
same process being validated cannot arbitrate anything.

So the harness ships first. When the recording session happens, traces
drop in here and the command reports on them with nothing further to
build.

## Trace format

Two files per trace, both already the app's canonical encodings — no
conversion step:

```
<name>.summary.json     one tripSummaryToJson object
<name>.samples.ndjson   one sampleToJson object per line
```

`<name>` is free-form but stable; the harness sorts by it so reports are
deterministic. A `.summary.json` without a matching `.samples.ndjson` is
**not** a trace and is skipped — half a trace cannot be replayed.

A torn final line in the NDJSON is skipped and every other sample
survives, the same rule `parseActiveTripWalFile` applies to the live WAL
(one torn write per hard kill is expected).

### The summary carries the truth

Ground truth is a field the recording cannot produce — it comes from the
pump:

| key | meaning |
|---|---|
| `truthLitres` | litres added at the closing full-to-full fill. **Required** for a trace to contribute error. |
| `distanceKm` | distance over the window |
| `fuelLitersConsumed` / `eFuel` | what the shipped pipeline produced, for the not-worse comparison |
| `pgk`, `pg` | the fuel key the gain was resolved under, and the gain applied (#4220, #3887) |
| `dfs` | dominant fuel source — the branch that produced most ticks (#3919) |
| `distanceSource` | `real` (odometer) or `virtual` (speed-integrated) |
| `kind` | `gpsOnly`, else absent for `gpsPlusObd2` |

All of these must be **retained** through anonymisation. None of them
locates anybody.

## Anonymisation — before commit, not after

#4231: *"removing/offsetting absolute coordinates and timestamps"*. The
harness **refuses to report** on a trace that still carries coordinates
and names it in an `⚠ Anonymisation failed` section, so a leak is loud
rather than silent.

| key | action | why |
|---|---|---|
| `la` latitude | **remove** | locates the driver |
| `lo` longitude | **remove** | locates the driver |
| `al` altitude | may stay | a metre figure alone locates nobody, and grade features need it |
| `t` timestamp | **offset by ONE constant per trace** | see below |

The timestamp rule is the one that is easy to get wrong. `t` is
milliseconds since epoch, and the replay derives `dt` between
consecutive samples — so the offset must be a **single constant applied
to every sample in the trace**. Re-randomising per sample, or rounding
each one, destroys the inter-sample spacing and with it the
acceleration term, the idle integration and the gap detection. Subtract
the trace's own first timestamp (making it start at 0) and the spacing
is preserved exactly.

Nothing else in `sampleToJson` is identifying: speeds, RPM, engine load,
temperatures, fuel trims, MAF/MAP, φ, ethanol %, pedal and battery
voltage describe the car, not the person or the place.

## Validity gates

A trace must clear the same gates `PhysicsScaleCalibrator` applies before
it will trust a trip as ground truth. Reused verbatim rather than
re-chosen, so a trip production refuses to learn from cannot become a
corpus entry under looser rules:

| gate | value |
|---|---|
| minimum distance | 2.0 km |
| minimum duration | 120 s |
| minimum samples | 10 |
| maximum sample gap | 60 s (longer is a gap, not a tick) |
| plausibility band | 0.5 – 30.0 L/100 km |

A trace that fails one is still loaded and counted for **coverage**, and
the report lists it with the reason it cannot contribute **error**. That
distinction matters: it tells whoever is recording which drive to repeat.

## Regression thresholds, per source class

#4208's merged-in content is explicit that thresholds are *"per source
class, not one global number"*. The classes, and why one number would be
wrong:

| source class | what it is | expected accuracy |
|---|---|---|
| `measured` | native ECU fuel rate (PID 9D / A2 / 5E) | tightest — the ECU is metering fuel. Error here means a mis-scaled PID implementation, not model error. |
| `estimated` | MAF / speed-density, pump-gain corrected | looser — an air-mass estimate through AFR, density and η_v, anchored by the learned gain |
| `gpsOnly` | road-load physics, no engine data | loosest — mass, CdA, rolling resistance and efficiency are priors, not measurements |
| `none` | no provenance stamps at all | not an accuracy class; a recording defect to investigate |

**Numeric thresholds are deliberately not set here yet.** Setting them
before a single real trace exists would be inventing the answer: a
threshold is only meaningful once measured against recordings, and the
first honest number comes from the first corpus. The harness reports MAE
in litres, MAPE and **signed bias** per class so the thresholds can be
chosen from data — and bias is reported with its sign because a
consistently high estimate is a different defect from a noisy one, and
averaging absolutes hides it.

When thresholds are set, they belong here beside the classes, and the
gate that enforces them belongs to #4234's retirement step — not to this
harness, which is read-only reporting and must never become CI
enforcement (the same standing constraint `tool/ratchet_report.dart`
carries).

## Running it

```sh
dart run tool/replay_consumption.dart
dart run tool/replay_consumption.dart --corpus path/to/other/corpus
```

Read-only. Writes nothing, touches no network, needs no UI — and is
tested in-process by `test/tool/replay_consumption_test.dart` (never
spawned, #3752).

### Current vs fuzzy (#4232)

Every eligible trace is also replayed through `FuzzyConsumptionEngine`
and reported in a second per-source-class table beside the shipped figure
(`tool/replay_consumption_fuzzy.dart`). The engine reads each tick's `f`
(native for `pid9D` / `pidA2` / `pid5E`, air-mass physics for `maf66` /
`maf` / `speedDensity` — the recorded, already pump-gain-applied rate),
or `fe` as GPS road-load physics. Grade, yaw rate, stop count and mass are
not in `sampleToJson`, so they replay as missing inputs. A trace with any
interval lacking a figure is listed as not replayable rather than
integrated partially. The shipped rule base is neutral until it is fitted
on real native-fuel-rate traces — see
`docs/decisions/0023-fuzzy-consumption-engine.md`.
