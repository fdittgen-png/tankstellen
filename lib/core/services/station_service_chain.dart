// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import '../cache/cache_manager.dart';
import '../error/exceptions.dart';
import '../logging/error_logger.dart';
import 'diagnostics/data_access_event.dart';
import 'diagnostics/data_access_recorder.dart';
import 'fuel_service_policy.dart';
import 'service_result.dart';
import 'station_failure_classifier.dart';
import 'station_service.dart';
import 'station_service_chain_codec.dart';
import 'station_transient_retry.dart';

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
class StationServiceChain implements StationService {
  final StationService _primary;
  final CacheStrategy _cache;
  final ServiceSource _errorSource;
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
  final DataAccessRecorder? _recorder;

  /// In-flight request deduplication: concurrent calls for the same cache key
  /// share a single Future instead of hitting the API multiple times.
  /// Entries are removed in the finally block of [_throughChain] and also
  /// evicted if older than [_inFlightMaxAge] to prevent leaks.
  final _inFlight = <String, Future<ServiceResult<dynamic>>>{};
  final _inFlightTimestamps = <String, DateTime>{};

  /// Max time an entry can stay in _inFlight before forced eviction.
  static const _inFlightMaxAge = Duration(minutes: 2);

  StationServiceChain(this._primary, this._cache, {
    ServiceSource errorSource = ServiceSource.tankerkoenigApi,
    this.countryCode = '',
    FuelServicePolicy? policy,
    DataAccessRecorder? recorder,
  })  : _errorSource = errorSource,
        _policy = policy,
        _recorder = recorder;

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
        return ServiceResult<T>(
          data: result.data as T,
          source: result.source,
          fetchedAt: result.fetchedAt,
          isStale: result.isStale,
          errors: result.errors,
        );
      }
      // Type mismatch from coalesced result — fall through to fresh request
    }

    final future = _executeChain<T>(
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

  Future<ServiceResult<T>> _executeChain<T>({
    required String cacheKey,
    required DataAccessEndpoint endpoint,
    required Future<ServiceResult<T>> Function() apiCall,
    required Map<String, dynamic> Function(T data) serialize,
    required T? Function(Map<String, dynamic> data) deserialize,
    required Duration ttl,
    bool Function(T data)? isValid,
  }) async {
    final errors = <ServiceError>[];
    final check = isValid ?? (_) => true;

    // Step 1: Fresh cache
    final fresh = _cache.getFresh(cacheKey);
    if (fresh != null) {
      final data = deserialize(fresh.payload);
      if (data != null && check(data)) {
        recordDataAccess(_recorder, countryCode, endpoint,
            DataAccessHit.hiveFresh, fresh.originalSource,
            count: dataAccessResultCount(data));
        return ServiceResult(
          data: data,
          source: fresh.originalSource,
          fetchedAt: fresh.storedAt,
        );
      }
    }

    // Step 2: API call. Wrapped with one transient-error retry so a
    // single 5xx burst or connect-timeout doesn't immediately fall
    // through to stale cache (or, when there is no stale cache, throw
    // `ServiceChainExhaustedException` straight to the user). The
    // affected sources right now are the MITECO endpoint (#1954 — 503s
    // under load) and the Argentina CKAN bulk-download (#1955 — slow
    // first-byte triggering Dio's connect timeout). Both recover on a
    // second attempt within a second.
    final apiClock = Stopwatch()..start();
    try {
      final result = await callWithTransientRetry(apiCall);
      apiClock.stop();
      await _cache.put(
        cacheKey,
        serialize(result.data),
        ttl: ttl,
        source: result.source,
      );
      recordDataAccess(_recorder, countryCode, endpoint,
          DataAccessHit.networkApi, result.source,
          count: dataAccessResultCount(result.data),
          latencyMicros: apiClock.elapsedMicroseconds);
      return result;
    } on Exception catch (e, st) {
      // #2296 — log the API-failure path (stack was previously discarded)
      // so a sustained upstream outage leaves a breadcrumb. Non-fatal.
      unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
        'where': 'StationServiceChain.apiCall',
        'country': countryCode,
        'key': cacheKey,
      }));
      errors.add(ServiceError(
        source: _errorSource,
        message: e.toString(),
        statusCode: e is ApiException ? e.statusCode : null,
        kind: e is ApiException ? effectiveFailureKind(e) : FailureKind.unknown,
        retryAfter: e is ApiException ? e.retryAfter : null,
        occurredAt: DateTime.now(),
      ));
    }

    // Step 3: Stale cache
    final stale = _cache.get(cacheKey);
    if (stale != null) {
      final data = deserialize(stale.payload);
      if (data != null && check(data)) {
        recordDataAccess(_recorder, countryCode, endpoint,
            DataAccessHit.hiveStale, ServiceSource.cache,
            count: dataAccessResultCount(data), isStale: true);
        return ServiceResult(
          data: data,
          source: ServiceSource.cache,
          fetchedAt: stale.storedAt,
          isStale: true,
          errors: errors,
        );
      }
    }

    // Step 4: Nothing worked
    throw ServiceChainExhaustedException(errors: errors);
  }

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
  }) {
    // #2264 — bulk-file sources local-filter a persisted whole-country
    // dataset, so a per-search-key cache only duplicates that work and can
    // serve a stale slice; answer nearby straight from the primary instead.
    if (_policy?.isBulkFile ?? false) {
      return _bulkSearch(params, cancelToken: cancelToken);
    }

    return _throughChain<List<Station>>(
      cacheKey: CacheKey.stationSearch(
        params.lat, params.lng, params.radiusKm, params.fuelType.apiValue,
        countryCode: countryCode,
        postalCode: params.postalCode,
        locationName: params.locationName,
      ),
      endpoint: params.postalCode != null
          ? DataAccessEndpoint.searchPostcode
          : DataAccessEndpoint.searchGeo,
      apiCall: () => _primary.searchStations(params, cancelToken: cancelToken),
      serialize: serializeStationList,
      deserialize: deserializeStationList,
      // Polled sources use the policy's per-key TTL; fall back to the global
      // default for legacy call sites that supply no policy.
      ttl: _policy?.searchResultTtl ?? CacheTtl.stationSearch,
      isValid: (stations) => stations.isNotEmpty,
    );
  }

  /// Bulk-dataset search path (#2264): no per-key Hive cache. Adds only the
  /// resilience layers that matter — in-flight coalescing + the single
  /// transient retry — then returns the primary's result verbatim, so search
  /// results are byte-identical to calling the primary directly.
  Future<ServiceResult<List<Station>>> _bulkSearch(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    _evictStaleInFlight();
    final key = 'bulk:${CacheKey.stationSearch(
      params.lat, params.lng, params.radiusKm, params.fuelType.apiValue,
      countryCode: countryCode,
      postalCode: params.postalCode,
      locationName: params.locationName,
    )}';

    if (_inFlight.containsKey(key)) {
      final result = await _inFlight[key]!;
      if (result.data is List<Station>) {
        recordDataAccess(_recorder, countryCode,
            DataAccessEndpoint.bulkDataset, DataAccessHit.coalesced,
            result.source,
            count: dataAccessResultCount(result.data),
            isStale: result.isStale);
        return ServiceResult<List<Station>>(
          data: result.data as List<Station>,
          source: result.source,
          fetchedAt: result.fetchedAt,
          isStale: result.isStale,
          errors: result.errors,
        );
      }
    }

    final future = callWithTransientRetry(
      () => _primary.searchStations(params, cancelToken: cancelToken),
    );
    _inFlight[key] = future;
    _inFlightTimestamps[key] = DateTime.now();
    final bulkClock = Stopwatch()..start();
    try {
      final result = await future;
      bulkClock.stop();
      recordDataAccess(_recorder, countryCode, DataAccessEndpoint.bulkDataset,
          DataAccessHit.networkApi, result.source,
          count: dataAccessResultCount(result.data),
          latencyMicros: bulkClock.elapsedMicroseconds,
          isStale: result.isStale);
      return result;
    } finally {
      unawaited(_inFlight.remove(key) ?? Future<void>.value());
      _inFlightTimestamps.remove(key);
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) =>
      _throughChain<StationDetail>(
        cacheKey: CacheKey.stationDetail(stationId),
        endpoint: DataAccessEndpoint.stationDetail,
        apiCall: () => _primary.getStationDetail(stationId),
        serialize: serializeStationDetail,
        deserialize: deserializeStationDetail,
        ttl: CacheTtl.stationDetail,
      );

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

  /// Remove in-flight entries older than [_inFlightMaxAge].
  /// Guards against orphaned futures from unhandled exceptions or timeouts.
  void _evictStaleInFlight() {
    final now = DateTime.now();
    final staleKeys = _inFlightTimestamps.entries
        .where((e) => now.difference(e.value) > _inFlightMaxAge)
        .map((e) => e.key)
        .toList();
    for (final key in staleKeys) {
      _inFlight.remove(key);
      _inFlightTimestamps.remove(key);
      debugPrint('StationServiceChain: evicted stale in-flight entry: $key');
    }
  }

}
