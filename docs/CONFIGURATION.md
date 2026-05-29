# Configuration surfaces

> Single index of every place the app reads configuration from, how to
> override each value, and the precedence when more than one source
> exists. Filed as #2194 (Epic #2167) because config was spread across
> five mechanisms with no map.

The app has **five** distinct configuration mechanisms. They are
intentionally separate (build-identity vs secrets vs user/runtime vs
tuning constants), but a contributor needs one place to find them.

## 1. `--dart-define` flags (compile-time, CI/build)

| Flag | Read in | Purpose | Override |
|---|---|---|---|
| `CHANNEL` | `lib/features/feature_management/application/feature_flags_provider.dart` | `production` vs `beta` feature channel | `flutter build … --dart-define=CHANNEL=beta` |
| `SENTRY_DSN` | `lib/app/app_initializer.dart` | Crash-reporting endpoint (empty → Sentry disabled) | `--dart-define=SENTRY_DSN=…` |
| `COMMUNITY_SUPABASE_URL` / `COMMUNITY_SUPABASE_ANON_KEY` | `lib/core/.../community_config.dart` | TankSync community backend (URL + public anon key) | `--dart-define=…` |

These bake into the binary; changing one requires a rebuild.

## 2. Asset-bundled JSON (dev fallback)

- `assets/tanksync_config.json` — read in `community_config.dart` as a
  **fallback** Supabase config for local/dev builds.

**Precedence:** the `--dart-define` values (mechanism 1) win when set;
the asset JSON is only consulted when the dart-defines are empty. Do not
ship real secrets in the asset — it's a dev convenience.

## 3. Hive-backed (user/runtime, persisted on device)

- Per-country API keys — `lib/core/services/country_service_registry.dart`
  (e.g. the Tankerkönig key entered in Settings).
- Feature flags / app profile — the feature-management subsystem.
- User preferences (active country, preferred fuel, search radius, etc.).

These are user-owned and mutable at runtime; no rebuild needed.

## 4. Compile-time constants (tuning)

- `lib/core/constants/app_constants.dart` — radius defaults, refresh
  interval + jitter.
- `lib/core/constants/api_constants.dart` — upstream base URL(s), radius
  bounds, min refresh interval.
- `lib/core/cache/cache_manager.dart` — cache TTLs (see the doc comments
  there for the rationale, #2195).

Deliberately compile-time (sensible defaults, rarely changed). A future
`RuntimeConfig`/remote-config layer could make the genuinely-tunable ones
overridable — see #2195.

## 5. Android Gradle flavor (`distribution`)

- `android/app/build.gradle.kts` defines a `distribution` flavor
  (`play` / `fdroid`) controlling store-specific build wiring.

**This is orthogonal to `CHANNEL`** (mechanism 1): `distribution`
selects the *store target* (Play vs F-Droid); `CHANNEL` selects the
*feature channel* (production vs beta). A `play` build can be either
channel and vice-versa.

---

_When adding a new config value, record it here and pick the mechanism
deliberately: build-identity → dart-define or flavor; secret → dart-define
(never assets); user/runtime → Hive; pure tuning → a constant._
