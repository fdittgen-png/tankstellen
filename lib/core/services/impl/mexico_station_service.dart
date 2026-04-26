import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../service_result.dart';
import '../station_service.dart';
import '../mixins/station_service_helpers.dart';

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
    with StationServiceHelpers
    implements StationService {
  final Dio _dio;
  final String _baseUrl;

  MexicoStationService({
    Dio? dio,
    String baseUrl = 'https://publicacionexterna.azurewebsites.net/publicaciones',
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ),
        _baseUrl = baseUrl;

  static const Duration _cacheTtl = Duration(hours: 4);

  List<_CreStation>? _cachedStations;
  DateTime? _lastFetch;

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

  Future<void> _ensureDataLoaded(CancelToken? cancelToken) async {
    if (_cachedStations != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return;
    }

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

    _cachedStations = _mergeFeeds(placesXml: placesXml, pricesXml: pricesXml);
    _lastFetch = DateTime.now();

    if (_cachedStations!.isEmpty) {
      throw const ApiException(
        message: 'CRE feeds parsed to zero stations (schema change?)',
      );
    }
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
        debugPrint('CRE place parse failed: $e\n$st');
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
        debugPrint('CRE price parse failed: $e\n$st');
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
    _lastFetch = null;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throw const ApiException(
      message: 'Station detail not supported for Mexico',
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return ServiceResult(
      data: const {},
      source: ServiceSource.mexicoApi,
      fetchedAt: DateTime.now(),
    );
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
