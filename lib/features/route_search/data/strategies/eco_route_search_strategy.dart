import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/geo_utils.dart' as geo;
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';
import '../helpers/batch_query_helper.dart';
import 'eco_route_candidate.dart';
import 'eco_route_scoring.dart';

// Re-export the value types so existing imports of
// `eco_route_search_strategy.dart` continue to resolve
// `EcoRouteCandidate` and `EcoSavingsEstimator` symbols without
// touching every callsite.
export 'eco_route_candidate.dart' show EcoRouteCandidate;
export 'eco_savings_estimator.dart' show EcoSavingsEstimator;

/// Eco routing strategy (#1123).
///
/// Picks routes that minimise *fuel*, not *time*. Across a set of
/// OSRM alternatives, the strategy scores each candidate with
///
///     weight = time_minutes
///            + α × elevationGainMeters
///            + β × speedVariancePenalty
///
/// and returns the candidate with the lowest weight. The tuning
/// constants ([EcoRouteScoring.alpha], [EcoRouteScoring.beta],
/// [EcoRouteScoring.maxSlowdownRatio]) are calibrated so that a
/// route up to ~15 % slower than the fastest option but with
/// markedly less elevation gain or steadier speeds wins. They live
/// on [EcoRouteScoring] so a future maintainer can re-tune from
/// one place.
///
/// ### Fallback
/// When OSRM returns no elevation profile (the public demo server
/// strips it), the formula degrades to `time + β × speedVariance`.
/// The strategy still produces a meaningful preference for steady
/// highway over zigzag-shortcut alternatives.
///
/// ### Scope
/// This file owns the *route-selection orchestration*. The pure
/// scoring math lives in `eco_route_scoring.dart`; the candidate
/// value type lives in `eco_route_candidate.dart`. The
/// station-search portion of the strategy (sampling along the
/// chosen polyline, filtering by detour, ordering by itinerary)
/// mirrors [`UniformSearchStrategy`] — once the eco route is
/// picked, the stations-along-route problem is the same one.
class EcoRouteSearchStrategy implements RouteSearchStrategy {
  @override
  String get name => 'Eco';

  @override
  String get l10nKey => 'ecoSearch';

  /// Score a single candidate. Delegates to [EcoRouteScoring.scoreCandidate]
  /// — the implementation lives there so the math is testable in isolation.
  static double scoreCandidate(EcoRouteCandidate c) =>
      EcoRouteScoring.scoreCandidate(c);

  /// Select the eco-best candidate from a list. Delegates to
  /// [EcoRouteScoring.selectEcoRoute].
  static EcoRouteCandidate selectEcoRoute(List<EcoRouteCandidate> candidates) =>
      EcoRouteScoring.selectEcoRoute(candidates);

  /// Parse an OSRM `/route/v1/driving/...?alternatives=true` JSON
  /// response into a list of [EcoRouteCandidate]s. Tolerates the
  /// public demo server's missing elevation data — extracts what's
  /// available and lets the scoring fall back gracefully.
  ///
  /// Returns an empty list when the response cannot be parsed.
  static List<EcoRouteCandidate> parseOsrmAlternatives(
    Map<String, dynamic> json,
  ) {
    try {
      if (json['code'] != 'Ok') return const <EcoRouteCandidate>[];
      final routes = json['routes'];
      if (routes is! List) return const <EcoRouteCandidate>[];

      final out = <EcoRouteCandidate>[];
      for (final r in routes) {
        if (r is! Map<String, dynamic>) continue;
        final distM = (r['distance'] as num?)?.toDouble() ?? 0.0;
        final durS = (r['duration'] as num?)?.toDouble() ?? 0.0;
        if (durS <= 0) continue;

        final geom = r['geometry'];
        final polyline = <LatLng>[];
        if (geom is Map<String, dynamic>) {
          final coords = geom['coordinates'];
          if (coords is List) {
            for (final c in coords) {
              if (c is List && c.length >= 2) {
                final lng = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                polyline.add(LatLng(lat, lng));
              }
            }
          }
        }

        // OSRM `legs` carry per-leg durations + distances. We turn
        // each into an average speed; the variance across these
        // averages is the "highway-vs-zigzag" signal.
        final legSpeeds = <double>[];
        double? totalElevGain;
        final legs = r['legs'];
        if (legs is List) {
          for (final leg in legs) {
            if (leg is! Map<String, dynamic>) continue;
            final ldist = (leg['distance'] as num?)?.toDouble() ?? 0.0;
            final ldur = (leg['duration'] as num?)?.toDouble() ?? 0.0;
            if (ldur > 0 && ldist > 0) {
              legSpeeds.add((ldist / 1000.0) / (ldur / 3600.0));
            }
            // OSRM-extras / Valhalla put elevation on the leg as
            // `summary.elevation_gain` or under annotation; accept
            // either shape. Stays null for the public demo server.
            final summary = leg['summary'];
            if (summary is Map<String, dynamic>) {
              final eg = summary['elevation_gain'];
              if (eg is num) {
                totalElevGain = (totalElevGain ?? 0) + eg.toDouble();
              }
            }
            final ann = leg['annotation'];
            if (ann is Map<String, dynamic>) {
              final eg = ann['elevation_gain'];
              if (eg is num) {
                totalElevGain = (totalElevGain ?? 0) + eg.toDouble();
              }
            }
          }
        }

        // Top-level `weight` sometimes carries elevation when the
        // OSRM profile is configured for it; we don't rely on it
        // but accept it as a final fallback.
        final topElev = r['elevation_gain'];
        if (totalElevGain == null && topElev is num) {
          totalElevGain = topElev.toDouble();
        }

        out.add(EcoRouteCandidate(
          geometry: polyline,
          distanceKm: distM / 1000.0,
          durationMinutes: durS / 60.0,
          elevationGainMeters: totalElevGain,
          legSpeedsKmh: legSpeeds,
        ));
      }
      return out;
    } catch (e, st) {
      // Never silent — route selection failing must surface.
      errorLogger.log(
        ErrorLayer.services,
        e,
        st,
        context: <String, Object?>{
          'where': 'EcoRouteSearchStrategy.parseOsrmAlternatives',
        },
      );
      return const <EcoRouteCandidate>[];
    }
  }

