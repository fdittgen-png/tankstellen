import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'argentina_fuel_classifier.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/services/utils/csv_parser.dart';

/// Argentine fuel prices from Secretaría de Energía open data.
/// Free, no API key. CSV with station-level prices + coordinates.
/// Prices in ARS (Argentine Peso).
class ArgentinaStationService with StationServiceHelpers, CachedDatasetMixin implements StationService {
  // #728 — HTTPS only. The Secretaría de Energía CDN serves the same
  // resource under TLS, so there's no reason to fetch the open-data
  // CSV in clear text (MITM could inject malicious rows, and the
  // integrity check downstream only catches the header schema).
  static const _csvUrl =
      'https://datos.energia.gob.ar/dataset/'
      '1c181390-5045-475e-94dc-410429be4b17/resource/'
      '80ac25de-a44a-4445-9215-090cf55cfda5/download/'
      'precios-en-surtidor-resolucin-3142016.csv';

  /// Default production constructor.
  ArgentinaStationService()
      : _dio = DioFactory.create(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          responseType: ResponseType.plain,
        );

  /// Test-only constructor that accepts a preconfigured [Dio] (usually with
  /// a [MockAdapter]) so the cert-error classification path (#837) can be
  /// driven without hitting the network.
  @visibleForTesting
  ArgentinaStationService.withDio(this._dio);

  final Dio _dio;

