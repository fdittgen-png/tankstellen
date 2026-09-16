// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/search_params.dart';
import '../domain/station.dart';
import '../background/provider_request_budget.dart';
import '../cache/cache_manager.dart';
import 'diagnostics/data_access_event.dart';
import 'diagnostics/data_access_recorder.dart';
import 'fuel_service_policy.dart';
import 'mixins/station_service_helpers.dart';
import 'non_fuel_station_guard.dart';
import 'service_result.dart';
import 'station_service.dart';
import 'chain_executor.dart';
import 'station_service_chain_codec.dart';
import 'station_transient_retry.dart';

part 'station_service_chain_coalescing.dart';

/// Orchestrates station data retrieval with fallback:
///
///   1. Fresh cache (< TTL) → return immediately (skip API)
///   2. Primary API → cache result, return
///   3. Stale cache (any age) → return with isStale=true
///   4. All failed → throw ServiceChainExhaustedException
///
/// Accumulated errors from each step are attached to the result,
/// so the UI can show what went wrong even when data was served.
///
/// ### Bulk-vs-polled search caching (#2264)
///
/// [searchStations] branches on the source's [FuelServicePolicy.model]:
///
///  - [SourceModel.polledApi] — each search is an upstream request, so the
///    result is cached per `search:<country>:<lat>:<lng>:<radius>:<fuel>` key
///    with the policy's `searchResultTtl` (the historical behaviour).
///  - [SourceModel.bulkFile] — the primary already holds the whole-country
///    dataset and local-filters it, so a per-search-key cache only duplicates
///    that work and can serve a stale slice of a fresh dataset. The chain
///    answers nearby directly from the primary (still coalesced + transient-
///    retried), and the dataset's own freshness is governed by the persisted
///    dataset cache (concern 3), not by a per-key Hive entry.
///
/// When no policy is supplied (legacy call sites + most chain unit tests) the
/// chain defaults to the polled path with [CacheTtl.stationSearch], so its
/// observable behaviour is unchanged.
class StationServiceChain with _ChainCoalescing implements StationService {
  @override
  final StationService _primary;
  final CacheStrategy _cache;
  final ServiceSource _errorSource;
  @override
  final String countryCode;

  /// Data-source policy (#2264). Controls whether [searchStations] uses the
  /// per-key TTL cache (polled) or local-filters a bulk dataset (bulkFile),
  /// and supplies the per-key TTL for polled sources. Null → polled defaults.
  final FuelServicePolicy? _policy;

  /// Dev-only data-access tracer (#2824). Null in production (the default), in
  /// which case every `recordDataAccess` call is a single null-check early
  /// return — the chain's only added cost. When a developer arms
  /// `Feature.debugMode` the registry hands a live recorder here and the
  /// network-vs-cache outcome of each access is recorded for the rate-limit
  /// compliance + cache-hit-ratio export.
  @override
  final DataAccessRecorder? _recorder;

  /// Shared foreground+background per-provider request budget (#2866). When
  /// supplied, the chain stamps [ProviderRequestBudget.recordRequest] for this
  /// [countryCode] on every successful upstream (`networkApi`) request, so the
  /// next background scan can see that the foreground just hit this provider
  /// and skip it within its `minInterval`. Null for the legacy call sites /
  /// unit tests that don't wire a budget — then no stamp is written.
  @override
  final ProviderRequestBudget? _budget;

  StationServiceChain(this._primary, this._cache, {
    this._errorSource = ServiceSource.tankerkoenigApi,
    this.countryCode = '',
    this._policy,
    this._recorder,
    this._budget,
  });

  /// Generic cache-through + request coalescing.
  ///
  ///   1. Return coalesced in-flight request if one exists for [cacheKey]
  ///   2. Fresh cache (< TTL) → return immediately
  ///   3. API call → cache result, return
  ///   4. Stale cache (any age) → return with isStale=true
  ///   5. All failed → throw ServiceChainExhaustedException
  Future<ServiceResult<T>> _throughChain<T>({
    required String cacheKey,
    required DataAccessEndpoint endpoint,
    required Future<ServiceResult<T>> Function() apiCall,
    required Map<String, dynamic> Function(T data) serialize,
    required T? Function(Map<String, dynamic> data) deserialize,
    required Duration ttl,
    bool Function(T data)? isValid,
  }) async {
    // Evict any stale in-flight entries that were not cleaned up
    _evictStaleInFlight();

    // Coalesce: if an identical request is already in-flight, await it
    if (_inFlight.containsKey(cacheKey)) {
      final result = await _inFlight[cacheKey]!;
      if (result.data is T) {
        recordDataAccess(_recorder, countryCode, endpoint,
            DataAccessHit.coalesced, result.source,
            count: dataAccessResultCount(result.data), isStale: result.isStale);
        return result.withData<T>(result.data as T);
      }
      // Type mismatch from coalesced result — fall through to fresh request
    }

    final future = ChainExecutor(
      cache: _cache,
      countryCode: countryCode,
      errorSource: _errorSource,
      recorder: _recorder,
      budget: _budget,
    ).execute<T>(
      stalePaintDeadline: stalePaintDeadline,
      cacheKey: cacheKey,
      endpoint: endpoint,
      apiCall: apiCall,
      serialize: serialize,
      deserialize: deserialize,
      ttl: ttl,
      isValid: isValid,
    );
    _inFlight[cacheKey] = future;
    _inFlightTimestamps[cacheKey] = DateTime.now();
    try {
      return await future;
    } finally {
      // The removed value is the same Future we already awaited above —
      // discard it explicitly so the analyzer doesn't flag it as a fire-
      // and-forget call.
      unawaited(_inFlight.remove(cacheKey) ?? Future<void>.value());
      _inFlightTimestamps.remove(cacheKey);
    }
  }


