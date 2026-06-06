<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0015: Per-fuel efficiency comparison v2 — pure-vs-mix composition buckets

**Status:** Accepted
**Date:** 2026-06-05
**Issue:** #2928
**Parent Epic:** #2881
**Supersedes:** ADR 0014 (dominant-fuel collapse)

## Context

ADR 0014 attributes each closed plein-to-plein interval, **whole**, to its
single DOMINANT fuel — the fuel with the most litres in that interval. For the
canonical user (a flex-fuel car run on **E85 / E10 / E5** depending on
availability), this collapses *every* mixed tank into the dominant grade. The
consequence is the exact comparison the feature exists to make becomes
impossible: a driver cannot put a **pure E85** tank next to an **E85/E10
blend** and ask which is cheaper to drive on. A tank that was 70 % E85 + 30 %
E10 is credited entirely to E85 and is indistinguishable from a 100 % E85 tank,
even though the blend burns and costs differently.

The per-interval litres-by-fuel composition is already computed —
`FuelTypeEfficiencyAggregator._attributeInterval` builds a `litresByFuel` map —
but v1 only used it to pick a single winner and threw the rest away. v2 keeps
that map and turns the **composition itself** into the grouping key.

## Decision

**v2 buckets each closed interval by its FUEL COMPOSITION**, not by a single
dominant fuel. A bucket is either a PURE grade or a `dominant/secondary` MIX.
This supersedes ADR 0014's dominant-collapse (ADR 0014 is now **Superseded**).

The authoritative rule:

1. **Unit = a CLOSED plein-to-plein interval**, identical to the
   `ConsumptionStats.fromFillUps` walker (unchanged from ADR 0014). An interval
   opens at a full-tank fill (or the very first fill) and closes at the next
   full-tank fill. The *contributing fills* are those strictly **after** the
   opening up to **and including** the closing plein. The opening fill anchors
   the odometer baseline and belongs to no closed interval; the in-progress
   tail after the last plein is excluded.

2. **Composition.** For each closed interval, sum litres per
   `FuelType.apiValue` across the contributing **non-correction** fills
   (`litresByFuel`). The **dominant** fuel is the largest volume share; the
   **secondary** the next largest. Ties on share break by lowest `apiValue`
   alphabetically for determinism.

3. **Pure vs mix threshold.** Let *minority share* = `1 − dominantShare`.
   A named constant `const kMaxMinorityShareForPure = 0.15` decides the bucket:
   - **Minority ≤ 15 % → PURE** (equivalently `dominantShare ≥ 0.85`). The
     bucket is the pure dominant `FuelType` (e.g. 90 % E85 + 10 % E10 → `E85`).
     The boundary is **inclusive**: an exactly-15 % minority is still pure.
   - **Minority > 15 % → MIX.** The bucket is `dominant/secondary`, dominant
     first (70 % E85 + 30 % E10 → `E85/E10`; 70 % E10 + 30 % E85 → `E10/E85`).
   - A **3-way blend** takes the two largest fuels for the label; **all** the
     interval's litres (including the third fuel's) still fold into that mix
     bucket — no litres are dropped.

