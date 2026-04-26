import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/location/location_service.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../data/models/search_params.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'ev_search_provider.dart';
// #727 — SearchState reads `searchLocationProvider` so we import
// filters_provider directly (re-exports don't surface symbols here).
import 'search_filters_provider.dart';
import 'search_result_helpers.dart';

// #727 — re-export so `import 'search_provider.dart'` keeps resolving
// `SearchLocation`, `SelectedFuelType`, `SearchRadius`, `fuelStations`.
export 'search_filters_provider.dart';

part 'search_provider.g.dart';

/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
/// Supports three search modes: [searchByGps], [searchByZipCode],
/// [searchByCoordinates]. All modes delegate to the country-appropriate
/// [StationService] via [stationServiceProvider] (fresh cache → API →
/// stale cache → error).
///
/// Pure helpers (result wrapping, distance recalc, postal-code
/// extraction, geocoding-error merging) live in
/// `search_result_helpers.dart`; this file keeps the stateful
/// orchestration (cancel tokens, profile lookups, state mutation).
@riverpod
class SearchState extends _$SearchState {
  CancelToken? _activeCancelToken;

  /// Cancel any in-flight search and create a fresh [CancelToken].
  CancelToken _newCancelToken() {
    final old = _activeCancelToken;
    final fresh = CancelToken();
    _activeCancelToken = fresh;
    old?.cancel('New search started');
    return fresh;
  }

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }

  /// Auto-update user position from GPS if the setting is enabled.
  Future<void> _autoUpdatePositionIfEnabled() async {
    if (ref.read(activeProfileProvider)?.autoUpdatePosition != true) return;
    try {
      await ref.read(userPositionProvider.notifier).updateFromGps();
    } on Exception catch (e, st) {
      debugPrint('GPS auto-update failed: $e\n$st');
    }
  }

  /// Wraps a search operation with standard loading state + error handling.
  Future<void> _runSearch(Future<void> Function(CancelToken cancelToken) search) async {
    state = const AsyncValue.loading();
    final cancelToken = _newCancelToken();
    try {
      await search(cancelToken);
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncValue.error(e, st);
    } on ServiceChainExhaustedException catch (e, st) {
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Resolves the effective fuel + radius: honour explicit overrides,
  /// otherwise fall back to the active profile's effective fuel (#704)
  /// and default radius.
  ({FuelType fuelType, double radiusKm}) _resolveFuelAndRadius(
      FuelType? fuelType, double? radiusKm) {
    final profile = ref.read(activeProfileProvider);
    return (
      fuelType: fuelType ?? ref.read(effectiveFuelTypeProvider),
      radiusKm: radiusKm ?? profile?.defaultSearchRadius ?? 10.0,
    );
  }

  /// If [fuelType] is EV, delegate to [EVSearchState] and copy the
  /// wrapped result into this provider's state. Returns `true` when
  /// dispatched so callers can early-return before the fuel path.
  Future<bool> _maybeDispatchEv({
    required FuelType fuelType,
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    if (fuelType != FuelType.electric) return false;
    await ref
        .read(eVSearchStateProvider.notifier)
        .searchNearby(lat: lat, lng: lng, radiusKm: radiusKm);
    _copyEvResults();
    return true;
  }

  /// Search for nearby stations using the device's current GPS position.
  /// Stores the position in [userPositionProvider], reverse-geocodes to
  /// extract a postal code (needed by Prix-Carburants etc.), then
  /// delegates to [StationService.searchStations]. Missing params fall
  /// back to the active profile's defaults.
  Future<void> searchByGps({
    FuelType? fuelType,
    double? radiusKm,
    SortBy? sortBy,
  }) async {
    await _runSearch((cancelToken) async {
      final position =
          await ref.read(locationServiceProvider).getCurrentPosition();
      ref.read(userPositionProvider.notifier).setFromGps(
            position.latitude, position.longitude,
          );

      final resolved = _resolveFuelAndRadius(fuelType, radiusKm);
      if (await _maybeDispatchEv(
        fuelType: resolved.fuelType,
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: resolved.radiusKm,
      )) {
        return;
      }

      // Reverse-geocode for a postal code (Prix-Carburants + co).
      String? resolvedPostalCode;
      try {
        final addrResult =
            await ref.read(geocodingChainProvider).coordinatesToAddress(
                  position.latitude, position.longitude,
                  cancelToken: cancelToken,
                );
        resolvedPostalCode = extractPostalCode(addrResult.data);
        ref.read(searchLocationProvider.notifier).set(addrResult.data);
      } on Exception catch (e, st) {
        debugPrint('Reverse geocoding failed: $e\n$st');
      }

      final params = SearchParams(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: resolved.radiusKm,
        fuelType: resolved.fuelType,
        sortBy: sortBy ?? SortBy.price,
        postalCode: resolvedPostalCode,
      );
      final result = await ref
          .read(stationServiceProvider)
          .searchStations(params, cancelToken: cancelToken);
      state = AsyncValue.data(wrapFuelResultAsSearchItems(result));
    });
  }

  /// Search for stations near a postal code. Geocodes [zipCode] via
  /// [GeocodingChain], reverse-geocodes for a city label, delegates to
  /// the station service, recalculates distances from the user's
  /// known GPS position, and merges geocoding errors/staleness into
  /// the final [ServiceResult].
  Future<void> searchByZipCode({
    required String zipCode,
    FuelType? fuelType,
    double? radiusKm,
    SortBy? sortBy,
  }) async {
    await _runSearch((cancelToken) async {
      await _autoUpdatePositionIfEnabled();
      final geocoding = ref.read(geocodingChainProvider);
      final coordsResult = await geocoding.zipCodeToCoordinates(
        zipCode, cancelToken: cancelToken,
      );

      final resolved = _resolveFuelAndRadius(fuelType, radiusKm);
      if (await _maybeDispatchEv(
        fuelType: resolved.fuelType,
        lat: coordsResult.data.lat,
        lng: coordsResult.data.lng,
        radiusKm: resolved.radiusKm,
      )) {
        return;
      }

      String? cityName;
      try {
        final addrResult = await geocoding.coordinatesToAddress(
          coordsResult.data.lat, coordsResult.data.lng,
          cancelToken: cancelToken,
        );
        cityName = addrResult.data;
      } on Exception catch (e, st) {
        debugPrint('ZIP reverse geocoding failed: $e\n$st');
      }

      final locationLabel = '$zipCode ${cityName ?? ''}'.trim();
      ref.read(searchLocationProvider.notifier).set(locationLabel);

      final params = SearchParams(
        lat: coordsResult.data.lat,
        lng: coordsResult.data.lng,
        radiusKm: resolved.radiusKm,
        fuelType: resolved.fuelType,
        sortBy: sortBy ?? SortBy.price,
        postalCode: zipCode,
        locationName: locationLabel,
      );
      final result = await ref
          .read(stationServiceProvider)
          .searchStations(params, cancelToken: cancelToken);

      final adjustedStations =
          recalcDistancesFrom(result.data, ref.read(userPositionProvider));

      state = AsyncValue.data(wrapFuelResultAsSearchItems(
        mergeGeocodingIntoStationResult(
          stationResult: result,
          geocodingErrors: coordsResult.errors,
          geocodingIsStale: coordsResult.isStale,
          adjustedStations: adjustedStations,
        ),
      ));
    });
  }

  /// Search for stations at exact coordinates with an optional postal
  /// code. Used by the city-name flow (Nominatim already resolved
  /// coordinates) and map-tap searches. Recalculates distances from
  /// the user's known position, not the search center.
  Future<void> searchByCoordinates({
    required double lat,
    required double lng,
    String? postalCode,
    String? locationName,
    FuelType? fuelType,
    double? radiusKm,
  }) async {
    await _runSearch((cancelToken) async {
      await _autoUpdatePositionIfEnabled();
      if (locationName != null) {
        ref.read(searchLocationProvider.notifier).set(locationName);
      }

      final resolved = _resolveFuelAndRadius(fuelType, radiusKm);
      if (await _maybeDispatchEv(
        fuelType: resolved.fuelType,
        lat: lat,
        lng: lng,
        radiusKm: resolved.radiusKm,
      )) {
        return;
      }

      final params = SearchParams(
        lat: lat,
        lng: lng,
        radiusKm: resolved.radiusKm,
        fuelType: resolved.fuelType,
        postalCode: postalCode,
        locationName: locationName,
      );
      final result = await ref
          .read(stationServiceProvider)
          .searchStations(params, cancelToken: cancelToken);
      final adjustedStations =
          recalcDistancesFrom(result.data, ref.read(userPositionProvider));

      state = AsyncValue.data(
        wrapFuelResultAsSearchItems(withStations(result, adjustedStations)),
      );
    });
  }

  /// Copies EVSearchState results into this provider's state, wrapped
  /// as [EVStationResult]. Called after [EVSearchState.searchNearby].
  void _copyEvResults() {
    ref.read(eVSearchStateProvider).when(
          data: (r) =>
              state = AsyncValue.data(wrapEvResultAsSearchItems(r)),
          loading: () {},
          error: (e, st) => state = AsyncValue.error(e, st),
        );
  }
}
