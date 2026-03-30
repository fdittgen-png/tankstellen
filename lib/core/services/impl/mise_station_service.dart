import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../mixins/cached_dataset_mixin.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Italian fuel prices from MIMIT (ex-MISE) open data CSV files.
/// Free, no API key, no registration. Updated daily at 08:00.
///
/// Downloads two CSV files:
/// - anagrafica_impianti_attivi.csv — station registry (id, brand, address, lat/lng)
/// - prezzo_alle_8.csv — current prices (id, fuel type, price, self-service flag)
///
/// Joins them by idImpianto, calculates distances locally, returns nearby stations.
class MiseStationService with StationServiceHelpers, CachedDatasetMixin implements StationService {
  static const _stationsUrl =
      'https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv';
  static const _pricesUrl =
      'https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv';

  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    responseType: ResponseType.plain,
  );

  // In-memory cache of parsed data
  Map<String, _StationData>? _cachedStations;
  Map<String, _PriceData>? _cachedPrices;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken: cancelToken);

      final stations = <Station>[];

      for (final entry in _cachedStations!.entries) {
        final s = entry.value;
        final dist = distanceKm(params.lat, params.lng, s.lat, s.lng);
        if (dist > params.radiusKm) continue;

        final prices = _cachedPrices![entry.key];

        stations.add(Station(
          id: entry.key,
          name: s.name.isNotEmpty ? s.name : s.brand,
          brand: s.brand,
          street: s.address,
          postCode: '',
          place: s.city,
          lat: s.lat,
          lng: s.lng,
          dist: roundedDistance(params.lat, params.lng, s.lat, s.lng),
          e5: prices?.benzinaSelf ?? prices?.benzinaServed,
          e10: prices?.benzinaSelf ?? prices?.benzinaServed,
          diesel: prices?.gasolioSelf ?? prices?.gasolioServed,
          lpg: prices?.gpl,
          cng: prices?.metano,
          isOpen: true,
          updatedAt: prices?.updatedAt,
          stationType: s.type == 'Autostradale' ? 'A' : 'R',
        ));
      }

      // Sort
      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.miseApi);
    } on DioException catch (e) {
      throwApiException(e, defaultMessage: 'Errore di rete');
    }
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) async {
    // Refresh cache every 2 hours
    if (_cachedStations != null &&
        _cachedPrices != null &&
        isDatasetFresh(const Duration(hours: 2))) {
      return;
    }

    // Download both files in parallel
    final results = await Future.wait([
      _dio.get<String>(_stationsUrl, cancelToken: cancelToken),
      _dio.get<String>(_pricesUrl, cancelToken: cancelToken),
    ]);

    _cachedStations = _parseStationsCsv(results[0].data ?? '');
    _cachedPrices = _parsePricesCsv(results[1].data ?? '');
    markDatasetRefreshed();
  }

  Map<String, _StationData> _parseStationsCsv(String csv) {
    final stations = <String, _StationData>{};
    final lines = const LineSplitter().convert(csv);

    // Skip first line (date header) and second line (column headers)
    for (var i = 2; i < lines.length; i++) {
      final parts = lines[i].split('|');
      if (parts.length < 10) continue;

      final id = parts[0].trim();
      final lat = double.tryParse(parts[8].trim()) ?? 0;
      final lng = double.tryParse(parts[9].trim()) ?? 0;
      if (lat == 0 || lng == 0) continue;

      stations[id] = _StationData(
        brand: parts[2].trim(),
        type: parts[3].trim(),
        name: parts[4].trim(),
        address: parts[5].trim(),
        city: parts[6].trim(),
        province: parts[7].trim(),
        lat: lat,
        lng: lng,
      );
    }
    return stations;
  }

  Map<String, _PriceData> _parsePricesCsv(String csv) {
    final prices = <String, _PriceData>{};
    final lines = const LineSplitter().convert(csv);

    // Skip first line (date header) and second line (column headers)
    for (var i = 2; i < lines.length; i++) {
      final parts = lines[i].split('|');
      if (parts.length < 5) continue;

      final id = parts[0].trim();
      final fuel = parts[1].trim().toLowerCase();
      final price = double.tryParse(parts[2].trim());
      final isSelf = parts[3].trim() == '1';
      final dateStr = parts[4].trim();

      if (price == null) continue;

      final existing = prices[id] ?? _PriceData();

      if (fuel.contains('benzina')) {
        if (isSelf) {
          existing.benzinaSelf ??= price;
        } else {
          existing.benzinaServed ??= price;
        }
      } else if (fuel.contains('gasolio') || fuel.contains('diesel')) {
        if (isSelf) {
          existing.gasolioSelf ??= price;
        } else {
          existing.gasolioServed ??= price;
        }
      } else if (fuel.contains('gpl')) {
        existing.gpl ??= price;
      } else if (fuel.contains('metano')) {
        existing.metano ??= price;
      }

      // Keep the most recent update time
      if (dateStr.isNotEmpty && (existing.updatedAt == null || dateStr.compareTo(existing.updatedAt!) > 0)) {
        // Convert "20/03/2026 20:00:08" → "20/03 20:00"
        final dtParts = dateStr.split(' ');
        if (dtParts.length >= 2) {
          final datePart = dtParts[0].split('/');
          final timePart = dtParts[1].split(':');
          if (datePart.length >= 2 && timePart.length >= 2) {
            existing.updatedAt = '${datePart[0]}/${datePart[1]} ${timePart[0]}:${timePart[1]}';
          }
        }
      }

      prices[id] = existing;
    }
    return prices;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('MISE API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.miseApi);
  }
}

class _StationData {
  final String brand;
  final String type;
  final String name;
  final String address;
  final String city;
  final String province;
  final double lat;
  final double lng;

  const _StationData({
    required this.brand,
    required this.type,
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.lat,
    required this.lng,
  });
}

class _PriceData {
  double? benzinaSelf;
  double? benzinaServed;
  double? gasolioSelf;
  double? gasolioServed;
  double? gpl;
  double? metano;
  String? updatedAt;
}
