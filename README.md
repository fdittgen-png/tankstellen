# Tankstellen — Free Fuel Price Comparison

[![CI](https://github.com/fdittgen-png/tankstellen/actions/workflows/ci.yml/badge.svg)](https://github.com/fdittgen-png/tankstellen/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/fdittgen-png/tankstellen)](https://github.com/fdittgen-png/tankstellen/releases)

**Tankstellen** is a free, open-source fuel price comparison app for Europe. It shows real-time fuel prices from official government transparency APIs — no ads, no tracking, fully local-first with optional cloud sync.

<!-- Coming soon: F-Droid and Google Play -->
<!-- [<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="80">](https://f-droid.org/packages/de.tankstellen.fuelprices/) -->
<!-- [<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" alt="Get it on Google Play" height="80">](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) -->

## Features

- **Real-time prices** from official government sources (Tankerkoenig DE, prix-carburants.gouv.fr, MISE IT, and more)
- **7 countries live** — Germany, France, Italy, Austria, Spain, Denmark, Argentina
- **GPS or postal code search** — find the cheapest station near you or anywhere
- **Interactive map** with color-coded price markers, marker clustering for dense areas
- **Bottom navigation** — Search, Map, Favorites, and Settings always one tap away
- **Price history charts** — 30-day local recording with min/max/avg/trend statistics
- **Price alerts with push** — set a target price per fuel/station, get notified when it drops (local background check via WorkManager)
- **"Best time to fill" predictions** — local statistical analysis of daily price patterns from your recorded history
- **Fuel calculator** — distance x consumption x price, pre-fills from the selected station
- **Multiple profiles** — switch between vehicles or countries with different fuel preferences
- **Auto-switch profiles** when crossing borders (GPS-based)
- **Favorites** — save and quickly check your go-to stations
- **TankSync** — optional Supabase backend for cross-device sync, server-side alerts, and community price reports
- **Route search** — plan your trip and find the cheapest stations along the way
- **EV charging stations** — find nearby charging points with connector/power filters
- **23 languages** — DE, EN, FR, ES, IT, DA, SV, FI, NL, PL, PT, CS, SK, HU, RO, BG, HR, SL, LT, LV, ET, EL, NB
- **Full offline support** — cached results available without internet
- **Platform** — Android and iOS

## Privacy First

This app is **local-first** — it works fully without an account, server, or internet connection. The only network requests go directly to the official fuel price APIs and OpenStreetMap for map tiles.

Your API key is stored locally and never shared with anyone except the respective fuel price API. See the full [Privacy Policy](PRIVACY.md).

## How It Works

Fuel prices in many European countries are regulated by law — stations must report price changes to a government agency in real time. Tankstellen reads directly from these free, public APIs:

| Country | Data Source | Status | Key Required? |
|---------|-----------|--------|---------------|
| Germany | Tankerkoenig (MTS-K) | LIVE | Yes (free) |
| France | prix-carburants.gouv.fr | LIVE | No |
| Italy | MISE (MiSE open data) | LIVE | No |
| Austria | E-Control Spritpreisrechner | LIVE | No |
| Spain | Ministerio de Industria | LIVE | No |
| Denmark | OK / Shell / Q8 | LIVE | No |
| Argentina | Secretaría de Energía | LIVE | No |

## Getting Started

1. Download the latest APK from [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases) or build from source
2. Choose your country and preferred fuel type
3. For Germany: register a free API key at [Tankerkoenig](https://creativecommons.tankerkoenig.de/)
4. Search by GPS or postal code

## TankSync (Optional Cloud Backend)

TankSync is a fully optional Supabase-based backend that unlocks additional features while preserving the app's privacy-first design:

- **Cross-device sync** — favorites and alerts synced across your devices
- **Server-side price alerts** — real push notifications even when the app is closed
- **Community price reports** — crowdsourced price corrections for all 7 countries
- **Extended price history** — server-aggregated history beyond the local 30-day window

TankSync is:
- **100% optional** — the app works fully without it
- **Self-hostable** — you can run your own Supabase instance
- **Anonymous** — no email or personal data required
- **Transparent** — every byte stored is visible, exportable, and deletable from within the app
- **Free** — runs on the Supabase free tier (500 MB Postgres, 50K requests/month, EU hosting)

## Build from Source

```bash
# Prerequisites: Flutter SDK 3.x

git clone https://github.com/fdittgen-png/tankstellen.git
cd tankstellen
flutter pub get
flutter run -d emulator-5554   # Android emulator
```

## The Ethics Behind This Project

Fuel prices are public data — governments mandate real-time price reporting precisely so consumers can compare and choose. Yet most fuel price apps monetize this public data through ads, tracking, or premium subscriptions.

**Tankstellen takes a different approach:**

- **Public data should stay public.** No paywalls, no premium tiers.
- **Privacy is non-negotiable.** No user accounts, no analytics SDKs, no data collection. Your location query goes to the API and nowhere else.
- **No corporate dependencies.** No Google Play Services, no Firebase, no ad networks. The app works with just the official APIs and OpenStreetMap.
- **Open source, MIT licensed.** Anyone can audit, fork, or improve the code.
- **Sustainable by choice.** The developer maintains this project voluntarily. If you find it useful, you can support it — but you'll never be pressured to.

## Support the Developer

This app is and will always be free, open source, and ad-free. If it saves you money at the pump, consider giving back:

- **PayPal:** [paypal.me/FlorianDITTGEN](https://www.paypal.me/FlorianDITTGEN)
- **GitHub:** Star this repo, report bugs, or contribute code
- **Word of mouth:** Tell a friend who drives

Every donation helps cover the time spent on development, testing, and expanding to new countries.

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

- Report bugs or suggest features via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues)
- Translations: add or improve ARB files in `lib/l10n/`
- New country APIs: implement the `StationService` interface

## License

[MIT](LICENSE) — use it, fork it, improve it.
