// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/logging/error_logger.dart';
import '../../station_detail/domain/opening_hours.dart';
import 'portugal_detail_parser.dart';
import 'portugal_opening_hours_adapter.dart';

/// DGEG (Direção-Geral de Energia e Geologia) Portuguese fuel price service.
///
/// Uses DGEG's `PesquisarPostos` endpoint, which returns one row per
/// (station, fuel type) combination with the station's coordinates,
/// address and fuel price already populated. The sibling
/// `ListarDadosPostos` endpoint used by the previous implementation
/// returned a station *index* with almost every meaningful field set
/// to `null` (no coordinates, no prices, no address) — that's why
/// Portugal search silently produced zero stations on 4.3.0 (see #503).
///
/// API: https://precoscombustiveis.dgeg.gov.pt/api/PrecoComb/PesquisarPostos
/// No API key, no auth. Reverse-engineered from the DGEG portal.
///
/// Response shape (one row per station-fuel):
/// ```json
/// {
///   "status": true,
///   "mensagem": "sucesso",
///   "resultado": [
///     {
///       "Id": 67360,
///       "Nome": "INTERMARCHE VILAR FORMOSO",
///       "Marca": "INTERMARCHÉ",
///       "Morada": "Sitio da Represa",
///       "CodPostal": "6355-289",
///       "Localidade": "Vilar Formoso",
///       "Municipio": "Almeida",
///       "Distrito": "Guarda",
///       "Latitude": 40.61817,
///       "Longitude": -6.84339,
///       "Combustivel": "Gasolina simples 95",
///       "Preco": "1,719 €",
///       "DataAtualizacao": "2026-04-14 08:00",
///       "Quantidade": 3111
///     },
///     ...
///   ]
/// }
/// ```
///
/// Prices are Portuguese-formatted decimals (`"1,719 €"`). The parser
/// strips the euro sign and swaps the comma decimal separator for a
/// dot before parsing. Stations are merged across fuel-type rows by
/// `Id` so a single [Station] carries all known prices.
class PortugalStationService
    with StationServiceHelpers, CachedDatasetMixin
    implements StationService {
  final Dio _dio;
  final String _baseUrl;
  final String _fuelTypeIds;

  /// In-memory copy of the last DGEG `resultado` payload (one row per
  /// station-fuel). The previous implementation re-downloaded the full
  /// ~10 000-row national dataset on every search; a moving user or a
  /// route fan-out across coordinates re-fetched it repeatedly. The
  /// dataset is national (no coordinate filter on the wire), so it is
  /// cached here with a short TTL and re-filtered per coordinate in
  /// [parseAndFilter] — correctness is unaffected (#2302).
  List<dynamic>? _cachedResultado;

  /// Dataset cache TTL. DGEG refreshes prices a few times a day; 15 min
  /// keeps a moving user / route fan-out off the wire without serving
  /// stale prices for long.
  static const Duration _datasetTtl = Duration(minutes: 15);

  PortugalStationService({
    Dio? dio,
    String baseUrl = 'https://precoscombustiveis.dgeg.gov.pt/api/PrecoComb',
    String fuelTypeIds = defaultFuelTypeIds,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ),
        _baseUrl = baseUrl,
        _fuelTypeIds = fuelTypeIds;

  /// DGEG fuel type IDs we query — 95-octane petrol simples + gasóleo
  /// (diesel) simples. Covers the two dominant fuels used by the app's
  /// search UI.
  ///
  /// - `3201` → Gasolina simples 95
  /// - `2101` → Gasóleo simples
  ///
  /// Other IDs exist (e.g. 3205 = Gasolina especial 95, 2105 = Gasóleo
  /// especial, and various LPG/98/E85 variants) and can be added later
  /// without changing the service's public shape — [_mergeInto] already
  /// dispatches on the `Combustivel` label, not on the ID.
  static const String defaultFuelTypeIds = '3201,2101';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resultado = await _ensureDataLoaded(cancelToken: cancelToken);

      final stations = parseAndFilter(
        resultado,
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      );

      return ServiceResult(
        data: stations,
        source: ServiceSource.portugalApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'DGEG API error', stackTrace: st);
    }
  }

  /// Returns the national DGEG dataset, served from the fresh in-memory
  /// copy when within [_datasetTtl], otherwise re-downloaded once and
  /// cached (#2302). The endpoint has no coordinate filter, so the same
  /// payload serves every search point until it expires.
  Future<List<dynamic>> _ensureDataLoaded({CancelToken? cancelToken}) async {
    final cached = _cachedResultado;
    if (cached != null && isDatasetFresh(_datasetTtl)) {
      return cached;
    }

    final response = await _dio.get<dynamic>(
      '$_baseUrl/PesquisarPostos',
      queryParameters: {
        'idsTiposComb': _fuelTypeIds,
        'idMarca': '',
        'idTipoPosto': '',
        'idDistrito': '',
        'idsMunicipios': '',
        'qtdPorPagina': 10000,
        'pagina': 1,
      },
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid DGEG response (not an object)',
      );
    }
    final resultado = data['resultado'];
    if (resultado is! List) {
      throw const ApiException(
        message: 'Invalid DGEG response (resultado is not a list)',
      );
    }

    _cachedResultado = resultado;
    markDatasetRefreshed();
    return resultado;
  }

  /// Groups [resultado] rows by station `Id`, attaches fuel prices,
  /// filters by [radiusKm] from ([lat], [lng]), sorts by distance and
  /// returns the nearest 50 stations.
  ///
  /// Exposed for unit tests — the HTTP layer is fake-adapter-driven
  /// in the tests, but the parser is the interesting surface to pin
  /// behaviour on (comma-decimal prices, missing coordinates, fuel
  /// merging, radius filter, empty-never-silent).
  @visibleForTesting
  static List<Station> parseAndFilter(
    List<dynamic> resultado, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final byId = <int, _MergedRow>{};

    for (final item in resultado) {
      if (item is! Map) continue;
      try {
        final id = (item['Id'] as num?)?.toInt();
        final itemLat = (item['Latitude'] as num?)?.toDouble();
        final itemLng = (item['Longitude'] as num?)?.toDouble();
        if (id == null || itemLat == null || itemLng == null) continue;

        final existing = byId[id];
        final merged = existing ??
            _MergedRow(
              id: id,
              name: item['Nome']?.toString() ?? '',
              brand: item['Marca']?.toString() ?? '',
              street: item['Morada']?.toString() ?? '',
              postCode: item['CodPostal']?.toString() ?? '',
              place: item['Localidade']?.toString() ??
                  item['Municipio']?.toString() ??
                  '',
              lat: itemLat,
              lng: itemLng,
            );

        final price = _parsePriceEur(item['Preco']);
        final fuel = item['Combustivel']?.toString() ?? '';
        merged.assignPrice(fuel, price);

        byId[id] = merged;
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'PT station row parse failed'}));
        continue;
      }
    }

    final stations = <Station>[];
    for (final row in byId.values) {
      final dist = distanceKm(lat, lng, row.lat, row.lng);
      if (dist > radiusKm) continue;
      stations.add(Station(
        id: 'pt-${row.id}',
        name: row.name,
        brand: row.brand,
        street: row.street,
        postCode: row.postCode,
        place: row.place,
        lat: row.lat,
        lng: row.lng,
        dist: dist,
        e5: row.gasolina95,
        // Portugal reports 95 simples as the single "petrol" — mirror it
        // into e10 so the UI shows something for E10-preferred users.
        e10: row.gasolina95,
        e98: row.gasolina98,
        diesel: row.gasoleo,
        lpg: row.gpl,
        isOpen: true,
      ));
    }

    stations.sort((a, b) => a.dist.compareTo(b.dist));
    return stations.take(50).toList();
  }

  /// Parses a DGEG price string like `"1,719 €"` into a double.
  /// Returns `null` when the value is missing or unparseable.
  @visibleForTesting
  static double? parsePriceForTest(dynamic value) => _parsePriceEur(value);

  static double? _parsePriceEur(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final cleaned = raw
        .replaceAll('€', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Fetches the DGEG `GetDadosPostoMapa` detail endpoint for [stationId] and
  /// returns a [StationDetail] carrying the weekly opening hours parsed from
  /// `HorarioPosto` (Epic #2707 C7, #2714). The detail endpoint has no
  /// coordinates, so [PortugalDetailParser] merges its payload onto the cached
  /// search row (coords + prices) — see that helper for the split-endpoint
  /// rationale.
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    try {
      final numericId = _stripCountryPrefix(stationId);
      final response = await _dio.get<dynamic>(
        '$_baseUrl/GetDadosPostoMapa',
        queryParameters: {'id': numericId, 'f': 'json'},
      );

      final data = response.data;
      if (data is! Map) {
        throw const ApiException(
          message: 'Invalid DGEG detail response (not an object)',
        );
      }
      final resultado = data['resultado'];
      if (resultado is! Map) {
        throw const ApiException(
          message: 'Invalid DGEG detail response (resultado is not an object)',
        );
      }

      final weeklyHours =
          const PortugalOpeningHoursAdapter().parse(resultado['HorarioPosto']);
      final station = PortugalDetailParser.stationFromDetail(
        stationId: stationId,
        numericId: numericId,
        resultado: resultado,
        cachedSearchRow: PortugalDetailParser.cachedSearchRow(
          numericId,
          _cachedResultado,
          parseAndFilter,
        ),
      );

      return ServiceResult(
        data: StationDetail(
          station: station,
          openingHours: weeklyHours.availability ==
                  OpeningHoursAvailability.notProvided
              ? null
              : weeklyHours,
        ),
        source: ServiceSource.portugalApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(
        e,
        defaultMessage: 'DGEG detail API error',
        stackTrace: st,
      );
    }
  }

  /// Strip the `pt-` prefix so the DGEG endpoint receives the bare numeric id.
  /// Tolerant of legacy unprefixed favourites.
  static String _stripCountryPrefix(String id) =>
      id.startsWith('pt-') ? id.substring(3) : id;

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.portugalApi);
  }
}

/// Mutable accumulator used while merging DGEG rows for the same
/// station Id across fuel types.
class _MergedRow {
  final int id;
  final String name;
  final String brand;
  final String street;
  final String postCode;
  final String place;
  final double lat;
  final double lng;

  double? gasolina95;
  double? gasolina98;
  double? gasoleo;
  double? gpl;

  _MergedRow({
    required this.id,
    required this.name,
    required this.brand,
    required this.street,
    required this.postCode,
    required this.place,
    required this.lat,
    required this.lng,
  });

  void assignPrice(String fuelLabel, double? price) {
    if (price == null) return;
    final label = fuelLabel.toLowerCase();
    // Order matters: check "98" before the generic "95" contains check.
    if (label.contains('98')) {
      gasolina98 = price;
    } else if (label.contains('95')) {
      gasolina95 = price;
    } else if (label.contains('gasóleo') ||
        label.contains('gasoleo') ||
        label.contains('diesel')) {
      gasoleo = price;
    } else if (label.contains('gpl')) {
      gpl = price;
    }
  }
}
