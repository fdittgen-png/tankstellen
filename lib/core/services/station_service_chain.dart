// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/search_params.dart';
import '../domain/station.dart';
import '../background/provider_request_budget.dart';
import '../cache/cache_manager.dart';
import '../error/exceptions.dart';
import 'diagnostics/data_access_event.dart';
import 'diagnostics/data_access_recorder.dart';
import 'fuel_service_policy.dart';
import 'mixins/station_service_helpers.dart';
import 'non_fuel_station_guard.dart';
import 'service_result.dart';
import 'station_api_failure_log.dart';
import 'station_failure_classifier.dart';
import 'station_service.dart';
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
    ServiceSource errorSource = ServiceSource.tankerkoenigApi,
    this.countryCode = '',
    FuelServicePolicy? policy,
    DataAccessRecorder? recorder,
    ProviderRequestBudget? budget,
  })  : _errorSource = errorSource,
        _policy = policy,
        _recorder = recorder,
        _budget = budget;

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
    //
    // #3668 — the stale tier is a LATENCY fallback too, not only a
    // failure fallback. When a servable stale entry exists, the fetch
    // races a short first-paint deadline: past it, the stale entry is
    // served (`isStale: true` — the ServiceStatusBanner renders the
    // "updating" state) while the fetch keeps running in the background
    // and caches its result, so the NEXT read is fresh. Field case: FR
    // legacy polling on weak 4G held the search skeleton >10 s (worst
    // case ~90 s: 15 s connect + 30 s receive + one retry) with
    // yesterday's results sitting in Hive the whole time.
    final staleForRace = _staleResult<T>(
      cacheKey, endpoint, deserialize, check, errors,
      recordHit: false,
    );

    Future<ServiceResult<T>> fetchAndCache() async {
      final apiClock = Stopwatch()..start();
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
      // #2866 — stamp the shared budget so a background scan (a different
      // isolate) sees this hit and won't re-poll the provider within its
      // minInterval. Fire-and-forget; null in legacy/test call sites.
      _budget?.recordRequest(countryCode);
      return result;
    }

    final pending = fetchAndCache();
    try {
      if (staleForRace != null) {
        return await pending.timeout(stalePaintDeadline);
      }
      return await pending;
    } on TimeoutException {
      // Deadline hit with a stale fallback in hand: serve it now, let the
      // fetch finish (and cache) in the background. Its eventual failure
      // is logged, never thrown into the void.
      unawaited(pending.then<void>((_) {}).catchError((Object e, StackTrace st) {
        recordDataAccessFailure(countryCode);
        logStationApiFailure(e is Exception ? e : Exception(e.toString()), st,
            countryCode: countryCode, cacheKey: cacheKey);
      }));
      recordDataAccess(_recorder, countryCode, endpoint,
          DataAccessHit.hiveStale, ServiceSource.cache,
          count: dataAccessResultCount(staleForRace!.data), isStale: true);
      return staleForRace;
    } catch (e, st) {
      // #3743 (S-fix) — catch-ALL, not `on Exception`: an implementor's
      // contract is ServiceResult-or-throw-ApiException, but a decode bug
      // (TypeError on drifted JSON shape) or a StateError throws an
      // `Error` that used to sail straight past this handler and out of
      // the chain as a raw crash. ANY throw from the primary is a
      // transport fault to this chain: it is absorbed into the error
      // accumulator and the stale-cache → ServiceChainExhaustedException
      // ladder below, so `ServiceChainExhaustedException` stays the ONLY
      // exception the polled chain surfaces (see the [StationService]
      // contract note).
      recordDataAccessFailure(countryCode); // #3146 — always-on tally
      // #3370/#2296 — breadcrumb an EXPECTED `unsupported` gap (e.g. Luxembourg
      // has no per-station detail); ERROR-log any real failure (with stack).
      logStationApiFailure(e is Exception ? e : Exception(e.toString()), st,
          countryCode: countryCode, cacheKey: cacheKey);
      errors.add(ServiceError(
        source: _errorSource,
        message: e.toString(),
        statusCode: e is ApiException ? e.statusCode : null,
        kind: e is ApiException ? effectiveFailureKind(e) : FailureKind.unknown,
        retryAfter: e is ApiException ? e.retryAfter : null,
        occurredAt: DateTime.now(),
      ));
    }

    // Step 3: Stale cache (fetch failed — re-read so the hit is recorded
    // and the accumulated errors ride along on the result).
    final stale = _staleResult<T>(
      cacheKey, endpoint, deserialize, check, errors,
      recordHit: true,
    );
    if (stale != null) return stale;

    // Step 4: Nothing worked
    throw ServiceChainExhaustedException(errors: errors);
  }

  /// Deserialize the stale cache entry for [cacheKey] into a servable
  /// [ServiceResult], or null when absent/invalid (#3668). [recordHit]
  /// controls whether the diagnostics recorder is stamped — the race
  /// pre-read must not record a hit it may never serve.
  ServiceResult<T>? _staleResult<T>(
    String cacheKey,
    DataAccessEndpoint endpoint,
    T? Function(Map<String, dynamic> data) deserialize,
    bool Function(T data) check,
    List<ServiceError> errors, {
    required bool recordHit,
  }) {
    final stale = _cache.get(cacheKey);
    if (stale == null) return null;
    final data = deserialize(stale.payload);
    if (data == null || !check(data)) return null;
    if (recordHit) {
      recordDataAccess(_recorder, countryCode, endpoint,
          DataAccessHit.hiveStale, ServiceSource.cache,
          count: dataAccessResultCount(data), isStale: true);
    }
    return ServiceResult(
      data: data,
      source: ServiceSource.cache,
      fetchedAt: stale.storedAt,
      isStale: true,
      errors: List.of(errors),
    );
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
