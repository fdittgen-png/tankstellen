# Changelog

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [5.0.0] - 2026-04-28 (Build 5112)

The "cheaper kilometre" release. Where 4.x found you a cheaper litre, 5.x helps you burn fewer of them and shows you exactly what each one cost.

### Added — Layer 2 (drive less consumption)

- **OBD-II auto-record (#1004)** — pair adapter to vehicle, auto-connect on Bluetooth, auto-start on movement, auto-save on disconnect, badge counter on the trips tab. Stale-paused-trip recovery on launch (phase 4-WAL).
- **Visual eco-coach on recording screen (#1273)** — live haptic + on-screen feedback when behaviour costs fuel. Pin-toggle help sheet and resume-recording hint.
- **Driving insights card (#1041 phases 1-5)** — hard-accel waste, idling fuel, cold-start surcharge, low-gear coaching (#1263) on the per-trip detail screen.
- **Composite driving score (#1041 phase 5a, opt-in via gamification toggle)** — single 0-100 number per trip with breakdown chips. Hidden on EV trips.
- **Throttle / RPM histogram (#1041 phase 3a)** — visualises the engine zone you actually drive in.
- **Engine-load chart (#1262 phase 3)** — per-sample engine load over the trip, when the car exposes PID 0x04.
- **Cold-start chip + tooltip (#1262 phase 3)** — surfaces trips where the engine never reached operating temperature.
- **Gear inference + coaching (#1263)** — 1-D k-means clustering on speed/RPM ratios, with a "labouring in low gear" insight when the metric exceeds 60 s per trip.
- **Maintenance analyzer (#1124)** — watches consumption drift over time. Pilot heuristics: MAF deviation (cruise fuel-rate drop), idle creep (warm idle drift), sluggish warm-up.
- **Trip-detail share (#1189)** — render Summary + Insights + charts to a PNG and hand off to the OS share sheet.
- **Fuel-cost field on trip summary (#1209)** — multiplies trip litres by the most-recent fill-up's price-per-litre when available.

### Added — Layer 3 (transparency)

- **Trips tab on Consumption screen (#889)** — full trip history with distance, duration, avg consumption chips. Resume-recording when a trip is already in progress (#1237).
- **Pump-display OCR scan handler** — scan the display at the pump as an alternative to receipt OCR.
- **Driving-insights card on Trip Detail (#1041 phase 2)** — phase 2 wires the insights surface above the charts.

### Added — Layer 1 (cheaper fuel)

- **Daily 18:00 Paris open-testing release (#1066)** — automated AAB → Play Store open-testing track at 18:00 Europe/Paris each day.

### Infrastructure

- **ARB fragment pattern** — `lib/l10n/_fragments/<feature>_<locale>.arb` plus `dart run tool/build_arb.dart` aggregator. Eliminates the multi-coordinator merge conflicts that used to plague `app_en.arb` / `app_de.arb`.
- **Shell branches refactor** — bottom-nav routes extracted to `lib/app/routes/shell_branches.dart` and `*_routes.dart` files. Drove the file-extraction phase work for #563.
- **Test coverage drive (#561)** — 7 phase PRs in the 4.3.x → 5.0.0 window covering route configs, route widgets, shell surfaces, loyalty providers, maintenance analyzer heuristics, and the trip-detail body. 100+ new test cases.
- **Coverage gate lowered to 40 %** (from 45 %, #1292) — temporary while the harder OBD-II / sync paths catch up; will be raised again in 5.1.x.
- **CI parallelism** — daily-beta job pinned to existing action versions (#1066 follow-up).

### Fixed

- Multi-coordinator race detection on parallel autonomous-loop sessions — first-PR-wins with CI-alive verification before closing the duplicate.
- Numerous unused-import / `unnecessary_underscores` info-level lint failures that CI started failing on after the analyse-stricter switch (#1168 cycle).
- Worker compute leaks where isolation worktrees could escape via `cd` — workers now verify `git rev-parse --show-toplevel` before every commit.

### Known limitations / not in this release

- iOS support (#9) is still deferred — code signing, notifications, and background tasks need a paid Apple Developer programme.
- Auto-import the OBD-II odometer reading into the fill-up form is hidden behind a gate until PID 0xA6 is proven reliable across the supported adapter registry (see [docs/guides/obd2-adapters.md](guides/obd2-adapters.md)).
- The price-prediction TFLite model (#1117) is on the backlog but not yet shipped.

---

## [4.3.0] - 2026-03-31 (Build 4001)

### Bug Fixes

**Favorites — Complete Rework**
- FIXED: Favorites screen showing grey/empty despite having saved stations
- Root cause: 3 out of 4 call sites called `toggle(stationId)` without passing station data, so only the ID was saved — no station JSON was persisted to Hive
- `station_detail_screen`: now passes loaded station detail to `toggle()` when favoriting
- `loadAndRefresh()`: automatically fetches station details from API for any favorites that have no persisted data (handles sync imports, legacy data, and edge cases)
- Favorites screen: typed `AsyncValue` parameter properly (was raw `AsyncValue` which could cause silent failures in release mode)

**Favorites Storage (from 4.1.1)**
- Rewritten favorites storage from expiring `CacheManager` (30-min TTL) to permanent Hive storage
- Station JSON persists across cache eviction and app restarts
- ZIP geocoding now uses the active country profile (was hardcoded)
- Route search results sorted by driving order (was unsorted)

### Testing

+38 new tests (27 favorites, 18 alerts — was 11 + 9)

**Favorites Provider Tests (27 total, was 11)**

| Test | What it catches |
|------|----------------|
| `add() with stationData persists JSON` | Verifies station data actually saved to Hive |
| `add() without stationData skips save` | Documents the null-data path |
| `toggle() passes stationData through` | End-to-end toggle with data |
| `remove() cleans up rating + history` | Cascading delete verification |
| `remove() survives cleanup errors` | Resilience to corrupted storage |
| `loadAndRefresh() loads from storage` | Full storage → provider → data flow |
| `loadAndRefresh() fetches missing data` | **The key test** — catches the original bug |
| `loadAndRefresh() merges fresh prices` | Price refresh into persisted stations |
| `loadAndRefresh() persists updated prices` | Verifies write-back to Hive |
| `loadAndRefresh() API failure → stale data` | Graceful degradation |
| `loadAndRefresh() missing + API fail` | No data + no API = empty, not crash |
| `loadAndRefresh() offline → stale data` | Offline path (was never tested) |
| `loadAndRefresh() offline + no data` | Orphan IDs + offline |
| `loadAndRefresh() skips corrupted JSON` | Invalid storage doesn't crash screen |
| `loadAndRefresh() multiple stations order` | List ordering preserved |
| `loadAndRefresh() mix persisted + missing` | Some from Hive, some fetched from API |
| `Station JSON round-trip` | Serialization correctness |

**Alert Provider Tests (18 total, was 9)**

| Test | What it catches |
|------|----------------|
| `addAlert() saves correct data` | Verifies actual saved JSON content |
| `removeAlert() non-existent id` | Edge case doesn't crash |
| `toggleAlert() non-existent id` | No save called for missing alert |
| `toggleAlert() saves correct data` | Verifies `isActive: false` in saved JSON |
| `getAlertStationIds() deduplication` | Unique active station IDs |
| `getAlertStationIds() no active alerts` | Returns empty list |
| `multiple add/remove operations` | Sequential state consistency |
| `PriceAlert JSON round-trip` | All fields including `lastTriggeredAt` |
| `PriceAlert fromJson all fuel types` | Every `FuelType` enum value round-trips |

### Why Tests Didn't Catch the Bug Before

1. **No tests for `FavoriteStations.loadAndRefresh()`** — the entire load flow was untested
2. **Mocks hid serialization bugs** — `MockHiveStorage` never verified `saveFavoriteStationData()` was called
3. **Tests never tested `stationData: null`** — the common production path (detail screen, sync) was untested
4. **Offline path never executed** — connectivity was always mocked as wifi
5. **Screen test only checked scaffolding** — never tested data rendering, state transitions, or error states

---

## [4.1.0] - 2026-03-29 (Build 19)

### New Features

**Route Search Strategies**
- 3 pluggable search algorithms: Uniform (thorough), Cheapest (price-focused), Balanced (price + proximity scoring)
- Strategy selector chips on route search form
- Route segment range extended to 50-1000 km (was 20-100 km)
- Auto-fill start position with GPS
- "All stations" / "Best stops" toggle now in search results (was map-only)

**Station Ratings**
- 5-star rating system on gas and EV station detail pages
- 3 privacy modes: Local only / Private sync / Shared with all DB users
- Configurable per profile in settings

**Ignored Stations**
- Swipe left to hide any station from results, map, and routes
- Synced to database when configured
- Undo via snackbar

**Swipe Navigation**
- Swipe right on any station card to open in maps/navigation
- Swipe left on favorites to remove, on alerts to delete
- Works across search results, route results, and favorites

**Background Price Monitoring**
- WorkManager runs every 1 hour (was 4h stub)
- Fetches prices for all favorites + alert stations (Tankerkoenig batch API)
- Records price history (60-min dedup, 30-day retention)
- Evaluates alert thresholds, fires local push notifications
- Updates cached station data with fresh prices

**Price History Graph**
- Always visible on station detail page (below rating)
- Current price auto-recorded on every detail page visit
- Auto-detects best fuel type (diesel > e10 > e5 > first available)
- Falls back to Supabase history when local is empty

**TankSync Setup Wizard**
- Multi-step guided flow with "Create new" and "Join existing" paths
- QR code scanner for joining existing databases
- Schema auto-detection with migration SQL generation
- Anon key visibility toggle with length validation (208 chars expected)
- Anonymous + Email auth with switching support

**QR Code Sharing**
- Database owners generate QR code (URL + anon key)
- Others scan to auto-fill connection fields
- Settings > TankSync > Share database

**Page Transitions**
- Smooth slide + fade animations between tabs (280ms)
- Horizontal swipe to navigate between bottom nav pages
- Bounce animation on nav bar icons
- Outlined/filled icon switching

**Configuration & Privacy Verification**
- New section at bottom of Settings
- Shows profile, API keys, cloud sync, data privacy per item
- Privacy summary card with contextual bullet points

### Improvements

**Local-First Data Pattern**
- Writes: save locally first, sync to DB async
- Reads: serve local immediately, merge with DB in background
- Local always wins on conflict
- Initial sync on first TankSync connect
- Offline mode: favorites from cache when no internet

**Code Quality**
- `NavigationUtils`: centralized map navigation (replaced 4 duplicates)
- `SyncHelper`: shared sync-if-enabled pattern (replaced 7 duplicates)
- Exception handling: 46 silent `catch (_)` converted to logged catches
- Junior-friendly documentation on major classes
- Best practices documented (11 categories)

**UI/UX**
- Compact best stops cards: 44px (was 120px)
- Compact route info bar and map toolbar
- System nav bar padding on all screens
- Pastel/flashy map markers for selected vs non-selected

**Storage & Cache**
- Cache management shows alerts, ignored stations, ratings counts
- Cache TTL info includes favorites data and city search
- Itineraries stored locally first with merge on sync

### Database

**New Tables**
- `itineraries` — saved routes with waypoints
- `ignored_stations` — user-hidden stations
- `station_ratings` — 1-5 stars with `is_shared` flag

**Schema**: 10 tables, RLS on all, 17 indexes. Migration: `supabase/migrations/20260329000001_complete_schema.sql`

### Testing

10 new test files, +75 tests (531 total, was ~458)

| File | Tests |
|------|-------|
| `navigation_utils_test.dart` | 13 |
| `sync_helper_test.dart` | 9 |
| `schema_verifier_test.dart` | 8 |
| `star_rating_test.dart` | 6 |
| `station_rating_provider_test.dart` | 9 |
| `ignored_stations_provider_test.dart` | 7 |
| `uniform_search_strategy_test.dart` | 5 |
| `cheapest_search_strategy_test.dart` | 5 |
| `balanced_search_strategy_test.dart` | 5 |
| `sync_key_validation_test.dart` | 11 |

### Dependencies Added
- `qr_flutter: ^4.1.0`
- `mobile_scanner: ^6.0.2`

### Stats
- 69 files changed, 6814 insertions, 849 deletions
- 24 new files created

---

## [4.0.0] - 2026-03-28 (Build 18)

### Route Search — "Cheapest Stations Along My Route"
- Enter start + destination (with autocomplete on ALL fields) + optional stops
- Route calculated via OSRM (free, no API key needed)
- Stations found every 15km along the route from country-specific APIs
- Auto-detects which country the route passes through (France, Germany, etc.)
- "Best stops" map view — shows only cheapest station per route segment
- Select/deselect stations and send them as waypoints to Google Maps/Waze
- Waypoints sent in driving order (no zigzag detours)
- Highway avoidance toggle (OSRM exclude=motorway)
- Route segment interval configurable in profile (20-100km)
- Polyline drawn on map with station markers color-coded by price
- 500ms rate limiting between API calls to avoid throttling
- Save routes to cloud for cross-device access
- "Saved routes" screen with load/delete functionality

### EV Charging Stations (OpenChargeMap Integration)
- "Electric" fuel type chip in search — queries OpenChargeMap API
- Pre-configured app-level API key (no setup needed by users)
- EV station cards show: operator, max power (kW), connector types (CCS/Type2/CHAdeMO), usage cost
- Connector chips color-coded: CCS=blue, Type2=green, CHAdeMO=orange, Tesla=pink
- EV station detail page with:
  - All connectors with power, current type, quantity, status badges
  - Status: "Currently Available", "In Use", "Operational", "Partly Operational", etc.
  - Usage cost display (free-text from OpenChargeMap)
  - Refresh button to re-fetch latest status
  - Navigate button (opens Google Maps)
  - Favorite toggle with SnackBar confirmation
  - Provider attribution ("Data from OpenChargeMap")
- Works in both "Nearby" and "Along route" search modes
- Profile toggle to show/hide EV stations and/or fuel stations
- Normal and power charger distinction via kW display

### TankSync Cloud Backend — Major Fixes + New Features
- FIXED: Database always showing 0 entries (root cause: missing public.users row for FK constraint)
- FIXED: Session/userId mismatch after app restart (JWT auth.uid() now always used)
- "Sync now" button on data transparency screen (syncs favorites + alerts)
- Email account creation alongside anonymous auth
  - "Continue as guest" or "Create account" options
  - Sign up / sign in with email + password via Supabase Auth
  - Auto-sync across all devices signed into same email
  - Profile shows "Account: user@email.com" or "Guest account"
- Link Device feature for anonymous users
  - Copy device UUID → paste on other device → merge data
  - Imports favorites + alerts, deduplicates, syncs back
- ntfy.sh push notifications — toggle now persists to push_tokens table
- Save itineraries to cloud — name, waypoints, distance, fuel type, selected stations
- Itineraries screen — list/load/delete saved routes

### 23 European Languages (was 10)
- NEW: Portuguese, Czech, Hungarian, Romanian, Greek, Bulgarian, Croatian, Slovak, Slovenian, Lithuanian, Latvian, Estonian, Norwegian Bokmål
- 120+ hardcoded English strings replaced with l10n references
- All new features (EV, route search, settings) fully localized
- "Along route" translated in all languages

### Code Quality — Major Refactoring
- Sealed `AppException` hierarchy — exhaustive pattern matching
- `StationServiceHelpers` mixin — eliminated ~350 lines of duplicated code across 7 services
- `CachedDatasetMixin` — standardized in-memory cache for bulk-download services
- `DioFactory` — centralized HTTP client creation
- `Station.priceFor(FuelType)` extension — replaced 4 duplicated switch statements
- `BrandDetector` — centralized brand name detection (was duplicated in 3 services)
- `CsvParser` — shared CSV utility for Italy + Argentina services
- `SyncAfterChangeMixin` — eliminated duplicated sync-after-change pattern
- `EmptyState` widget — reusable empty state (icon + text + action button)
- `SwipeToDelete` widget — reusable swipe-to-delete wrapper
- `StationMapLayers` — shared map layers between MapScreen + InlineMap
- `Spacing` constants — standardized spacing values
- Prix-Carburants: returns empty result instead of throwing for empty searches

### Search UX Improvements
- Compact mode toggle chips ("Nearby" / "Along route") instead of bulky SegmentedButton
- Slimmer station cards (reduced margins/padding, combined address line)
- Search results header condensed to single row
- "Cheapest" green badge on cheapest station in route results
- Cache key includes postal code/location name (different searches no longer return stale results)
- EV API key missing → clickable SnackBar navigates to Settings

### Settings Improvements
- API keys section redesigned: shows both Tankerkoenig + OpenChargeMap with status
- Each key has: status indicator, edit button, clickable registration link
- GPS position: "Tap to update" when cleared, confirmation dialog before clearing
- Route segment (km) slider in profile
- Avoid highways toggle in profile
- Show fuel stations / Show EV charging stations toggles
- Search radius used as max detour distance for route search

### Map Improvements
- Two map view modes for routes: "All stations" / "Best stops"
- Best stops: horizontal scrollable cards with selection checkboxes
- "Open in Maps" sends waypoints in driving order via Google Maps Directions API
- Save route button (bookmark icon) in route info bar

### Infrastructure & CI
- `.gitattributes` for line ending consistency
- `.editorconfig` for cross-editor formatting
- ProGuard rules for Hive, Supabase, Freezed, WorkManager
- Gradle parallel builds + caching (build time: 96s → 46s)
- All analyzer warnings fixed — CI passes with exit code 0
- Development docs moved to `docs/` (gitignored)
- Screenshot files moved to `assets_dev/` (gitignored)

### Bug Fixes
- Route search: detects correct country via reverse geocoding (was using profile country)
- Prix-Carburants: returns empty list instead of throwing for empty results
- SearchState: CancelToken race condition fixed (assign new before cancelling old)
- PricePrediction: guard against reduce() on empty list
- DetectedCountry: debounce guard prevents concurrent reverse-geocoding calls
- FavoriteStations: error logging instead of silent swallowing
- price_recorder: per-record try/catch prevents loop abort
- Hive storage: recursive deep conversion of nested maps
- Favorites loading: localized empty state instead of hardcoded German
- Profile: redundant invalidate() calls removed (dependents already watch)

### Tests
- 470 tests total (was ~317 at v2.2)
- New test files: station_service_helpers, cached_dataset_mixin, dio_factory, exceptions hierarchy, station_extensions, charging_station model, search_result_item, route_info, ev_charging_service, routing_service, price_recorder, search_mode_provider, empty_state widget, swipe_to_delete widget, ev_station_card widget
