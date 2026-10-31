<!-- Copyright (c) 2026 Florian DITTGEN -->
<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

# Physical tank reference — #4469

Implementation base: `f16377fe0`. This is a deterministic arithmetic and
consumer-wiring correction, not a field-accuracy or telemetry-model evaluation.

`physicalTankWindows` now owns the existing full-to-full reconstruction.
The report, fill-anchored reference, consumption statistics, fill-history
consumption/trends and per-fuel efficiency consume that reconstruction. Fuel
behaviour evidence, comparison reports and pump learning inherit the qualified
report windows. Purchase totals remain separate; synthetic records are retained.

- Only physical full fills establish boundaries. Purchased quantities strictly
  after the opening through the closing full count, including physical partials.
- Synthetic corrections contribute neither volume nor boundaries. Accounting
  correction tallies and the original saved records remain available.
- Invalid quantities, invalid odometers, ambiguous duplicate/time ordering and
  independent tank combinations produce explicit rejection categories. Collision
  keys use epoch microseconds, so UTC/local representations of the same instant
  cannot hide a partial after the closing event ID. Duplicate
  identical IDs count once; conflicting copies cannot establish pump truth.
- Known vehicles are reconstructed independently. The existing single-vehicle
  legacy-unassigned convention is preserved; an unassigned record is never
  counted in several explicitly identified vehicles.
- Petrol blends retain their aggregate physical result. A grade-changing partial
  marks the report window mixed and prevents single-grade pump calibration even
  when every linked recording happens to carry the same grade.
- The conservative shared litre-reference plausibility band is 1–35 L/100 km
  over more than 3 and at most 3,000 km, combining existing reference/report
  guards. Rejected intervals are not repaired or rewritten. Unit-aware efficiency
  buckets retain their kg/kWh presentation and native spend; litre-only
  plausibility limits do not filter native-unit purchases.

## Odometer zero is not a new sentinel

The shipped form's `AddFillUpValidators.positiveNumber` explicitly requires the
odometer to be greater than zero; both the add form and correction editor use
it. The existing fill-anchored reference likewise rejects non-positive absolute
readings. This change preserves that entry/reference contract. A nominal 0→500
km imported pair is explicitly rejected instead of silently changing the
contract. A future product decision to support a genuine new-car zero must
change entry validation and unknown-reading semantics together.

Old composition/comparison fixtures used zero as an arbitrary origin. Those
fixtures now use 10,000 plus the old reading, preserving every distance and
independent numerical expectation. The one assertion exposing that source
reading was adjusted as well. No persisted user record is modified.

## Acceptance evidence

| Contract | Executable evidence |
|---|---|
| 42.2 L / 597 km = 7.0686767169…; opening partial and synthetic full never qualify | `physical_tank_consumers_test.dart`, parameterized over five production consumers |
| Finite/positive quantities and trustworthy distance, duplicates, independent tanks, blends and weighted averages | Same consumer suite; explicit rejection assertions |
| Source class and partial recordings cannot replace the 597 km denominator | Existing `consumption_source_class_gates_test.dart` (#4236), 421 km recorded subset |
| Actual persistence mutations and restart recompute report/stats/evidence | `physical_tank_invalidation_test.dart`: add, import, synthetic reconciliation, edit, delete and reopen |
| No pump learning from a first partial or an ambiguous physical blend | Existing `pump_gain_learner_test.dart` regressions |
| Unknown consumption is actionable; displayed stats show 7.07 and report names 597 km / 42.2 L | `physical_tank_display_test.dart`, en/de/fr empty-state assertions and real calculation output |

Pre-fix production regressions reproduced six failures in report/statistics,
six more in fill-history/efficiency twins, and a learner that accepted a
physical mixed tank. The already-correct fill-anchored reference was the control.
Existing accounting/currency, blend, comparison, backup and source-class suites
remain part of validation; the efficiency price prefix ends at the last
qualified close, so a rejected late full cannot reprice earlier windows; no real-device/corpus accuracy or deployment is
claimed. Exact commands and final results travel with the PR head review.

## Local verification sequence

Pinned Flutter 3.44.9 / Dart 3.12.2 on macOS; no device run is claimed.

- Affected fill-up domain/providers/widgets, the existing #4236 gate,
  tank-report domain tests and backup compatibility: **1,001 passed**.
- Final integrated consumer, persistence, display, lint and localization
  checks after the reviewed #4497 merge: **406 passed**.
- Additional efficiency/valuation/reference regressions cover the rejected
  late-full price boundary and low native-unit hydrogen spend.
- Clean code generation: **550 outputs, no generated Dart drift**; full
  ARB/pseudo/localization generation likewise leaves no drift after the merge.
- Full analyzer: **zero issues**; no runtime schema, saved fill-up, raw trip or
  historical vehicle-gain reset is performed. Existing persisted gains are
  not replayed without provenance; calibration revisions belong to #4472.

The final PR records exact commands and its independently reviewed full SHA.
