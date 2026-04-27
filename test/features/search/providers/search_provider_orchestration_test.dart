import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/providers/search_provider_orchestration.dart';

/// Coverage for orchestration helpers extracted from `search_provider.dart`
/// (#563): pure error classifier, reverse-geocode wrapper, fuel/radius
/// resolution, and the GPS auto-update side-effect dispatcher.
///
/// `dispatchEvIfNeeded` is intentionally only covered for the non-electric
/// short-circuit path — the electric path requires a fully wired EV provider
/// stack and adds no orchestration coverage beyond the short-circuit branch.
///
/// The Ref-taking helpers are exercised by wrapping them in throwaway
/// `Provider`s; reading the provider runs the helper with a real Ref.

// ─── Fakes ────────────────────────────────────────────────────────────────

/// Records calls to [coordinatesToAddress] so tests can verify cancel-token
/// threading. The other [GeocodingChain] methods are unused by
/// [tryReverseGeocode] and intentionally throw to flag accidental calls.
class _FakeGeocodingChain implements GeocodingChain {
  final ServiceResult<String>? _result;
  final Object? _error;

  CancelToken? lastCancelToken;
  int callCount = 0;

  _FakeGeocodingChain.success(this._result) : _error = null;
  _FakeGeocodingChain.failure(this._error) : _result = null;

  @override
  Future<ServiceResult<String>> coordinatesToAddress(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) async {
    callCount++;
    lastCancelToken = cancelToken;
    if (_error != null) {
      // ignore: only_throw_errors
      throw _error;
    }
    return _result!;
  }

  @override
  Future<ServiceResult<({double lat, double lng})>> zipCodeToCoordinates(
    String zipCode, {
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError('not used by tryReverseGeocode');

  @override
  Future<String?> coordinatesToCountryCode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError('not used by tryReverseGeocode');
}

class _NullProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}

class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile _profile;

  @override
  UserProfile? build() => _profile;
}

/// UserPosition double that records `updateFromGps()` invocations and lets
/// tests opt into a thrown exception (to exercise the swallow-and-debugPrint
/// branch of [autoUpdatePositionIfEnabled]).
class _RecordingUserPosition extends UserPosition {
  _RecordingUserPosition({this.throwOnUpdate});

  final Object? throwOnUpdate;
  int updateCallCount = 0;

  @override
  UserPositionData? build() => null;

  @override
  Future<void> updateFromGps() async {
    updateCallCount++;
    if (throwOnUpdate != null) {
      // ignore: only_throw_errors
      throw throwOnUpdate!;
    }
  }
}

