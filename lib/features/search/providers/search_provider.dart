import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/location/location_service.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../data/models/search_params.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
// #727 — SearchState reads `searchLocationProvider` so we import
// filters_provider directly (re-exports don't surface symbols here).
import 'search_filters_provider.dart';
import 'search_provider_orchestration.dart';
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
/// `search_result_helpers.dart`; orchestration helpers (EV dispatch,
/// fuel/radius resolution, error classification, GPS auto-update)
/// live in `search_provider_orchestration.dart`. This file keeps only
/// the public search entry points + state mutation.
@riverpod
class SearchState extends _$SearchState {
  CancelToken? _activeCancelToken;

  /// Replays the most recently issued search. `null` until the user has
  /// run at least one search. Used by [repeatLastSearch], which lets
  /// observers (e.g. MapScreen's app-resume handler, #1268) refresh
  /// stale data without knowing which search-by-X variant was invoked.
  Future<void> Function()? _lastSearchReplay;

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

  /// Re-runs the most recent search (whichever entry point — GPS, ZIP,
  /// coordinates) with the same parameters. No-op if no search has run
  /// yet or one is already in flight.
  ///
  /// Used by [MapScreen] to refresh stale tile + price data when the
  /// app returns from background after >10 s (#1268). Returns the same
  /// future the underlying search returns, or a completed future when
  /// no replay is available.
  Future<void> repeatLastSearch() async {
    final replay = _lastSearchReplay;
    if (replay == null) return;
    if (state.isLoading) return;
    await replay();
  }

  /// Wraps a search closure with standard loading state + error
  /// handling. Cancellations are silently dropped; every other
  /// exception flows into [AsyncValue.error] via [classifySearchError]
  /// so the UI can surface a fallback summary.
  Future<void> _runSearch(
    Future<void> Function(CancelToken cancelToken) search,
  ) async {
    state = const AsyncValue.loading();
    final cancelToken = _newCancelToken();
    try {
      await search(cancelToken);
    } catch (e, st) {
      final classified = classifySearchError(e, st);
      if (classified != null) state = classified;
    }
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
    _lastSearchReplay = () => searchByGps(
          fuelType: fuelType,
          radiusKm: radiusKm,
          sortBy: sortBy,
        );
    await _runSearch((cancelToken) async {
      final position =
          await ref.read(locationServiceProvider).getCurrentPosition();
      ref.read(userPositionProvider.notifier).setFromGps(
            position.latitude, position.longitude,
          );

      final resolved = resolveFuelAndRadius(ref, fuelType, radiusKm);
      final ev = await dispatchEvIfNeeded(
        ref: ref,
        fuelType: resolved.fuelType,
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: resolved.radiusKm,
      );
      if (ev != null) { state = ev; return; }

      // Reverse-geocode for a postal code (Prix-Carburants + co).
      final addr = await tryReverseGeocode(
        ref.read(geocodingChainProvider),
        position.latitude, position.longitude,
        cancelToken: cancelToken,
      );
      String? resolvedPostalCode;
      if (addr != null) {
        resolvedPostalCode = extractPostalCode(addr);
        ref.read(searchLocationProvider.notifier).set(addr);
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
    _lastSearchReplay = () => searchByZipCode(
          zipCode: zipCode,
          fuelType: fuelType,
          radiusKm: radiusKm,
          sortBy: sortBy,
        );
    await _runSearch((cancelToken) async {
      await autoUpdatePositionIfEnabled(ref);
      final geocoding = ref.read(geocodingChainProvider);
      final coordsResult = await geocoding.zipCodeToCoordinates(
        zipCode, cancelToken: cancelToken,
      );

      final resolved = resolveFuelAndRadius(ref, fuelType, radiusKm);
      final ev = await dispatchEvIfNeeded(
        ref: ref,
        fuelType: resolved.fuelType,
        lat: coordsResult.data.lat,
        lng: coordsResult.data.lng,
        radiusKm: resolved.radiusKm,
      );
      if (ev != null) { state = ev; return; }

      final cityName = await tryReverseGeocode(
        geocoding, coordsResult.data.lat, coordsResult.data.lng,
        cancelToken: cancelToken,
      );

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
    _lastSearchReplay = () => searchByCoordinates(
          lat: lat,
          lng: lng,
          postalCode: postalCode,
          locationName: locationName,
          fuelType: fuelType,
          radiusKm: radiusKm,
        );
    await _runSearch((cancelToken) async {
      await autoUpdatePositionIfEnabled(ref);
      if (locationName != null) {
        ref.read(searchLocationProvider.notifier).set(locationName);
      }

      final resolved = resolveFuelAndRadius(ref, fuelType, radiusKm);
      final ev = await dispatchEvIfNeeded(
        ref: ref,
        fuelType: resolved.fuelType,
        lat: lat,
        lng: lng,
        radiusKm: resolved.radiusKm,
      );
      if (ev != null) { state = ev; return; }

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
}
