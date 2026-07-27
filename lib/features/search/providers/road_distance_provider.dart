// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/station.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../route_search/api.dart';

part 'road_distance_provider.g.dart';

/// How many top-ranked stations get a real road distance per refresh —
/// one OSRM `/table` request covers all of them (#3634).
const int kRoadDistanceTopN = 8;

/// Movement/time gate mirroring the #3254 in-radius merge: don't re-ask
/// OSRM until the origin moved this far or this long has passed.
const double kRoadDistanceRefetchMeters = 500;
const Duration kRoadDistanceRefetchInterval = Duration(seconds: 60);

/// The single road-distance fetch seam, injectable so tests never touch
/// the network. Defaults to the shared [RoutingService] table call.
@Riverpod(keepAlive: true)
Future<List<double?>> Function(
  double lat,
  double lng,
  List<({double lat, double lng})> destinations,
) roadDistanceFetcher(Ref ref) {
  final service = RoutingService();
  return (lat, lng, destinations) => service.roadDistancesKm(
        originLat: lat,
        originLng: lng,
        destinations: destinations,
      );
}

/// Station-id → real road distance (km) for the radar surface (#3634).
///
/// Display-only enrichment: the crow-flies figure always remains the
/// baseline, sorting stays with the ranking authority, and any failure
/// leaves the map as-is (silent degrade — the list must never suffer for
/// a routing hiccup). Session-lived; `keepAlive` so paging around the
/// app doesn't refetch.
@Riverpod(keepAlive: true)
class RoadDistances extends _$RoadDistances {
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastAt;
  bool _inFlight = false;

  @override
  Map<String, double> build() => const {};

  /// Refresh road distances for the [kRoadDistanceTopN] nearest of
  /// [ranked] from ([lat], [lng]). Gated on movement + time; silent on
  /// failure; merges into the existing map so older entries keep
  /// answering while a refresh is in flight.
  Future<void> refresh({
    required double lat,
    required double lng,
    required List<Station> ranked,
  }) async {
    if (ranked.isEmpty || _inFlight) return;
    final now = DateTime.now();
    final lastLat = _lastLat, lastLng = _lastLng, lastAt = _lastAt;
    if (lastLat != null && lastLng != null && lastAt != null) {
      final movedM = geo.distanceMeters(lastLat, lastLng, lat, lng);
      if (movedM < kRoadDistanceRefetchMeters &&
          now.difference(lastAt) < kRoadDistanceRefetchInterval) {
        return;
      }
    }
    final top = ranked.take(kRoadDistanceTopN).toList(growable: false);
    _inFlight = true;
    try {
      final fetch = ref.read(roadDistanceFetcherProvider);
      final kms = await fetch(
        lat,
        lng,
        [for (final s in top) (lat: s.lat, lng: s.lng)],
      );
      _lastLat = lat;
      _lastLng = lng;
      _lastAt = now;
      final next = Map<String, double>.from(state);
      for (var i = 0; i < top.length && i < kms.length; i++) {
        final km = kms[i];
        if (km != null) next[top[i].id] = km;
      }
      state = next;
    } catch (e, st) {
      // Routing is best-effort garnish — log for the field export, keep
      // whatever distances we already had.
      unawaited(errorLogger.log(ErrorLayer.services, e, st,
          context: const {'where': 'RoadDistances refresh'}));
    } finally {
      _inFlight = false;
    }
  }
}