4. **Folding.** The WHOLE interval — litres, distance, cost — folds into its
   bucket's accumulator. **Corrections** (`isCorrection`) inherit the bucket,
   never enter the composition tally (so they cannot create or flip a mix), and
   their `totalCost` is 0 (the #2446 honesty precedent), so they do not move
   €/km.

5. **Per-bucket metrics**, accumulated over the bucket's intervals:
   - `avgL100km    = Σlitres / Σdistance × 100`
   - `avgCostPerKm = Σcost   / Σdistance`
   - Both are **null** when the bucket has no usable distance (an odometer
     reset clamped to 0, or — degenerate — no closed interval). The UI
     null-skips those cells with an em-dash.
   - `totalSpent` / `fillCount` are folded from the bucket's intervals' fills
     (this is the deliberate semantic shift from v1, see Consequences).

6. **Only-used.** A bucket with zero classified intervals never materialises —
   the result lists only compositions the user has actually driven. A fuel that
   only ever appeared in an opening fill (anchoring no interval) produces no
   bucket.

7. **Verdict gate.** `const kMinAttributedIntervalsForVerdict = 2` (unchanged).
   The "cheapest per km: <composition>" verdict is crowned only when **every**
   compared bucket that has fills has `attributedIntervalCount ≥ 2`, and it
   compares across **all** buckets — pure *and* mix. Below the threshold the
   helper returns `null`; the UI shows numbers without a winner.

The grouping is by exact `FuelType.apiValue` (no family rollup). Result list is
sorted by `avgCostPerKm` ascending (nulls last), tie-broken by the bucket key.

## Worked example

Five fills for one flex-fuel vehicle, chronological. Clean round prices so the
arithmetic is checkable by hand.

| Fill | odo (km) | fuel | litres | totalCost | full tank?         |
|------|---------:|------|-------:|----------:|:-------------------|
| F0   |        0 | E85  |     40 |     40.00 | yes (opening)      |
| F1   |      500 | E85  |     50 |     50.00 | yes → closes **A** |
| F2   |     1300 | E10  |     15 |     12.00 | **no** (partial)   |
| F3   |     1800 | E85  |     35 |     28.00 | yes → closes **B** |
| F4   |     2300 | E85  |     50 |     50.00 | yes → closes **C** |

| Interval | contributing fills | litres tally          | dominant share | bucket    | distance |
|----------|--------------------|-----------------------|:--------------:|-----------|---------:|
| A        | F1                 | E85 = 50              | 100 %          | `E85`     | 500      |
| B        | F2, F3             | E85 = 35, E10 = 15    | 70 %           | `E85/E10` | 500      |
| C        | F4                 | E85 = 50              | 100 %          | `E85`     | 500      |

- **`E85`** (pure, A + C): Σlitres 100, Σdistance 1000, Σcost 100.00 →
  `avgL100km` 10.0, `avgCostPerKm` 0.100, `attributedIntervalCount` 2.
- **`E85/E10`** (mix, B): Σlitres 50, Σdistance 500, Σcost 40.00 →
  `avgL100km` 10.0, `avgCostPerKm` 0.080, `attributedIntervalCount` 1.

Both compositions appear as **distinct comparable rows**. (With a second mix
interval clearing the gate, the cheaper-per-km `E85/E10` would be crowned over
pure `E85` — the verdict compares across pure + mix.)

## Consequences

- A flex-fuel driver can finally compare **pure vs blended** tanks head-to-head
  — the headline value of the feature, impossible under ADR 0014.
- **Semantic shift in `totalSpent` / `fillCount`.** Under v1 these were
  *per-fuel* facts over **every** non-correction fill (including the opening
  fill and the open tail). Under v2 they are *per-bucket* facts folded from the
  bucket's classified intervals, so an opening-fill-only fuel no longer
  produces a row, and a fill's spend is credited to the composition of the tank
  it closed rather than to its own grade. This is intentional: a bucket now
  answers "what did tanks of *this composition* cost", consistent with its €/km.
- The **mixed-tank footnote** of ADR 0014 ("N of M tanks counted toward their
  main fuel") is gone — mixes are now first-class buckets, not hidden inside a
  dominant fuel. A composition footnote discloses the ≥ 85 % pure rule instead.
- The number of rows can grow (a pure grade plus each blend it appears in), but
  only for compositions actually driven, so it stays bounded by real behaviour.
- The interval walker logic is **unchanged** from ADR 0014 / `consumption_stats.dart`.

## Alternatives Considered

- **Keep ADR 0014's dominant-fuel collapse.** Rejected: it is precisely what
  makes pure-vs-blend comparison impossible, the gap this ADR closes.
- **Proportional litre-split.** Split a mixed interval's distance between fuels
  in proportion to their litres. Rejected (as in ADR 0014): distance per fuel
  is not measurable without OBD2 per-fuel burn, so the "proportion" would be a
  fiction dressed as precision. Composition bucketing instead treats the blend
  as its own honest unit.
- **A different pure threshold (e.g. 90 % or 95 %).** Rejected for v1 of this
  model: 85 % (15 % minority) is a round, defensible line — a 10 % splash-top
  reads as "basically that grade", a 30 % blend is genuinely a different fuel.
  The threshold is a single named constant (`kMaxMinorityShareForPure`) so it
  can be retuned without touching the bucketing logic.
- **Label a 3-way blend with all three fuels (`E85/E10/E5`).** Rejected: an
  unbounded label is noisy and rare; the two-largest label (`E85/E10`) keeps
  rows scannable while still folding every litre into the bucket. Noted as the
  simplest reasonable default.
