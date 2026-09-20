<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0027: The legacy consumption estimators are deprecated, not removed — a field-by-field policy (#4234)

**Status:** Accepted
**Date:** 2026-09-20
**Issue:** #4234 (Epic #4222, absorbs #4207's legacy part)
**Related:** ADR 0010 (GPS calibration matrix), ADR 0012 (GPS-only live
estimator), ADR 0020 (pump-anchored fuel gain), ADR 0022 (the canonical
`ConsumptionEstimate`), ADR 0024 (wiring the fuzzy engine), #4231 (replay
corpus — the removal gate), #4233 (integration), #4330 (the F4
classification and the backup provenance round trip)

## Context

Epic #4222 makes fuzzy inference the single production estimation mode.
#4233 wired the engine in behind a **neutral** rule base, so every
estimated figure now passes through it while coming out bit-identical to
what shipped before. #4234 is the retirement step.

It cannot run yet. The epic's **validation gate** is binding:

> Until #4231's replay shows the fuzzy path is **not worse** than the
> shipped figure for a source class, the existing path keeps producing
> that class's figure.

#4231 shipped the replay *harness*; the anonymized corpus it measures
does not exist. So there is nothing to validate against, and deleting or
disabling a legacy path today would breach the gate — it would swap a
figure users see for one no evidence says is as good.

What *can* be settled without a corpus, and is settled here:

1. **Nothing production reads a legacy estimator any more.** Proven, not
   claimed — see *The audit* below.
2. **Historical values stay reproducible.** Pinned by
   `test/features/consumption/historical_value_reproducibility_test.dart`.
3. **Each retained field has a written policy**: what it is, why it is
   kept, how its history stays readable, and what must be true before it
   can go. That is the body of this ADR.

## Decision

### 1. Deprecated means "no new production selection", not "gone"

A legacy path is **deprecated** when:

- no production consumer reads a figure out of it (the audit below);
- no user setting, `Feature` flag or runtime branch can select it
  (`test/lint/single_consumption_estimator_test.dart`, ADR 0024 §8);
- it remains readable, so historical recordings, old backups and the
  replay tool keep working.

It is **removed** only when its Exit condition below is met. Every Exit
condition includes #4231's corpus, because every one of these paths still
produces or calibrates a number a user has already seen.

### 2. The audit that makes claim 1 checkable

Two tests, deliberately of different kinds, because a source scan proves
the text and not the code — this repository once ran four regex guards
that reported green while never executing at all.

**Executable** —
`test/features/consumption/legacy_estimator_consumer_audit_test.dart`
drives the real consumers (`tripConsumptionEstimate`,
`CalibratedTripFigures`, `calibratedTankRecording`,
`aggregateMonthlyInsights`, `tripFuelEvidenceFor`,
`coachSpokenAvgLPer100Km`, `tripConsumedLitersOrNull`,
`aggregateByTripLength`) against four vehicle profiles that differ *only*
in legacy-estimator state: no GPS matrix, `physicsScale` 1.9,
`physicsScale` 0.6, and `calibrationMode: fuzzy`. A consumer that read
the matrix or branched on the mode would return different numbers. None
does. A second property checks each consumer's figure against the
canonical `ConsumptionEstimate`, with every divergence pinned by name,
reason and issue in a map that is exact both ways, so the count can only
shrink.

**Static** — `test/lint/legacy_consumption_estimator_test.dart` enumerates
every file in `lib/` that so much as *names* a legacy symbol, with the
role that entitles it to. The role vocabulary contains *legacy
implementation*, *producer*, *persistence*, *setting UI* and *maturity
chrome*. It deliberately does **not** contain *consumer*: that absence is
the audit's finding.

#### What the audit cannot see

State it plainly, because a gate whose blind spots are undocumented is
worse than no gate:

- **The recording lifecycle.** `trip_recording_controller_summary.dart`
  and the GPS/OBD2 pipelines are Riverpod notifiers with hardware-shaped
  dependencies; the executable audit cannot call them. Their *output* is
  pinned bit-for-bit by
  `consumption_identity_goldens_test.dart` instead.
- **Rendering.** Both tests reason about the number a consumer resolves,
  never about the glyphs a widget paints. A widget that computed a
  figure inline in `build` would be caught by the static scan only if it
  named a legacy symbol.
- **Indirection.** The static scan matches identifiers. A legacy value
  reached through a variable renamed on the way (`final s = matrix;` in
  one file, `s.physicsScale` in another) is caught in the file that names
  `physicsScale`, but a value passed as a bare `double` through three
  hops is not traceable by either test.
