<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Sparkilo (`tankstellen`) — Complete Project Reference

> **One document, everything about this project**: what the app is, how it is built,
> the architecture, the rules a contributor must follow, the CI/CD topology on GitHub,
> the GitHub repository configuration, and the three distribution channels
> (Google Play, Apple App Store, F-Droid).
>
> Generated 2026-07-31 against `master` @ `884713dbf`, app version **6.0.4+5137**.
>
> Companion documents this one summarises and points at:
> `README.md`, `CLAUDE.md` / `docs/AGENT_RULES.md`, `docs/decisions/` (ADRs),
> `docs/guides/`, the `tankstellen-conventions` skill.

---

## Table of contents

1. [Identity & positioning](#1-identity--positioning)
2. [Product — what the app actually does](#2-product--what-the-app-actually-does)
3. [Technology stack](#3-technology-stack)
4. [Technical architecture](#4-technical-architecture)
5. [Core subsystems in depth](#5-core-subsystems-in-depth)
6. [Data sources — the 17 countries](#6-data-sources--the-17-countries)
7. [Localisation (23 locales)](#7-localisation-23-locales)
8. [TankSync — the optional cloud backend](#8-tanksync--the-optional-cloud-backend)
9. [Privacy, security & compliance posture](#9-privacy-security--compliance-posture)
10. [Coding best practices](#10-coding-best-practices)
11. [Development best practices & workflow](#11-development-best-practices--workflow)
12. [Testing strategy](#12-testing-strategy)
13. [CI on GitHub — the workflow topology](#13-ci-on-github--the-workflow-topology)
14. [GitHub repository configuration](#14-github-repository-configuration)
15. [Google Play distribution](#15-google-play-distribution)
16. [Apple App Store / TestFlight distribution](#16-apple-app-store--testflight-distribution)
17. [F-Droid distribution (two channels)](#17-f-droid-distribution-two-channels)
18. [GitHub Pages site](#18-github-pages-site)
19. [Secrets inventory](#19-secrets-inventory)
20. [Local development environment](#20-local-development-environment)
21. [Known constraints, traps & standing decisions](#21-known-constraints-traps--standing-decisions)
22. [Known gaps and stale documentation](#22-known-gaps-and-stale-documentation)

---

## 1. Identity & positioning

| | |
|---|---|
| **Public brand** | **Sparkilo** |
| **Repository / technical identity** | `tankstellen` (github.com/fdittgen-png/tankstellen) |
| **Android `applicationId`** | `de.tankstellen.fuelprices` |
| **Android `namespace`** | `de.tankstellen.tankstellen` |
| **iOS bundle ID** | `de.tankstellen.tankstellen` (widget: `…​.TankstellenWidget`) |
| **Apple Team ID** | `C4Y5RDF8P9` |
| **App Store ID** | `6766543414` |
| **Licence** | MIT (ADR 0007) |
| **Author** | Florian DITTGEN — `fdittgen@gmail.com` (Apple Developer account is `fdittgen@gmx.de`) |
| **Version** | `6.0.4+5137` (`pubspec.yaml`) |
| **Pitch** | *The cost of driving, attacked from three sides.* 17 countries, 23 languages, no ads, no tracking. |

### The leitmotiv — three savings layers

Every feature must ladder up to at least one of these, in priority order. **A proposal
serving none of them gets pushed back before code is written.**

1. **Buy fuel for less money** — live cross-country price comparison, route-aware
   cheapest-stop planning, drop alerts, 30-day price history, "best time to fill".
2. **Burn less of it per kilometre** — OBD-II / GPS trip recording, live eco-coaching,
   driving score, throttle/RPM histograms, maintenance drift analysis.
3. **See what you're really spending** — fill-up log (manual / OCR / OBD auto-import),
   per-trip cost, CO₂ dashboard, fuel-cost projections, service reminders.

---

## 2. Product — what the app actually does

### Layer 1 — buying cheaper

- **Real-time prices** from each country's **official government open-data source**
  (not crowdsourced, not scraped). The results header names the live source and links
  to it (e.g. *France — Prix-Carburants (gouv.fr)*).
- **17 countries**, **23 languages**.
- **One central search button** in a concave notch of the 5-tab bottom bar
  (Favorites · Map · **Search** · Fuel · Trips) opening a *Search criteria* sheet:
  Nearby vs Search-along-route, fuel-type chips (E10 / E5 / 98 / Diesel / LPG / CNG /
  E85 / EV), radius slider, *Open only*, amenity filters, highway filter,
  *Save as my defaults*.
- **Result sorting & detail** — sort by Distance / Price / A-Z / 24h-open; each card
  carries price, trend arrow, community star rating, amenity badges, distance,
  last-update time, favourite star.
- **Route-aware search** — *All stations* vs *Best stops*, distances measured **along
  the corridor**, a *Cheapest* badge, partial-results banner so a slow country never
  blocks the answer.
- **Cross-border route search** — a corridor crossing a border queries **every**
  country it passes through with that country's provider and that country profile's
  fuel grade; the header credits every contributing source; results stream in
  progressively.
- **Fuel Station Radar** — a one-tap GPS-centred scan. On search results a floating
  pill starts it; during trip recording a *Closest station* card is pinned at the top
  with a proximity fill-bar and swipe-through candidates. Station **locations** are
  cached up to an hour (forecourts don't move); only **prices** for imminent stations
  are fetched just-in-time.
- **Price alerts** — per-station thresholds + radius alerts, on-device,
  consent-gated, evaluated only when nearby.
- **Price history & predictions** — 30-day charts, day-of-week + threshold heuristic.
- **Brand filter**, **Favorites** (fuel + EV chargers in one list, swipe actions),
  **home-screen widget** (two layouts, cold/warm tap routing, in-widget refresh),
  **EV charging** via Open Charge Map (connector, max power, live availability).

### Layer 2 — burning less

- **OBD2 optional, not required.** Medium-profile users record trips with GPS alone;
  Full-profile users get the OBD2 telemetry pipeline. Both produce real L/100 km via a
  **per-vehicle calibration matrix** (ADR 0010) that converges after 3–8 fill-ups.
- **GPS-only trip recorder** — speed-band integration, accel/brake event counting,
  altitude grade tracking, live consumption estimator (ADR 0012).
- **OBD2 trip recorder** — any ELM327-compatible adapter (BLE + Classic RFCOMM +
  dual-mode); fuel rate, RPM, throttle %, engine load, GPS path; speed-density fallback
  when PID 5E is absent.
- **Always-both recording** — OBD2 and GPS run in parallel; mid-trip dropouts are
  tolerated; the trip classifies at end as `gpsOnly` / `gpsPlusObd2` / `hybrid` from the
  coverage ratio.
- **Auto-record** — pair adapter↔vehicle, auto-connect on Bluetooth, auto-start on
  movement, auto-save on disconnect (Android verified; iOS background-wake is #1542).
- **Live coaching** — shift-up/down and ease-pedal tiles on OBD2 trips;
  lift-off-coast / anticipate-brake / smooth-accel on GPS-only (rolling 5 s window).
  Haptic eco-coach; IMU (accelerometer/gyroscope) hard-event detection on both paths.
- **Trip detail** — summary + GPS route map colour-coded *Efficient / Borderline /
  Wasteful*, GPX export, *Top wasteful behaviours* (litres wasted), *How you used the
  engine* (throttle-position and RPM-band breakdowns).
- **Driving score** — composite 0–100 per trip, opt-in.
- **Driving mode** — full-screen in-car map, voice announcements, and a PiP overlay that
  flips to a huge price layout on station approach (Epic #2065, ADR 0011). A
  *Test approach overlay* button in the Privacy Dashboard fires a synthetic in-radius
  signal for 30 s so it can be verified without driving.
- **Maintenance analyzer** — consumption drift, MAF deviation, idle creep, sluggish
  warm-up.

### Layer 3 — seeing what you spend

- **Fill-up log** — manual, receipt OCR (incl. shared-PDF receipts
  rasterised on-device), or OBD auto-import on disconnect. Each fill shows L/100 km,
  % delta vs previous, €/L.
- **Fuel tab** — live tank level + estimated range, consumption stats with an accuracy
  indicator, learned volumetric efficiency η_v, avg L/100 km, avg cost/km, totals.
- **Trip history**, **vehicle profiles** (combustion / hybrid / EV, multi-vehicle),
  **fuel-cost calculator**, **carbon dashboard** (cost + CO₂, split by trip length and
  speed band), **service reminders**.

### Cross-cutting

- **Feature-management presets** — **Basic / Medium / Full / Custom**; a `Feature` enum
  (~32 values) with a manifest declaring per-`BuildChannel` defaults and `requires:`
  prerequisite edges.
- **One profile per country** — each profile pins a country and preferred fuel grade
  and activates the matching provider; route-mode reads each country's profile grade.
- **Grouped Settings** — Profile · Setup & data sources · Features & usage ·
  Account & sync · Appearance · Privacy · About.
- **Local-first** (ADR 0002), **optional TankSync** cloud, **Privacy Dashboard** with
  per-row JSON/CSV export, error-log dump and one-tap delete-all.
- **Accessibility** — Android + Apple tap-target guidelines asserted in tests,
  semantic labels throughout.
- **Android Auto** (`androidx.car.app` 1.7.0, `play` flavor only — GMS-free artifact,
  Robolectric-tested car screens).

---

## 3. Technology stack

| Layer | Technology | Notes |
|---|---|---|
| Framework | **Flutter 3.41.9** (stable, pinned) / **Dart 3.11.3** | CI pins the exact SDK — bumping is deliberate, never drift (#1936) |
| State | **Riverpod 3** + `riverpod_annotation` codegen | No manual `Provider`/`StateProvider` |
| Models | **freezed 3** + `json_serializable` (`explicit_to_json: true`) | Deep serialisation required by Hive (#690) |
| Storage | **Hive 2** (8+ boxes, 6 encrypted with an AES key from `flutter_secure_storage`) | ADR 0004 / re-validated by ADR 0008 |
| HTTP | **Dio 5** with `RateLimitInterceptor` + `ConditionalGetInterceptor`, built by `DioFactory` | Never `Dio()` directly |
| Maps | **flutter_map 8** + OpenStreetMap, `flutter_map_marker_cluster`, `latlong2` (held at 0.9) | No Google Maps; tiles via a Supabase caching proxy (ADR 0013) |
| Routing | **go_router 17**; **OSRM** for road routing + `/table` distance matrix |  |
| Location | `geolocator` (GMS on Play, LocationManager on F-Droid), `geocoding`, Nominatim |  |
| Sensors | `sensors_plus` (IMU, GMS-free) behind `lib/core/sensors/imu_sensor_source.dart` |  |
| OBD2 | `flutter_blue_plus` **pinned to 1.x** (2.x is a commercial licence, #2072) + in-repo Classic RFCOMM channel |  |
| OCR | ML Kit text recognition on **Android**, **Apple Vision** on iOS (ML Kit pods stripped via vendored `third_party/` forks, #3172) |  |
| Background | **WorkManager** (Android); BGTaskScheduler on iOS (partial) |  |
| Notifications | `flutter_local_notifications`, `app_badge_plus` |  |
| Cloud (optional) | **Supabase** (`supabase_flutter`) — self-hostable |  |
| Crash/error | **Sentry** on Play/iOS, consent-gated; **compiled out entirely on F-Droid** (#3492) |  |
| ML | `tflite_flutter` (price-prediction inference seam) |  |
| UI | `flex_color_scheme`, `shimmer`, `cached_network_image`, `qr_flutter`, `flutter_tts` |  |
| Scanning | `mobile_scanner` (Play/iOS) ↔ **`flutter_zxing`** (libre/F-Droid, #3477) |  |
| CI/CD | **GitHub Actions** (20 workflows), **fastlane** (iOS), Play Developer API (Python), `fdroidserver` |  |

### Deliberate dependency holds

| Package | Held at | Why |
|---|---|---|
| `flutter_blue_plus` | 1.x | 2.x switched to a commercial-only licence (#2072) |
| `latlong2` | 0.9.x | 0.10 is a breaking API bump across the map/routing layer (#1684) |
| `connectivity_plus` | < 7.1 | 7.1 iOS source references the iOS 26 SDK symbol `NWPath.isUltraConstrained`; the macOS runner's Xcode 16 fails to compile it |
| riverpod / analyzer cluster (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint` **pinned exactly 3.1.3**, `json_serializable`, `json_annotation`) | lockstep | `riverpod_lint` ≥ 3.1.4 → analyzer ^12 → `meta` ^1.18, which the Flutter SDK's `flutter_test` `meta 1.17.0` pin forbids. **All members are Dependabot-ignored** — ignoring one alone lets Dependabot co-bump the rest (#3352, #3563) |
| `meta` / `test` / `test_api` / `test_core` | SDK-pinned | Same root cause (#3567) |
| `freezed` | stable only | Dependabot pulled a `-dev` prerelease into #3563 |
| `google_mlkit_text_recognition` / `google_mlkit_commons` | vendored `third_party/` | iOS plugin platform removed so the pods leave the IPA (#3172) |

---

## 4. Technical architecture

### Directory layout

```
lib/
├── main.dart
├── app/                      # composition root
│   ├── app.dart, app_initializer.dart, router.dart(+.g), theme.dart
│   ├── shell/, shell_screen.dart, routes/, startup/, widgets/
├── core/                     # cross-cutting ONLY
│   ├── background/  cache/  calendar/  constants/  country/  data/  domain/
│   ├── error/  export/  feedback/  language/  location/  logging/  navigation/
│   ├── network/  notifications/  perf/  permissions/  platform/  providers/
│   ├── sensors/  services/  sharing/  storage/  sync/  telemetry/  theme/
│   ├── types/  utils/  widgets/
└── features/<name>/
    ├── data/{models,repositories}/
    ├── domain/{entities,services}/     # pure Dart — no Flutter, no Hive, no Dio
    ├── presentation/{screens,widgets}/
    └── providers/                      # the ONLY bridge presentation → data
```

**Features present** (`lib/features/`): `achievements`, `alerts`, `approach`,
`calculator`, `car` (Android Auto), `carbon`, `consent`, `consumption`, `driving`,
`ev`, `favorites`, `feature_management`, `glide_coach`, `itinerary`, `loyalty`, `map`,
`obd2`, `payment`, `price_history`, `profile`, `report`, `route_search`, `search`,
`setup`, `station_detail`, `station_services`, `sync`, `vehicle`, `widget`.

### Architectural hard rules

- **Features never reach into each other's internals.** Cross-feature data flows
  through a `core/` provider or a shared entity. Enforced by
  `test/lint/feature_boundary_test.dart` (per-file import-pair counts that may only
  decrease) and `scripts/check_module_boundaries.sh`.
- **`presentation/` never imports `data/` directly** — always via `providers/`
  (`test/lint/presentation_data_imports_test.dart`).
- **`domain/` is pure Dart** — unit-testable without a widget tester.
- **Size budgets**: screens < 300 lines, providers < 200, repository methods < 50.
  A grandfathered allow-list lives in `test/lint/file_length_test.dart` — it is a
  single shared snapshot map and a notorious merge-conflict magnet.
- **Cross-platform by default** (ADR 0009): iOS + Android share one Dart codebase;
  platform-specific surfaces (BLE, background tasks, widgets, sensors) live behind
  loosely-coupled plugin interfaces. **Never** inline `if (Platform.isIOS)` in shared
  code — enforced by `test/lint/no_inline_platform_check_test.dart`.
- **One code base for all countries, activation by configuration only.** There is no
  per-country variant, group or flavor — `country_config` + the registry is the only
  switch. (`play` / `fdroid` are *store channels*, not country groups.)

### The service-chain pattern (ADR 0005)

Every HTTP-backed data source goes through a chain that gives fresh-first reads, stale
fallback, request coalescing, per-Dio rate limiting and a structured result:

```
cache.getFresh() → service.fetch() → cache.get(stale) → throw ServiceChainExhaustedException
```

`ServiceResult<T>` carries `data`, `source` (`ServiceSource` enum), `fetchedAt`,
`isStale`, `errors[]`. Adding a new source means: conform to the abstract interface
(`StationService`, `GeocodingProvider`, …), register it in the country/service registry,
and create the Dio via `DioFactory.create(rateLimit: RateLimitConfig(...))`. Caching,
coalescing, retries and result wrapping come for free — never reimplement them.

### Caching

- **Banned**: direct `HiveStorage.cacheData()` for API responses — use `CacheManager`.
- TTLs are constants in `CacheTtl`; never invent an inline TTL.
- Key shape: `type:country:rounded-coords:radius:fuel:postal` — coordinates rounded to
  3 decimals for search (~110 m) or 4 for geocoding (~11 m).
- `CacheManager.evictExpired()` runs on a 30-minute `Timer.periodic` and only walks
  entries older than **3 × ttl**, so stale-fallback stays available.

### Storage

Hive boxes (`lib/core/storage/hive_boxes.dart`): `settings`, `favorites`, `cache`,
`profiles`, `price_history`, `alerts`, `obd2_baselines`, `obd2_trip_history`,
`achievements`, `obd2_supported_pids`, `obd2_negotiated_protocol`, `service_reminders`,
`obd2_paused_trips`, `obd2_active_trip`, `price_snapshots`, `isolate_error_spool`,
`traffic_signals_cache`, `feature_flags`, `app_profile`, `box_schema`
(`currentSchemaVersion = 2`), with an encrypted subset and a deferred-open subset.

- Hive returns `Map<dynamic, dynamic>`; always pass through
  `HiveBoxes.toStringDynamicMap()` before a freezed `fromJson`.
- Storage keys live in `StorageKeys` — a pinning test enforces uniqueness + snake_case.
- API keys, Supabase URL/anon key → **secure storage only**, never plain Hive, never
  logged.
- Background tasks run in a separate isolate: `HiveStorage.initInIsolate()` plus a
  file-based `HiveIsolateLock` prevents concurrent main-isolate access.
- **One accessor per stored value (#3592).** If a value has a dedicated accessor adding
  semantics (secure vault read, shipped default, caching — e.g.
  `ApiKeyStorage.getEvApiKey()`), *every* reader must use it. A generic
  `getSetting(StorageKeys.x)` read of that same value is a bug that compiles and
  "works": #3592 had the map provider reading the plain settings box (always null —
  the key lives in the vault) and silently serving demo stations for months.

### Riverpod conventions

- `@riverpod` (auto-dispose) for screen-scoped state;
  `@Riverpod(keepAlive: true)` only for genuine app-lifetime state (storage, profiles,
  active country/language, favorites, OBD2 connection).
- `ref.watch` in `build()`, `ref.read` in event handlers, `ref.listen` for
  snackbars/navigation. **Never mix watch and read in one expression.**
- After `await` in widget code: `if (!context.mounted) return;` (lint = error).
- Tests override with `ProviderScope(overrides: [...])`, always starting from
  `standardTestOverrides` in `test/helpers/mock_providers.dart`.
- **Cross-provider reads inside catch-all providers fail silent-empty.** Many
  radar/approach providers end in `on Object { return const []; }` — a new
  `ref.read(...)` inside one throws in any unmocked test container and the catch-all
  turns it into `[]`. Wrap new cross-reads in their own try/catch with a safe default.
- **A `Consumer` added inside a widely-reused widget breaks any test that pumps it
  without a `ProviderScope`.** Grep the widget's tests for raw `pumpWidget` first.

---

## 5. Core subsystems in depth

### OBD2 / trip recording

- `lib/features/obd2/` — `data/adapters/`, `data/oem_pid_tables/`,
  `data/can_frame_decoders/`, `domain/services/`, `providers/`, `presentation/`.
- Transport: BLE (`flutter_blue_plus`) **and** Classic RFCOMM; adapter registry in
  `docs/guides/obd2-adapters.md`.
- The link layer was rewritten under **Epic #3527** — read
  `docs/guides/obd2-link-rewrite-validation.md` before touching connection code.
  Historic traps: two competing reconnect authorities fighting over one adapter
  (fixed with an `Obd2RecordingLinkOwnership` latch); Classic RFCOMM re-open hanging
  80–120 s because the adapter's single SPP channel is still held post-drop (7 s
  watchdog); a PARK/REUSE state trap where the coordinator stranded on a dead session.
- **A stream that swallows errors makes `onError`/`onDone` dead code.** Several device
  streams (e.g. `Obd2SpeedStream`) emit `null` on failure by design and never error or
  close — liveness checks on them must be in-band (per-tick), not callback-based.
- Known god-classes / conflict magnets: `trip_recording_controller.dart` (1400+ lines),
  `trip_recording_provider.dart`, `trip_recording_screen.dart` — serialise work on
  them, never parallelise (decomposition tracked by #2187/#2188/#2190).

### Approach detection & polling (ADR 0011)

Speed-aware polling scheduler that detects when the driver enters a station's radius and
flips the driving-mode PiP overlay to the large-price layout.

### Consumption estimation

- ADR 0010 — GPS driving-style **calibration matrix** mapping a GPS feature set to
  estimated L/100 km, refined after each fill-up.
- ADR 0012 — GPS-only live consumption estimator.
- ADR 0014 → **superseded by** ADR 0015 — per-fuel efficiency comparison using
  pure-vs-mix **composition buckets** rather than a dominant-fuel collapse.

### OCR

- The 7-segment pump-display scanner (#1868/#3397) was **removed** in #3765 —
  it never read reliably in the field. Receipt OCR is the remaining camera path.
- Receipt OCR also accepts shared PDFs, rasterised on-device by `pdfx`
  (`android.graphics.pdf.PdfRenderer` / `CGPDFPage` — **not** Pdfium, so the F-Droid
  GMS audit stays clean).
- Config assets: `assets/ocr_config/index.json`, `assets/receipt_overrides/index.json`.

### Maps (ADR 0013)

Tiles are served through a **Supabase OSM caching proxy** edge function; camera uses
`initialCameraFit`; markers render `bestDisplayPrice`.

---

## 6. Data sources — the 17 countries

Each country implements `StationService` in `lib/features/station_services/<country>/`.
Adding a country is **one new file** plus **two appends** (a `CountryServiceEntry` in
the registry and a `ServiceSource` enum value) — see `docs/guides/NEW_COUNTRY.md`
(and its guard test `test/docs/new_country_guide_test.dart`).

| Country | Provider (`ServiceSource.displayName`) | Cadence / notes |
|---|---|---|
| Germany | Tankerkönig API (CC BY 4.0) | ~5 min — **free API key required** |
| France | Prix-Carburants (gouv.fr), Licence Ouverte 2.0 | ~10 min (flux instantané) |
| Austria | E-Control Spritpreisrechner (CC BY 3.0 AT) | hourly |
| Spain | Geoportal Gasolineras (MITECO) | daily bulk, filtered locally |
| Italy | Osservaprezzi (MIMIT/MISE), IODL 2.0 | daily bulk |
| Denmark | Danish Fuel APIs (OK / Shell / Q8 aggregate) | every few hours |
| Portugal | DGEG (preçoscombustíveis) | daily |
| Luxembourg | gouvernement.lu (CC0 1.0) | daily (regulated prices) |
| Slovenia | goriva.si | |
| United Kingdom | CMA Fuel Finder (OGL v3.0) | twice-daily bulk |
| Argentina | Energía Argentina (Secretaría de Energía) | daily bulk |
| Australia | FuelCheck NSW | |
| Mexico | CRE México | |
| South Korea | OPINET / KNOC (KOGL Type 1) | ~30 min |
| Chile | CNE Bencina en Línea | |
| Greece | Paratiritirio Timon | restored (#3539) via the emvouvakis mirror — one ranged call, REGION codes as apiName; fragile, a durable self-published Pages pipeline is planned (#3549) |
| Romania | Monitorul Prețurilor | |

Non-station sources in the same enum: `osrmRouting`, `openChargeMapApi`,
`nominatimGeocoding`, `nativeGeocoding`, `gpsLocation`, `cache`.

**API keys** are entered by the user (or use a shared community default) and stored in
the OS keystore/keychain via `flutter_secure_storage`. They are never embedded in
source and never leave the device.

A **weekly endpoint canary** (`.github/workflows/endpoint-canary.yml`, `tool/endpoint_canary.dart`)
live-probes every country endpoint and tracks outages in a single rolling issue, so a
silent endpoint death surfaces in days, not months.

---

## 7. Localisation (23 locales)

**Locales shipped**: `bg cs da de el en es et fi fr hr hu it lt lv nb nl pl pt ro sk sl sv`
plus the `en_XA` **text-expansion pseudo-locale** (#1699). `app_en.arb` is canonical and
currently holds ~4 769 keys.

### The fragment pipeline

New strings go into `lib/l10n/_fragments/<feature>_<locale>.arb` (220 fragment files) —
**never** directly into the aggregated `app_*.arb`. Then, always:

```bash
dart run tool/build_arb.dart    # merge fragments → app_<locale>.arb (+ autofill_locales.dart)
dart tool/gen_pseudo_arb.dart   # regenerate the en_XA pseudo-locale
flutter gen-l10n                # regenerate lib/l10n/app_localizations*.dart
git add -- lib/l10n/            # commit the full fan-out
```

- `nullable-getter: false` in `l10n.yaml` — `AppLocalizations.of(context)` is
  non-nullable, so the `l10n?.key ?? 'English fallback'` blind spot is impossible
  (#3162). Contexts without delegates (background isolates, TTS, notifications) use
  `lookupAppLocalizations(locale)`.
- **French is hand-maintained** directly in `lib/l10n/app_fr.arb`; the other 20 locales
  are machine-filled to 100 % by `tool/autofill_locales.dart` (#2335). Only the core
  French-reachable surfaces demand a real French string — declared one prefix per line
  in `test/l10n/french_required_prefixes.dart`.
- Plurals use ICU with `int` placeholders; numbers/dates/currency go through
  `UnitFormatter` + `intl`, never raw Dart formatting.
- MT strings are acceptable for non-critical text, marked
  `@@description: "MT — needs native review"`.
- **Parallel ARB PRs always conflict.** Keep at most **one** ARB-touching PR in flight.
  Deterministic resolution recipe: `git checkout --theirs` the conflicted generated
  `app_*.arb`, re-run the three pipeline steps (the `_fragments/` hold both sides'
  keys so the pipeline produces a clean union), `git add lib/l10n/`, commit, push.

Enforcement: `test/l10n/localization_completeness_test.dart`,
`test/i18n/arb_key_parity_test.dart`, `test/l10n/text_expansion_test.dart`,
`test/lint/arb_fragments_consistency_test.dart`, plus the CI `l10n-gate` job.

---

## 8. TankSync — the optional cloud backend

Opt-in, free, **self-hostable** cross-device sync on Supabase.

- Client code: `lib/core/sync/` — per-entity sync modules (`favorites_sync`,
  `alerts_sync`, `trips_sync`, `fill_ups_sync`, `vehicles_sync`, `itineraries_sync`,
  `baselines_sync`, `price_history_sync`, `ratings_sync`, `trip_shares_sync`,
  `ignored_stations_sync`, `deletions_sync`), plus `sync_pull_coordinator`,
  `pending_deletions_journal`, `sync_isolate_decode`, `sync_run_trace`,
  `schema_verifier`, `schema_sql` (the wizard SQL) and `tanksync_init`.
- Server: `supabase/migrations/` (source of truth, ~20 migrations),
  `supabase/functions/` — `check-alerts`, `record-prices`, `validate-report`,
  `aggregate-wait-times`, `tiles` (the OSM caching proxy), plus `pg_cron` schedules.
- Identity: anonymous-per-device UUID; the anon → permanent email upgrade must
  **keep the same UUID** (never `signUp`) — #3079; QR device-pairing #3080.
- Known state (Epic #3075): TankSync was historically upload-only. Favorites/ignored
  now pull (#3076/#3082); trips, baselines and itineraries pull; fill_ups, vehicles and
  alerts still don't (#3077).

### HARD RULE #5 — local synced-schema changes must reach Supabase

Synced data persists locally *and*, when TankSync is on, to the user's **self-hosted**
project. Drift means silent per-table sync failures for self-hosters (#2929).

- Most synced entities store the whole model in a JSONB `data` column, so adding a
  **field** is transparent — no Supabase change needed.
- Adding a new **synced table** (a new `.from('<table>')` under `lib/core/sync`) or a
  new **explicit non-`data` column** requires updating `schema_verifier.dart`
  (`requiredTables` / `optionalTables`, `getMigrationSql()` — idempotent
  `CREATE TABLE IF NOT EXISTS`, RLS policies, any RPC) to match
  `supabase/migrations/`, and bumping `kSupabaseSchemaVersion`.
- Enforcement: `test/core/sync/schema_verifier_completeness_test.dart` plus
  `test/security/supabase_rls_test.dart` and `test/security/trip_sync_migration_test.dart`.

---

## 9. Privacy, security & compliance posture

- **No Firebase, no Google Play Services in the libre build, no Apple analytics SDKs,
  no third-party tracking, no ads** (ADR 0003).
- **GPS position and API keys never leave the device.** Location is sent to a fuel-price
  API only as an ephemeral search parameter.
- **Privacy Dashboard** — every stored row visible, one-tap JSON/CSV export, error-log
  dump, one-tap delete-all; server-side deletion via TankSync → Data Transparency.
- **Error reporting is consent-gated and user-driven**: the app composes a GitHub issue
  body and `launchUrl`s it. The app itself never uploads. Not captured: GPS, API keys,
  PII, profile name, Supabase anon key, raw price values.
- **Sentry** ships only on Play/iOS and is stripped from the F-Droid flavor
  (Tracking anti-feature, #3492).
- Play **Data Safety** answers live in `docs/play-store/DATA_SAFETY.md`
  (collects: approximate location — ephemeral, optional; an anonymous UUID if TankSync
  is on. Everything else: not collected).
- Privacy policy: <https://fdittgen-png.github.io/tankstellen/privacy-policy/>
  (built by `tools/build_privacy_policy.py`, guarded by `test/docs/privacy_policy_test.dart`).
- Security guard tests: `test/security/` — `no_hardcoded_secrets_test.dart`,
  `android_manifest_security_test.dart`, `no_plaintext_station_endpoints_test.dart`,
  `external_urls_reachable_test.dart`, `supabase_rls_test.dart`.
- CI runs a `security-scan`, a `license-audit` (`scripts/license_audit.sh`, **no GPL
  dependencies**) and a `dependency-check` job.

---

## 10. Coding best practices

### The five HARD RULES

Mirrored version-controlled in `docs/AGENT_RULES.md` (because `CLAUDE.md` is
gitignored by decision #296 / #2355).

**1. No hard-coded user-facing text.** Every string a user can see — `Text`, `Tooltip`,
`SnackBar`, `hintText`, `labelText`, `helperText`, `semanticLabel`, button labels,
dialog text, AppBar titles, user-facing error messages — comes from `AppLocalizations`.
Only exemptions: brand names/proper nouns, URLs, language-neutral format masks — each
with an inline `// i18n-ignore: <reason>`. Enforced by
`test/lint/no_hardcoded_ui_strings_test.dart`; its baseline may only ever **decrease**,
target 0 (legacy cleanup epic #1657).

**2. Never develop without an issue.** Every change traces to a GitHub issue.
Large / multi-PR / multi-subsystem work is an **Epic**: file the parent, get the
breakdown validated by the maintainer, then file children.

**3. Clean-codegen-before-push.** Regenerate **from clean**, never incrementally:
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
git add -- '*.g.dart' '*.freezed.dart'
```
An incremental build keeps stale hashes CI's clean run flags. Leaving any generated diff
uncommitted is a **defect** — it has reached CI 4+ times in a single session at ~13 min
per round-trip. Never "fix it in the next push". Don't `dart format` whole generated
files.

**4. Every new `en` ARB key must reach all 23 locales before push** — run the full
pipeline in §7 and commit the fan-out. Never raise a coverage baseline to make it pass.

**5. Local synced-schema changes must reach the Supabase/TankSync schema** — see §8.

Rules #3 and #4 are enforced **locally** by an installable pre-push hook —
`bash scripts/install_hooks.sh`, once per clone. Emergency bypass (you then own the CI
red) is `SKIP_PREPUSH=1 git push`.

### Analyzer configuration

`analysis_options.yaml` extends `package:flutter_lints`, activates **riverpod_lint 3.1.3
as a native analyzer plugin** (not `custom_lint` — unresolvable against analyzer ^9),
excludes `third_party/**`, and turns on strict language modes:

```yaml
language:
  strict-casts: true
  strict-inference: true
  strict-raw-types: true
```

Elevated to **error**: `prefer_const_constructors`, `use_build_context_synchronously`,
`unawaited_futures`, `discarded_futures`, `cancel_subscriptions`, `close_sinks`,
`avoid_slow_async_io`, `avoid_type_to_string`, `no_logic_in_create_state`,
`prefer_void_to_null`, `test_types_in_equals`, `throw_in_finally`,
`unnecessary_statements`, `unrelated_type_equality_checks`, `valid_regexps`.
CI runs `flutter analyze` **fatal on infos**, over `lib/` **and** `test/`.

Three riverpod_lint diagnostics are disabled with documented inventories
(`avoid_public_notifier_properties`, `only_use_keep_alive_inside_keep_alive`,
`scoped_providers_should_specify_dependencies`) because the 3.1.3 plugin does **not**
honour `// ignore:` comments — the unblock lever is a riverpod_lint bump, not
re-disabling more rules.

### Static lint tests (`test/lint/`) — repo-specific rules with no analyzer equivalent

| Test | Rule |
|---|---|
| `no_hardcoded_ui_strings_test.dart` | HARD RULE #1 |
| `no_silent_catch_test.dart` | no `catch (_) {}` |
| `catch_block_stacktrace_coverage_test.dart` | `catch_no_st` (#1103) — every `catch (e)` must be `catch (e, st)` with `st` logged, or carry `// ignore: catch_no_st` |
| `no_debugprint_only_catch_test.dart`, `no_raw_debugprint_error_test.dart` | errors go to the logger/trace recorder, not a bare `debugPrint` |
| `no_inline_border_radius_test.dart` | use `AppRadius` tokens |
| `no_inline_platform_check_test.dart` | ADR 0009 — no inline `Platform.isX` in shared code |
| `no_raw_appbar_in_features_test.dart`, `no_raw_card_in_features_test.dart`, `no_inline_title_theme_test.dart` | design-system components only |
| `no_string_literal_routes_test.dart` | typed route constants |
| `no_ref_after_await_test.dart` | Riverpod `ref` use after `await` |
| `presentation_data_imports_test.dart`, `feature_boundary_test.dart` | layering + feature boundaries |
| `file_length_test.dart` | size budgets with a grandfathered snapshot |
| `never_throws_contract_test.dart` | a "never throws" docstring (#2349/#1103) needs a sibling fault-injection test |
| `declared_dependencies_test.dart` | pubspec hygiene |
| `analysis_options_severity_test.dart` | the severity table above can't silently regress |
| `sync_error_layer_test.dart`, `sync_utc_timestamps_test.dart` | sync-layer invariants |
| `retry_tile_provider_call_site_test.dart`, `tab_switcher_canonical_test.dart` | pinned call sites |
| `design_system_doc_present_test.dart`, `asset_spec_coverage_test.dart` | docs/assets parity |

### Error handling & tracing

- Always pass the stack trace: `traceRecorder.record(e, st)`.
- For `ServiceChainExhaustedException` also pass `serviceChainState: chain.snapshot()`.
- `FlutterError.onError` and `PlatformDispatcher.instance.onError` route into
  `TraceRecorder` at app init.
- **Repeated identical failures get an episode gate, not a log entry each** (#3581) —
  one overnight Supabase outage must not flood the bounded error log and evict the
  traces you actually need. Count consecutive identical-signature errors in a window
  and stamp the count on the next distinct trace.
- Crash forensics: `PreviousProcessDeath` traces carry reason + stack + last
  breadcrumbs; export via the Privacy Dashboard error-log dump.

### The "don'ts"

No `print` (use `debugPrint`) · no `Dio()` per request · no `setState` for shared state ·
no `presentation → data` imports · no hardcoded strings · no `context` after `await`
without a `mounted` check · no `catch (_) {}` · no magic strings/numbers in business
logic (pin to a constants class with a pinning test) · no Google Play Services, no
Firebase, no third-party tracking, no GPL dependencies · **never adopt a paid
service/API/SDK** (standing product constraint — prefer free/open/on-device).

### Feature-enum cascade checklist

Adding a value to the `Feature` enum is a **fan-out**, all in one PR:

1. The enum value in `lib/features/feature_management/domain/feature.dart` with a
   dartdoc naming the gating issue and any `Requires [...]`. Values may be reordered
   but **never renamed** (persistence uses `Enum.name`).
2. A `FeatureManifestEntry` in `feature_manifest.dart` `defaultManifest` with
   per-`BuildChannel` defaults and `requires:` edges.
3. `case` arms in `feature_management_section.dart`: `_featureLabel`,
   `_featureDescription`, and — if it has prerequisites —
   `_blockedEnableMessage` / `_blockedDisableMessage` (exhaustive switches).
4. ARB keys `featureLabel_<name>` / `featureDescription_<name>`
   (+ `featureBlocked*_<name>`) in the `feature_management_{en,de}` fragments, French
   appended to `app_fr.arb`, then the full ARB pipeline.
5. Bump the hard-coded `Feature.values.length` literal in
   `test/features/profile/presentation/screens/profile_screen_feature_mgmt_test.dart`.
6. Clean codegen if it was wired into a freezed/`@riverpod` consumer.

Adding a `GoRoute` similarly bumps the exact-count guard in
`test/app/routes/profile_routes_test.dart`.

### Generated files are committed

`*.freezed.dart`, `*.g.dart`, `lib/l10n/app_localizations*.dart` are committed so
Dependabot PRs don't look broken on fresh clones. Hence HARD RULE #3.

---

## 11. Development best practices & workflow

### GitHub Flow

- Branch off `master`. Prefixes: `feat/`, `fix/`, `refactor/`, `test/`, `docs/`,
  `chore/`, `ci/`, `perf/`, `style/`.
- Conventional-commit subject: `type(scope): imperative subject under 72 chars, no
  trailing period`.
- One concern per branch, short-lived (1–3 days).
- **PRs under 400 lines** excluding generated files.
- Link the issue: `Closes #NN`.
- **Squash-merge only**; auto-delete head branches.
- **One commit per closed issue even inside a bundled PR** — the PR title summarises,
  the commit log preserves per-issue rationale forever.
- **Forbidden**: direct commits to `master`, force-push to `master`, `--no-verify`,
  `--amend` on pushed commits, interactive rebase in CI/scripts.
- Before every commit: `flutter analyze` + the relevant `flutter test`.

### Issue-first & Epics

- File the issue before writing code (HARD RULE #2).
- Epic shape needs maintainer validation **before** children are filed. Helper skills:
  `epic-triage` (Task-vs-Epic signal count + dependency-ordered breakdown) then
  `epic-scaffolder` (files the parent + children behind the validation gate).
- Close epics **after** child PRs merge, never while they're in flight.
- GitHub Project #2 board: 5 iteration milestones as the roadmap + a kanban Status
  model. Every new issue gets project + milestone + status.

### Bug-fix protocol (not optional)

1. Grep the UI to find the **exact** method the failing widget calls.
2. Write a failing test calling **that exact method** — it must fail for the same reason
   the app fails.
3. If it passes immediately you're testing the wrong thing — re-read the UI.
4. Implement the fix; make the test pass.
5. Run the full suite (no regressions).
6. **Only then** build an APK. Never build before the test proves the fix.
7. Grep all callers of any changed function/getter before asserting new behaviour.
8. **Twin-bug audit** — grep for the *pattern*, not just the file: same exception type
   leaking into the UI, the same paired call site, twin screens sharing a widget, a
   second error surface in the same method. Fix every occurrence in the one PR.
   *(Four of six closed follow-up chains were "same bug, second location": #1186 →
   #1234, #1370 → #1392.)*

**Producer + consumer ship together.** Never merge the reader half of a feature without
the writer (#1430 shipped a fuel-level badge no producer ever populated — dark in
production until #1434).

**If a fix adds an affordance, a test must tap it** (#1303 shipped a recovery banner
whose buttons were silent no-ops).

**Regression escalation — stop patching after the second recurrence.** If a bug has been
"fixed" before and came back, do not ship fix N+1: isolate the real root cause and ask
whether there are actually *two* failure modes that look identical on screen. The map
grey-tile bug was "fixed" nine times (#473 → #1316) because cause #2 was never isolated.
See the `recurring-bug-protocol` skill. Verify against `origin/master`, not a stale
working-tree branch.

### Verification discipline

- **"Data missing" reports → verify against the AUTHORITATIVE upstream source**, never
  your own parser's classification. A FR station was reported hours-less because the
  adapter dropped `01:00-01:00` as "degenerate"; the official site showed it as the
  24 h convention (#3308). The false-green test was part of the bug.
- **Fakes that echo the request give false-green tests.** A fake service returning the
  requested fuel grade hid a cross-border bug three times. For data-shape/availability
  bugs, drive the **real** service with a **recorded real-API fixture** and prove the
  test is RED on master before the fix.
- **Silent fallbacks need a visible tell.** A demo/degraded dataset that renders
  indistinguishably from live data hides outages *and* bugs. Give every fallback a
  recognisable signature, `debugPrint` the downgrade, and document the tell.
- **Writing user docs is a verification pass** — fact-check every claim against the
  code as you write it. Never document behaviour from memory.
- **UI must tell the truth about persistence** (#3582). If data is already saved when a
  sheet appears, the sheet must not offer a "Discard" that silently keeps it.
- **"Still doesn't work" usually means a stale Open-Testing build** (Play beta lag) —
  check the About version first, sideload a local profile APK from master to verify.

### Efficiency / batching doctrine

- **Bundle**: regroup as many issues as possible into one PR (even cross-epic when
  disjoint), then test-and-fix until green. Always bundle PRs touching the same
  CI workflow file or the same ARB fan-out.
- **Serialize auto-merges** — strict-mode is off and there is no merge queue, so each
  merge bumps the rest to BEHIND; open PR N+1 only after N merges to avoid O(N²) CI
  churn. Never auto-merge a stacked PR whose base is a feature branch.
- **Never commit on master**; `git fetch --prune` first; disarm `--auto` during Actions
  outages.
- **No optimisation may break start→merge autonomy** — nothing that adds a step needing
  a human, or that breaks `gh pr merge --auto`.
- **Decomposing a file? Don't carry cross-feature imports into the new helper** — pass
  primitives (`bool byPrice`, not `SortMode`); `feature_boundary_test` counts per-file
  and fails the push on a raised pair.
- **Async display enrichment must not re-sort a visible list** as answers trickle in.
- **Inventory an existing backend's other endpoints before adding a new one** — "real
  road distances" needed zero new services: the OSRM instance already used for routing
  has a `/table` matrix endpoint.
- **Heuristic filters on safety-critical surfaces degrade to UNFILTERED, never to
  empty** — a low-fuel driver must never see zero stations because of a heuristic. Make
  the fallback explicit in the API (`result.filtered == false`).

### Parallel-agent orchestration (when running worktree agents)

- **File-disjoint → separate agents; same file → one agent.** Do a 30-second
  file-ownership check before launching a wave.
- Always pass `isolation: "worktree"` — otherwise agents switch the shared checkout's
  branch and collide.
- **Conflict magnets**: `lib/l10n/app_*.arb` + generated localisations, `*.g.dart` /
  `*.freezed.dart`, `.github/workflows/ci.yml`, the `file_length_test.dart` allow-list
  (resolve to the **combined post-merge** line count, not either branch's), and the
  `trip_recording_*` trio.
- Paste the lint guardrails into every implementation-agent prompt (`catch_no_st`,
  `no_inline_border_radius`, `no_silent_catch`, analyze **including** `test/`,
  no macOS-baselined goldens, route-count guard, clean codegen).
- In an agent worktree the pre-push hook can't run `build_runner clean` — run the gates
  by hand, confirm zero drift, then `SKIP_PREPUSH=1 git push`.

### Documentation

- **ADRs** in `docs/decisions/` (format guarded by `test/docs/adr_format_test.dart`).
- **Guides** in `docs/guides/` — new country, i18n fragments, OBD2 adapters, auto-record,
  iOS codesigning/build/release/TestFlight/widget/share extension, F-Droid submission,
  Play FGS declaration, store-listing refresh, go-live runbook, network tests,
  feature flags, opening hours, driving insights, backup schema.
- **CHANGELOG.md** — Keep-a-Changelog format with an `[Unreleased]` section
  discipline (#3177). The Play deploy workflow **refuses to ship a version with no
  `## [X.Y.Z]` entry**.

---

## 12. Testing strategy

### The pyramid

Target **70 % unit / 20 % widget / 10 % integration**. ~1 500 test files, ~15 k tests,
~25 min locally; CI shards across `test (0..3)`.

- **Fakes over mocks** for the service layer — a small in-file
  `_FakeStationService extends StationService` is canonical. `mocktail` only for
  widget-level callbacks (`verify(() => onTap()).called(1)`).
- Cache TTL tests always cover fresh hit / stale hit / miss.
- Service-chain tests always cover API success / API failure with stale / total failure.
- Accessibility: every interactive screen asserts `meetsGuideline(androidTapTargetGuideline)`.
- **Structural widget tests only — no macOS-baselined golden PNGs.** They fail Linux CI
  at 3–4 % against a 1.5 % tolerance and turn master red. Baseline on Linux or prefer
  structural assertions.

### Test tags (`dart_test.yaml`)

| Tag | Meaning |
|---|---|
| `network` | Hits real third-party APIs. Upstream timeouts can't block PRs — run on demand with `flutter test --tags=network`. |
| `flaky` | Observably flaked in CI without a code change (usually platform-plugin channel timing). |

PR and master runs use `--exclude-tags=network,flaky`; the nightly workflows re-run both
so genuine regressions surface within a day.

### Test directory map

```
test/
├── a11y/  accessibility/          # tap targets, semantics
├── app/                           # router, shell, startup
├── ci/ci_workflow_test.dart       # the CI YAML itself is unit-tested
├── core/  features/               # the bulk
├── docs/                          # ADR format, NEW_COUNTRY guide, privacy policy
├── fakes/  mocks/  helpers/  fixtures/   # standardTestOverrides, recorded API fixtures
├── goldens/  widget_test.dart
├── i18n/  l10n/                   # key parity, completeness, expansion, autofill
├── integration/
├── lint/                          # the repo-specific static rules (table in §10)
├── scripts/                       # bash tests for the shell scripts
└── security/
integration_test/                  # app_test, fresh_install_wizard, golden_flow, appstore_screenshots
```

### Coverage & performance gates

- **Coverage**: `scripts/check_coverage.sh` parses `lcov.info` and excludes generated
  files. CI passes **no** `--threshold`, so the effective gate is the script default
  of **40 %** — and it runs only on pushes to `master`, never on a pull request.
  See [§22-A](#22-known-gaps-and-stale-documentation).
- **Startup budget**: `scripts/check_startup_budget.sh`, **2000 ms**.
- **Module boundaries**: `scripts/check_module_boundaries.sh` +
  `scripts/module_boundary_allowlist.txt`.

---

## 13. CI on GitHub — the workflow topology

20 workflows in `.github/workflows/`. Runners are `ubuntu-latest` except iOS
(`macos-15`, deliberately pinned off `macos-latest`) and the App Store listing
(`macos-latest`). Flutter is pinned to **3.41.9** everywhere.

### `ci.yml` — the main pipeline

**Triggers**: push to `master` and `v*` tags, PRs to `master`, a weekly Sunday 06:00
cron, and `workflow_dispatch` (a manual hatch with a `reason` input, #2128).
`paths-ignore` skips `**/*.md`, `docs/**`, `LICENSE`, `.gitignore`,
`ios/fastlane/**` and `fastlane/metadata/**`.
Concurrency: `${{ workflow }}-${{ ref }}` with `cancel-in-progress: true`.

| Job | Purpose |
|---|---|
| `green-gate` | **#2417 green-tree skip.** `record-green` saves an `actions/cache` marker keyed on a hash of the build-relevant source tree after a full green pass; `green-gate` probes it with `lookup-only`. On a HIT (rebase, base retarget, empty-commit re-fire) every gated leaf job skips. |
| `changes` | Path filter producing `code` / `deps` outputs |
| `analyze` | `flutter analyze` — **fatal on infos**, over `lib/` and `test/` |
| `codegen-drift` | Clean `build_runner` run; fails on any generated diff (HARD RULE #3) |
| `l10n-gate` | Full ARB pipeline + locale-coverage assertions (HARD RULE #4) |
| `test (0..3)` | 4-way sharded suite, `fail-fast: false`, `--exclude-tags=network,flaky` |
| `coverage-merge` | Non-PR only; merges shard lcov and applies the coverage gate |
| `startup-budget` | 2000 ms cold-start budget |
| `integration` | `integration_test/` |
| `security-scan` / `license-audit` / `dependency-check` | Gated on `changes.deps` or non-PR |
| `build-android` | Play-flavor AAB/APK build |
| `release` | Tag-triggered (`refs/tags/v*`) GitHub release from `build-android` artifacts |
| `record-green` | Writes the green-tree cache marker when every gate passed |

**Caching**: `~/.pub-cache` + `.dart_tool` keyed on `pubspec.lock`; `build/` keyed on
`pubspec.lock` + `lib/**/*.dart`; Gradle caches keyed on `android/**/*.gradle*`.
Shards check out with `fetch-depth: 0` because the test selector needs
`git diff master...HEAD` (#1594). `build_runner` is **not** run in the test job —
generated files are committed (#1730).

> **Matrix-skip trap (#2417, and a standing rule).** A **matrix** job must never be
> skipped at *job* level: a skipped matrix never expands, so the required
> `test (0..3)` contexts are never reported and branch protection blocks the PR
> forever — auto-merge can never fire. The matrix job therefore always runs and each
> heavy *step* is gated on the green-gate cache. Single-context leaf jobs keep the
> cheaper job-level skip, whose `skipped` conclusion counts as a pass.

### `ci-docs-stub.yml` — required-context mirror

Named `CI` as well, triggered on exactly the paths `ci.yml` ignores. It re-emits every
required context (`analyze`, `test`, `coverage-merge`, `codegen-drift`, `l10n-gate`,
`build-android`, `integration`, `startup-budget`) as trivial jobs so a docs- or
store-metadata-only PR can still satisfy branch protection and auto-merge (#2568).

### Release / distribution workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `deploy.yml` — *Deploy to Play Store* | `v*` tags; dispatch (`deploy-internal` / `promote-rollout`) | Validates the CHANGELOG entry, waits for CI's AAB, uploads to **internal**, then promotes to production at a chosen staged-rollout percentage (1/5/10/25/50/100) from `beta` (default), `alpha` or `internal`. Concurrency group `play-store-deploy`, `cancel-in-progress: false`. |
| `daily-beta.yml` — *Daily Open-Testing Build* | 16:00 Europe/Paris cron + dispatch | Builds `--flavor play` AAB with a **monotonic run-counter build number** and uploads to the **beta (open testing)** track; tags the commit so every shipped versionCode maps back to a commit (#3177). |
| `daily-github-release.yml` | 21:00 cron + dispatch | `pre-check` → `build-android` + `build-ios` (macOS) → `release` (or `skipped-summary`). |
| `ios-testflight.yml` | 04:30 cron + dispatch | macOS-15 build + TestFlight upload; `distribute` input pushes to the external `extern` group; `sync_certs` repair mode runs write-mode match. |
| `ios-beta-review.yml` | dispatch | Pushes localised Beta App Review test info ahead of a build (#2611). |
| `ios-testers.yml` | dispatch | Adds external TestFlight testers idempotently. |
| `app-store-listing.yml` | dispatch (macOS) | `fastlane deliver` for App Store text metadata only — no binary. |
| `play-store-listing.yml` | dispatch + push to listing paths | `fastlane supply` metadata-only upload of the public Play listing. |
| `play-status.yml` | dispatch | Read-only Play track status. |
| `fdroid.yml` — *F-Droid no-GMS audit* | every PR + push to master | **Advisory, deliberately not a required check.** Builds the keyless-unsigned fdroid **release** APK and runs the 3-layer GMS/MLKit/Play-Core/Sentry audit. |
| `fdroid-publish.yml` | `v*` tags + dispatch | Builds + signs the fdroid APK, regenerates the `fdroidserver` index, assembles the combined Pages site and deploys it. Shares the `pages` concurrency group. |
| `pages.yml` | push to landing/privacy/fdroid-repo paths + dispatch | Deploys the combined Pages site (landing at root, `/privacy-policy/`, `/fdroid`). |
| `dev-apk.yml` | dispatch | arm64 dev APK for sideload verification. |

### Quality / maintenance workflows

| Workflow | Schedule | Purpose |
|---|---|---|
| `nightly-full.yml` | 04:00 | Full test suite, nothing excluded |
| `nightly-flaky.yml` | 05:00 | Re-runs the `flaky` + `network` tagged suites |
| `endpoint-canary.yml` | Mondays 05:23 | Live-probes every country endpoint, tracks outages in one rolling issue |
| `gr-fuel-publish.yml` | daily 11:00 | Publishes the Greek fuel-price dataset |
| `epic-backpatch.yml` | on `issues` events | Back-patches Epic checklists when children change |

> Crons are deliberately staggered (04:00, 04:30, 05:00, 05:23, 11:00, 16:00, 21:00) so
> no two heavy jobs collide.

---

## 14. GitHub repository configuration

- **Repo**: `fdittgen-png/tankstellen`, default branch `master`.
- **CODEOWNERS**: `* @fdittgen-png`.
- **Branch protection** is codified in `scripts/configure_branch_protection.sh`
  (`--verify` reports drift, PATCH is idempotent) — the source of truth since #2343.
  - `strict: false` (deliberately — strict mode caused O(N²) BEHIND-churn).
  - **Required checks**: `analyze`, `test (0)`, `test (1)`, `test (2)`, `test (3)`,
    `codegen-drift`, `build-android`, `integration`, `startup-budget`, `l10n-gate`.
  - `coverage-merge` must **not** appear (phantom context, #2338). `build-fdroid` is
    deliberately excluded — a transient Gradle failure must never block auto-merge.
- **Merge policy**: squash-merge only, auto-delete head branches, `gh pr merge --auto`
  is the normal path.
- **Issue templates** (`.github/ISSUE_TEMPLATE/`): `bug_report.yml`,
  `feature_request.yml`, `new_country.yml`, `documentation.yml`, `epic.yml`, `config.yml`.
- **PR template** with What / Why / Type / How / Testing / Checklist / Screenshots /
  Breaking-changes sections — the checklist pins `flutter analyze` zero-warning,
  `flutter test`, ARB strings, no secrets, and the < 400-line rule.
- **`release.yml`** — release-notes categorisation config.
- **`FUNDING.yml`** — sponsorship links (donation links are hidden on iOS by
  `donationLinksVisibleProvider` for App Store guideline 3.1.1 compliance).
- **Dependabot** (`.github/dependabot.yml`): weekly Monday `pub` updates grouped as
  `minor-and-patch`, limit 5 open PRs, with the ignore list in §3; plus weekly
  `github-actions` updates grouped as `actions`.
  - Triaging a red Dependabot PR: don't close it — check the riverpod/analyzer
    lockstep cluster first, and remember `pubspec.fdroid.lock` needs a **manual
    regeneration** or the F-Droid audit goes red on every deps PR.
- **Project #2 board** — 5 iteration milestones as the roadmap plus a kanban Status
  model; every new issue gets project + milestone + status.
- **Wiki** — user-facing docs (`User-en-Getting-Started`, etc.).

---

## 15. Google Play distribution

| | |
|---|---|
| Package | `de.tankstellen.fuelprices` |
| Listing | <https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices> |
| Flavor | `play` (GMS available) |
| Tracks | internal → alpha → **beta (open testing)** → production |
| Signing | Play App Signing; upload key resolved from `ANDROID_KEYSTORE_*` env vars (CI secrets) or a legacy local `android/key.properties` |

### Build configuration (`android/app/build.gradle.kts`)

- Java/Kotlin **17**, core-library desugaring on, `buildConfig = true`.
- Release build type: `isMinifyEnabled = true`, `isShrinkResources = true`,
  `proguard-android-optimize.txt` + `proguard-rules.pro`.
- **Release builds never fall back to the debug signing key (#48).** If no release
  signing config resolves and a release task is requested, the build throws — with one
  sanctioned exception: an **fdroid-only** release, which is intentionally unsigned
  because F-Droid signs downstream (#3471). The throw is deferred to actual release
  tasks so Dependabot's `assemblePlayDebug` (which can't read secrets) still configures.
- **Flavors** (`distribution` dimension): `play` and `fdroid`.
- **Per-ABI versionCode**: `base*10 + {1,2,3}` — **gated to the fdroid flavor only**,
  because Play split builds carry the shared wall-clock code (~2.03e9) and `*10` would
  overflow Android's int32 cap (#3513/#3518).
- **Foreground-service gating (#3173).** The app currently ships with **zero**
  `FOREGROUND_SERVICE*` permissions so `edits.commit` never 403s on the pending Play
  "Foreground Service Use" form (#1498). One flag flips both halves in lockstep:
  `--dart-define=FGS_FORM_APPROVED=true` turns on
  `kGpsRecordingForegroundServiceEnabled` in Dart *and* swaps the flavor manifest to the
  `*FgsApproved` overlay in Gradle. `scripts/audit_no_fgs.sh` guards the default shape;
  the repo variable `vars.FGS_FORM_APPROVED` flips it in `daily-beta.yml` once approved.
  See `docs/guides/play-fgs-declaration.md`.

### Deployment path

1. Tag `vX.Y.Z` → `ci.yml` builds the AAB → `deploy.yml` verifies the CHANGELOG entry,
   waits for the artifact, uploads to **internal**.
2. Or the **daily 16:00** `daily-beta.yml` build goes straight to **beta**.
3. Promote with `deploy.yml` → `promote-rollout` (source track defaults to `beta`,
   because `internal` is rarely updated and defaulting to it silently promotes a stale,
   lower-versionCode build — #3407).
4. `scripts/promote_play_store.sh` / `tools/upload_to_play.py` drive the Play Developer
   API; `scripts/play_track_status.sh` reads current track state.

### Store listing

- Source: `fastlane/metadata/android/<locale>/` — `title.txt`,
  `short_description.txt`, `full_description.txt`, `changelogs/<versionCode>.txt`,
  `images/` (`icon.png`, **`featureGraphic.png`**, `phoneScreenshots/`).
- Locales: `en-US`, `de-DE`, `fr-FR`, `es-ES`, `it-IT`, `pt-PT`.
- Published by `play-store-listing.yml` (`fastlane supply`, metadata-only — no app
  rebuild needed).
- **`featureGraphic.png` must be camelCase and exactly 1024×500** — a snake_case
  filename is silently ignored.
- `sync_image_upload` **deletes remote images missing locally** — never publish a
  partial image set.
- **Beta release notes must contain no embedded double quotes** — the Play upload
  arg-splits, the build succeeds and the upload fails. Use single quotes.
- Data Safety answers: `docs/play-store/DATA_SAFETY.md`. Privacy-policy URL in the
  console must point at `/privacy-policy/` (manual field).

---

## 16. Apple App Store / TestFlight distribution

| | |
|---|---|
| Bundle IDs | `de.tankstellen.tankstellen` (app), `…​.TankstellenWidget` (WidgetKit) |
| Team ID | `C4Y5RDF8P9` |
| Apple Developer account | `fdittgen@gmx.de` (**not** the GitHub email) |
| App Store ID | `6766543414` |
| Status | Production listing live; nightly builds go to TestFlight `extern` |
| Targets in `ios/` | `Runner`, `RunnerTests`, `TankstellenWidget`, `ShareExtension` |

### Signing

- **fastlane match**, `storage_mode git`, repo
  `git@github.com:fdittgen-png/tankstellen-ios-certs.git` over **SSH** (a fine-grained
  PAT kept 403-ing). CI loads a read-only ed25519 deploy key (`MATCH_DEPLOY_KEY`) via
  `webfactory/ssh-agent`.
- `type("appstore")`, and **both** signed targets are listed in `app_identifier` — the
  archive fails with "No profile for …" otherwise.
- Both App IDs need the **App Groups** capability enabled in the Apple Developer Portal
  (`group.de.tankstellen.tankstellen`, the host↔widget `UserDefaults` bridge) so the
  regenerated profiles carry the `application-groups` entitlement. **App Groups have no
  App Store Connect API endpoint** — that step is portal-only and manual.
- `readonly(ENV["CI"] == "true")` — CI never mints certs; only a human on a trusted
  machine may touch the portal and the encrypted match repo.
- On CI, `setup_ci` creates and unlocks a temporary keychain **before** any signing
  action; without it match installs into the locked login keychain and `codesign`
  hangs on a UI prompt until the job times out.

### fastlane lanes (`ios/fastlane/Fastfile`)

`match_dev` · `match_appstore` · `match_bootstrap` (workstation-only) ·
`match_sync_appstore` (CI-safe repair for missing profiles) · `build_appstore` ·
`upload_testflight` (`distribute_external:true` → the `extern` group, which submits for
Beta App Review) · `release_testflight` (end-to-end) · `manage_testers` (idempotent) ·
`configure_beta_review` (pushes localised Beta App Review info ahead of a build) ·
`upload_metadata` (workstation-only, never auto-submits).

Auth is an **App Store Connect API key** (`APP_STORE_CONNECT_API_KEY_BASE64` /
`_KEY_ID` / `_ISSUER_ID`) shared by every lane.

### App Store listing

- Source: `ios/fastlane/metadata/<locale>/` — `name.txt` (≤30), `subtitle.txt` (≤30,
  indexed for search), `keywords.txt` (≤100 chars total, comma-separated, **no spaces
  after commas**), `description.txt` (≤4000), `promotional_text.txt` (≤170, editable
  without review), `release_notes.txt`; plus `copyright.txt` and
  `primary_category.txt`.
- Locales: `en-US`, `de-DE`, `fr-FR`, `es-ES`, **`it`** — note App Store Connect's
  Italian locale code is `it`, **not** `it-IT`; using `it-IT` rejects the localisation
  with *"The 'locale' value is invalid"* (#2611).
- Published by `app-store-listing.yml` (`fastlane deliver`, text only, never auto-submit).

### App Store review compliance playbook (2026-07-09, PR #3538)

Learned from a 5.1.1 / 3.1.1 / 2.1 rejection:

- **5.1.1** — pre-permission explainer screens must be **Continue-only** and must always
  proceed; no gating the app behind a permission.
- **3.1.1** — **no non-IAP donation links on iOS**; `donationLinksVisibleProvider` hides
  them.
- **2.1** — Apple requires a **demo video recorded on a physical device** showing the
  background-location and Bluetooth/OBD2 flows *including every permission prompt*,
  **with every submission**. The unlisted link lives in the `DEMO_VIDEO_URL` secret and
  is appended automatically to the Beta Review notes; when unset the base notes ship
  alone rather than failing the lane.
- The App-Review contact block requires `BETA_CONTACT_PHONE` (mandatory, never
  fabricated) — the lane returns `nil` and skips rather than inventing one.

### iOS-specific notes

- iOS OCR is 100 % **Apple Vision**; the ML Kit pods are stripped from the IPA via the
  vendored `third_party/` forks (#3172).
- `remove_alpha_ios: true` + `background_color_ios: "#2E7D32"` in
  `flutter_launcher_icons` — Apple rejects icons with an alpha channel.
- iOS background-wake for auto-record is still open (#1542).
- Guides: `docs/guides/ios-codesigning.md`, `ios-build-and-release.md`,
  `ios-testflight-testers.md`, `ios-widget-extension.md`, `ios-share-extension.md`,
  `ios-auto-record.md`.

---

## 17. F-Droid distribution (two channels)

### Channel A — the self-hosted repo (live today)

`https://fdittgen-png.github.io/tankstellen/fdroid/repo`

- Config: `fdroid/config.yml` (`repo_name: Sparkilo`, key alias
  `sparkilo-fdroid-repo`). **Secrets are never inlined** — passwords come from the
  environment via fdroidserver's `{env: VAR}` indirection; the keystore file
  (`fdroid/keystore.p12`) is git-ignored.
- Built + signed + indexed + deployed by `fdroid-publish.yml` on a `v*` tag.
- The repo signing key is **separate** from the app signing key.
- Single-version repo — no `/archive` split.

### Channel B — the official fdroiddata catalog

- Recipe: `metadata/de.tankstellen.fuelprices.yml` (mirrored at
  `fdroid/metadata/...`), submitted as fdroiddata **MR !42093** (`add-sparkilo`).
- **Reproducible build**: F-Droid's buildserver checks out the tagged commit and builds
  the `fdroid` flavor itself. Three per-ABI builds (`armeabi-v7a` / `arm64-v8a` /
  `x86_64`) with `versionCode = base*10 + ABI`, `VercodeOperation: '%c * 10 + 1'`,
  `AutoUpdateMode: Version`, `UpdateCheckMode: Tags ^v[0-9.]+$`.
- Prebuild steps pin the Flutter version by parsing it out of `.github/workflows/fdroid.yml`,
  swap in `pubspec_overrides.fdroid.yaml` + `pubspec.fdroid.lock`, `pub get
  --enforce-lockfile`, then `build_runner build`.
- `scanignore` covers the two vendored ML Kit forks; `scandelete` drops `.pub-cache`.
- Build flags: `--flavor fdroid --split-per-abi --target-platform <abi>
  --dart-define=FORCE_LOCATION_MANAGER=true --dart-define=FGS_FORM_APPROVED=true`.
- Guide: `docs/guides/fdroid-submission.md`.

### Making the build libre

Four proprietary sources had to go:

| Source | Pulled in | Replacement |
|---|---|---|
| `geolocator_android` | `com.google.android.gms:play-services-location` | Android `LocationManager` (`GeolocatorWrapper.forceLocationManager`, `BuildConfig.FORCE_LOCATION_MANAGER`) |
| `google_mlkit_text_recognition` | `com.google.mlkit`, `play-services-base/basement` | Absent — `ReceiptScanService` catches `MissingPluginException` and degrades |
| `in_app_review` (#3069) | `com.google.android.play:review` (Play Core) | Absent — `InAppReviewService` swallows `NoClassDefFoundError` and no-ops |
| `mobile_scanner` | ML Kit barcode backend | **`flutter_zxing`** (FFI to libzxing) selected when `AppFlavor.isLibre`; `mobile_scanner` is swapped for a no-op stub (#3477) |
| `sentry_flutter` | `io.sentry` (Tracking anti-feature) | Compiled out entirely (#3492) |

Mechanics:
- Gradle `exclude(group = …)` for `com.google.android.gms`, `com.google.mlkit`,
  `com.google.android.play` on `fdroidImplementation` and each fdroid runtime classpath.
- `proguard-rules-fdroid.pro` supplies `-dontwarn` rules (the real classes are absent,
  so R8 would otherwise abort with "Missing class …").
- `tool/apply_fdroid_overrides.dart` swaps GMS-tied plugins for the Dart-only stubs in
  `tool/fdroid_stubs/` **before** dependency resolution, and swaps in
  `pubspec.fdroid.lock` — the audit and the catalog build then run against the real
  libre graph.

### The 3-layer no-GMS audit (`scripts/audit_no_gms.sh`)

| Layer | What it proves |
|---|---|
| **A — dependency graph** (always) | The fdroid release runtime classpath contains no `com.google.android.gms`, `com.google.mlkit`, `com.google.android.play`, `io.sentry` coordinates. This is the authoritative gate and what the reproducible build inspects. |
| **B — bytecode definitions** (with an APK) | `dexdump` every `classesN.dex`; no such class is **defined**. Falls back to `strings`. |
| **C — strict reference gate** (release APK, #3480) | Even a **dangling type reference** fails — the exact bar F-Droid's `check apk` scanner applies, which rejected MR !42093 on references a debug-dex audit could not see. A release fdroid dex audits `gms:0 mlkit:0 play:0 sentry:0`. |

The audit must run on a **release** APK: only R8 strips Flutter's dead
`PlayStoreDeferredComponentManager` references (#3479), so a debug dex can never reach
the 0-reference bar. The build is keyless-unsigned, which is the sanctioned F-Droid
shape.

`scripts/audit_no_fgs.sh` is the sibling audit for the foreground-service permission
shape.

---

## 18. GitHub Pages site

One Pages site, three payloads, assembled by two workflows sharing the `pages`
concurrency group so they never race:

| Path | Content | Source |
|---|---|---|
| `/` | Marketing landing page | `docs/landing/index.html` + `docs/screenshots/` + the feature graphic |
| `/privacy-policy/` | Privacy policy | `docs/privacy-policy/` (built by `tools/build_privacy_policy.py`) |
| `/fdroid/repo` | Self-hosted F-Droid repo | `fdroid/repo/**` (committed index) |

> **Historic trap (#3071).** `pages.yml` does a full-replace deploy. Because
> `fdroid/repo` used not to be committed, a docs deploy wiped the live F-Droid repo.
> Fixed in #3072 by mirroring the live repo into the deploy payload; if it ever
> disappears again, restore with a `fdroid-publish` dispatch.

---

## 19. Secrets inventory

Repository Actions secrets referenced by the workflows:

| Secret | Used by |
|---|---|
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` | Android release signing (`ci.yml`, `daily-beta.yml`, `daily-github-release.yml`) |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Play Developer API uploads + promotion + status |
| `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID` | Every iOS lane (build, TestFlight, testers, beta review, deliver) |
| `MATCH_DEPLOY_KEY`, `MATCH_PASSWORD` | fastlane match (certs repo access + decryption) |
| `BETA_CONTACT_PHONE`, `BETA_CONTACT_FIRST`, `BETA_CONTACT_LAST`, `BETA_FEEDBACK_EMAIL` | App Store Beta Review contact block |
| `DEMO_VIDEO_URL` | Guideline 2.1 demo video appended to Beta Review notes |
| `FDROID_REPO_KEYSTORE_BASE64`, `FDROID_REPO_KEYSTORE_PASSWORD`, `FDROID_REPO_KEY_PASSWORD` | Self-hosted F-Droid repo signing |
| `RELEASE_TOKEN` | Release/tag automation needing more than `GITHUB_TOKEN` |
| `GITHUB_TOKEN` | Standard Actions token |

Repository **variables**: `FGS_FORM_APPROVED` (flips the foreground-service build shape
once Play approves the declaration).

> `MATCH_PASSWORD` is not stored on the local Mac — cert operations that need it run in
> CI or require re-entry.

---

## 20. Local development environment

The local Mac is the **main dev and build server** — full Flutter + fastlane stack for
both iOS and Android. Default to local builds.

```bash
export PATH="/Users/floriandittgen/development/flutter/bin:/opt/homebrew/bin:$PATH"
export JAVA_HOME=/Users/floriandittgen/android-toolchain/jdk-17.0.13+11/Contents/Home
```

Gradle tasks must name a **flavor** — `compilePlayDebugKotlin`, not
`compileDebugKotlin`.

### Setup

```bash
git clone https://github.com/fdittgen-png/tankstellen.git && cd tankstellen
flutter pub get
dart run build_runner build --delete-conflicting-outputs
bash scripts/install_hooks.sh        # once per clone — HARD RULES #3 + #4
flutter run
```

### Daily commands

```bash
flutter analyze                                  # zero warnings, fatal infos in CI
flutter test                                     # ~25 min full suite
flutter test --coverage && bash scripts/check_coverage.sh --threshold 45
flutter test --tags=network                      # on-demand upstream probes
dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs
dart run tool/build_arb.dart && dart tool/gen_pseudo_arb.dart && flutter gen-l10n
flutter build appbundle --release --flavor play
flutter build apk --release --flavor fdroid --dart-define=FORCE_LOCATION_MANAGER=true
bash scripts/audit_no_gms.sh build/app/outputs/flutter-apk/app-fdroid-release.apk
```

Prerequisites: Flutter stable 3.41+, JDK 17 + Android SDK, and for iOS Xcode 26+,
CocoaPods 1.16+, Ruby 3.x with Bundler (`Gemfile` / `Gemfile.lock` are committed).

Repo-local slash commands live in `.claude/commands/`; agent worktrees under
`.claude/worktrees/`. Note that a worktree lacks gitignored secrets — build release
artifacts in the shared checkout.

---

## 21. Known constraints, traps & standing decisions

### Standing product constraints

- **Never adopt a paid service, API or SDK.** This killed the PSD2 detector (#2688).
  Prefer free / open / on-device alternatives.
- **No Firebase, no GMS in the libre build, no tracking, no ads, no GPL dependencies.**
- **One code base for all countries** — activation by configuration only.
- **Features default to both iOS and Android**; platform-specific code is a
  loosely-coupled plugin, never an inline `Platform.isIOS`.
- **Alert delivery SLA**: 1–3× per day, ≤3–4 h latency, never next-day, on both
  platforms. Android Tier-1 meets it; iOS needs a Tier-2 push to guarantee it
  (deferred post-go-live).

### CI/CD traps worth re-reading before touching the pipeline

1. **A job-level skip of a MATRIX job blocks required checks forever.** Gate matrix jobs
   **per-step**; only single-context jobs may skip at job level.
2. **Codegen drift reaches CI at ~13 min per round-trip.** Always clean-regenerate.
3. **Parallel ARB PRs always conflict.** One ARB PR in flight at a time.
4. **macOS-baselined goldens fail Linux CI** (3–4 % vs 1.5 % tolerance) → red master.
5. **Serialized auto-merge chains stall when the head PR stays red** — watchers die and
   downstream goes stale on remote. Verify remote `auto`/`mergeState` and that the fix
   is actually on `origin/<branch>`.
6. **`pubspec.fdroid.lock` needs manual regeneration** on every dependency bump or the
   F-Droid audit goes red.
7. **Beta release notes containing double quotes** break the Play upload (the build
   succeeds first, so it looks like a build success). Re-dispatch is safe — a fresh
   versionCode is minted.
8. **`featureGraphic.png` must be camelCase 1024×500**; snake_case is silently ignored.
9. **App Store Connect's Italian locale is `it`, not `it-IT`.**
10. **App Groups have no ASC API endpoint** — enabling them is a manual portal step.
11. **A "never throws" docstring needs a sibling fault-injection test** or the l10n-gate
    job goes red (bit twice in one session: #2914/#2919).
12. **`connectivity_plus` ≥ 7.1 breaks the macOS runner build** until GitHub ships
    Xcode 26 with the iOS 26 SDK.

### Open / tracked work

- `#1542` — iOS background-wake for auto-record.
- `#1498` / `#3173` — Play "Foreground Service Use" declaration; the FGS build shape
  ships dark until approved.
- `#1657` — legacy hard-coded-string cleanup to a zero baseline.
- `#2187` / `#2188` / `#2190` — decomposition of the `trip_recording_*` god-classes.
- `#3075` epic — TankSync bidirectional sync (`#3077` fill_ups/vehicles/alerts pull,
  `#3079` anon→email UUID-preserving upgrade, `#3080` QR pairing, `#3081` over-broad
  Community delete block).
- `#3549` — a durable self-published pipeline for the fragile Greek data source.
- fdroiddata **MR !42093** — awaiting maintainer review.
- `#2072` — the `flutter_blue_plus` 2.x commercial-licence decision.
- The riverpod/analyzer cluster unblocks when the Flutter SDK ships `meta` ≥ 1.18.

---

## 22. Known gaps and stale documentation

Discrepancies between what the committed documentation claims and the
**verified** state of the code, the repository configuration and the live
systems. Items marked ✅ were corrected on the date shown; the rest are listed
so they can be addressed deliberately rather than rediscovered.

> **Why this section exists.** It is the only section that tells you which of
> the others to distrust. A document that is uniformly confident gives a reader
> no way to calibrate, so every stale line is believed at full weight. This
> pattern is borrowed from the sibling project, whose equivalent section is the
> single most useful page in its documentation set. Re-audit quarterly; the
> cost is about an hour and the alternative is documentation people route
> around.

### A. The coverage gate is 40 %, not 45 %, and never runs on a pull request ⚠️

Two separate problems, both verified 2026-08-01.

**The number is wrong.** The `tankstellen-conventions` skill states a
"coverage gate **45%**", and §12 of this document repeated it. CI invokes
`scripts/check_coverage.sh` with **no `--threshold` argument**, so it enforces
the script's default of **40**:

```
scripts/check_coverage.sh:20:  THRESHOLD=40
.github/workflows/ci.yml:455:  run: bash scripts/check_coverage.sh
```

**The reach is narrower than it looks.** The `coverage-merge` job that runs it
is gated `if: github.event_name != 'pull_request'`. Coverage is therefore
checked **only on pushes to `master`** — after a merge, never before one. A
pull request can lower coverage arbitrarily and nothing reports it.

Neither is necessarily wrong as a *decision* — a gate that never fails a build
is not a control either way, and the sibling project says the same of its own
45 % floor in its known-gaps section. What is wrong is the documentation
claiming a threshold and an enforcement point that do not exist.

**Partially fixed 2026-08-01** ✅: CI now passes `--threshold 40` explicitly,
with a comment stating the post-merge-only reach and citing this entry — the
number is stated where it is enforced. Still open: whether to *raise* it and
whether coverage should ever be PR-visible (a deliberate autonomy trade,
#2338).

### B. `logFailure` migration is complete — the ratchet sits at zero ✅
*(closed 2026-08-01)*

`lib/core/error/guarded.dart` collapsed 72 call sites across 37 files in the
first pass; the remaining 16 blocks across 12 files (extra context keys,
synthetic errors, non-ui layers) were hand-migrated in the second. The
grandfathered set in `test/lint/guarded_error_helper_test.dart` is **empty and
pinned at zero** — re-introducing the raw shape anywhere fails the build.
`runGuarded` also gained its first production consumers (the auto-record
persist guard and the backup-export pipeline), closing the
producer-without-consumer gap the first pass left open.

### C. Branch protection matches its codified target ✅ *(verified 2026-08-01)*

`bash scripts/configure_branch_protection.sh --verify` reports
`strict=false` and all ten required checks matching `TARGET_CHECKS`. Recorded
here because the sibling project documents branch protection in three places
and has none on the server — this repository does not have that problem, and
the verify mode is what proves it. Re-run it as part of the quarterly audit.

### D. Counts stated in this document, re-measured ✅ *(2026-08-01)*

| Claim | Measured | Status |
|---|---|---|
| 17 countries | 17 registry entries, 17 station `ServiceSource` values | ✅ |
| 23 locales + pseudo-locale | 24 `app_*.arb` files | ✅ |
| ~1 500 test files | 1 515 | ✅ |
| 20 workflows | 21 (this audit added `release-boot.yml`) | ✅ updated |
| 26 lint tests | 27 (this audit added the `logFailure` ratchet) | ✅ updated |
| 15 ADRs | 15 | ✅ |

### E. Device-layer fixes still marked "needs on-device validation" ⚠️

Several OBD2 link fixes are recorded as awaiting hardware validation and have
sat across releases. A green CI run cannot observe a radio, so these are not
verifiable by the suite at any effort level. Two consequences worth stating:
the fixes may or may not work, and the issues cannot honestly be closed. The
new `Obd2ScanReadinessProbe` reduces the surface — an empty scan is now
self-diagnosing — but does not substitute for a road test.

### F. `release-boot.yml` has never run ⚠️

Added by this audit and advisory by design. It builds a throwaway-signed
R8-shrunk release APK and asserts the process survives 15 s on an emulator.
The follow-up review found and fixed two defects in the first version before
it ever ran: `${{ env.ANDROID_SDK_ROOT }}` is empty in the expressions
context (machine vars are not in `env.`), and the runner's debug keystore
does not exist until AGP's *debug* config lazily creates it — wired as the
release keystore it was a missing file. The workflow now `keytool`-generates
a throwaway keystore into `$RUNNER_TEMP`. It has still not executed; dispatch
the first run manually and watch it (the AVD snapshot cache is cold,
~8–10 min).

### G. `flutter test` output must not be piped

Not a documentation gap but an operational trap worth recording where people
will read it: piping the command (`| tail`, `| grep`) yields the **pipe's**
exit code, not the suite's, so a red run reads as green to any script checking
`$?`. Capture to a file and check the status separately.

---

## Appendix — quick file index

| Looking for | Go to |
|---|---|
| The four/five HARD RULES | `docs/AGENT_RULES.md` (mirrors gitignored `CLAUDE.md`) |
| Full conventions (architecture, TDD, agent doctrine) | the `tankstellen-conventions` skill |
| Architectural decisions | `docs/decisions/0001`–`0015` + `docs/decisions/README.md` |
| Adding a country | `docs/guides/NEW_COUNTRY.md` |
| ARB fragments | `docs/guides/ARB_FRAGMENTS.md` |
| OBD2 adapters / link rewrite | `docs/guides/obd2-adapters.md`, `obd2-link-rewrite-validation.md` |
| iOS release | `docs/guides/ios-*.md` |
| F-Droid submission | `docs/guides/fdroid-submission.md` |
| Play FGS declaration | `docs/guides/play-fgs-declaration.md` |
| Store listing refresh | `docs/guides/PLAY-STORE-LISTING-REFRESH.md`, `app-store-listing.md` |
| Go-live checklist | `docs/guides/go-live-runbook.md` |
| Data Safety answers | `docs/play-store/DATA_SAFETY.md` |
| Design system | `docs/design/DESIGN_SYSTEM.md`, `docs/design/ASSET_SPEC.md` |
| Feature parameters | `docs/feature-concepts/FEATURE_PARAMETER_MAP.md` |
| Contributing | `docs/CONTRIBUTING.md`, `docs/CODE_OF_CONDUCT.md` |
| Release history | `CHANGELOG.md` |
