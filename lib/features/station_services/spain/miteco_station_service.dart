// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/logging/error_logger.dart';
import 'spain_provinces.dart';

/// Spanish fuel prices from Geoportal Gasolineras (MITECO).
/// Free, no API key, no registration.
///
/// The API has no coordinate/radius search — only by province/municipality.
/// Strategy: fetch all stations, calculate distances locally, filter by radius.
/// The full dataset (~12,000 stations) is cached aggressively.
class MitecoStationService with StationServiceHelpers implements StationService {
  static const String defaultBaseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes'
      '/PreciosCarburantes';

  final Dio _dio;
  final String _baseUrl;
  final CacheStrategy? _cache;

  /// #2181 — Dio injectable for tests; defaults to the standard factory.
  /// #2193 — [baseUrl] injectable too, harmonising the override surface
  /// with Portugal / Slovenia / South Korea; defaults to [defaultBaseUrl].
  /// #2264 — [cache] enables per-province disk persistence (read-through);
  /// omit it for the pure in-memory behaviour the parser tests rely on.
  MitecoStationService({Dio? dio, String? baseUrl, CacheStrategy? cache})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl,
        _cache = cache;

  // #2264 — soft/hard dataset TTLs mirror the ES FuelServicePolicy (soft 6 h,
  // hard 24 h). The legacy single-list 10-minute cache is replaced by a
  // per-province cache so province A's stations are never served for B.
  static const Duration _softTtl = Duration(hours: 6);
  static const Duration _hardTtl = Duration(hours: 24);

  /// Per-province in-memory cache, keyed by `IDProvincia`. The previous single
  /// unkeyed `_cachedStations` list meant the first province searched was
  /// served for every later search regardless of location (#2264).
  final Map<String, _ProvinceCache> _byProvince = {};

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // #2264 — fetch every province overlapping the search radius (a point
      // near a border touches several) and merge, so a station physically
      // nearby but administratively in the neighbour is not dropped.
      final provinceIds =
          spainProvincesNear(params.lat, params.lng, params.radiusKm);

      final allStations = <Station>[];
      final seenIds = <String>{};
      for (final provinceId in provinceIds) {
        final rawStations =
            await _stationsForProvince(provinceId, cancelToken: cancelToken);
        for (final r in rawStations) {
          final station = _parseStation(r, params.lat, params.lng);
          // Dedupe across province borders by station id.
          if (station != null && seenIds.add(station.id)) {
            allStations.add(station);
          }
        }
      }

      // Filter by radius; if nothing found, return nearest 20
      final stations = filterByRadius(allStations, params.radiusKm);

