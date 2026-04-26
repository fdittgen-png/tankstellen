# Contributing to Tankstellen

Thank you for your interest in contributing to Tankstellen, the free fuel price
comparison app for Europe and beyond.

## Development Setup

1. **Flutter SDK** 3.41.5+ installed and on your PATH
2. **Android SDK** with a configured emulator or physical device
3. **JDK 17** (Eclipse Adoptium recommended)

```bash
export PATH="/c/dev/flutter/bin:$PATH"          # or your Flutter path
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-17.0.18.8-hotspot"
flutter doctor   # verify everything is green
flutter pub get
flutter run -d emulator-5554
```

### Release builds

Debug builds (`flutter run`, `flutter build apk --debug`) work out of the box.
Release builds (`flutter build apk --release`, `flutter build appbundle --release`)
require the Android signing keystore to be resolvable or the build will
**fail with a `GradleException`** — there is no silent fallback to the debug
key (see [#48](https://github.com/fdittgen-png/tankstellen/issues/48)).

Signing config resolution order on every build:

1. **Environment variables** (preferred) — set these in your shell rc or via
   `direnv`:
   ```bash
   export ANDROID_KEYSTORE_PATH="$HOME/.android/fuel-prices-release.jks"
   export ANDROID_KEYSTORE_PASSWORD="<your store password>"
   export ANDROID_KEY_ALIAS="fuel-prices"
   # optional: ANDROID_KEY_PASSWORD (falls back to store password)
   ```
2. **Legacy `android/key.properties`** — still supported for convenience.
   Gitignored, plaintext, not recommended for multi-dev machines but fine
   for a single-dev laptop.
3. **Neither** — release build fails fast with an error naming every env var
   you need to set.

For CI and the secrets rotation process, see the **Android Release Signing**
section in the [Security wiki page](https://github.com/fdittgen-png/tankstellen/wiki/Security).

## Branch and PR Workflow

We follow **GitHub Flow** with conventional commits and squash merges.

1. Branch off `master` -- one concern per branch, keep it short-lived (1-3 days).
2. Use branch prefixes: `feat/`, `fix/`, `refactor/`, `test/`, `docs/`, `chore/`.
3. Write conventional commit messages: `feat:`, `fix:`, `docs:`, `refactor:`, etc.
4. Push and open a PR against `master` -- link issues with `Closes #N`.
5. All PRs are squash-merged. Auto-delete of head branches is enabled.

## Code Style

- Run `flutter analyze` before every commit -- zero warnings required.
- All user-facing strings go through ARB localization (`lib/l10n/`).
- All external services are behind abstract interfaces (`StationService`, etc.).
- All API responses are wrapped in `ServiceResult<T>`.
- All caching goes through `CacheManager` -- never call `HiveStorage` directly.
- Generated files (`.g.dart`, `.freezed.dart`) are committed to git.
- Prefer `const` constructors everywhere possible.

After changing freezed or Riverpod models, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Testing

- Every change must include tests -- no exceptions.
- Target the testing pyramid: 70% unit, 20% widget, 10% integration.
- Prefer fakes over mocks for service layer tests.
- Use `pumpApp` from `test/helpers/pump_app.dart` for widget tests.
- Tests that hit real third-party endpoints are isolated under
  `@Tags(['network'])` and excluded from CI — see
  [docs/guides/NETWORK_TESTS.md](guides/NETWORK_TESTS.md) for the
  full inventory and re-run triggers.

```bash
flutter test                # all tests
flutter test --coverage     # with coverage report
```

## Adding a New Country

This is the most common type of contribution. See the full step-by-step guide:

**[docs/guides/NEW_COUNTRY.md](docs/guides/NEW_COUNTRY.md)**

### Quick Checklist

When adding a new country, you must touch **all** of these files:

- [ ] `lib/core/services/impl/<country>_station_service.dart` -- new service
- [ ] `lib/core/services/service_providers.dart` -- register in factory map
- [ ] `lib/core/services/service_result.dart` -- add `ServiceSource` enum value
- [ ] `lib/core/country/country_config.dart` -- add `CountryConfig` + add to `Countries.all`
- [ ] `lib/core/country/country_bounding_box.dart` -- add bounding box
- [ ] `lib/features/search/domain/entities/fuel_type.dart` -- add case in `fuelTypesForCountry`
- [ ] `test/` -- unit tests for the new service

Optional but recommended:

- [ ] `lib/l10n/app_*.arb` -- localized country name if needed
- [ ] Update `Countries.all` ordering for logical display grouping

## Dependency Policy

- All dependencies must be MIT/BSD/Apache compatible -- no GPL.
- No Google Play Services or Firebase (privacy constraint).
- Run `dart pub outdated` before adding new packages.
- Major version bumps get their own `chore/bump-<package>` branch.

## For Junior Devs — A Tour of the Codebase

If you're new to the project (or new to Flutter/Riverpod), start here. This
section walks you through the architecture in the order you'll meet it
when reading code, and points at the files that anchor each concept.

### 1. Where the app starts

```
lib/main.dart                 → 11 lines, calls AppInitializer.run()
lib/app/app_initializer.dart  → cold-start phases (bootstrap → storage → services → optional → runApp)
lib/app/app.dart              → TankstellenApp: MaterialApp.router + global wrappers
lib/app/router.dart           → GoRouter config + consent/setup gating redirects
lib/app/shell_screen.dart     → bottom navigation + tab transitions
```

Read these five files in order. By the time you reach `shell_screen.dart`
you'll understand how a tap on a tab translates into a `goBranch` call
that flips the visible feature.

### 2. Feature-first layout

Every user-visible piece lives under `lib/features/<name>/` with a
predictable substructure:

```
lib/features/<name>/
├── data/         → repositories, model converters, raw API DTOs
├── domain/       → freezed entities, enums, business types
├── presentation/
│   ├── screens/  → ConsumerWidget / ConsumerStatefulWidget pages
│   └── widgets/  → small reusable building blocks for those screens
└── providers/    → @riverpod / @Riverpod(keepAlive: true) state holders
```

When you add a new feature, mirror this exact layout. When you read
existing code, look for the `providers/` folder first — it's the entry
point for understanding how state flows.

### 3. State management (Riverpod 3.0)

We use Riverpod's code-generation flavour exclusively. The two
annotations you'll see all over the codebase:

- `@riverpod` — screen-scoped state (search results, station detail,
  price history). The provider disposes when the last listener
  unsubscribes.
- `@Riverpod(keepAlive: true)` — app-lifetime state (storage, favorites,
  profiles, auth, ignored stations). Survives navigation.

Read vs watch:

- `ref.watch(provider)` — inside `build()`. Triggers a rebuild when the
  provider's value changes.
- `ref.read(provider.notifier).method()` — inside callbacks. One-shot
  action, never triggers a rebuild on its own.

Mixing the two carelessly is the most common Riverpod bug — if you
`watch` inside an `onPressed`, you'll capture a stale value. Always
`read` for actions, `watch` for UI.

### 4. Service abstraction (`ServiceResult<T>`)

External APIs are never called directly from a provider. Each one is
wrapped in an abstract interface (`StationService`, `GeocodingProvider`,
…) and called through `StationServiceChain`, which implements a
4-step fallback:

```
fresh cache → API → stale cache → error
```

Every API response is a `ServiceResult<T>` carrying `data`, `source`
(`api`, `cache`, `staleCache`, `demo`), `fetchedAt`, and any errors
that accumulated along the chain. The `ServiceStatusBanner` widget
reads `result.source` and `result.isStale` to tell the user where the
data came from. **Never bypass the chain** — it's the single source of
truth for caching, retry, and request coalescing.

Anchor files:

```
lib/core/services/service_result.dart
lib/core/services/station_service_chain.dart
lib/core/services/country_service_registry.dart
lib/core/cache/cache_manager.dart
```

### 5. Storage (Hive + secure storage + sync)

We are **local-first**. Every write hits Hive locally before anything
hits the network. Sync is best-effort and asynchronous.

- `lib/core/storage/hive_storage.dart` — Hive boxes (settings, favorites,
  profiles, cache). Use `StorageRepository` (the abstract interface) in
  new code, not `HiveStorage` directly.
- `lib/core/storage/storage_keys.dart` — string keys for the settings
  box. Always reference these constants, never inline strings.
- API keys and Supabase tokens live in `flutter_secure_storage`
  (Android Keystore / Windows DPAPI), never Hive.

The cardinal rule for storage: **load from DB, then overwrite with
local.** Local always wins on conflict. Sync adds and changes, but
never deletes — only explicit user actions trigger server deletes.

### 6. Localization (ARB)

- All user-facing strings go through `AppLocalizations`. Files live in
  `lib/l10n/app_*.arb` (one per supported language).
- After editing an ARB file, regenerate: `flutter gen-l10n` (also runs
  as part of `flutter pub get`).
- Always provide an English fallback in code:
  `l10n?.someKey ?? 'English fallback'`.
- German (`app_de.arb`) is the primary user language; English is the
  default fallback.

### 7. How to add a new feature module

1. Create the feature folder layout from §2.
2. Define your domain entities in `domain/entities/` as freezed classes.
3. Build a service interface in `data/services/` if you call an external
   API. Wrap it in `ServiceResult<T>` and register it in
   `country_service_registry.dart` if it's country-specific.
4. Write a Riverpod provider in `providers/` that exposes the state to
   the UI. Use `@Riverpod(keepAlive: true)` only if the data should
   survive navigation.
5. Build screens in `presentation/screens/` using `ConsumerWidget` or
   `ConsumerStatefulWidget`. Keep `build()` under ~150 lines — extract
   sections to `presentation/widgets/`.
6. Add a route in `lib/app/router.dart` and (if it's a top-level tab)
   wire it into `shell_screen.dart`.
7. Add ARB strings for every user-facing label.
8. Write tests (see §Testing) for the provider, the service, and at
   least one widget test for the screen.
9. Run `dart run build_runner build --delete-conflicting-outputs` to
   regenerate `.g.dart` / `.freezed.dart` files.
10. Run `flutter analyze` (must be zero warnings) and
    `flutter test` (must pass) before opening a PR.

### 8. Common gotchas

- **`package_info_plus` is pinned to `^8.3.1`.** 9.x breaks plugin
  registration on Android. Don't bump it without a known Flutter SDK
  fix.
- **Generated files are committed.** If `.g.dart` / `.freezed.dart`
  diverges from your source after editing a model, run the build runner
  and commit the regenerated files.
- **`context.mounted` after `await`.** Always check `if (!mounted) return;`
  before touching `BuildContext` after an async gap. The
  `use_build_context_synchronously` lint is set to `error`, so the
  analyzer will catch this — but understand *why* it matters.
- **Don't bypass `CacheManager`.** Calling `HiveStorage.cacheData()`
  directly skips TTL handling and request coalescing.
- **Network-tagged tests.** Tests that hit real APIs are tagged
  `@Tags(['network'])` and excluded from CI by default. Run them on
  demand with `flutter test --tags=network`.
- **Consent → setup → main app.** The router has redirects for both
  GDPR consent and onboarding completion. New screens reachable from
  outside the shell must respect these gates or you'll trap the user.
- **Release builds fail without a signing keystore.** As of #48 the
  build throws a `GradleException` when neither the env vars nor
  `android/key.properties` are set. This is intentional — the old code
  silently fell back to the debug signing key, which produced CI
  release artefacts that couldn't upgrade a real user install. If you
  hit this error, read the env var names in the error message and set
  them in your shell rc. See the "Release builds" subsection of
  "Development Setup" above.

### 9. Where to look when you're stuck

- **A provider isn't rebuilding** — check that your `build` method
  watches the right provider, and that you're not accidentally calling
  `read` instead of `watch`.
- **An API call is duplicated** — `StationServiceChain` coalesces
  in-flight requests by cache key. Check the key generation in the
  service.
- **A test passes locally but fails in CI** — first check whether the
  test is in `test/network/` or hits a real API. The CI excludes
  `--exclude-tags=network`. Check `dart_test.yaml` for the tag config.
- **Build runner errors after pulling master** — delete `.dart_tool/`
  and re-run `dart run build_runner build --delete-conflicting-outputs`.

If you're still stuck, open an issue with the `needs-triage` label and
include the file paths you were reading + what you tried.

## Questions?

Open a GitHub issue with the `needs-triage` label, or check existing issues
for context on planned work.
