// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../cache/cache_manager.dart';
import '../dio_factory.dart';
import '../mixins/cached_dataset_mixin.dart';
import '../persistent_dataset.dart';
import '../service_result.dart';
import 'motorway_exits.dart';

/// Per-country motorway-exit datasets (#3633), consumed from the
/// rolling `motorway-exits` release the pipeline publishes — a URL
/// fully under the project's control (the fuel-gr pattern, #3549).
///
/// Keyed per country through [KeyedCachedDatasetMixin] +
/// [PersistentDataset]: soft TTL 30 days (exits change on the timescale
/// of years; the pipeline republishes monthly), hard TTL 365 days as
/// offline grace. A never-fetched country simply yields an empty list —
/// highway mode degrades to its exit-less v1 behaviour.
class MotorwayExitsService with KeyedCachedDatasetMixin {
  MotorwayExitsService({Dio? dio, CacheStrategy? cache, String? baseUrl})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
        _cache = cache,
        _baseUrl = baseUrl ?? defaultBaseUrl;

  /// Rolling release the `motorway-exits-publish.yml` pipeline feeds.
  // i18n-ignore: release-asset URL, not user-facing text
  static const String defaultBaseUrl =
      'https://github.com/fdittgen-png/tankstellen/releases/download/'
      'motorway-exits';

  static const Duration _softTtl = Duration(days: 30);
  static const Duration _hardTtl = Duration(days: 365);

  final Dio _dio;
  final CacheStrategy? _cache;
  final String _baseUrl;

  final Map<String, List<MotorwayExit>> _byCountry = {};

  PersistentDataset<List<MotorwayExit>>? _datasetFor(String cc) {
    final cache = _cache;
    if (cache == null) return null;
    return PersistentDataset<List<MotorwayExit>>(
      cache: cache,
      countryCode: cc,
      datasetName: 'motorway_exits',
      source: ServiceSource.cache,
      serialize: _serializeExits,
      deserialize: _deserializeExits,
    );
  }

  /// The exits for [countryCode] (upper- or lower-case). Serves the
  /// in-memory/persisted copy per the keyed mixin's SWR semantics and
  /// refreshes from the release asset when soft-stale. NEVER throws:
  /// any failure yields the last-known copy or an empty list (v1
  /// degradation).
  Future<List<MotorwayExit>> exitsFor(String countryCode) async {
    final cc = countryCode.toUpperCase();
    try {
      return await loadKeyedPersistentDataset<List<MotorwayExit>>(
        key: cc,
        cached: _byCountry[cc],
        softTtl: _softTtl,
        hardTtl: _hardTtl,
        persistent: _datasetFor(cc),
        fetch: () => _fetch(cc),
        store: (v) => _byCountry[cc] = v,
      );
    } on Object {
      // ignore: silent_catch — degrade to exit-less v1; the mixin already
      // exhausted the persisted fallbacks before rethrowing.
      return _byCountry[cc] ?? const [];
    }
  }

  Future<List<MotorwayExit>> _fetch(String cc) async {
    final url = '$_baseUrl/exits_${cc.toLowerCase()}.json';
    final resp = await _dio.get<Map<String, dynamic>>(url);
    final body = resp.data;
    if (body == null) return const [];
    return parseMotorwayExits(body);
  }
}

// Top-level (isolate-sendable, #3154) codec pair for [PersistentDataset].
Map<String, dynamic> _serializeExits(List<MotorwayExit> exits) => {
      'exits': [
        for (final e in exits)
          {
            'la': e.lat,
            'lo': e.lng,
            if (e.ref != null) 'r': e.ref,
            if (e.name != null) 'n': e.name,
          },
      ],
    };

List<MotorwayExit>? _deserializeExits(Map<String, dynamic> json) =>
    parseMotorwayExits(json);