  /// #3668 — first-paint deadline for the stale race: when a servable
  /// stale entry exists, the API call gets this long to answer before
  /// the stale entry is served and the fetch continues in the
  /// background. 2 s keeps a fast network fresh-first while capping the
  /// startup skeleton; mutable for tests (pattern of
  /// [transientRetryDelay]).
  @visibleForTesting
  static Duration stalePaintDeadline = const Duration(seconds: 2);

  /// Delay between the first and second attempt of the in-chain transient
  /// retry. Re-exports the single source of truth in
  /// `station_transient_retry.dart` (#2842) so the existing test surface
  /// (`StationServiceChain.transientRetryDelay = …`) keeps working unchanged.
  @visibleForTesting
  static Duration get transientRetryDelay => stationTransientRetryDelay;

  @visibleForTesting
  static set transientRetryDelay(Duration value) =>
      stationTransientRetryDelay = value;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    // #2264 — bulk-file sources local-filter a persisted whole-country
    // dataset, so a per-search-key cache only duplicates that work and can
    // serve a stale slice; answer nearby straight from the primary instead.
    final result = (_policy?.isBulkFile ?? false)
        ? await _bulkSearch(params, cancelToken: cancelToken)
        : await _throughChain<List<Station>>(
            cacheKey: CacheKey.stationSearch(
              params.lat, params.lng, params.radiusKm, params.fuelType.apiValue,
              countryCode: countryCode,
              postalCode: params.postalCode,
              locationName: params.locationName,
            ),
            endpoint: params.postalCode != null
                ? DataAccessEndpoint.searchPostcode
                : DataAccessEndpoint.searchGeo,
            apiCall: () =>
                _primary.searchStations(params, cancelToken: cancelToken),
            serialize: serializeStationList,
            deserialize: deserializeStationList,
            // Polled sources use the policy's per-key TTL; fall back to the
            // global default for legacy call sites that supply no policy.
            ttl: _policy?.searchResultTtl ?? CacheTtl.stationSearch,
            isValid: (stations) => stations.isNotEmpty,
          );

    // #2926 — the SHARED hard-fuel-filter chokepoint. The cache stores the
    // full in-radius set (honest, fuel-agnostic, keyed per fuel anyway), but
    // every consumer — the regular search AND the on-search Fuel Station Radar
    // (which calls this same method for its in-radius merge) — sees ONLY
    // stations that actually sell the selected fuel. This guarantees search and
    // radar return an identical result set for the same position + radius +
    // fuel across all 17 countries. `FuelType.all` (and electric/hydrogen,
    // which route to the EV feed) pass through unfiltered.
    // The cross-border route corridor opts out (params.applyFuelFilter=false)
    // so its E5↔E10 sibling fallback can still price a country that sells only
    // the sibling grade (#2641/#2680); search + radar keep the hard filter.
    final filtered = params.applyFuelFilter
        ? StationServiceHelpers.filterByFuel(result.data, params.fuelType)
        : result.data;
    return identical(filtered, result.data) ? result : result.withData(filtered);
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    rejectNonFuelStationId(stationId, countryCode: countryCode); // #3455
    return _throughChain<StationDetail>(
        cacheKey: CacheKey.stationDetail(stationId),
        endpoint: DataAccessEndpoint.stationDetail,
        apiCall: () => _primary.getStationDetail(stationId),
        serialize: serializeStationDetail,
        deserialize: deserializeStationDetail,
        ttl: CacheTtl.stationDetail,
      );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      _throughChain<Map<String, StationPrices>>(
        cacheKey: CacheKey.prices(ids),
        endpoint: DataAccessEndpoint.batchPrices,
        apiCall: () => _primary.getPrices(ids),
        serialize: serializePrices,
        deserialize: deserializePrices,
        ttl: CacheTtl.prices,
      );
}
