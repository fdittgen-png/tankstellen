# Fuel Log & Consumption

Layers 2 and 3 of the [three savings layers](User-en-How-It-Works#the-three-savings-layers): how much you burn, and what it truly cost. The ⛽ **Fuel** tab appears on the **Medium** and **Full** use modes.

---

## The Fuel tab at a glance

<img src="guide/fuel-tab.jpg" width="340" alt="Fuel tab: tank level with range, consumption stats card with accuracy badge, and the fill-up list">

*Three blocks: what's in the tank, what your driving costs, and what you have actually pumped.*

### Tank level and range

The gauge is **anchored to your last full fill-up** and then debited by the fuel your recorded trips consumed. The date stamp under the bar tells you which fill it is anchored to.

Two ranges are shown deliberately:

- **"≈ 548 km at your last tank's consumption"** — recent behaviour, useful today.
- **"Long-run average: ≈ 611 km"** — your historical average, useful for planning.

If they diverge a lot, something changed recently: a roof box, winter, a different route mix, or a fuel switch.

> When an OBD2 adapter is connected and your car exposes the fuel-level PID, the gauge switches to the **tank sensor** and says so. That reading is a measurement, not an inference, and it survives unrecorded driving.

### The consumption stats card

The three badges are the honesty layer:

| Badge | Meaning |
|---|---|
| **Accuracy: High · ±3-7 %** | Both fill-ups and OBD2 trips are feeding the model |
| **Accuracy: Medium** | Fill-ups anchor it, but no OBD2 trip has fed the loop yet |
| **Accuracy: Low** | GPS only, nothing anchored yet — add a couple of full fill-ups |
| **η_v : 0.93 · 6 samples** | The learned volumetric efficiency of the speed-density model and how many samples back it |

Below them: average L/100 km, average cost per km, total litres, total spent, number of fills. Tap the card to open the full [consumption statistics](#consumption-statistics).

---

## Logging a fill-up

Tap **➕ Add fill-up** — or, much faster, tap **Add fill-up** directly on a station's detail page, which pre-fills the station, the fuel and the price.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Fill-up form pre-filled with brand, fuel and price from a recent search">

*Coming from a station, three fields are already right — you type litres, total and odometer.*

| Field | Why it matters |
|---|---|
| **Date** | Orders the tank windows |
| **Vehicle** | Attributes the fill and the calibration |
| **Fuel type** | On a flex-fuel car this is the field the whole comparison hangs on |
| **Litres** | The numerator of the pump truth |
| **Total cost** | Cost per km, monthly spend |
| **Odometer** | **The most important field on the form** |
| **Full tank** | Closes a calibration window — see below |
| Station, notes | Optional |

### Why the odometer is the critical field

Consumption is litres ÷ kilometres. The litres come from the pump receipt and are exact. The kilometres come from *your two odometer readings*. A 20 km typo on a 600 km tank is a 3 % error in the result — and because that result is what recalibrates the estimator, the error propagates into every future trip estimate. The form refuses an odometer lower than the previous fill's, because distance cannot go backwards.

### The "Full tank" tick

Tick it whenever you filled to the brim. That is what turns two fill-ups into a **closed tank window** with a physically true consumption figure.

Partial fills are still recorded, still count for cost, and still show in the list — they simply cannot close a window. The statistics screen shows a banner counting *"partial fills pending a full tank — not in average"* so you always know what is and isn't in the numbers.

### Scanning instead of typing

- **Scan the pump display** — point the camera at the pump's screen; the app reads litres, total and price.
- **Scan the receipt** — same, from the printed slip.
- **Share a receipt photo** from another app straight into the fill-up form.

Recognition runs **on the device**; the image is never uploaded. Always glance at the values before saving — a scan is a head start, not an oracle. If it misreads, the *Report scan error* action files an issue with the crop so the recogniser improves.

> **F-Droid build:** on-device text recognition ships only in the Play / App Store builds. The GMS-free F-Droid build has no scanning — type fill-ups by hand there. Everything else is identical.

---

## The tank report — the moment of truth

Every time a full tank closes, the app publishes a report. On the Trips tab it looks like this:

<img src="guide/trips-tab.jpg" width="340" alt="Tank report card: 6.4 L/100 km, delta vs previous tank, coverage bar and calibration verdict">

*One card, four different statements — and they are deliberately not the same number.*

| Line | What it is |
|---|---|
| **6.4 L/100 km** | The **pump truth** for this tank: litres pumped ÷ odometer km |
| **1.5 L/100 km less than the previous fill** | Trend against the last closed tank |
| **559 km · 35.7 L · €32.12** | The raw window |
| **Recordings cover 81 % of this tank** | How much of those kilometres you actually recorded |
| **Recorded slice: 10.5 L/100 km** | What the *recorded* kilometres alone averaged |
| **Recorded estimates run 39 % over pump truth** | The calibration verdict — the estimator was reading high, and has now been corrected |

### Reading it correctly

The recorded slice and the pump truth **are allowed to differ**, for two separate reasons that are easy to confuse:

1. **Selection.** You record the drives you record. If your recorded 81 % is mostly short urban hops and the unrecorded 19 % is a motorway run, the recorded slice legitimately reads higher than the tank average. Nothing is broken.
2. **Calibration.** The estimator itself may be biased. That is what the last line measures, and it is what gets corrected — by comparing the two **per kilometre**, so coverage cancels out and only affects how much weight the window carries.

After a correction like the one above, expect trip estimates to drop noticeably on the next drive and then settle. See the full mechanism in [How Sparkilo Works → How a litre becomes a number](User-en-How-It-Works#how-a-litre-becomes-a-number).

The card can also point at *what changed* — high-RPM share, harsh events per 100 km, cold starts, idle share, each versus the previous tank — with an explicit caveat that recordings are spontaneous and cover only part of the tank, so those hints are indicative.

---

## Consumption statistics

Tap the stats card, or **Fuel → Consumption stats**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="Statistics header: fuel filter chips, totals, and this-month-vs-last-month table">

*Filter chips at the top scope everything below to one fuel — essential on a flex-fuel car, where a combined average is meaningless.*

The month-on-month table shows litres, spend, average price per litre, average consumption, cost per km and fill count, each with its delta. Red arrows are not judgements — a rise in *spend* after a rise in *price per litre* is the market, not your right foot. The number to watch for driving is **L/100 km**.

### Cost per kilometre by fuel

<img src="guide/consumption-stats-2.jpg" width="340" alt="Cost per kilometre by fuel: E85 and E5 rows with cost/km, L/100 km, price paid and CO2">

*The flex-fuel driver's actual question, answered: not which fuel is cheaper per litre, but which is cheaper per kilometre.*

Each fuel gets a row built from **closed tank windows only**: measured L/100 km, price actually paid per litre, cost per 100 km, total spent, distance measured, litres burned, CO₂ per 100 km, and how many full tanks are behind it. A row backed by a single tank is labelled **Provisional**.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Cost-of-driving verdict card with the winner, the break-even price and the CO2 note">

*The verdict card states the winner, the gap per 1000 km, and — most usefully — the **break-even price**.*

The break-even line ("E5 becomes better than E85 below €0.75/L") is computed from **your own measured consumption of each fuel**, so it moves as your driving changes. That is a decision rule you can use at the pump; a generic ratio from the internet is not.

CO₂ figures are well-to-wheel estimates (EU JEC WTW v5) applied to your measured consumption — awareness, not audit-grade accounting. Blends are excluded from CO₂ because the emission factor depends on the mix, which the row does not record.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Evolution over time: litres per month and spend per month, stacked by fuel">

*The trend charts stack by fuel, so a switch shows up as one colour replacing another rather than as a mysterious jump.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Price per litre and L/100 km per month charts">

*Price per litre and L/100 km are separate charts on purpose — one is the market, the other is you.*

**Export** writes everything to a CSV in your public Downloads folder.

---

## Eco-score per fill-up

Each fill-up is badged against a rolling average of your last three same-fuel fills:

| Delta | Badge | Read it as |
|---|---|---|
| ≥ 3 % better | 🟢 Improving | You burned noticeably less than your own baseline |
| within ±3 % | ⚪ Stable | Normal variation |
| ≥ 3 % worse | 🟠 Worsening | Check tyre pressure, roof box, cold weather, route mix |

The badge stays hidden until you have four fills of that fuel, so the baseline is real.

---

## When the numbers don't add up

Sooner or later you will pump more litres than your recorded trips can account for — someone else drove, the adapter was unplugged, the app was closed. Instead of silently absorbing the difference, the app raises a **gap banner** and offers a short reconciliation:

> *We found a 4.2 L gap. You pumped 35.7 L, but your recorded trips only account for 31.5 L.*

It asks two questions:

1. **Are all your fill-ups for this tank complete and correct?** — No means a fill is missing or mistyped, and the app adds a **correction fill-up** so the litres add up.
2. **Are all your drives recorded?** — No means a drive went unrecorded, and the app adds a **virtual trip** for the missing distance.

Both artefacts are editable and deletable afterwards, and both are labelled as auto-generated so you never mistake one for a real record. You can also choose **Decide later** — the banner stays until you resolve it.

**Why it matters:** an unresolved gap silently biases the calibration window. Resolving it (or deleting the bad entry) keeps the pump anchor trustworthy.

---

## Loyalty cards

**Settings → Driving & consumption → Loyalty cards** stores per-litre discounts for the chains you use. The discount is then applied in price comparisons, so a station that looks 2 c/L dearer can correctly rank as the cheaper one for you. Enable the feature under Features & use mode → Entry & scanning.

---

<details>
<summary>Whole-screen reference — consumption statistics, full page</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Full consumption statistics screen stitched from five captures">

</details>

---

**See also:** [Vehicles & OBD2](User-en-Vehicles-And-OBD2) · [Trips & Eco-Coaching](User-en-Trips-And-Coaching)
**Next:** [Trips & Eco-Coaching →](User-en-Trips-And-Coaching)
