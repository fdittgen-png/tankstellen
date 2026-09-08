# Sparkilo — User Guide (English)

> *Pay less per litre. Burn fewer of them per kilometre. See exactly what you spent.*

Sparkilo is a free, open-source app for **cutting the running cost of your car**. No account, no ads, no trackers, no Google Play Services. Everything it knows about you lives on your phone until you explicitly switch something on.

*The one screen you'll use most: live prices near you, cheapest first, with the official open-data source named at the top.*

---

## The three savings layers

The whole app is organised around one idea: **there are three separate ways a car costs you money, and they need three different tools.**

| Layer | The question it answers | Where it lives |
|---|---|---|
| **1. Price** | *Where is fuel cheapest right now?* | Search, Map, Favourites, Alerts, Route planning |
| **2. Consumption** | *How many litres do I burn per 100 km, and why?* | Trips, eco-coaching, OBD2 |
| **3. Truth** | *What did I actually pay, and is the app's estimate honest?* | Fuel tab, fill-ups, consumption statistics |

Layer 1 alone already saves money and needs nothing but the app. Layers 2 and 3 need you to log fill-ups; layer 2 gets much sharper with a cheap OBD2 adapter. You decide how far down you go — see How Sparkilo Works.

---

## What's in this guide

**Start here**

| Page | What you'll learn |
|---|---|
| Getting Started | Install, first-launch consent, country and language, choosing a use mode, your first search |
| How Sparkilo Works | The concepts behind everything: profiles, use modes, one data source per country, where your data lives, and how a litre becomes a number |

**Finding cheap fuel (layer 1)**

| Page | What you'll learn |
|---|---|
| Finding Stations | The central Search button, criteria, reading a station card, station detail, the map, the Fuel Station Radar |
| Route Planning | Cheapest stops along a route, cross-border corridors, the four strategies |
| Favourites & Alerts | Saved stations, per-station and radius alerts, how the background check really behaves |
| EV Charging | Charging points via OpenChargeMap, connectors, power filters |
| Price History & Predictions | The local 30-day history, "best time to fill", and what the algorithm deliberately does *not* do |

**Burning less and knowing what you spent (layers 2 and 3)**

| Page | What you'll learn |
|---|---|
| Vehicles & OBD2 | The vehicle model, tank size, flex-fuel, adapter pairing, baseline calibration, rule-based vs fuzzy |
| Fuel Log & Consumption | Fill-ups, tank level, the tank report, accuracy levels, cost per km by fuel |
| Trips & Eco-Coaching | Recording with GPS or OBD2, the trip detail, driving score, the carbon dashboard |

**Reference**

| Page | What you'll learn |
|---|---|
| Settings Reference | Every screen of the two-level settings tree, with the operational impact of each switch |
| Privacy, Profiles & Sync | Consents, the Privacy & data topics, TankSync, backup, your GDPR rights |
| Troubleshooting & FAQ | Nothing found? Adapter won't connect? Widget stale? |

---

## The 17 supported countries

🇩🇪 Germany · 🇫🇷 France · 🇦🇹 Austria · 🇪🇸 Spain · 🇮🇹 Italy · 🇩🇰 Denmark · 🇵🇹 Portugal · 🇱🇺 Luxembourg · 🇸🇮 Slovenia · 🇬🇧 United Kingdom · 🇦🇷 Argentina · 🇦🇺 Australia · 🇲🇽 Mexico · 🇰🇷 South Korea · 🇨🇱 Chile · 🇬🇷 Greece · 🇷🇴 Romania

