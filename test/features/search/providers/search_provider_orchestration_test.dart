import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider_orchestration.dart';

/// Coverage for the orchestration helpers extracted from the search
/// notifier (#563). Each helper takes [Ref] explicitly so unit tests
/// drive them through a [ProviderContainer] with override fakes for
/// every upstream dependency.
///
/// Pinned behaviour:
///   * [classifySearchError] — DioException(cancel) → null, every other
///     class → [AsyncValue.error].
///   * [resolveFuelAndRadius] — explicit args win, otherwise fall back
///     to active profile / [effectiveFuelTypeProvider] / 10.0 km.
///   * [tryReverseGeocode] — returns [ServiceResult.data] on success,
///     `null` on Exception.
///   * [autoUpdatePositionIfEnabled] — only invokes
///     [UserPosition.updateFromGps] when the active profile opted in;
///     swallows exceptions.
///   * [dispatchEvIfNeeded] — returns null for non-electric, otherwise
///     forwards to [EVSearchState.searchNearby] and projects the
///     resolved [AsyncValue] into the unified search-item shape.

class _FixedActiveProfile extends ActiveProfile {
  _FixedActiveProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

/// Fake [UserPosition] notifier that records [updateFromGps] calls
/// without touching the real [LocationService] / Hive storage.
class _RecordingUserPosition extends UserPosition {
  _RecordingUserPosition({this.shouldThrow = false});

  /// When true, [updateFromGps] throws to exercise the swallow path.
  final bool shouldThrow;

  /// Number of times [updateFromGps] was called by the helper under
  /// test. Lets the test assert "did the helper short-circuit?".
  int updateFromGpsCalls = 0;

  @override
  UserPositionData? build() => null;

  @override
  Future<void> updateFromGps() async {
    updateFromGpsCalls += 1;
    if (shouldThrow) throw Exception('GPS denied');
  }
}

/// Fake [EVSearchState] that lets the test choose the resolved state
/// (data vs error) and verifies that [dispatchEvIfNeeded] forwards
/// arguments unchanged to [searchNearby].
class _FakeEvSearchState extends EVSearchState {
  _FakeEvSearchState({required AsyncValue<ServiceResult<List<ChargingStation>>> resolved})
      : _resolved = resolved;

  final AsyncValue<ServiceResult<List<ChargingStation>>> _resolved;

  bool searchNearbyCalled = false;
  double? lastLat;
  double? lastLng;
  double? lastRadiusKm;

  @override
  AsyncValue<ServiceResult<List<ChargingStation>>> build() {
    // Initial state matches the real provider so the very first
    // `read(eVSearchStateProvider)` before [searchNearby] still
    // returns the expected empty payload, even though tests only
    // care about the post-[searchNearby] resolution.
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime(2024, 1, 1),
    ));
  }

  @override
  Future<void> searchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    searchNearbyCalled = true;
    lastLat = lat;
    lastLng = lng;
    lastRadiusKm = radiusKm;
    state = _resolved;
  }
}

/// Hand-rolled [GeocodingChain] stub. Cannot extend the real class
/// (no abstract interface), so we shadow the methods used by
/// [tryReverseGeocode]. The class only depends on
/// [coordinatesToAddress], so the stub only needs to override that
/// method via inheritance from a class that satisfies the type. We
/// achieve this by extending [GeocodingChain] with empty providers
/// and overriding the single method the helper calls.
class _StubGeocodingChain extends GeocodingChain {
  _StubGeocodingChain.success(this._result)
      : _throw = false,
        super(const [], const _NoopCache());

  _StubGeocodingChain.failure()
      : _result = null,
        _throw = true,
        super(const [], const _NoopCache());

  final ServiceResult<String>? _result;
  final bool _throw;

  bool wasCalled = false;
  double? lastLat;
  double? lastLng;
  CancelToken? lastCancelToken;

  @override
  Future<ServiceResult<String>> coordinatesToAddress(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) async {
    wasCalled = true;
    lastLat = lat;
    lastLng = lng;
    lastCancelToken = cancelToken;
    if (_throw) throw Exception('net down');
    return _result!;
  }
}

/// Minimal cache strategy that never returns anything and accepts every
/// write. The stub geocoding chain delegates exclusively through the
/// overridden [coordinatesToAddress], so the cache is never consulted —
/// but [GeocodingChain]'s constructor requires one, so we satisfy the
/// type with this no-op.
class _NoopCache implements CacheStrategy {
  const _NoopCache();

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {}

  @override
  CacheEntry? get(String key) => null;

