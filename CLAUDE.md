# Tankstellen — Project Context for Claude Code

## What is this project?

Free, open-source fuel price comparison app for Europe (7 countries live).
Built with Flutter/Dart, targeting Android (iOS planned). Version 4.1.0.

## Tech Stack

- **Framework:** Flutter 3.41.5 / Dart 3.11.3
- **State:** Riverpod 3.0.3 with code generation
- **Storage:** Hive 2.2.3 (local-first) + optional Supabase (TankSync cloud backend)
- **HTTP:** Dio 5.x with service abstraction layer
- **Maps:** flutter_map 7.x + OpenStreetMap (free), flutter_map_marker_cluster for dense areas
- **Backend (optional):** supabase_flutter for anonymous auth, sync, and Edge Functions
- **Background:** workmanager for periodic alert checks
- **UI:** shimmer for loading states, flutter_local_notifications for price alerts
- **Models:** freezed + json_serializable (run `dart run build_runner build --delete-conflicting-outputs` after model changes)
- **IDE:** VS Code with Flutter/Dart extensions

## Architecture

- **Feature-first clean architecture** in `lib/features/`
- **Bottom navigation shell** — Search, Map, Favorites, Settings as top-level destinations
- **Service abstraction layer** in `lib/core/services/` — abstract interfaces + fallback chains
- **TankSync (optional)** — Supabase backend for cross-device sync, server-side alerts, community reports
- **Background tasks** — WorkManager periodic alert checks with local push notifications
- **Price history & predictions** — 30-day local recording, "best time to fill" statistical analysis
- **Unified cache** in `lib/core/cache/` — CacheManager with consistent TTLs
- **Error tracing** in `lib/core/error_tracing/` — captures errors with full context for AI diagnosis

## Key Commands

```bash
# Run
flutter run -d emulator-5554   # Android emulator

# Build
flutter build apk --release

# Test
flutter test                   # All tests
flutter test --coverage        # With coverage

# Code generation (after changing freezed/riverpod models)
dart run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze

# Supabase local development (optional — only for TankSync features)
supabase start                  # Start local Supabase stack (Docker required)
supabase db push                # Apply migrations to local database
supabase functions deploy       # Deploy Edge Functions to hosted project
```

## Environment Setup

Flutter SDK: `C:\dev\flutter`
Android SDK: `%LOCALAPPDATA%\Android\Sdk`
JDK: `C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot`

Add to PATH in each session:
```bash
export PATH="/c/dev/flutter/bin:$PATH"
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-17.0.18.8-hotspot"
export ANDROID_HOME="$LOCALAPPDATA/Android/Sdk"
```

## Conventions

- All user-facing strings in German (primary), English (secondary) via ARB files
- All external services behind abstract interfaces (StationService, GeocodingProvider)
- All API responses wrapped in ServiceResult<T> with source/freshness metadata
- All caching via CacheManager — never call HiveStorage.cacheData directly
- Errors go through TraceRecorder for instrumentation
- Run `flutter analyze` before committing — must be zero warnings
- Generated files (.g.dart, .freezed.dart) are committed to git

## Documents

Development docs are in `docs/` (git-ignored, local reference only):

- `docs/api/SPEC.md` — Auditable implementation spec (security, reliability, testing, CI/CD)
- `docs/guides/CONCEPT.md` — Vision, features, architecture, i18n/globalization
- `docs/guides/IMPLEMENTATION.md` — Technical details, API contracts, sprint plan
- `docs/analysis/RISK_ANALYSIS.md` — 24 risks with mitigations
- `docs/guides/DEPLOYMENT.md` — Per-platform build/ship instructions

## Git Workflow (GitHub Flow)

Never commit directly to `master`. `master` is always deployable.

### Branching

- Branch off `master` for every change — keep branches short-lived (1-3 days max)
- Branch naming: `feat/`, `fix/`, `refactor/`, `test/`, `docs/`, `chore/`
- One concern per branch — don't mix a bug fix with a refactor
- Rebase onto latest master before pushing (`git fetch origin master && git rebase origin/master`)

### Commits

- Conventional commit messages: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`
- Focus on **why**, not **what** — the diff shows what changed
- One logical change per commit — split large changes into multiple commits on the same branch

### Pull Requests

- Always create a PR, even for small changes — forces a diff review
- PR title follows conventional commit format (becomes the squash-merge commit message)
- PR description uses the template: What / Why / Testing / Screenshots
- Link issues: `Closes #N` or `Fixes #N` in the PR body to auto-close issues on merge
- Keep PRs under 400 lines changed (excluding generated files)
- For large features: split into stacked PRs (data layer → presentation → integration)

### Merging

- **Squash and merge** only (enforced in repo settings) — keeps master history clean
- Auto-delete head branches is enabled — merged branches are cleaned up automatically
- After merge: `git checkout master && git pull` to sync local

### Releasing

- Tag on master: `git tag -a v4.2.0 -m "Release 4.2.0"` → `git push origin v4.2.0`
- Tags trigger the CI release job (builds artifacts + creates GitHub Release)
- Update `CHANGELOG.md` as part of the release PR, not after
- Build number (`+N` in pubspec) auto-incremented via CI run number

