// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/country/country_bounding_box.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/services/dio_factory.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../domain/entities/charging_station.dart';
import 'ev_price_enricher.dart';

/// A single matchable IRVE record (the four fields we select).
class _IrveRecord {
  final double lat;
  final double lng;
  final bool? free;
  final String? tarification;

  const _IrveRecord({
    required this.lat,
    required this.lng,
    required this.free,
    required this.tarification,
  });
}

/// One cached viewport's parsed IRVE records, with its fetch time.
class _CacheEntry {
  final List<_IrveRecord> records;
  final DateTime fetchedAt;

  const _CacheEntry(this.records, this.fetchedAt);
}

/// Enriches French charging stations with the IRVE open dataset's
/// authoritative `gratuit` (free) flag + `tarification` indicative text,
/// served from the no-backend ODRÉ geo-query API (#2618).
///
/// Plug-in implementation of [EvPriceEnricher] — the EV search provider
/// always calls [enrich]; this one is a no-op for any result set with no
/// FR stations, so non-FR searches make zero network calls.
///
/// ## Access method (verified against the live endpoint)
/// One bounding-box query per viewport against
/// `bornes-irve/records`, selecting only the four fields we need:
/// `nom_station, id_station_itinerance, gratuit, tarification,
/// consolidated_latitude, consolidated_longitude`. We use
/// `consolidated_latitude/longitude` (correct) rather than
/// `coordonneesxy` (lat/lng swapped) and avoid `within_distance(
/// geo_point_borne)` because that geo column is NULL in the rows.
///
/// ## Matching
/// Each OCM station is matched to the nearest IRVE record by haversine,
/// accepted only within [_matchRadiusMeters]. No match → station left
/// unchanged.
///
/// ## Caching
/// In-memory LRU keyed by a rounded (3-decimal) bbox grid, [_ttl] TTL.
/// One network call per viewport, never per station.
class FrIrvePriceService implements EvPriceEnricher {
  final Dio _dio;

  FrIrvePriceService({Dio? dio}) : _dio = dio ?? _defaultDio();

  /// Default Dio — separate so tests can inject a capturing Dio without
  /// re-implementing the BaseOptions (mirrors EVChargingService).
  static Dio _defaultDio() => DioFactory.create(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      );

  static const _endpoint =
      'https://odre.opendatasoft.com/api/explore/v2.1/catalog/datasets/'
      'bornes-irve/records';

  /// Accept an IRVE match only within this haversine radius.
  static const double _matchRadiusMeters = 75;

  /// Viewport cache TTL.
  static const Duration _ttl = Duration(hours: 24);

  /// Max cached viewports (LRU eviction beyond this).
  static const int _maxCacheEntries = 16;

  /// Margin added around the result bbox so border points still match.
  static const double _bboxMarginDeg = 0.01;

  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  @override
  Future<List<ChargingStation>> enrich(List<ChargingStation> stations) async {
    // Only FR stations are eligible — inferred from coordinates, NOT the
    // active-country code, so a cross-border search still enriches FR
    // rows. Bail with zero network if none qualify.
    final frStations = stations
        .where((s) => countryCodeFromLatLng(s.lat, s.lng) == 'FR')
        .toList();
    if (frStations.isEmpty) return stations;

    final records = await _recordsFor(frStations);
    if (records.isEmpty) return stations;

    return [
      for (final station in stations)
        countryCodeFromLatLng(station.lat, station.lng) == 'FR'
            ? _applyMatch(station, records)
            : station,
    ];
  }

  /// Returns the cached or freshly-fetched IRVE records covering the
  /// bounding box of [frStations]. Returns an empty list on any failure.
  Future<List<_IrveRecord>> _recordsFor(List<ChargingStation> frStations) async {
    var minLat = double.infinity, maxLat = double.negativeInfinity;
    var minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final s in frStations) {
      minLat = s.lat < minLat ? s.lat : minLat;
      maxLat = s.lat > maxLat ? s.lat : maxLat;
      minLng = s.lng < minLng ? s.lng : minLng;
      maxLng = s.lng > maxLng ? s.lng : maxLng;
    }
    minLat -= _bboxMarginDeg;
    maxLat += _bboxMarginDeg;
    minLng -= _bboxMarginDeg;
    maxLng += _bboxMarginDeg;

