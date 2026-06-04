// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import '../cache/cache_manager.dart';
import '../data/storage_repository.dart';
import '../logging/error_logger.dart';
import '../services/country_service_registry.dart';
import '../services/fuel_service_policy.dart';
import '../services/station_service.dart';
import '../utils/json_extensions.dart';
import 'background_price_shape.dart';
import 'country_alert_strategy.dart';

/// [CountryAlertStrategy] for a [SourceModel.bulkFile] country (#2863) — ES,
/// IT, AR, DK, plus the flag-gated GB-bulk / FR-bulk paths.
///
/// ## Dataset-once + local-filter, zero per-alert network
///
/// Bulk countries publish a whole-country dataset (ES MITECO per-province, IT
/// MIMIT CSV, AR Secretaría de Energía CSV, DK multi-brand aggregate, GB CMA
/// consolidated, FR *flux instantané*) rather than a per-search endpoint. The
/// existing foreground bulk infrastructure already downloads that dataset
/// once, persists it (`PersistentDataset` / `CacheManager`, shared Hive),
/// obeys `datasetTtlSoft` / `datasetTtlHard` via [CachedDatasetMixin], parses
/// heavy CSV in `compute()`, and **local-filters** every search over the
/// cached dataset. The [StationServiceChain] built for a bulk policy routes
/// `searchStations` through its bulk path — no per-key cache, answered straight
/// from the local-filtering primary.
///
/// This strategy REUSES exactly that path: it builds the country's
/// bulk-backed [StationService] via
/// [CountryServiceRegistry.buildBackgroundService] (the same chain + bulk
/// primary the foreground search uses) and answers every alert from it:
///
///  - [searchArea] — a radius search is a local geo-filter over the cached
///    dataset. The first search of a scan may download + persist the dataset
///    (governed by the policy's `datasetTtl`); every search after that — and
///    every scan within the soft TTL — answers from the cache with ZERO
///    network. The twice-daily background cadence (Epic #2860) makes the
///    per-`minInterval` download budget trivially compliant.
///  - [fetchPrices] — the bulk primaries return an empty `getPrices` by design
///    (prices live on the dataset rows the search emits, not behind a
///    per-station endpoint), so per-station price alerts are answered by a
///    tiny local geo-filter around each alert station's last-known coordinates
///    and matched by id — again zero per-alert network once the dataset is
///    cached.
///
/// AU is NOT a bulk country and is excluded upstream by
/// [CountryAlertStrategy.forCountry] (throwing stub #804).
class BulkDatasetAlertStrategy implements CountryAlertStrategy {
  BulkDatasetAlertStrategy({
    required this.countryCode,
    required StorageRepository storage,
    required CacheStrategy cache,
    required FuelServicePolicy policy,
    @visibleForTesting StationService? service,
    @visibleForTesting StationCoordsResolver? coordsResolver,
  })  : _storage = storage,
        _cache = cache,
        _policy = policy,
        _serviceOverride = service,
        _coordsResolver = coordsResolver ?? _defaultCoordsResolver(storage);

  @override
  final String countryCode;

  final StorageRepository _storage;
  final CacheStrategy _cache;
  final FuelServicePolicy _policy;

  /// Test seam: a pre-built bulk service (a fake dataset). Production leaves
  /// this null and builds the real bulk chain on first use.
  final StationService? _serviceOverride;

  /// Resolves an alert station's last-known coordinates so a per-station price
  /// alert can be answered by a tiny local geo-filter (the bulk dataset has no
  /// per-station price endpoint). Defaults to reading the shared Hive caches.
  final StationCoordsResolver _coordsResolver;

  /// The bulk-backed station service, built once per strategy instance so a
  /// scan that runs a radius search AND a per-station price lookup for the same
  /// country shares one in-memory dataset (the dataset is downloaded at most
  /// once per scan, then local-filtered).
  StationService? _service;

