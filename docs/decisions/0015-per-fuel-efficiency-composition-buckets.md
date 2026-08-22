<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0015: Per-fuel efficiency comparison v2 — pure-vs-mix composition buckets

**Status:** Accepted (amended 2026-08-22 by the v3 carried-content section, #3764)
**Date:** 2026-06-05
**Issue:** #2928 (v2) · #3764 (v3 amendment)
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

## v3 amendment (2026-08-22, #3764) — the composition includes the carried-over tank content

### Problem

v2's composition tally saw only the interval's *contributing fills*, so the
fuel already in the tank at the opening plein was invisible. The reporting
user's case: **14 L of E5** still in the tank, topped with **21 L of E85 to
full (35 L)** — the tank that then burns is a **~40/60 E5/E85 blend**, yet v2
bucketed the following interval by its contributing fills alone (→ pure E85).
The `TankMixEstimator` (#3652) already models exactly that prior-content
chain; the aggregator simply never consulted it.

### Decision

v3 classifies each closed interval by **what the tank actually held while it
was being burned**:

```
composition = opening content
            + non-correction fills STRICTLY INSIDE the interval
```

1. **Opening content.** Knowable exactly when the interval opens at a
   **physical plein** and the **tank capacity is known** (user-set
   `tankCapacityL`, or backfilled from the reference catalog by the vehicle
   editor): the content is the full tank —
   `capacity × the mix shares as of that fill`, where the shares come from
   `estimateTankMixForCapacity` (the #3652 prior-content chain, reused
   verbatim) replayed over the fill-history **prefix up to and including the
   opening fill**. For the very first fill the chain attributes the unknown
   residual to that fill's own grade (its documented convergence rule).
2. **The closing plein is EXCLUDED from the composition tally.** Its fuel
   enters the tank *after* the interval's burn — it belongs to the **next**
   interval's opening content, where the mix chain delivers it. (Including
   it would, in the run-dry case, turn a pure-E5 burn closed by an E85 plein
   into a fictitious 50/50 blend.) Under v2 the closing plein was the tally's
   main ingredient; under v3 the burned tank replaces it. The canonical case
   thus buckets as exactly the 40/60 `E85/E5` mix.
3. **Capacity-unknown fallback.** When the opening content is NOT knowable —
   capacity unset, the interval opens on a non-plein first fill, or the
   opening entry is a synthetic correction (#1361) — the interval falls back
   to the v2 contributing-fills tally (closing plein included) **exactly**,
   and is counted in the new `legacyAttributedIntervalCount` on the bucket's
   stats so the UI can disclose partially-legacy attribution. A history run
   entirely without capacity is bit-for-bit v2.
4. **Unchanged:** the interval walker, the 85 % purity rule
   (`kMaxMinorityShareForPure`), dominant/secondary labelling, tie-breaks,
   the corrections rules (a corrections-only interval still attributes
   nothing, even with a known opening content), the verdict gate
   (`kMinAttributedIntervalsForVerdict`), and the sort.

### Metric folding stays v2

Σlitres / Σcost / Σdistance still fold from the **contributing fills**
(closing plein included): between two pleins, pumped litres ≈ burned litres,
and that identity is the honest basis of `avgL100km`. Only the
**classification** tally changed. Consequence, stated openly: on a
fuel-switch interval the folded cost is the *closing* plein's price while the
bucket names the *burned* blend — a one-interval price lag, exactly the v2
"spend is credited to the tank it closed" approximation, which washes out
over the bucket's intervals. Folding the opening content's historical prices
instead was rejected as fabricated precision (those litres were paid inside
earlier intervals at unrecorded blend ratios).

### Consequences

- The canonical flex-fuel pattern — run partway down on grade A, top to full
  with grade B — finally produces the blend bucket the driver actually burns;
  switching grades no longer mislabels whole tanks as pure.
- A truly run-dry switch (prior content 0 at the plein) correctly stays
  PURE: `capacity − pumped = 0` pins the mix to the new grade alone.
- Attribution now depends (deliberately) on the tank capacity: adding or
  correcting `tankCapacityL` can re-bucket past intervals. The
  `legacyAttributedIntervalCount` field makes the mixed-provenance case
  inspectable instead of silent.
- The aggregator is no longer a pure function of the fill list alone — it
  takes an optional `tankCapacityL` and replays the mix chain per interval
  (O(n²) worst case; fill histories are small, measured in hundreds).
