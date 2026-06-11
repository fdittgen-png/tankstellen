// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'mise_dataset.dart';
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
  final PersistentDataset<MiseDataset>? _persistent;

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
            : PersistentDataset<MiseDataset>(
                cache: cache,
                countryCode: 'IT',
                datasetName: 'stations',
                source: ServiceSource.miseApi,
                serialize: serializeMiseDataset,
                deserialize: deserializeMiseDataset,
              );

  // #2270 — soft/hard dataset TTLs mirror the IT FuelServicePolicy in the
  // registry (soft 6 h, hard 24 h). The legacy 2-hour in-memory TTL is the
  // soft bound now; the persisted read-through governs offline freshness.
  static const Duration _softTtl = Duration(hours: 6);
  static const Duration _hardTtl = Duration(hours: 24);

  // In-memory cache of parsed data
  Map<String, MiseStationData>? _cachedStations;
  Map<String, MisePriceData>? _cachedPrices;

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
          e98: prices?.benzinaPremiumSelf ?? prices?.benzinaPremiumServed,
          diesel: prices?.gasolioSelf ?? prices?.gasolioServed,
          dieselPremium:
              prices?.gasolioPremiumSelf ?? prices?.gasolioPremiumServed,
          lpg: prices?.gpl,
          cng: prices?.metano,
          // #3198 — the MIMIT dataset carries no open/closed signal:
          // honest unknown instead of the old hard-coded `true`.
          isOpen: null,
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
    Future<MiseDataset> fetch() async {
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

    void store(MiseDataset value) {
      _cachedStations = value.$1;
      _cachedPrices = value.$2;
    }

    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — preserve the legacy in-memory path.
      return loadDataset<MiseDataset>(
        cached: cached,
        ttl: const Duration(hours: 2),
        fetch: fetch,
        store: store,
      );
    }
    // #2270 — disk read-through: survives cold start + offline.
    return loadPersistentDataset<MiseDataset>(
      cached: cached,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: persistent,
      fetch: fetch,
      store: store,
    );
  }

  /// #3188 — a code-like "Nome Impianto": an optional short letter prefix
  /// followed by 3+ digits, optionally trailed by more text (live registry
  /// examples: "03674", "AG021", "PV8380", "19829 AGRIGENTO",
  /// "TM06058 BAGNOLO MELLA", "08011 - 959304"). These are internal plant
  /// codes, not display names — treated as empty so the brand fallback fires.
  static final RegExp _codeLikeName = RegExp(r'^[A-Z]{0,3}\d{3,}( .*)?$');

  Map<String, MiseStationData> _parseStationsCsv(String csv) {
    final stations = <String, MiseStationData>{};
    final rows = CsvParser.parseAll(csv, skipLines: 2, separator: '|');

    for (final parts in rows) {
      if (parts.length < 10) continue;

      final id = parts[0];
      final lat = double.tryParse(parts[8]) ?? 0;
      final lng = double.tryParse(parts[9]) ?? 0;
      if (lat == 0 || lng == 0) continue;

      final rawName = parts[4].trim();
      stations[id] = MiseStationData(
        brand: parts[2],
        type: parts[3],
        name: _codeLikeName.hasMatch(rawName) ? '' : rawName,
        address: parts[5],
        city: parts[6],
        province: parts[7],
        lat: lat,
        lng: lng,
      );
    }
    return stations;
  }

  /// #3188 — known 98+-octane premium petrol grades (lowercase, exact) from
  /// the live prezzo_alle_8.csv of 2026-06-10.
  static const Set<String> _premiumBenzina = {
    'blue super',
    'benzina wr 100',
    'benzina plus 98',
    'benzina energy 98 ottani',
    'benzina shell v power',
    'v-power',
  };

  /// #3188 — known premium diesel grades (lowercase, exact) from the live
  /// prezzo_alle_8.csv of 2026-06-10.
  static const Set<String> _premiumGasolio = {
    'blue diesel',
    'supreme diesel',
    'hi-q diesel',
    'gasolio premium',
    'gasolio speciale',
    'diesel shell v power',
    'v-power diesel',
  };

  Map<String, MisePriceData> _parsePricesCsv(String csv) {
    final prices = <String, MisePriceData>{};
    final rows = CsvParser.parseAll(csv, skipLines: 2, separator: '|');

    for (final parts in rows) {
      if (parts.length < 5) continue;

      final id = parts[0];
      final fuel = parts[1].toLowerCase();
      final price = double.tryParse(parts[2]);
      final isSelf = parts[3] == '1';
      final dateStr = parts[4];

      if (price == null) continue;

      final existing = prices[id] ?? MisePriceData();

      // #3188 — exact matching for the regular grades and an explicit list
      // for the known premium variants. The old contains('benzina') /
      // contains('gasolio')||contains('diesel') matcher mis-slotted ~12k
      // premium rows ("Blue Diesel", "Gasolio speciale", "Diesel Shell
      // V Power", …) into the REGULAR price slots. Unknown names fall
      // through unmapped — never into a regular slot.
      if (fuel == 'benzina') {
        if (isSelf) {
          existing.benzinaSelf ??= price;
        } else {
          existing.benzinaServed ??= price;
        }
      } else if (fuel == 'gasolio') {
        if (isSelf) {
          existing.gasolioSelf ??= price;
        } else {
          existing.gasolioServed ??= price;
        }
      } else if (_premiumBenzina.contains(fuel)) {
        if (isSelf) {
          existing.benzinaPremiumSelf ??= price;
        } else {
          existing.benzinaPremiumServed ??= price;
        }
      } else if (_premiumGasolio.contains(fuel)) {
        if (isSelf) {
          existing.gasolioPremiumSelf ??= price;
        } else {
          existing.gasolioPremiumServed ??= price;
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
