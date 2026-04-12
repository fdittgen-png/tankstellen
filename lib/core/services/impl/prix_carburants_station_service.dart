import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../../features/search/domain/entities/station_amenity.dart';
import 'osm_brand_enricher.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Real French fuel price data from Prix-Carburants (gouv.fr).
/// Free, no API key, no registration. Updated every 10 minutes.
///
/// Strategy: when a postal code is provided, query the native CP filter
/// first (100% accurate), then fall back to geo. For GPS searches without
/// a postal code, query by geo (within_distance) directly.
class PrixCarburantsStationService with StationServiceHelpers implements StationService {
  final OsmBrandEnricher? _enricher;
  final Dio _dio;

  PrixCarburantsStationService({OsmBrandEnricher? enricher, Dio? dio})
      : _enricher = enricher,
        _dio = dio ?? DioFactory.create(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        );

  static const _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets'
      '/prix-des-carburants-en-france-flux-instantane-v2/records';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    List<Map<String, dynamic>> allResults = [];

    final hasPostalCode = params.postalCode != null && params.postalCode!.isNotEmpty;
    final hasValidCoords = params.lat != 0 && params.lng != 0;

    if (hasPostalCode) {
      // Postal code search strategy:
      // 1. Run the native CP filter first — fast, 100% accurate for the
      //    target postal code, and returns stations even when geocoding
      //    is unreliable (e.g., Paris arrondissements).
      // 2. ALSO run the geo query when valid coordinates are present, so
      //    that neighboring postal codes are included when the user picks
      //    a wider radius. Without this, a GPS search from a rural village
      //    (which auto-attaches its postal code via reverse geocoding) would
      //    cap results at the village's own ~5 stations regardless of
      //    radius — bug #315.
      // 3. Merge and dedupe by station id.
      final cpResults = await _queryByPostalCode(params.postalCode!, cancelToken: cancelToken);

      if (hasValidCoords) {
        final geoResults = await _queryByGeo(params.lat, params.lng, params.radiusKm, cancelToken: cancelToken);
        allResults = _mergeById(cpResults, geoResults);
      } else {
        allResults = cpResults;
      }

      // Final fallback: if both queries returned nothing (e.g., invalid CP
      // and no coordinates), give up gracefully.
      if (allResults.isEmpty && !hasValidCoords) {
        allResults = const [];
      }
    } else {
      // GPS / coordinate search: geo query is the only option
      allResults = await _queryByGeo(params.lat, params.lng, params.radiusKm, cancelToken: cancelToken);
    }

    // Parse all results into Station objects
    final parsed = <Station>[];
    for (final r in allResults) {
      final station = _parseStation(r, params.lat, params.lng);
      if (station != null) parsed.add(station);
    }

    // Filter by radius. The postal-code query (`cp='...'`) returns every
    // station sharing that code regardless of distance, so without this
    // post-filter the `radiusKm` parameter would be silently ignored on
    // the CP path — bug #298.
    final stations = filterByRadius(parsed, params.radiusKm);

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
    // is unreliable on this API and often returns 0 results. Preserve one
    // decimal of precision so sub-km radius selections aren't silently
    // rounded to the nearest integer.
    final radiusStr = radiusKm.toStringAsFixed(1);
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'where':
            "within_distance(geom,geom'POINT($lng $lat)',${radiusStr}km)",
        'limit': 50,
      }, cancelToken: cancelToken);
      return _extractResults(response.data);
    } on DioException catch (e) {
      debugPrint('Prix-Carburants geo fetch failed: $e');
      return [];
    }
  }

  /// Merge two raw API result lists, deduplicating by station id.
  /// Stations from [primary] win when an id collides.
  List<Map<String, dynamic>> _mergeById(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> secondary,
  ) {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final r in primary) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty && seen.add(id)) {
        merged.add(r);
      } else if (id.isEmpty) {
        merged.add(r);
      }
    }
    for (final r in secondary) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty && seen.add(id)) {
        merged.add(r);
      } else if (id.isEmpty) {
        merged.add(r);
      }
    }
    return merged;
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
        amenities: parseAmenitiesFromServices(_parseServices(r['services_service'])),
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
      'TOTAL ACCESS': 'TotalEnergies',
      'TOTAL ': 'Total',
      'LECLERC': 'E.Leclerc',
      'CARREFOUR': 'Carrefour',
      'INTERMARCHE': 'Intermarché',
      'INTERMARCHÉ': 'Intermarché',
      'AUCHAN': 'Auchan',
      'SUPER U': 'Super U',
      'SYSTEME U': 'Système U',
      'SYSTÈME U': 'Système U',
      'U EXPRESS': 'Système U',
      'HYPER U': 'Système U',
      'CASINO': 'Casino',
      'GEANT CASINO': 'Casino',
      'BP ': 'BP',
      'SHELL': 'Shell',
      'ESSO': 'Esso',
      'AVIA': 'AVIA',
      'VITO': 'Vito',
      'NETTO': 'Netto',
      'DYNEFF': 'Dyneff',
      'ENI': 'ENI',
      'AGIP': 'ENI',
      'Q8 ': 'Q8',
      'TAMOIL': 'Tamoil',
      'JET ': 'JET',
      'LUKOIL': 'Lukoil',
      'REPSOL': 'Repsol',
      'CEPSA': 'Cepsa',
      'GALP': 'Galp',
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
