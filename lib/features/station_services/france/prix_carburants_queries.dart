// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/network/dio_offline.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'prix_carburants_parsers.dart' as parser;

/// The two ODSQL `records` queries against the data.economie.gouv.fr
/// flux-instantane endpoint, split out of `PrixCarburantsStationService` (#3326)
/// so that orchestrator stays under the file-length cap. Pure transport: each
/// takes the caller's [dio] + [baseUrl], returns raw result maps, and swallows
/// an OFFLINE failure to `[]` (only a real API error gets an ERROR trace).

Future<List<Map<String, dynamic>>> queryPrixCarburantsByPostalCode(
  Dio dio,
  String baseUrl,
  String cp, {
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.get<dynamic>(baseUrl, queryParameters: {
      'where': "cp='$cp'",
      'limit': 50,
    }, cancelToken: cancelToken);
    return parser.extractPrixCarburantsResults(response.data);
  } on DioException catch (e, st) {
    // #2524 — an OFFLINE failure (no network) is expected and already handled
    // (returns []), so it must NOT pollute the user error spool. Drop it to a
    // debugPrint; only a real API error (4xx/5xx, malformed) gets an ERROR.
    if (_isOffline(e)) {
      debugPrint('Prix-Carburants ZIP fetch skipped — offline ($e)');
      return [];
    }
    unawaited(errorLogger.log(ErrorLayer.other, e, st,
        context: const {'where': 'Prix-Carburants ZIP fetch failed'}));
    return [];
  }
}

Future<List<Map<String, dynamic>>> queryPrixCarburantsByGeo(
  Dio dio,
  String baseUrl,
  double lat,
  double lng,
  double radiusKm, {
  CancelToken? cancelToken,
}) async {
  // Use within_distance with km unit — the distance() function with meters
  // is unreliable on this API and often returns 0 results. Preserve one
  // decimal of precision so sub-km radius selections aren't silently
  // rounded to the nearest integer.
  final radiusStr = radiusKm.toStringAsFixed(1);
  // #2966 — order the corridor server-side by distance so the `limit: 50`
  // slice keeps the NEAREST 50, not an arbitrary 50. Without it a dense
  // corridor (e.g. 140 stations within 10 km of central Paris) returns an
  // un-distance-ordered subset and the genuinely-nearest forecourt can be
  // truncated out entirely — the server-side root cause behind the radar /
  // closeness / in-trip "missing nearest station" symptoms (deferred #2813
  // dense case; #2806 / #2965 in-radius merges become belt-and-braces). The
  // old `distance()` "0 results" note was the metres form; the validated v2.1
  // ODSQL `order_by=distance(geom,geom'POINT(lon lat)')` form (lon-lat order)
  // is accepted live and returns rows nearest-first — it changes only the
  // ordering / cap survival, never which stations are in-radius (still gated
  // by the unchanged `within_distance` filter).
  final point = "geom'POINT($lng $lat)'";
  try {
    final response = await dio.get<dynamic>(baseUrl, queryParameters: {
      'where': 'within_distance(geom,$point,${radiusStr}km)',
      'order_by': 'distance(geom,$point)',
      'limit': 50,
    }, cancelToken: cancelToken);
    return parser.extractPrixCarburantsResults(response.data);
  } on DioException catch (e, st) {
    // #2524 — an offline failure is expected and swallowed; only a real API
    // error gets an ERROR trace.
    if (_isOffline(e)) {
      // #2745 — the field trace #1 was a `DioException[unknown]` wrapping an
      // `HttpException('Software caused connection abort')` while offline. Drop
      // it to a diagnostic breadcrumb instead of an ERROR.
      BreadcrumbCollector.add(
        'Prix-Carburants geo fetch skipped — offline',
        detail: 'lat=$lat lng=$lng type=${e.type}',
      );
      debugPrint('Prix-Carburants geo fetch skipped — offline ($e)');
      return [];
    }
    unawaited(errorLogger.log(ErrorLayer.other, e, st,
        context: const {'where': 'Prix-Carburants geo fetch failed'}));
    return [];
  }
}

/// Whether [e] is an offline / no-network failure rather than a real API
/// error (#2524). Delegates to the shared [isOfflineError] classifier so this
/// and the trace-recorder de-noise gate classify offline transients
/// identically and can't drift (#2703/#2745).
bool _isOffline(DioException e) => isOfflineError(e);
