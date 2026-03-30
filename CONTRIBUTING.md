# Contributing to Tankstellen

Thanks for your interest in contributing! This guide covers everything you need to get started.

## Code of Conduct

By participating, you agree to uphold our [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to Contribute

- **Bug reports** — open an [issue](https://github.com/fdittgen-png/tankstellen/issues) with steps to reproduce
- **Feature requests** — open an issue describing the use case
- **Translations** — add or improve ARB files in `lib/l10n/`
- **New country APIs** — implement the `StationService` interface in `lib/core/services/`
- **Code improvements** — fork, branch, and submit a pull request
- **Documentation** — improve README, guides, or code comments

## Development Setup

### Prerequisites

- Flutter SDK 3.x ([install guide](https://flutter.dev/docs/get-started/install))
- Android SDK (via Android Studio)
- JDK 17

### Getting Started

```bash
git clone https://github.com/fdittgen-png/tankstellen.git
cd tankstellen
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d emulator-5554
```

### Useful Commands

| Command | Purpose |
|---------|---------|
| `flutter analyze` | Static analysis (must pass with zero warnings) |
| `flutter test` | Run all unit and widget tests |
| `flutter test --coverage` | Run tests with coverage report |
| `dart run build_runner build --delete-conflicting-outputs` | Regenerate freezed/riverpod code |

## Branch Naming

Create a branch from `master` using one of these prefixes:

| Prefix | Use for |
|--------|---------|
| `feat/` | New features |
| `fix/` | Bug fixes |
| `refactor/` | Code restructuring (no behavior change) |
| `test/` | Adding or improving tests |
| `docs/` | Documentation changes |
| `chore/` | Tooling, CI, dependencies |

Example: `feat/norway-api`, `fix/cache-ttl-overflow`, `refactor/extract-price-widget`

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Norwegian fuel price API integration
fix: prevent cache key explosion from unrounded coordinates
refactor: extract station card into reusable widget
test: add service chain fallback tests for Spain API
docs: update TankSync setup guide
chore: bump dio to 5.8.0
ci: add coverage threshold check to CI pipeline
```

Focus on **why**, not **what** — the diff shows what changed.

## Pull Request Process

1. **Branch** from `master` — keep branches short-lived (1-3 days)
2. **Commit** with conventional commit messages
3. **Verify** before pushing:
   - `flutter analyze` — zero warnings
   - `flutter test` — all tests pass
4. **Push** your branch and open a PR against `master`
5. **Fill out** the PR template (What / Why / Type / Testing / Checklist)
6. **Link issues** with `Closes #N` in the PR description

### PR Guidelines

- Keep PRs under 400 lines changed (excluding generated `.g.dart` / `.freezed.dart` files)
- One concern per PR — don't mix a bug fix with a refactor
- For large features: split into stacked PRs (data layer -> presentation -> integration)
- All PRs are squash-merged to keep `master` history clean

## Code Style

- Follow existing patterns in the codebase
- User-facing strings go in ARB files (`lib/l10n/`), not hardcoded
- External services go behind abstract interfaces (`StationService`, `GeocodingProvider`)
- API responses use `ServiceResult<T>` wrappers with source/freshness metadata
- Caching goes through `CacheManager`, never direct Hive calls
- Riverpod providers use `@riverpod` annotations, never manual creation
- Use `const` constructors everywhere possible
- Keep screens under 300 lines, providers under 200 lines

## Testing

- **Prefer fakes over mocks** — create `_FakeService` with explicit return values
- Test the service chain fallback pattern: API success, API fail + stale cache, all fail
- Use real `Station` fixtures from `test/fixtures/`
- New features should include tests for happy path, error cases, and edge cases

## Security

- Never commit API keys, secrets, or credentials
- API keys go in `FlutterSecureStorage` (platform keystore)
- No PII in error traces or log output
- Validate all user input at system boundaries
- See [SECURITY.md](SECURITY.md) for vulnerability reporting

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
