// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import '../cache/cache_manager.dart';
import '../error/exceptions.dart';
import 'service_result.dart';
import 'station_service.dart';
import '../../core/logging/error_logger.dart';

/// Orchestrates station data retrieval with fallback:
///
///   1. Fresh cache (< TTL) → return immediately (skip API)
///   2. Primary API → cache result, return
///   3. Stale cache (any age) → return with isStale=true
///   4. All failed → throw ServiceChainExhaustedException
///
/// Accumulated errors from each step are attached to the result,
/// so the UI can show what went wrong even when data was served.
class StationServiceChain implements StationService {
  final StationService _primary;
  final CacheStrategy _cache;
  final ServiceSource _errorSource;
  final String countryCode;

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
  }) : _errorSource = errorSource;

  /// Generic cache-through + request coalescing.
  ///
  ///   1. Return coalesced in-flight request if one exists for [cacheKey]
  ///   2. Fresh cache (< TTL) → return immediately
  ///   3. API call → cache result, return
  ///   4. Stale cache (any age) → return with isStale=true
  ///   5. All failed → throw ServiceChainExhaustedException
  Future<ServiceResult<T>> _throughChain<T>({
    required String cacheKey,
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
    try {
      final result = await _callWithTransientRetry(apiCall);
      await _cache.put(
        cacheKey,
        serialize(result.data),
        ttl: ttl,
        source: result.source,
      );
      return result;
    } on Exception catch (e, st) { // ignore: unused_catch_stack
      errors.add(ServiceError(
        source: _errorSource,
        message: e.toString(),
        statusCode: e is ApiException ? e.statusCode : null,
        kind: e is ApiException ? _effectiveKind(e) : FailureKind.unknown,
        retryAfter: e is ApiException ? e.retryAfter : null,
        occurredAt: DateTime.now(),
      ));
    }

    // Step 3: Stale cache
    final stale = _cache.get(cacheKey);
    if (stale != null) {
      final data = deserialize(stale.payload);
      if (data != null && check(data)) {
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

  /// Delay between the first and second attempt of [_callWithTransientRetry].
  /// 500 ms keeps the user-visible latency tight (most browsers stall ≥1 s
  /// before a user even notices), and is long enough for an overloaded
  /// upstream to clear a 503 burst. Exposed as `@visibleForTesting` so the
  /// retry test can run without sleeping a real half-second.
  @visibleForTesting
  static Duration transientRetryDelay = const Duration(milliseconds: 500);

  /// Wraps a single [apiCall] with one retry on transient remote errors.
  /// Transience is decided by [FailureKind] (#2255): a network blip, a
  /// timeout, or a rate-limit response are the kinds a short retry could
  /// plausibly recover from. One retry only — the goal is to absorb a
  /// transient blip, not to mask sustained outages from the chain's
  /// fall-through to stale cache or to the user-visible error dialog.
  ///
  /// Returns the second attempt's result on success; rethrows the second
  /// attempt's exception on failure so the caller observes the same
  /// `on Exception` semantics as a plain `await apiCall()`. Non-transient
  /// errors (auth, notFound, parse, unsupported, unknown) skip the retry —
  /// those are not going to fix themselves in 500 ms.
  Future<ServiceResult<T>> _callWithTransientRetry<T>(
    Future<ServiceResult<T>> Function() apiCall,
  ) async {
    try {
      return await apiCall();
    } on ApiException catch (e, st) {
      if (!_isTransient(e)) rethrow;
      // Single retry — log to the dev console so debug builds surface
      // the recovered call (production has no listener attached). The
      // stack trace is included to satisfy the
      // `catch_block_stacktrace_coverage` lint (#1103) and to help a
      // future bug report identify which upstream code path triggered
      // the retry without re-running under a debugger.
      debugPrint(
        'StationServiceChain: retrying after transient error '
        '(status=${e.statusCode}, kind=${_effectiveKind(e).name})\n$st',
      );
      // Honour an upstream-suggested Retry-After when present (#2255) but cap
      // it at [transientRetryDelay] so a long server hint never stretches the
      // user-visible latency of the in-chain retry — sustained rate-limits
      // fall through to stale cache instead.
      final delay = e.retryAfter != null && e.retryAfter! < transientRetryDelay
          ? e.retryAfter!
          : transientRetryDelay;
      await Future<void>.delayed(delay);
      return apiCall();
    }
  }

  /// `true` when [e] is a transient failure a single short retry could
  /// plausibly recover from. Routes on [FailureKind] (#2255) instead of
  /// sniffing the English [ApiException.message] prefix:
  /// network / timeout / rateLimited → transient;
  /// auth / notFound / parse / unsupported / unknown → terminal.
  static bool _isTransient(ApiException e) {
    switch (_effectiveKind(e)) {
      case FailureKind.network:
      case FailureKind.timeout:
      case FailureKind.rateLimited:
        return true;
      case FailureKind.auth:
      case FailureKind.notFound:
      case FailureKind.parse:
      case FailureKind.unsupported:
      case FailureKind.unknown:
        return false;
    }
  }

  /// Resolve the [FailureKind] for [e], preserving the pre-#2255 classification
  /// for exceptions that predate typed kinds (or were constructed without one).
  /// When [ApiException.kind] is explicitly set (anything but
  /// [FailureKind.unknown]) it wins; otherwise we fall back to the legacy
  /// signals — HTTP status (5xx → network, matching the old transient-5xx
  /// rule) then the Dio-type message prefix stamped by `throwApiException`.
  static FailureKind _effectiveKind(ApiException e) {
    if (e.kind != FailureKind.unknown) return e.kind;
    final code = e.statusCode;
    if (code != null) {
      final fromStatus = failureKindFromStatus(code);
      if (fromStatus != FailureKind.unknown) return fromStatus;
    }
    final msg = e.message;
    if (msg.startsWith('connectionTimeout') ||
        msg.startsWith('receiveTimeout') ||
        msg.startsWith('sendTimeout')) {
      return FailureKind.timeout;
    }
    if (msg.startsWith('connectionError')) return FailureKind.network;
    return FailureKind.unknown;
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) =>
      _throughChain<List<Station>>(
        cacheKey: CacheKey.stationSearch(
          params.lat, params.lng, params.radiusKm, params.fuelType.apiValue,
          countryCode: countryCode,
          postalCode: params.postalCode,
          locationName: params.locationName,
        ),
        apiCall: () => _primary.searchStations(params, cancelToken: cancelToken),
        serialize: _serializeStationList,
        deserialize: _deserializeStationList,
        ttl: CacheTtl.stationSearch,
        isValid: (stations) => stations.isNotEmpty,
      );

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) =>
      _throughChain<StationDetail>(
        cacheKey: CacheKey.stationDetail(stationId),
        apiCall: () => _primary.getStationDetail(stationId),
        serialize: _serializeStationDetail,
        deserialize: _deserializeStationDetail,
        ttl: CacheTtl.stationDetail,
      );

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      _throughChain<Map<String, StationPrices>>(
        cacheKey: CacheKey.prices(ids),
        apiCall: () => _primary.getPrices(ids),
        serialize: _serializePrices,
        deserialize: _deserializePrices,
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

  // --- Serialization helpers (JSON-safe for Hive storage) ---

  Map<String, dynamic> _serializeStationList(List<Station> stations) => {
        'stations': stations.map((s) => s.toJson()).toList(),
      };

  List<Station>? _deserializeStationList(Map<String, dynamic> data) {
    try {
      final list = data['stations'] as List<dynamic>?;
      if (list == null) return null;
      return list
          .map((j) => Station.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Cache: station list parse failed'}));
      return null;
    }
  }

  Map<String, dynamic> _serializeStationDetail(StationDetail detail) => {
        'station': detail.station.toJson(),
        'openingTimes': detail.openingTimes.map((ot) => ot.toJson()).toList(),
        'overrides': detail.overrides,
        'wholeDay': detail.wholeDay,
        'state': detail.state,
      };

  StationDetail? _deserializeStationDetail(Map<String, dynamic> data) {
    try {
      final stationJson = data['station'] as Map<String, dynamic>?;
      if (stationJson == null) return null;

      final otList = data['openingTimes'] as List<dynamic>? ?? [];
      return StationDetail(
        station: Station.fromJson(stationJson),
        openingTimes: otList
            .map((j) => OpeningTime.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList(),
        overrides: List<String>.from(data['overrides'] as List? ?? []),
        wholeDay: data['wholeDay'] as bool? ?? false,
        state: data['state'] as String?,
      );
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Cache: station detail parse failed'}));
      return null;
    }
  }

  Map<String, dynamic> _serializePrices(Map<String, StationPrices> prices) => {
        'prices': prices.map((k, v) => MapEntry(k, v.toJson())),
      };

  Map<String, StationPrices>? _deserializePrices(Map<String, dynamic> data) {
    try {
      final raw = data['prices'] as Map<String, dynamic>?;
      if (raw == null) return null;
      return raw.map(
        (k, v) => MapEntry(k, StationPrices.fromJson(Map<String, dynamic>.from(v as Map))),
      );
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Cache: prices parse failed'}));
      return null;
    }
  }
}
