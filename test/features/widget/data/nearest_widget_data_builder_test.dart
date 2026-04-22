import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/widget/data/nearest_widget_data_builder.dart';

import 'package:dio/dio.dart';

/// Fake [StationService] that returns a fixed list (or throws) on
/// searchStations. getPrices / getStationDetail are unused by the builder.
class _FakeStationService implements StationService {
  _FakeStationService();

  List<Station> stationsToReturn = const [];
  bool throwOnSearch = false;
  SearchParams? lastParams;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    lastParams = params;
    if (throwOnSearch) {
      throw Exception('network down');
    }
    return ServiceResult(
      data: stationsToReturn,
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}

/// Fake [SettingsStorage] that stores values in a plain map.
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _store = {};

  @override
  dynamic getSetting(String key) => _store[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _store[key] = value;
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}

/// Fake [ProfileStorage] returning a single active profile.
class _FakeProfileStorage implements ProfileStorage {
  _FakeProfileStorage({this.activeProfileJson});

  Map<String, dynamic>? activeProfileJson;

  @override
  String? getActiveProfileId() =>
      activeProfileJson == null ? null : 'p1';

  @override
  Map<String, dynamic>? getProfile(String id) =>
      id == 'p1' ? activeProfileJson : null;

  @override
  List<Map<String, dynamic>> getAllProfiles() =>
      activeProfileJson == null ? const [] : [activeProfileJson!];

  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) async {
    activeProfileJson = profile;
  }

  @override
  Future<void> setActiveProfileId(String id) async {}

  @override
  Future<void> deleteProfile(String id) async {
    activeProfileJson = null;
  }

  @override
  int get profileCount => activeProfileJson == null ? 0 : 1;
}

/// In-memory implementation of the widget payload persistence boundary,
/// so tests can simulate the previous run's payload without touching the
/// real home_widget plugin (which requires platform channels).
class _InMemoryStore implements NearestWidgetPayloadStore {
  final Map<String, Object?> _data = {};

  @override
  Future<String?> readLastJson() async =>
      _data['nearest_json'] as String?;

  @override
  Future<DateTime?> readLastFetchedAt() async {
    final iso = _data['nearest_updated_at'] as String?;
    return iso == null ? null : DateTime.tryParse(iso);
  }

  @override
  Future<void> writePayload({
    required int count,
    required String stationsJson,
    required String updatedAtIso,
    required String emptyReason,
    required bool isStale,
    double? userLat,
    double? userLng,
  }) async {
    _data['nearest_count'] = count;
    _data['nearest_json'] = stationsJson;
    _data['nearest_updated_at'] = updatedAtIso;
    _data['nearest_empty_reason'] = emptyReason;
    _data['nearest_is_stale'] = isStale;
    _data['nearest_lat'] = userLat;
    _data['nearest_lng'] = userLng;
  }

  T? read<T>(String key) => _data[key] as T?;
}

Station _stationFixture({
  required String id,
  required String brand,
  required String street,
  required String place,
  required double lat,
  required double lng,
  double? e10,
  double? e5,
  double? diesel,
  double dist = 0.0,
  bool isOpen = true,
}) =>
    Station(
      id: id,
      name: brand,
      brand: brand,
      street: street,
      postCode: '00000',
      place: place,
      lat: lat,
      lng: lng,
      dist: dist,
      e5: e5,
      e10: e10,
      diesel: diesel,
      isOpen: isOpen,
    );

