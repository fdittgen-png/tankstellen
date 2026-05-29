// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'argentina_fuel_classifier.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
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
  static const String defaultCsvUrl =
      'https://datos.energia.gob.ar/dataset/'
      '1c181390-5045-475e-94dc-410429be4b17/resource/'
      '80ac25de-a44a-4445-9215-090cf55cfda5/download/'
      'precios-en-surtidor-resolucin-3142016.csv';

  /// Default production constructor.
  ///
  /// #2193 — accepts an optional [baseUrl] (the CSV endpoint) so tests can
  /// point the service at a fake host; defaults to [defaultCsvUrl] so
  /// production + the registry factory are unaffected.
  /// #2264 — [cache] enables the disk read-through (the registry passes the
  /// shared CacheManager); omit it for the pure in-memory behaviour the
  /// existing parser tests rely on.
  ArgentinaStationService({String? baseUrl, CacheStrategy? cache})
      : _csvUrl = baseUrl ?? defaultCsvUrl,
        _persistent = _buildPersistent(cache),
        _dio = DioFactory.create(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          responseType: ResponseType.plain,
        );

  /// Test-only constructor that accepts a preconfigured [Dio] (usually with
  /// a [MockAdapter]) so the cert-error classification path (#837) can be
  /// driven without hitting the network. #2193 — also accepts an optional
  /// [baseUrl] (the CSV endpoint), defaulting to [defaultCsvUrl].
  @visibleForTesting
  ArgentinaStationService.withDio(this._dio, {String? baseUrl, CacheStrategy? cache})
      : _csvUrl = baseUrl ?? defaultCsvUrl,
        _persistent = _buildPersistent(cache);

  final Dio _dio;
  final String _csvUrl;

  /// #2264 — disk persistence (read-through), or null when no cache is wired.
  final PersistentDataset<List<_RawStation>>? _persistent;

  /// #2264 — soft/hard dataset TTLs mirror the AR FuelServicePolicy (soft 6 h,
  /// hard 24 h); the legacy 6-hour in-memory TTL is the soft bound now.
  static const Duration _softTtl = Duration(hours: 6);
  static const Duration _hardTtl = Duration(hours: 24);

  static PersistentDataset<List<_RawStation>>? _buildPersistent(
    CacheStrategy? cache,
  ) {
    if (cache == null) return null;
    return PersistentDataset<List<_RawStation>>(
      cache: cache,
      countryCode: 'AR',
      datasetName: 'stations',
      source: ServiceSource.argentinaApi,
      serialize: (rows) => {'rows': rows.map((r) => r.toJson()).toList()},
      deserialize: (json) {
        final list = json['rows'] as List<dynamic>?;
        if (list == null) return null;
        return list
            .map((j) => _RawStation.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      },
    );
  }

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

  /// Hostname of the Argentina open-data CSV — derived from [_csvUrl] so
  /// the certificate error message names the exact provider the user should
  /// contact (#837). Falls back to the default host when the URL has no
  /// authority (e.g. a relative test URL).
  String get _csvHost {
    final host = Uri.tryParse(_csvUrl)?.host ?? '';
    return host.isNotEmpty ? host : 'datos.energia.gob.ar';
  }

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

  Future<List<_RawStation>> _fetchCsv({CancelToken? cancelToken}) async {
    final response = await _dio.get<String>(_csvUrl, cancelToken: cancelToken);
    return compute(_parseCsv, response.data ?? '');
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) {
    final persistent = _persistent;
    if (persistent == null) {
      // No cache wired (unit tests) — preserve the legacy in-memory path.
      return loadDataset<List<_RawStation>>(
        cached: _cachedStations,
        ttl: const Duration(hours: 6),
        fetch: () => _fetchCsv(cancelToken: cancelToken),
        store: (value) => _cachedStations = value,
      );
    }
    // #2264 — disk read-through: survives cold start + offline.
    return loadPersistentDataset<List<_RawStation>>(
      cached: _cachedStations,
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: persistent,
      fetch: () => _fetchCsv(cancelToken: cancelToken),
      store: (value) => _cachedStations = value,
    );
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

  /// #2264 — compact JSON for the persisted dataset (single-letter keys keep
  /// the ~700 KB national CSV's Hive footprint down).
  Map<String, dynamic> toJson() => {
        'e': empresa,
        'd': direccion,
        'l': localidad,
        'pv': provincia,
        'pr': producto,
        'p': precio,
        'f': fechaVigencia,
        'b': bandera,
        'la': lat,
        'lo': lng,
      };

  factory _RawStation.fromJson(Map<String, dynamic> j) => _RawStation(
        empresa: j['e'] as String? ?? '',
        direccion: j['d'] as String? ?? '',
        localidad: j['l'] as String? ?? '',
        provincia: j['pv'] as String? ?? '',
        producto: j['pr'] as String? ?? '',
        precio: (j['p'] as num?)?.toDouble() ?? 0,
        fechaVigencia: j['f'] as String? ?? '',
        bandera: j['b'] as String? ?? '',
        lat: (j['la'] as num?)?.toDouble() ?? 0,
        lng: (j['lo'] as num?)?.toDouble() ?? 0,
      );
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