### Step-by-step (when asked to commit and push):

1. Create a feature branch from `master`
2. Commit with conventional commit messages
3. Push the branch with `-u`
4. Create a pull request via `gh pr create` targeting `master`
5. Return the PR URL to the user

## GitHub Project Management

### Issues

- Every feature, bug, and task should be a GitHub issue before work starts
- Use the YAML issue templates: Bug Report, Feature Request, New Country API
- Label issues with: `type/*`, `priority/*`, `area/*`, `effort/*`, `country/*` (if applicable)
- Assign issues to milestones (`v4.2.0`, `v5.0.0-beta`)
- Link PRs to issues with `Closes #N` for automatic closure

### Labels

| Category | Labels | Purpose |
|----------|--------|---------|
| Type | `type/bug`, `type/feature`, `type/enhancement`, `type/refactor`, `type/test`, `type/docs`, `type/chore` | What kind of work |
| Priority | `P0-critical`, `P1-high`, `P2-medium`, `P3-low` | Urgency |
| Area | `area/core`, `area/ui`, `area/api`, `area/sync`, `area/ci`, `area/maps`, `area/alerts`, `area/route` | Which part of the codebase |
| Country | `country/de`, `country/fr`, `country/it`, `country/es`, `country/at`, `country/be`, `country/lu` | Country-specific API issues |
| Effort | `effort/small` (< 2h), `effort/medium` (2-8h), `effort/large` (1+ days) | Size estimation |
| Status | `needs-triage`, `blocked` | Workflow state |

### Milestones

- `v4.2.0` — Next feature release (target: May 2026)
- `v5.0.0-beta` — Beta launch, fresh public repo, production Play Store (target: July 2026)

### CI/CD Pipeline

- **On PR / push to master**: `analyze` + `test` run in parallel (with caching)
- **On PR merge**: builds Android APK (split-per-abi) + App Bundle (.aab)
- **On version tag** (`v*`): creates GitHub Release with auto-generated notes + artifacts
- **iOS build**: disabled (not ready for distribution)
- **Dependabot**: weekly PRs for pub + GitHub Actions dependency updates
- **Coverage**: measured on app code only (excludes l10n, .g.dart, .freezed.dart), threshold 35%

### Dependency Updates

- Dependabot creates weekly PRs for minor/patch updates — review and merge if CI passes
- Major version bumps: create a dedicated `chore/bump-<package>` branch, test thoroughly
- Run `dart pub outdated` monthly to review available updates
- Always check changelogs for breaking changes before major bumps
- License audit: all dependencies must be MIT/BSD/Apache compatible (no GPL)

## Backlog Workflow (Claude Code Integration)

### Commands
- `/backlog` — View all open issues grouped by priority and milestone
- `/pick-task` — AI-ranked suggestion for the best next task (waits for confirmation)
- `/implement` or `/implement 19` — Plan and implement an issue (plan mode -> user confirms -> code)
- `/ship` — Run checks, commit, push, create PR, update project board
- `/review` — Review current branch changes against master

### Testing Commands
- `/test` or `/test <path>` — Run tests, parse results, diagnose failures
- `/test-write <file>` — Write tests for a specific file or feature
- `/test-gaps` — Find untested files, prioritized by risk
- `/test-coverage` — Analyze line-level coverage, suggest improvements
- `/test-accessibility` — Run accessibility guideline checks on screens

### Rules
- **Never write code without explicit user confirmation** — always present a plan first
- **Always write tests** for new or changed code — no exceptions
- Always run `flutter analyze` and `flutter test` before shipping
- Always link PRs to issues with `Closes #N` in the PR body

### Testing Pyramid (70/20/10)
- **Unit (70%)**: Providers, services, models, utils, error classification, cache TTL
- **Widget (20%)**: Individual widgets, user interactions, state-driven UI, accessibility
- **Integration (10%)**: Full user flows, deep links, navigation guards

### Test Conventions
- Prefer fakes over mocks for service layer tests
- Use `pumpApp` from `test/helpers/pump_app.dart` for widget tests
- Use `standardTestOverrides` from `test/helpers/mock_providers.dart`
- Test error classification exhaustively (8+ error categories)
- Test cache TTL behavior: fresh hit, stale hit, miss
- Test service chain fallback: API success, API fail + stale cache, all fail
- Every screen should pass `meetsGuideline(androidTapTargetGuideline)`

## Flutter/Dart Best Practices & Patterns

### State Management (Riverpod)
- **Always use `@riverpod` / `@Riverpod(keepAlive: true)` annotations** — never create providers manually
- Use `keepAlive: true` for app-lifetime state: storage, favorites, profiles, auth, ignored stations
- Use plain `@riverpod` for screen-scoped state: search results, station detail, price history
- **Read vs Watch**: `ref.watch()` for reactive UI rebuilds, `ref.read()` for one-shot actions in callbacks
- Derived providers for simple transformations: `isFavorite(ref, stationId)` watches `favoritesProvider`
- **AsyncNotifier** for API calls: set `state = AsyncValue.loading()`, then `AsyncValue.data()` or `AsyncValue.error()`

