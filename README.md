<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

﻿<p align="center">
  <img src="assets/icon.png" alt="Sparkilo app icon" width="160" height="160" />
</p>

# Sparkilo

<sub>The repository, bundle id (`de.tankstellen.fuelprices`), and internal package name remain `tankstellen` — that's the project's technical identity. **Sparkilo** is the public-facing brand on the App Store, Play Store, and the app's home-screen tile.</sub>

> **The cost of driving, attacked from three sides.**
>
> A car loses you money in three places: at the pump, on the road, and in everything you forgot to track. Sparkilo tackles all three — pay less per litre, burn fewer of them per kilometre, and see exactly where the money actually went.

[![CI](https://github.com/fdittgen-png/tankstellen/actions/workflows/ci.yml/badge.svg)](https://github.com/fdittgen-png/tankstellen/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-blue.svg)](https://flutter.dev)

<p>
  <a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
    <img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="64"/>
  </a>
  &nbsp;
  <a href="https://apps.apple.com/app/id6766543414">
    <img alt="Download on the App Store" src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="64"/>
  </a>
</p>

<sub>iPhone listing currently in <strong>TestFlight beta</strong> — the App Store page will populate once Apple's first-build review clears.</sub>

**A free, open-source companion app for cutting the running cost of your car.** 13 countries, 23 languages, privacy-first, no ads, no tracking.

Sparkilo aggregates real-time fuel prices from official government APIs, plugs into your car's OBD-II port to see how it actually drives, and keeps a tidy log of every fill-up and trip so the savings stop being theoretical.

## The objective: a cheaper kilometre

Every feature ladders up to one goal — **reduce what your car costs you, per kilometre driven** — through three layers, in priority order:

### 1. Buy fuel for less money

Live cross-country price comparison, route-aware "cheapest stop" planning, drop alerts, and 30-day price history with "best time to fill" guidance. Cheap fuel is the easiest win — and the one drivers leave on the table the most.

### 2. Burn less of it per kilometre

Plug in any ELM327-compatible OBD-II adapter and the app starts coaching: live haptic eco-feedback, hard-acceleration and idling insights, a per-trip driving score, and a throttle/RPM histogram showing where your engine actually lives. Behaviour change is harder than picking a station, but it pays out on every drive instead of every fill-up.

### 3. See what you're really spending

A fill-up log (manual, receipt-OCR, or OBD-II auto-record on disconnect), per-trip cost detail, fuel-cost projections, a CO₂ dashboard, and a maintenance-suggestion engine that watches consumption drift over time. You can't reduce what you don't measure — and most drivers measure nothing.

Features that don't serve at least one of those three layers don't belong.

## Features

### Layer 1 — buying cheaper

- **Real-time prices** from each country's official government data source — no scraping
- **13 countries** — Germany, France, Austria, Spain, Italy, Denmark, Portugal, Luxembourg, Slovenia, UK, Argentina, Australia, Mexico
- **23 languages** — from Bulgarian to Swedish
- **Route-aware search** — uniform / cheapest / balanced strategies, "best stops" along a planned trip
- **Cross-border suggestions** — when the next country over is meaningfully cheaper, the app says so
- **Price alerts** — threshold-based notifications, evaluated by a background job
- **Price history & predictions** — 30-day charts plus "best time to fill" guidance (a day-of-week + price-threshold heuristic) from your local history
- **Brand filter** — Total / Esso / Shell / Aral, country-aware brand registry
- **Favorites** — quick access with swipe-to-navigate / swipe-to-remove
- **Home-screen widget** — current prices and a "predictive" variant without opening the app
- **EV charging** — OpenChargeMap integration with connector type, max power, and pricing

### Layer 2 — burning less

- **OBD2 optional, not required** — Medium-profile users record trajets with GPS alone (no adapter); Full-profile users get the full OBD2 telemetry pipeline. Both paths produce real L/100 km figures via a per-vehicle calibration matrix that refines after every fill-up.
- **GPS-only trajet recorder** — speed-band integration, accel/brake event counting, altitude grade tracking. The matrix maps the resulting feature set to an estimated L/100 km that converges toward your real-world fuel burn after 3–8 fill-ups.
- **OBD2 trajet recorder** — any ELM327-compatible adapter (BLE classic + dual-mode, see the adapter registry); fuel rate, RPM, throttle %, engine load (when supported), GPS path. Speed-density fallback for cars without PID 5E.
- **Always-both recording** — OBD2 and GPS run in parallel during every recording. Mid-trip adapter dropouts are tolerated; the trip classifies as `gpsOnly` / `gpsPlusObd2` / `hybrid` at trip end based on coverage ratio.
- **Auto-record** — pair adapter to vehicle, auto-connect on Bluetooth, auto-start on movement, auto-save on disconnect (Android-verified; iOS background-wake pending #1542).
- **Live coaching** — OBD2 trajets get shift-up / shift-down / ease-pedal tiles. GPS-only trajets get lift-off-coast / anticipate-brake / smooth-accel tiles, derived from a rolling 5-second GPS sample window.
- **Trip detail view** — per-trip charts (speed, fuel rate, RPM, engine load when present) plus GPS route map with consumption-band colour coding and a shareable GPX export.
- **Driving insights** — hard-accel waste, idling fuel, cold-start surcharge, low-gear coaching.
- **Driving score** — composite 0-100 score per trip with breakdown chips, opt-in.
- **Throttle / RPM histogram** — see the engine zone you actually drive in (OBD2 only).
- **Visual eco-coach** — live haptic + on-screen feedback when behaviour costs fuel.
- **Driving mode** — full-screen, in-car friendly map with large markers and voice announcements; redesigned PiP overlay (#2068) leads with a huge L/100 km figure for glance-distance legibility.
- **Maintenance analyzer** — watches consumption drift over time, flags MAF deviation, idle creep, sluggish warm-up.

### Layer 3 — seeing what you actually spend

- **Fill-up log** — manual entry, receipt OCR scan, pump-display OCR, or OBD-II auto-import on disconnect
- **Trip history** — every recorded trip with distance, duration, avg consumption, fuel used, fuel cost
- **Vehicle profiles** — combustion, hybrid, or EV; tank capacity, battery, connectors, multi-vehicle households
- **Cost calculator** — tank fill cost, cross-station savings, fuel-budget projections
- **CO₂ dashboard** — emissions per vehicle with 30-day rolling chart
- **Service reminders** — interval + mileage-driven, configurable per vehicle

### Cross-cutting

- **Right-sized profiles** — Basic (search + favorites + alerts), Medium (+ manual fill-ups + GPS-only trajets), Full (+ OBD2 auto-record + driving scores + loyalty cards), Custom (à la carte). Switching is one tap in Settings.
- **Local-first** — Hive storage, smart caching, offline-capable.
- **Cross-device sync** — optional TankSync cloud backend (self-hostable via Supabase), free, anonymous-or-email auth, opt-in trajet sync.
- **Privacy** — no Firebase, no Google Play Services, no Apple analytics SDKs, no tracking, no ads, GDPR-compliant. Privacy Dashboard surfaces every stored row with one-tap JSON / CSV export + delete-all.
- **23 locales fully translated** — every UI label, including new feature surfaces; no English fallbacks except for brand names and unit masks.
- **Accessibility** — meets Android tap-target and Apple Human Interface tap-target guidelines, semantic labels throughout.
- **Cross-platform architecture** — iOS and Android share the same Dart codebase; platform-specific surfaces (BLE OBD2, background tasks, widgets) live behind plugin interfaces, never inline `Platform.isIOS` branches. Android is the verified platform; the iOS background-wake path for auto-record is pending #1542.

## Screenshots

Captured 2026-05-25 on a Samsung Galaxy S20 (Android 14, French locale) running Sparkilo against the live `Prix Carburants` (France) API. UI is fully localised across 23 languages — these are the French strings; English / German / 20 others render the same screens.

### Find fuel & EV charging

| Search list | Search criteria | Favorites + alerts |
|:--:|:--:|:--:|
| ![Sparkilo home — 10 stations near Pézenas with E85 filter, sorted by distance, price arrow + amenity badges](docs/screenshots/01-search-results.png) | ![Search criteria modal — Nearby vs Search-along-route toggle, fuel-type chips, 10 km radius slider, Open-only toggle, amenity + brand filters, Save as my defaults](docs/screenshots/15-search-criteria.png) | ![Favorites tab — Independent + Pézenas Carburant pinned, with full per-fuel pricing and a 22 kW Type-2 EV charger card](docs/screenshots/02-favorites-and-alerts.png) |
| Real-time prices ranked by distance with amenity badges and a one-tap driving-mode launcher. | Single modal: Nearby vs Search-along-route mode, fuel type, radius, Open-only filter, 8 amenity chips, brand multi-select. Save-as-defaults pins your usual filter set. | Saved fuel stations AND EV chargers in one list, with full per-fuel pricing and one-tap toggle to the price-alerts pane. |

| Map (nearby) | Map (best stops along route) |
|:--:|:--:|
| ![Map view — 10 stations within 10 km radius, green-to-red price markers + a bon-marché/cher legend](docs/screenshots/03-map-price-clusters.png) | ![Map view in Best stops mode — Perpignan→Agde 117 km/77 min route with the 3 cheapest stops surfaced inline (Auchan 0.768 €, Intermarché 0.798 €) on a color-coded price scale](docs/screenshots/14-route-search-best-stops.png) |
| Interactive map with green-to-red price markers across a country-wide radius, fuel-station / EV toggle in the app bar. | Plan a route, get the cheapest stops along it surfaced as ranked chips — saves money + time without making you scroll a list. |

### Track & alert

| Price alerts | Trips list | Per-trip GPS route |
|:--:|:--:|:--:|
| ![Price alerts tab — Diesel ≤ 2.040 € on 26 AVENUE DE VERDUN with the explanatory zone-alerts card and on/off toggle](docs/screenshots/04-price-alerts.png) | ![Trips tab — monthly stats (57 trips, 1176 km, 7.4 L/100), per-trip cards with distance + duration + L/100 km, View all on map link](docs/screenshots/06-trips-monthly.png) | ![Trip detail — 21.4 km / 24m20 / 7.6 L/100 km Peugeot trip with GPS path map and an Efficient / Borderline / Wasteful color legend](docs/screenshots/07-trip-detail-gps-route.png) |
| Per-station, per-fuel-type threshold alerts — background check fires every 30 min. Plus a zone-alert mode for nearby price drops. | Auto + manual trip recording with month-over-month comparison. Every trip carries distance, duration, and (when OBD2 is paired) real L/100 km. | GPS-recorded route per trip, color-coded by instantaneous consumption band — find your wasteful segments at a glance. |

### Consumption & coaching

| Fuel + tank + stats | Trajets aggregated | Feature presets |
|:--:|:--:|:--:|
| ![Fuel tab — 16.5 L tank level + 235 km range, Avg L/100 km 6.70, Total liters 87.8, η_v 0.84 learning chip, per-fill-up cards with L/100 km trend](docs/screenshots/05-fuel-tank-and-stats.png) | ![Trajets-on-map — every recorded trip layered over France with color-coded path lines from Montpellier to Provence-Alpes-Côte d'Azur](docs/screenshots/08-trajets-on-map.png) | ![Settings — Feature management with Basic / Medium / Full / Custom preset cards explaining each tier](docs/screenshots/13-feature-management.png) |
| Live tank level (OBD2-measured when an adapter is paired), L/100 km + cost/km totals, per-fill-up trend chips, and a self-learning η_v calibration badge. | All your recorded trips layered onto a single map — see where you spend most of your driving life. | Right-size the app: Basic (search-only), Medium (+ manual fill-ups + GPS trajets), Full (+ OBD2 auto-record), or Custom. |

### Privacy & sync

| TankSync settings | Privacy dashboard | Data on device |
|:--:|:--:|:--:|
| ![TankSync card — Sparkilo Community connected via email, Switch to anonymous + Sync trip recordings toggle ON, View my data + Link device + Disconnect](docs/screenshots/09-tank-sync.png) | ![Privacy Dashboard — Profile (Standard, E85, FR), API keys (community + shared defaults), Cloud Sync connected via email, Privacy summary card](docs/screenshots/11-privacy-dashboard.png) | ![Privacy Dashboard — Data on this device (2 favorites, 1 rating, 1 alert, 2 price-history stations, 26 cache entries, 140.5 KB), Cloud sync details + Share learned vehicle profiles toggle](docs/screenshots/12-privacy-data-on-device.png) |
| Free cross-device sync via TankSync — favorites, alerts, trip recordings. Anonymous mode keeps the same database without an email. | One-glance summary of what's stored, who has it, and which API keys are in use. Profile section explicit about country + active fuel type. | Detailed breakdown of every stored row — favorites, ratings, alerts, cache, API keys — with the on-device storage footprint in plain KB. |

### Setup

| API key setup |
|:--:|
| ![Settings — API key setup card with Tankerkoenig (not configured, registration link) + EV Charging via OpenChargeMap (app default key)](docs/screenshots/10-api-keys-and-theme.png) |
| Bring-your-own API keys when the community shared key isn't enough. Registration links built in. EV charging uses the bundled default unless you override. |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.41+)
- **For Android builds:** Android SDK with at least one emulator or connected device, plus JDK 17
- **For iOS builds (macOS only):** Xcode 26+, CocoaPods 1.16+, Ruby 3.0+ with Bundler (see [docs/guides/ios-codesigning.md](docs/guides/ios-codesigning.md) for the fastlane match setup)

### Setup

```bash
# Clone the repository
git clone https://github.com/fdittgen-png/tankstellen.git
cd tankstellen

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Launch on a connected device or emulator
flutter run
```

### API Keys

Sparkilo uses official government fuel price APIs. Some require a free API key:

| Country | API | Key Required |
|---------|-----|:------------:|
| Germany | [Tankerkoenig](https://creativecommons.tankerkoenig.de/) | Yes (free) |
| France | [Prix Carburants](https://www.prix-carburants.gouv.fr/) | No |
| Austria | [E-Control](https://www.e-control.at/) | No |
| Spain | [MiTECO](https://sedeaplicaciones.mineco.gob.es/) | No |
| Italy | [MISE](https://dgsaie.mise.gov.it/) | No |

Keys are stored securely on-device (Android Keystore on Android, iOS Keychain on iOS via `flutter_secure_storage`) — never embedded in source code.

## Architecture

```
lib/
  app/              # App entry, routing, theme
  core/
    cache/          # Unified CacheManager with TTLs
    services/       # Abstract interfaces + country implementations
    storage/        # Hive local storage
    sync/           # TankSync cloud backend (optional)
    telemetry/  # Structured error capture
  features/
    search/         # City/postal code search
    map/            # Interactive map with clustering
    favorites/      # Saved stations with swipe actions
    alerts/         # Price drop notifications
    calculator/     # Trip cost calculator
    price_history/  # 30-day charts & predictions
    route_search/   # Along-the-route cheapest station
    station_detail/ # Station info, prices, reports
    profile/        # Settings & preferences
    sync/           # Cross-device sync UI
    widget/         # Home screen widget
    ...
```

**Key patterns:**
- Feature-first clean architecture with data / domain / presentation layers
- Riverpod 3.0 with code generation for state management
- Service abstraction with 4-step fallback: fresh cache → API → stale cache → error
- All API responses wrapped in `ServiceResult<T>` with source tracking

## Development

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Static analysis (must pass with zero warnings)
flutter analyze

# Code generation (after changing models/providers)
dart run build_runner build --delete-conflicting-outputs

# Build release APK
flutter build apk --release
```

### Adding a New Country

The app is designed to be easily extensible. Each country has its own service implementation behind the `StationService` interface. See `lib/features/station_services/` for examples.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.41 / Dart 3.11 |
| State | Riverpod 3.0 with code generation |
| Storage | Hive (local-first) + optional Supabase |
| Networking | Dio 5.x with interceptors |
| Maps | flutter_map + OpenStreetMap (no Google dependency) |
| Data Classes | Freezed + json_serializable |
| Background | WorkManager for periodic alert checks |
| CI/CD | GitHub Actions — analyze, test, build, release |

## Contributing

Contributions are welcome — see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for the full version. Quick summary:

1. **Open an issue first** — describe the bug or feature before writing code
2. **Branch from `master`** — conventional branch names (`feat/`, `fix/`, `refactor/`, `test/`)
3. **Write tests** — every change needs tests (unit, widget, or integration)
4. **Run checks** — `flutter analyze` and `flutter test` must pass with zero warnings
5. **Keep PRs small** — under 400 lines changed (excluding generated files)
6. **Conventional commits** — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`

A feature that doesn't ladder up to one of the three savings layers above is unlikely to be merged.

### Commit Messages

```
feat: add price alerts for Portugal stations
fix: prevent duplicate API calls during rapid scroll
refactor: extract cache TTL constants to config
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Fuel price data provided by official government APIs of each supported country
- Maps powered by [OpenStreetMap](https://www.openstreetmap.org/) contributors
- Built with [Flutter](https://flutter.dev) and the amazing Dart ecosystem
