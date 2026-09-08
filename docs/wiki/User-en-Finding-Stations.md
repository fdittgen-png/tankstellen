# Finding Stations

Layer 1 of the [three savings layers](User-en-How-It-Works#the-three-savings-layers): pay less per litre.

---

## One button, one mental model

The bottom bar has one search trigger — the raised green button in the middle notch. It is context-aware rather than modal:

- **From any tab** → opens the criteria sheet.
- **From the results or the map** → re-opens the criteria sheet with what you last used.
- **Inside the sheet** → runs the search.

The button label changes to say what it will do, and in route mode it stays disabled until there is a destination to route to. There are deliberately no separate "search nearby" and "search along route" buttons.

---

## Setting the criteria

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Criteria sheet: nearby vs route, address, fuel chips, radius slider, open-now, amenities, brands">

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

### How it actually works

A nearby search sends **your coordinates (or a region code) and a radius** to your country's official price provider — never your identity. Countries that publish a daily bulk file (Spain, Italy) are filtered on the device instead, so those searches need no per-search network call at all once the file is cached.

---

## Reading a result card

<img src="guide/search-results.jpg" width="340" alt="Result list with price, trend arrow, freshness, amenities, distance and favourite star">

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

Freshness is a property of the **country's provider**, not of the app. A Spanish price that is 14 hours old is not a bug: that country publishes once a day. See [How Sparkilo Works → One data source per country](User-en-How-It-Works#one-data-source-per-country).

### Swipe actions

- **Swipe right** — open in your navigation app (Google Maps, Waze, OsmAnd, Organic Maps).
- **Swipe left** — hide the station from every future result. Un-hide from **Privacy & data → Data on this device → Ignored stations**.

---

## Station detail

<img src="guide/station-detail-1.jpg" width="340" alt="Station detail: per-fuel price table, add fill-up, opening hours, region">

*Tap a card. The brand header falls back through brand → name → street, so an Intermarché with an empty brand field still reads "Intermarché".*

The top block is the **full price table** — every grade the provider reports for this station, with `--` where it reports none. That is the fastest way to see whether the cheap E85 station also has a competitive diesel.

**Add fill-up** right there pre-fills the station, the fuel and the price into the fill-up form — the single biggest time-saver in the app if you log your fills.

<img src="guide/station-detail-2.jpg" width="340" alt="Station detail continued: zone, amenities, payment methods, your rating, price history">

*Below the fold: services, accepted payment methods, your own private star rating, and the 30-day local price history.*

The app-bar actions are, left to right: **set a price alert**, **scan a payment QR code**, **report a wrong price to the community**, and **favourite**.

---

## The map

<img src="guide/map-view.jpg" width="340" alt="Map with price-coloured pins, radius circle and cheap-to-expensive legend">

*Colour is relative to what is on screen: green is the cheapest visible, red the dearest. The footer states the station count, the radius and the age of the data.*

- **Cluster markers** collapse pins as you zoom out; tap to zoom in.
- **Long-press** anywhere to drop a marker and search from that point.
- The **EV toggle** (top right) flips the map to charging points — see [EV Charging](User-en-EV-Charging).
- **Share** sends the current view to someone else.

Tiles come from OpenStreetMap. By default they are fetched through the developer's EU proxy so that OpenStreetMap never sees your IP; you can switch the proxy off in Settings → Privacy & data and go direct instead. The F-Droid build never uses the proxy.

---

## The Fuel Station Radar

A one-tap live scan around your current position, designed for use **while driving**.

<img src="screenshots/radar-start.png" width="340" alt="The Start fuel station radar pill on the results screen">

*After any nearby search, a floating pill appears bottom-right. One tap starts the radar.*

### How it actually works

The radar refreshes your GPS fix, fetches station **locations** across a wide 60 km corridor and merges a direct in-radius fetch, so it can never show less than a normal search. Forecourts don't move, so those locations are cached for up to an hour and reused between taps; only the **price** of a station you are actually approaching is fetched just in time. That is what keeps a continuously running radar cheap in both data and battery.

<img src="screenshots/radar-active.png" width="340" alt="Radar running: live price pins and a distance-sorted list with proximity bars">

*Running: results sorted by distance, each with a proximity bar that fills as you close in.*

### While a trip is recording

The radar pins a **Closest station** card to the top of the recording screen — name, price for your fuel, distance, and a bar that fills to 100 % on arrival. Swipe left/right to page through the ranked candidates. Cross inside the configured approach radius and the picture-in-picture tile flips to a large price display; see [Trips & Eco-Coaching → Approach overlay](User-en-Trips-And-Coaching#the-approach-overlay).

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

<img src="guide/full/station-detail.jpg" width="420" alt="Full station detail screen stitched from two captures">

</details>

---

**See also:** [Route Planning](User-en-Route-Planning) · [Favourites & Alerts](User-en-Favorites-And-Alerts) · [Price History](User-en-Price-History-And-Predictions)
**Next:** [Route Planning →](User-en-Route-Planning)
