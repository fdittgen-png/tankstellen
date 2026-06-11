// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/logging/error_logger.dart';

/// Danish fuel prices aggregated from 3 free public APIs:
/// - OK (ok.dk) — ~350 stations
/// - Shell (geoapp.me) — ~200 stations
/// - Q8/F24 (q8.dk) — ~250 stations
///
/// All APIs are free, require no API key, and return all stations nationally.
/// We download all, calculate distances locally, and filter by radius.
/// Prices are in DKK (Danish Kroner).
class DenmarkStationService with StationServiceHelpers, CachedDatasetMixin implements StationService {
  final Dio _dio;

  /// #2264 — optional disk persistence (read-through). When a [CacheStrategy]
  /// is supplied (the registry factory passes the shared CacheManager) the
  /// parsed national dataset is persisted to Hive so it survives a cold start
  /// and works offline. Null in unit tests that don't exercise persistence.
  final PersistentDataset<List<Station>>? _persistent;

  /// #2181 — Dio injectable for tests; defaults to the standard factory.
  /// #2264 — [cache] enables the disk read-through; omit it for the pure
  /// in-memory behaviour the existing parser tests rely on.
  DenmarkStationService({Dio? dio, CacheStrategy? cache})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
        _persistent = cache == null
            ? null
            : PersistentDataset<List<Station>>(
                cache: cache,
                countryCode: 'DK',
                datasetName: 'stations',
                source: ServiceSource.denmarkApi,
                serialize: (stations) =>
                    {'stations': stations.map((s) => s.toJson()).toList()},
                deserialize: (json) {
                  final list = json['stations'] as List<dynamic>?;
                  if (list == null) return null;
                  return list
                      .map((j) =>
                          Station.fromJson(Map<String, dynamic>.from(j as Map)))
                      .toList();
                },
              );

  // #2264 — soft/hard dataset TTLs mirror the DK FuelServicePolicy in the
  // registry (soft 2 h, hard 12 h). The legacy 5-minute in-memory TTL is
  // superseded; the persisted read-through governs freshness now.
  static const Duration _softTtl = Duration(hours: 2);
  static const Duration _hardTtl = Duration(hours: 12);

