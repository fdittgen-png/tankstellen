# Contributing to Tankstellen

Thanks for your interest in contributing! Here's how to get started.

## Ways to Contribute

- **Bug reports** — open an [issue](https://github.com/fdittgen-png/tankstellen/issues) with steps to reproduce
- **Feature requests** — open an issue describing the use case
- **Translations** — add or improve ARB files in `lib/l10n/`
- **New country APIs** — implement the `StationService` interface in `lib/core/services/`
- **Code improvements** — fork, branch, and submit a pull request

## Development Setup

```bash
# Prerequisites: Flutter SDK 3.x, Android SDK, JDK 17

git clone https://github.com/fdittgen-png/tankstellen.git
cd tankstellen
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d emulator-5554
```

## Pull Request Process

1. Fork the repo and create a feature branch from `master`
2. Make your changes in focused, well-described commits
3. Run `flutter analyze` — must pass with zero warnings
4. Run `flutter test` — all tests must pass
5. Open a PR against `master` with a clear description of what and why

## Code Style

- Follow existing patterns in the codebase
- User-facing strings go in ARB files (`lib/l10n/`), not hardcoded
- External services go behind abstract interfaces
- API responses use `ServiceResult<T>` wrappers
- Caching goes through `CacheManager`, never direct Hive calls

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
