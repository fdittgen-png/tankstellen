<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Per-fuel-type efficiency attribution (v1 — dominant-fuel)

| Section  | Value                                                          |
|----------|----------------------------------------------------------------|
| Status   | Accepted                                                       |
| Date     | 2026-06-05                                                    |
| Epic     | [#2881](https://github.com/fdittgen-png/tankstellen/issues/2881) |
| Child    | [#2882](https://github.com/fdittgen-png/tankstellen/issues/2882) (this note) |

## Context

A multi-fuel owner — the canonical case is a Peugeot 107 run on **E85 / E10 /
E5** depending on availability — cannot tell which fuel is actually *cheapest
per kilometre*. E85 is cheaper per litre but burns more, so the per-litre price
on the pump is a lie about the real cost of driving. Today every fill-up is
aggregated into one all-fuel `ConsumptionStats`. `FillUp.fuelType` already
exists (typed `FuelType`, round-trips via `@FuelTypeJsonConverter`) but is
never used as a grouping key.

The challenge is **attribution**: consumption is only ever measurable over a
*closed plein-to-plein interval* (the existing walker in
`consumption_stats.dart`), and a single interval can legitimately contain fills
of more than one fuel (you topped up with E10 because the station had no E85).
Litres are known per fill; **distance is only known per interval** (odometer
delta). There is no honest way to split one interval's distance between two
fuels without OBD2 per-fuel burn data, which v1 does not have.

## Decision

**v1 attributes each closed interval, whole, to its DOMINANT fuel** — the fuel
that contributed the most litres to that interval. This is deliberately the
simplest model that produces a usable €/km verdict, and it is honest about its
own fuzziness via a "N of M tanks were mixed" footnote.

The authoritative rule:

1. **Unit = a CLOSED plein-to-plein interval**, identical to the
   `ConsumptionStats.fromFillUps` walker. An interval opens at a full-tank fill
   (or the very first fill) and closes at the next full-tank fill. The
   *contributing fills* of an interval are the fills strictly **after** the
   opening, up to **and including** the closing plein. The opening fill's
   litres belong to no closed interval (it anchors the odometer baseline). The
   in-progress tail after the last plein is excluded.

2. **Dominance tally.** For each closed interval, sum litres per
   `FuelType.apiValue` across the contributing **non-correction** fills.
   Attribute the WHOLE interval — litres, distance, cost — to the fuel with the
   **most litres** (the *dominant* fuel).
   - **Tie-break 1:** the closing plein's fuel type.
   - **Tie-break 2 (final, for determinism):** lowest `apiValue` alphabetically.

3. **Corrections** (`isCorrection`) inherit the interval's dominant fuel. They
   **never** count as a distinct fuel in the dominance tally and can **never**
   flip an interval. (Their `totalCost` is always 0, mirroring the #2446
   honesty precedent, so they do not move €/km either.)

4. **Per-fuel metrics**, accumulated over that fuel's dominant-attributed
   intervals:
   - `avgL100km    = Σlitres / Σdistance × 100`
   - `avgCostPerKm = Σcost   / Σdistance`
   - Both are **null** when the fuel has zero attributed intervals
     (`attributedIntervalCount == 0`) — e.g. a fuel that only ever appeared as a
     minority in mixed tanks, or only in the open tail / opening fill.

5. **`totalSpent`** per fuel is a **per-fill fact**, independent of interval
   attribution: Σ `totalCost` of **every** non-correction fill of that fuel,
   across all intervals (including the opening fill and the open tail). It
   answers "how much have I spent on E85 in total", which is true regardless of
   which interval each fill landed in.

6. **`fillCount`** per fuel = count of all non-correction fills of that fuel.

7. **`mixedIntervalCount`** per fuel = attributed intervals that actually
   contained more than one fuel among their contributing non-correction fills.
   Drives the footnote "N of M tanks were mixed — each counted toward its main
   fuel".

8. **Verdict gate.** `const kMinAttributedIntervalsForVerdict = 2`. The
   "cheapest per km: <fuel>" verdict is only crowned when **every** compared
   fuel that has fills has `attributedIntervalCount >= 2`. Below the threshold
   the helper returns `null` and the UI shows numbers without a winner — one
   lucky cheap tank must not crown a fuel.

Out of scope for v1 (tracked on the Epic): proportional litre-splitting via
OBD2 `fuelLevelBefore/After`; family rollup (lumping E5 + E10). v1 groups by
exact `FuelType.apiValue`.

## Worked example (the frozen RED fixture for #2883)

Six fills for one vehicle, chronological. All are full-tank pleins **except F3**
(a partial top-up). Prices are clean round €/L so the arithmetic is checkable
by hand.

| Fill | odo (km) | fuel | litres | €/L  | totalCost | full tank?         |
|------|---------:|------|-------:|-----:|----------:|:-------------------|
| F0   |        0 | E10  |     40 | 1.70 |     68.00 | yes (opening)      |
| F1   |      600 | E10  |     30 | 1.70 |     51.00 | yes → closes **A** |
| F2   |     1100 | E85  |     45 | 1.00 |     45.00 | yes → closes **B** |
| F3   |     1400 | E85  |     20 | 1.00 |     20.00 | **no** (partial)   |
| F4   |     1700 | E10  |     35 | 1.70 |     59.50 | yes → closes **C** |
| F5   |     2300 | E85  |     50 | 1.00 |     50.00 | yes → closes **D** |

### Interval classification

| Interval | opens at | closes at | contributing fills | litres tally       | dominant | mixed? | distance (km)       |
|----------|----------|-----------|--------------------|--------------------|----------|:------:|--------------------:|
| A        | F0       | F1        | F1                 | E10 = 30           | **E10**  | no     | 600 − 0    = 600    |
| B        | F1       | F2        | F2                 | E85 = 45           | **E85**  | no     | 1100 − 600 = 500    |
| C        | F2       | F4        | F3, F4             | E85 = 20, E10 = 35 | **E10**  | yes    | 1700 − 1100 = 600   |
| D        | F4       | F5        | F5                 | E85 = 50           | **E85**  | no     | 2300 − 1700 = 600   |

F0's 40 L anchor the baseline and belong to no closed interval. In interval C,
E10 (35 L) outweighs E85 (20 L), so the *whole* 600 km / 55 L / €79.50 is
attributed to **E10** — this is the deliberate fuzziness the footnote discloses.

### Expected per-fuel result

**E10** — attributed intervals A + C:
- Σdistance = 600 + 600 = **1200 km**
- Σlitres   = 30 + 55  = **85 L**   (C contributes 35 E10 + 20 E85 = 55)
- Σcost     = 51.00 + 79.50 = **€130.50**  (C: 59.50 + 20.00)
- `avgL100km`    = 85 / 1200 × 100 = **7.0833 L/100km**
- `avgCostPerKm` = 130.50 / 1200  = **€0.108750 /km**
- `attributedIntervalCount` = **2**, `mixedIntervalCount` = **1**
- `totalSpent` = 68.00 + 51.00 + 59.50 = **€178.50** (F0 + F1 + F4)
- `fillCount` = **3** (F0, F1, F4)

**E85** — attributed intervals B + D:
- Σdistance = 500 + 600 = **1100 km**
- Σlitres   = 45 + 50  = **95 L**
- Σcost     = 45.00 + 50.00 = **€95.00**
- `avgL100km`    = 95 / 1100 × 100 = **8.6364 L/100km**
- `avgCostPerKm` = 95.00 / 1100  = **€0.086364 /km**
- `attributedIntervalCount` = **2**, `mixedIntervalCount` = **0**
- `totalSpent` = 45.00 + 20.00 + 50.00 = **€115.00** (F2 + F3 + F5)
- `fillCount` = **3** (F2, F3, F5)

### Verdict

Both fuels have `attributedIntervalCount = 2 >= kMinAttributedIntervalsForVerdict`
→ the gate opens. Cheapest €/km is **E85** (0.0864 < 0.1088) — even though E85
burns *more* litres per 100 km (8.64 vs 7.08). This is the whole point of the
feature: the cheaper-per-litre fuel can still win per kilometre. The result list
is sorted by `avgCostPerKm` ascending, so **E85 sorts first**, E10 second.

## Consequences

- The model is **biased toward the dominant fuel** of any mixed tank — a
  minority fuel's distance is credited to whatever you put more of in. The
  footnote (`mixedIntervalCount` of `attributedIntervalCount`) makes this
  visible rather than silent.
- A fuel can have `totalSpent > 0` and `fillCount > 0` but `null` per-km
  metrics (only ever a minority, or only in the opening / open tail). The UI
  must null-skip the L/100km and €/km cells for such a fuel.
- The walker logic is the **same** as `consumption_stats.dart`; #2883's
  aggregator reuses that interval definition (replicating it faithfully with a
  cross-reference comment, since the existing walker does not expose a
  per-interval hook).
- The verdict gate trades early gratification for trust: a user who has driven
  only one E85 tank gets numbers but no crown until a second closed E85 tank
  confirms it.

## Alternatives considered

- **Proportional litre-split.** Split a mixed interval's distance between fuels
  in proportion to their litres. Rejected for v1: distance per fuel is not
  measurable without OBD2 per-fuel burn, so the "proportion" would itself be a
  fiction dressed up as precision. Deferred to a post-v1 OBD2 path.
- **Drop mixed intervals entirely.** Only count mono-fuel intervals. Rejected:
  throws away real driving data for the exact users (frequent fuel-switchers)
  the feature targets, and would starve the verdict gate.
- **Family rollup (E5 + E10 as one petrol bucket).** Rejected for v1: the E85
  vs E10 decision is precisely *within* the petrol family, so collapsing it
  defeats the purpose. Exact `apiValue` grouping keeps E5 / E10 / E85 distinct.
