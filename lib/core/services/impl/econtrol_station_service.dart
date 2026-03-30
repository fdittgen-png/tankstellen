import 'package:dio/dio.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Austrian fuel prices from E-Control Spritpreisrechner.
/// Free, no API key, no registration.
///
/// The API only supports 3 fuel types: DIE (Diesel), SUP (Super 95), GAS (CNG).
/// We query DIE + SUP to get both diesel and gasoline prices, then merge results.
class EControlStationService with StationServiceHelpers implements StationService {
  static const _baseUrl = 'https://api.e-control.at/sprit/1.0';

  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // Query both diesel and super to get all prices
      final results = await Future.wait([
        _queryByCoordinates(params.lat, params.lng, 'DIE', cancelToken: cancelToken),
        _queryByCoordinates(params.lat, params.lng, 'SUP', cancelToken: cancelToken),
      ]);

      final dieselStations = results[0];
      final superStations = results[1];

      // Merge: combine prices from both queries by station ID
      final merged = <int, Station>{};

      for (final s in dieselStations) {
        final id = int.tryParse(s.id) ?? 0;
        merged[id] = s;
      }

      for (final s in superStations) {
        final id = int.tryParse(s.id) ?? 0;
        final existing = merged[id];
        if (existing != null) {
          // Merge e5 from super query into existing diesel station
          merged[id] = existing.copyWith(
            e5: s.e5,
            e10: s.e5, // Austrian "Super 95" maps to both E5 and E10
          );
        } else {
          merged[id] = s.copyWith(
            e5: s.e5,
            e10: s.e5,
          );
        }
      }

      // Filter by radius; if nothing found, return all (API already limits to nearest ~10)
      final allStations = merged.values.toList();
      final stations = filterByRadius(allStations, params.radiusKm);

      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.eControlApi);
    } on DioException catch (e) {
      throwApiException(e);
    }
  }

  Future<List<Station>> _queryByCoordinates(
    double lat, double lng, String fuelType, {CancelToken? cancelToken}
  ) async {
    final response = await _dio.get(
      '$_baseUrl/search/gas-stations/by-address',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'fuelType': fuelType,
        'includeClosed': 'true',
      },
      cancelToken: cancelToken,
    );

    if (response.data is! List) return [];

    final stations = <Station>[];
    for (final r in response.data as List) {
      final station = _parseStation(r, lat, lng, fuelType);
      if (station != null) stations.add(station);
    }
    return stations;
  }

  Station? _parseStation(
    Map<String, dynamic> r, double searchLat, double searchLng, String fuelType,
  ) {
    try {
      final location = r['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (location['longitude'] as num?)?.toDouble() ?? 0;

      // Distance from API or calculated
      final apiDist = (r['distance'] as num?)?.toDouble();

      // Parse price
      double? price;
      final prices = r['prices'] as List<dynamic>? ?? [];
      for (final p in prices) {
        if (p is Map<String, dynamic>) {
          price = (p['amount'] as num?)?.toDouble();
        }
      }

      // Opening hours text
      final openingHours = r['openingHours'] as List<dynamic>? ?? [];
      final hoursText = openingHours.map((oh) {
        if (oh is Map<String, dynamic>) {
          return '${oh['label'] ?? oh['day']}: ${oh['from']}-${oh['to']}';
        }
        return '';
      }).where((s) => s.isNotEmpty).join(', ');

      final name = r['name']?.toString() ?? '';
      final isOpen = r['open'] as bool? ?? true;

      return Station(
        id: r['id']?.toString() ?? '',
        name: name,
        brand: _extractBrand(name),
        street: location['address']?.toString() ?? '',
        postCode: location['postalCode']?.toString() ?? '',
        place: location['city']?.toString() ?? '',
        lat: lat,
        lng: lng,
        dist: apiDist ?? roundedDistance(searchLat, searchLng, lat, lng),
        e5: fuelType == 'SUP' ? price : null,
        e10: fuelType == 'SUP' ? price : null,
        diesel: fuelType == 'DIE' ? price : null,
        lpg: fuelType == 'GAS' ? price : null,
        isOpen: isOpen,
        openingHoursText: hoursText.isNotEmpty ? hoursText : null,
      );
    } on FormatException catch (_) {
      return null;
    }
  }

  /// Extract brand name from station name.
  /// E-Control names are like "BP", "Shell Austria", "AVANTI - Wien Platz 1".
  String _extractBrand(String name) {
    const brands = [
      'OMV', 'BP', 'Shell', 'Jet', 'Eni', 'Avanti', 'Turmöl',
      'IQ', 'Avia', 'A1', 'Genol', 'Lagerhaus', 'SB',
    ];
    final upper = name.toUpperCase();
    for (final b in brands) {
      if (upper.startsWith(b.toUpperCase())) return b;
    }
    // Use first word as brand
    final firstWord = name.split(RegExp(r'[\s\-]')).first;
    return firstWord.isNotEmpty ? firstWord : name;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('E-Control API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.eControlApi);
  }
}
