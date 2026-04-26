import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../fakes/fake_hive_storage.dart';
import '../fakes/fake_storage_repository.dart';
import '../mocks/mocks.dart';

/// Creates an override for [storageRepositoryProvider] using a [MockStorageRepository].
///
/// Returns both the override and the mock so callers can configure stubs.
({Object override, MockStorageRepository mock}) mockStorageRepositoryOverride() {
  final mock = MockStorageRepository();
  // Default stubs to avoid null returns from Mock
  when(() => mock.getFavoriteIds()).thenReturn([]);
  when(() => mock.getFavoriteStationData(any())).thenReturn(null);
  when(() => mock.getEvFavoriteIds()).thenReturn([]);
  when(() => mock.getEvFavoriteStationData(any())).thenReturn(null);
  when(() => mock.isFavorite(any())).thenReturn(false);
  when(() => mock.isEvFavorite(any())).thenReturn(false);
  return (
    override: storageRepositoryProvider.overrideWithValue(mock),
    mock: mock,
  );
}

/// Legacy alias — creates an override for [hiveStorageProvider] using a [MockHiveStorage].
///
/// Prefer [mockStorageRepositoryOverride] for new tests.
({Object override, MockHiveStorage mock}) mockHiveStorageOverride() {
  final mock = MockHiveStorage();
  return (
    override: hiveStorageProvider.overrideWithValue(mock),
    mock: mock,
  );
}

/// Creates an override for [storageRepositoryProvider] using a stateful
/// [FakeStorageRepository]. Prefer this over [mockStorageRepositoryOverride]
/// for any test that needs read-after-write storage semantics — see
/// `feedback_test_doubles_must_mirror_real_service_outputs.md`.
({Object override, FakeStorageRepository fake}) fakeStorageRepositoryOverride() {
  final fake = FakeStorageRepository();
  return (
    override: storageRepositoryProvider.overrideWithValue(fake),
    fake: fake,
  );
}

/// Creates an override for [hiveStorageProvider] using a stateful
/// [FakeHiveStorage]. Prefer this over [mockHiveStorageOverride] for any
/// test that needs read-after-write semantics.
({Object override, FakeHiveStorage fake}) fakeHiveStorageOverride() {
  final fake = FakeHiveStorage();
  return (
    override: hiveStorageProvider.overrideWithValue(fake),
    fake: fake,
  );
}

/// Override [activeCountryProvider] with a specific [CountryConfig].
///
/// Uses overrideWith to provide a custom Notifier that returns [country].
Object activeCountryOverride(CountryConfig country) {
  return activeCountryProvider.overrideWith(() => _FixedActiveCountry(country));
}

/// A minimal ActiveCountry notifier that returns a fixed value.
class _FixedActiveCountry extends ActiveCountry {
  final CountryConfig _country;
  _FixedActiveCountry(this._country);

  @override
  CountryConfig build() => _country;
}

/// Override [favoritesProvider] with a list of favorite station IDs.
Object favoritesOverride(List<String> ids) {
  return favoritesProvider.overrideWith(() => _FixedFavorites(ids));
}

class _FixedFavorites extends Favorites {
  final List<String> _ids;
  _FixedFavorites(this._ids);

  @override
  List<String> build() => _ids;
}

/// Override [isFavoriteProvider] for a specific station ID.
Object isFavoriteOverride(String stationId, bool value) {
  return isFavoriteProvider(stationId).overrideWith((ref) => value);
}

/// Override [selectedFuelTypeProvider] with a specific fuel type.
Object selectedFuelTypeOverride(FuelType fuelType) {
  return selectedFuelTypeProvider
      .overrideWith(() => _FixedSelectedFuelType(fuelType));
}

class _FixedSelectedFuelType extends SelectedFuelType {
  final FuelType _type;
  _FixedSelectedFuelType(this._type);

  @override
  FuelType build() => _type;
}

/// Override [searchRadiusProvider] with a specific radius.
Object searchRadiusOverride(double radius) {
  return searchRadiusProvider.overrideWith(() => _FixedSearchRadius(radius));
}

class _FixedSearchRadius extends SearchRadius {
  final double _radius;
  _FixedSearchRadius(this._radius);

  @override
  double build() => _radius;
}

/// Override [searchLocationProvider] with a specific location string.
Object searchLocationOverride(String location) {
  return searchLocationProvider
      .overrideWith(() => _FixedSearchLocation(location));
}

class _FixedSearchLocation extends SearchLocation {
  final String _location;
  _FixedSearchLocation(this._location);

  @override
  String build() => _location;
}

/// Override [userPositionProvider] with specific coordinates.
Object userPositionOverride({
  required double lat,
  required double lng,
  String source = 'GPS',
}) {
  return userPositionProvider.overrideWith(
    () => _FixedUserPosition(UserPositionData(
      lat: lat,
      lng: lng,
      updatedAt: DateTime.now(),
      source: source,
    )),
  );
}

/// Override [userPositionProvider] with null (no known position).
Object userPositionNullOverride() {
  return userPositionProvider.overrideWith(() => _FixedUserPosition(null));
}

class _FixedUserPosition extends UserPosition {
  final UserPositionData? _data;
  _FixedUserPosition(this._data);

  @override
  UserPositionData? build() => _data;
}

/// Convenience: returns a standard set of overrides for widget tests
/// that need a MockStorageRepository with no API key and Germany as country.
({List<Object> overrides, MockStorageRepository mockStorage})
    standardTestOverrides({
  CountryConfig country = Countries.germany,
  List<String> favoriteIds = const [],
}) {
  final storage = mockStorageRepositoryOverride();
  return (
    overrides: [
      storage.override,
      activeCountryOverride(country),
      favoritesOverride(favoriteIds),
      evFavoritesProvider.overrideWith(() => _EmptyEvFavorites()),
      syncStateProvider.overrideWith(() => _DisabledSyncState()),
    ],
    mockStorage: storage.mock,
  );
}

/// Same as [standardTestOverrides] but backed by a [FakeStorageRepository]
/// for tests that exercise real storage state transitions. Returns the
/// fake so callers can pre-seed storage (e.g. `fake.setApiKey('x')`).
({List<Object> overrides, FakeStorageRepository fakeStorage})
    standardFakeTestOverrides({
  CountryConfig country = Countries.germany,
  List<String> favoriteIds = const [],
}) {
  final storage = fakeStorageRepositoryOverride();
  return (
    overrides: [
      storage.override,
      activeCountryOverride(country),
      favoritesOverride(favoriteIds),
      evFavoritesProvider.overrideWith(() => _EmptyEvFavorites()),
      syncStateProvider.overrideWith(() => _DisabledSyncState()),
    ],
    fakeStorage: storage.fake,
  );
}

class _EmptyEvFavorites extends EvFavorites {
  @override
  List<String> build() => const [];
}



/// SyncState that returns a disabled config (no sync, no Supabase calls).
class _DisabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}
