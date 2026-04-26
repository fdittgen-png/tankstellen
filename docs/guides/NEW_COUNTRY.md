# Adding a New Country to Tankstellen

This guide walks through adding support for a new country's fuel price API.

Since #1111 the per-country touchpoints are consolidated onto a single
`CountryServiceEntry` in the registry, so adding a new country requires
**one new file** plus **two small appends** (the registry entry and the
`ServiceSource` enum value).

## Prerequisites

- A publicly accessible fuel price API (free, no GPL data license)
- API documentation or example responses
- Country-specific fuel type names and postal code format

## Step-by-step

### 1. Create the Station Service

**File (NEW):** `lib/core/services/impl/<country>_station_service.dart`

This is the core implementation. It must implement `StationService` and handle
fetching + parsing station data from the country's API.

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// <Country> fuel prices from <API provider>.
class ExampleStationService
    with StationServiceHelpers
    implements StationService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.example.com/stations',
        queryParameters: {
          'lat': params.lat,
          'lng': params.lng,
          'radius': params.radiusKm,
        },
        cancelToken: cancelToken,
      );

      // Parse response into Station objects (prefix ids with country code).
      final items = response.data as List<dynamic>? ?? [];
      final stations = items.map((item) {
        return Station(
          id: 'xx-${item['id']}',
          name: item['name'] ?? '',
          brand: item['brand'] ?? '',
          street: item['address'] ?? '',
          postCode: item['postCode'] ?? '',
          place: item['city'] ?? '',
          lat: (item['lat'] as num).toDouble(),
          lng: (item['lng'] as num).toDouble(),
          dist: 0,
          e5: (item['petrol'] as num?)?.toDouble(),
          diesel: (item['diesel'] as num?)?.toDouble(),
          isOpen: true,
        );
      }).toList();

      for (var i = 0; i < stations.length; i++) {
        stations[i] = stations[i].copyWith(
          dist: roundedDistance(
            params.lat, params.lng,
            stations[i].lat, stations[i].lng,
          ),
        );
      }
      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.exampleApi);
    } on DioException catch (e) {
      throwApiException(e, defaultMessage: 'Network error');
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) {
    throwDetailUnavailable('Example API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return emptyPricesResult(ServiceSource.exampleApi);
  }
}
```

**Key patterns:**

- Use `DioFactory.create()` for HTTP — never instantiate raw `Dio()`.
- Mix in `StationServiceHelpers` for distance/filter/sort/wrap helpers.
- For APIs that return all stations nationally, also mix in `CachedDatasetMixin`.
- Prefix station IDs with the country code to avoid collisions across APIs.
- Always handle `DioException` and call `throwApiException`.

### 2. Add the ServiceSource enum value

**File:** `lib/core/services/service_result.dart`

```dart
enum ServiceSource {
  // ... existing entries ...
  exampleApi('Example API'),       // <-- add this
  // ...
}
```

### 3. Append the CountryServiceEntry

**File:** `lib/core/services/country_service_registry.dart`

This is the single registry edit that wires everything together — bounding
box, fuel types, error source, API-key requirement, and the service factory
all live on the entry. The registry uses `StationServiceChain` automatically
to wrap the raw service.

```dart
import 'impl/example_station_service.dart';

// ... in the entries list ...
CountryServiceEntry(
  countryCode: 'XX',
  errorSource: ServiceSource.exampleApi,
  // Generous 1-2 degree margin around the country's actual bounds. See
  // ordering note on entries — tighter / island / coastal boxes go first.
  boundingBox: CountryBoundingBox(
    minLat: 40.0, maxLat: 50.0, minLng: -5.0, maxLng: 10.0,
  ),
  // Order matters — UI selectors render in this order. End every list
  // with FuelType.electric followed by FuelType.all.
  availableFuelTypes: [
    FuelType.e5, FuelType.diesel, FuelType.electric, FuelType.all,
  ],
  requiresApiKey: false,
  createService: _createExample,
),