  @override
  Future<List<SearchResultItem>> searchAlongRoute({
    required RouteInfo route,
    required FuelType fuelType,
    required double searchRadiusKm,
    required StationQueryFunction queryStations,
    double? maxDetourKm,
  }) async {
    debugPrint(
      'EcoSearch: querying ${route.samplePoints.length} sample points '
      'with radius=${searchRadiusKm}km on the eco-selected polyline',
    );

    const batchHelper = BatchQueryHelper(batchSize: 4);
    final results = await batchHelper.queryAll(
      samplePoints: route.samplePoints,
      queryStations: queryStations,
      fuelType: fuelType,
      searchRadiusKm: searchRadiusKm,
    );

    final detourLimit = maxDetourKm ?? searchRadiusKm;
    final filtered = <SearchResultItem>[];
    for (final item in results) {
      if (item is FuelStationResult) {
        final minDist = _minDistanceToPolyline(
          item.station.lat,
          item.station.lng,
          route.geometry,
        );
        if (minDist <= detourLimit) {
          filtered.add(item);
        }
      } else {
        filtered.add(item);
      }
    }

    _sortByItineraryOrder(filtered, route.geometry);
    return filtered;
  }

  @override
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
  }) {
    final segmentCheapest = <int, String>{};
    for (final item in results) {
      if (item is FuelStationResult) {
        final station = item.station;
        int nearestSampleIdx = 0;
        double minDist = double.infinity;
        for (int i = 0; i < route.samplePoints.length; i++) {
          final d = geo.distanceKm(
            station.lat,
            station.lng,
            route.samplePoints[i].latitude,
            route.samplePoints[i].longitude,
          );
          if (d < minDist) {
            minDist = d;
            nearestSampleIdx = i;
          }
        }
        final segmentIdx = (nearestSampleIdx * 15 / segmentKm).floor();
        final price = station.priceFor(fuelType);
        if (price != null) {
          final currentBest = segmentCheapest[segmentIdx];
          if (currentBest == null) {
            segmentCheapest[segmentIdx] = station.id;
          } else {
            final currentBestItem = results
                .whereType<FuelStationResult>()
                .where((r) => r.id == currentBest)
                .firstOrNull;
            final currentBestPrice =
                currentBestItem?.station.priceFor(fuelType);
            if (currentBestPrice == null || price < currentBestPrice) {
              segmentCheapest[segmentIdx] = station.id;
            }
          }
        }
      }
    }
    return segmentCheapest;
  }

  double _minDistanceToPolyline(
    double lat,
    double lng,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return double.infinity;
    double minDist = double.infinity;
    final step = polyline.length > 300 ? 3 : 1;
    for (int i = 0; i < polyline.length; i += step) {
      final p = polyline[i];
      final d = geo.distanceKm(lat, lng, p.latitude, p.longitude);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  void _sortByItineraryOrder(
    List<SearchResultItem> items,
    List<LatLng> geometry,
  ) {
    items.sort((a, b) {
      final da = geo.distanceAlongPolyline(a.lat, a.lng, geometry);
      final db = geo.distanceAlongPolyline(b.lat, b.lng, geometry);
      return da.compareTo(db);
    });
  }
}
