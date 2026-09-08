# How Sparkilo Works

This page is the mental model. Everything else in the guide is a click path; this is *why* the click paths are shaped the way they are. Ten minutes here will save you an hour of hunting through settings.

---

## The three savings layers

A car costs money in three independent ways, and lowering one does nothing for the others:

1. **Price per litre** — the pump you choose. Fixed by geography and the market; the app's job is to show you the cheapest one you can realistically reach.
2. **Litres per kilometre** — how you drive and what you drive. The app's job is to measure it honestly and show you which habit costs the most.
3. **What you actually paid** — the audit trail. The app's job is to keep its own estimates anchored to reality instead of drifting.

Layer 1 works the second you install the app. Layers 2 and 3 need input from you: at minimum your fill-ups, ideally also recorded trips. **The app never pretends to know more than it has been told** — that is why you see accuracy badges, coverage percentages and "provisional" labels rather than confident round numbers.

---

## Use modes: right-sizing the app

Sparkilo can be a two-screen price finder or a full driving computer. Rather than shipping every switch to everybody, it groups features into **use-mode presets**.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Feature management with the Basic, Medium, Full and Custom presets">

*Settings → Features & use mode. Picking a preset flips the whole matching set of feature switches at once; touching an individual switch afterwards moves you to **Custom**.*

| Preset | You get | Bottom bar |
|---|---|---|
| **Basic** | Cheapest fuel and charging nearby, favourites, price alerts, route planning | Favourites · Map · **Search** |
| **Medium** | Everything in Basic + manual fill-up logging, real consumption and cost | + Fuel |
| **Full** | Everything in Medium + automatic OBD2 trip recording, driving scores, loyalty cards | + Trips |
| **Custom** | Your own mix — what you get the moment you flip any single switch | depends |

### How it actually works

A preset is not a mode the app runs in — it is a **named set of feature flags**. Each flag independently hides or shows a feature, and some flags declare prerequisites: *Baseline sync* stays greyed out until *TankSync* is on, *Voice announcements* until *Spoken feedback* is on, *Auto-record* until an adapter is paired. The card explains why a switch is locked instead of silently ignoring your tap.

### What this means in practice

- **Turning a feature off removes it from the UI, not just from view** — its background work stops too. Switching off *Price alerts* stops the periodic background check; switching off *GPS trip path* stops storing route points.
- **Presets are destructive to your custom mix.** Tapping *Medium* overwrites every individual switch. If you have tuned things by hand, stay on Custom.
- **The bottom bar changes shape.** If the Fuel or Trips tab has vanished, you (or a preset) turned off *Consumption tab* or *OBD2 trip recording* — not a bug.

---

## Profiles: one context, one set of defaults

A **profile** bundles everything that depends on *where and how you are driving right now*: country, language, preferred fuel, default search radius, home postal code, route-planning parameters, landing screen, station notes visibility, the Fuel Station Radar settings and the default vehicle.

<img src="guide/profile-edit-1.jpg" width="340" alt="Edit profile — name, preferred fuel derived from the vehicle, default radius">

*Settings → Profiles & region → edit. The preferred fuel is **derived from your default vehicle** — remove the vehicle if you want to pick a fuel by hand.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Region section of the profile — country and language pickers">

*Country and language live inside the profile, which is why switching profiles can switch data source and interface language in one tap.*

### How it actually works

The country stored in the active profile decides **which national open-data provider the app calls**. Changing it clears cached station data, because prices from the old country's provider are meaningless for the new one. The preferred fuel decides which price is the headline number on every card, which fuel a price alert defaults to, and which grade a route search optimises for.

### What this means in practice

- **One profile per country you drive in.** "Home — Germany, E10, 10 km" and "Holiday — Spain, E5, map landing" are two profiles, not two settings sessions.
- **Cross-border route searches use each country's own profile fuel.** Without a profile for the second country, that leg of the corridor has no fuel grade to price and its stations show `--`.
- **Automatic profile switching** (Settings → Data sources & location) can flip the profile for you when GPS says you crossed a border.
- Settings tiles carry a **scope label** — *this profile*, *all profiles*, or *this vehicle* — so you always know how far a change reaches.

---

## One data source per country

Sparkilo does not aggregate. Each country is queried through its own official source, and the result header names it.

<img src="guide/search-results.jpg" width="340" alt="Result header naming the French government price source">

*The line under the app bar is not decoration — it tells you which authority published these prices, and links to it.*

### How it actually works

| Country | Source | Cadence |
|---|---|---|
| Germany | Tankerkönig (needs your own free key) | ~5 minutes |
| France | Prix-Carburants (gouv.fr) | continuous, per station |
| Spain | Geoportal Gasolineras (MITECO) | daily bulk file, filtered on device |
| Italy | MIMIT bulk file | daily bulk file, filtered on device |
| …and 13 more | each country's own open-data portal | varies |

### What this means in practice

- **Fuel grades differ across a border.** Spain sells E5 and rarely E10; France lists SP95-E10 prominently; Germany publishes E5, E10 and Diesel. The same physical fuel can carry three names in three countries.
- **Freshness differs.** A German price can be five minutes old; a Spanish one can be yesterday's bulk publication. The freshness badge on each card tells you which you are looking at — trust it more than the number.
- **Density differs.** A thin national dataset returns fewer stations in the same radius. That is the country's data, not a failed search.
- **A `--` instead of a price means "this provider does not report that grade for this station"** — not "the station doesn't sell it".

