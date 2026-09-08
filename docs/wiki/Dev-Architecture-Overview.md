# Architecture Overview

## Guiding principle

Feature-first clean architecture with a small, strict `core/` at the centre. Every external concern (HTTP, maps, storage, geocoding, Bluetooth) sits behind an abstract interface so it can be faked in tests and swapped per platform.

```
┌──────────────────────────────────────────────────────────────┐
│ lib/main.dart — minimal bootstrap                            │
│   └─ AppInitializer.run()  (lib/app/app_initializer.dart)    │
│       1. bootstrap   2. storage   3. services   4. optional  │
│       5. runApp      → TankstellenApp                        │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ lib/app/app.dart — TankstellenApp (ConsumerWidget)           │
│   MaterialApp.router                                         │
│     ├─ routerProvider  (go_router + consent gating)          │
│     ├─ activeLanguageProvider                                │
│     └─ CountrySwitchListener                                 │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ lib/app/shell_screen.dart — StatefulShellRoute.indexedStack  │
│   Router branches: Search(0) Map(1) Favorites(2)            │
│     Carburant/Fuel(3) Settings/profile(4) Trajets/Trips(5)  │
│   Visual slot order puts Search in the centre, raised:      │
│     Favorites · Map · [Search] · Fuel · Trips               │
│   NavigationRail on ≥600dp / BottomNavBar on <600dp         │
│   Central search FAB owns search across every tab (#2113)   │
└──────────────────────────────────────────────────────────────┘
```

The bottom bar exposes one central **search FAB** that every tab funnels through. The *router* branch indices and the *visual* slot order differ on purpose: Search is branch 0 but sits in the centre slot, raised into a concave notch, flanked by the other destinations (see `lib/app/shell/shell_destinations.dart`). The Consumption surface is split into two destinations gated by `ConsoMode`: **Fuel** alone in fuel-only mode, **Fuel + Trips** in the full fuel-and-trips mode. **Settings is not a tab** — it lives in the top-right app-bar action (`SettingsAppBarAction`, router branch 4 `/profile`). Surfaces that need a contextual action (the Search criteria sheet wants the FAB to *run* the search instead of jumping to Search) register a `SearchFabAction` in `lib/app/shell/search_fab_action_provider.dart`; the FAB swaps its icon, tooltip and onTap accordingly.

## The three layers

### 1. `lib/app/` — composition root
- `app.dart` — MaterialApp, theme (FlexColorScheme + Material 3), locale wiring
- `app_initializer.dart` — cold-start orchestration
- `router.dart` — `go_router` with `NavigationTraceObserver` for error tracing
- `shell_screen.dart` — the bottom-nav shell

### 2. `lib/features/<feature>/` — features
Every feature is self-contained and follows the same shape:

```
features/search/
├── data/
│   ├── models/        # DTOs, JSON, internal shapes
│   └── repositories/  # Wraps a service; adds cache, retries
├── domain/
│   ├── entities/      # Business objects (Station, FuelType, ...)
│   └── services/      # Pure computations (EcoScoreCalculator, ...)
├── presentation/
│   ├── screens/       # Full screens
│   └── widgets/       # Composable parts
└── providers/         # Riverpod providers glueing the layers
```

Features don't reach into each other's internals. Cross-feature data flows through `core/` providers (e.g. `activeCountryProvider`) or shared entities.

### 3. `lib/core/` — cross-cutting concerns
- `services/` — abstract `StationService`, `StationServiceChain`, per-country implementations (17 countries — DE, FR, AT, ES, IT, DK, PT, LU, SI, GB, AR, AU, MX, KR, CL, GR, RO), `GeocodingChain`, `approach_detector.dart` (Epic #2065 — the geo-fence that feeds the PiP approach overlay; consumed by `lib/features/approach/providers/`)
- `cache/` — `CacheManager`, `CacheKey`, `CacheTtl`
- `storage/` — Hive boxes, per-feature stores (`FavoritesHiveStore`, `AlertsHiveStore`, ...)
- `sync/` — Supabase client, sync services, isolate lock
- `country/` — `CountryConfig`, `Countries` registry, `activeCountryProvider`, country-switch flow
- `error_tracing/` — `TraceRecorder`, storage, device-info collector
- `error_reporting/` — consent-gated GitHub-issue composer
- `background/` — WorkManager tasks
- `network/` — `DioFactory`, `RateLimitInterceptor`
- `utils/` — `UnitFormatter`, `PriceFormatter`, shared helpers
- `language/` — `activeLanguageProvider`, locale resolver
- `theme/`, `widgets/`, `permissions/`, `notifications/`, etc.

## Data flow — a search request

```
SearchScreen
  └─ tap "Search"
      └─ searchStateProvider.search(SearchParams)
          └─ StationService (country-specific, resolved via activeCountryProvider)
              ↑ wrapped by
          StationServiceChain:
            1. CacheManager.getFresh(key)   ── hit? return ServiceResult(fresh)
            2. stationService.fetch(...)    ── ok? cache and return
            3. CacheManager.get(key)        ── stale hit? return ServiceResult(stale)
            4. throw ServiceChainExhaustedException

          → ServiceResult<List<SearchResultItem>>
            { data, source, fetchedAt, isStale, errors[], freshnessLabel }

          → AsyncValue<ServiceResult<...>> exposed by searchStateProvider
            ↓
          SearchResultsView rebuilds with the result + freshness badge
```

## Shell & navigation

- `StatefulShellRoute.indexedStack` — every tab keeps its widget tree in memory; stack is not lost when you switch tabs
- Six router branches: Search(0), Map(1), Favorites(2), Carburant/Fuel(3), Settings/profile(4), Trajets/Trips(5). Settings is reached from the app-bar action, not a bottom-bar slot.
- Visible destinations depend on the use mode: Basic shows `Favorites · [Search] · Map`; fuel-only adds `Fuel`; full adds `Trips`.
- On compact screens (<600dp) the nav is at the bottom with the raised central Search FAB; on medium/expanded a `NavigationRail` on the left
- Transitions: slide+fade with a subtle icon bounce on selection
- Compact swipe gesture allows left/right tab switching

## Country switch flow

`CountrySwitchListener` (in `TankstellenApp` builder) watches `countrySwitchEvent` which fires when:

- System location GPS differs from active profile's country
- User explicitly picks a new country

Three event types:
- `suggest` — found a profile matching detected country → modal prompt
- `autoSwitch` — auto-switch enabled → profile already switched, just notify
- `noProfile` — no matching profile → navigate to country setup

Switching clears the search cache (to avoid showing German stations after moving to France) and invalidates `PriceFormatter.activeCountry`.

## Cross-cutting providers

These are `keepAlive: true` — alive for the whole app lifetime:
- `activeCountryProvider` — current country config
- `activeLanguageProvider` — current locale
- `activeProfileProvider` — current user profile
- `storageRepositoryProvider` — top-level Hive access
- `evStationServiceProvider` — OpenChargeMap client

These are scoped to a screen/widget — auto-disposed when the last listener unmounts:
- `searchStateProvider`
- `stationDetailProvider(stationId)`
- `pricePredictionProvider(stationId, fuelType)`
- `priceHistoryProvider(stationId)`

## Related pages

- [Project Structure](Dev-Project-Structure) — exhaustive folder map
- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — the chain in detail
- [State Management (Riverpod)](Dev-State-Management-Riverpod) — provider conventions
- [Storage & Sync](Dev-Storage-Hive-Sync) — persistence model