  @override
  CacheEntry? getFresh(String key) => null;
}

/// Captures a [Ref] from a [ProviderContainer] so tests can call the
/// orchestration helpers directly. Returning [Object] keeps the
/// trick provider parameterless and keeps Riverpod from complaining
/// about the captured ref outliving the container — the test always
/// disposes the container immediately after.
Ref _captureRef(ProviderContainer container) {
  late Ref captured;
  final probe = Provider<int>((ref) {
    captured = ref;
    return 0;
  });
  container.read(probe);
  return captured;
}

void main() {
  group('classifySearchError', () {
    final stack = StackTrace.current;

    test('DioException(cancel) returns null', () {
      final cancel = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.cancel,
      );
      expect(classifySearchError(cancel, stack), isNull);
    });

    test('non-cancel DioException wraps as AsyncValue.error', () {
      final timeout = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      final result = classifySearchError(timeout, stack);
      expect(result, isA<AsyncError<ServiceResult<List<SearchResultItem>>>>());
      expect(result!.error, same(timeout));
      expect(result.stackTrace, same(stack));
    });

    test('ServiceChainExhaustedException wraps as AsyncValue.error', () {
      const exhausted = ServiceChainExhaustedException(errors: []);
      final result = classifySearchError(exhausted, stack);
      expect(result, isA<AsyncError<ServiceResult<List<SearchResultItem>>>>());
      expect(result!.error, same(exhausted));
      expect(result.stackTrace, same(stack));
    });

    test('plain Exception wraps as AsyncValue.error', () {
      final boom = Exception('boom');
      final result = classifySearchError(boom, stack);
      expect(result, isA<AsyncError<ServiceResult<List<SearchResultItem>>>>());
      expect(result!.error, same(boom));
      expect(result.stackTrace, same(stack));
    });
  });

  group('resolveFuelAndRadius', () {
    test('explicit args win — provider reads do not influence the result',
        () {
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(
              const UserProfile(
                id: 'p1',
                name: 'p',
                preferredFuelType: FuelType.diesel,
                defaultSearchRadius: 25,
              ),
            )),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = resolveFuelAndRadius(ref, FuelType.e10, 5);

      expect(result.fuelType, FuelType.e10);
      expect(result.radiusKm, 5);
    });

    test('only fuelType supplied → radius falls back to active profile', () {
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(
              const UserProfile(
                id: 'p1',
                name: 'p',
                defaultSearchRadius: 12.5,
              ),
            )),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = resolveFuelAndRadius(ref, FuelType.e85, null);

      expect(result.fuelType, FuelType.e85);
      expect(result.radiusKm, 12.5);
    });

    test('only radiusKm supplied → fuelType falls back to '
        'effectiveFuelTypeProvider', () {
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(null)),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.lpg),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = resolveFuelAndRadius(ref, null, 7);

      expect(result.fuelType, FuelType.lpg);
      expect(result.radiusKm, 7);
    });

    test('both null + no active profile → radius defaults to 10.0', () {
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(null)),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.electric),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = resolveFuelAndRadius(ref, null, null);

      expect(result.fuelType, FuelType.electric);
      expect(result.radiusKm, 10.0);
    });
  });

  group('tryReverseGeocode', () {
    test('returns the data field on success', () async {
      final stub = _StubGeocodingChain.success(ServiceResult(
        data: 'Foo Street',
        source: ServiceSource.nominatimGeocoding,
        fetchedAt: DateTime(2024, 1, 1),
      ));

      final result = await tryReverseGeocode(stub, 48.85, 2.35);

      expect(result, 'Foo Street');
      expect(stub.wasCalled, isTrue);
      expect(stub.lastLat, 48.85);
      expect(stub.lastLng, 2.35);
    });

    test('returns null when the chain throws an Exception', () async {
      final stub = _StubGeocodingChain.failure();

      final result = await tryReverseGeocode(stub, 0, 0);

      expect(result, isNull);
      expect(stub.wasCalled, isTrue);
    });
  });

  group('autoUpdatePositionIfEnabled', () {
    test('no active profile → updateFromGps is not called', () async {
      final fakePosition = _RecordingUserPosition();
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(null)),
        userPositionProvider.overrideWith(() => fakePosition),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      await autoUpdatePositionIfEnabled(ref);

      expect(fakePosition.updateFromGpsCalls, 0);
    });

    test('autoUpdatePosition false → updateFromGps is not called',
        () async {
      // freezed @Default(false) for autoUpdatePosition keeps the
      // helper's guard happy — no need to set it explicitly.
      final fakePosition = _RecordingUserPosition();
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(
              const UserProfile(id: 'p1', name: 'p'),
            )),
        userPositionProvider.overrideWith(() => fakePosition),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      await autoUpdatePositionIfEnabled(ref);

      expect(fakePosition.updateFromGpsCalls, 0);
    });

    test('autoUpdatePosition true → updateFromGps invoked exactly once',
        () async {
      final fakePosition = _RecordingUserPosition();
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(
              const UserProfile(
                id: 'p1',
                name: 'p',
                autoUpdatePosition: true,
              ),
            )),
        userPositionProvider.overrideWith(() => fakePosition),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      await autoUpdatePositionIfEnabled(ref);

      expect(fakePosition.updateFromGpsCalls, 1);
    });

    test('updateFromGps throws → exception swallowed (no rethrow)',
        () async {
      final fakePosition = _RecordingUserPosition(shouldThrow: true);
      final container = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedActiveProfile(
              const UserProfile(
                id: 'p1',
                name: 'p',
                autoUpdatePosition: true,
              ),
            )),
        userPositionProvider.overrideWith(() => fakePosition),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      // Must not throw — the helper logs via debugPrint and returns.
      await autoUpdatePositionIfEnabled(ref);

      expect(fakePosition.updateFromGpsCalls, 1);
    });
  });

  group('dispatchEvIfNeeded', () {
    test('non-electric fuel → returns null and does not touch '
        'eVSearchStateProvider.notifier', () async {
      // Fake provider that would record any call. If the helper
      // short-circuits correctly, [searchNearbyCalled] stays false.
      final fakeEv = _FakeEvSearchState(
        resolved: AsyncValue.data(ServiceResult(
          data: const [],
          source: ServiceSource.openChargeMapApi,
          fetchedAt: DateTime(2024, 1, 1),
        )),
      );
      final container = ProviderContainer(overrides: [
        eVSearchStateProvider.overrideWith(() => fakeEv),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = await dispatchEvIfNeeded(
        ref: ref,
        fuelType: FuelType.e10,
        lat: 48.85,
        lng: 2.35,
        radiusKm: 10,
      );

      expect(result, isNull);
      expect(fakeEv.searchNearbyCalled, isFalse);
    });

    test('electric + EV state resolves to data → wraps as AsyncValue.data',
        () async {
      const station = ChargingStation(
        id: 'cs-1',
        name: 'Demo CP',
        latitude: 48.85,
        longitude: 2.35,
      );
      final fakeEv = _FakeEvSearchState(
        resolved: AsyncValue.data(ServiceResult(
          data: const [station],
          source: ServiceSource.openChargeMapApi,
          fetchedAt: DateTime(2024, 1, 1),
        )),
      );
      final container = ProviderContainer(overrides: [
        eVSearchStateProvider.overrideWith(() => fakeEv),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = await dispatchEvIfNeeded(
        ref: ref,
        fuelType: FuelType.electric,
        lat: 48.85,
        lng: 2.35,
        radiusKm: 7,
      );

      expect(fakeEv.searchNearbyCalled, isTrue);
      expect(fakeEv.lastLat, 48.85);
      expect(fakeEv.lastLng, 2.35);
      expect(fakeEv.lastRadiusKm, 7);
      expect(result, isA<AsyncData<ServiceResult<List<SearchResultItem>>>>());
      final wrapped = result!.value!;
      expect(wrapped.data, hasLength(1));
      expect(wrapped.data.single, isA<EVStationResult>());
      expect((wrapped.data.single as EVStationResult).station.id, 'cs-1');
      expect(wrapped.source, ServiceSource.openChargeMapApi);
    });

    test('electric + EV state resolves to error → wraps as AsyncValue.error',
        () async {
      final boom = Exception('ev down');
      final stack = StackTrace.current;
      final fakeEv = _FakeEvSearchState(
        resolved: AsyncValue.error(boom, stack),
      );
      final container = ProviderContainer(overrides: [
        eVSearchStateProvider.overrideWith(() => fakeEv),
      ]);
      addTearDown(container.dispose);
      final ref = _captureRef(container);

      final result = await dispatchEvIfNeeded(
        ref: ref,
        fuelType: FuelType.electric,
        lat: 0,
        lng: 0,
        radiusKm: 5,
      );

      expect(fakeEv.searchNearbyCalled, isTrue);
      expect(result, isA<AsyncError<ServiceResult<List<SearchResultItem>>>>());
      expect(result!.error, same(boom));
      expect(result.stackTrace, same(stack));
    });
  });
}
