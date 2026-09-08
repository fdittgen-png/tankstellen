# State Management (Riverpod)

Tankstellen uses **Riverpod 3 with code generation**. Every provider is declared via `@riverpod` or `@Riverpod(keepAlive: true)` — never the manual `StateProvider`/`Provider`/`FutureProvider` constructors.

After changing any provider declaration, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Annotation cheat sheet

| Annotation | Lifetime | Use for |
|---|---|---|
| `@riverpod` | Auto-dispose when unused | Screen-scoped state, per-parameter fetches |
| `@Riverpod(keepAlive: true)` | App lifetime | Global state — storage, profiles, auth, active country |

## Common shapes

### Plain synchronous provider

```dart
@Riverpod(keepAlive: true)
CountryConfig activeCountry(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return Countries.byCode(storage.get(StorageKeys.activeCountryCode) ?? 'DE');
}
```

### `AsyncNotifier` for API-backed state

```dart
@riverpod
class SearchState extends _$SearchState {
  @override
  FutureOr<ServiceResult<List<SearchResultItem>>> build() => const AsyncValue.loading();

  Future<void> search(SearchParams params) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(stationServiceProvider).fetch(params);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

### Derived provider

```dart
@riverpod
bool isFavorite(Ref ref, String stationId) {
  final favs = ref.watch(favoritesProvider);
  return favs.ids.contains(stationId);
}
```

One-shot derivation — no AsyncNotifier needed, and the UI rebuilds only when `favoritesProvider.ids` changes.

### Family provider

```dart
@riverpod
Future<PricePrediction?> pricePrediction(
  Ref ref,
  String stationId,
  FuelType fuelType,
) async {
  final repo = ref.watch(priceHistoryRepositoryProvider);
  final history = await repo.getHistory(stationId, days: 30);
  // …
}
```

Generated code handles the tuple cache key.

## `watch` vs `read`

| Call | Where | Effect |
|---|---|---|
| `ref.watch(p)` | `build()` and stateless widgets | **Subscribes**. Widget/provider rebuilds when `p` changes. |
| `ref.read(p)` | Event handlers, imperative code | **One-shot read**. No subscription. |
| `ref.listen(p, cb)` | `build()` | Runs `cb` without rebuilding. Use for snackbars / navigation side effects. |

Rule: **never mix `ref.watch` and `ref.read` carelessly in the same expression**.

```dart
// WRONG — easy to misread
final data = ref.watch(pA) + ref.read(pB).value;

// RIGHT — pick one
final a = ref.watch(pA);
final b = ref.watch(pB);
```

## Keep-alive list

`keepAlive: true` is expensive — these providers live forever. Use sparingly.

Actual keep-alive providers (not exhaustive):

- `storageRepositoryProvider`
- `activeCountryProvider`
- `activeLanguageProvider`
- `activeProfileProvider`
- `favoritesProvider`
- `alertsProvider`
- `ignoredStationsProvider`
- `evStationServiceProvider`
- `fillUpListProvider`
- `obd2ConnectionProvider`

Not keep-alive:
- `searchStateProvider` — disposed when user leaves the search tab
- `stationDetailProvider(id)` — disposed when detail screen closes
- `pricePredictionProvider(id, fuel)` — disposed with its viewer

## Overriding for tests

All providers are testable via `ProviderScope(overrides: [...])`:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      stationServiceProvider.overrideWithValue(_FakeStationService(...)),
      activeCountryProvider.overrideWithValue(Countries.germany),
    ],
    child: SearchScreen(),
  ),
);
```

A shared `standardTestOverrides` list lives in `test/helpers/mock_providers.dart` — always start from there and add feature-specific overrides on top.

## Common pitfalls

### `mounted` after await in a provider

You usually don't need `mounted` inside a provider — Riverpod handles disposal. But in **widgets** after an `await`, always check:

```dart
await something();
if (!context.mounted) return;
```

Widget test for this exists (`test/lint/no_context_after_await_test.dart`).

### `setState` leftovers

Don't use `setState` for anything that's shared across widgets — it belongs in a provider.

### Double-fetching

If two widgets watch the same `FutureProvider` the first time it resolves, Riverpod dedupes naturally. But if one uses `ref.refresh(p)` while another still watches the old value, you can accidentally trigger two concurrent fetches. The `StationServiceChain`'s request coalescing is the safety net.

## Related

- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — where `AsyncValue<ServiceResult<...>>` comes from
- [Testing & TDD](Dev-Testing-TDD-Pyramid) — provider test patterns