---

## Where your data lives

Sparkilo is **local-first**. Everything it knows is in encrypted databases on your phone; the encryption key is in the Android Keystore / iOS Keychain.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Data on this device: every data category held locally, with size and count">

*Settings → Privacy & data → Data on this device shows every category with a live count, so nothing about your data is invisible to you.*

Only four things ever leave the phone, and three of them are optional:

| Leaves the phone | When | Optional? |
|---|---|---|
| Search coordinates or a region code | Every search, to that country's price source | Required for live prices |
| Map viewport + your IP | Map tile fetch through the developer's EU proxy | Yes — turn the proxy off and tiles come straight from OpenStreetMap |
| Crash traces | Only with *Error reporting* on | Yes — off by default |
| Your synced rows | Only with *TankSync* on | Yes — off by default |

**Your identity is never part of a price query.** See [Privacy, Profiles & Sync](User-en-Privacy-Profiles-Sync) for the full accounting.

---

## How a litre becomes a number

This is the part most fuel apps get quietly wrong, so it is worth understanding.

### The pump is the truth

The only physically certain figure the app ever gets is **litres pumped ÷ kilometres driven between two full tanks**. Everything else — GPS estimates, MAF-derived flow, speed-density modelling — is a model that can drift.

So the app treats every **full-to-full tank window** as a calibration event:

1. You log a fill-up and tick **Full tank**. That closes the previous window.
2. The app computes the window's *pump truth*: litres pumped ÷ odometer kilometres × 100.
3. It compares that with what its own estimator produced over the kilometres it actually recorded, with every previously applied correction stripped out.
4. The ratio between the two becomes the vehicle's **pump gain**, blended with earlier windows and bounded to a sane range.
5. That gain then multiplies **every estimated fuel-rate branch** — speed-density and MAF — on the next trip.

Fuel your car *reports itself* over OBD2 (PID 5E / 9D) is measured, not modelled, so it is never touched by the gain.

<img src="guide/trips-tab.jpg" width="340" alt="Tank report card showing coverage and the calibration delta">

*The tank report is the calibration made visible: this tank ran at 6.4 L/100 km at the pump, recordings covered 81 % of it, and the estimator was running 39 % high before this window corrected it.*

### Why coverage doesn't bias it

Comparing the two figures **per kilometre** means the kilometres nobody recorded simply carry no weight. A tank you only recorded a fifth of still yields an unbiased ratio — it just counts for less in the blend. That is why the app shows you a coverage percentage instead of hiding it: it tells you how much to trust *this* window, not whether the calibration is valid.

### The accuracy ladder

| Badge | What is behind it | Typical band |
|---|---|---|
| **Low** | GPS only — no fill-up has anchored anything yet | ±15 % and worse |
| **Medium** | Fill-ups have anchored the model, but no OBD2 trip has fed the loop | ±7–15 % |
| **High** | Fill-ups *and* OBD2-recorded trips | ±3–7 % |

### What this means in practice

- **Always tick "Full tank" when you fill to the brim.** A partial fill is still logged and still counts for cost, but it cannot close a calibration window. Partial fills waiting for a full tank are shown as a banner on the statistics screen.
- **Odometer accuracy matters more than litre accuracy.** A 2 % odometer typo poisons the window; a 0.2 L rounding does not.
- **The first window is taken at face value; later ones smooth.** Expect the estimate to jump once, then settle.
- **If you drive without recording, the numbers won't add up** — and the app says so rather than fudging it. See the reconciliation flow in [Fuel Log & Consumption](User-en-Fuel-And-Consumption#when-the-numbers-dont-add-up).

---

## How the app learns your driving

Separately from the pump gain, a vehicle carries a **driving-situation baseline**: what your car consumes while idling, in stop-and-go, in town, on the motorway, decelerating, climbing or loaded, from cold, under sustained load, and coasting.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Baseline calibration with per-situation sample counts and a missing-situations warning">

*Each situation fills independently. The warning is honest: two situations still have zero samples, so the profile is incomplete.*

### How it actually works

Every OBD2 sample is classified into a driving situation and added to that bucket. Two classification modes exist:

- **Rule-based** — each sample is assigned to exactly one situation. Crisp, but a car cruising at 60 km/h flips between "urban" and "highway" from one sample to the next.
- **Fuzzy** *(default)* — each sample is spread across all situations by how well it fits each. Smoother exactly at the boundaries where rule-based is jumpy.

### What this means in practice

- **A baseline is per vehicle, not per phone.** Changing cars means starting a new one; *Baseline sync* (needs TankSync) carries it to a second device.
- **Missing situations are honest gaps, not errors.** If you never tow, "Sustained load / towing" will read 0 forever, and the app will keep saying the profile is incomplete. That is fine.
- **Resetting the baseline drops you back to cold-start defaults** until new trips refill it — do it after a mechanical change, not because a number looked odd.

---

## The one settings rule worth memorising

Settings is a **two-level tree**: a root of topic tiles, one screen per topic, and a search field that filters the tiles by keyword.

<img src="guide/settings-root-1.jpg" width="340" alt="Settings root with topic tiles and the search field">

*Every parameter has exactly one home. If you remember the topic, you never have to scroll.*

Full map of every screen: [Settings Reference](User-en-Settings-Reference).

---

**Next:** [Finding Stations →](User-en-Finding-Stations)
