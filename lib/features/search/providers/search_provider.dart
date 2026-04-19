import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/location/location_service.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/utils/geo_utils.dart';
import '../data/models/search_params.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
import '../domain/entities/station.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'ev_search_provider.dart';

part 'search_provider.g.dart';

/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
///
/// Supports three search modes:
/// - [searchByGps] -- uses device GPS to determine coordinates
/// - [searchByZipCode] -- geocodes a postal code, then searches
/// - [searchByCoordinates] -- uses explicit lat/lng (from city search)
///
/// All modes delegate to the country-appropriate [StationService] via
/// the [stationServiceProvider], which applies the full fallback chain
/// (fresh cache -> API -> stale cache -> error).
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

  /// Recalculate station distances from user's known position.
  /// Returns stations with updated dist fields.
  List<Station> _recalcDistances(List<Station> stations) {
    final userPos = ref.read(userPositionProvider);
    if (userPos == null) return stations;

    return stations.map((s) {
      final d = distanceKm(userPos.lat, userPos.lng, s.lat, s.lng);
      return s.copyWith(dist: double.parse(d.toStringAsFixed(1)));
    }).toList();
  }

  /// Auto-update user position from GPS if the setting is enabled.
  Future<void> _autoUpdatePositionIfEnabled() async {
    final profile = ref.read(activeProfileProvider);
    if (profile?.autoUpdatePosition != true) return;

    try {
      await ref.read(userPositionProvider.notifier).updateFromGps();
    } on Exception catch (e) {
      debugPrint('GPS auto-update failed: $e');
    }
  }

  /// Wraps a search operation with standard loading state + error handling.
  Future<void> _runSearch(Future<void> Function(CancelToken cancelToken) search) async {
    state = const AsyncValue.loading();
    final cancelToken = _newCancelToken();
    try {
      await search(cancelToken);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncValue.error(e, StackTrace.current);
    } on ServiceChainExhaustedException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Search for nearby stations using the device's current GPS position.
  ///
  /// Steps:
  /// 1. Request GPS coordinates from [LocationService].
  /// 2. Store the position in [userPositionProvider] for distance calculations.
  /// 3. Reverse-geocode coordinates to extract a postal code (needed by some
  ///    country APIs like Prix-Carburants).
  /// 4. Build [SearchParams] from GPS coords and active profile defaults.
  /// 5. Delegate to [StationService.searchStations] via the fallback chain.
  ///
  /// Falls back to profile defaults for [fuelType], [radiusKm], and [sortBy]
  /// when not explicitly provided.
  Future<void> searchByGps({
    FuelType? fuelType,
    double? radiusKm,
    SortBy? sortBy,
  }) async {
    await _runSearch((cancelToken) async {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      // Auto-capture GPS position as user's known position
      ref.read(userPositionProvider.notifier).setFromGps(
        position.latitude, position.longitude,
      );

      final profile = ref.read(activeProfileProvider);
      // #704 — effective fuel resolves the vehicle-vs-profile hierarchy.
      final FuelType resolvedFuelType =
          fuelType ?? ref.read(effectiveFuelTypeProvider);
      final resolvedRadius = radiusKm ?? profile?.defaultSearchRadius ?? 10.0;

      // EV dispatch: delegate to EVSearchState, then copy wrapped results.
      if (resolvedFuelType == FuelType.electric) {
        await ref.read(eVSearchStateProvider.notifier).searchNearby(
              lat: position.latitude,
              lng: position.longitude,
              radiusKm: resolvedRadius,
            );
        _copyEvResults();
        return;
      }

      // Reverse-geocode GPS to get postal code (used by services like Prix-Carburants)
      String? resolvedPostalCode;
      try {
        final geocoding = ref.read(geocodingChainProvider);
        final addrResult = await geocoding.coordinatesToAddress(
          position.latitude, position.longitude,
          cancelToken: cancelToken,
        );
        final address = addrResult.data;
        // Geocoding returns "34120 Pézenas" format
        final parts = address.split(' ');
        for (final part in parts) {
          if (RegExp(r'^\d{4,5}$').hasMatch(part)) {
            resolvedPostalCode = part;
            break;
          }
        }
        ref.read(searchLocationProvider.notifier).set(address);
      } on Exception catch (e) {
        debugPrint('Reverse geocoding failed: $e');
      }

      final params = SearchParams(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: resolvedRadius,
        fuelType: resolvedFuelType,
        sortBy: sortBy ?? SortBy.price,
        postalCode: resolvedPostalCode,
      );

      final stationService = ref.read(stationServiceProvider);
      final result = await stationService.searchStations(params, cancelToken: cancelToken);
      state = AsyncValue.data(_wrapFuelResult(result));
    });
  }

  /// Search for stations near a postal code.
  ///
  /// Steps:
  /// 1. Geocode [zipCode] to lat/lng via [GeocodingChain].
  /// 2. Reverse-geocode to get a display-friendly city name.
  /// 3. Build [SearchParams] and delegate to the station service.
  /// 4. Recalculate distances from the user's known GPS position
  ///    (if available) so that distances reflect the user's actual
  ///    location, not the ZIP code center.
  /// 5. Merge any geocoding errors into the result's error list.
  ///
  /// Falls back to profile defaults for [fuelType], [radiusKm], and [sortBy]
  /// when not explicitly provided.
  Future<void> searchByZipCode({
    required String zipCode,
    FuelType? fuelType,
    double? radiusKm,
    SortBy? sortBy,
  }) async {
    await _runSearch((cancelToken) async {
      // Auto-update user position if enabled
      await _autoUpdatePositionIfEnabled();

      final geocoding = ref.read(geocodingChainProvider);
      final coordsResult = await geocoding.zipCodeToCoordinates(zipCode, cancelToken: cancelToken);

      final profile = ref.read(activeProfileProvider);
      // #704 — effective fuel resolves the vehicle-vs-profile hierarchy.
      final FuelType resolvedFuelType =
          fuelType ?? ref.read(effectiveFuelTypeProvider);
      final resolvedRadius = radiusKm ?? profile?.defaultSearchRadius ?? 10.0;

      // EV dispatch: geocode the ZIP, then delegate to EVSearchState.
      if (resolvedFuelType == FuelType.electric) {
        await ref.read(eVSearchStateProvider.notifier).searchNearby(
              lat: coordsResult.data.lat,
              lng: coordsResult.data.lng,
              radiusKm: resolvedRadius,
            );
        _copyEvResults();
        return;
      }

      // Resolve city name for display
      String? cityName;
      try {
        final addrResult = await geocoding.coordinatesToAddress(
          coordsResult.data.lat, coordsResult.data.lng,
          cancelToken: cancelToken,
        );
        cityName = addrResult.data;
      } on Exception catch (e) { debugPrint('ZIP reverse geocoding failed: $e'); }

      // Show resolved location in UI
      ref.read(searchLocationProvider.notifier).set(
        '$zipCode ${cityName ?? ''}'.trim(),
      );

      final params = SearchParams(
        lat: coordsResult.data.lat,
        lng: coordsResult.data.lng,
        radiusKm: resolvedRadius,
        fuelType: resolvedFuelType,
        sortBy: sortBy ?? SortBy.price,
        postalCode: zipCode,
        locationName: '$zipCode ${cityName ?? ''}'.trim(),
      );

      final stationService = ref.read(stationServiceProvider);
      final result = await stationService.searchStations(params, cancelToken: cancelToken);

      // Recalculate distances from user's known position
      final adjustedStations = _recalcDistances(result.data);

      // Merge geocoding errors into station result
      final mergedErrors = [
        ...coordsResult.errors,
        ...result.errors,
      ];

      state = AsyncValue.data(_wrapFuelResult(ServiceResult(
        data: adjustedStations,
        source: result.source,
        fetchedAt: result.fetchedAt,
        isStale: result.isStale || coordsResult.isStale,
        errors: mergedErrors,
      )));
    });
  }

  /// Search for stations at exact coordinates with an optional postal code.
  ///
  /// Used by the city name search flow where Nominatim has already resolved
  /// coordinates. Also useful for map-tap searches.
  ///
  /// Recalculates distances from the user's known GPS position (if available)
  /// so the displayed distances reflect how far the user actually is, not the
  /// distance from the search center.
  Future<void> searchByCoordinates({
    required double lat,
    required double lng,
    String? postalCode,
    String? locationName,
    FuelType? fuelType,
    double? radiusKm,
  }) async {
    await _runSearch((cancelToken) async {
      // Auto-update user position if enabled
      await _autoUpdatePositionIfEnabled();

      if (locationName != null) {
        ref.read(searchLocationProvider.notifier).set(locationName);
      }

      final profile = ref.read(activeProfileProvider);
      // #704 — effective fuel resolves the vehicle-vs-profile hierarchy.
      final FuelType resolvedFuelType =
          fuelType ?? ref.read(effectiveFuelTypeProvider);
      final resolvedRadius = radiusKm ?? profile?.defaultSearchRadius ?? 10.0;

      // EV dispatch: delegate to EVSearchState with the explicit coordinates.
      if (resolvedFuelType == FuelType.electric) {
        await ref.read(eVSearchStateProvider.notifier).searchNearby(
              lat: lat,
              lng: lng,
              radiusKm: resolvedRadius,
            );
        _copyEvResults();
        return;
      }

      final params = SearchParams(
        lat: lat,
        lng: lng,
        radiusKm: resolvedRadius,
        fuelType: resolvedFuelType,
        postalCode: postalCode,
        locationName: locationName,
      );

      final stationService = ref.read(stationServiceProvider);
      final result = await stationService.searchStations(params, cancelToken: cancelToken);

      // Recalculate distances from user's known position
      final adjustedStations = _recalcDistances(result.data);

      state = AsyncValue.data(_wrapFuelResult(ServiceResult(
        data: adjustedStations,
        source: result.source,
        fetchedAt: result.fetchedAt,
        isStale: result.isStale,
        errors: result.errors,
      )));
    });
  }

  /// Wraps a fuel [ServiceResult<List<Station>>] as [List<SearchResultItem>].
  ServiceResult<List<SearchResultItem>> _wrapFuelResult(
    ServiceResult<List<Station>> result,
  ) {
    return ServiceResult(
      data: result.data.map((s) => FuelStationResult(s) as SearchResultItem).toList(),
      source: result.source,
      fetchedAt: result.fetchedAt,
      isStale: result.isStale,
      errors: result.errors,
    );
  }

  /// Copies EVSearchState results into this provider's state, wrapped as
  /// [EVStationResult]. Called after [EVSearchState.searchNearby] completes.
  void _copyEvResults() {
    final evState = ref.read(eVSearchStateProvider);
    evState.when(
      data: (result) {
        state = AsyncValue.data(ServiceResult(
          data: result.data.map((cs) => EVStationResult(cs) as SearchResultItem).toList(),
          source: result.source,
          fetchedAt: result.fetchedAt,
        ));
      },
      loading: () {},
      error: (e, st) { state = AsyncValue.error(e, st); },
    );
  }
}

