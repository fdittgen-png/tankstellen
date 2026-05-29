// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/rate_limit_interceptor.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/route_search_strategy.dart';

/// Executes station queries in concurrent batches for faster route search.
///
/// Three optimisations on the original per-point fan-out:
/// 1. **Per-sample-point top-N reduce (#2101)** — each point's raw
///    response is immediately collapsed to the top N stations by
///    [RouteSearchCriterion] before being merged into the global
///    accumulator. Bounds the candidate pool feeding into the
///    downstream isolate-hopped distance math.
/// 2. **Higher concurrency + adaptive throttle (#2104)** — defaults
///    to 8-wide and skips the 200 ms inter-batch pause unless the
///    upstream returns 429 or throws a connection-class failure. A
///    single 429 anywhere in the sweep re-enables the pause for the
///    rest of the search.
/// 3. **Incremental emission (#2103)** — optional [onPartial]
///    callback fires after each batch with the running, top-N-reduced
///    accumulator so the UI can paint the first screenful while later
///    batches are still in flight.
class BatchQueryHelper {
  final int batchSize;

  /// #2104 — fallback pause re-enabled after a 429 or connection-class
  /// failure. 200 ms matches the prior unconditional throttle.
  final Duration backoffPause;

  const BatchQueryHelper({
    this.batchSize = 8,
    this.backoffPause = const Duration(milliseconds: 200),
  });

  /// Query stations at all [samplePoints] using concurrent batches.
  ///
  /// Returns deduplicated results already capped at
  /// [topNPerSamplePoint] per sample point and ranked by [criterion].
  /// Failed individual queries are skipped without aborting the batch.
  Future<List<SearchResultItem>> queryAll({
    required List<LatLng> samplePoints,
    required StationQueryFunction queryStations,
    required FuelType fuelType,
    required double searchRadiusKm,
    int topNPerSamplePoint = 10,
    RouteSearchCriterion criterion = RouteSearchCriterion.cheapest,
    void Function(List<SearchResultItem> partial)? onPartial,
  }) async {
    final seen = <String>{};
    final results = <SearchResultItem>[];
    int successCount = 0;
    int failCount = 0;
    bool rateLimited = false;
    // #2255 — longest upstream-suggested Retry-After seen this sweep. When
    // present it replaces the flat [backoffPause] so we honour the server's
    // own pacing instead of always pausing the same 200 ms.
    Duration? retryAfter;

    for (var batchStart = 0;
        batchStart < samplePoints.length;
        batchStart += batchSize) {
      final batchEnd =
          (batchStart + batchSize).clamp(0, samplePoints.length);
      final batch = samplePoints.sublist(batchStart, batchEnd);

      final futures = batch.map((point) async {
        try {
          final raw = await queryStations(
            lat: point.latitude,
            lng: point.longitude,
            radiusKm: searchRadiusKm,
            fuelType: fuelType,
          );
          // #2101 lever B — reduce **at this sample point** before
          // anything joins the global accumulator. Smaller pool ⇒
          // less work downstream and cheaper dedup.
          return (
            point: point,
            stations: _topNForPoint(
              raw,
              point: point,
              fuelType: fuelType,
              topN: topNPerSamplePoint,
              criterion: criterion,
            ),
            rateLimited: false,
            retryAfter: null,
          );
        } catch (e, st) {
          // #2255 — the services throw [DioException] / [ApiException] /
          // [ServiceChainExhaustedException], never http.ClientException, so
          // the old type-specific catches were dead code. Classify any
          // failure here: a 429 (raw or typed) re-enables the throttle and
          // carries the parsed Retry-After; a connection-class blip also
          // throttles to give the upstream room to recover.
          final (limited: isLimited, retryAfter: ra) = _classifyFailure(e);
          debugPrint(
              'BatchQuery: point ${point.latitude},${point.longitude} '
              'failed (${e.runtimeType}, rateLimited=$isLimited): $e\n$st');
          return (
            point: point,
            stations: const <SearchResultItem>[],
            rateLimited: isLimited,
            retryAfter: ra,
          );
        }
      });

      final batchResults = await Future.wait(futures);

      for (final r in batchResults) {
        if (r.rateLimited) rateLimited = true;
        if (r.retryAfter != null &&
            (retryAfter == null || r.retryAfter! > retryAfter)) {
          retryAfter = r.retryAfter;
        }
        if (r.stations.isNotEmpty) {
          successCount++;
        } else {
          failCount++;
        }
        for (final item in r.stations) {
          if (seen.add(item.id)) {
            results.add(item);
          }
        }
      }

      // #2103 lever C — emit the running, deduped accumulator. The
      // consumer takes a defensive copy if it wants to keep it.
      onPartial?.call(List<SearchResultItem>.unmodifiable(results));

      // #2104 lever D — pause only after a 429 / connection-class
      // failure has been observed in this sweep. Healthy sweeps run
      // back-to-back; degraded sweeps pause for the upstream-suggested
      // Retry-After (#2255) if one was sent, else the flat [backoffPause].
      if (batchEnd < samplePoints.length && rateLimited) {
        await Future<void>.delayed(retryAfter ?? backoffPause);
      }
    }

    debugPrint(
        'BatchQuery: $successCount succeeded, $failCount empty/failed, '
        '${results.length} unique stations (topN=$topNPerSamplePoint, '
        'criterion=${criterion.key}, throttle=${rateLimited ? "on" : "off"})');
    return results;
  }