void main() {
  group('NearestWidgetDataBuilder.build', () {
    late _FakeStationService stationService;
    late _FakeSettingsStorage settings;
    late _FakeProfileStorage profiles;
    late _InMemoryStore store;
    late NearestWidgetDataBuilder builder;

    setUp(() {
      stationService = _FakeStationService();
      settings = _FakeSettingsStorage();
      profiles = _FakeProfileStorage(activeProfileJson: {
        'id': 'p1',
        'name': 'Default',
        'preferredFuelType': 'e10',
        'defaultSearchRadius': 10.0,
      });
      store = _InMemoryStore();
      builder = NearestWidgetDataBuilder(
        stationService: stationService,
        settingsStorage: settings,
        profileStorage: profiles,
        payloadStore: store,
      );
    });

    test('empty payload with empty_reason=no_gps when settings have no GPS',
        () async {
      // No userPositionLat / userPositionLng set.
      final result = await builder.build();

      expect(result.stations, isEmpty);
      expect(result.emptyReason, 'no_gps');
      expect(result.isStale, isFalse);
      expect(store.read<int>('nearest_count'), 0);
      expect(store.read<String>('nearest_empty_reason'), 'no_gps');
    });

    test('empty payload with empty_reason=no_network when search throws '
        '(and no prior payload)', () async {
      await settings.putSetting(StorageKeys.userPositionLat, 52.52);
      await settings.putSetting(StorageKeys.userPositionLng, 13.40);
      stationService.throwOnSearch = true;

      final result = await builder.build();

      expect(result.stations, isEmpty);
      expect(result.emptyReason, 'no_network');
      expect(result.isStale, isFalse);
      expect(store.read<String>('nearest_empty_reason'), 'no_network');
    });

    test('returns up to 5 nearest stations sorted by distance ascending '
        'with all required fields populated', () async {
      await settings.putSetting(StorageKeys.userPositionLat, 52.5200);
      await settings.putSetting(StorageKeys.userPositionLng, 13.4050);

      // 7 stations at increasing distances. The API returns them unsorted
      // on purpose so we can prove the builder sorts locally.
      stationService.stationsToReturn = [
        _stationFixture(
          id: 'de-0',
          brand: 'Shell',
          street: 'Str0',
          place: 'Berlin',
          lat: 52.5201,
          lng: 13.4051,
          e10: 1.799,
          dist: 0.1,
        ),
        _stationFixture(
          id: 'de-5',
          brand: 'JET',
          street: 'Str5',
          place: 'Berlin',
          lat: 52.57,
          lng: 13.45,
          e10: 1.859,
          dist: 5.5,
        ),
        _stationFixture(
          id: 'de-2',
          brand: 'ARAL',
          street: 'Str2',
          place: 'Berlin',
          lat: 52.53,
          lng: 13.41,
          e10: 1.829,
          dist: 1.2,
        ),
        _stationFixture(
          id: 'de-6',
          brand: 'Total',
          street: 'Str6',
          place: 'Berlin',
          lat: 52.60,
          lng: 13.50,
          e10: 1.869,
          dist: 9.1,
        ),
        _stationFixture(
          id: 'de-1',
          brand: 'BP',
          street: 'Str1',
          place: 'Berlin',
          lat: 52.525,
          lng: 13.405,
          e10: 1.819,
          dist: 0.5,
        ),
        _stationFixture(
          id: 'de-4',
          brand: 'Esso',
          street: 'Str4',
          place: 'Berlin',
          lat: 52.55,
          lng: 13.43,
          e10: 1.849,
          dist: 3.2,
        ),
        _stationFixture(
          id: 'de-3',
          brand: 'OIL!',
          street: 'Str3',
          place: 'Berlin',
          lat: 52.54,
          lng: 13.42,
          e10: 1.839,
          dist: 2.1,
        ),
      ];

      final result = await builder.build();

      expect(result.emptyReason, isNull);
      expect(result.isStale, isFalse);
      expect(result.stations, hasLength(5));

      // Exactly the 5 closest IDs (0..4) in ascending-distance order.
      expect(
        result.stations.map((s) => s['id']).toList(),
        ['de-0', 'de-1', 'de-2', 'de-3', 'de-4'],
      );

      // Each row must carry every field the Kotlin renderer expects for
      // parity with the search-results list.
      for (final s in result.stations) {
        expect(s['brand'], isA<String>());
        expect(s['street'], isA<String>());
        expect(s['place'], isA<String>());
        expect(s['distanceKm'], isA<num>());
        expect(s['priceFormatted'], isA<String>());
        expect(s['currency'], isA<String>());
        expect(s['isOpen'], isA<bool>());
      }
      // First station has the shortest distance.
      final d0 = result.stations.first['distanceKm'] as num;
      final d1 = result.stations[1]['distanceKm'] as num;
      expect(d0, lessThanOrEqualTo(d1));
    });

    test('uses the active profile radius and fuel type (not hardcoded)',
        () async {
      await settings.putSetting(StorageKeys.userPositionLat, 52.5200);
      await settings.putSetting(StorageKeys.userPositionLng, 13.4050);
      profiles.activeProfileJson = {
        'id': 'p1',
        'name': 'Truck',
        'preferredFuelType': 'diesel',
        'defaultSearchRadius': 25.0,
      };

      stationService.stationsToReturn = const [];

      await builder.build();

      expect(stationService.lastParams, isNotNull);
      expect(stationService.lastParams!.lat, 52.5200);
      expect(stationService.lastParams!.lng, 13.4050);
      expect(stationService.lastParams!.radiusKm, 25.0);
      expect(stationService.lastParams!.fuelType, FuelType.diesel);
    });

    test('on second call after network failure, returns last successful '
        'payload flagged isStale=true', () async {
      await settings.putSetting(StorageKeys.userPositionLat, 52.5200);
      await settings.putSetting(StorageKeys.userPositionLng, 13.4050);

      // 1. First call succeeds → payload stored.
      stationService.stationsToReturn = [
        _stationFixture(
          id: 'de-0',
          brand: 'Shell',
          street: 'Str0',
          place: 'Berlin',
          lat: 52.5201,
          lng: 13.4051,
          e10: 1.799,
        ),
      ];
      final first = await builder.build();
      expect(first.emptyReason, isNull);
      expect(first.stations, hasLength(1));

      // Capture the JSON that was persisted on the first successful run.
      final storedJson = store.read<String>('nearest_json');
      expect(storedJson, isNotNull);

      // 2. Second call: API throws. We expect the last successful payload
      //    to be returned with isStale=true (widget doesn't blank).
      stationService.throwOnSearch = true;
      final second = await builder.build();

      expect(second.isStale, isTrue);
      expect(second.emptyReason, isNull);
      expect(second.stations, hasLength(1));
      expect(second.stations.first['id'], 'de-0');
      expect(store.read<bool>('nearest_is_stale'), isTrue);
      // The prior JSON is kept / re-written unchanged.
      expect(store.read<String>('nearest_json'), storedJson);
    });
  });
}
