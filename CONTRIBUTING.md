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

## Questions?

Open a GitHub issue with the `needs-triage` label, or check existing issues
for context on planned work.
