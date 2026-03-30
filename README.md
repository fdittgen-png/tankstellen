# Tankstellen — Free Fuel Price Comparison

[![CI](https://github.com/fdittgen-png/tankstellen-app/actions/workflows/ci.yml/badge.svg)](https://github.com/fdittgen-png/tankstellen-app/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/fdittgen-png/tankstellen-app)](https://github.com/fdittgen-png/tankstellen-app/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)](https://flutter.dev)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

**Tankstellen** is a free, open-source fuel price comparison app for Europe and beyond. It shows real-time fuel prices from official government transparency APIs — no ads, no tracking, fully local-first with optional cloud sync.

<!-- Coming soon: F-Droid and Google Play -->
<!-- [<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="80">](https://f-droid.org/packages/de.tankstellen.fuelprices/) -->
<!-- [<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" alt="Get it on Google Play" height="80">](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) -->

## Features

### Search & Discovery
- **Real-time prices** from 11 official government sources
- **GPS or postal code search** — find the cheapest station near you or anywhere
- **Interactive map** with color-coded price markers and marker clustering
- **EV charging stations** — OpenChargeMap integration with connector types, power levels, and availability
- **Route search** — find the cheapest fuel stops along your trip with 3 strategies (Uniform, Cheapest, Balanced)
- **Station ratings** — 1-5 star ratings with local, private, or shared visibility

### Monitoring & Alerts
- **Price history charts** — 30-day local recording with min/max/avg/trend statistics
- **Price alerts** — set a target price per fuel type and station, get push notifications when it drops (hourly background checks via WorkManager)
- **"Best time to fill" predictions** — statistical analysis of daily price patterns
- **Fuel calculator** — distance x consumption x price, pre-fills from the selected station

### Organization & Sync
- **Favorites** — save stations with swipe gestures for quick navigation and removal
- **Multiple profiles** — switch between vehicles or countries with different fuel preferences
- **Auto-switch profiles** when crossing borders (GPS-based country detection)
- **TankSync** — optional Supabase backend for cross-device sync, server-side alerts, and community reports
- **Ignored stations** — hide unwanted stations from all results, map, and routes

### Platform & Internationalization
- **11 countries** — Germany, France, Italy, Austria, Spain, Denmark, Argentina, Portugal, United Kingdom, Australia, Mexico
- **23 languages** — Bulgarian, Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French, German, Greek, Hungarian, Italian, Latvian, Lithuanian, Norwegian, Polish, Portuguese, Romanian, Slovak, Slovenian, Spanish, Swedish
- **Full offline support** — cached results available without internet
- **Android** (iOS planned)

## Privacy First

This app is **local-first** — it works fully without an account, server, or internet connection. The only network requests go directly to the official fuel price APIs and OpenStreetMap for map tiles.

Your API key is stored in the platform keystore (Android Keystore) and never shared with anyone except the respective fuel price API. See the full [Privacy Policy](PRIVACY.md).

## Supported Countries

| Country | Data Source | Fuel Types | Key Required? |
|---------|-----------|------------|---------------|
| Germany | [Tankerkoenig](https://creativecommons.tankerkoenig.de/) (MTS-K) | Super E5, Super E10, Diesel | Yes (free) |
| France | [prix-carburants.gouv.fr](https://www.prix-carburants.gouv.fr/) | SP95, SP98, E10, Gazole, E85, GPLc | No |
| Austria | [E-Control](https://www.e-control.at/spritpreisrechner) | Super 95, Super 95 E10, Diesel | No |
| Spain | [Geoportal Gasolineras](https://geoportalgasolineras.es/) (MITECO) | Gasolina 95/98, Gasoleo A, GLP | No |
| Italy | [Osservaprezzi](https://osservaprezzi.mise.gov.it/) (MASE) | Benzina, Gasolio, GPL, Metano | No |
| Denmark | OK / Shell / Q8 | Blyfri 95, Diesel | No |
| Argentina | [Secretaria de Energia](https://datos.energia.gob.ar/) | Nafta, Gas Oil, GNC | No |
| Portugal | [DGEG](https://www.dgeg.gov.pt/) | Gasolina 95/98, Gasoleo, GPL Auto | No |
| United Kingdom | CMA Fuel Finder | Unleaded, Super, Diesel, Premium Diesel | No |
| Australia | FuelCheck NSW | Unleaded 91/95/98, Diesel, LPG | No |
| Mexico | [CRE / datos.gob.mx](https://datos.gob.mx/) | Regular, Premium, Diesel | No |

All data sources are official government transparency APIs or regulated open data portals.

## Architecture

```
lib/
├── app/                    # App entry point, router, shell
├── core/                   # Shared infrastructure
│   ├── background/         # WorkManager periodic tasks
│   ├── cache/              # CacheManager with TTL management
│   ├── country/            # Country detection and configuration
│   ├── error_tracing/      # Error classification and diagnostics
│   ├── location/           # GPS and geocoding
│   ├── services/           # API service layer
│   │   ├── impl/           # 11 country API + demo + geocoding implementations
│   │   └── mixins/         # Shared parsing helpers
│   ├── storage/            # Hive local storage
│   ├── sync/               # Supabase sync service
│   └── utils/              # Price formatting, station extensions, geo utils
├── features/               # Feature modules (clean architecture)
│   ├── alerts/             # Price alert management
│   ├── calculator/         # Fuel cost calculator
│   ├── favorites/          # Favorite stations
│   ├── itinerary/          # Saved routes
│   ├── map/                # Map view with station markers
│   ├── price_history/      # Price recording and charts
│   ├── profile/            # User profiles and settings
│   ├── report/             # Community price reports
│   ├── route_search/       # Route optimization (3 strategies)
│   ├── search/             # Station search + EV charging
│   ├── setup/              # First-launch configuration
│   ├── station_detail/     # Individual station view
│   └── sync/               # TankSync wizard and screens
└── l10n/                   # 23 language ARB files
```

### Key Design Patterns
- **Feature-first clean architecture** — each feature has `data/`, `domain/`, `presentation/`, `providers/`
- **Service chain with fallback** — Fresh cache -> API -> Stale cache -> Error
- **Local-first sync** — save locally first, sync to server async, local always wins on conflict
- **Riverpod with code generation** — `@riverpod` annotations, never manual provider creation

## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.41 / Dart 3.11 |
| State Management | Riverpod 3.0 with code generation |
| Local Storage | Hive 2.2 (key-value) |
| Networking | Dio 5.x with interceptors |
| Maps | flutter_map + OpenStreetMap (free, no API key) |
| Backend (optional) | Supabase (anonymous auth, Postgres, Edge Functions) |
| Background Tasks | WorkManager (Android) |
| Notifications | flutter_local_notifications |
| Crash Reporting | Sentry (privacy-first, optional) |
| Models | Freezed + json_serializable |
| Routing | GoRouter with bottom navigation shell |
| EV Data | OpenChargeMap API |

## Getting Started

1. Download the latest APK from [GitHub Releases](https://github.com/fdittgen-png/tankstellen-app/releases) or build from source
2. Choose your country and preferred fuel type
3. For Germany: register a free API key at [Tankerkoenig](https://creativecommons.tankerkoenig.de/)
4. Search by GPS or postal code

## Build from Source

```bash
# Prerequisites: Flutter SDK 3.x, Android SDK, JDK 17

git clone https://github.com/fdittgen-png/tankstellen-app.git
cd tankstellen-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d emulator-5554   # Android emulator
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for full development setup and guidelines.

## TankSync (Optional Cloud Backend)

TankSync is a fully optional Supabase-based backend that unlocks additional features while preserving the app's privacy-first design:

- **Cross-device sync** — favorites, alerts, ratings, and ignored stations synced across devices
- **Server-side price alerts** — push notifications via ntfy.sh even when the app is closed
- **Community price reports** — crowdsourced price corrections
- **Extended price history** — server-aggregated history beyond the local 30-day window
- **Saved itineraries** — store and share route plans across devices

TankSync is:
- **100% optional** — the app works fully without it
- **Self-hostable** — run your own Supabase instance
- **Anonymous** — no email required (optional email auth available)
- **Transparent** — every byte stored is visible, exportable, and deletable from the app
- **Free** — runs on the Supabase free tier (500 MB Postgres, 50K requests/month, EU hosting)

Database: 10 tables with Row-Level Security, anonymous + email auth, QR code sharing for database access.

## The Ethics Behind This Project

Fuel prices are public data — governments mandate real-time price reporting precisely so consumers can compare and choose. Yet most fuel price apps monetize this public data through ads, tracking, or premium subscriptions.

**Tankstellen takes a different approach:**

- **Public data should stay public.** No paywalls, no premium tiers.
- **Privacy is non-negotiable.** No user accounts required, no analytics SDKs, no data collection. Your location query goes to the API and nowhere else.
- **No corporate dependencies.** No Google Play Services, no Firebase, no ad networks. The app works with just the official APIs and OpenStreetMap.
- **Open source, MIT licensed.** Anyone can audit, fork, or improve the code.
- **Sustainable by choice.** The developer maintains this project voluntarily. If you find it useful, you can support it — but you'll never be pressured to.

## Support the Developer

This app is and will always be free, open source, and ad-free. If it saves you money at the pump, consider giving back:

- **PayPal:** [paypal.me/FlorianDITTGEN](https://www.paypal.me/FlorianDITTGEN)
- **GitHub:** Star this repo, report bugs, or contribute code
- **Word of mouth:** Tell a friend who drives

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- Report bugs or suggest features via [GitHub Issues](https://github.com/fdittgen-png/tankstellen-app/issues)
- Translations: add or improve ARB files in `lib/l10n/`
- New country APIs: implement the `StationService` interface
- See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

## License

[MIT](LICENSE) — use it, fork it, improve it.
