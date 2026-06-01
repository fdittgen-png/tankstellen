<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Phone screenshots

Eight JPGs (1080x2316 portrait) live in this directory. Fastlane Supply
uploads them in numerical order. The same curated set is mirrored across
every locale (the UI is localised at runtime) and into
`docs/play-store/metadata/android/<locale>/images/phoneScreenshots/`.

| File | Scene |
|------|------|
| `01_search_results.jpg` | Unified nearby search results with price |
| `02_map_price_pins.jpg` | Map with cheap→expensive price pins / route |
| `03_route_best_stops.jpg` | Route-corridor best stops with Cheapest badge |
| `04_favorites.jpg` | Favourites — fuel multi-price rows + EV chargers |
| `05_price_alerts.jpg` | Per-station + radius price alerts |
| `06_consumption_stats.jpg` | Consumption tracker (L/100km, cost/km, history) |
| `07_trip_detail_gps.jpg` | Trip detail with GPS route coloured by efficiency |
| `08_privacy_dashboard.jpg` | Privacy Dashboard (see / export / delete-all) |

**Caveat:** these captures carry the device status bar with a stray
"YouTube" / "Line 1" media notification. They are usable for an interim
listing, but clean recaptures or device-framed mockups are recommended
before the final store upload. Replace each file one-for-one; the
filenames are the stable contract.

See `docs/guides/PLAY-STORE-LISTING-REFRESH.md` for the full production
plan.