### Service Chain & Fallback Pattern
- **4-step fallback**: Fresh cache → API → Stale cache → Error
- **Request coalescing**: In-flight map prevents duplicate concurrent API calls for the same cache key
- Wrap every external service in `StationServiceChain` for automatic caching and fallback
- Every API response is `ServiceResult<T>` with source tracking and error accumulation
- Use `freshnessLabel` and `isStale` flag to inform the user about data quality

### Local-First Data Strategy
- **Save locally first, then sync to server** — never block UI on network
- **Load from DB, then overwrite with local** (local always wins on conflict)
- **Sync adds/changes but never deletes** — only explicit user actions (remove favorite) trigger server deletes
- Use `connectivity_plus` to check network before API calls; serve cached data when offline
- Background tasks (WorkManager) run independently in isolates — no Riverpod, use Dio/Hive directly

### Error Handling
- **Never use `catch (_) {}`** — always `catch (e) { debugPrint('Context: $e'); }` minimum
- Critical errors go through `TraceRecorder.recordError()` for structured diagnosis
- `ServiceResult.errors` accumulates fallback chain errors for user-facing `fallbackSummary`
- Global error handlers in `main.dart`: FlutterError + PlatformDispatcher.onError + optional Sentry
- Use `AppException` / `ApiException` for business logic errors with message + statusCode

### Caching
- **All caching via `CacheManager`** — never call `HiveStorage.cacheData()` directly
- Standard TTLs: prices 5min, search 5min, detail 15min, geocoding 24h, station data 30min
- Cache keys use rounded coordinates (3-4 decimal places) to prevent key explosion
- `cache.get()` returns expired entries (caller decides); `cache.getFresh()` returns only fresh

### Performance
- **Debounce** user input: 800ms for city search, 500ms for API rate limiting
- **Rate limit** external APIs: 2s minimum for Tankerkoenig, 1s for Nominatim, 500ms between route queries
- Add random jitter (500-2500ms) to rate limits to prevent thundering herd
- Sample route polylines every 15km; skip every 3rd point for distance calculations on long polylines
- Use `const` constructors everywhere possible (1141+ const occurrences in codebase)

### Security
- **API keys in FlutterSecureStorage only** (Android Keystore / iOS Keychain / Windows DPAPI)
- In-memory cache (`_apiKeyCache`) to avoid async reads on every API call
- Inject keys via Dio interceptors at request time — never embed in URLs or logs
- Sanitize all user input: URLs (strip whitespace/newlines, validate format), postal codes (country-specific regex)
- No PII in error traces; no API keys in log output

### UI Patterns
- **System nav bar padding**: Always add `MediaQuery.of(context).viewPadding.bottom` to bottom elements
- **Swipe gestures**: `Dismissible` with `confirmDismiss` for non-destructive actions (return `false` to keep item)
- Bidirectional swipe: `background` (swipe right) + `secondaryBackground` (swipe left)
- **Responsive layout**: `isWideScreen()` for split-view, `isLandscape` for compact controls
- All user-facing strings via `AppLocalizations.of(context)?.key ?? 'English fallback'`
- Use `AnimatedCrossFade`, `AnimatedDefaultTextStyle`, `AnimatedContainer` for smooth UI transitions

### Testing
- **Prefer fakes over mocks** for service layer tests — `_FakeStationService` with explicit `stationsToReturn`
- Test error classification exhaustively (8+ error categories)
- Test cache TTL behavior: fresh hit, stale hit, miss
- Test service chain fallback: API success, API fail + stale cache, all fail
- Always test with real `Station` fixtures from `test/fixtures/`

### Code Organization
- **Feature-first**: `lib/features/{name}/data/`, `domain/`, `presentation/`, `providers/`
- **Core services**: `lib/core/services/`, `lib/core/cache/`, `lib/core/storage/`, `lib/core/sync/`
- Keep screens under 300 lines — extract section widgets to `presentation/widgets/`
- Keep providers under 200 lines — extract business logic to services/repositories
- Generated files (`.g.dart`, `.freezed.dart`) are committed to git

### Common Pitfalls to Avoid
- Don't create Dio instances per-request — use `DioFactory.create()` or shared providers
- Don't use `setState()` for shared state — use Riverpod providers
- Don't mix `ref.watch()` and `ref.read()` in the same expression carelessly
- Don't forget `mounted` check after async operations in StatefulWidget
- Don't hardcode German/English strings — use ARB localization even for error messages
- Don't assume `context` is valid after `await` — always check `context.mounted`
- Don't use `StatefulShellRoute.indexedStack` with custom `PageView` — they conflict; use `goBranch` with animations instead

## Don't

- Don't add Google Play Services or Firebase (privacy constraint)
- Don't embed API keys in source (user provides their own)
- Don't use GPL-licensed dependencies (MIT project)
- Don't bypass GDPR consent for location access
- Don't call Tankerkoenig API more than once per 5 minutes automatically
