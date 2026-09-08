# Adding a New Country

The canonical "new feature" contribution — most contributors find their first PR here. This page walks through what's involved. The app currently ships **17 supported countries** (DE, FR, AT, ES, IT, DK, PT, LU, SI, GB, AR, AU, MX, KR, CL, GR, RO) — adding the 18th follows the same recipe.

## Pre-flight

Answer these before you touch code:

- **Is there a free open-data source?** Search *"open data fuel prices {country}"*. Government APIs are preferred; scraped sources are rejected on privacy + reliability grounds.
- **What's the rate limit?** We need to set `RateLimitInterceptor` correctly.
- **What fuel types does the country use?** E5, E10, Diesel, LPG, CNG — and any local specialties (E95 in most of Europe vs. E87 in the US/Mexico, HVO in Scandinavia, SP95-E10 in France).
- **Is there an API key?** Most EU countries don't need one. Germany does. Note the signup URL.
- **What's the postal code format?** 5-digit numeric in DE, 5-digit in FR, 5-digit in ES, 4-digit in AT, 5-digit in IT, 4-digit in DK, 4-digit in PT, alphanumeric in UK, etc.
- **Licensing** — the data source must allow redistribution under terms compatible with our MIT use. Read their ToS.

File a **New Country API** issue with these answers before writing code — it avoids wasted work if there's a gotcha.

## Step-by-step

### 1. Define the `CountryConfig`

`lib/core/country/country_config.dart` — the `CountryConfig` class is at the top, the `Countries` registry (with `Countries.all` and `Countries.verified`) is at the bottom of the same file.

```dart
class Countries {
  // ... existing countries
  static const japan = CountryConfig(
    code: 'JP',
    name: 'Japan',
    flag: '🇯🇵',
    locale: Locale('ja'),
    currency: 'JPY',
    currencySymbol: '¥',
    postalCodeRegex: r'^\d{3}-\d{4}$',
    postalCodeLabel: 'Postcode',
    apiProvider: 'METI',
    apiKeyUrl: null,   // no key needed
    fuelTypes: [FuelType.e95, FuelType.diesel],
    distanceUnit: DistanceUnit.km,
    volumeUnit: VolumeUnit.liter,
    priceUnit: PriceUnit.primary,   // ¥ per L
    examplePostalCode: '100-0005',
    exampleCity: 'Tokyo',
  );
}
```

Add it to `Countries.all` so the registry picks it up. Until the live endpoint is confirmed, set `verified: false` — the country stays registered (so station IDs carrying its prefix still resolve) but is hidden from the user-facing country pickers, which iterate `Countries.verified` instead of `Countries.all`. Flip to `true` once you've end-to-end-tested live prices.

### 2. Write the `StationService` implementation

`lib/core/services/impl/japan_station_service.dart`

```dart
class JapanStationService implements StationService {
  JapanStationService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  @override
  ServiceSource get source => ServiceSource.metiApi;

  @override
  Future<List<Station>> fetch(SearchParams params) async {
    final response = await _dio.get(
      '/stations',
      queryParameters: {
        'lat': params.latitude,
        'lng': params.longitude,
        'radius_km': params.radiusKm,
      },
    );
    return _parseResponse(response.data);
  }

  List<Station> _parseResponse(dynamic data) {
    // Map the API's native shape to List<Station>
    // — remember to populate FuelPrice with fetchedAt = DateTime.now()
    // — normalise any non-metric units to our canonical metric internals
  }
}
```

### 3. Add `ServiceSource` enum entry

`lib/core/services/service_result.dart`

```dart
enum ServiceSource {
  // ... existing
  metiApi,
}
```

### 4. Register in the country service registry

`lib/core/services/country_service_registry.dart`

```dart
StationService _stationServiceFor(String code) => switch (code) {
  'DE' => TankerkoenigStationService(dio: _dioDE),
  // ... existing
  'JP' => JapanStationService(dio: _dioJP),
  _    => DemoStationService(),
};

// And define _dioJP with:
final _dioJP = DioFactory.create(
  baseUrl: 'https://open-data.meti.go.jp/fuel/v1',
  rateLimit: RateLimitConfig(minInterval: Duration(seconds: 1)),
);
```

### 5. Locale translations

Add Japanese to the ARB files if not already present. See [Localization](Dev-Localization-ARB). At minimum:

- Country name in `lib/l10n/app_*.arb` as `countryJapan`
- Any JP-specific fuel-type labels

### 6. Tests (mandatory — no exceptions)

`test/core/services/impl/japan_station_service_test.dart`:

```dart
group('JapanStationService', () {
  test('parses minimal response', () async {
    final dio = MockDio(response: jpSampleJson);
    final service = JapanStationService(dio: dio);
    final stations = await service.fetch(_jpParams);
    expect(stations, hasLength(1));
    expect(stations.first.brand, 'ENEOS');
    expect(stations.first.prices.first.eurPerLiter, 120.0);   // ¥/L
  });

  test('throws ApiException on 503', () async {
    final dio = MockDio(statusCode: 503);
    final service = JapanStationService(dio: dio);
    await expectLater(() => service.fetch(_jpParams), throwsA(isA<ApiException>()));
  });
});
```

Plus at least one integration-level test in `test/features/search/` that verifies the chain works end-to-end for JP.

### 7. Probe the live API before shipping

From `feedback_probe_live_before_country_api_fix`:

```bash
curl 'https://open-data.meti.go.jp/fuel/v1/stations?lat=35.6&lng=139.7&radius_km=5' \
  -H 'Accept: application/json' | jq .
```

Docstrings rot; the live response is the truth.

### 8. Privacy URL reachability test

Add a reachability check for any URLs you add to `AppConstants`:

```dart
@Tags(['network'])
test('JP data source privacy URL is reachable', () async {
  final response = await http.get(Uri.parse(AppConstants.japanDataSourceUrl));
  expect(response.statusCode, 200);
});
```

### 9. Documentation

- Update the Home page's country list.
- Add the country entry to `README.md`.
- Add it to `User-en-Home.md` (and the translated user-home files).
- Update `PRIVACY.md` if the API source requires any disclosures.

### 10. CI considerations

The new tests add a minute or two. If the network-tagged test is flaky against a public API, consider:

- Mocking the response at the Dio interceptor layer (preferred).
- Moving it behind `@Tags(['network'])` and excluding from the default CI run.

### 11. Ship it

See [GitHub Workflow](Dev-GitHub-Workflow) for the commit / PR process. Expect 1-2 review rounds on the first country PR — after that you can usually merge within a day.

## Common gotchas

- **Latitude/longitude order.** Some APIs take `lng,lat`, others `lat,lng`. Write a test that pins the axis.
- **Currency units.** Price-per-gallon vs price-per-liter. Store the canonical internal (always per-L) in `Station.prices` and only format differently at the UI.
- **Cache key.** Include country code first: `search:JP:lat:lng:radius:fuel`.
- **Fallback to demo.** If the new country is in `Countries.all` but its service isn't yet registered, `_stationServiceFor` falls back to `DemoStationService`. Tests must verify this: a fresh install with JP selected should not crash.
- **Rate limit trap.** Set `minInterval` generously on first roll-out; tune down after watching live usage.

## Related

- [Service Layer & Fallback](Dev-Service-Layer-Fallback)
- [Testing & TDD](Dev-Testing-TDD-Pyramid)
- [Localization (ARB)](Dev-Localization-ARB)
