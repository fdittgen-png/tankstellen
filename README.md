<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

<p align="center">
  <img src="assets/play_store_icon_512.png" alt="Sparkilo app icon" width="160" height="160" />
</p>

# Sparkilo

**Find a better fuel stop. Understand what each kilometre costs.**

Sparkilo brings fuel-price comparison, route searches, fill-ups and trip records together in one free,
open-source app. It is for everyday drivers, cross-border commuters and road-trip planners who want to
connect the price at the pump with what running their own car actually costs.

Start with a nearby search. Add a fill-up log when you want to track consumption.
Connect a compatible OBD-II adapter when you want engine data alongside your trips.
The core app works without an account; cloud sync is optional.

[![CI](https://github.com/fdittgen-png/tankstellen/actions/workflows/ci.yml/badge.svg)](https://github.com/fdittgen-png/tankstellen/actions/workflows/ci.yml)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE)
[![Built with Flutter](https://img.shields.io/badge/Built_with-Flutter-blue.svg)](https://flutter.dev)

[Get started](https://github.com/fdittgen-png/tankstellen/wiki/User-en-Getting-Started) · [User guide](https://github.com/fdittgen-png/tankstellen/wiki) ·
[Releases](https://github.com/fdittgen-png/tankstellen/releases) · [Issues & roadmap](https://github.com/fdittgen-png/tankstellen/issues)

## Get Sparkilo

| Platform | Availability |
|---|---|
| Android — Google Play | [Public release on Google Play](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices). Open Testing is a separate beta channel that receives builds first. |
| Android — F-Droid client | Add the [project's own F-Droid repository](https://fdittgen-png.github.io/tankstellen/fdroid/repo) to install the libre build. |
| Android — direct download | APKs of the Google Play build are attached to [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases). |
| iPhone | TestFlight beta only; the app is not yet on the App Store. See the [installation guide](https://github.com/fdittgen-png/tankstellen/wiki/User-en-Getting-Started) for access. |

The libre (F-Droid) build leaves out Google Play Services, ML Kit and the Sentry SDK. Receipt and
pump-display text recognition is therefore unavailable in that build; manual entry and QR-code scanning
remain. Read the installation guide before switching between builds, because their signing keys can
differ.

## What you can do

### Choose your next fuel stop

- **Compare nearby stations** in a list, on a map, or in a table with one column per fuel grade.
  Each result names the data source it came from.
- **Search along a route**, including across a border into supported countries.
  One profile per country holds the preferred fuel for that leg.
- **Keep useful stations close** with favourites, price alerts (per station or within a radius) and
  price history. History builds from the prices the app has collected; "best time to fill" hints are a
  heuristic over that history, not a forecast guarantee.
- **Find EV charging locations** through Open Charge Map, with connector, power and the status Open
  Charge Map reports. That directory is not a live occupancy feed and carries no guaranteed tariffs.

### Understand your running costs

- **Log fill-ups and vehicles** by hand, or read a receipt or pump display with on-device text
  recognition on the Google Play and iOS builds. Check the extracted values before saving.
- **Follow consumption and cost per kilometre**, tank level and range, compare the fuels you have
  used, and price a planned journey with the fuel-cost calculator.
- **Keep your records useful** with trip history, service reminders, data export and optional
  TankSync across devices.

### Explore your driving

- **Record trips with GPS alone**, no adapter needed: route, distance, speed and an estimated
  consumption.
- **Add a compatible ELM327 OBD-II adapter** to enrich trips with the engine signals your vehicle
  exposes, such as fuel rate, RPM, throttle or load.
- **Review how you drive** through trip summaries, a route coloured by efficiency, and coaching hints.
  Adapter compatibility, available signals and background recording depend on the vehicle, the phone,
  the operating system and the build.

Choose the Basic, Medium, Full or Custom feature preset to keep the app as simple or as deep as you
need. The interface is available in 23 languages.

## A look inside

| Compare fuel prices | Plan across borders | Follow a tank's consumption |
|:---:|:---:|:---:|
| ![Station search results showing prices and their source](docs/screenshots/02-search-results.jpg) | ![Route search results with stations from France and Spain](docs/screenshots/08-route-cross-border.jpg) | ![Fuel screen comparing fill-up records with recorded trips](docs/screenshots/15-fuel-tab.jpg) |

Android screenshots captured in September 2026. The [illustrated user guide](https://github.com/fdittgen-png/tankstellen/wiki) has the full tour.

## Coverage you can plan around

Fuel data comes from government open data and, where no national feed exists, from retailer feeds.
Coverage, fuel grades, station details and update frequency vary by source. Cached results stay
readable offline; fresh prices need a connection and a reachable provider.

The code contains 17 country integrations. Thirteen are offered in the app's country selection:

| Countries | What you get |
|---|---|
| Germany, France, Austria, Spain, Italy, Portugal, Slovenia, United Kingdom, Mexico, Argentina | Station-level prices from a national source. Update cadence ranges from about 5 minutes (Germany) to daily. Germany needs a free [Tankerkönig API key](https://onboarding.tankerkoenig.de/); without one the app shows demo data. Argentina's source host was unreachable in September 2026 ([#4171](https://github.com/fdittgen-png/tankstellen/issues/4171)). |
| Denmark | Prices from the OK, Shell and Q8 chains only — a cheapest result speaks for those three chains, not the whole market. |
| Luxembourg | The national regulated price, shown at city locations. These are not individual station quotes or coordinates. |
| Greece | Regional averages from the ministry's price bulletins, one location per prefecture rather than per forecourt. |
| South Korea, Chile, Romania | Implemented but hidden until their live feeds are verified. South Korea and Chile also need provider credentials. |
| Australia | Unavailable: the NSW FuelCheck endpoint was retired ([#804](https://github.com/fdittgen-png/tankstellen/issues/804)); the integration stays hidden. |

For a cross-border journey, set up a profile with the right fuel for each country. Fuel names and grades
differ across borders, so check that the selected grade suits your car.

The [country configuration](lib/core/country/country_config.dart) and
[provider capabilities](lib/core/services/country_capabilities.dart) are the source of truth for this
table; the [issue tracker](https://github.com/fdittgen-png/tankstellen/issues) follows coverage repairs.

## Measured data and estimates

- **Fill-up consumption** comes from the litres you enter and the distance between full tanks.
  It is only as good as the records are complete.
- **Vehicle-reported fuel rate** comes from the ECU when the car supports it. Other OBD-II
  consumption values are calculated from engine measurements.
- **GPS-only consumption, range and CO₂** are estimates based on vehicle settings, recorded
  driving and calibration against your fill-ups. Coaching and forecasts are guidance.

Consumption modelling is still being validated against real driving and fill-up data, and the project
has no general accuracy benchmark yet. The new fuzzy consumption engine is staged and not yet the
production estimator: see the [design decision](docs/decisions/0023-fuzzy-consumption-engine.md), the
empty [replay corpus](test/fixtures/consumption_corpus/README.md) and
[#4222](https://github.com/fdittgen-png/tankstellen/issues/4222). OBD-II lost-connection recovery is
still being field-validated ([#4195](https://github.com/fdittgen-png/tankstellen/issues/4195)).

## Privacy & GDPR

Sparkilo is local-first and has no ads, no advertising identifiers and no tracking. Fuel search and local
logging need no account. Online features still send requests:

- **Prices, search, routes and maps:** a search sends its coordinates to the price source for that
  country; address search, routing, road data, EV charging and map tiles go to their services
  (Nominatim, OSRM, Overpass, Open Charge Map, OpenStreetMap). Each of them sees the request and your
  IP address. Your Tankerkönig key is sent only to Tankerkönig. Map tiles go through the Sparkilo tile
  proxy by default; you can switch to OpenStreetMap directly in the privacy settings.
- **TankSync:** optional cloud sync of favourites, alerts, vehicles, fill-ups and similar records to
  your own Supabase project, a group, or the Sparkilo Community database in the EU. Recorded GPS trips
  leave the device only if you also turn on trip sync.
- **Other optional services:** crash reports and performance traces to Sentry (Google Play and iOS
  builds, opt-in), online VIN decoding (NHTSA vPIC) and internet brand logos (Clearbit) each have their
  own switch.
- **Your controls:** consent settings with dates, a one-ZIP export of your data, local deletion, and
  TankSync account deletion from inside the app.

Read the [privacy policy v4](https://fdittgen-png.github.io/tankstellen/privacy-policy/) and the
[privacy and sync guide](https://github.com/fdittgen-png/tankstellen/wiki/User-en-Privacy-Profiles-Sync)
for purposes, recipients and controls. [`docs/privacy/data_inventory.json`](docs/privacy/data_inventory.json)
is the machine-readable inventory; tests keep the policy, the Play Data Safety answers, the iOS privacy
manifest and this README in line with it.

## Project status

Sparkilo is an actively developed independent project with a public Android release and an iOS beta.
Background recording ([#3417](https://github.com/fdittgen-png/tankstellen/issues/3417)), OBD-II
recovery, consumption modelling and provider reliability are active areas of work. Alerts and
background features depend on permissions and operating-system limits, and vary by platform and build.
Trip-cost, refuelling and vehicle-comparison features are planned in
[#4358](https://github.com/fdittgen-png/tankstellen/issues/4358).

The [release notes](https://github.com/fdittgen-png/tankstellen/releases) list shipped changes;
[open issues](https://github.com/fdittgen-png/tankstellen/issues) track known problems and planned work.

## Build and develop

The public app is **Sparkilo**. The repository, Dart package (`tankstellen`) and Android application ID
(`de.tankstellen.fuelprices`) keep the project's original name.

Use **Flutter 3.44.9** (the version [CI](.github/workflows/ci.yml) pins) with Dart 3.12.
Android development needs the Android SDK, JDK 17 and a device or emulator.
iOS development needs macOS and Xcode; see the [iOS signing guide](docs/guides/ios-codesigning.md).

```bash
git clone https://github.com/fdittgen-png/tankstellen.git
cd tankstellen
flutter pub get
bash scripts/install_hooks.sh
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor play
```

The run command targets Android. Provider keys are entered in the app; TankSync is optional.
[Configuration](docs/CONFIGURATION.md) describes build flags and runtime settings.

```bash
flutter analyze
flutter test --exclude-tags=network
flutter build apk --debug --flavor play
```

Release builds need a signing keystore; see [release builds](docs/CONTRIBUTING.md#release-builds).
The [F-Droid build guide](docs/guides/fdroid-submission.md) covers the libre flavour, and
[network tests](docs/guides/NETWORK_TESTS.md) covers the live-provider checks.

## Architecture

The Flutter codebase is organised by feature, with shared services for data access, caching, storage
and platform integration.

| Area | Approach |
|---|---|
| UI and state | Flutter with Riverpod code generation; feature folders separate domain, data and presentation. |
| External data | Each country implements a shared station-service contract and declares its provider capabilities. Results carry their source. |
| Resilience | Service chains combine requests with cache fallbacks; upstream availability still limits fresh results. |
| Local records | Hive persistence, with secure storage for credentials. |
| Optional sync | TankSync on Supabase; [backend setup](supabase/README.md) is included for self-hosting. |
| Maps and devices | OpenStreetMap through flutter_map; platform integrations for location, Bluetooth, background work and widgets. |
| Validation | Unit, widget and integration tests plus static checks in GitHub Actions; live-provider checks are tagged and run separately. |

The [architecture decisions](docs/decisions/README.md) explain the choices and trade-offs. The
[contributor guide](docs/CONTRIBUTING.md) includes a codebase tour, and the
[new-country guide](docs/guides/NEW_COUNTRY.md) explains how to add a provider.

## Contributing

Useful contributions include reproducible bug reports, provider verification, translation review,
accessibility improvements and tests on real devices and adapters.

Before changing code, read the [contribution guide](docs/CONTRIBUTING.md) and the
[repository rules](docs/AGENT_RULES.md). Link each change to an issue, branch from `master`, and keep pull
requests focused. Follow the clean code-generation and localisation workflow for models, providers and
user-facing strings.

## License and acknowledgments

Sparkilo is licensed under the
[GNU Affero General Public License v3.0 or later](LICENSE).
© 2026 Florian DITTGEN. It was MIT until 2026-09-20 — see
[ADR 0028](docs/decisions/0028-agpl-with-a-commercial-exception.md) for
why that changed, and note that everything released before then stays
MIT and can be forked on those terms for ever.

What this means for you: **almost certainly nothing.** Associations,
public bodies, schools, individuals — and companies running Sparkilo as
it ships — owe nothing and never will, whether or not they run a
commercial fleet on it. The AGPL's §13 obligation is triggered by
*modifying* Sparkilo *and* serving it over a network, not by using it
and not by charging for the service you run with it. If you do modify it
and would rather not publish the changes, there is a
[commercial licence](COMMERCIAL-LICENCE.md).

Two additional permissions are granted under §7 — for app-store
distribution and for the Play flavour's proprietary Google libraries —
in [LICENSE-EXCEPTIONS.md](LICENSE-EXCEPTIONS.md).

"Sparkilo" and its logo are trademarks; a fork is welcome and needs its
own name ([TRADEMARK.md](TRADEMARK.md)). Contributions: see
[CONTRIBUTING.md](CONTRIBUTING.md).

If Sparkilo saves you money, you can support its development through the repository's GitHub Sponsor
button or [PayPal](https://www.paypal.me/FlorianDITTGEN).

Thanks to the fuel-price publishers, [Tankerkönig](https://tankerkoenig.de/) (CC BY 4.0),
[Open Charge Map](https://openchargemap.org/), [OpenStreetMap contributors](https://www.openstreetmap.org/copyright),
and the [Flutter](https://flutter.dev) and Dart communities. Third-party data and assets remain subject to
their own licences and attribution requirements.
