import 'dart:math';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../constants/app_constants.dart';
import '../../storage/hive_storage.dart';
import '../../../features/search/domain/entities/station.dart';

part 'osm_brand_enricher.g.dart';

@Riverpod(keepAlive: true)
OsmBrandEnricher osmBrandEnricher(Ref ref) {
  return OsmBrandEnricher(ref.watch(hiveStorageProvider));
}

/// Enriches fuel stations with brand names using Nominatim search.
/// Brands are cached persistently in Hive for instant lookup.
class OsmBrandEnricher {
  final HiveStorage _storage;
  final Map<String, String> _sessionCache = {};

  OsmBrandEnricher(this._storage);

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': AppConstants.userAgent},
  ));

  static DateTime? _lastRequest;

  Future<List<Station>> enrich(List<Station> stations) async {
    if (stations.isEmpty) return stations;

    var result = _applyCachedBrands(stations);

    final uncached = result.where(_needsBrand).toList();
    if (uncached.isEmpty) return result;

    await _fetchBrandsFromNominatim(stations);
    result = _applyCachedBrands(result);

    return result;
  }

  bool _needsBrand(Station s) =>
      s.brand.isEmpty || s.brand == 'Station' || s.brand == 'Autoroute';

  Future<void> _fetchBrandsFromNominatim(List<Station> stations) async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      if (elapsed < const Duration(seconds: 2)) {
        await Future<void>.delayed(
          Duration(milliseconds: 2000 - elapsed.inMilliseconds),
        );
      }
    }

    try {
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (final s in stations) {
        if (s.lat < minLat) minLat = s.lat;
        if (s.lat > maxLat) maxLat = s.lat;
        if (s.lng < minLng) minLng = s.lng;
        if (s.lng > maxLng) maxLng = s.lng;
      }
      minLat -= 0.01; maxLat += 0.01;
      minLng -= 0.01; maxLng += 0.01;

      _lastRequest = DateTime.now();

      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'limit': 50,
          'amenity': 'fuel',
          'viewbox': '$minLng,$minLat,$maxLng,$maxLat',
          'bounded': '1',
        },
      );

      final results = response.data;
      if (results is! List) return;

      final pois = <_Poi>[];
      for (final r in results) {
        if (r is! Map) continue;
        final name = r['name']?.toString();
        final lat = double.tryParse(r['lat']?.toString() ?? '');
        final lng = double.tryParse(r['lon']?.toString() ?? '');
        if (name != null && name.isNotEmpty && lat != null && lng != null) {
          pois.add(_Poi(name, lat, lng));
        }
      }

      for (final s in stations) {
        if (!_needsBrand(s)) continue;
        _Poi? nearest;
        double nearestDist = 0.2;
        for (final poi in pois) {
          final d = _distKm(s.lat, s.lng, poi.lat, poi.lng);
          if (d < nearestDist) {
            nearestDist = d;
            nearest = poi;
          }
        }
        if (nearest != null) {
          _sessionCache[s.id] = nearest.name;
          _storage.putSetting('brand_${s.id}', nearest.name);
        }
      }
    } on DioException catch (_) {}
  }

  List<Station> _applyCachedBrands(List<Station> stations) {
    return stations.map((s) {
      if (!_needsBrand(s)) return s;
      final cached = _sessionCache[s.id];
      if (cached != null) return s.copyWith(brand: cached);
      final persisted = _storage.getSetting('brand_${s.id}');
      if (persisted is String) {
        _sessionCache[s.id] = persisted;
        return s.copyWith(brand: persisted);
      }
      return s;
    }).toList();
  }

  static double _distKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

class _Poi {
  final String name;
  final double lat;
  final double lng;
  _Poi(this.name, this.lat, this.lng);
}