    final key = _cacheKey(minLat, maxLat, minLng, maxLng);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _ttl) {
      // Touch for LRU recency.
      _cache.remove(key);
      _cache[key] = cached;
      return cached.records;
    }

    try {
      final response = await _dio.get<dynamic>(
        _endpoint,
        queryParameters: {
          'where': 'consolidated_latitude>=$minLat and '
              'consolidated_latitude<=$maxLat and '
              'consolidated_longitude>=$minLng and '
              'consolidated_longitude<=$maxLng',
          'select': 'nom_station,id_station_itinerance,gratuit,tarification,'
              'consolidated_latitude,consolidated_longitude',
          'limit': 100,
        },
      );
      final records = _parseRecords(response.data);
      _store(key, _CacheEntry(records, DateTime.now()));
      return records;
    } catch (e, st) {
      // Graceful no-enrichment fallback (#2618): the EV search must not
      // crash on an IRVE outage, but the failure must not be swallowed
      // silently either — route to the exportable log.
      unawaited(errorLogger.log(ErrorLayer.services, e, st, context: const {
        'where': 'FrIrvePriceService: IRVE bbox query',
      }));
      return const [];
    }
  }

  /// Parses the ODRÉ `results` array into matchable records, skipping any
  /// row missing coordinates.
  List<_IrveRecord> _parseRecords(dynamic data) {
    if (data is! Map<String, dynamic>) return const [];
    final results = data['results'];
    if (results is! List) return const [];
    final out = <_IrveRecord>[];
    for (final row in results) {
      if (row is! Map<String, dynamic>) continue;
      final lat = (row['consolidated_latitude'] as num?)?.toDouble();
      final lng = (row['consolidated_longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      out.add(_IrveRecord(
        lat: lat,
        lng: lng,
        free: _normalizeGratuit(row['gratuit']?.toString()),
        tarification: _nonEmptyOrNull(row['tarification']?.toString()),
      ));
    }
    return out;
  }

  /// Applies the nearest in-radius IRVE record to a station, if any.
  ChargingStation _applyMatch(
      ChargingStation station, List<_IrveRecord> records) {
    _IrveRecord? best;
    var bestDist = double.infinity;
    for (final r in records) {
      final d = distanceMeters(station.lat, station.lng, r.lat, r.lng);
      if (d < bestDist) {
        bestDist = d;
        best = r;
      }
    }
    if (best == null || bestDist > _matchRadiusMeters) return station;

    final match = best;
    return station.copyWith(
      // tarification is often null — only override the indicative text
      // when the dataset actually carries one.
      usageCost: match.tarification ?? station.usageCost,
      // The IRVE `gratuit` flag is authoritative. Confirmed-free → both
      // structured flags explicitly false (no payment, no membership
      // gate), which EvAccessCost reads as a free badge. Confirmed-paid
      // → pay-at-location true. Unknown `gratuit` leaves the OCM signal
      // untouched.
      isPayAtLocation: switch (match.free) {
        true => false,
        false => true,
        null => station.isPayAtLocation,
      },
      isMembershipRequired: match.free == true
          ? false
          : station.isMembershipRequired,
      isFranceIrveEnriched: true,
    );
  }

  /// Normalizes the messy free-text `gratuit` field. The live dataset
  /// carries `null, 0, 1, true/false` in every casing — `true`/`1` mean
  /// free, `false`/`0` mean paid, anything else is unknown (null).
  static bool? _normalizeGratuit(String? raw) {
    final g = raw?.trim().toLowerCase();
    if (g == null || g.isEmpty) return null;
    if (g == 'true' || g == '1') return true;
    if (g == 'false' || g == '0') return false;
    return null;
  }

  static String? _nonEmptyOrNull(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    // The dataset uses "Inconnu" ("unknown") as a non-value sentinel.
    if (t.toLowerCase() == 'inconnu') return null;
    return t;
  }

  /// LRU store with a hard cap — evicts the least-recently-used entry.
  void _store(String key, _CacheEntry entry) {
    _cache.remove(key);
    _cache[key] = entry;
    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  static String _cacheKey(
      double minLat, double maxLat, double minLng, double maxLng) {
    String r(double v) => v.toStringAsFixed(3);
    return '${r(minLat)},${r(maxLat)},${r(minLng)},${r(maxLng)}';
  }
}