  // In-memory cache
  List<Station>? _cachedStations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken: cancelToken);

      // Calculate distances from search center
      final allWithDist = <Station>[];
      for (final s in _cachedStations!) {
        allWithDist.add(s.copyWith(
          dist: roundedDistance(params.lat, params.lng, s.lat, s.lng),
        ));
      }

      // Filter by radius; if nothing found, return nearest 20 instead
      final stations = filterByRadius(allWithDist, params.radiusKm);

      // Sort
      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.denmarkApi);
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'Netværksfejl', stackTrace: st);
    }
  }

  /// #2249 — short TTL applied to a *partial* multi-brand fetch so an
  /// incomplete dataset (one brand feed down) is pinned only briefly and the
  /// next search retries the missing source instead of holding the gap for
  /// the full [_hardTtl].
  static const Duration _partialTtl = Duration(minutes: 10);

  /// Whether the most recent [_fetchAll] saw **every active brand source**
  /// (OK + Shell) succeed. Q8 is excluded — it returns no coordinates today,
  /// so its empty result is by-design, not a failure. Read by the
  /// completeness gate in [_ensureDataLoaded].
  bool _lastFetchComplete = true;

  Future<List<Station>> _fetchAll({CancelToken? cancelToken}) async {
    // Fetch all sources in parallel. Each active brand reports success/failure
    // so a single down feed downgrades completeness (→ short TTL) rather than
    // silently caching a partial national dataset at the full TTL.
    final results = await Future.wait([
      _fetchSource(() => _fetchOk(cancelToken: cancelToken)),
      _fetchSource(() => _fetchShell(cancelToken: cancelToken)),
    ]);
    // Q8 has no coordinates — always empty, never counted toward completeness.
    final q8 = await _fetchQ8();

    // Every active source down → surface a network error. The persistent
    // read-through catches it and serves the last good disk copy; the legacy
    // in-memory path and searchStations' `on DioException` turn it into an
    // ApiException instead of pinning an empty dataset.
    if (results.every((r) => !r.ok)) {
      throw DioException(
        requestOptions: RequestOptions(path: 'dk-aggregate'),
        type: DioExceptionType.connectionError,
        error: 'DK: all brand feeds failed',
      );
    }
    _lastFetchComplete = results.every((r) => r.ok);
    return [
      for (final r in results) ...r.stations,
      ...q8,
    ];
  }

  /// Run one brand fetcher, tagging whether it completed without a network
  /// error. The brand fetchers themselves swallow [DioException] and return an
  /// empty list, so we re-detect failure here by catching anything they
  /// rethrow and, for the swallow path, treating a thrown error as a miss.
  Future<({List<Station> stations, bool ok})> _fetchSource(
    Future<List<Station>> Function() fetch,
  ) async {
    try {
      return (stations: await fetch(), ok: true);
    } on Object {
      return (stations: const <Station>[], ok: false);
    }
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) {
    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — preserve the legacy in-memory path.
      return loadDataset<List<Station>>(
        cached: _cachedStations,
        ttl: const Duration(minutes: 5),
        fetch: () => _fetchAll(cancelToken: cancelToken),
        store: (value) => _cachedStations = value,
      );
    }
    // #2264 — disk read-through: survives cold start + offline.
    // #2249 — completeness gate: a partial fetch (a brand feed down) is cached
    // under [_partialTtl] instead of [_hardTtl] so the gap is retried soon.
    return loadPersistentDatasetGuarded<List<Station>>(
      cached: _cachedStations,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      shortTtl: _partialTtl,
      persistent: persistent,
      fetch: () => _fetchAll(cancelToken: cancelToken),
      store: (value) => _cachedStations = value,
      isComplete: (_) => _lastFetchComplete,
    );
  }

  /// OK — https://mobility-prices.ok.dk/api/v1/fuel-prices
  Future<List<Station>> _fetchOk({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://mobility-prices.ok.dk/api/v1/fuel-prices',
        cancelToken: cancelToken,
      );
      if (response.data is! Map) return [];
      final items = response.data['items'] as List<dynamic>? ?? [];

      return items.map((r) {
        final coords = r['coordinates'] as Map<String, dynamic>? ?? {};
        final lat = (coords['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (coords['longitude'] as num?)?.toDouble() ?? 0;
        if (lat == 0 || lng == 0) return null;

        final prices = r['prices'] as List<dynamic>? ?? [];
        // #3187 — OK feed grades (live 2026-06-10): "Blyfri 95",
        // "Svovlfri Diesel", "Oktan 100". The 100-octane grade gets its own
        // exact match so it lands in e98, never in a regular slot.
        double? e5, e98, diesel;
        for (final p in prices) {
          final name = (p['product_name']?.toString() ?? '').trim().toLowerCase();
          final price = (p['price'] as num?)?.toDouble();
          if (name == 'oktan 100') {
            e98 ??= price;
          } else if (name.contains('95') || name.contains('blyfri')) {
            e5 ??= price;
          } else if (name.contains('diesel')) {
            diesel ??= price;
          }
        }

        final street = r['street']?.toString() ?? '';
        final houseNr = r['house_number']?.toString() ?? '';
        final city = r['city']?.toString() ?? '';

        return Station(
          id: 'ok-${r['facility_number'] ?? ''}',
          name: 'OK',
          brand: 'OK',
          street: '$street $houseNr'.trim(),
          postCode: r['postal_code']?.toString() ?? '',
          place: city,
          lat: lat,
          lng: lng,
          dist: 0,
          // #3198 — the single Danish 95-octane grade lives in e5 only;
          // the old e10 mirror asserted an E10 price the feed never
          // publishes (catalog change in CountryConfig / registry).
          e5: e5,
          e98: e98,
          diesel: diesel,
          // #3198 — the OK feed carries no open/closed signal: honest
          // unknown instead of the old hard-coded `true`.
          isOpen: null,
          updatedAt: _formatIsoTime(r['last_updated_time']?.toString()),
        );
      }).whereType<Station>().toList();
    } on DioException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'DK OK fetch failed'}));
      // #2249 — rethrow so the completeness gate sees a *failed* source (vs a
      // genuinely empty feed). [_fetchSource] catches it and downgrades the
      // dataset to a short TTL; the legacy in-memory path is unaffected.
      rethrow;
    }
  }

  /// Shell — https://shellpumpepriser.geoapp.me/v1/prices
  Future<List<Station>> _fetchShell({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://shellpumpepriser.geoapp.me/v1/prices',
        cancelToken: cancelToken,
      );
      if (response.data is! List) return [];

      return (response.data as List).map((r) {
        final coords = r['coordinates'] as Map<String, dynamic>? ?? {};
        final lat = double.tryParse(coords['latitude']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(coords['longitude']?.toString() ?? '') ?? 0;
        if (lat == 0 || lng == 0) return null;

        final prices = r['prices'] as List<dynamic>? ?? [];
        // #3187 — exact product-name mapping. The live feed lists
        // "V-Power Diesel" BEFORE "FuelSave Diesel" at ~76% of stations, so a
        // `contains('diesel')` first-wins matcher stamped the PREMIUM price as
        // regular diesel. Grades (live 2026-06-10): "V-Power Diesel"
        // (premium diesel), "FuelSave Diesel" (regular), "V-Power" (octane-98
        // petrol), "Blyfri 95". If a station only carries the premium grade,
        // regular diesel stays null — never substitute premium.
        double? e5, e98, diesel, dieselPremium;
        for (final p in prices) {
          final name = (p['productName']?.toString() ?? '').trim().toLowerCase();
          final price = double.tryParse(p['price']?.toString() ?? '');
          switch (name) {
            case 'fuelsave diesel' || 'diesel':
              diesel ??= price;
            case 'v-power diesel':
              dieselPremium ??= price;
            case 'v-power':
              e98 ??= price;
            case 'blyfri 95':
              e5 ??= price;
          }
        }

        return Station(
          id: 'shell-${r['stationId'] ?? ''}',
          name: r['brand']?.toString() ?? 'Shell',
          brand: r['brand']?.toString() ?? 'Shell',
          street: '${r['street'] ?? ''} ${r['houseNumber'] ?? ''}'.trim(),
          postCode: r['postalCode']?.toString() ?? '',
          place: r['city']?.toString() ?? '',
          lat: lat,
          lng: lng,
          dist: 0,
          // #3198 — no e10 mirror (single 95-octane grade, see above).
          e5: e5,
          e98: e98,
          diesel: diesel,
          dieselPremium: dieselPremium,
          // #3198 — the Shell feed carries no open/closed signal either.
          isOpen: null,
          updatedAt: _formatIsoTime(
            (prices.isNotEmpty ? prices.first['lastUpdated'] : null)?.toString(),
          ),
        );
      }).whereType<Station>().toList();
    } on DioException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'DK Shell fetch failed'}));
      // #2249 — rethrow so the completeness gate downgrades to a short TTL.
      rethrow;
    }
  }

  /// Q8/F24 — no coordinates in API response, skip for now.
  Future<List<Station>> _fetchQ8() async {
    // Q8's API (beta.q8.dk) returns station prices but no lat/lng coordinates.
    // Without coordinates we cannot calculate distances or show on map.
    return [];
  }

  String? _formatIsoTime(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'DK date parse failed'}));
      return null;
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throwDetailUnavailable('Danish APIs');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return emptyPricesResult(ServiceSource.denmarkApi);
  }
}
