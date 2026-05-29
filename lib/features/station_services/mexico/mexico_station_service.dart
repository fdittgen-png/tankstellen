// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/logging/error_logger.dart';

/// CRE (Comisión Reguladora de Energía) Mexican fuel price service.
///
/// The previous implementation queried `api.datos.gob.mx/v2/...`
/// which has been retired — requests simply time out in the TLS
/// handshake (see #505). Switched to the CRE public publication
/// hosted on Azure, which is the canonical upstream for the official
/// Mexican fuel price dataset:
///
/// - `https://publicacionexterna.azurewebsites.net/publicaciones/places`
///   returns one `<place>` per station with `<name>`, `<cre_id>`, and
///   `<location><x/><y/></location>` (x = longitude, y = latitude).
/// - `https://publicacionexterna.azurewebsites.net/publicaciones/prices`
///   returns one `<place>` per station with one or more
///   `<gas_price type="regular|premium|diesel">` children. Prices
///   are Mexican pesos per litre.
///
/// Both feeds are joined client-side by `place_id` to produce
/// fully-populated [Station] records. The merged list is cached for
/// 4 hours — the CRE dataset updates several times daily but rarely
/// faster than that.
class MexicoStationService
    with StationServiceHelpers, CachedDatasetMixin
    implements StationService {
  final Dio _dio;
  final String _baseUrl;

  /// #2270 — disk persistence (read-through), or null when no cache is wired.
  /// Persists the merged place+price dataset so MX survives a cold start +
  /// works offline, mirroring DK/AR/ES (#2264 deferred MX on-disk persistence
  /// because [_CreStation] needed a bespoke JSON codec — added now).
  final PersistentDataset<List<_CreStation>>? _persistent;

  /// #2270 — [cache] enables the disk read-through; omit it for the pure
  /// in-memory behaviour the existing parser tests rely on.
  MexicoStationService({
    Dio? dio,
    String baseUrl = 'https://publicacionexterna.azurewebsites.net/publicaciones',
    CacheStrategy? cache,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ),
        _baseUrl = baseUrl,
        _persistent = cache == null
            ? null
            : PersistentDataset<List<_CreStation>>(
                cache: cache,
                countryCode: 'MX',
                datasetName: 'stations',
                source: ServiceSource.mexicoApi,
                serialize: (stations) =>
                    {'stations': stations.map((s) => s.toJson()).toList()},
                deserialize: (json) {
                  final list = json['stations'] as List<dynamic>?;
                  if (list == null) return null;
                  return list
                      .map((j) => _CreStation.fromJson(
                          Map<String, dynamic>.from(j as Map)))
                      .toList();
                },
              );

  static const Duration _cacheTtl = Duration(hours: 4);

  // #2270 — soft/hard dataset TTLs for the persisted read-through. Soft mirrors
  // the 4-hour merge cadence (_cacheTtl); the 24-hour hard bound is the offline
  // grace window past which a blocking re-pull is forced.
  static const Duration _softTtl = _cacheTtl;
  static const Duration _hardTtl = Duration(hours: 24);

  List<_CreStation>? _cachedStations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken);
      final cached = _cachedStations ?? const <_CreStation>[];

      final stations = <Station>[];
      for (final c in cached) {
        final dist = distanceKm(params.lat, params.lng, c.lat, c.lng);
        if (dist > params.radiusKm) continue;
        stations.add(Station(
          id: 'mx-${c.id}',
          name: c.name,
          brand: c.name.split(' ').first,
          street: '',
          postCode: '',
          place: '',
          lat: c.lat,
          lng: c.lng,
          dist: dist,
          e5: c.regular,
          e10: c.premium,
          diesel: c.diesel,
          isOpen: true,
        ));
      }

      stations.sort((a, b) => a.dist.compareTo(b.dist));

      return ServiceResult(
        data: stations.take(50).toList(),
        source: ServiceSource.mexicoApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'CRE API error', stackTrace: st);
    }
  }

  // #2264 — migrated onto CachedDatasetMixin: the manual _lastFetch + TTL
  // diff is replaced by loadDataset's guard→fetch→store→mark idiom, matching
  // the other bulk-dataset services (ES/IT/AR/DK).
  // #2270 — when a cache is wired the merged dataset is persisted to Hive with
  // a disk read-through so it survives a cold start + works offline.
  Future<void> _ensureDataLoaded(CancelToken? cancelToken) {
    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — preserve the legacy in-memory path.
      return loadDataset<List<_CreStation>>(
        cached: _cachedStations,
        ttl: _cacheTtl,
        fetch: () => _fetchMerged(cancelToken),
        store: (value) => _cachedStations = value,
      );
    }
    return loadPersistentDataset<List<_CreStation>>(
      cached: _cachedStations,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: persistent,
      fetch: () => _fetchMerged(cancelToken),
      store: (value) => _cachedStations = value,
    );
  }

  Future<List<_CreStation>> _fetchMerged(CancelToken? cancelToken) async {
    final responses = await Future.wait([
      _dio.get<String>(
        '$_baseUrl/places',
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      ),
      _dio.get<String>(
        '$_baseUrl/prices',
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      ),
    ]);

    final placesXml = responses[0].data;
    final pricesXml = responses[1].data;
    if (placesXml == null || placesXml.isEmpty) {
      throw const ApiException(
        message: 'CRE /places feed returned an empty body',
      );
    }
    if (pricesXml == null || pricesXml.isEmpty) {
      throw const ApiException(
        message: 'CRE /prices feed returned an empty body',
      );
    }

    final merged = _mergeFeeds(placesXml: placesXml, pricesXml: pricesXml);
    if (merged.isEmpty) {
      throw const ApiException(
        message: 'CRE feeds parsed to zero stations (schema change?)',
      );
    }
    return merged;
  }

  /// Parses the `/places` and `/prices` XML feeds and joins them by
  /// `place_id`. The merged list drives [searchStations] via the
  /// in-memory cache.
  static List<_CreStation> _mergeFeeds({
    required String placesXml,
    required String pricesXml,
  }) {
    final places = _parsePlaces(placesXml);
    final prices = _parsePrices(pricesXml);

    final merged = <_CreStation>[];
    for (final entry in places.entries) {
      final meta = entry.value;
      final p = prices[entry.key] ?? const _CrePrices();
      merged.add(_CreStation(
        id: entry.key,
        name: meta.name,
        lat: meta.lat,
        lng: meta.lng,
        regular: p.regular,
        premium: p.premium,
        diesel: p.diesel,
      ));
    }
    return merged;
  }

  static Map<String, _CrePlace> _parsePlaces(String xmlString) {
    final doc = XmlDocument.parse(xmlString);
    final out = <String, _CrePlace>{};
    for (final node in doc.findAllElements('place')) {
      try {
        final id = node.getAttribute('place_id');
        if (id == null) continue;
        final name =
            node.findElements('name').firstOrNull?.innerText.trim() ?? '';
        final location = node.findElements('location').firstOrNull;
        if (location == null) continue;
        final x = double.tryParse(
          location.findElements('x').firstOrNull?.innerText.trim() ?? '',
        );
        final y = double.tryParse(
          location.findElements('y').firstOrNull?.innerText.trim() ?? '',
        );
        if (x == null || y == null) continue;
        out[id] = _CrePlace(name: name, lat: y, lng: x);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'CRE place parse failed'}));
        continue;
      }
    }
    return out;
  }

  static Map<String, _CrePrices> _parsePrices(String xmlString) {
    final doc = XmlDocument.parse(xmlString);
    final out = <String, _CrePrices>{};
    for (final node in doc.findAllElements('place')) {
      try {
        final id = node.getAttribute('place_id');
        if (id == null) continue;
        double? regular, premium, diesel;
        for (final gp in node.findElements('gas_price')) {
          final type = gp.getAttribute('type');
          final value = double.tryParse(gp.innerText.trim());
          if (value == null) continue;
          switch (type) {
            case 'regular':
              regular = value;
              break;
            case 'premium':
              premium = value;
              break;
            case 'diesel':
              diesel = value;
              break;
          }
        }
        out[id] = _CrePrices(
          regular: regular,
          premium: premium,
          diesel: diesel,
        );
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'CRE price parse failed'}));
        continue;
      }
    }
    return out;
  }

  /// Clears the merged-station cache so the next search re-fetches
  /// both feeds. Intended for tests.
  @visibleForTesting
  void clearCacheForTest() {
    _cachedStations = null;
    // #2264 — CachedDatasetMixin owns the freshness clock now; expire it so
    // the next search re-fetches.
    markDatasetRefreshedAt(const Duration(days: 3650));
  }

  // #2264 — route the unsupported endpoints through the shared helpers
  // (throwDetailUnavailable / emptyPricesResult) like the other services.
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('CRE API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.mexicoApi);
  }
}