/// Stores the resolved search location for display (ZIP + city).
@riverpod
class SearchLocation extends _$SearchLocation {
  @override
  String build() => '';

  void set(String location) => state = location;
}

@riverpod
class SelectedFuelType extends _$SelectedFuelType {
  @override
  FuelType build() {
    // Effective fuel (#704): when a profile is configured, the default
    // vehicle's fuel overrides the profile's own preferredFuelType so
    // the chips reflect "what does my car actually take" without the
    // user having to keep profile + vehicle manually in sync.
    //
    // No profile yet (fresh install, before the onboarding wizard) →
    // keep the historical "FuelType.all" wildcard so the first search
    // doesn't silently filter out non-E10 pumps.
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) return FuelType.all;
    return ref.watch(effectiveFuelTypeProvider);
  }

  void select(FuelType type) {
    state = type;
  }
}

@riverpod
class SearchRadius extends _$SearchRadius {
  @override
  double build() {
    final profile = ref.watch(activeProfileProvider);
    return profile?.defaultSearchRadius ?? 10.0;
  }

  void set(double radius) {
    state = radius.clamp(1.0, 25.0);
  }
}

/// Extracts fuel [Station] objects from the unified search results.
///
/// Convenience for consumers that need [List<Station>] (cross-border
/// comparisons, driving mode, station detail lookup, brand filter chips).
@riverpod
List<Station> fuelStations(Ref ref) {
  final searchState = ref.watch(searchStateProvider);
  if (!searchState.hasValue) return const [];
  return searchState.value!.data
      .whereType<FuelStationResult>()
      .map((r) => r.station)
      .toList();
}
