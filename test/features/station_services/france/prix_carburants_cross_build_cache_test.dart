// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart'
    as parser;
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3219 follow-up — the field re-report: the #3224 per-day-hours fix was IN
/// the installed build (versionCode tag → merge commit verified) yet the
/// phone STILL showed only 24/7 hours for France.
///
/// Mechanism: the chain caches PARSED stations under the search key with
/// FR's 6-hour `searchResultTtl`. The pre-fix build — running while the
/// upstream had dropped the derived `horaires_jour` column — persisted
/// hour-less stations. After the update, `getFresh` kept serving that
/// pre-fix parse output for the same search key until the TTL lapsed, so
/// the fix was invisible for up to 6 hours ("fix shipped, phone still
/// broken"). This test drives the REAL chain with the REAL recorded Paris
/// corpus: the cache is seeded with exactly what the pre-fix build wrote
/// (hour-less parse of the degraded record, in an envelope with no build
/// stamp — pre-stamp builds wrote none), and the API fixture carries the
/// recorded row whose structured `horaires` column has the schedule. The
/// chain must NOT serve the stale pre-fix payload as fresh: the returned
/// stations must carry the per-day schedule parsed by the CURRENT code.
class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.body);
  final Object body;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? rs,
      Future<void>? cf) async {
    fetchCount++;
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _FakeCacheStorage implements CacheStorage {
  final Map<String, dynamic> store = {};

  @override
  Future<void> cacheData(String key, dynamic data) async {
    if (data == null) {
      store.remove(key);
    } else {
      store[key] = data;
    }
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final raw = store[key];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  Future<void> clearCache() async => store.clear();

  @override
  int get cacheEntryCount => store.length;

  @override
  Iterable<dynamic> get cacheKeys => store.keys;

  @override
  Future<void> deleteCacheEntry(String key) async => store.remove(key);
}

void main() {
  silenceErrorLoggerSpool();

  late Map<String, dynamic> recorded;

  setUpAll(() {
    recorded = jsonDecode(
      File('test/fixtures/prix_carburants_paris_geo_ordered.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  Map<String, dynamic> recordedRow(int id) => (recorded['results'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((r) => r['id'] == id);

  test(
      'an update is not masked by the pre-fix build\'s cached hour-less '
      'parse output — the chain re-fetches and the per-day schedule renders '
      '(#3219 field re-report)', () async {
    AppConstants.setRuntimeVersion('6.0.0+CURRENT_BUILD');
    const params = SearchParams(lat: 48.8566, lng: 2.3522, radiusKm: 10.0);

    // The recorded Total Energies 75008010 row — a real split-shift week in
    // the structured `horaires` column; the derived column nulled, the very
    // degradation that triggered #3219.
    final degraded = Map<String, dynamic>.of(recordedRow(75008010))
      ..['horaires_jour'] = null;

    // What the PRE-#3224 build persisted for this search: the same record
    // parsed with BOTH hours columns absent (the old code never read the
    // structured column, so its output is byte-identical to parsing a
    // hours-less record with the current code).
    final hourless = Map<String, dynamic>.of(degraded)..['horaires'] = null;
    final preFixStation =
        parser.parsePrixCarburantsStation(hourless, params.lat, params.lng)!;
    expect(
      preFixStation.openingHours?.availability,
      OpeningHoursAvailability.notProvided,
      reason: 'seed sanity: the pre-fix parse output carries no schedule',
    );

    final storage = _FakeCacheStorage();
    // Seed the EXACT envelope a pre-stamp build wrote: fresh (stored now,
    // 6 h TTL like FR's searchResultTtl), parsed payload, NO appBuild key.
    storage.store[CacheKey.stationSearch(
      params.lat, params.lng, params.radiusKm, FuelType.all.apiValue,
      countryCode: 'FR',
    )] = {
      'payload': serializeStationList([preFixStation]),
      'storedAt': DateTime.now().millisecondsSinceEpoch,
      'source': ServiceSource.prixCarburantsApi.name,
      'ttlMs': const Duration(hours: 6).inMilliseconds,
    };

    final adapter = _FixtureAdapter({
      'total_count': 1,
      'results': [degraded],
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://data.economie.gouv.fr'))
      ..httpClientAdapter = adapter;
    final chain = StationServiceChain(
      PrixCarburantsStationService(dio: dio, enricher: null),
      CacheManager(storage),
      errorSource: ServiceSource.prixCarburantsApi,
      countryCode: 'FR',
    );

    final result = await chain.searchStations(params);

    expect(adapter.fetchCount, greaterThan(0),
        reason: 'the cross-build cache entry must be a fresh-miss that '
            'forces a re-fetch — serving it fresh is exactly how the #3224 '
            'fix stayed invisible on the updated device');
    expect(result.data, hasLength(1));
    final hours = result.data.single.openingHours;
    expect(hours, isNotNull);
    final monday = hours!.dayFor(OpeningDay.mon);
    expect(monday?.state, DayState.openRanges,
        reason: 'the re-fetched record must carry the per-day schedule '
            'parsed from the structured horaires column by the CURRENT code');
    expect(monday!.ranges, isNotEmpty);
  });
}