  // Cache parsed stations
  List<_RawStation>? _cachedStations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken: cancelToken);

      final stations = <Station>[];
      // Group prices by station address (unique key: empresa+direccion+localidad)
      final stationMap = <String, _MergedStation>{};

      // First pass: find all stations within radius
      final nearbyRaw = <({_RawStation raw, double dist})>[];
      for (final raw in _cachedStations!) {
        if (raw.lat == 0 || raw.lng == 0) continue;
        final dist = distanceKm(params.lat, params.lng, raw.lat, raw.lng);
        nearbyRaw.add((raw: raw, dist: dist));
      }

      // Filter by radius; if nothing found, take nearest 200 raw entries
      // Note: filterByRadius works on Station, but here we filter raw records
      // before merging, so we keep the raw-record filtering inline.
      var filtered = nearbyRaw.where((e) => e.dist <= params.radiusKm).toList();
      if (filtered.isEmpty && nearbyRaw.isNotEmpty) {
        filtered = nearbyRaw.sortedBy<num>((e) => e.dist).take(200).toList();
      }

      for (final entry in filtered) {
        final raw = entry.raw;
        final dist = entry.dist;

        final key = '${raw.empresa}|${raw.direccion}|${raw.localidad}';
        final merged = stationMap.putIfAbsent(key, () => _MergedStation(
          raw: raw,
          dist: dist,
        ));

        // Map fuel types — classification lives in classifyArgentinaProduct
        // so it can be unit-tested against the API's quirky product strings.
        switch (classifyArgentinaProduct(raw.producto)) {
          case ArgentinaFuelCategory.naftaPremium:
            merged.naftaPremium ??= raw.precio;
          case ArgentinaFuelCategory.naftaRegular:
            merged.naftaRegular ??= raw.precio;
          case ArgentinaFuelCategory.dieselPremium:
            merged.dieselPremium ??= raw.precio;
          case ArgentinaFuelCategory.dieselRegular:
            merged.dieselRegular ??= raw.precio;
          case ArgentinaFuelCategory.gnc:
            merged.gnc ??= raw.precio;
          case null:
            break;
        }
      }

      for (final entry in stationMap.values) {
        final raw = entry.raw;
        // #516 — preserve the `ar-` prefix so Countries.countryForStationId
        // can dispatch AR stations off the id alone. The previous form
        // built `'ar-…'.hashCode.toString()` which discarded the prefix
        // into an opaque integer, leaving the `ar-` dispatch path in
        // country_config.dart as dead code for real Argentine stations.
        final signatureHash =
            '${raw.empresa}-${raw.direccion}'.hashCode.abs();
        stations.add(Station(
          id: 'ar-$signatureHash',
          name: raw.empresa,
          brand: raw.bandera,
          street: raw.direccion,
          postCode: '',
          place: raw.localidad,
          lat: raw.lat,
          lng: raw.lng,
          dist: roundedDistance(params.lat, params.lng, entry.raw.lat, entry.raw.lng),
          e5: entry.naftaRegular,
          e10: entry.naftaRegular,
          e98: entry.naftaPremium,
          diesel: entry.dieselRegular,
          dieselPremium: entry.dieselPremium,
          cng: entry.gnc,
          isOpen: true,
          updatedAt: raw.fechaVigencia,
          region: raw.provincia,
        ));
      }

      // Sort
      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.argentinaApi);
    } on DioException catch (e, st) {
      _throwCertificateOrApiException(e); // #837 — classify cert errors first.
      throwApiException(e, defaultMessage: 'Error de red', stackTrace: st);
    }
  }

  /// #837 — if [e] is a TLS/certificate error, throw the specific
  /// [UpstreamCertificateException] so the UI can blame the data provider
  /// (not the app). Otherwise, return normally and let the caller fall back
  /// to [throwApiException].
  void _throwCertificateOrApiException(DioException e) {
    if (_isCertificateError(e)) {
      throw UpstreamCertificateException(
        host: _csvHost,
        countryCode: 'ar',
        detail: e.message,
      );
    }
  }

  /// Hostname of the Argentina open-data CSV — kept in a constant so the
  /// certificate error message names the exact provider the user should
  /// contact (#837).
  static const _csvHost = 'datos.energia.gob.ar';

  /// Detect whether a [DioException] is a TLS/certificate validation
  /// failure. Dio 5.x signals most cert errors via
  /// [DioExceptionType.badCertificate], but on some platforms a bad cert
  /// arrives under [DioExceptionType.unknown] with an `HandshakeException`
  /// / `TlsException` wrapped in [DioException.error] — we match both.
  static bool _isCertificateError(DioException e) {
    if (e.type == DioExceptionType.badCertificate) return true;
    if (e.type != DioExceptionType.unknown) return false;
    final haystack = '${e.error ?? ''} ${e.message ?? ''}'.toUpperCase();
    return haystack.contains('CERT') ||
        haystack.contains('X509') ||
        haystack.contains('SSL') ||
        haystack.contains('TLS') ||
        haystack.contains('HANDSHAKE');
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) async {
    if (_cachedStations != null && isDatasetFresh(const Duration(hours: 6))) {
      return;
    }

    final response = await _dio.get<String>(_csvUrl, cancelToken: cancelToken);
    _cachedStations = await compute(_parseCsv, response.data ?? '');
    markDatasetRefreshed();
  }

  /// Expected CSV header columns from the Argentina open data endpoint.
  /// Used as an integrity check to detect MITM tampering or format changes
  /// since the endpoint only supports HTTP (no TLS protection).
  static const _expectedHeaderColumns = [
    'empresa',
    'direccion',
    'localidad',
    'producto',
    'precio',
    'latitud',
    'longitud',
  ];

  static List<_RawStation> _parseCsv(String csv) {
    final stations = <_RawStation>[];
    final lines = const LineSplitter().convert(csv);

    // First line is header — validate structure as MITM protection
    if (lines.isEmpty) return stations;

    final header = lines.first.toLowerCase();
    for (final col in _expectedHeaderColumns) {
      if (!header.contains(col)) {
        throw FormatException(
          'Argentina CSV integrity check failed: '
          'missing expected column "$col" in header. '
          'Possible data tampering or API format change.',
        );
      }
    }

    for (var i = 1; i < lines.length; i++) {
      // CSV with comma separator, fields may be quoted
      final parts = CsvParser.parseLine(lines[i]);
      if (parts.length < 19) continue;

      final lat = double.tryParse(parts[16]) ?? 0;
      final lng = double.tryParse(parts[17]) ?? 0;
      final precio = double.tryParse(parts[12]) ?? 0;
      if (precio <= 0) continue;

      stations.add(_RawStation(
        empresa: parts[3],
        direccion: parts[4],
        localidad: parts[5],
        provincia: parts[6],
        producto: parts[9],
        precio: precio,
        fechaVigencia: parts[13].length >= 10 ? parts[13].substring(0, 10) : parts[13],
        bandera: parts[15],
        lat: lat,
        lng: lng,
      ));
    }
    return stations;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throwDetailUnavailable('Argentina API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return emptyPricesResult(ServiceSource.argentinaApi);
  }
}

class _RawStation {
  final String empresa;
  final String direccion;
  final String localidad;
  final String provincia;
  final String producto;
  final double precio;
  final String fechaVigencia;
  final String bandera;
  final double lat;
  final double lng;

  const _RawStation({
    required this.empresa,
    required this.direccion,
    required this.localidad,
    required this.provincia,
    required this.producto,
    required this.precio,
    required this.fechaVigencia,
    required this.bandera,
    required this.lat,
    required this.lng,
  });
}

class _MergedStation {
  final _RawStation raw;
  final double dist;
  double? naftaRegular;
  double? naftaPremium;
  double? dieselRegular;
  double? dieselPremium;
  double? gnc;

  _MergedStation({required this.raw, required this.dist});
}
