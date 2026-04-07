# Adding a New Country to Tankstellen

This guide walks through every file you need to create or modify when adding
support for a new country's fuel price API.

## Prerequisites

- A publicly accessible fuel price API (free, no GPL data license)
- API documentation or example responses
- Country-specific fuel type names and postal code format

## Step-by-step

### 1. Create the Station Service

**File:** `lib/core/services/impl/<country>_station_service.dart`

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
///
/// <Brief description of API: free/paid, key required, data format.>
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

      // Parse response into Station objects
      final items = response.data as List<dynamic>? ?? [];
      final stations = items.map((item) {
        return Station(
          id: 'xx-${item['id']}',       // prefix with country code
          name: item['name'] ?? '',
          brand: item['brand'] ?? '',
          street: item['address'] ?? '',
          postCode: item['postCode'] ?? '',
          place: item['city'] ?? '',
          lat: (item['lat'] as num).toDouble(),
          lng: (item['lng'] as num).toDouble(),
          dist: 0,                        // calculated below
          e5: (item['petrol'] as num?)?.toDouble(),
          diesel: (item['diesel'] as num?)?.toDouble(),
          isOpen: true,
        );
      }).toList();

      // Calculate distances and filter by radius
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
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    // Implement if the API supports detail queries, otherwise:
    throwDetailUnavailable('Example API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    // Implement if the API supports batch price queries, otherwise:
    return emptyPricesResult(ServiceSource.exampleApi);
  }
}
```

**Key patterns:**

- Use `DioFactory.create()` for HTTP -- never create raw `Dio()` instances.
- Mix in `StationServiceHelpers` for `roundedDistance`, `filterByRadius`,
  `sortStations`, `wrapStations`, `throwApiException`, etc.
- For APIs that return all stations nationally (no radius query), also mix in
  `CachedDatasetMixin` for in-memory caching with TTL. See
  `denmark_station_service.dart` or `argentina_station_service.dart`.
- Prefix station IDs with the country code to avoid collisions across APIs.
- Always handle `DioException` and call `throwApiException`.

### 2. Add ServiceSource Enum Value

**File:** `lib/core/services/service_result.dart`

Add a new entry to the `ServiceSource` enum:

```dart
enum ServiceSource {
  // ... existing entries ...
  exampleApi('Example API'),        // <-- add this
  // ...
}
```

### 3. Register in Service Providers

**File:** `lib/core/services/service_providers.dart`

Add an import for your new service and register it in the
`_countryServiceFactories` map:

```dart
import 'impl/example_station_service.dart';

final _countryServiceFactories = <String, StationService Function(Ref, CacheStrategy)>{
  // ... existing entries ...
  'XX': (ref, cache) => StationServiceChain(
    ExampleStationService(), cache,
    errorSource: ServiceSource.exampleApi, countryCode: 'XX',
  ),
};
```

If the API requires an API key, follow the `'DE'` pattern in the
`stationService` provider (check `storage.hasApiKey()` first).

### 4. Add Country Configuration

**File:** `lib/core/country/country_config.dart`

Add a new `CountryConfig` constant to the `Countries` class:

```dart
static const example = CountryConfig(
  code: 'XX',
  name: 'Example Country',
  flag: '\u{1F1FD}\u{1F1FD}',      // flag emoji (regional indicator symbols)
  currency: 'EUR',                   // or 'GBP', 'USD', etc.
  currencySymbol: '\u20ac',          // or '\u00a3', '\$', etc.
  locale: 'xx_XX',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'Postal code',
  requiresApiKey: false,             // true if user must provide their own key
  apiKeyRegistrationUrl: null,       // URL where user can register for an API key
  apiProvider: 'Example Data Provider',
  attribution: 'Data: example.com',
  fuelTypes: ['Petrol 95', 'Diesel'],
  examplePostalCode: '10000',
  exampleCity: 'Capital City',
);
```

Then add it to `Countries.all`:

```dart
static const all = [
  // ... existing entries ...
  example,    // <-- add here
];
```

### 5. Add Country Bounding Box

**File:** `lib/core/country/country_bounding_box.dart`

Add a bounding box for coordinate validation. Use generous margins (1-2 degrees)
around the country's actual boundaries:

```dart
const countryBoundingBoxes = <String, CountryBoundingBox>{
  // ... existing entries ...
  'XX': CountryBoundingBox(minLat: 40.0, maxLat: 50.0, minLng: -5.0, maxLng: 10.0),
};
```

Source bounding box coordinates from OpenStreetMap or Natural Earth data.

### 6. Add Fuel Type Mapping

**File:** `lib/features/search/domain/entities/fuel_type.dart`

Add a case to the `fuelTypesForCountry` switch for your country code:

```dart
List<FuelType> fuelTypesForCountry(String countryCode) {
  switch (countryCode) {
    // ... existing cases ...
    case 'XX':
      return [FuelType.e5, FuelType.diesel, FuelType.electric, FuelType.all];
    default:
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
  }
}
```

Map the country's local fuel names to the canonical `FuelType` values. If a
country sells a fuel type not yet in the sealed class hierarchy, you will need to
add a new `FuelType` subclass.

### 7. Write Tests

**Required:** Create `test/core/services/impl/<country>_station_service_test.dart`

Test at minimum:

- Parsing a valid API response into `Station` objects
- Handling empty responses gracefully
- Handling network errors (DioException)
- Distance calculation and radius filtering
- Station ID prefixing

Use fakes, not mocks. See existing tests for patterns:

```bash
ls test/core/services/impl/
```

### 8. Run Checks

```bash
flutter analyze --no-fatal-infos   # must be zero warnings
flutter test                        # must pass
```

## File Summary

| File | Action | Required |
|------|--------|----------|
| `lib/core/services/impl/<country>_station_service.dart` | Create | Yes |
| `lib/core/services/service_result.dart` | Add enum value | Yes |
| `lib/core/services/service_providers.dart` | Add import + factory entry | Yes |
| `lib/core/country/country_config.dart` | Add config + update `all` list | Yes |
| `lib/core/country/country_bounding_box.dart` | Add bounding box | Yes |
| `lib/features/search/domain/entities/fuel_type.dart` | Add `fuelTypesForCountry` case | Yes |
| `test/core/services/impl/<country>_station_service_test.dart` | Create | Yes |
| `lib/l10n/app_*.arb` | Localized strings | Optional |

## Tips

- Study `denmark_station_service.dart` for a "download all, filter locally" pattern.
- Study `tankerkoenig_station_service.dart` for a "radius query with API key" pattern.
- Study `portugal_station_service.dart` for a "dataset with CSV parsing" pattern.
- The `StationServiceHelpers` mixin provides all distance, sorting, and wrapping utilities.
- The `CachedDatasetMixin` provides in-memory TTL caching for national datasets.
- Use the GitHub issue template `.github/ISSUE_TEMPLATE/new_country.yml` when proposing a new country.