// ... at the bottom of the file, alongside the other factories ...
StationService _createExample(Ref ref) => ExampleStationService();
```

If the API requires a user-supplied key, mirror the Tankerkönig pattern
(`_createTankerkoenig` in the registry): fall back to `DemoStationService`
when no key is configured.

### 4. Append the CountryConfig

**File:** `lib/core/country/country_config.dart`

`CountryConfig` carries the user-facing presentation data (display name,
flag, currency, postal-code shape) consumed by every UI surface — this is
why it stays separate from the service registry. Add a new constant and
append it to `Countries.all`:

```dart
static const example = CountryConfig(
  code: 'XX',
  name: 'Example Country',
  flag: '\u{1F1FD}\u{1F1FD}',
  currency: 'EUR',
  currencySymbol: '€',
  locale: 'xx_XX',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'Postal code',
  apiProvider: 'Example Data Provider',
  attribution: 'Data: example.com',
  fuelTypes: ['Petrol 95', 'Diesel'],
  examplePostalCode: '10000',
  exampleCity: 'Capital City',
);

// Append to Countries.all:
static const all = [
  // ... existing entries ...
  example,
];
```

The startup assertion `CountryServiceRegistry.assertAllCountriesRegistered()`
verifies `Countries.all` and the registry stay in sync — drift fails fast
on app launch in debug.

### 5. Bounding box & fuel types

These live on the `CountryServiceEntry` you appended in step 3 — there is
no longer a separate `country_bounding_box.dart` map or a
`fuelTypesForCountry` switch to edit (#1111). Both `countryBoundingBoxes`
and `fuelTypesForCountry` continue to work as backwards-compatible
top-level lookup helpers; they delegate to `CountryServiceRegistry`.

### 6. Write tests

**Required:** `test/core/services/impl/<country>_station_service_test.dart`

Test at minimum:

- Parsing a valid API response into `Station` objects
- Handling empty responses gracefully
- Handling network errors (`DioException`)
- Distance calculation and radius filtering
- Station ID prefixing

Use fakes, not mocks. Follow patterns in existing tests under
`test/core/services/impl/`.

### 7. Run checks

```bash
flutter analyze    # must be zero warnings
flutter test       # full suite must pass
```

## File summary (post #1111)

| File | Action | Required |
|------|--------|----------|
| `lib/core/services/impl/<country>_station_service.dart` | Create | Yes |
| `lib/core/services/service_result.dart` | Add `ServiceSource` enum value | Yes |
| `lib/core/services/country_service_registry.dart` | Append `CountryServiceEntry` + factory fn | Yes |
| `lib/core/country/country_config.dart` | Append `CountryConfig` + update `Countries.all` list | Yes |
| `test/core/services/impl/<country>_station_service_test.dart` | Create | Yes |
| `lib/l10n/app_*.arb` | Localized strings | Optional |

Compared to the pre-#1111 layout you no longer touch
`lib/core/country/country_bounding_box.dart` or the per-country switch in
`lib/features/search/domain/entities/fuel_type.dart` — both now read from
`CountryServiceRegistry.entries`.

## Tips

- Study `denmark_station_service.dart` for a "download all, filter locally" pattern.
- Study `tankerkoenig_station_service.dart` for a "radius query with API key" pattern.
- Study `portugal_station_service.dart` for a "dataset with CSV parsing" pattern.
- The `StationServiceHelpers` mixin provides distance, sorting, and wrapping utilities.
- The `CachedDatasetMixin` provides in-memory TTL caching for national datasets.
- Use the GitHub issue template `.github/ISSUE_TEMPLATE/new_country.yml` when proposing a new country.
- Bounding-box ordering matters when a tight/island box sits inside a generous
  neighbour's box. Insert your entry early in `CountryServiceRegistry.entries`
  if your country could be shadowed by an existing one.
