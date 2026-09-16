// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../cache/cache_manager.dart';
import '../background/provider_request_budget.dart';
import '../error/exceptions.dart';
import 'diagnostics/data_access_event.dart';
import 'diagnostics/data_access_recorder.dart';
import 'service_result.dart';
import 'station_api_failure_log.dart';
import 'station_failure_classifier.dart';
import 'station_transient_retry.dart';

/// The cache-through ladder `StationServiceChain` runs for every read
/// (#4288).
///
/// Extracted verbatim from the chain, which sat at **exactly** the
/// 400-line cap with its library pinned at 492 — leaving no room for
/// #4171's freshness hook, or anything else. A `part` file would not
/// have helped: `file_length_test`'s own message says a part "does not
/// make the unit smaller", and its library axis counts the part too.
///
/// The ladder, unchanged:
///
///   1. fresh cache → serve it;
///   2. API call, with one transient-error retry (#1954 / #1955) racing a
///      first-paint deadline when a servable stale entry exists (#3668);
///   3. stale cache → serve it with the accumulated errors riding along;
///   4. nothing worked → `ServiceChainExhaustedException`.
///
/// [ChainExecutor] owns no mutable state, so the chain constructs one
/// per call site without ceremony. In-flight coalescing stays in the
/// chain's own mixin — this class is deliberately unaware of it.
class ChainExecutor {
  const ChainExecutor({
    required this.cache,
    required this.countryCode,
    required this.errorSource,
    this.recorder,
    this.budget,
  });

  final CacheStrategy cache;
  final String countryCode;
  final ServiceSource errorSource;
  final DataAccessRecorder? recorder;
  final ProviderRequestBudget? budget;

  Future<ServiceResult<T>> execute<T>({
    required String cacheKey,
    /// #3668 first-paint deadline, passed PER CALL: the chain owns the
    /// `@visibleForTesting static` and a test mutates it between `setUp`
    /// and the call, so capturing it at construction would read a stale
    /// value and silently disarm the stale race.
    required Duration stalePaintDeadline,
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
    final fresh = cache.getFresh(cacheKey);
    if (fresh != null) {
      final data = deserialize(fresh.payload);
      if (data != null && check(data)) {
        recordDataAccess(recorder, countryCode, endpoint,
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
      await cache.put(
        cacheKey,
        serialize(result.data),
        ttl: ttl,
        source: result.source,
      );
      recordDataAccess(recorder, countryCode, endpoint,
          DataAccessHit.networkApi, result.source,
          count: dataAccessResultCount(result.data),
          latencyMicros: apiClock.elapsedMicroseconds);
      // #2866 — stamp the shared budget so a background scan (a different
      // isolate) sees this hit and won't re-poll the provider within its
      // minInterval. Fire-and-forget; null in legacy/test call sites.
      budget?.recordRequest(countryCode);
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
        logStationApiFailure(e, st, countryCode: countryCode, cacheKey: cacheKey);
      }));
      recordDataAccess(recorder, countryCode, endpoint,
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
      // #3979 — `e` as thrown: the old `e is Exception ? e : Exception(e
      // .toString())` erased every Error subtype (a TypeError on drifted
      // JSON became an anonymous Exception); the logger takes Object.
      logStationApiFailure(e, st, countryCode: countryCode, cacheKey: cacheKey);
      errors.add(ServiceError(
        source: errorSource,
        message: e.toString(),
        errorType: e.runtimeType.toString(),
        stackTrace: st,
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
    final stale = cache.get(cacheKey);
    if (stale == null) return null;
    final data = deserialize(stale.payload);
    if (data == null || !check(data)) return null;
    if (recordHit) {
      recordDataAccess(recorder, countryCode, endpoint,
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
}