Each country is served by **its own official government open-data source** — never a single aggregator. Germany needs a free API key from [tankerkoenig.de](https://creativecommons.tankerkoenig.de/); every other country works out of the box. Why that matters for what you see on screen is explained in How Sparkilo Works.

The interface is translated into **23 languages** (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) and follows your system locale.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="80"/>
</a>

---

**Next:** Getting Started →

> **A note on the screenshots.** All screenshots in this guide come from one device running the app in **French**, against the live French price source. The interface is fully localised — your screens carry the same layout with your own language's words.

---

# Getting Started

Ten minutes from install to your first saved euro. If you only read one other page afterwards, make it How Sparkilo Works.

---

## 1. Install

### Google Play (Android)

Install from the **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — the public production release.

> **Coming from the beta?** Play keeps serving beta builds once you have joined Open Testing (the listing shows a *(beta)* tag). To move to production: open the [Play listing](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Leave the programme** → uninstall → reinstall.
>
> **Want features first?** Stay in the beta instead — every build reaches the beta channel before production.

### F-Droid (Android, Google-free)

A fully **GMS-free** build ships through its own F-Droid repository (OpenStreetMap maps, no Google services). In F-Droid open **Settings → Repositories → +** and add:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Then search for **Sparkilo**. If the Play build is installed, uninstall it first — different signing key, so it cannot update over it.

### Other ways

- **APK** — from [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — TestFlight beta; request an invite via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) until the App Store listing is live.

**Minimum Android** 7.0 (API 24), target Android 15. **Minimum iOS** 15.5, target iOS 18.

No account, no sign-up, no e-mail. The app is fully usable the moment it finishes installing.

---

## 2. First launch — consent

Before any other screen, the app shows a **GDPR consent screen**. It is not a cookie banner: it lists each processing purpose, and the app proceeds only when you accept.

*Every consent shown here is listed again later in Settings → Privacy & data, with the date you gave it and the policy version you saw.*

| Item | Why | If you decline |
|---|---|---|
| **Location** *(while in use)* | Nearby search, route start, trip recording | Search by postal code or pick a point on the map |
| **Notifications** | Price alerts only | Alerts never fire |
| **Diagnostics** | Crash traces to Sentry — **off by default** | Nothing is sent; you can still save the error log yourself |

Before each *system* permission prompt (camera, Bluetooth, notifications) the app shows its own short explanation first, so you know what you are agreeing to before Android asks.

Full text: **[Privacy policy v3, 29 August 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. Country, language and your home area

Both are auto-detected from your system locale, and both live **inside your profile** — see How Sparkilo Works → Profiles.

*Settings → Profiles & region → edit your profile. The home postal code lets you search a fixed area without ever handing over GPS.*

Changing the country **clears cached station data**, because prices from the previous country's provider don't apply to the new one. Expect the next search to take a moment longer.

---

## 4. Pick a use mode

This is the single most consequential setting, because it decides how much app you get.

*Settings → Features & use mode. Start on **Basic** if you only want cheaper fuel; move up when you want to know why your car drinks.*

- **Basic** — find cheap fuel and charging, favourites, alerts, routes.
- **Medium** — adds the **Fuel** tab: log fill-ups, see real consumption and cost. No hardware needed.
- **Full** — adds the **Trips** tab: automatic recording, driving scores, loyalty cards. An OBD2 adapter is optional even here — trips record on GPS alone.

You can move between presets any time, and any individual switch you flip afterwards puts you on **Custom**. The full list of switches, and what each one costs you in battery, data or privacy, is in Settings Reference → Features & use mode.

---

## 5. Germany only: the free API key

16 of the 17 countries work instantly. **Germany's** official price service issues a per-user key.

*Settings → Data sources & location. A red cross here is the reason a German search returns nothing.*

1. Open [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/), request a key (short form, free).
2. Copy it — it is a UUID like `00000000-0000-0000-0000-000000000002`.
3. Paste it into the **Fuel prices (Tankerkoenig)** slot.

The key is kept in the hardware-backed vault (Android Keystore / iOS Keychain) and is only ever sent to the German price service. The **EV charging** slot below already carries a shared built-in key, so charging data works without any setup.

---

## 6. The bottom bar

*The raised green **Search** button in the middle notch is the only search trigger in the entire app.*

- ⭐ **Favourites** — saved stations and your price alerts
- 🗺️ **Map** — every nearby station as a price-coloured pin
- 🔍 **Search** *(centre)* — nearby or along a route
- ⛽ **Fuel** — tank, consumption, fill-ups *(Medium and up)*
- 🛣️ **Trips** — logbook and coaching *(Full)*

Settings is **not** a tab: it is the gear icon in the top-right of the main screens. On a tablet, or a phone held sideways, the app splits into two columns so a list and the map (or a detail) are visible at once.

---

## 7. Your first search

*Tap **Search** → the criteria sheet opens pre-filled from your profile. Adjust, then tap **Search** again to run it.*

You get a list sorted cheapest-first (or by distance — your choice), each card showing price, trend, distance and how fresh the number is. Tap any card for the full station detail. The complete tour is in Finding Stations.

**Tip:** tap **Save as defaults** at the bottom of the sheet once you have the criteria you use most — every future search starts there.

---

## 8. Two settings worth changing on day one

*Settings → Units & display. **Consumption unit** is *Automatic* by default (mpg in the UK, L/100 km elsewhere); pick L/100 km, km/L or mpg explicitly if you prefer.*

The second is **Settings → Driving & consumption → Live consumption window** (3 / 5 / 10 / 30 s). It controls the big live figure on the recording screen: a longer window is steadier to read while driving, a shorter one reacts faster to your right foot.

---

## 9. Choose what the app opens on

**Settings → Profiles & region → Start screen**: *Nearby* (instant search with your last criteria), *Nearest station*, *Favourites*, or *Map*. Pick the one that matches why you open the app.

---

## 10. Where everything lives

Settings is a two-level tree with a keyword search at the top — type "radius", "OBD2" or "theme" and the matching tile surfaces.

*Twelve topics, one home per parameter. The full map is Settings Reference.*

---

**Next:** How Sparkilo Works →

---

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

*Settings → Profiles & region → edit. The preferred fuel is **derived from your default vehicle** — remove the vehicle if you want to pick a fuel by hand.*

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

*Settings → Privacy & data → Data on this device shows every category with a live count, so nothing about your data is invisible to you.*

Only four things ever leave the phone, and three of them are optional:

| Leaves the phone | When | Optional? |
|---|---|---|
| Search coordinates or a region code | Every search, to that country's price source | Required for live prices |
| Map viewport + your IP | Map tile fetch through the developer's EU proxy | Yes — turn the proxy off and tiles come straight from OpenStreetMap |
| Crash traces | Only with *Error reporting* on | Yes — off by default |
| Your synced rows | Only with *TankSync* on | Yes — off by default |

**Your identity is never part of a price query.** See Privacy, Profiles & Sync for the full accounting.

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
- **If you drive without recording, the numbers won't add up** — and the app says so rather than fudging it. See the reconciliation flow in Fuel Log & Consumption.

---

## How the app learns your driving

Separately from the pump gain, a vehicle carries a **driving-situation baseline**: what your car consumes while idling, in stop-and-go, in town, on the motorway, decelerating, climbing or loaded, from cold, under sustained load, and coasting.

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

*Every parameter has exactly one home. If you remember the topic, you never have to scroll.*

Full map of every screen: Settings Reference.

---

**Next:** Finding Stations →

---

# Finding Stations

Layer 1 of the three savings layers: pay less per litre.

---

## One button, one mental model

The bottom bar has one search trigger — the raised green button in the middle notch. It is context-aware rather than modal:

- **From any tab** → opens the criteria sheet.
- **From the results or the map** → re-opens the criteria sheet with what you last used.
- **Inside the sheet** → runs the search.

The button label changes to say what it will do, and in route mode it stays disabled until there is a destination to route to. There are deliberately no separate "search nearby" and "search along route" buttons.

---

## Setting the criteria

*The sheet opens pre-filled from your active profile — you usually only change one thing.*

| Control | What it does | Operational impact |
|---|---|---|
| **Nearby / Along route** | Switches the whole search mode | Route mode needs a destination and queries every country in the corridor |
| **Address, postal code or city** | Search a place instead of your GPS position | Nothing about your location leaves the phone; the place name is geocoded via OpenStreetMap Nominatim and cached 24 h |
| **Fuel chips** | Which grade the prices are for | The chip list adapts to what your country's provider actually publishes |
| **Radius** | How far to look | A big radius on a dense country returns a lot of stations and a slower search |
| **Open now** | Hides closed stations | Depends on the provider publishing opening hours — some don't |
| **Amenities** | Shop, car wash, air, WC… | Filters on reported data only; a station with an empty amenity field disappears |
| **Brands** | Restrict to specific chains | Counted from the current result set, so the list changes with the radius |
| **Save as defaults** | Writes these criteria into the profile | Every future search starts here |

### The search button

The raised button in the middle of the bottom bar is the only search
trigger. From any tab it opens this sheet; from the results or the map it
re-opens it with what you last used; inside the sheet it runs the search.

### Nearby or along a route

Two different questions. **Nearby** searches around your position or an
address. **Along route** needs a destination and measures distance along
the corridor rather than as the crow flies, so a station 2 km away down a
side road ranks behind one on your way.

### Fuel type

Which grade the prices are for. The chips adapt to what your country's
provider actually publishes — a grade missing from the list is missing
from the data, not from the app.

### Radius

How far to look. A wide radius in a dense country returns a lot of
stations and a slower search, and the extra stations are usually further
than the saving is worth.

### Open now only

Hides stations that are closed. It depends on the provider publishing
opening hours, and some do not — where they are missing the station is
kept rather than guessed at.

### Amenities

Shop, car wash, air, WC. These filter on **reported** data: a station
that publishes nothing about its amenities disappears from a filtered
list even if it has all of them.

### Motorway stations

Motorway stations are usually the most expensive fuel in the country, so
excluding them is the single filter that most often changes what you
pay. Keep them when you cannot leave the motorway.

### Save as my defaults

Writes these criteria into your profile, so every later search starts
here instead of from the app's own defaults. It is the setting that makes
the sheet a one-tap confirmation rather than a form.

### How it actually works

A nearby search sends **your coordinates (or a region code) and a radius** to your country's official price provider — never your identity. Countries that publish a daily bulk file (Spain, Italy) are filtered on the device instead, so those searches need no per-search network call at all once the file is cached.

---

## Reading a result card

*Everything a decision needs, without opening anything.*

- **Price** — for the fuel you searched, in your country's convention (note the trailing superscript tenth-of-a-cent).
- **Trend arrow** ▲▼▬ — where this station's price has been going lately, from *your own* local history.
- **★** — tap to favourite; a filled star means it's already saved.
- **Amenity chips** — shop, car wash, air, ATM, as reported.
- **Distance** — crow-flies from your position.
- **"Updated 31/08 00:01"** — the freshness stamp. **Read this before the price.**
- **Sort row** — Distance / Price / A–Z / 24 h, plus a stale-data warning chip when the newest price in the list is more than an hour old.

### Freshness, and why it matters more than the price

| Badge | Age | What to do |
|---|---|---|
| Green | < 5 min | Trust it |
| Yellow | 5–30 min | Fine for a decision |
| Orange | hours | Plausible; the provider may publish slowly |
| Red outline | > 1 day | Treat as indicative only — refresh before driving out of your way |

Freshness is a property of the **country's provider**, not of the app. A Spanish price that is 14 hours old is not a bug: that country publishes once a day. See How Sparkilo Works → One data source per country.

### Swipe actions

- **Swipe right** — open in your navigation app (Google Maps, Waze, OsmAnd, Organic Maps).
- **Swipe left** — hide the station from every future result. Un-hide from **Privacy & data → Data on this device → Ignored stations**.

---

## Station detail

*Tap a card. The brand header falls back through brand → name → street, so an Intermarché with an empty brand field still reads "Intermarché".*

The top block is the **full price table** — every grade the provider reports for this station, with `--` where it reports none. That is the fastest way to see whether the cheap E85 station also has a competitive diesel.

**Add fill-up** right there pre-fills the station, the fuel and the price into the fill-up form — the single biggest time-saver in the app if you log your fills.

*Below the fold: services, accepted payment methods, your own private star rating, and the 30-day local price history.*

The app-bar actions are, left to right: **set a price alert**, **scan a payment QR code**, **report a wrong price to the community**, and **favourite**.

---

## The map

*Colour is relative to what is on screen: green is the cheapest visible, red the dearest. The footer states the station count, the radius and the age of the data.*

- **Cluster markers** collapse pins as you zoom out; tap to zoom in.
- **Long-press** anywhere to drop a marker and search from that point.
- The **EV toggle** (top right) flips the map to charging points — see EV Charging.
- **Share** sends the current view to someone else.

Tiles come from OpenStreetMap. By default they are fetched through the developer's EU proxy so that OpenStreetMap never sees your IP; you can switch the proxy off in Settings → Privacy & data and go direct instead. The F-Droid build never uses the proxy.

---

## The Fuel Station Radar

A one-tap live scan around your current position, designed for use **while driving**.

*After any nearby search, a floating pill appears bottom-right. One tap starts the radar.*

### How it actually works

The radar refreshes your GPS fix, fetches station **locations** across a wide 60 km corridor and merges a direct in-radius fetch, so it can never show less than a normal search. Forecourts don't move, so those locations are cached for up to an hour and reused between taps; only the **price** of a station you are actually approaching is fetched just in time. That is what keeps a continuously running radar cheap in both data and battery.

*Running: results sorted by distance, each with a proximity bar that fills as you close in.*

### While a trip is recording

The radar pins a **Closest station** card to the top of the recording screen — name, price for your fuel, distance, and a bar that fills to 100 % on arrival. Swipe left/right to page through the ranked candidates. Cross inside the configured approach radius and the picture-in-picture tile flips to a large price display; see Trips & Eco-Coaching → Approach overlay.

### Settings that change its behaviour

All under **Settings → Driving & consumption**: the **radius** at which the overlay enlarges, whether it shows the **nearest** station or the **cheapest in radius**, the **minimum refresh interval** (a floor, not a fixed rate — it queries faster at higher speed but never tighter than this), and **auto-pin**, which keeps the screen awake and hides the system bars for dash-mount use at the cost of battery.

---

## The fuel-cost calculator

Three numbers in — distance, your consumption, the fuel price — and out come litres burned, total cost and cost per kilometre. It pre-fills your consumption and the current price from your own data, so usually you only type the distance.

It exists to answer one question honestly: *is the station 12 km further away actually cheaper once I have driven there?*

---

## Home-screen widget

- Shows your cheapest favourite (or the nearest station) and its current price.
- **Tap the widget** → opens that station's detail, whether the app was warm or cold-killed.
- **Tap the refresh icon** → re-pulls prices in the background without opening the app.
- Background refresh runs every 30 min while charging, hourly otherwise, and respects Doze.

Appearance and content variant (*current price* vs *predictive: best time to fill*) are set per profile in **Settings → Units & display → Home-screen widget**.

---

## Android Auto

Connected to an Android Auto head unit, the app offers two driver-safe screens: **Search** (the stations from your last phone-side search) and **Radar** (cheapest around your current route). Run the search on the phone first — the car side is deliberately read-only, because there is no safe way to type while driving. Android only; there is no CarPlay build.

---

<details>
<summary>Whole-screen reference — station detail, full page</summary>

</details>

---

**See also:** Route Planning · Favourites & Alerts · Price History
**Next:** Route Planning →

---

# Route Planning

Not "cheapest near me" but **cheapest on the way** — the difference is worth several euros on any long drive.

---

## Starting a route search

*Tap **Search** → switch to **Search along route**. The Search button stays disabled until a destination and a fuel grade are set.*

| Field | Meaning |
|---|---|
| **Start** | Your current position, or a typed city / postal code |
| **Add a stop** | Intermediate waypoints — the corridor follows them |
| **Destination** | City, postal code or coordinates |
| **Fuel** | The grade to price along the corridor |
| **Route segment** | Show the cheapest station every *n* km (50–1000 km) |
| **Max detour** | How far off the direct line a station may sit |
| **Minimum saving** | Hide stops that don't beat the corridor average by at least this much; *Off* shows everything |

*The same open-now / amenity / brand filters as a nearby search apply to the corridor.*

### How it actually works

1. The app calls the public **OSRM** open routing service to get the road polyline for your route.
2. It samples candidate points along that polyline, spaced by your **route segment** setting.
3. Around each sample point it queries the price provider **of whichever country that point is in**, using the fuel grade from that country's profile.
4. It ranks candidates within each segment by your chosen strategy and the **max detour** limit.

### What this means in practice

- **Segment length is the real control.** 50 km on a 600 km drive gives you twelve shortlists; 200 km gives you three. Pick it to match how often you actually stop.
- **Max detour is measured off the direct route**, not from you. 5 km means "up to 5 km of extra driving to reach it".
- **Long routes take longer.** A 500 km corridor samples many points across possibly several providers.
- If the start is *auto GPS* and you lose signal, the search falls back to the last known fix.

---

## Cross-border corridors

When a route crosses a border, **every country in the corridor is queried through its own provider**, and the result header credits all of them:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Because grades differ by country, a cross-border result legitimately shows E85 on the French leg and Gasolina 95/E5 on the Spanish leg. They are priced correctly for each side, never averaged.

**You need a profile per country** with the right preferred fuel, otherwise the second leg has no grade to price and its stations render `--`. See How Sparkilo Works → Profiles.

---

## Results stream in

One slow national API should not hold up the rest of the corridor, so results arrive **progressively**: each country's stations appear as that provider answers, with a banner naming the sources still pending. Tap a cheap result the moment it lands — you don't have to wait for the slowest country.

---

## The four strategies

### 🏆 Best stops *(default)*
Surfaces the 3–5 cheapest realistically-reachable stations as ranked chips at the top. Detours stay small. This is what most drivers actually want.

### 🎯 Cheapest
The single lowest-priced station on the whole route. Best when you refuel once and want the maximum per-litre saving.

### ⚖️ Balanced
Scores each candidate on price *and* proximity to the line. A station 5 km off but 10 c/L cheaper wins; one 50 km off has to be dramatically cheaper.

### 📏 Uniform
Splits the route into equal segments and proposes one stop per segment. Best for long cross-border drives with multiple refuels.

The default strategy, along with segment length, max detour, minimum saving and how many candidates are considered per sampling point, is stored **per profile**:

*Settings → Profiles & region → edit → Route planning. Set it once here instead of adjusting the sheet on every trip.*

---

## Reading the results

Each row adds two numbers a nearby search doesn't have:

- **Distance from start** — how far along the route the station sits, so you can match it to when your tank will actually be low.
- **Detour** — the extra kilometres versus the direct line.
- **Saving vs. average** — against the corridor average, not a national one.

Switch to **All stations** to see every station along the route rather than the shortlist. The map draws the polyline with all pins.

---

## Avoiding motorways

**Settings → Profiles & region → Display & stations → Avoid motorways** makes the router prefer secondary roads. This changes the *polyline*, so it changes which stations are candidates at all — motorway service stations disappear from the corridor rather than merely being deprioritised. Useful precisely because motorway fuel is usually the most expensive on any route.

---

## Saved itineraries

Tap **Save route** on the results screen. Saved itineraries appear at the top of the route form; tapping one re-runs the same corridor with **fresh prices**. The route geometry is stored, not the prices.

---

**See also:** Finding Stations · Settings Reference
**Next:** Favourites & Alerts →

---

# EV Charging

Sparkilo is not only for combustion cars. Charging points come from [OpenChargeMap](https://openchargemap.org), the largest open community registry of chargers worldwide.

---

## Turning it on

Two independent switches, both in **Settings → Features & use mode → Search & map**:

- **EV charging** — the feature itself (search, detail pages, favourites).
- **Show charging stations** — whether chargers appear in results and on the map.

*You can show fuel stations, charging points, or both. An EV-only driver typically turns **Show fuel stations** off.*

Then create an EV vehicle under **Settings → Vehicles & OBD2 → My vehicles → Add**, choosing **Electric** as the drivetrain. An EV vehicle carries battery capacity (kWh), maximum AC and DC charging power (kW) and its supported connectors (Type 2, CCS, CHAdeMO, Tesla, Schuko, Type 1, 3-pin). Searches then filter down to chargers your car can actually use.

---

## How the data works

*Settings → Data sources & location. The **EV charging (OpenChargeMap)** slot ships with a shared key, so charging works with zero setup.*

The app queries the OpenChargeMap POI API live for the area you are looking at, and caches what it gets so the last results survive going offline.

### Why you might want your own key

The built-in key is shared across every Sparkilo user and is therefore rate-limited as a pool. A personal key gives you your own quota and lets OpenChargeMap see genuine usage of its data. It is free:

1. Register at [openchargemap.org](https://openchargemap.org).
2. Open **My Profile → My Apps**.
3. **Register an Application**, describe it briefly, and the API key (a UUID) is issued instantly.

Paste it into the EV slot. It is stored in the same hardware-backed vault as the German price key, never leaves the device, and is only ever sent to OpenChargeMap. Clear the field to fall back to the shared key.

### The fallback that looks like a bug

If OpenChargeMap cannot be reached at all, the app draws a small **built-in demo dataset** rather than an empty map. If you see the same handful of generic chargers in every town, that is the fallback telling you the live fetch failed — check connectivity or your key, don't trust those pins.

### Contributing back

OpenChargeMap is community-maintained. A missing or wrong charger is fixed at [openchargemap.org](https://openchargemap.org), not in this app — and the fix then reaches every OCM-based app, including this one, on the next fetch.

---

## Searching

*The EV toggle in the map's app bar flips the pins from fuel to charging. Pin colour tracks power: light blue AC, dark blue DC.*

From the criteria sheet, pick the **EV** type and run a radius search. Filters available: connector types, minimum kW, and only-currently-available where the operator reports live status.

---

## A charger's detail page

- **Connectors** — type, quantity and maximum power each
- **Tariff** — per kWh where the operator publishes it (many don't)
- **Network** — Ionity, Fastned, Tesla, …
- **Availability** — real-time when reported
- **Amenities** — food, restrooms, shopping (they matter more when you are parked for 30 minutes)
- **Opening hours** — 24/7 or operator-specified
- **Reviews** — from OpenChargeMap contributors

---

## Favourites and logging

Chargers can be favourited exactly like fuel stations; on landscape and tablet the favourites and alerts panes render side by side. The favourite card shows **kW per connector**, **how many are free right now**, and the **connector types**.

Price alerts are of limited use for charging because most operators use flat per-kWh tariffs. Charging sessions are logged like fill-ups: **Fuel tab → Add**, with kWh instead of litres, which feeds the same cost-per-kilometre statistics as combustion fill-ups.

---

## Crossing borders

There is deliberately **no country filter** on charging. Drive from Germany into France and you see both countries' infrastructure on the same map. Fuel prices are national datasets; charging is one worldwide dataset, so the "one profile per country" rule does not apply here.

---

**See also:** Finding Stations · Fuel Log & Consumption
**Next:** Vehicles & OBD2 →

---

# Favourites & Price Alerts

The ⭐ tab is your shortlist plus the robots that watch it for you.

---

## Favourites

*Two tabs at the top: **Favourites** and **Price alerts**. Each card carries all reported grades, not just your preferred one.*

Mark a station with the ★ on any result card or on its detail screen.

### What is actually stored

A favourite is not a bookmark — it is a **full local copy** of the station: identifier, address, amenities, accepted payments, opening hours and the last prices seen. That is why the tab still works with no network: you see the last-known prices, clearly marked by their freshness stamp.

### What this means in practice

- **Favourites work offline**; searches do not. Before a trip into poor coverage, open the tab once on Wi-Fi to refresh the cache.
- Prices refresh when you open the tab, not continuously.
- Favourites are one of the categories **TankSync** mirrors between your devices, if you turn it on.

### Sort and swipe

Sort by price (cheapest first, default), distance or alphabetically. **Swipe right** opens the station in your navigation app; **swipe left** removes it, with an undo snackbar.

### EV chargers

Charging points can be favourited too, and the card shows what an EV driver needs: per-connector **power in kW**, how many are **available right now**, and the **connector types**.

### Landscape and tablets

On landscape phones and any screen wider than 600 dp, favourites and alerts render **side by side** with a divider instead of behind a tab switcher. Both panes are visible at once, so there is no toggle in that layout.

---

## Price alerts

*Three counters at the top — active rules, hits today, hits this week — then the two kinds of alert. The footer stamps the last background check.*

There are two kinds, and they answer different questions.

### Station alert — "tell me when *this* pump gets cheap"

Created from a station's detail page (the bell icon). Pick the fuel, set a threshold, save. Best for the station you already use: your commute stop, the supermarket forecourt near home.

### Zone alert — "tell me when *anywhere near here* gets cheap"

*Settings → Prices & alerts → Price alerts → **Create a zone alert**.*

| Field | What it does |
|---|---|
| **Label** | Free text so a list of alerts stays readable ("Diesel near home") |
| **Fuel type** | One grade per alert — a station can have several alerts on it |
| **Threshold (€/L)** | Fires when any station in the zone drops **below** this |
| **Radius (km)** | The watched area around the centre point |
| **Check frequency** | How often the background task looks — see below |
| **Use my position / Pick on map / Postal code** | Three ways to set the centre; a postal code never touches GPS |

Best for "ping me whenever diesel drops below €1.60 anywhere within 5 km of home", when you don't care which forecourt wins.

---

## How the checking actually works

A background task, scheduled by the operating system, wakes up and:

1. Fetches live prices for the stations behind your alerts.
2. Compares each with its threshold.
3. Fires a **local notification** if any price is below. Tapping it opens that station.

The cadence is **every 30 minutes while charging, hourly otherwise**, and only when the phone has a network connection. Your per-alert *check frequency* is a ceiling within that: setting an alert to "once a day" makes the task skip it most of the time.

### What this means in practice

- **Alerts are best-effort, not real-time.** The OS decides when the task actually runs; aggressive battery savers delay or kill it. If timing matters, whitelist the app under Android's battery settings.
- **No GPS is used.** Alerts work on the stations' stored coordinates, so an alert around your home keeps working while you are 500 km away.
- **Battery cost is negligible** — a few KB per wake, inside an OS-managed slot, Doze-respecting. Well under 0.5 % a day.
- **A side effect worth knowing:** the same background check writes a price record into your local history. A station under an alert therefore builds its 30-day history in hours instead of weeks, which is what makes the *best time to fill* banner appear quickly. See Price History.
- **If you switch notifications off at system level**, the in-app toggle cannot fire. Re-enable under Android Settings → Apps → Sparkilo → Notifications.

---

## Stats

The counters at the top of the alerts screen show how many rules are active and how often they have fired today and this week — a quick sanity check that the background task is really running. A row of zeros with several active alerts and a stale "last check" stamp is the classic symptom of a battery optimiser killing the task.

---

## Stopping alerts

Toggle an alert off to pause it without losing the rule, or swipe left to delete. Deleting the station from favourites does **not** delete its alerts.

---

**See also:** Price History & Predictions · Settings Reference → Prices & alerts
**Next:** EV Charging →

---

# Price History & Predictions

The app builds a **private, local** picture of how prices move around you, and turns it into one honest recommendation.

---

## What is recorded, and where

Every time a station's price passes through the app — a search, a favourites refresh, or a background alert check — the app writes a record **on your phone**: station, fuel, price, timestamp. Nothing is uploaded, and no one else's data is downloaded.

- **De-duplicated to one record per station per hour.** Searching the same station five times in ten minutes adds one entry.
- **Retained 30 days.** Older records are deleted automatically.
- **Enabled by** *Features & use mode → Prices & alerts → Price history*. Switch it off and no records are written at all.

*Settings → Prices & alerts. **Price history** is the prerequisite for the prediction below it — turn history off and the prediction has nothing to work with.*

---

## Viewing a station's history

Open a station's detail page and scroll to **Price history**:

- **Hourly chart** — the average price for each hour of the day over the last 30 days.
- **Day-of-week chart** — the average for each weekday.
- **Min / max / average / trend** summary.

The cheapest hour or day is highlighted green, the dearest red.

---

## "Best time to fill"

Once there is enough history the station grows a banner:

> 💡 **Prices typically drop Tuesday 18:00–20:00** — save ~3.2 c/L

### What it is — and is not

It is a **summary of what has already happened at this station in the last 30 days**, in *your* data. It is deliberately **not**:

- a forecast of tomorrow's price,
- aware of oil markets, tax changes or weather,
- built from other users' data.

That restraint is the point. A regional Monday-morning markup is a real, repeating, local pattern you can act on; a market prediction from a phone is not.

### The learning phase

The banner stays hidden until the app has at least **10 price records for that station in the last 30 days**. How long that takes depends entirely on how often the station's price passes through the app:

| Situation | Time to the banner |
|---|---|
| Station has a **price alert** on it | A few hours — the background check records every 30–60 min |
| Station is a **favourite** you open daily | About 10 days |
| Neither — you only search it occasionally | Weeks, possibly never |

**The practical trick:** put an alert on the station you actually use. The alert earns its keep twice — it pings you on a drop, and it fills the history that produces the recommendation.

### Why your favourite still has no banner

1. **Not enough records yet** (see above).
2. **The price barely moved.** If the 30-day spread is under 0.1 c/L there is nothing worth acting on, so nothing is shown.
3. **Only one fuel has samples.** The threshold is per fuel type, not per station.

---

## On-device price prediction

*Features & use mode → Prices & alerts → **Best time to fill up*** enables a small TensorFlow Lite model that runs **entirely on the device**. Its features and its predictions never leave the phone. It is what powers the *predictive* variant of the home-screen widget (**Settings → Units & display → Home-screen widget → Content variant**), which shows the best moment to fill rather than just the current price.

If you would rather have nothing inferred at all, switch it off: history and the pattern banner keep working without it.

---

## Community price reports

*Features & use mode → Prices & alerts → **Community price reports*** adds a flag action to the station detail so you can report a price the official source has wrong. Reports go to the shared TankSync database under your pseudonymous account and are visible to other signed-in users — so this is the one price feature that is **not** purely local. It requires TankSync and is off unless you turn it on.

---

## Exporting

**Settings → Privacy & data → Export or delete → Export my data → CSV** writes a CSV — its price-history table holds station, fuel, price, timestamp — to your public Downloads folder, ready for a spreadsheet.

---

**See also:** Favourites & Alerts · Finding Stations → Freshness
**Next:** Settings Reference →

---

# Fuel Log & Consumption

Layers 2 and 3 of the three savings layers: how much you burn, and what it truly cost. The ⛽ **Fuel** tab appears on the **Medium** and **Full** use modes.

---

## The Fuel tab at a glance

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

After a correction like the one above, expect trip estimates to drop noticeably on the next drive and then settle. See the full mechanism in How Sparkilo Works → How a litre becomes a number.

The card can also point at *what changed* — high-RPM share, harsh events per 100 km, cold starts, idle share, each versus the previous tank — with an explicit caveat that recordings are spontaneous and cover only part of the tank, so those hints are indicative.

---

## Consumption statistics

Tap the stats card, or **Fuel → Consumption stats**.

*Filter chips at the top scope everything below to one fuel — essential on a flex-fuel car, where a combined average is meaningless.*

The month-on-month table shows litres, spend, average price per litre, average consumption, cost per km and fill count, each with its delta. Red arrows are not judgements — a rise in *spend* after a rise in *price per litre* is the market, not your right foot. The number to watch for driving is **L/100 km**.

### Cost per kilometre by fuel

*The flex-fuel driver's actual question, answered: not which fuel is cheaper per litre, but which is cheaper per kilometre.*

Each fuel gets a row built from **closed tank windows only**: measured L/100 km, price actually paid per litre, cost per 100 km, total spent, distance measured, litres burned, CO₂ per 100 km, and how many full tanks are behind it. A row backed by a single tank is labelled **Provisional**.

*The verdict card states the winner, the gap per 1000 km, and — most usefully — the **break-even price**.*

The break-even line ("E5 becomes better than E85 below €0.75/L") is computed from **your own measured consumption of each fuel**, so it moves as your driving changes. That is a decision rule you can use at the pump; a generic ratio from the internet is not.

CO₂ figures are well-to-wheel estimates (EU JEC WTW v5) applied to your measured consumption — awareness, not audit-grade accounting. Blends are excluded from CO₂ because the emission factor depends on the mix, which the row does not record.

*The trend charts stack by fuel, so a switch shows up as one colour replacing another rather than as a mysterious jump.*

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

</details>

---

**See also:** Vehicles & OBD2 · Trips & Eco-Coaching
**Next:** Trips & Eco-Coaching →

---

# Tracking Fuel, Trips & Driving *(moved)*

This page has been split into three, so each topic has its own anchors for in-app help:

- **Vehicles & OBD2** — your car, tank capacity, flex-fuel, adapter pairing, baseline calibration, auto-record.
- **Fuel Log & Consumption** — fill-ups, tank level, the tank report, accuracy, cost per kilometre by fuel.
- **Trips & Eco-Coaching** — recording, the trip detail, driving score, the carbon dashboard.

Start with **How Sparkilo Works** if you want the concepts behind all three.

---

# Vehicles & OBD2

Everything the app knows about *your car*. This is the page that decides whether the consumption numbers on every other page are trustworthy.

---

## Why the app needs a vehicle at all

Without a vehicle, Sparkilo is a price finder. With one it can convert litres and kilometres into *your* cost per kilometre, estimate range, and — with an adapter — model instantaneous fuel flow.

*Settings → Vehicles & OBD2. Note the scope badge on the adapter tile: adapters are paired **per vehicle**, not per phone.*

*The green check marks the active vehicle — the one new fill-ups and trips are attributed to.*

---

## Identity and drivetrain

*Name it whatever you'll recognise. The VIN is optional.*

### The VIN, and what it buys you

Entering (or reading) the VIN lets the app look up engine displacement, cylinder count, power and fuel type, which are the inputs of the consumption model. **Read VIN from car** pulls it over OBD2 in a second.

Online VIN decoding is a **separate consent** — the app asks before sending anything, and offline partial decoding still works if you decline. A VIN is personal data; treat it like one.

### Drivetrain

**Combustion / Hybrid / Electric** changes which fields exist below it. Combustion asks for tank capacity, power and preferred fuel; electric asks for battery capacity and connectors.

---

## Tank capacity, power, and flex-fuel

*Tank capacity is the single most load-bearing number on this screen.*

### Why tank capacity matters so much

It is the denominator of the tank-level gauge and of the range estimate, and it bounds what the app considers a plausible fill. A wrong capacity produces a plausible-looking but wrong range for months. Take it from the handbook, not from memory — manufacturers often quote a usable capacity a couple of litres below the nominal one.

### "I can fill up with different fuels"

Turn this on for a flex-fuel car (E85/E10, or anything you genuinely alternate). Two things change:

- The fill-up form **asks which fuel you actually pumped** every time, instead of assuming the preferred one.
- The statistics screen gains the **cost per kilometre by fuel** comparison, which is the only honest way to compare a cheap-per-litre, thirsty fuel against an expensive, efficient one.

Leave it off if you always pump the same grade — it just adds a field.

---

## The OBD2 adapter

An OBD2 adapter is a small Bluetooth dongle in your car's diagnostic port (usually under the dashboard). **It is entirely optional.** Everything works on GPS alone; the adapter upgrades estimates to measurements.

### What it changes

| Without adapter | With adapter |
|---|---|
| Distance and time from GPS | Same, plus engine data |
| Consumption **modelled** from your calibration | Consumption **measured** (or modelled with a far better model) |
| Coaching from speed and acceleration | Coaching from RPM, throttle, load, gear |
| Accuracy ceiling: Medium | Accuracy ceiling: High (±3–7 %) |
| Manual trip start | Auto-record possible |

### What the app reads

Speed, RPM, engine load %, throttle position %, coolant and intake-air temperature, ignition timing advance, fuel level %, odometer (standard PID A6, falling back to PID 31 and manufacturer Mode 22), and instantaneous fuel flow — either directly from **PID 5E** where the car reports it, or derived from the mass-airflow sensor.

> **The important distinction:** if your car answers PID 5E, your consumption is *measured* and no calibration is applied to it. If it does not, the figure is *modelled* from airflow and engine parameters, and that model is what the pump-anchored gain corrects. The vehicle screen tells you which case you are in.

### Supported adapters

16 models are recognised by Bluetooth advertisement name, each with a compatibility tier:

- ✅ **Tested** — confirmed on real hardware by the maintainer.
- 👤 **User-verified** — at least one user reported it working.
- ⚠️ **Theoretical** — the profile and transport are right, but nobody has confirmed end-to-end yet.

| Adapter | Transport | Notes | Tier |
|---|---|---|---|
| vLinker FS | Classic BT | Dominant EU model; recommended | ✅ |
| vLinker BM-Android | Classic BT | Classic SPP sibling of BM+ | ✅ |
| SmartOBD (BLE) | BLE | Generic ELM327 v1.5 clone | 👤 |
| SmartOBD (Classic) | Classic BT | Same brand, Classic SPP | 👤 |
| vLinker FD / MC | BLE | Nordic UART FFF0 family | ⚠️ |
| OBDLink MX+ | BLE | Scantool premium | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | ELM327 v2.1 BLE clone | ⚠️ |
| vLinker BM+ | BLE | BLE-only sibling | ⚠️ |
| Konnwei KW902 | Classic BT | ELM327 v1.5 clone | ⚠️ |
| Vgate iCar Pro | BLE | BLE variant only | ⚠️ |
| Panlong WiFi | — | WiFi-only, listed so mis-pairings are labelled | ⚠️ |
| BAFX 34t5 | Classic BT | Legacy ELM327 v1.5 | ⚠️ |
| Generic ELM327 (BLE) | BLE | Catch-all for BLE FFF0 clones | ⚠️ |
| Generic ELM327 (Classic) | Classic BT | Catch-all for Classic SPP clones | ⚠️ |

Unlisted adapters fall through to the generic ELM327 profile and usually work. If yours does — or doesn't — [open an issue](https://github.com/fdittgen-png/tankstellen/issues) so the tier can be corrected.

### Pairing

1. Turn the ignition to **on** (engine running is fine, off is not).
2. Plug the adapter in; its LED should be solid.
3. Open the vehicle and tap the adapter section, or start a trip.
4. Grant **Bluetooth Scan** and **Bluetooth Connect** (Android 12+). On Android 11 and below the OS demands **Location** for Bluetooth scanning instead — an OS rule, not a tracking decision.
5. Wait roughly 8 seconds for the scan and tap your adapter. The app runs the ELM327 handshake and confirms.

Once paired, the adapter belongs to that vehicle. **Reset connection** re-runs the handshake without forgetting the device — the first thing to try after a mid-drive dropout. **Forget adapter** clears the pairing entirely.

---

## Baseline calibration — teaching the app your car

*210 of 270 samples collected. Two driving situations are still empty, and the app says so rather than pretending the profile is complete.*

Each OBD2 sample is filed into a driving situation: **idle, stop & go, urban, highway, decelerating, climbing / loaded, cold start, sustained load / towing, coasting**. The per-situation averages become the vehicle's baseline — the model that produces a plausible L/100 km when the adapter is absent or a PID stops answering.

*Situations with zero samples are the ones that will fall back to defaults. Two of them here — decelerating and towing.*

### Rule-based vs fuzzy

*Fuzzy is the default and the better choice for almost everyone.*

- **Rule-based** assigns each sample to exactly one situation. Predictable, but it flips between "urban" and "highway" from sample to sample when you cruise near the boundary — around 60 km/h, for example.
- **Fuzzy** spreads each sample across all situations by how well each one fits. Smoother precisely where rule-based is jumpy, at the cost of being harder to reason about sample by sample.

### The two reset buttons — and what they really do

- **Reset volumetric efficiency** discards the learned η_v and restores the 0.85 default. η_v is a parameter of the speed-density model that estimates airflow when there is no MAF reading. Reset it only after a mechanical change; a wrong-looking number is more likely a coverage problem than a bad η_v. Cars that report fuel rate directly (PID 5E) never use it at all.
- **Reset from vehicle database** re-pulls displacement, power and defaults from the built-in catalogue, discarding your manual overrides.
- **Reset driving-situation baseline** (in the baseline card) wipes every learned sample and drops you back to cold-start defaults until new trips refill the profile.

None of these touch the **pump gain**, which is learned from full-to-full fill-up windows and lives outside the OBD2 model — see How Sparkilo Works → How a litre becomes a number.

---

## Service reminders

At the bottom of the vehicle editor: presets for **oil change (15 000 km)**, **tyres (20 000 km)** and **inspection (30 000 km)**, plus custom reminders. They count against the odometer readings you enter with your fill-ups, so they only advance if you log the odometer — which is also what the calibration needs. One habit, two payoffs.

---

## Auto-record

With an adapter paired, recording can be fully hands-off:

- **Auto-pair** — the first manual pairing creates the adapter ↔ vehicle association.
- **Auto-connect** — when the OS sees the paired adapter advertising, the app reconnects in the background.
- **Auto-start** — once connected and moving above the start-speed threshold, the trip begins.
- **Auto-save** — the adapter loses power with the ignition, and after the configured delay the trip is finalised and saved.

Auto-record needs the **"Allow all the time"** location grant, because Android only lets a background service stream GPS with that permission. That grant is used by auto-record and nothing else; searching and map centring use the ordinary foreground grant.

> **Platform note.** Auto-record is verified on **Android**. On iOS the OS-level background wake needed for "connect when the adapter powers up" is not available yet ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); iOS users start trips manually.

Thresholds (start speed, save delay after disconnect) live in the vehicle editor, so a car you use for short hops can have a different trigger than a commuter.

---

<details>
<summary>Whole-screen reference — the vehicle editor, full page</summary>

</details>

---

**See also:** Trips & Eco-Coaching · Troubleshooting → OBD2
**Next:** Fuel Log & Consumption →

---

# Trips & Eco-Coaching

The 🛣️ **Trips** tab is an automatic logbook plus a driving coach. It appears on the **Full** use mode.

---

## The Trips tab

*Month-on-month totals, the latest tank report, then the trip list. The floating button starts a recording.*

The month comparison needs at least three trips per month before it will compare — with fewer, the average is noise rather than a trend.

*The map icon in the app bar draws every recorded trip on one map — a year of driving at a glance, and an easy way to spot the routes worth optimising.*

---

## Two ways to record

### With your phone alone

No hardware. The app logs the route, distance, duration and speed from GPS, and **models** consumption from your vehicle calibration and driving. Marked with a `~` and an explicit "GPS estimate" note wherever it appears.

Accuracy starts poor and improves: each closed fill-up window re-anchors the model to the pump, so after a handful of full tanks a GPS-only trip typically lands within a few percent. Until then it is labelled preliminary rather than dressed up.

### With an OBD2 adapter

Engine data instead of inference: real fuel flow (measured where the car reports PID 5E), RPM, load, throttle. No learning period for consumption, and the coaching gets access to signals GPS cannot see — gear, revs, engine load. Setup is in Vehicles & OBD2.

> **Recording never requires an adapter.** Turn off *Require OBD2 for trip recording* (Features & use mode → Consumption) to record GPS-only trips; the coaching is reduced, not absent.

---

## While you drive

### The live figure

The headline number is your average **over the last few seconds** — fuel burned ÷ distance covered, the same quantity a dashboard trip computer shows — labelled *"Last 5 s"*. At a standstill it switches to L/h, because L/100 km is undefined at zero speed.

Change the window under **Settings → Driving & consumption → Live consumption window** (3 / 5 / 10 / 30 s). A **longer window is steadier and easier to read while driving**; a shorter one reacts fast enough to teach you what your right foot costs. The unit follows **Units & display → Consumption unit** everywhere: banner, PiP tile, iOS Live Activity and the trip average.

### Landscape = the in-car view

Turn the phone sideways during a recording and the screen becomes a zero-touch, glanceable layout: on the left the big instant consumption figure with the coaching cue underneath (*lift off* / *anticipate* / *smooth accel* on GPS, *shift up* / *shift down* / *ease pedal* on OBD2) and a large speed read-out; on the right the closest-station radar card above a 2×2 grid of **Distance · Avg · Elapsed · Fuel used**.

Nothing scrolls and nothing is small. Prop the phone in a dash mount and never touch it.

### Picture-in-picture

Shrink the app into a floating tile and keep your navigation app on top. The tile is context-adaptive:

| Situation | Big number | Secondary |
|---|---|---|
| OBD2 connected | live L/100 km (L/h at idle) | distance · elapsed |
| GPS-only, moving | distance so far | elapsed |
| Warming up | elapsed time | — |

### The approach overlay

Come within the configured radius of a station and the tile flips to a large **fuel price** display for it — price for your fuel, brand, distance, readable at a glance.

Which station it locks onto is set in **Settings → Driving & consumption → Station approach overlay**: **nearest** (the first station whose radius you entered) or **cheapest in radius**. On leaving the radius the price layout lingers for a five-second grace period, so brushing past a forecourt doesn't make the tile flicker.

**Test it without driving:** Settings → Developer tools → **Test approach overlay** pushes a synthetic in-radius state for 30 seconds.

---

## Reading a trip

*The summary states its own provenance — vehicle, adapter, and a **GPS track** badge on the distance so you know where the kilometres came from.*

*The route is coloured by efficiency — green under 6 L/100 km, amber to 10, red above. Where the fuel went, geographically.*

That colouring is the single most actionable view in the app: it puts the expensive parts of your commute on a map. A red stretch that repeats every day is a junction, a hill or a habit worth changing.

*Three blocks: your own verdict, the fuel attribution, and how you actually used the engine.*

- **"How did this drive go?"** — *Smooth / Moderate / Aggressive*. Your answer is used to calibrate the driving-style thresholds against real drives, not to score you.
- **Where your fuel went** — litres attributed to hard acceleration versus normal driving. Small absolute numbers on a short trip; the ratio is the point.
- **Throttle position** and **engine speed** distributions — the percentage of the trip spent coasting, light, firm and full throttle, and in each RPM band. A high share above 3000 rpm on a commute means you are short-shifting late, which is expensive.

*Two diagnostics: how complete the GPS track is, and how well the adapter behaved.*

*Expanded, the OBD2 card explains itself in plain language.*

**Read this card before doubting a consumption figure.** It states how many samples carried engine data, the resulting **coverage percentage**, the adapter and negotiated protocol, the session duration, why the session ended (`userStopped`, a disconnect, a process death), and the decisive line: *"Consumption values come from the adapter, not GPS estimates."* If coverage is well under 100 %, the gaps were filled with GPS estimates and the trip average is a blend.

*Speed, fuel flow and RPM on a shared time axis — the three curves that explain any consumption number.*

*Engine load and throttle side by side show the difference between working the engine and merely revving it.*

*Altitude matters more than most drivers expect: a climb explains a consumption spike that would otherwise look like bad driving.*

The **share** and **delete** actions sit in the app bar. Sharing exports the trip (including a GPX track) so you can keep it outside the app.

---

## Driving score and coaching

With an adapter, each trip is scored out of 100 — a composite of idling, hard acceleration, hard braking, high-RPM time, full throttle, lugging, jerkiness, sustained high speed, aggressive pedal work and mixture richness. The breakdown names which behaviour cost the most, so the score is a diagnosis rather than a grade.

The **top wasteful behaviours** card turns that into sentences you can act on — and says *"No notable inefficiency — keep it up"* when there is nothing to fix, rather than inventing a complaint.

Coaching can also be delivered while driving:

- **Real-time eco coaching** — a light vibration plus an on-screen cue when you accelerate hard at cruising speed.
- **Spoken driving coaching** — the same advice read aloud, so your eyes stay on the road.
- **Glide-coach (beta)** — a subtle haptic when you should lift off ahead of a red light, using traffic-signal positions from OpenStreetMap. **Off by default: it is a distraction risk**, and it needs network access to fetch signal positions for your area.

*Settings → Driving & consumption. Achievements and scores can be hidden app-wide if gamification isn't for you.*

---

## The carbon dashboard

*Cost and CO₂ from the same measured litres, broken down two ways.*

- **By trip length** — short hops are usually the most expensive per kilometre, because a cold engine drinks. Seeing that quantified is what makes people combine errands.
- **By speed band** — how much fuel goes on crawling in town versus cruising.

It is built entirely from data on your phone, and switched on under Features & use mode → Consumption.

---

## Exports and diagnostics

- **Share** a single trip (summary + GPX).
- **Export driving-analysis trace** — the trip's GPS KPIs, score and lessons as JSON, with a free-text field for how the drive actually felt. Sharing it back helps calibrate the driving-style thresholds against real drives. Developer-mode feature.
- **Export my data → ZIP archive** under Privacy & data → Export or delete includes every trip and one GPX per trip.

---

<details>
<summary>Whole-screen reference — trip detail, full page</summary>

</details>

---

**See also:** Vehicles & OBD2 · Fuel Log & Consumption
**Next:** Price History & Predictions →

---

# Privacy, Data & Sync

Sparkilo's privacy claims are checkable, and this page is where you check them.

---

## Privacy by default

Concretely:

- **No Google Play Services. No Firebase. No Google Analytics. No advertising identifiers.**
- **No third-party tracking SDKs** — `pubspec.yaml` in the public source has zero analytics dependencies.
- **No account required.** The app is fully functional without one.
- **Local-first.** Everything lives on your phone unless you switch something on.
- **Consent before processing**, plus a plain-language explanation *before* each system permission prompt.
- **Open source, MIT.** The project's own tests fail if the privacy policy and the code drift apart.

### What actually leaves the phone

| Data | To whom | When | Avoidable? |
|---|---|---|---|
| Search coordinates or a region code | Your country's official price provider | Every live search | Search by postal code instead of GPS |
| Map viewport + IP | The developer's EU tile proxy, which fetches from OpenStreetMap | Map use | Turn the proxy off — OpenStreetMap then sees your IP directly |
| Your IP | logo.clearbit.com | Only if you enable internet brand logos | Leave it off (default) |
| Sanitised crash traces | Sentry | Only with *Error Reporting* on | Off by default |
| Your synced rows | Your chosen TankSync database | Only with TankSync on | Off by default |

**Your identity is never part of a price query**, and the developer runs no server that stores your searches.

---

## Who is the data controller

It depends entirely on how you use TankSync:

| Mode | Controller |
|---|---|
| **No TankSync** *(default)* | **Only you.** Nothing sits on any server the developer operates |
| **Your own Supabase project** | **You** — the developer never sees it |
| **A group's database** | **The group owner** who runs that project |
| **Sparkilo Community** | **The developer, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. is the processor; hosted in the EU (AWS eu-central-1, Frankfurt) |

The app states which case applies **before** you connect, and again as the *Sync mode* row of **Sync & account**.

---

## The Privacy & data screen

**Settings → Privacy & data** is the single entry point. It opens on a summary card followed by four topic tiles:

| Line or tile | What it tells you |
|---|---|
| *Your data stays on this device* / *Your data is also synced to TankSync* | Where your data physically lives right now |
| *Sync: off* / *Sync: on · anonymous account* / *Sync: on · email account* | Whether TankSync is connected, and with which kind of account |
| *… stored on this device* | The total storage the app currently uses |
| **Your choices** — *n of 5 enabled* | The five consents and the two network controls |
| **Data on this device** — *size · n categories* | Every category held locally, with size and count |
| **Sync & account** | TankSync status, account, database and the sync actions |
| **Export or delete** — *ZIP, JSON, CSV · error log (n)* | The exports, the error log and the danger zone |

The former *Privacy Dashboard* no longer exists: its counters, sync facts, exports and delete button now live under these four topics. Old links and home-screen widgets that pointed at the dashboard open **Privacy & data** instead.

---

## Your choices

*The two network-shaped controls, each stated as what it actually leaks. The five consents sit above them on the same card.*

Every row is a switch — *"You can change your privacy choices at any time."*

| Row | What it decides |
|---|---|
| **Location Access** | Find nearby fuel stations using your location. Off: search by postal code |
| **Error Reporting** | Send anonymous crash reports to improve the app. Off by default — nothing is ever uploaded without it |
| **Cloud Sync** | Sync favorites and alerts across devices — the consent behind TankSync |
| **VIN online decode** | Decode the VIN via NHTSA's free public service. Off: type the vehicle data yourself |
| **Sync trip recordings** | Back up OBD2 + GPS trips to TankSync. Greyed out until *Cloud Sync* is on |
| **Route map tiles through the Sparkilo proxy** | On: the map viewport and your IP address reach the developer's EU server, which fetches the tiles from OpenStreetMap. Off: tiles load from tile.openstreetmap.org directly, which then sees your IP instead |
| **Load brand logos from the internet** | Off by default: bundled placeholders are shown. On: logos are fetched from logo.clearbit.com, which sees your IP address |

The two network controls carry an info button (*Learn more*) with the full explanation. The footer records *Consent given on … · policy version …* — the audit trail the GDPR asks for — and links to the **Privacy policy** in your language. Withdrawing a consent stops that processing immediately; earlier processing remains lawful.

---

## Data on this device

*Storage, itemised: a bar by category, then one row per category with its size, its count and a dot in the bar's colour. Empty categories are greyed, not hidden.*

The rows under **Storage usage on this device**: **Favorites** · **Station ratings** · **Search profiles** · **Price Alerts** · **Price history stations** · **Ignored stations** · **Blocked users** · **Saved routes** · **Cache** · **Settings** (*API key, active profile*) · **Total**.

Everything sits in **encrypted Hive databases**; the key is in the Android Keystore / iOS Keychain.

| Box | Contents |
|---|---|
| `settings` | Configuration, country, language, units |
| `profiles` | Your search profiles |
| `favorites` | Saved stations with their full data |
| `cache` | Cached API responses and itineraries |
| `priceHistory` | The local 30-day price records |
| `price_snapshots` | Snapshots used offline and by the widget |
| `alerts` | Your alert rules |
| `service_reminders` | Service reminders |
| `obd2Baselines` | Per-vehicle consumption baselines |
| `obd2TripHistory` | Trips: route, speed, sensors |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Adapter capability caches |

API keys, the GitHub token and the TankSync session live in the hardware-backed vault, not in Hive.

### Cache details

*The **Cache details** tile expands to the lifetime of each cached class — searches 5 min, station details 15 min, price queries 5 min, favourites data 30 min, city lookups 30 min, postal-code geocoding 24 h — and the **Clear cache** button.*

The cache stores API responses for faster loading and offline access. Clearing it deletes cached results and prices only — profiles, favourites and settings are untouched; the next few searches are slower, nothing is lost. The button reads *Cache is empty* and is disabled when there is nothing to clear.

### Blocked users

**Blocked users** is the only tappable row: it opens the list of accounts you blocked, each with an **Unblock** button. Content shared by these users is hidden on this device; blocking is local — it does not report the account.

---

## Permissions

| Permission | Why | Refusable? |
|---|---|---|
| **Location** *(while in use)* | Nearby search, route start, trip recording | Yes — use a postal code |
| **Location** *("Allow all the time")* | **Only** OBD2 auto-record, so the route keeps recording with the screen off | Yes — start trips manually |
| **Bluetooth Scan + Connect** | Adapter pairing | Yes — OBD2 is optional |
| **Notifications** | Price alerts | Yes — alerts won't fire |
| **Camera** | On-device OCR of pump displays, receipts and QR codes | Yes — type manually |
| **Internet** | Price and map calls | Required |

On Android 11 and below the OS demands **Location** for any Bluetooth scan — that is a platform rule, not a tracking decision. Revoke any permission later in your device settings; the matching feature simply stops.

---

## Sync & account

*Reachable from the Privacy & data tile and directly from the Settings root. The screen also surfaces problems — here a self-hosted schema that is out of date and therefore silently failing to sync some tables.*

Opt-in. *Disabled* means nothing is stored on any server, anywhere. The overview card at the top states the facts:

| Row | Value |
|---|---|
| **Status** | *Connected* or *Disabled* |
| **Sync mode** | *Sparkilo Community — the developer's EU server* · *Shared group — a database you joined* · *Self-hosted — your own Supabase* |
| **Account** | *Anonymous account, tied to this device* or *Email account: …* |
| **User ID** | Your UUID, with a copy button — quote it in a support request |
| **Database host** | The host name of the database you sync to; the key is never shown |
| **Share learned vehicle profiles** | Upload per-vehicle consumption baselines so a second device can reuse them |

### Three deployment shapes

1. **Sparkilo Community** — the shared database the developer runs (Supabase, EU/Frankfurt). Your account is a random UUID; you may link an e-mail so you can reach it from another device. Community price reports and publicly shared ratings are readable by every signed-in user.
2. **Your own Supabase project** — the SQL schema and Edge Functions are in the repository. You are the controller and keep full ownership.
3. **A group's database** — connect to a project run by family or friends. That person is the controller.

### Setting it up

**Sync & account → Set up cloud sync.** For Community, scan the QR from the wiki or paste the URL and anon key; for your own or a group's project, paste the project URL and anon key. Both are stored in the hardware-backed vault, and plain-HTTP endpoints are refused outright.

> **Self-hosters:** after an app update the screen may warn that your **schema is outdated**. Re-run the setup SQL it offers — otherwise the newer tables fail to sync **silently**, which is far worse than a visible error.

### Actions once connected

- **Switch to email** — keep data, add sign-in from other devices; the UUID stays the same. **Switch to anonymous** does the reverse.
- **Consents** — a cross-link to *Your choices*: the Cloud Sync and trip-sync consents live there, not here.
- **View my data** — the *Data transparency* screen lists the rows the server holds for you; its **Forget all synced trips** button scrubs only the trip rows.
- **Link device** — bring a second phone onto the same account.
- **Delete synced data** — pick *Trips*, *Vehicles*, *Fill-ups* or *Everything* to remove from the sync database; local copies stay.
- **Share database** — a QR code so family or friends can join your own or a group's database (not offered on Community).
- **Disconnect** — stop syncing; local data is kept.
- **Delete account** — remove all server data permanently, then the account identity itself, including any linked e-mail. Offered for your own and group databases; on Community use *Delete synced data → Everything* or the danger zone described below.

### What syncs

Favourites · price alerts · ignored stations · ratings (with a per-rating privacy flag: local / private-synced / publicly shared) · itineraries · vehicles including VIN and adapter identifier · fill-ups and charging logs · consumption baselines · community and content reports you submit.

**Trips are separate.** Trip sync is opt-in *even after* Cloud Sync is on — the *Sync trip recordings* switch stays greyed until then. On the server, trip summaries stay until you delete them; the detailed GPS samples are pruned after 90 days.

Every table is protected by row-level security: an account can only read or delete its own rows. Shared ratings and community price reports are the only rows other signed-in users can see.

### Conflicts

**Local always wins.** Sync adds and updates but never silently deletes — only your explicit delete triggers a server delete, which then propagates to your other devices.

---

## Export or delete

One button, one format sheet, one red zone. **Export my data** opens *Choose a format*:

| Format | Hint in the sheet | What you get |
|---|---|---|
| **ZIP archive** | *Everything, attachments included — for a complete backup* | `sparkilo-my-data-<date>.zip`: one machine-readable JSON per category — favourites, alerts, profiles, routes, price history, vehicles, fill-ups, trips with GPS samples plus a GPX per trip, baselines, service reminders, charging logs, achievements and your consent record — plus every server table when TankSync is connected |
| **JSON** | *Machine-readable — for another app* | `tankstellen-data.json`: the on-device categories in one flat file, also copied to the clipboard |
| **CSV** | *Spreadsheet — one table per category* | `tankstellen-data.csv`: one `# table` block per category — favourites, alerts, price history and the rest — also copied to the clipboard |

All exports land in your **public Downloads** folder (*Saved to your Downloads folder*), so any file manager can pick them up.

**Error log** shows how many sanitised traces the app holds (*No entries* … *n entries*). **Save** writes them to Downloads for a bug report — no e-mails, coordinates, keys or tokens inside, and nothing is ever uploaded automatically; **Clear** empties the log.

**Danger zone** — *Permanently deletes everything the app stores on this device. With sync on, your data on the TankSync server is erased too.* **Delete all my data** asks for confirmation and lists what goes: favourites and station data, search profiles, price alerts, price history, cached data, your API key, all app settings. With TankSync connected it erases your server rows first; if a table could not be erased, the app **tells you which one** instead of claiming success. The app then returns to first-launch setup. Irreversible.

For a restorable snapshot rather than a data export, use **Settings → Backup & restore** — see Settings Reference.

---

## Your rights under the GDPR

Every right in Articles 15–22 has a button. No support request needed.

- **Access** — *Data on this device* lists every category on the device; *View my data* lists every row in your TankSync database.
- **Portability** — *Export my data* as a ZIP archive.
- **Rectification** — edit any entry in place; the change syncs if TankSync is on.
- **Erasure**
  - *Device:* **Export or delete → Delete all my data**.
  - *Server:* **Sync & account → Delete account** erases every row you own **in one transaction** — favourites, alerts, ignored stations, price and content reports, vehicles, fill-ups, itineraries, baselines, ratings, trips, trip shares given and received, sync settings, deletion records and your user row — then the account identity itself, including any linked e-mail. If a table could not be erased, the app **tells you which one** instead of claiming success.
  - *Individual items:* everything is individually deletable; **Delete synced data** removes trips, vehicles or fill-ups from the server, and **Forget all synced trips** scrubs only the trip rows.
- **Withdraw consent** — Privacy & data → Your choices; processing stops immediately.
- **Restriction / objection** — switch off TankSync, trip sync, the tile proxy or diagnostics; revoke permissions in your device settings.
- **Complain** — to a supervisory authority, in particular in your country of residence, workplace or of the alleged infringement. The developer would appreciate a chance to fix it first: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

If you can no longer open the app, request deletion by e-mail from the address linked to your account. **An anonymous account never linked to an e-mail cannot be identified by anyone — including the developer — without the device that created it.** That is the price of not asking you to register.

Full text: **[Privacy policy v3, 29 August 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**, available in all 23 app languages ([Deutsch](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/), [Français](https://fdittgen-png.github.io/tankstellen/privacy-policy/fr/), …). The app records which version you consented to and shows the policy again whenever it changes.

---

**See also:** Settings Reference · How Sparkilo Works → Where your data lives
**Next:** Troubleshooting & FAQ →

---

# Settings Reference

Every screen of the settings tree, and — more usefully — **what each switch costs you** in battery, data, accuracy or privacy.

---

## The shape of it

Settings is a **two-level tree**: a root of topic tiles, one screen per topic, and a keyword search across all of them.

*Type "radius", "OBD2" or "theme" into the search field and the matching tile surfaces — you never need to remember which topic owns a parameter.*

*Twelve topics in total. Reaching Settings: the gear icon in the top-right of the main screens.*

Three design rules make the tree predictable:

1. **One home per parameter.** Nothing appears in two places; cross-links point at the single owner.
2. **Scope labels.** A tile marked *this profile*, *all profiles* or *this vehicle* tells you how far a change reaches before you make it.
3. **Honest empty states.** A section whose feature is off says so and links to the switch, instead of hiding.

---

## Profiles & region

*Country, language, fuel, search radius, route planning · scope: this profile*

*The preferred fuel is derived from the default vehicle. To choose a fuel directly, remove the vehicle from the profile.*

| Setting | Impact |
|---|---|
| **Profile name** | Cosmetic, but it is what the profile chip shows |
| **Preferred fuel** | The headline price on every card; the default for alerts; what route search optimises |
| **Default radius** | Larger = more results and slower searches |

*Route planning defaults. **Candidates per sampling point** trades thoroughness for speed on long corridors.*

*Three separate things worth knowing.*

- **Avoid motorways** changes the computed route itself, so motorway service stations stop being candidates at all — usually a saving, since motorway fuel is the dearest on any corridor.
- **Station notes** — *Local* (this device only), *Private* (synced to your own account) or *Shared* (visible to other users). This is a privacy choice, not a storage one.
- **Start screen** — what the app opens on: Nearby, Nearest station, Favourites or Map.

*The approach overlay's radius and its **nearest vs cheapest-in-radius** rule live in the profile, so a commuting profile and a holiday profile can behave differently.*

*Country decides the data provider. Changing it clears cached station data.*

*A **home postal code** gives you area searches with no GPS involved at all — the cleanest way to use the app if you never want to share your location.*

---

## Vehicles & OBD2

*Your cars, tank size, adapter pairing · scope: this vehicle*

*Adapters are paired per vehicle, so the adapter tile sends you into a vehicle rather than opening a global pairing screen.*

Full treatment — VIN, tank capacity, flex-fuel, calibration modes, baseline, auto-record thresholds, service reminders — is in Vehicles & OBD2.

---

## Driving & consumption

*Coaching, rewards, the radar, troubleshooting · scope: mixed*

*The top two entries are the ones you will actually tune.*

| Setting | Impact |
|---|---|
| **Live consumption window** (3/5/10/30 s) | Longer is steadier and easier to read while driving; shorter reacts fast enough to teach you what the pedal costs |
| **Station approach overlay** | Radius, price mode, query floor and screen pinning for the active profile |
| **Real-time eco coaching** | Light haptic + on-screen cue on hard acceleration at cruising speed |
| **Spoken driving coaching** | The same advice read aloud — eyes stay on the road |
| **Glide-coach beta** | Haptic before a red light using OpenStreetMap signal positions. **Off by default — distraction risk**, and it needs network access |

*Rewards and troubleshooting.*

- **Loyalty cards** — per-litre discounts applied inside price comparisons, so a nominally dearer station can correctly rank cheaper for you.
- **Show achievements and scores** — off hides every badge, score and trophy app-wide. Nothing stops being measured; it stops being displayed.
- **OBD2 debug logging** — records every session (connection, handshake, data loss, reconnects) into an exportable XML log. **Off by default**: it writes continuously and is only worth enabling while chasing an adapter problem.

---

## Prices & alerts

*Alerts, voice announcements, history, community reports*

*The greyed voice-announcements block is an honest empty state: it names both switches you need and where they live.*

| Setting | Impact |
|---|---|
| **Price alerts** | Opens the alert list; the feature itself is a switch under Features & use mode |
| **Price history** | Local 30-day recording. Off = no charts, no "best time to fill" |
| **TFLite price prediction** | On-device model; features and predictions never leave the phone |
| **Community price reports** | Requires TankSync; your reports are visible to other signed-in users |
| **Scan payment QR** | Adds the QR reader to station details |

---

## Units & display

*Theme, distance unit, consumption unit, home-screen widget · scope: mixed*

*The **consumption unit** propagates everywhere at once — live banner, PiP tile, trip averages, statistics, widget.*

- **Distance unit** defaults to the active profile's country (km or miles).
- **Consumption unit**: *Automatic* (mpg in the UK and US, L/100 km elsewhere), or an explicit L/100 km, km/L or mpg.

*Widget choices are stamped **this profile** and apply to every installed widget showing that profile, from the next refresh.*

**Content variant** — *current price only*, or *predictive: best time to fill up* (which needs the TFLite prediction feature).

---

## Features & use mode

*Presets and every individual switch*

*Picking a preset **overwrites** every individual switch. If you have a hand-tuned mix, stay on Custom.*

Dependencies are enforced, not hidden: a switch whose prerequisite is off stays disabled and says which prerequisite to enable.

*Search & map — including whether fuel stations and charging points appear at all.*

*Prices & alerts. Price history is the parent of the prediction beneath it.*

*The radar, its voice announcements, and the master **Spoken feedback** switch — with it off, the app never opens a speech engine at all.*

*The **Off / Fuel / Fuel + Trips** selector is the compact form of the whole consumption stack.*

| Switch | Impact |
|---|---|
| **Consumption analytics** | The analysis tab over fill-ups and trips |
| **Gamification** | Driving scores and earned badges |
| **Haptic eco-coach** | Real-time vibration feedback while driving |
| **Glide-coach** | Eco advice from OpenStreetMap traffic signals — needs network |
| **GPS trip path** | Stores the route points of every trip. Off = smaller database, no route maps |
| **Auto-record** | Starts a trip when the paired adapter connects to a moving vehicle |

*Two switches here change data quality rather than the UI.*

- **Experimental OEM PIDs** — reads the exact tank level in litres via manufacturer-specific PIDs on compatible adapters. Better tank data where it works; harmless where it doesn't.
- **Require OBD2 for trip recording** — when **off**, trips record on GPS alone. Coaching is reduced (no instantaneous L/100 km, fewer engine signals) but nothing is blocked.
- **Baseline sync** — uploads per-vehicle consumption baselines so a second device can reuse them. Requires TankSync.

*Entry & scanning. Recognition is on-device; these switches only decide whether the shortcuts exist.*

*Developer & experimental — safe to leave off unless you are reporting bugs.*

---

## Data sources & location

*API keys, GPS, automatic profile switching*

*A red cross on the fuel-price key is the usual reason a German search comes back empty.*

| Setting | Impact |
|---|---|
| **Fuel prices (Tankerkoenig)** | Required for Germany only. Free, per-user, stored in the hardware-backed vault |
| **EV charging (OpenChargeMap)** | Optional — replaces the shared built-in key with your own quota |
| **Automatic update** | Refreshes the GPS fix before each search. Off = faster searches, possibly from a stale position |
| **Automatic profile switching** | Switches profile when you cross a border, so the right provider and fuel are used automatically |

---

## Sync & account

*This screen also surfaces problems — here, a self-hosted TankSync schema that is out of date and therefore silently failing to sync some tables.*

Covered in full in Privacy, Profiles & Sync → TankSync. The essentials:

- **Sparkilo Community / your own database / a group's database** — three deployment shapes with three different data controllers.
- **Anonymous → e-mail** — *Switch to e-mail* keeps your existing data and account and adds a way to sign in from another device. An anonymous account exists only on the device that created it.
- **Schema outdated** — self-hosters must re-run the setup SQL after an app update, or newer tables fail to sync silently.

---

## Privacy & data

*Two network-shaped privacy choices, each stated as what it actually leaks.*

- **Map tiles through the Sparkilo proxy** — *on*: the developer's EU server sees your map viewport and IP and fetches the tiles for you. *Off*: tiles come straight from tile.openstreetmap.org, which then sees your IP instead. Neither option is "no network"; pick who you would rather be seen by. The F-Droid build never uses the proxy.
- **Load brand logos from the internet** — *off* by default; generic bundled logos are used. On, logos come from logo.clearbit.com, which sees your IP.

*Storage, itemised. Cache is almost always the biggest slice and is the only one that is safe to drop.*

*Cache management, with the lifetime of each cached class stated: searches 5 min, station details 15 min, price queries 5 min, favourites data 30 min, city lookups 30 min, postal-code geocoding 24 h.*

*Clearing the cache deletes cached results and prices only — profiles, favourites and settings are untouched. The next few searches are slower; nothing is lost.*

---

## Backup & restore

*A complete ZIP of vehicles, fill-ups, trips and charging logs.*

**Export backup** writes the ZIP to your Downloads folder. **Restore backup** offers *merge* or *replace* — merge keeps what is on the device and adds what is missing; replace wipes first. Use this before a phone change or a factory reset. TankSync is not a backup: it mirrors selected categories, not everything.

---

## Advanced & developer

*The GitHub token is optional — without it, failed-scan feedback is shared manually instead of filing an issue automatically.*

The **Developer tools** entry appears only when developer mode is on (Features & use mode → Developer & experimental).

*The error log is the useful part for ordinary users: **Save error log** writes sanitised traces to Downloads to attach to a bug report.*

*The startup trace is a waterfall of initialisation phases — how a slow launch gets diagnosed instead of guessed at.*

***Test approach overlay** pushes a synthetic in-radius state for 30 s so you can verify the picture-in-picture price layout without driving anywhere.*

---

## About

***Version and build number** — quote both in any bug report, and check them first when a fix "didn't work" (a store rollout may simply not have reached you yet).*

*The app is free, open source and ad-free. Attribution for the price data and the map data is at the bottom, as the licences require.*

---

**See also:** How Sparkilo Works · Privacy, Profiles & Sync
**Next:** Privacy, Profiles & Sync →

---

# Troubleshooting & FAQ

Ordered roughly by how often each one actually happens.

---

## Before anything else: check your version

*Settings → About. Quote **both** the version and the build number in any report.*

A large share of "it's still broken" reports are a store rollout that has not reached the device yet. If the build number is older than the release that contains the fix, there is nothing to debug.

---

## "No prices found"

1. **Check the country in your profile.** A German profile calls the German API; in France it will find nothing. Settings → Profiles & region → Region.
2. **Germany: is the API key set?** Settings → Data sources & location — a red cross on *Fuel prices (Tankerkoenig)* is the answer.
3. **Are you offline?** Live prices need a network call. Cached prices are still shown, flagged stale.
4. **Provider outage.** National open-data services do go down. Retry in a few minutes.
5. **Stale cache.** Pull to refresh, or tap the refresh icon.

---

## Germany: "API key missing" or "Invalid API key"

- Get a free key at [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); it is a UUID.
- Paste it into **Settings → Data sources & location → Fuel prices (Tankerkoenig)**.
- Still failing? The key may be rate-limited. Keys are per user — never publish or share one.

---

## I can't find the search button

There is exactly one: the raised green button in the middle of the bottom bar. From any tab it opens the criteria sheet; inside the sheet, a second tap runs the search. If it looks greyed out you are in **route mode without a destination**.

---

## Location is "unknown" or GPS never fixes

- System location must be on, with **While in use** granted to the app.
- GPS does not fix indoors. Step outside, or set a **home postal code** in your profile and search by area instead.
- "Coarse location only" — enable precise location in the system permission screen.

---

## Routing is slow or fails

- OSRM is a free public service and is sometimes slow.
- A multi-country corridor **streams partial results**; the banner names the providers still answering, and you can tap a result before the rest arrive.
- Retry — the polyline is cached, so the second attempt is usually instant.

---

## OBD2 adapter won't connect

**Nothing found during the scan**

- Ignition must be **on** (accessory or run). Engine running is fine; ignition off is not.
- The adapter LED should be on and steady. Blinking or dark → re-seat it.
- Phone Bluetooth on.
- Android 12+: grant **Bluetooth Scan** and **Bluetooth Connect**.
- Android 11 and below: the OS requires **Location** to enumerate Bluetooth devices. That is a platform rule, not tracking.

**Found, but the connection fails**

- *"Unresponsive"* — cheap clone. Wait 30 s and retry; briefly starting the engine often helps.
- *"Protocol init failed"* — counterfeit ELM327 chip. Try another model; vLinker FS is the reliable cheap option.
- *"Permission denied"* — re-grant in system settings; some Android builds forget Bluetooth permissions after a reboot.

**Connects, then drops mid-drive**

Use **Reset connection** in the vehicle's adapter card — it re-runs the handshake without forgetting the pairing. If it keeps happening, turn on **Settings → Driving & consumption → OBD2 debug logging**, drive once, then export the XML log and attach it to an issue. Turn the logging back off afterwards.

**The odometer reads 0 or is wrong**

Your car may not expose PID A6. The app retries with PID 31 and manufacturer Mode 22. Some pre-2008 European cars expose no odometer at all over OBD2 — type it with each fill-up instead.

---

## Auto-record didn't fire

It needs all of:

1. An adapter **paired to a vehicle**.
2. **Auto-record** on for that vehicle.
3. The **"Allow all the time"** location grant.
4. Bluetooth on, and the app not being killed by a battery optimiser.

Also check the **start-speed threshold** in the vehicle editor — a short crawl out of a car park may never reach it.

> **iOS:** the background wake needed for "connect when the adapter powers up" is not available yet ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). Start trips manually on iOS.

---

## My consumption figure looks wrong

Work through it in this order:

1. **Open the trip and read the OBD2 communication health card.** If coverage is well under 100 %, the gaps were filled with GPS estimates and the trip average is a blend, not a measurement.
2. **Check the tank report on the Trips tab.** If it says the estimates run *n* % over or under pump truth, the app already knows and has just corrected itself — expect the next trips to move.
3. **Check the tank capacity** on the vehicle. A wrong capacity produces plausible-but-wrong range for months.
4. **Check your odometer entries.** Consumption is litres ÷ kilometres, and the kilometres are entirely your typing.
5. **Check whether you ticked "Full tank".** Only full-to-full windows can calibrate anything.
6. **Check the accuracy badge** on the Fuel tab. *Low* means nothing has anchored the model yet — the figure is a model output, and it says so.

Background: How Sparkilo Works → How a litre becomes a number.

---

## "We found a gap of X litres"

You pumped more than your recorded trips account for. Answer the two questions in the reconciliation flow: a missing or mistyped fill-up gets a **correction entry**, an unrecorded drive gets a **virtual trip**. Both are editable afterwards. Leaving it unresolved biases the calibration, so it is worth two taps. See Fuel Log & Consumption.

---

## The picture-in-picture tile doesn't show a price

The approach overlay only fires while a **trip is recording** *and* you are inside the approach radius. To verify the layout without driving: **Settings → Developer tools → Test approach overlay** pushes a synthetic in-radius state for 30 seconds.

---

## Price-alert notifications don't arrive

- System notifications allowed for the app?
- Battery saver: Android's aggressive modes kill background work. Set the app to **not restricted**.
- The phone may have been offline at the scheduled slot; the check runs at the next network window.
- The price may simply not have crossed the threshold.
- The **Last check** stamp at the bottom of the alerts screen tells you whether the task is running at all. Old stamp + zero hits = the OS is killing it.

---

## The home-screen widget is stale

- Android limits widget refreshes to roughly once every 30 minutes; that is a system policy.
- Tap the **refresh icon on the widget itself** — it re-pulls prices without opening the app.
- Widget appearance and content variant are per profile, under **Settings → Units & display**.

---

## The map shows grey or blank tiles

- Usually a weak connection; swipe to refresh.
- If it persists, the tile servers may be rate-limiting — try again in a few minutes.
- Try toggling **Settings → Privacy & data → Map tiles through the Sparkilo proxy**; the two paths fail independently.

---

## Scanning a pump or receipt reads nothing

- The **F-Droid** build has no scanning at all — on-device text recognition ships only in the Play / App Store builds. Type the fill-up by hand there.
- Glare on a pump display is the most common cause. Shade it, get square to the display, fill the frame with the digits.
- If it reads the labels but not the numbers, use **Report scan error** so the crop can be used to improve the recogniser.

---

## The app takes a long time to start

Turn on **Startup initialization trace** (Features & use mode → Developer & experimental), restart, then open **Developer tools**. The waterfall names the slow phase; export it and attach it to an issue.

*Each bar is one initialisation phase with its duration — a slow launch stops being a guess.*

---

## The app crashes on launch

- Clear the cache from your device's app settings.
- If it persists, file an issue with the Android version, phone model, the app version **and build number** from Settings → About, and the saved error log (the app offers to save it on the next launch; the file lands in Downloads).

---

## How do I back up my data?

**Settings → Backup & restore → Export backup** writes a ZIP to Downloads; restore offers merge or replace. For a machine-readable data export instead, use **Privacy & data → Export or delete → Export my data → ZIP archive**.

TankSync is **not** a backup — it mirrors selected categories, and trips only if you also enabled trip sync.

---

## How do I delete everything?

- **Device:** Privacy & data → Export or delete → **Delete all my data**. Irreversible.
- **Server (TankSync):** delete the server side **first** — Sync & account → Data transparency → **Delete account** removes every row you own in one transaction and names any table it could not erase.

Details: Privacy, Data & Sync → Your rights.

---

## Can I use the app offline?

Partly. Favourites show their last-known prices, recently viewed map tiles are cached, and fill-ups and trips are entirely local. Discovering new stations needs a network call.

---

## Where did the Fuel or Trips tab go?

They belong to the **Medium** and **Full** use modes. If one vanished, a preset or an individual switch turned it off: Settings → Features & use mode → Consumption.

---

## More help

- **Bugs:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — use the Bug Report template and attach the saved error log.
- **Ideas:** the Feature Request template, or [Discussions](https://github.com/fdittgen-png/tankstellen/discussions) first.
- **Privacy questions:** the [privacy policy](https://fdittgen-png.github.io/tankstellen/privacy-policy/), or fdittgen@gmail.com.

---

**Back to:** User Guide home
