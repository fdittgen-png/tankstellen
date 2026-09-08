# Testing & TDD

## The pyramid

Target composition:

- **70 % unit** — providers, services, models, utils, error classification, cache TTL
- **20 % widget** — individual widgets, user interactions, state-driven UI, accessibility
- **10 % integration** — full user flows, deep links, navigation guards

At time of writing the suite has **1400+ tests** and runs in ~40 s locally.

## Fakes over mocks

Standing project rule: **prefer fakes over mocks for the service layer**. A fake is a small in-file class that fulfills the interface with explicit behaviour. Mocks with `when(...).thenReturn(...)` grow into untyped spaghetti.

Example:

```dart
class _FakeStationService extends StationService {
  _FakeStationService({this.stationsToReturn = const [], this.failWith});
  final List<Station> stationsToReturn;
  final Exception? failWith;

  @override
  ServiceSource get source => ServiceSource.demo;

  @override
  Future<List<Station>> fetch(SearchParams params) async {
    if (failWith != null) throw failWith!;
    return stationsToReturn;
  }
}
```

`mocktail` is used only for widget-level callbacks (e.g. `verify(() => onTap()).called(1)`).

## Mandatory pre-fix test protocol

For bug fixes this is not optional — standing project rule:

1. **Trace the UI first** — `grep` the screen/widget file that triggers the bug. Read the exact method call.
2. **Write a failing test** that calls the EXACT same method the UI calls (not the "correct" one). The test must fail for the same reason the app fails.
3. If the test passes immediately, it's testing the wrong thing. Re-read the UI file.
4. **Implement the fix** — make the test pass.
5. **Run full suite** — no regressions.
6. **Only THEN build APK** — never build before the test proves the fix works.
7. **Ask "what else depends on this?"** — grep all callers of any changed function/getter before asserting new behaviour in tests.

These rules came out of incidents where the cost of skipping each step was high enough to write it down — keep them.

## Unit test conventions

### Providers

```dart
test('searchStateProvider emits loading → data on success', () async {
  final container = ProviderContainer(
    overrides: [stationServiceProvider.overrideWithValue(
      _FakeStationService(stationsToReturn: [testStation()]))],
  );
  addTearDown(container.dispose);

  expect(container.read(searchStateProvider), const AsyncValue.loading());
  await container.read(searchStateProvider.notifier).search(_params);
  expect(container.read(searchStateProvider).requireValue.data, hasLength(1));
});
```

### Cache TTL (three cases always)

```dart
test('fresh hit', () async { /* store now, getFresh returns */ });
test('stale hit', () async { /* store 10 min ago with 5 min TTL, get returns, getFresh returns null */ });
test('miss',      () async { /* never stored, getFresh returns null */ });
```

### Service chain fallback (three cases always)

1. API success — single call, no cache hit, result marked fresh
2. API failure + stale cache — chain returns stale, errors populated
3. Everything fails — throws `ServiceChainExhaustedException` with all errors

### Error classifier (exhaustive)

Every exception type the app throws has an asserted category:

```dart
for (final case in [
  (DioException(...), ErrorCategory.network),
  (ApiException(...), ErrorCategory.api),
  (CacheException(...), ErrorCategory.cache),
  // ... 8+ categories total
]) {
  test('${case.$1.runtimeType} maps to ${case.$2}', () {
    expect(ErrorClassifier.classify(case.$1), case.$2);
  });
}
```

## Widget tests

### The standard harness

```dart
await tester.pumpWidget(
  pumpApp(
    overrides: [...standardTestOverrides, featureOverride],
    child: const SearchScreen(),
  ),
);
```

`pumpApp` lives in `test/helpers/pump_app.dart` — sets up MaterialApp, localisations, and provider scope in one call. `standardTestOverrides` (`test/helpers/mock_providers.dart`) gives safe fakes for all keep-alive providers.

### Accessibility

Every interactive screen tests against the tap-target guideline:

```dart
testWidgets('SearchScreen passes tap-target guideline', (tester) async {
  await tester.pumpWidget(pumpApp(child: const SearchScreen()));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
});
```

Icon-button tooltip coverage is enforced by a static scan:

```dart
// test/accessibility/icon_button_tooltip_coverage_test.dart
// fails if any IconButton is missing a tooltip
```

### Semantics for custom widgets

Station cards expose brand + address + price + open/closed as a single merged Semantics node, not a tree of isolated `Text` widgets. The test asserts the merged label:

```dart
expect(find.bySemanticsLabel(RegExp(r'Shell.*€.*open')), findsOneWidget);
```

## Integration tests

`integration_test/` directory. Run on emulator:

```bash
flutter test integration_test/
```

Cover:

- Consent gate → country setup → first search — the "golden path"
- Favorite toggle persists across app restart
- Price alert fires a notification when the background check is triggered manually
- Deep link `tankstellen://station/{id}` opens the detail screen
- Offline-to-online transition: stale data shown, then refreshed

## Static lint scans

`test/lint/`:

- `no_silent_catch_test.dart` — fails if any `catch (_) {}` is committed
- `no_hardcoded_ui_strings_test.dart` — fails if any user-facing string is hard-coded instead of routed through `AppLocalizations`. The baseline may only ever decrease; the target is zero (epic #1657)
- `file_length_test.dart` — caps every file at **400 lines**; the limit is the project's strongest signal that a file needs splitting
- `no_raw_appbar_in_features_test.dart` / `no_raw_card_in_features_test.dart` — force feature code through the design-system wrappers
- `arb_fragments_consistency_test.dart` — pins the ARB-fragment → top-level ARB build pipeline
- `catch_block_stacktrace_coverage_test.dart` — fails if a `catch (e)` swallows the stack trace

Static scans are the cheapest way to prevent regressions that would otherwise go through every code review.

## Silencing the error-logger spool in unit tests

Tests that exercise a code path which calls `errorLogger.log(...)` will, by default, flood test output with the spooled errors. Use the helper:

```dart
import 'package:tankstellen/core/telemetry/storage/isolate_error_spool.dart';

void main() {
  silenceErrorLoggerSpool();   // top of main(), before any group()

  group('GithubIssueReporter', () { ... });
}
```

The pattern came out of Epic #2146 (309 silent-catch sites rerouted through `errorLogger.log(ErrorLayer.<layer>, e, st, context: {...})`) — every test file that exercises those code paths now opens with this one-liner so legitimate test output isn't drowned in spool noise. See [Error Reporting & Tracing](Dev-Error-Reporting-Tracing) for the production logger contract.

## Coverage

```bash
flutter test --coverage
```

Report: `coverage/lcov.info`. CI enforces a 45 % threshold on app code (excludes `l10n/`, `*.g.dart`, `*.freezed.dart`).

## Running a subset

```bash
flutter test test/features/search/          # one feature tree
flutter test -p windows test/core/cache/    # one core area
flutter test -name 'caches fresh entries'   # name pattern
```

Tags:

```bash
flutter test --tags network     # @Tags(['network'])  — reachability tests
flutter test --exclude-tags golden
```

## Related

- [State Management (Riverpod)](Dev-State-Management-Riverpod) — provider override patterns
- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — what the chain tests verify
- [CI/CD Pipeline](Dev-CI-CD-Pipeline) — where tests run on every PR
