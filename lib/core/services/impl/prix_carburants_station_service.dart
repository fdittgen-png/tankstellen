import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import 'osm_brand_enricher.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Real French fuel price data from Prix-Carburants (gouv.fr).
/// Free, no API key, no registration. Updated every 10 minutes.
///
/// Strategy: query by postal code first (most reliable), then expand
/// to nearby postal codes if needed, then fallback to geo query.
class PrixCarburantsStationService with StationServiceHelpers implements StationService {
  final OsmBrandEnricher? _enricher;

  PrixCarburantsStationService({OsmBrandEnricher? enricher})
      : _enricher = enricher;

  static const _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets'
      '/prix-des-carburants-en-france-flux-instantane-v2/records';

  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    List<Map<String, dynamic>> allResults = [];

    // Primary strategy: geo query with within_distance (most accurate)
    allResults = await _queryByGeo(params.lat, params.lng, params.radiusKm, cancelToken: cancelToken);

    // Fallback: if geo returns nothing, try by postal code from SearchParams
    if (allResults.isEmpty && params.postalCode != null && params.postalCode!.isNotEmpty) {
      allResults = await _queryByPostalCode(params.postalCode!, cancelToken: cancelToken);
    }

    // Parse all results into Station objects
    final stations = <Station>[];
    for (final r in allResults) {
      final station = _parseStation(r, params.lat, params.lng);
      if (station != null) stations.add(station);
    }

    // Sort
    sortStations(stations, params);

    if (stations.isEmpty) {
      // Return empty result instead of throwing — route searches
      // query many sample points and empty results at rural points
      // are expected, not errors.
      return ServiceResult(
        data: const [],
        source: ServiceSource.prixCarburantsApi,
        fetchedAt: DateTime.now(),
      );
    }

    // Enrich with brand names from OpenStreetMap (best-effort)
    final enriched = _enricher != null
        ? await _enricher.enrich(stations, cancelToken: cancelToken)
        : stations;