- **Anything outside `lib/`.** Platform channels, the Android/iOS widget
  code and `tool/` are not scanned.
- **Whether the fuzzy figure is *better*.** Neither test measures
  accuracy. That is exactly what #4231's corpus is for, and why removal
  is gated on it rather than on these tests being green.

### 3. The per-field policy

Each entry: **what it is · why retained · how history stays readable ·
exit condition**.

#### 3.1 `VehicleProfile.gpsCalibration` (`GpsCalibrationMatrix`)

*What.* A persisted per-vehicle matrix (ADR 0010): a baseline L/100 km
plus idle / high-speed / accel coefficients, the `physicsScale`
multiplier, and reconciliation bookkeeping
(`fillUpReconciliationCount`, `residualVariance`, `lastReconciledAt`).

*Why retained.* It is still a **producer-side input**: `physicsScale`
scales the GPS road-load estimator's per-tick output before the fuzzy
stage refines it, and the maturity counters drive user-visible
confidence chrome. Dropping it would change every GPS-only figure with
no evidence that the change is an improvement.

*History.* The field is a `freezed` member of the persisted
`VehicleProfile` with a defaulted `physicsScale` of 1.0, so an old
profile deserialises without migration. Stored trip figures already have
the matrix baked in; nothing recomputes them.

*Exit.* #4231's corpus shows the fuzzy path is not worse for the
`gpsOnly` source class **without** `physicsScale`, and the maturity
chrome has a replacement confidence source (the estimate's own
`confidence`). Then the field becomes read-only (decoded, never written)
for one release before the schema drops it.

#### 3.2 `GpsMatrixReconciler`

*What.* The EWMA/LSQ update that folds a completed fill-up window back
into the matrix coefficients, driven from
`consumption_providers_calibration.dart`.

*Why retained.* It is the only thing that keeps a live matrix anchored
to reality. While §3.1 is in production, freezing the reconciler would
leave every matrix drifting at its cold-start seed.

*History.* Pure function over stored inputs; it writes only to the
matrix in §3.1 and never edits a recorded trip.

*Exit.* Follows §3.1 exactly — it has no independent consumer.

#### 3.3 `PhysicsScaleCalibrator`

*What.* Nudges `physicsScale` toward OBD2 ground truth by replaying a
trip's GPS estimate against its measured average
(`trip_recording_provider_persist.dart`).

*Why retained.* Same as §3.2, and it is also the only path that gives a
hybrid-equipped car a calibrated GPS figure for the stretches its dongle
missed.

*History.* Only ever writes `physicsScale`; it explicitly never
re-measures or rewrites a trip's stored figures.

*Exit.* Follows §3.1. Its replay usage is separately useful and may be
kept as **replay-only support** (`tool/`-side), which the epic permits
for explicitly versioned migration/replay code.

#### 3.4 `gps_matrix_maturity_badge.dart`

*What.* The cold / warming / converged badge beside a GPS-only average,
read from the matrix's reconciliation counters.

*Why retained.* It is the user's only signal that a GPS figure is a
young estimate. Removing it before `ConsumptionEstimate.confidence` is
populated and rendered would make an unreliable number look definitive —
a regression in honesty, not a cleanup.

*History.* Pure presentation over §3.1; renders nothing when the matrix
is absent.

*Exit.* `ConsumptionEstimate.confidence` is produced end-to-end by the
fuzzy path and a confidence affordance renders from it. Then the badge
switches source, or goes.

#### 3.5 `trip_avg_consumption_card.dart`

*What.* The live **Average consumption** card on the recording screen.
Three modes: a receipt-derived broken-MAP override, the measured OBD2
live average, and the GPS estimate with the §3.4 badge.

*Why retained.* It renders `TripLiveReading`, which does not carry a
`ConsumptionEstimate` — ADR 0024 lists the live reading's emit code as
deferred lifecycle work. Its numbers already come from the single
production path (the GPS branch runs through the fuzzy stage), so this
is a *contract* gap, not an estimator gap.

*History.* Live-only; persists nothing.

*Exit.* The live reading carries a `ConsumptionEstimate`, and the card
reads value + confidence from it. That work is lifecycle-side and does
not need the corpus; the §3.4 badge it hosts does.

#### 3.6 `gps_trip_fuel_backfill.dart`

*What.* Fills a `gpsOnly` trip's `avgLPer100Km` / litres after the fact —
the live-folder figure when one exists, else a batch `GpsFuelEstimator`
fit over the whole trip.

