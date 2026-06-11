// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/domain/search_params.dart';
import '../../../core/domain/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'france_opening_hours_adapter.dart';
import 'prix_carburants_flux_parser.dart' as flux;

/// French Prix-Carburants **bulk-file** service (#2277).
///
/// The legacy [PrixCarburantsStationService] polls `data.economie.gouv.fr` on
/// *every* search (one or two HTTP calls per query). This service instead
/// downloads the whole-country *flux instantané* ZIP **once per ~10 min
/// cadence**, parses it (ZIP → XML → [Station]s), persists the parsed list via
/// [PersistentDataset] (survives cold start + offline), and answers every
/// search by **local geo-filter** — it never polls per-station.
///
/// This also fixes the FR empty-result/cache contract: the legacy path returned
/// an empty [ServiceResult] on a transient network error (so the chain cached
/// nothing and re-hit the API next search). Here the persisted dataset is
/// served on a network failure (stale-but-offline via
/// [CachedDatasetMixin.loadPersistentDataset]), and a search with genuinely no
/// nearby station returns empty *without* discarding the dataset.
///
/// Results are preserved: the flux parser maps the same fuel grades onto the
/// same [Station] fields as the legacy JSON parser (`SP95→e5`, `E10→e10`,
/// `SP98→e98`, `Gazole→diesel`, `E85→e85`, `GPLc→lpg`) with the `fr-` id prefix.
///
/// Only wired into the registry when `BulkMigrationFlags.frFluxBulk` is `true`
/// (staged rollout, defaults to the legacy polling service).
class PrixCarburantsFluxStationService
    with StationServiceHelpers, CachedDatasetMixin
    implements StationService {
  final Dio _dio;
  final String _zipUrl;

  /// Disk persistence (read-through). When a [CacheStrategy] is supplied the
  /// parsed national station list is persisted so it survives cold start +
  /// works offline. Null in the pure-in-memory parser tests.
  final PersistentDataset<List<Station>>? _persistent;

  /// Default whole-country flux ZIP. ~1 MB, refreshed every ~10 minutes.
  /// Overridable for tests / endpoint drift.
  // i18n-ignore: gouv.fr open-data endpoint URL, not user-facing text
  static const String defaultZipUrl =
      'https://donnees.roulez-eco.fr/opendata/instantane';

  PrixCarburantsFluxStationService({
    Dio? dio,
    String? zipUrl,
    CacheStrategy? cache,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.bytes,
            ),
        _zipUrl = zipUrl ?? defaultZipUrl,
        _persistent = cache == null
            ? null
            : PersistentDataset<List<Station>>(
                cache: cache,
                countryCode: 'FR',
                datasetName: 'stations',
                source: ServiceSource.prixCarburantsApi,
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

  /// Soft/hard dataset TTLs mirror the FR bulk [FuelServicePolicy] in the
  /// registry (soft 10 min ≈ flux cadence, hard 6 h offline grace).
  static const Duration _softTtl = Duration(minutes: 10);
  static const Duration _hardTtl = Duration(hours: 6);

  // In-memory copy of the parsed national dataset.
  List<Station>? _cachedStations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken: cancelToken);
    } on DioException catch (e, st) {
      // No persisted copy to fall back to AND no cached dataset → surface the
      // network error to the chain (which then falls through to its own stale
      // cache / error UI) rather than masking it as an empty result.
      if (_cachedStations == null) {
        throwApiException(e, defaultMessage: 'Erreur réseau', stackTrace: st);
      }
    }

    final all = _cachedStations ?? const <Station>[];
    // #3152 — compute the distance first and `copyWith` ONLY the in-radius
    // survivors. The previous shape copied all ~11k national stations per
    // search before discarding everything outside the radius — pure
    // allocation churn on the UI isolate. Output is unchanged: the same
    // rounded distance drives the same strict filter, and the survivors
    // carry the identical `dist` they did before.
    //
    // Strict radius filter — unlike a top-N fallback, a far-from-France
    // search correctly returns empty (the legacy path's #298/#315 radius
    // contract).
    final stations = <Station>[];
    for (final s in all) {
      final dist = roundedDistance(params.lat, params.lng, s.lat, s.lng);
      if (dist <= params.radiusKm) {
        stations.add(s.copyWith(dist: dist));
      }
    }
    sortStations(stations, params);

    return wrapStations(stations, ServiceSource.prixCarburantsApi);
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) {
    Future<List<Station>> fetch() => _downloadAndParse(cancelToken: cancelToken);
    void store(List<Station> value) => _cachedStations = value;

    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — pure in-memory soft-TTL behaviour.
      return loadDataset<List<Station>>(
        cached: _cachedStations,
        ttl: _softTtl,
        fetch: fetch,
        store: store,
      );
    }
    // Disk read-through: survives cold start + offline, refreshes past soft TTL.
    return loadPersistentDataset<List<Station>>(
      cached: _cachedStations,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: persistent,
      fetch: fetch,
      store: store,
    );
  }

  Future<List<Station>> _downloadAndParse({CancelToken? cancelToken}) async {
    final response = await _dio.get<List<int>>(
      _zipUrl,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return const [];
    // #3152 — the whole-country ZIP+XML parse (~11k stations) runs in a
    // background isolate via `compute` (same pattern as the Argentina CSV
    // bulk parse) so a cold-start search doesn't jank the UI isolate.
    // [flux.parseFluxZip] is a pure top-level function and [Station] is a
    // plain immutable object graph, so both the message and the result are
    // isolate-sendable.
    return compute(flux.parseFluxZip, Uint8List.fromList(bytes));
  }

  /// Clears the in-memory dataset so the next search re-downloads. For tests.
  @visibleForTesting
  void clearCacheForTest() {
    _cachedStations = null;
    markDatasetRefreshedAt(const Duration(days: 3650));
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    // The flux dataset is the whole country, so a single-station lookup is a
    // local find rather than a network call.
    final all = _cachedStations;
    if (all != null) {
      for (final s in all) {
        if (s.id == stationId) {
          // #2710 — build the structured weekly schedule from the SAME FR
          // adapter the polling path uses, fed the legacy fields the flux
          // parser flattened onto the Station (`openingHoursText` carries the
          // `horaires_jour`-shaped string, `is24h` the automate flag). Pure +
          // total: no hours → `notAvailable`, display falls back to the bridge.
          const adapter = FranceOpeningHoursAdapter();
          final openingHours = adapter.parse(<String, dynamic>{
            'horaires_jour': s.openingHoursText,
            'horaires_automate_24_24': s.is24h ? 'Oui' : 'Non',
          });
          return ServiceResult(
            data: StationDetail(station: s, openingHours: openingHours),
            source: ServiceSource.prixCarburantsApi,
            fetchedAt: DateTime.now(),
          );
        }
      }
    }
    throwDetailUnavailable('Prix Carburants (flux)');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.prixCarburantsApi);
  }
}