  /// Radius (km) of the tiny local geo-filter used to locate a single alert
  /// station within the cached dataset. Small enough to be a cheap local scan,
  /// generous enough to absorb minor coordinate drift between the cached
  /// favorite/station record and the dataset's own coordinates.
  static const double _perStationProbeRadiusKm = 1.0;

  /// `true` when [countryCode]'s registry policy is a bulk-file source — the
  /// discriminator [CountryAlertStrategy.forCountry] branches on (NOT the
  /// country code, so GB/FR follow [BulkMigrationFlags]).
  static bool isBulk(String countryCode) =>
      CountryServiceRegistry.policyFor(countryCode)?.isBulkFile ?? false;

  StationService _bulkService() {
    return _service ??= _serviceOverride ??
        CountryServiceRegistry.buildBackgroundService(
          countryCode,
          storage: _storage,
          cache: _cache,
        );
  }

  /// Radius search = local geo-filter over the cached whole-country dataset.
  /// Returns an empty list on any fault (spooled, never thrown).
  @override
  Future<List<Station>> searchArea(SearchParams params) async {
    try {
      final result = await _bulkService().searchStations(params);
      return result.data;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'BulkDatasetAlertStrategy.searchArea($countryCode)',
        'ttlSoftMin': _policy.datasetTtlSoft.inMinutes,
      }));
      return const [];
    }
  }

  /// Per-station prices by LOCAL geo-filter over the cached dataset — zero
  /// per-alert network once the dataset is cached.
  ///
  /// For each alert station id we resolve its last-known coordinates (from the
  /// shared station/favorite caches) and run a tiny-radius [searchArea] around
  /// them, then pick out the row whose id matches. All probes share one
  /// in-memory dataset, so a country with N per-station alerts triggers at most
  /// one dataset download per scan, never N. Ids whose coordinates cannot be
  /// resolved (never cached / never a favorite) are skipped this scan — they
  /// still get refreshed once they appear in a radius-alert or search result.
  ///
  /// Returns an empty map for no ids or any fault.
  @override
  Future<Map<String, Map<String, dynamic>>> fetchPrices(
    Set<String> stationIds,
  ) async {
    if (stationIds.isEmpty) return const {};
    try {
      final out = <String, Map<String, dynamic>>{};
      for (final id in stationIds) {
        final coords = _coordsResolver(id);
        if (coords == null) continue;
        final found = await searchArea(SearchParams(
          lat: coords.lat,
          lng: coords.lng,
          radiusKm: _perStationProbeRadiusKm,
        ));
        for (final station in found) {
          if (station.id == id) {
            out[id] = stationToTankerkoenigShape(station);
            break;
          }
        }
      }
      return out;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'BulkDatasetAlertStrategy.fetchPrices($countryCode)',
        'ids': stationIds.length,
      }));
      return const {};
    }
  }

  /// Default coordinate resolver: read the alert station's last-known lat/lng
  /// from the shared favorite-station cache first (permanent, never expires),
  /// then the generic `station:<id>` cache the scan + velocity runner populate.
  static StationCoordsResolver _defaultCoordsResolver(
    StorageRepository storage,
  ) {
    return (String stationId) {
      final fav = storage.getFavoriteStationData(stationId);
      final favLat = fav?.getDouble('lat');
      final favLng = fav?.getDouble('lng');
      if (favLat != null && favLng != null) {
        return (lat: favLat, lng: favLng);
      }
      final cached = storage.getCachedData('station:$stationId');
      final data = cached?.getMap('data') ?? cached;
      final lat = data?.getDouble('lat');
      final lng = data?.getDouble('lng');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
      return null;
    };
  }
}

/// Resolves a station id to its last-known coordinates, or null when unknown.
/// Injected so a [BulkDatasetAlertStrategy] test can seed coordinates without
/// a real Hive box.
typedef StationCoordsResolver = ({double lat, double lng})? Function(
  String stationId,
);
