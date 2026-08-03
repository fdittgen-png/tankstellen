// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'station_service_chain.dart';

/// #3668 — the chain's in-flight coalescing state + the bulk-dataset
/// search path, split out of `station_service_chain.dart` as a `part`
/// mixin to keep the chain file under the #1680 length ratchet after
/// the stale-first deadline race landed. Same library, so the private
/// fields on [StationServiceChain] satisfy the abstract members below.
mixin _ChainCoalescing {
  // Satisfied by the fields/getters on [StationServiceChain].
  StationService get _primary;
  DataAccessRecorder? get _recorder;
  ProviderRequestBudget? get _budget;
  String get countryCode;

  /// In-flight request deduplication: concurrent calls for the same cache key
  /// share a single Future instead of hitting the API multiple times.
  /// Entries are removed in the finally block of `_throughChain` and also
  /// evicted if older than [_inFlightMaxAge] to prevent leaks.
  final _inFlight = <String, Future<ServiceResult<dynamic>>>{};
  final _inFlightTimestamps = <String, DateTime>{};

  /// Max time an entry can stay in _inFlight before forced eviction.
  static const _inFlightMaxAge = Duration(minutes: 2);

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
        return result.withData<List<Station>>(result.data as List<Station>);
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
      // #2866 — stamp the shared per-provider (here: per-dataset) budget so a
      // background scan won't re-download the whole-country dataset within the
      // policy's minInterval after a foreground search just fetched it.
      _budget?.recordRequest(countryCode);
      return result;
    } finally {
      unawaited(_inFlight.remove(key) ?? Future<void>.value());
      _inFlightTimestamps.remove(key);
    }
  }

  /// Remove in-flight entries older than [_inFlightMaxAge].
  /// Guards against orphaned futures from unhandled exceptions or timeouts.
  void _evictStaleInFlight() {
    final now = DateTime.now();
    final staleKeys = _inFlightTimestamps.entries
        .where((e) => now.difference(e.value) > _inFlightMaxAge)
        .map((e) => e.key)
        .toList();
    for (final key in staleKeys) {
      unawaited(_inFlight.remove(key));
      _inFlightTimestamps.remove(key);
      debugPrint('StationServiceChain: evicted stale in-flight entry: $key');
    }
  }
}
