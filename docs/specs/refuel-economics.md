# Refuel economics — the Sparkilo decision model

Status: **specification**, v1 (2026-09-12). Implemented by
`lib/features/search/domain/refuel_economics.dart`.

Sparkilo is not a fuel-price database; it is a decision engine for
choosing where to refuel. This document is the economic model behind
that claim. It is written before the code because a recommendation the
user cannot trust is worse than no recommendation at all.

## 1. Why the old ranking had to go

The `Price/km` sort ranked by `price ÷ distance`, ascending
(`price_utils.dart`). That quantity has no economic meaning — €/L
divided by km is not a cost — and it is **monotonically improved by
driving further**: two stations at €1.00/L rank 10 km before 2 km,
because 0.1 < 0.5. It recommended detours for their own sake.

## 2. The model

For a station `S`, with the selected fuel:

| symbol | meaning | source |
|---|---|---|
| `P` | price per litre at `S` | station data |
| `D` | one-way travel distance to `S` | road distance when known, else crow-flies × `r` |
| `C` | vehicle consumption, L/100 km | measured from fill-ups; else estimated; else **none** |
| `Q` | litres the user intends to buy | the user's own median fill-up; else a default |
| `k` | trip factor | `2.0` there-and-back (default), `1.0` when a route is active |
| `r` | crow-flies → road correction | `1.3`, documented assumption |

```
detourLitres = k · D · C / 100
detourCost   = detourLitres · P
purchaseCost = Q · P
totalCost    = purchaseCost + detourCost
effectivePricePerLitre = totalCost / Q = P · (1 + k · D · C / (100 · Q))
```

**Tank capacity is not in the formula.** The fuel burned reaching a
station costs the same whether the tank holds 40 L or 70 L. Capacity
matters only as a ceiling on `Q`, and even then only because you cannot
buy more than fits.

### Worked example

`P = 0.829`, `D = 7.2 km`, `C = 7.0`, `Q = 40`, `k = 2`, `r = 1.3`:

```
detourLitres = 2 · 9.36 · 7.0 / 100 = 1.31 L
detourCost   = 1.31 · 0.829          = €1.09
purchaseCost = 40 · 0.829            = €33.16
effective    = 34.25 / 40            = €0.856/L
```

The detour costs 2.7 cents per litre bought — which is exactly the
number a user cannot compute in their head, and the reason this engine
exists.

### Break-even quantity

Station `S` beats a reference station `K` (we use the **closest** one)
when `totalCost(S) < totalCost(K)`. Solving for `Q` when `S` is cheaper
but further (`P_K > P_S`):

```
Q* = (k · C / 100) · (D_S · P_S − D_K · P_K) / (P_K − P_S)
```

This is the honest form of "only worth the detour if you buy ≥ Q* L".
When `Q* ≤ 0` the cheaper station wins at any quantity.

## 3. Three rankings, never one "best"

| ranking | objective |
|---|---|
| **Cheapest** | minimum `P` — pure price |
| **Closest** | minimum `D` — minimum effort |
| **Best value** | minimum `effectivePricePerLitre` — economics |

The UI must never claim one station is objectively best **on the strength
of the ranking alone**. It presents the three and explains each. Where one
station holds several titles, they collapse into one card rather than
repeating it.

### 3.1 The conditional lead (#4139)

A driver's actual question is "which stop is worth it", and answering
"here are three rankings" is a worse answer when the inputs are good
enough to give a real one. So the UI MAY lead with Best Value — present
it first and larger — when **all** of these hold:

| condition | why |
|---|---|
| `bestValue` exists | rule 1 already |
| consumption is **measured**, not estimated | rule 2: a lead built on a model reads as a measurement |
| the station is **not known to be closed** | §5's objection — a confident answer at a closed forecourt is the failure that loses a user permanently |
| its price is **not known to be stale** (< 24 h) | §5's other objection |

Any condition failing returns the UI to the three-answer header, and the
other two rankings stay visible in both cases. Leading is a matter of
EMPHASIS; it never removes an answer, and it never invents one.

This is the fourth ranking §5 ruled out, admitted under exactly the
conditions §5 said were missing — not a reversal of the reasoning, an
application of it.

#### A gate the provider cannot answer (#4156)

The last two conditions were originally written as "the station is open
now" and "its price is fresh", and implemented against a `bool?` and a
`Duration?`. That made *unknown* mean *no*, and unknown is the permanent
state of eleven of the seventeen registered countries: their data source
publishes no opening hours for anybody, and eight of the seventeen stamp
no prices. The lead could therefore never fire in most of the app, and
nothing said why.

A provider that has never published a fact has not failed the gate — it
has made the gate inapplicable. The rule is therefore:

- the provider publishes this kind of data and this row lacks it → the
  gate **blocks**. That gap is real and specific to the forecourt we are
  about to send someone to;
- the provider publishes it for nobody → the gate **stands down**, and
  the reason is stated next to the lead (`LeadCaveat`). Rule 1 again: a
  missing input is stated, never defaulted — and "we did not check
  whether it is open, because nobody publishes that here" is a statement,
  where silently passing would not be;
- an actual `false`, or an actual age over 24 h, still blocks. The
  stand-down is about absence, never about a "no" we were told.

Which countries can answer which question is `ProviderCapability`
(#4156), declared per country and read without constructing the service.
The threshold — 24 h — stays here in the spec, where it can be reviewed;
the capability holds no thresholds of its own.

## 4. Trust rules (each is a test)

1. **No consumption, no Best Value.** If `C` is unknown the ranking is
   withheld and the UI says why. It is never silently defaulted.
2. **Estimated consumption is marked estimated.** `FuelConsumptionFigure`
   already carries provenance; an explanation built on an estimate reads
   as an approximation (`≈`), never as a measurement.
3. **No price, no economic rank.** A station without a price for the
   selected fuel can still appear, but not in a cost ranking.
4. **Every claim is reproducible.** A stated saving is
   `totalCost(reference) − totalCost(station)` for the `Q` shown, with
   the reference named. No opaque scores.
5. **Distances are honest.** Crow-flies input is corrected by `r` and
   the result is presented as approximate; a real road distance is used
   whenever the route layer has one.

## 5. Deliberately out of scope for v1

A fourth "Recommended" ranking that folds freshness, opening hours,
availability and reliability into a SCORE. A blended score cannot be
explained — trust rule 4 requires every claim be reproducible, and a
weighted number is exactly the opaque score that rule forbids.

§3.1 admits those same signals as **gates** rather than weights: they
decide whether Best Value may lead, and they never change its value. A
gate can be stated in one sentence ("open now, price from this morning,
consumption measured from your fill-ups"); a weight cannot.

This was ruled out entirely in v1 with the note that "`RefuelEconomics`
is a pure function of its inputs so this can be added later without
touching the UI" — which is what #4139 did.