      // Sort
      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.mitecoApi, limit: 50);
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'Error de red', stackTrace: st);
    }
  }

  /// Returns the raw station rows for one province, served from (in order):
  /// the fresh in-memory copy, the persisted Hive copy (read-through, when a
  /// cache is wired), then the network — and persisted on a fresh fetch.
  Future<List<Map<String, dynamic>>> _stationsForProvince(
    String provinceId, {
    CancelToken? cancelToken,
  }) async {
    final mem = _byProvince[provinceId];
    if (mem != null &&
        DateTime.now().difference(mem.fetchedAt) < _softTtl) {
      return mem.rows;
    }

    final persistent = _persistentFor(provinceId);
    if (persistent != null) {
      final disk = persistent.read();
      if (disk != null && disk.age <= _hardTtl) {
        _byProvince[provinceId] =
            _ProvinceCache(disk.value, DateTime.now().subtract(disk.age));
        if (disk.age <= _softTtl) return disk.value;
      }
    }

    try {
      final rows = await _fetchProvince(provinceId, cancelToken: cancelToken);
      _byProvince[provinceId] = _ProvinceCache(rows, DateTime.now());
      await persistent?.write(rows, hardTtl: _hardTtl);
      return rows;
    } on Object {
      // Network failed — serve any persisted/in-memory copy rather than throw.
      final disk = persistent?.read();
      if (disk != null) {
        _byProvince[provinceId] =
            _ProvinceCache(disk.value, DateTime.now().subtract(disk.age));
        return disk.value;
      }
      if (mem != null) return mem.rows;
      rethrow;
    }
  }

  PersistentDataset<List<Map<String, dynamic>>>? _persistentFor(
    String provinceId,
  ) {
    final cache = _cache;
    if (cache == null) return null;
    return PersistentDataset<List<Map<String, dynamic>>>(
      cache: cache,
      countryCode: 'ES',
      datasetName: 'province-$provinceId',
      source: ServiceSource.mitecoApi,
      serialize: (rows) => {'rows': rows},
      deserialize: (json) => (json['rows'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProvince(
    String provinceId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/EstacionesTerrestres/FiltroProvincia/$provinceId',
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid MITECO response');
    }

    if (data['ResultadoConsulta'] != 'OK') {
      throw ApiException(
        message: data['ResultadoConsulta']?.toString() ?? 'API error',
      );
    }

    final list = data['ListaEESSPrecio'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Station? _parseStation(
    Map<String, dynamic> r, double searchLat, double searchLng,
  ) {
    try {
      // Coordinates use comma as decimal separator
      final lat = _parseCommaDouble(r['Latitud']?.toString());
      final lng = _parseCommaDouble(r['Longitud (WGS84)']?.toString());
      if (lat == null || lng == null) return null;

      final brand = r['Rótulo']?.toString() ?? '';
      final address = r['Dirección']?.toString() ?? '';
      final city = r['Localidad']?.toString() ?? '';
      final postalCode = r['C.P.']?.toString() ?? '';
      final horario = r['Horario']?.toString() ?? '';

      // Determine if open based on schedule (simplistic: assume open if horario is not empty)
      final isOpen = horario.isNotEmpty && horario != 'Cerrado';

      // #753 — `es-` prefix so a MITECO `IDEESS` (bare numeric) cannot
      // collide with another country's numeric id space.
      final rawId = r['IDEESS']?.toString() ?? '';
      return Station(
        id: rawId.isEmpty
            ? ''
            : (rawId.startsWith('es-') ? rawId : 'es-$rawId'),
        name: brand.isNotEmpty ? brand : address,
        brand: brand,
        street: address,
        postCode: postalCode,
        place: city,
        lat: lat,
        lng: lng,
        dist: roundedDistance(searchLat, searchLng, lat, lng),
        e5: _parseCommaDouble(r['Precio Gasolina 95 E5']?.toString()),
        e10: _parseCommaDouble(r['Precio Gasolina 95 E10']?.toString()),
        e98: _parseCommaDouble(r['Precio Gasolina 98 E5']?.toString()),
        diesel: _parseCommaDouble(r['Precio Gasoleo A']?.toString()),
        dieselPremium: _parseCommaDouble(r['Precio Gasoleo Premium']?.toString()),
        e85: _parseCommaDouble(r['Precio Gasolina 95 E85']?.toString()),
        lpg: _parseCommaDouble(r['Precio Gases licuados del petróleo']?.toString()),
        cng: _parseCommaDouble(r['Precio Gas Natural Comprimido']?.toString()),
        isOpen: isOpen,
        openingHoursText: horario.isNotEmpty ? horario : null,
        stationType: r['Margen']?.toString(),
      );
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'MITECO station parse failed'}));
      return null;
    }
  }

  /// Parse a number string that uses comma as decimal separator.
  /// "1,817" → 1.817, "" → null, null → null
  double? _parseCommaDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('MITECO API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.mitecoApi);
  }
}

/// One province's cached raw rows + when they were fetched (#2264). Keyed by
/// `IDProvincia` in [MitecoStationService._byProvince] so province A's
/// stations are never served for a search in province B.
class _ProvinceCache {
  final List<Map<String, dynamic>> rows;
  final DateTime fetchedAt;
  const _ProvinceCache(this.rows, this.fetchedAt);
}
