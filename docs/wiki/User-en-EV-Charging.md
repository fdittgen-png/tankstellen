# EV Charging

Sparkilo is not only for combustion cars. Charging points come from [OpenChargeMap](https://openchargemap.org), the largest open community registry of chargers worldwide.

---

## Turning it on

Two independent switches, both in **Settings → Features & use mode → Search & map**:

- **EV charging** — the feature itself (search, detail pages, favourites).
- **Show charging stations** — whether chargers appear in results and on the map.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Search & map feature switches including EV charging and show charging stations">

*You can show fuel stations, charging points, or both. An EV-only driver typically turns **Show fuel stations** off.*

Then create an EV vehicle under **Settings → Vehicles & OBD2 → My vehicles → Add**, choosing **Electric** as the drivetrain. An EV vehicle carries battery capacity (kWh), maximum AC and DC charging power (kW) and its supported connectors (Type 2, CCS, CHAdeMO, Tesla, Schuko, Type 1, 3-pin). Searches then filter down to chargers your car can actually use.

---

## How the data works

<img src="guide/data-sources-location.jpg" width="340" alt="EV charging API key slot showing the app's default shared key">

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

<img src="screenshots/map-ev-charging.png" width="340" alt="Map in EV mode with connector filter chips">

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

**See also:** [Finding Stations](User-en-Finding-Stations) · [Fuel Log & Consumption](User-en-Fuel-And-Consumption)
**Next:** [Vehicles & OBD2 →](User-en-Vehicles-And-OBD2)
