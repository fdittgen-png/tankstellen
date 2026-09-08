# Project Structure

Feature-first; `lib/core/` for cross-cutting concerns; `lib/app/` for composition.

```
tankstellen/
├── android/                       # Android native shell
├── ios/                           # iOS shell (not shipping yet)
├── linux/ macos/ windows/         # Desktop shells (not actively used)
├── web/                           # Minimal web entry (dev only)
│
├── lib/
│   ├── main.dart                  # Entry. 3 lines: → AppInitializer.run()
│   │
│   ├── app/
│   │   ├── app.dart               # TankstellenApp (MaterialApp.router)
│   │   ├── app_initializer.dart   # Cold-start phases
│   │   ├── router.dart            # go_router + NavigationTraceObserver
│   │   ├── shell_screen.dart      # Bottom nav / NavigationRail
│   │   └── country_switch_listener.dart
│   │
│   ├── core/                      # Cross-cutting
│   │   ├── services/              # StationService, chain, per-country impls
│   │   ├── cache/                 # CacheManager, CacheKey, CacheTtl
│   │   ├── storage/               # Hive boxes + *HiveStore classes
│   │   ├── sync/                  # Supabase client, sync service, isolate lock
│   │   ├── country/               # CountryConfig, Countries registry
│   │   ├── error_tracing/         # TraceRecorder, classifier, collectors
│   │   ├── error_reporting/       # Consent-gated GitHub issue composer
│   │   ├── background/            # WorkManager tasks
│   │   ├── network/               # DioFactory, RateLimitInterceptor
│   │   ├── utils/                 # UnitFormatter, PriceFormatter, helpers
│   │   ├── language/              # Active locale provider
│   │   ├── theme/                 # FlexColorScheme wiring
│   │   ├── widgets/               # Shared widgets (banners, placeholders)
│   │   ├── notifications/         # Local notification dispatch
│   │   ├── permissions/           # Runtime permission helpers
│   │   ├── location/              # GPS wrapper
│   │   ├── data/                  # Shared data types
│   │   ├── error/                 # Exception classes
│   │   ├── export/                # CSV / JSON export
│   │   ├── car/                   # Shared car helpers
│   │   ├── perf/                  # Perf helpers
│   │   ├── providers/             # Root-level Riverpod providers
│   │   ├── constants/             # App-wide constants (URLs, defaults)
│   │   └── types/                 # Typedefs and minor types
│   │
│   ├── features/                  # 21 feature modules
│   │   ├── alerts/
│   │   ├── calculator/
│   │   ├── carbon/
│   │   ├── consent/
│   │   ├── consumption/           # Fill-ups, OCR, OBD2, eco-score
│   │   │   ├── data/
│   │   │   │   ├── repositories/
│   │   │   │   ├── obd2/          # Transport, registry, connection service
│   │   │   │   └── pump_display_parser.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/      # FillUp, EcoScore
│   │   │   │   └── services/      # EcoScoreCalculator
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   ├── driving/
│   │   ├── ev/
│   │   ├── favorites/
│   │   ├── itinerary/
│   │   ├── map/
│   │   ├── payment/
│   │   ├── price_history/         # Stats, prediction, charts
│   │   ├── profile/
│   │   ├── report/
│   │   ├── route_search/
│   │   ├── search/
│   │   ├── setup/
│   │   ├── station_detail/
│   │   ├── sync/
│   │   ├── vehicle/
│   │   └── widget/                # Home-screen widget
│   │
│   └── l10n/                      # 23 ARB files + generated L10n class
│
├── test/
│   ├── helpers/
│   │   ├── pump_app.dart          # Standard widget-test harness
│   │   └── mock_providers.dart    # standardTestOverrides
│   ├── fixtures/                  # Canned Station instances
│   ├── core/                      # Tests mirror lib/ tree
│   ├── features/
│   ├── lint/                      # Static scans (no silent catch, tooltips)
│   └── accessibility/             # Tap-target + Semantics tests
│
├── docs/                          # Local dev docs (git-ignored)
├── supabase/                      # SQL migrations + Edge Functions
├── scripts/                       # Release + helper shell scripts
├── .github/
│   ├── workflows/                 # CI definitions
│   ├── ISSUE_TEMPLATE/            # Bug / Feature / Country templates
│   └── dependabot.yml
│
├── pubspec.yaml                   # Version (e.g. 5.0.0+5062), deps
├── analysis_options.yaml          # Lint rules
└── README.md
```

## Feature folder shape (the contract)

Every feature should follow this shape. Deviations need a reason:

```
features/<name>/
├── data/
│   ├── models/          # DTOs / JSON-only types
│   └── repositories/    # Wraps services, adds caching/retries
├── domain/
│   ├── entities/        # Business objects (pure Dart, no Flutter)
│   └── services/        # Pure computations (calculators, parsers)
├── presentation/
│   ├── screens/         # Full-page widgets
│   └── widgets/         # Reusable sub-widgets
└── providers/           # Riverpod providers glueing the above
```

### Why this layering

- **`domain/` is import-safe from anywhere** — no Flutter, no Hive, no Dio. Pure Dart means cheap to test.
- **`data/` depends on domain + external packages**. Repositories can reach into `core/services/` and `core/storage/`.
- **`presentation/` depends on domain + providers** — never directly on `data/`. The provider is the only allowed bridge.
- **`providers/` depends on all three** and exposes the feature to the UI layer.

## File size limits

Soft guidance from the project conventions:

- Screens: under 300 lines — extract sections to `presentation/widgets/`
- Providers: under 200 lines — extract logic to services or repositories
- Repository methods that exceed 50 lines probably hide a pure computation that belongs in `domain/services/`

## Generated files

Committed to git:

- `*.freezed.dart`
- `*.g.dart`
- `lib/l10n/app_localizations*.dart`

They're in git because Dependabot PRs would otherwise look broken on fresh clones, and CI runs `dart run build_runner build` only when source changes require it. Always re-run build_runner after touching a freezed class or `@riverpod` annotation.

## Related

- [Architecture Overview](Dev-Architecture-Overview) — how these layers compose at runtime
- [Dart Best Practices](Dev-Dart-Best-Practices) — freezed, exceptions, naming