  /// Reduce one sample point's raw response to the top [topN] by
  /// [criterion]. EV / non-fuel results pass through unchanged (no
  /// price → can't rank by cheapest; nearest is meaningless when
  /// criterion is cheapest). Result order is best-first.
  @visibleForTesting
  static List<SearchResultItem> topNForPoint(
    List<SearchResultItem> raw, {
    required LatLng point,
    required FuelType fuelType,
    required int topN,
    required RouteSearchCriterion criterion,
  }) =>
      _topNForPoint(
        raw,
        point: point,
        fuelType: fuelType,
        topN: topN,
        criterion: criterion,
      );

  static List<SearchResultItem> _topNForPoint(
    List<SearchResultItem> raw, {
    required LatLng point,
    required FuelType fuelType,
    required int topN,
    required RouteSearchCriterion criterion,
  }) {
    if (raw.length <= topN) return raw;
    final fuel = raw.whereType<FuelStationResult>().toList();
    final other =
        raw.where((r) => r is! FuelStationResult).toList(growable: false);
    switch (criterion) {
      case RouteSearchCriterion.cheapest:
        // Stations with no price for the requested fuel land at the
        // end — keep them rather than dropping (an unknown price
        // isn't a reason to hide a stop), but they don't displace a
        // priced station within the top-N.
        fuel.sort((a, b) {
          final pa = a.station.priceFor(fuelType);
          final pb = b.station.priceFor(fuelType);
          if (pa == null && pb == null) return 0;
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });
      case RouteSearchCriterion.nearest:
        fuel.sort((a, b) {
          final da = distanceKm(
              a.station.lat, a.station.lng, point.latitude, point.longitude);
          final db = distanceKm(
              b.station.lat, b.station.lng, point.latitude, point.longitude);
          return da.compareTo(db);
        });
    }
    return [...fuel.take(topN), ...other];
  }

  /// Classify a per-point failure for throttle purposes (#2255).
  ///
  /// Returns `(limited, retryAfter)` where `limited` re-enables the inter-batch
  /// pause for the rest of the sweep, and `retryAfter` is the upstream-suggested
  /// backoff when one was carried. Detects the rate-limit signal across every
  /// shape the data layer can surface:
  /// - a raw [DioException] with `response.statusCode == 429` (or a
  ///   `Retry-After` header) — the real services throw these;
  /// - a typed [ApiException] / [ServiceError] with
  ///   [FailureKind.rateLimited] — the chain stamps these (and connection /
  ///   timeout kinds also throttle);
  /// - a [ServiceChainExhaustedException] carrying any rate-limited
  ///   [ServiceError]; and
  /// - the legacy [http.ClientException] / [SocketException] string forms, for
  ///   any non-Dio caller.
  static ({bool limited, Duration? retryAfter}) _classifyFailure(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final header = e.response?.headers.value('retry-after');
      if (code == 429 || header != null) {
        return (limited: true, retryAfter: parseRetryAfter(header));
      }
      // Connection-class blip — throttle to give the upstream room.
      final t = e.type;
      final connClass = t == DioExceptionType.connectionError ||
          t == DioExceptionType.connectionTimeout ||
          t == DioExceptionType.receiveTimeout ||
          t == DioExceptionType.sendTimeout;
      return (limited: connClass, retryAfter: null);
    }
    if (e is ApiException) {
      final limited = e.kind == FailureKind.rateLimited ||
          e.kind == FailureKind.network ||
          e.kind == FailureKind.timeout;
      return (limited: limited, retryAfter: e.retryAfter);
    }
    if (e is ServiceChainExhaustedException) {
      Duration? ra;
      var limited = false;
      for (final err in e.errors) {
        if (err is ServiceError) {
          if (err.kind == FailureKind.rateLimited ||
              err.kind == FailureKind.network ||
              err.kind == FailureKind.timeout) {
            limited = true;
          }
          if (err.retryAfter != null &&
              (ra == null || err.retryAfter! > ra)) {
            ra = err.retryAfter;
          }
        }
      }
      return (limited: limited, retryAfter: ra);
    }
    if (e is SocketException) {
      // Connection-class blip — throttle for the rest of the sweep.
      return (limited: true, retryAfter: null);
    }
    if (e is http.ClientException) {
      final msg = e.message.toLowerCase();
      final limited =
          msg.contains('429') || msg.contains('too many requests');
      return (limited: limited, retryAfter: null);
    }
    return (limited: false, retryAfter: null);
  }
}