*Why retained.* Without it a dongle-less trip has no consumption figure
at all. The live-folder branch is already fuzzy-era and stamps `cmv`
(ADR 0024 §5).

*History.* The **batch** branch stays unstamped on purpose: it fits a
whole trip at once, has no per-sample inputs and never passes through the
engine, so claiming a model version for it would be invented provenance.
An unstamped row therefore means "not produced by the fuzzy path", which
is precisely the distinction retirement needs — see §4.

*Exit.* #4231's corpus shows a per-sample fuzzy fit is not worse than the
batch fit for whole-trip GPS reconstruction. Then the batch estimator
goes and every GPS trip is stamped.

#### 3.7 `obd2_gps_estimate_fallback.dart`

*What.* For a car whose ECU exposes no fuel PID, fills the trip from the
GPS road-load estimate at stop time.

*Why retained.* It is the only fuel figure those cars ever get. It is
already fuzzy-era: it runs through `GpsLiveFuelEstimator` (hence the
stage) and stamps `tripConsumptionVersion()`.

*History.* Stamped, so its rows are distinguishable from pre-#4233 ones.
Since #4330 it also stamps `dominantFuelSource: 'gpsPhysics'`, which
`tripFuelSourceKind` maps to `gps`.

*Exit.* Not a removal candidate as such. What retires with §3.1 is its
use of the matrix; the fallback itself stays.

