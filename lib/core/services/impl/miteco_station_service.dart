import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../mixins/cached_dataset_mixin.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Spanish fuel prices from Geoportal Gasolineras (MITECO).
/// Free, no API key, no registration.
///
/// The API has no coordinate/radius search — only by province/municipality.
/// Strategy: fetch all stations, calculate distances locally, filter by radius.
/// The full dataset (~12,000 stations) is cached aggressively.
class MitecoStationService with StationServiceHelpers, CachedDatasetMixin implements StationService {
  static const _baseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes'
      '/PreciosCarburantes';

  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  );

  // Cache the province list and full station data to avoid repeated large downloads
  List<_Province>? _cachedProvinces;
  List<Map<String, dynamic>>? _cachedStations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // Find nearest province for the search coordinates
      final provinceId = await _findNearestProvince(params.lat, params.lng, cancelToken: cancelToken);

      // Fetch stations for that province
      final rawStations = await _fetchStationsByProvince(provinceId, cancelToken: cancelToken);

      // Parse all stations with distance
      final allStations = <Station>[];
      for (final r in rawStations) {
        final station = _parseStation(r, params.lat, params.lng);
        if (station != null) allStations.add(station);
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

  /// Find the nearest Spanish province to the given coordinates.
  Future<String> _findNearestProvince(double lat, double lng, {CancelToken? cancelToken}) async {
    if (_cachedProvinces == null) {
      final response = await _dio.get('$_baseUrl/Listados/Provincias/', cancelToken: cancelToken);
      if (response.data is! List) {
        throw const ApiException(message: 'Invalid province list response');
      }
      _cachedProvinces = (response.data as List).map((p) {
        return _Province(
          id: p['IDPovincia']?.toString() ?? p['IDProvincia']?.toString() ?? '',
          name: p['Provincia']?.toString() ?? '',
        );
      }).toList();
    }

    // Province approximate centers (major city coordinates)
    // Use these to find which province the user is closest to
    const provinceCenters = {
      '01': (42.8467, -2.6727),   // Álava
      '02': (38.9943, -1.8585),   // Albacete
      '03': (38.3452, -0.4810),   // Alicante
      '04': (36.8340, -2.4637),   // Almería
      '05': (40.6565, -4.6818),   // Ávila
      '06': (38.8794, -6.9707),   // Badajoz
      '07': (39.5696, 2.6502),    // Baleares
      '08': (41.3851, 2.1734),    // Barcelona
      '09': (42.3440, -3.6970),   // Burgos
      '10': (39.4753, -6.3724),   // Cáceres
      '11': (36.5271, -6.2886),   // Cádiz
      '12': (39.9864, -0.0513),   // Castellón
      '13': (38.9860, -3.9273),   // Ciudad Real
      '14': (37.8882, -4.7794),   // Córdoba
      '15': (43.3623, -8.4115),   // A Coruña
      '16': (40.0704, -2.1374),   // Cuenca
      '17': (41.9794, 2.8214),    // Girona
      '18': (37.1773, -3.5986),   // Granada
      '19': (40.6337, -3.1660),   // Guadalajara
      '20': (43.3183, -1.9812),   // Guipúzcoa
      '21': (37.2614, -6.9447),   // Huelva
      '22': (42.1318, -0.4078),   // Huesca
      '23': (37.7796, -3.7849),   // Jaén
      '24': (42.5987, -5.5671),   // León
      '25': (41.6176, 0.6200),    // Lleida
      '26': (42.4650, -2.4500),   // La Rioja
      '27': (43.0099, -7.5562),   // Lugo
      '28': (40.4168, -3.7038),   // Madrid
      '29': (36.7213, -4.4214),   // Málaga
      '30': (37.9922, -1.1307),   // Murcia
      '31': (42.8125, -1.6458),   // Navarra
      '32': (42.3358, -7.8639),   // Ourense
      '33': (43.3619, -5.8494),   // Asturias
      '34': (42.0097, -4.5288),   // Palencia
      '35': (28.1235, -15.4363),  // Las Palmas
      '36': (42.4310, -8.6446),   // Pontevedra
      '37': (40.9701, -5.6635),   // Salamanca
      '38': (28.4636, -16.2518),  // S/C de Tenerife
      '39': (43.4623, -3.8100),   // Cantabria
      '40': (40.9429, -4.1088),   // Segovia
      '41': (37.3891, -5.9845),   // Sevilla
      '42': (41.7636, -2.4649),   // Soria
      '43': (41.1189, 1.2445),    // Tarragona
      '44': (40.3456, -1.1065),   // Teruel
      '45': (39.8628, -4.0273),   // Toledo
      '46': (39.4699, -0.3763),   // Valencia
      '47': (41.6523, -4.7245),   // Valladolid
      '48': (43.2630, -2.9350),   // Vizcaya
      '49': (41.5033, -5.7446),   // Zamora
      '50': (41.6488, -0.8891),   // Zaragoza
      '51': (35.8894, -5.3213),   // Ceuta
      '52': (35.2923, -2.9381),   // Melilla
    };

    String bestId = '28'; // Default: Madrid
    double bestDist = double.infinity;

    for (final entry in provinceCenters.entries) {
      final d = distanceKm(lat, lng, entry.value.$1, entry.value.$2);
      if (d < bestDist) {
        bestDist = d;
        bestId = entry.key;
      }
    }

    return bestId;
  }

  Future<List<Map<String, dynamic>>> _fetchStationsByProvince(
    String provinceId, {CancelToken? cancelToken}
  ) async {
    // Use cache if fresh (< 10 minutes)
    if (_cachedStations != null && isDatasetFresh(const Duration(minutes: 10))) {
      return _cachedStations!;
    }

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
    _cachedStations = list.cast<Map<String, dynamic>>();
    markDatasetRefreshed();
    return _cachedStations!;
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

      return Station(
        id: r['IDEESS']?.toString() ?? '',
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
      debugPrint('MITECO station parse failed: $e\n$st');
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

class _Province {
  final String id;
  final String name;
  const _Province({required this.id, required this.name});
}