/// Merged place+price record used for in-memory caching. The public
/// [Station] is built from this when [MexicoStationService.searchStations]
/// runs, so the cached shape is whatever is cheapest to build.
class _CreStation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double? regular;
  final double? premium;
  final double? diesel;

  const _CreStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.regular,
    required this.premium,
    required this.diesel,
  });

  /// #2270 — compact JSON for the persisted dataset (single-letter keys keep
  /// the ~13k-station merged dataset's Hive footprint down).
  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        'la': lat,
        'lo': lng,
        if (regular != null) 'r': regular,
        if (premium != null) 'p': premium,
        if (diesel != null) 'd': diesel,
      };

  factory _CreStation.fromJson(Map<String, dynamic> j) => _CreStation(
        id: j['i'] as String? ?? '',
        name: j['n'] as String? ?? '',
        lat: (j['la'] as num?)?.toDouble() ?? 0,
        lng: (j['lo'] as num?)?.toDouble() ?? 0,
        regular: (j['r'] as num?)?.toDouble(),
        premium: (j['p'] as num?)?.toDouble(),
        diesel: (j['d'] as num?)?.toDouble(),
      );
}

class _CrePlace {
  final String name;
  final double lat;
  final double lng;
  const _CrePlace({required this.name, required this.lat, required this.lng});
}

class _CrePrices {
  final double? regular;
  final double? premium;
  final double? diesel;
  const _CrePrices({this.regular, this.premium, this.diesel});
}