*F4 is closed (#4330).* The classification gap ADR 0024 recorded — such a
trip carries a figure but classed as `none` — is fixed at the producer.
The audit carries a `noFuelPidGpsPhysics` fixture shaped exactly as
`fillWhenNoFuelPid` now writes it (average, litres and the tag together);
it diverges from the canonical figure on **no** consumer. The pre-#4330
shape is kept as a second fixture because rows written that way exist in
users' histories and can no longer be produced; its divergences are
frozen, not open bugs.

#### 3.8 The `rule | fuzzy` setting

Five touch points, one subject. **Read this first: it is not a
consumption-estimator switch.** ADR 0022 established, and the audit now
proves executably, that its two branches select how a driving-*situation*
baseline vote is recorded — one hard bucket versus seven weighted
memberships (#894 / #1426 / #779) — feeding `FuzzyClassifier` into the
Welford `BaselineStore`. It does not choose a fuel estimator. Retiring it
under #4234 would delete a working feature under the wrong issue.

| touch point | what it is |
|---|---|
| `VehicleProfile.calibrationMode` | the persisted `rule \| fuzzy` value, default `rule` |
| backup XML `CalibrationMode` | the element the writer emits and the reader parses |
| `trip_baseline_recorder.dart:158` | the branch that records one bucket or seven memberships |
| `vehicle_calibration_mode_selector.dart` | the selector widget |
| the calibration topic screen / topic tiles / form controllers | where the selector is mounted and edited |

*Why retained.* It governs a feature Epic #4222 explicitly leaves
undefined ("the fate of the situation baselines"), and the baselines it
feeds are synced (`Feature.baselineSync` → TankSync). Nothing in the
consumption epic decides them.

*History.* `VehicleCalibrationMode.fromKey` falls back to `rule` for a
null or unrecognised key, so a profile or a backup written before the
setting existed decodes cleanly.

*Exit.* A decision on the situation baselines — their own issue, not
this one. Until then the setting stays exactly as it is. If that decision
is "remove", the reader obligation in §5 still applies.

### 4. Historical values stay reproducible — the rule

Three numbers travel with a figure (`ConsumptionModelVersion`: model,
rules, calibration; ADR 0022 §4), persisted as trip key `cmv`.

- A row **with** a stamp keeps it exactly through decode and re-encode,
  and orders against the shipping engine's version with `isOlderThan`, so
  a replay can tell "recompute this" from "trust this".
- A row **without** a stamp decodes to `null` — *unknown version* — and
  is never re-read as current. Defaulting it to `model: 1` would erase
  the only signal that separates a legacy figure from a fuzzy-era one,
  and #4234's whole retirement argument rests on that separation.
- Re-expressing an estimated figure at today's pump gain updates only the
  **calibration generation**; model and rules stay the producing build's.
  The stored row is never rewritten, so the original number is always
  recomputable from it.
- A malformed stamp is unknown, not repaired.

Pinned by `historical_value_reproducibility_test.dart` against literal
persisted rows, so a future encoder change cannot quietly redefine what
an old row looked like.

**The backup gap is closed (#4330).** This ADR first recorded ADR 0024's
F8 as a must-fix-before-removal: the backup XML dropped `pg` / `pgk` /
`dfs` / `cmv`, so a restored trip lost the gain its litres carry and its
version stamp, and after a removal such a row could never be regenerated.
#4330 landed the round trip — `backup_xml_trip_provenance.dart` writes
and reads all four, omitted-when-null — and `_finaliseSummary` now stamps
`consumptionVersion` as well, so the lifecycle-finalised trips ADR 0024
listed as deferred are no longer unstamped. **This is no longer a blocker
for removal.** #4231's corpus is the remaining gate.

Pinned end-to-end for #4234's purposes by the backup round-trip group of
`historical_value_reproducibility_test.dart`: a restored trip resolves to
the same `ConsumptionEstimate` — value, source class, pump gain and
version — as the one that was backed up, and a pre-#4330 backup (no
provenance elements at all) still restores as unknown-version rather than
acquiring one.

### 5. The backup reader must keep accepting old backups

Stated plainly because it is the obligation most easily lost in a
cleanup: **a restore of a pre-migration backup is not optional.**

Whatever happens to `VehicleProfile.calibrationMode` or
`VehicleProfile.gpsCalibration`, `BackupXmlReader` must keep parsing a
document that carries the old element, and must keep parsing one that
does not. Removing a field from the model means the reader *ignores* that
element; it never means the reader rejects the document, drops the
vehicle, or throws. Users restore backups that are years old, and a
restore that fails is data loss with extra steps.

Pinned by the backup group of
`historical_value_reproducibility_test.dart`: a vehicle element with no
`CalibrationMode` restores to the default, one with `fuzzy` keeps it, and
an unrecognised value falls back rather than throwing.

#4330's provenance elements follow the same discipline and extend the
obligation rather than narrowing it: each is omitted when its field is
null, a pre-#4330 document restores byte-identically, and a malformed
`<ConsumptionVersion>` degrades to null instead of failing the restore.

### 6. Removal is gated on #4231's corpus

No entry in §3 may be deleted, disabled, or made unreachable until:

1. #4231's anonymized replay corpus exists and covers the source class
   the path serves;
2. the replay shows the fuzzy path is **not worse** than the shipped
   figure for that class, on accuracy *and* confidence;
3. a replay regression gate runs in CI, so a later rule-base change
   cannot silently undo the result;
4. this ADR's entry is updated to **Removed** in the same PR, with the
   replay numbers quoted.

Until then the correct action on a legacy path is to leave it alone.

## Consequences

- #4234's boxes 1–3 are ticked and testable; boxes 4–5 (end-to-end proof
  for every major consumer, and the replay regression gates) stay open,
  both waiting on the corpus.
- The audit's divergence map is a live inventory of every place a
  consumer's number is not the canonical one, each with a reason. It can
  only shrink, so the inventory cannot rot into a list of excuses. Its
  surviving entries are now of exactly two kinds: rows a current build
  can no longer write (the pre-#4330 shape), and the litres basis, which
  stays at the recorded gain on purpose.
- Two genuine inconsistencies surfaced and are recorded: the voice coach
  read the raw stored average (fixed here — it now reads
  `tripConsumptionEstimate`, so the spoken figure can no longer disagree
  with the card the driver is looking at), and the litres basis
  deliberately stays at the recorded gain because re-expressing it would
  feed the pump-gain learner its own output.
- Carrying five deprecated-but-live paths has a cost: every one of them
  is code a reader must still understand. That cost is accepted for as
  long as the gate says the evidence to remove them does not exist.

## Alternatives Considered

- **Delete the GPS matrix now and let the fuzzy path take over.**
  Rejected: the rule base is neutral, so "taking over" means the raw
  road-load output with `physicsScale` dropped — a changed figure for
  every GPS-only user, justified by nothing.
- **Hide the legacy paths behind a flag instead of documenting them.**
  Rejected: a flag that can select an estimator is exactly what Epic
  #4222 forbids, and `single_consumption_estimator_test.dart` fails the
  build on one.
- **Default an unstamped row to the shipping version.** Rejected: it
  destroys the legacy/fuzzy distinction the retirement decision needs,
  and claims provenance the row does not have.
- **Retire the `rule | fuzzy` setting with the estimators, since #4234
  names it.** Rejected: the audit proves executably that it selects a
  situation-baseline vote, not a fuel estimator. Removing it here would
  delete a working, synced feature under an issue that never analysed it.
- **A single "legacy" boolean on the profile instead of per-field
  policy.** Rejected: the five paths have genuinely different exit
  conditions — two need the corpus, one needs a confidence renderer, one
  needs lifecycle work, one needs a product decision that is not in this
  epic at all.
