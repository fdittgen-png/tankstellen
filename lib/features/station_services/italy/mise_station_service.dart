// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/services/utils/csv_parser.dart';

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

  final Dio _dio;

  /// #2270 — disk persistence (read-through), or null when no cache is wired.
  /// Persists the parsed registry+price dataset so IT survives a cold start +
  /// works offline, mirroring DK/AR/ES (#2264 deferred IT on-disk persistence
  /// because its private record types needed bespoke JSON codecs — added now).
  final PersistentDataset<_MiseDataset>? _persistent;

  /// #2181 — Dio injectable for tests; defaults to the standard factory.
  /// #2270 — [cache] enables the disk read-through; omit it for the pure
  /// in-memory behaviour the existing parser tests rely on.
  MiseStationService({Dio? dio, CacheStrategy? cache})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              responseType: ResponseType.plain,
            ),
        _persistent = cache == null
            ? null
            : PersistentDataset<_MiseDataset>(
                cache: cache,
                countryCode: 'IT',
                datasetName: 'stations',
                source: ServiceSource.miseApi,
                serialize: _serializeDataset,
                deserialize: _deserializeDataset,
              );

  // #2270 — soft/hard dataset TTLs mirror the IT FuelServicePolicy in the
  // registry (soft 6 h, hard 24 h). The legacy 2-hour in-memory TTL is the
  // soft bound now; the persisted read-through governs offline freshness.
  static const Duration _softTtl = Duration(hours: 6);
  static const Duration _hardTtl = Duration(hours: 24);

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

        // #753 — `it-` prefix so a MISE registry id (bare numeric)
        // cannot collide with another country's numeric id space.
        final rawId = entry.key;
        stations.add(Station(
          id: rawId.isEmpty
              ? ''
              : (rawId.startsWith('it-') ? rawId : 'it-$rawId'),
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
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'Errore di rete', stackTrace: st);
    }
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) {
    // Both maps are populated from a single download, so they're cached
    // together as a record — present only when both are non-null.
    final cached = (_cachedStations != null && _cachedPrices != null)
        ? (_cachedStations!, _cachedPrices!)
        : null;
    Future<_MiseDataset> fetch() async {
      // Download both files in parallel
      final results = await Future.wait([
        _dio.get<String>(_stationsUrl, cancelToken: cancelToken),
        _dio.get<String>(_pricesUrl, cancelToken: cancelToken),
      ]);
      return (
        _parseStationsCsv(results[0].data ?? ''),
        _parsePricesCsv(results[1].data ?? ''),
      );
    }

    void store(_MiseDataset value) {
      _cachedStations = value.$1;
      _cachedPrices = value.$2;
    }

    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — preserve the legacy in-memory path.
      return loadDataset<_MiseDataset>(
        cached: cached,
        ttl: const Duration(hours: 2),
        fetch: fetch,
        store: store,
      );
    }
    // #2270 — disk read-through: survives cold start + offline.
    return loadPersistentDataset<_MiseDataset>(
      cached: cached,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: persistent,
      fetch: fetch,
      store: store,
    );
  }

  Map<String, _StationData> _parseStationsCsv(String csv) {
    final stations = <String, _StationData>{};
    final rows = CsvParser.parseAll(csv, skipLines: 2, separator: '|');

    for (final parts in rows) {
      if (parts.length < 10) continue;

      final id = parts[0];
      final lat = double.tryParse(parts[8]) ?? 0;
      final lng = double.tryParse(parts[9]) ?? 0;
      if (lat == 0 || lng == 0) continue;

      stations[id] = _StationData(
        brand: parts[2],
        type: parts[3],
        name: parts[4],
        address: parts[5],
        city: parts[6],
        province: parts[7],
        lat: lat,
        lng: lng,
      );
    }
    return stations;
  }

  Map<String, _PriceData> _parsePricesCsv(String csv) {
    final prices = <String, _PriceData>{};
    final rows = CsvParser.parseAll(csv, skipLines: 2, separator: '|');

    for (final parts in rows) {
      if (parts.length < 5) continue;

      final id = parts[0];
      final fuel = parts[1].toLowerCase();
      final price = double.tryParse(parts[2]);
      final isSelf = parts[3] == '1';
      final dateStr = parts[4];

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

/// #2270 — the parsed MISE dataset: the station registry joined-by-id with the
/// current prices. Both maps come from a single (two-file) download, so they
/// are persisted and rehydrated together as one record.
typedef _MiseDataset = (Map<String, _StationData>, Map<String, _PriceData>);

/// #2270 — JSON codec for the persisted IT dataset. Single-letter keys keep
/// the Hive footprint of the ~25k-station registry + price table down.
Map<String, dynamic> _serializeDataset(_MiseDataset value) => {
      's': {for (final e in value.$1.entries) e.key: e.value.toJson()},
      'p': {for (final e in value.$2.entries) e.key: e.value.toJson()},
    };

_MiseDataset? _deserializeDataset(Map<String, dynamic> json) {
  final stationsJson = json['s'];
  final pricesJson = json['p'];
  if (stationsJson is! Map || pricesJson is! Map) return null;
  final stations = <String, _StationData>{
    for (final e in stationsJson.entries)
      e.key as String:
          _StationData.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };
  final prices = <String, _PriceData>{
    for (final e in pricesJson.entries)
      e.key as String:
          _PriceData.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };
  return (stations, prices);
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

  Map<String, dynamic> toJson() => {
        'b': brand,
        't': type,
        'n': name,
        'a': address,
        'c': city,
        'pv': province,
        'la': lat,
        'lo': lng,
      };

  factory _StationData.fromJson(Map<String, dynamic> j) => _StationData(
        brand: j['b'] as String? ?? '',
        type: j['t'] as String? ?? '',
        name: j['n'] as String? ?? '',
        address: j['a'] as String? ?? '',
        city: j['c'] as String? ?? '',
        province: j['pv'] as String? ?? '',
        lat: (j['la'] as num?)?.toDouble() ?? 0,
        lng: (j['lo'] as num?)?.toDouble() ?? 0,
      );
}

class _PriceData {
  double? benzinaSelf;
  double? benzinaServed;
  double? gasolioSelf;
  double? gasolioServed;
  double? gpl;
  double? metano;
  String? updatedAt;

  _PriceData();

  Map<String, dynamic> toJson() => {
        if (benzinaSelf != null) 'bs': benzinaSelf,
        if (benzinaServed != null) 'bv': benzinaServed,
        if (gasolioSelf != null) 'gs': gasolioSelf,
        if (gasolioServed != null) 'gv': gasolioServed,
        if (gpl != null) 'gp': gpl,
        if (metano != null) 'me': metano,
        if (updatedAt != null) 'u': updatedAt,
      };

  factory _PriceData.fromJson(Map<String, dynamic> j) => _PriceData()
    ..benzinaSelf = (j['bs'] as num?)?.toDouble()
    ..benzinaServed = (j['bv'] as num?)?.toDouble()
    ..gasolioSelf = (j['gs'] as num?)?.toDouble()
    ..gasolioServed = (j['gv'] as num?)?.toDouble()
    ..gpl = (j['gp'] as num?)?.toDouble()
    ..metano = (j['me'] as num?)?.toDouble()
    ..updatedAt = j['u'] as String?;
}
