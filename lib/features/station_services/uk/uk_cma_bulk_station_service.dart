// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'uk_station_service.dart';

/// UK CMA / Fuel Finder **bulk-file** fuel-price service (#2277).
///
/// The legacy [UkStationService] fans out across ~14 retailer feeds on *every*
/// search — slow, fragile and rate-risky. Under the Motor Fuel Price (Open
/// Data) Regulations 2025 the same standardized station records are published
/// as a single consolidated file (the Fuel Finder twice-daily download), so
/// this service downloads that **once per ~12 h publication cadence**, persists
/// it via [PersistentDataset] (survives cold start + offline), and answers
/// every search by **local geo-filter** — no per-search network round-trip.
///
/// Results are preserved: the consolidated file carries the *same* standardized
/// record schema as the retailer feeds, and this service parses each search
/// through the identical [UkStationService.parseCmaStations] used by the legacy
/// path, so a given area returns the same stations.
///
/// The consolidated download is JSON-shaped exactly like the retailer feeds
/// (`{"stations": [ {site_id, brand, address, postcode, location:{latitude,
/// longitude}, prices:{E5,E10,B7,...}} ]}`); the persisted dataset is the raw
/// record list, re-filtered per search. The download URL is injectable so the
/// subscription-issued consolidated endpoint is a one-line config change.
///
/// This service is only wired into the registry when
/// `BulkMigrationFlags.ukCmaBulk` is `true` (staged rollout, defaults to the
/// legacy fan-out).
class UkCmaBulkStationService
    with StationServiceHelpers, CachedDatasetMixin
    implements StationService {
  final Dio _dio;
  final String _consolidatedUrl;

  /// Disk persistence (read-through). When a [CacheStrategy] is supplied (the
  /// registry factory passes the shared CacheManager) the parsed consolidated
  /// record list is persisted to Hive so it survives a cold start and works
  /// offline. Null in the pure-in-memory parser tests.
  final PersistentDataset<List<Map<String, dynamic>>>? _persistent;

  /// Default consolidated CMA / Fuel Finder download. Published twice daily
  /// under the gov.uk Fuel Finder scheme; one file covers every forecourt.
  /// Overridable so the subscription-issued URL (or an OAuth2-fronted variant)
  /// drops in without touching the parse/persist/filter logic.
  // i18n-ignore: gov.uk data endpoint URL, not user-facing text
  static const String defaultConsolidatedUrl =
      'https://www.fuel-finder.service.gov.uk/api/v1/prices/latest';

  UkCmaBulkStationService({
    Dio? dio,
    String? consolidatedUrl,
    CacheStrategy? cache,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.json,
            ),
        _consolidatedUrl = consolidatedUrl ?? defaultConsolidatedUrl,
        _persistent = cache == null
            ? null
            : PersistentDataset<List<Map<String, dynamic>>>(
                cache: cache,
                countryCode: 'GB',
                datasetName: 'stations',
                source: ServiceSource.ukApi,
                serialize: (records) => {'records': records},
                deserialize: (json) {
                  final list = json['records'] as List<dynamic>?;
                  if (list == null) return null;
                  return list
                      .map((r) => Map<String, dynamic>.from(r as Map))
                      .toList();
                },
              );

  /// Soft/hard dataset TTLs mirror the GB bulk [FuelServicePolicy] in the
  /// registry (soft 12 h ≈ publication cadence, hard 48 h offline grace).
  static const Duration _softTtl = Duration(hours: 12);
  static const Duration _hardTtl = Duration(hours: 48);

  // In-memory copy of the parsed consolidated records.
  List<Map<String, dynamic>>? _cachedRecords;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    await _ensureDataLoaded(cancelToken: cancelToken);

    // Local geo-filter through the SAME parser the legacy path uses, so a
    // given area returns identical stations (radius filter + dedupe by
    // site_id + sort-by-distance + cap-50 all live in parseCmaStations).
    final stations = UkStationService.parseCmaStations(
      _cachedRecords ?? const [],
      lat: params.lat,
      lng: params.lng,
      radiusKm: params.radiusKm,
    );

    return ServiceResult(
      data: stations,
      source: ServiceSource.ukApi,
      fetchedAt: DateTime.now(),
    );
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) {
    Future<List<Map<String, dynamic>>> fetch() =>
        _downloadConsolidated(cancelToken: cancelToken);
    void store(List<Map<String, dynamic>> value) => _cachedRecords = value;

    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — pure in-memory soft-TTL behaviour.
      return loadDataset<List<Map<String, dynamic>>>(
        cached: _cachedRecords,
        ttl: _softTtl,
        fetch: fetch,
        store: store,
      );
    }
    // Disk read-through: survives cold start + offline, refreshes past soft TTL.
    return loadPersistentDataset<List<Map<String, dynamic>>>(
      cached: _cachedRecords,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: persistent,
      fetch: fetch,
      store: store,
    );
  }

  /// Download + extract the consolidated record list. Tolerates the two
  /// standardized envelope shapes (`{stations:[...]}` / `{data:[...]}`) and a
  /// bare top-level list.
  Future<List<Map<String, dynamic>>> _downloadConsolidated({
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      _consolidatedUrl,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.json),
    );
    return extractConsolidatedRecords(response.data);
  }

  /// Extract the standardized station-record list from the consolidated
  /// envelope. Exposed for tests; mirrors the per-feed extraction the legacy
  /// service does in `_fetchFeed`.
  @visibleForTesting
  static List<Map<String, dynamic>> extractConsolidatedRecords(dynamic data) {
    List<dynamic> raw;
    if (data is Map<String, dynamic>) {
      raw = data['stations'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          const [];
    } else if (data is List) {
      raw = data;
    } else {
      return const [];
    }
    final out = <Map<String, dynamic>>[];
    for (final r in raw) {
      if (r is Map) out.add(Map<String, dynamic>.from(r));
    }
    return out;
  }

  /// Clears the in-memory dataset so the next search re-downloads. For tests.
  @visibleForTesting
  void clearCacheForTest() {
    _cachedRecords = null;
    markDatasetRefreshedAt(const Duration(days: 3650));
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('CMA Fuel Finder');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.ukApi);
  }
}