    return ServiceResult(
      data: enriched,
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> _queryByPostalCode(String cp, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'where': "cp='$cp'",
        'limit': 50,
      }, cancelToken: cancelToken);
      return _extractResults(response.data);
    } on DioException catch (e) {
      debugPrint('Prix-Carburants ZIP fetch failed: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> _queryByGeo(
    double lat, double lng, double radiusKm, {CancelToken? cancelToken}
  ) async {
    // Use within_distance with km unit — the distance() function with meters
    // is unreliable on this API and often returns 0 results.
    final radiusInt = radiusKm.round();
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'where':
            "within_distance(geom,geom'POINT($lng $lat)',${radiusInt}km)",
        'limit': 50,
      }, cancelToken: cancelToken);
      return _extractResults(response.data);
    } on DioException catch (e) {
      debugPrint('Prix-Carburants geo fetch failed: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _extractResults(dynamic data) {
    if (data is Map<String, dynamic>) {
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .map((r) => r as Map<String, dynamic>)
          .toList();
    }
    return [];
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    final response = await _dio.get(_baseUrl, queryParameters: {
      'where': "id=$stationId",
      'limit': 1,
    });

    final results = _extractResults(response.data);
    if (results.isEmpty) throw Exception('Station $stationId not found');

    final r = results[0];
    final station = _parseStation(r, 0, 0);
    if (station == null) throw Exception('Failed to parse station');

    final is24h = r['horaires_automate_24_24'] == 'Oui';

    return ServiceResult(
      data: StationDetail(station: station, wholeDay: is24h),
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    final prices = <String, StationPrices>{};
    for (final id in ids.take(10)) {
      try {
        final response = await _dio.get(_baseUrl, queryParameters: {
          'where': "id=$id",
          'limit': 1,
        });
        final results = _extractResults(response.data);
        if (results.isNotEmpty) {
          final r = results[0];
          prices[id] = StationPrices(
            e5: _toDouble(r['sp95_prix']),
            e10: _toDouble(r['e10_prix']),
            diesel: _toDouble(r['gazole_prix']),
            status: 'open',
          );
        }
      } on DioException catch (e) { debugPrint('Prix-Carburants detail fetch failed: $e'); }
    }
    return ServiceResult(
      data: prices,
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  Station? _parseStation(Map<String, dynamic> r, double searchLat, double searchLng) {
    try {
      final geom = r['geom'] as Map<String, dynamic>?;
      double lat = (geom?['lat'] as num?)?.toDouble() ?? 0;
      double lng = (geom?['lon'] as num?)?.toDouble() ?? 0;

      // Some stations have lat/lng in old format (multiplied by 100000)
      if (lat == 0 || lng == 0) {
        final latStr = r['latitude']?.toString() ?? '0';
        final lngStr = r['longitude']?.toString() ?? '0';
        lat = (double.tryParse(latStr) ?? 0) / 100000;
        lng = (double.tryParse(lngStr) ?? 0) / 100000;
      }

      // Use flat price fields (already in EUR, e.g., 2.129)
      final adresse = r['adresse'] as String? ?? '';
      final ville = r['ville'] as String? ?? '';
      final cp = r['cp'] as String? ?? '';

      return Station(
        id: r['id']?.toString() ?? '',
        name: adresse,
        brand: _detectBrand(adresse, r['services_service'], r),
        street: adresse,
        postCode: cp,
        place: ville,
        lat: lat,
        lng: lng,
        dist: roundedDistance(searchLat, searchLng, lat, lng),
        e5: _toDouble(r['sp95_prix']),
        e10: _toDouble(r['e10_prix']),
        e98: _toDouble(r['sp98_prix']),
        diesel: _toDouble(r['gazole_prix']),
        e85: _toDouble(r['e85_prix']),
        lpg: _toDouble(r['gplc_prix']),
        isOpen: true,
        updatedAt: _mostRecentUpdate(r),
        is24h: r['horaires_automate_24_24'] == 'Oui',
        openingHoursText: _parseOpeningHours(r['horaires_jour']),
        services: _parseServices(r['services_service']),
        availableFuels: _parseStringList(r['carburants_disponibles']),
        unavailableFuels: _parseStringList(r['carburants_indisponibles']),
        stationType: r['pop']?.toString(),
        department: r['departement']?.toString(),
        region: r['region']?.toString(),
      );
    } on FormatException catch (e) {
      debugPrint('Prix-Carburants station parse failed: $e');
      return null;
    }
  }

  String? _mostRecentUpdate(Map<String, dynamic> r) {
    final dates = <String>[
      r['gazole_maj']?.toString() ?? '',
      r['sp95_maj']?.toString() ?? '',
      r['e10_maj']?.toString() ?? '',
      r['sp98_maj']?.toString() ?? '',
      r['e85_maj']?.toString() ?? '',
      r['gplc_maj']?.toString() ?? '',
    ].where((d) => d.isNotEmpty).toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a)); // Most recent first
    // Format: "2026-03-23T00:01:00+00:00" → "23/03 00:01"
    try {
      final dt = DateTime.parse(dates.first);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } on FormatException catch (e) {
      debugPrint('Prix-Carburants date parse failed: $e');
      return dates.first.substring(0, 16).replaceAll('T', ' ');
    }
  }

  String? _parseOpeningHours(dynamic hoursStr) {
    if (hoursStr == null) return null;
    final s = hoursStr.toString();
    if (s.isEmpty) return null;
    // Format: "Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30..."
    // Clean up: add spaces around times
    return s
        .replaceAll('Automate-24-24, ', '')
        .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})-(\d{2})\.(\d{2})'),
            (m) => '${m[1]}:${m[2]}-${m[3]}:${m[4]}')
        .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})'),
            (m) => '${m[1]}:${m[2]}')
        .replaceAll(', ', '\n');
  }

  List<String> _parseServices(dynamic services) {
    if (services is List) return services.map((e) => e.toString()).toList();
    return [];
  }

  List<String> _parseStringList(dynamic list) {
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _detectBrand(String adresse, dynamic services, Map<String, dynamic> r) {
    // Check address, ville, and services for known brand names
    final ville = r['ville']?.toString() ?? '';
    final allServices = services is List ? services.join(' ') : (services?.toString() ?? '');
    final text = '$adresse $ville $allServices'.toUpperCase();

    const brandMap = {
      'TOTALENERGIES': 'TotalEnergies',
      'TOTAL ': 'Total',
      'LECLERC': 'E.Leclerc',
      'CARREFOUR': 'Carrefour',
      'INTERMARCHE': 'Intermarché',
      'INTERMARCHÉ': 'Intermarché',
      'AUCHAN': 'Auchan',
      'SUPER U': 'Super U',
      'SYSTEME U': 'Système U',
      'SYSTÈME U': 'Système U',
      'CASINO': 'Casino',
      'BP ': 'BP',
      'SHELL': 'Shell',
      'ESSO': 'Esso',
      'AVIA': 'AVIA',
      'VITO': 'Vito',
      'NETTO': 'Netto',
      'DYNEFF': 'Dyneff',
    };

    for (final entry in brandMap.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    // Fallback: use station type
    final pop = r['pop']?.toString() ?? '';
    if (pop == 'A') return 'Autoroute';
    return 'Station';
  }
}