void main() {
  group('classifySearchError', () {
    final stack = StackTrace.current;

    test('DioException with type cancel returns null', () {
      final err = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(),
      );

      final result = classifySearchError(err, stack);

      expect(result, isNull);
    });

    test(
        'DioException with type connectionTimeout returns AsyncValue.error '
        'preserving error and stackTrace', () {
      final err = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(),
      );

      final result = classifySearchError(err, stack);

      expect(result, isA<AsyncError>());
      expect(result!.error, same(err));
      expect(result.stackTrace, same(stack));
    });

    test(
        'DioException with type badResponse returns AsyncValue.error', () {
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(),
      );

      final result = classifySearchError(err, stack);

      expect(result, isA<AsyncError>());
      expect(result!.error, same(err));
    });

    test(
        'ServiceChainExhaustedException returns AsyncValue.error '
        'preserving the exception', () {
      const err = ServiceChainExhaustedException(errors: []);

      final result = classifySearchError(err, stack);

      expect(result, isA<AsyncError>());
      expect(result!.error, same(err));
      expect(result.stackTrace, same(stack));
    });

    test('generic Exception falls through to AsyncValue.error', () {
      final err = Exception('boom');

      final result = classifySearchError(err, stack);

      expect(result, isA<AsyncError>());
      expect(result!.error, same(err));
    });

    test(
        'non-Exception Object (StateError) still wrapped via fallback '
        'branch', () {
      final err = StateError('bad state');

      final result = classifySearchError(err, stack);

      expect(result, isA<AsyncError>());
      expect(result!.error, same(err));
      expect(result.stackTrace, same(stack));
    });
  });

  group('tryReverseGeocode', () {
    test('success returns the address from the ServiceResult', () async {
      final fake = _FakeGeocodingChain.success(
        ServiceResult<String>(
          data: '34120 Pézenas',
          source: ServiceSource.nominatimGeocoding,
          fetchedAt: DateTime.now(),
        ),
      );

      final addr = await tryReverseGeocode(fake, 43.46, 3.42);

      expect(addr, '34120 Pézenas');
      expect(fake.callCount, 1);
    });

    test('Exception is swallowed and null is returned', () async {
      final fake = _FakeGeocodingChain.failure(Exception('network'));

      final addr = await tryReverseGeocode(fake, 43.46, 3.42);

      expect(addr, isNull);
      expect(fake.callCount, 1);
    });

    test('DioException is also swallowed (it is an Exception subtype)',
        () async {
      final fake = _FakeGeocodingChain.failure(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ),
      );

      final addr = await tryReverseGeocode(fake, 43.46, 3.42);

      expect(addr, isNull);
    });

    test('cancelToken is forwarded to the geocoder', () async {
      final fake = _FakeGeocodingChain.success(
        ServiceResult<String>(
          data: 'Paris',
          source: ServiceSource.nominatimGeocoding,
          fetchedAt: DateTime.now(),
        ),
      );
      final token = CancelToken();

      await tryReverseGeocode(fake, 48.85, 2.35, cancelToken: token);

      expect(fake.lastCancelToken, same(token));
    });
  });

  group('resolveFuelAndRadius', () {
    /// Reads a one-shot probe Provider that wraps [resolveFuelAndRadius]
    /// against [container]. Keeps each test focused on the args it cares
    /// about.
    ({FuelType fuelType, double radiusKm}) readResolve(
      ProviderContainer container, {
      FuelType? fuelType,
      double? radiusKm,
    }) {
      final probe = Provider<({FuelType fuelType, double radiusKm})>(
        (ref) => resolveFuelAndRadius(ref, fuelType, radiusKm),
      );
      return container.read(probe);
    }

    test(
        'explicit fuelType + radiusKm override profile and effective fuel',
        () {
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedProfile(
              const UserProfile(
                id: 'p1',
                name: 'p1',
                defaultSearchRadius: 7.5,
                preferredFuelType: FuelType.e10,
              ),
            )),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
      ]);
      addTearDown(c.dispose);

      final result = readResolve(c,
          fuelType: FuelType.diesel, radiusKm: 12.0);

      expect(result.fuelType, FuelType.diesel);
      expect(result.radiusKm, 12.0);
    });

    test(
        'both nulls + profile present → falls back to '
        'effectiveFuelTypeProvider and profile.defaultSearchRadius', () {
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedProfile(
              const UserProfile(
                id: 'p1',
                name: 'p1',
                defaultSearchRadius: 5.0,
              ),
            )),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
      ]);
      addTearDown(c.dispose);

      final result = readResolve(c);

      expect(result.fuelType, FuelType.diesel);
      expect(result.radiusKm, 5.0);
    });

    test(
        'both nulls + profile null → falls back to '
        'effectiveFuelTypeProvider and 10.0 km default', () {
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _NullProfile()),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e5),
      ]);
      addTearDown(c.dispose);

      final result = readResolve(c);

      expect(result.fuelType, FuelType.e5);
      expect(result.radiusKm, 10.0);
    });

    test(
        'explicit radiusKm only → keeps the override and still '
        'resolves fuel from effectiveFuelTypeProvider', () {
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _NullProfile()),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
      ]);
      addTearDown(c.dispose);

      final result = readResolve(c, radiusKm: 3.0);

      expect(result.fuelType, FuelType.diesel);
      expect(result.radiusKm, 3.0);
    });
  });

  group('autoUpdatePositionIfEnabled', () {
    /// Reads a probe FutureProvider that runs [autoUpdatePositionIfEnabled]
    /// against [container].
    Future<void> readAutoUpdate(ProviderContainer container) {
      final probe = FutureProvider<void>(
        (ref) async => autoUpdatePositionIfEnabled(ref),
      );
      return container.read(probe.future);
    }

    test('no active profile → no-op (updateFromGps not called)', () async {
      final pos = _RecordingUserPosition();
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _NullProfile()),
        userPositionProvider.overrideWith(() => pos),
      ]);
      addTearDown(c.dispose);

      await readAutoUpdate(c);

      expect(pos.updateCallCount, 0);
    });

    test('profile.autoUpdatePosition: false → no-op', () async {
      final pos = _RecordingUserPosition();
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedProfile(
              const UserProfile(
                id: 'p1',
                name: 'p1',
                // autoUpdatePosition defaults to false
              ),
            )),
        userPositionProvider.overrideWith(() => pos),
      ]);
      addTearDown(c.dispose);

      await readAutoUpdate(c);

      expect(pos.updateCallCount, 0);
    });

    test('profile.autoUpdatePosition: true → updateFromGps called once',
        () async {
      final pos = _RecordingUserPosition();
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedProfile(
              const UserProfile(
                id: 'p1',
                name: 'p1',
                autoUpdatePosition: true,
              ),
            )),
        userPositionProvider.overrideWith(() => pos),
      ]);
      addTearDown(c.dispose);

      await readAutoUpdate(c);

      expect(pos.updateCallCount, 1);
    });

    test('updateFromGps throwing Exception is swallowed (no rethrow)',
        () async {
      final pos = _RecordingUserPosition(
        throwOnUpdate: Exception('GPS unavailable'),
      );
      final c = ProviderContainer(overrides: [
        activeProfileProvider.overrideWith(() => _FixedProfile(
              const UserProfile(
                id: 'p1',
                name: 'p1',
                autoUpdatePosition: true,
              ),
            )),
        userPositionProvider.overrideWith(() => pos),
      ]);
      addTearDown(c.dispose);

      // Must not throw — the helper logs via debugPrint and continues so
      // the search can still proceed without GPS.
      await readAutoUpdate(c);

      expect(pos.updateCallCount, 1);
    });
  });

  group('dispatchEvIfNeeded', () {
    /// Reads a probe that runs [dispatchEvIfNeeded] for [fuelType] against
    /// [container]. `eVSearchStateProvider` is intentionally NOT overridden
    /// so any accidental read on the non-electric branch would explode.
    Future<AsyncValue<ServiceResult<dynamic>>?> readDispatch(
      ProviderContainer container, {
      required FuelType fuelType,
    }) {
      final probe = FutureProvider<AsyncValue<ServiceResult<dynamic>>?>(
        (ref) async => dispatchEvIfNeeded(
          ref: ref,
          fuelType: fuelType,
          lat: 48.85,
          lng: 2.35,
          radiusKm: 5.0,
        ),
      );
      return container.read(probe.future);
    }

    test(
        'non-electric fuel returns null without touching '
        'eVSearchStateProvider', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      final result = await readDispatch(c, fuelType: FuelType.diesel);

      expect(result, isNull);
    });

    test('non-electric fuel (e10) also returns null', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      final result = await readDispatch(c, fuelType: FuelType.e10);

      expect(result, isNull);
    });

    test('non-electric fuel (FuelType.all) also returns null', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      final result = await readDispatch(c, fuelType: FuelType.all);

      expect(result, isNull);
    });
  });
}
