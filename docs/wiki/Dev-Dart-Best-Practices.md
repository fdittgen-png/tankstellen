# Dart Best Practices (Tankstellen)

Project-specific conventions on top of [Effective Dart](https://dart.dev/effective-dart). Lint is enforced via `analysis_options.yaml`.

## Null safety

All files are sound null-safe. No `!` escape hatches unless unavoidable — prefer:

```dart
// prefer
final name = station?.name ?? l10n.unknownStation;

// over
final name = station!.name;
```

Use `late` only for lifecycle-bound fields that are guaranteed to be set before first read (e.g. `late final Obd2Service _service;` after `connect()`).

## Immutability first

Every model is `@freezed`:

```dart
@freezed
class Station with _$Station {
  const factory Station({
    required String id,
    required String brand,
    required double latitude,
    required double longitude,
    @Default([]) List<FuelPrice> prices,
  }) = _Station;

  factory Station.fromJson(Map<String, dynamic> json) => _$StationFromJson(json);
}
```

After editing a freezed file, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Mutating an existing instance:

```dart
final updated = station.copyWith(prices: [...station.prices, newPrice]);
```

## Async

- `async/await` everywhere. Explicit `Future<T>` return types.
- `unawaited(...)` when fire-and-forget is intentional (e.g. `unawaited(traceRecorder.record(e, st));`).
- Never `Future.value(null)` as a placeholder — `Future.value()` or use `SynchronousFuture` if truly sync.
- Don't forget `await` — the `unawaited_futures` lint catches most of it.

### Streams

Prefer `Stream<T>` over `StreamController<T>` exposed to callers:

```dart
Stream<Position> positionStream() async* {
  await for (final pos in _raw.positionStream) yield pos;
}
```

## Extensions

Great for adding domain-specific helpers without inheritance:

```dart
extension FuelPriceX on FuelPrice {
  bool get isStale => DateTime.now().difference(fetchedAt) > Duration(minutes: 5);
  String get formatted => UnitFormatter.formatPricePerUnit(eurPerLiter);
}
```

Keep extensions in the same file as the type, or in `*_x.dart` files co-located with the type.

## Error handling

- `AppException` / `ApiException` hierarchy with `message` + optional `statusCode`
- Never `catch (_) {}` (see the pinning test in `test/lint/`)
- Always pass the stack trace to the trace recorder

```dart
try {
  await something();
} on ApiException catch (e, st) {
  debugPrint('API failure: $e');
  traceRecorder.record(e, st);
  rethrow;
}
```

See [Error Reporting & Tracing](Dev-Error-Reporting-Tracing).

## Constants

Anywhere you find a magic string or number that could be wrong, pin it:

```dart
class CacheTtl {
  static const stationSearch = Duration(minutes: 5);
  static const stationDetail = Duration(minutes: 15);
  static const geocode       = Duration(hours: 24);
  // ...
}
```

Pinning tests (`test/core/constants/`) guarantee no one silently changes them.

## Enums

Prefer enhanced enums over string enums:

```dart
enum FuelType {
  e5(label: 'E5',  grade: 95),
  e10(label: 'E10', grade: 95),
  diesel(label: 'Diesel', grade: null),
  ;

  const FuelType({required this.label, required this.grade});
  final String label;
  final int? grade;
}
```

## Naming

- Types: `UpperCamelCase` — `StationServiceChain`, `PricePrediction`
- Members / locals: `lowerCamelCase` — `fetchedAt`, `isStale`
- Private: leading `_` — `_cache`, `_inFlight`
- Constants: either `UpperCamelCase` for class-level, or `lowerCamelCase` for compile-time `const`. Project convention: prefer `lowerCamelCase const` inside classes (`static const defaultRadius = 5`).
- Files: `snake_case.dart` — `station_service_chain.dart`, `obd2_connection_service.dart`

## No widgets wider than 300 lines

Split into sub-widgets. `presentation/widgets/` is where the pieces live. This keeps `setState` scopes small and widget tests focused.

## No providers wider than 200 lines

Extract business logic to a service or repository, have the provider only orchestrate.

## Equality

Always `@freezed` classes or `Equatable`. Never override `operator ==` by hand unless the class is performance-critical.

## JSON

Generated via `json_serializable`. Manual parsing only for external formats that freezed can't handle (e.g. OBD2 byte stream — that's why `Obd2Service` has hand-rolled parsers).

## Docstrings

Only when the *why* isn't obvious:

```dart
// BAD
/// Returns the price.
double get price => _price;

// GOOD
// MAF-derived fuel rate: assumes gasoline stoichiometry (14.7:1 AFR, 820 g/L).
// Diesel approximation uses 14.5:1 — 3% high, close enough for trip summaries.
double _deriveFuelRateFromMaf(double mafGps, FuelType type) { ... }
```

## `const` everywhere it compiles

Perf win, and lint-enforced:

```dart
return const Center(child: CircularProgressIndicator());
```

At last count the codebase had 1141+ `const` occurrences.

## Don't

- Don't use `print` — use `debugPrint` (compiles away in release).
- Don't instantiate `Dio()` per request — use `DioFactory.create()`.
- Don't use `setState` for shared state — use a Riverpod provider.
- Don't reach into `data/` from `presentation/` — go through `providers/`.
- Don't hardcode strings — everything user-facing goes through ARB.
- Don't assume `context` is valid after `await` — `if (!context.mounted) return;`
- Don't `catch (_) { }`.

## Related

- [Project Structure](Dev-Project-Structure) — where each file shape fits
- [State Management (Riverpod)](Dev-State-Management-Riverpod) — the Riverpod-specific rules
- [Testing & TDD](Dev-Testing-TDD-Pyramid) — how these rules are enforced
