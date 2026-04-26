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

/// A single OSRM alternative (or any candidate route) scored by the
/// eco strategy. Bundles the raw OSRM-derived metrics we need to
/// compute `time + α × elevation + β × speed_variance_penalty`.
///
/// `elevationGainMeters` is null when OSRM did not return an
/// elevation profile (the public demo server typically doesn't).
/// In that case `EcoRouteSearchStrategy.scoreCandidate` falls back
/// to time + speed-variance only — see the strategy's class docs.
@immutable
class EcoRouteCandidate {
  const EcoRouteCandidate({
    required this.geometry,
    required this.distanceKm,
    required this.durationMinutes,
    this.elevationGainMeters,
    this.legSpeedsKmh = const <double>[],
  });

  final List<LatLng> geometry;
  final double distanceKm;
  final double durationMinutes;

  /// Total positive elevation gain along the candidate, in metres.
  /// Null when the OSRM response carries no elevation data.
  final double? elevationGainMeters;

  /// Per-leg average speed in km/h. Used to compute a speed-variance
  /// penalty: routes that mix highway + slow stretches burn more
  /// fuel than a flat-cruise highway-only route. Empty list means
  /// "we couldn't sample legs" and the variance penalty is 0.
  final List<double> legSpeedsKmh;

  /// Convert to the public `RouteInfo` shape, sampling every ~15 km
  /// for downstream station-along-route queries (mirrors
  /// `RoutingService._sampleAlongPolyline`).
  RouteInfo toRouteInfo() {
    final samples = _sampleAlongPolyline(geometry, 15.0);
    return RouteInfo(
      geometry: geometry,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      samplePoints: samples,
    );
  }

  static List<LatLng> _sampleAlongPolyline(
    List<LatLng> polyline,
    double intervalKm,
  ) {
    if (polyline.isEmpty) return const <LatLng>[];
    final samples = <LatLng>[polyline.first];
    double accumulated = 0;
    for (var i = 1; i < polyline.length; i++) {
      final prev = polyline[i - 1];
      final curr = polyline[i];
      accumulated += geo.distanceKm(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
      if (accumulated >= intervalKm) {
        samples.add(curr);
        accumulated = 0;
      }
    }
    if (samples.last != polyline.last) {
      samples.add(polyline.last);
    }
    return samples;
  }
}

/// Eco routing strategy (#1123).
///
/// Picks routes that minimise *fuel*, not *time*. Across a set of
/// OSRM alternatives, the strategy scores each candidate with
///
///     weight = time_minutes
///            + α × elevationGainMeters
///            + β × speedVariancePenalty
///
/// and returns the candidate with the lowest weight. The constants
/// [alpha] and [beta] are tuned so that a route up to ~15 % slower
/// than the fastest option but with markedly less elevation gain
/// or steadier speeds wins. They are documented in-source so a
/// future maintainer can re-tune from one place.
///
/// ### Fallback
/// When OSRM returns no elevation profile (the public demo server
/// strips it), the formula degrades to `time + β × speedVariance`.
/// The strategy still produces a meaningful preference for steady
/// highway over zigzag-shortcut alternatives.
///
/// ### Scope
/// This file owns the *route-selection* logic. The station-search
/// portion of the strategy (sampling along the chosen polyline,
/// filtering by detour, ordering by itinerary) mirrors
/// [`UniformSearchStrategy`] — once the eco route is picked, the
/// stations-along-route problem is the same one.
class EcoRouteSearchStrategy implements RouteSearchStrategy {
  /// Cost in `score units` per metre of cumulative elevation gain.
  ///
  /// Tuning rationale: a typical 100 km highway leg with 200 m of
  /// gain represents ~+0.3 L of fuel for a 7 L/100 km vehicle.
  /// We want that to *outweigh* a +5 minute detour penalty around
  /// the gain — so 1 m ≈ 0.05 minutes of equivalent "cost" puts
  /// 200 m of climb on par with a 10 minute detour. That feels
  /// right for "ship the flatter route unless it's wildly slower".
  static const double alpha = 0.05;

  /// Cost in `score units` per (km/h)² of speed variance across
  /// route legs. Highway-only candidates have variance ≈ 0;
  /// city + highway mixes can hit 600–900 km²/h². The constant
  /// 0.02 makes a variance of 500 worth ~10 minutes of equivalent
  /// detour, which discourages stop-and-go shortcuts.
  static const double beta = 0.02;

  /// Cap on how much slower the eco choice may be vs the fastest
  /// candidate. Above this ratio the eco strategy gives up on the
  /// alternative and re-selects the fastest, on the theory that
  /// the user came to drive, not to crawl. Matches the issue's
  /// "≤ 15 % slower" acceptance bullet.
  static const double maxSlowdownRatio = 1.15;

  @override
  String get name => 'Eco';

  @override
  String get l10nKey => 'ecoSearch';

  /// Score a single candidate. Public so tests can pin the
  /// weighting math without going through OSRM.
  static double scoreCandidate(EcoRouteCandidate c) {
    final elevTerm =
        c.elevationGainMeters == null ? 0.0 : alpha * c.elevationGainMeters!;
    final variance = _speedVariance(c.legSpeedsKmh);
    final varianceTerm = beta * variance;
    return c.durationMinutes + elevTerm + varianceTerm;
  }

  /// Select the eco-best candidate from a list. Returns the
  /// fastest candidate when:
  ///   * the list is empty (caller-side error — never hits here
  ///     in practice),
  ///   * only one candidate exists,
  ///   * every alternative is more than [maxSlowdownRatio] slower
  ///     than the fastest.
  ///
  /// Otherwise returns the lowest-weight candidate within the
  /// slowdown cap.
  static EcoRouteCandidate selectEcoRoute(List<EcoRouteCandidate> candidates) {
    if (candidates.isEmpty) {
      throw ArgumentError('selectEcoRoute requires at least one candidate');
    }
    if (candidates.length == 1) return candidates.first;

    final fastest = candidates
        .reduce((a, b) => a.durationMinutes <= b.durationMinutes ? a : b);
    final cap = fastest.durationMinutes * maxSlowdownRatio;

    EcoRouteCandidate best = fastest;
    double bestScore = scoreCandidate(fastest);
    for (final c in candidates) {
      if (c.durationMinutes > cap) continue;
      final s = scoreCandidate(c);
      if (s < bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return best;
  }

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

  /// Population variance of the per-leg speeds. Returns 0 for
  /// empty/single-element lists (no penalty when we have no signal).
  static double _speedVariance(List<double> speeds) {
    if (speeds.length < 2) return 0;
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    double sumSq = 0;
    for (final s in speeds) {
      final d = s - mean;
      sumSq += d * d;
    }
    return sumSq / speeds.length;
  }
}

/// Estimated litres saved by picking the eco route over the fastest.
///
/// Simple model: distance × consumption_baseline_lPer100km / 100,
/// adjusted by the eco route's expected efficiency uplift relative
/// to the fastest. We assume the eco route burns
/// `1 / (1 + ecoEfficiencyLift)` as much per km as the fastest —
/// `0.07` (7 % less) is a defensible default for a steady-cruise
/// vs zigzag delta on a typical European motorway+B-road mix.
///
/// Returns 0.0 when either route is empty or the math underflows.
class EcoSavingsEstimator {
  /// Default consumption (L / 100 km) when the user hasn't set a
  /// vehicle baseline. 7 L is roughly the EU fleet average for
  /// petrol passenger cars (EEA 2023). Diesel users will see a
  /// slight over-estimate — fine for a UI hint.
  static const double defaultConsumptionLPer100km = 7.0;

  /// Eco route burns `1 / (1 + lift)` × the fastest route's per-km
  /// consumption. 7 % is a conservative midpoint of the
  /// 5–10 % range reported by EU eco-driving studies for steady
  /// cruise vs aggressive variable-speed driving.
  static const double ecoEfficiencyLift = 0.07;

  /// Compute estimated litres saved by switching from [fastest] to
  /// [eco]. Both arguments are total-route distances in km +
  /// total-route durations in minutes; consumption is L/100 km.
  ///
  /// Returns a non-negative value (clamped at 0) — if the model
  /// somehow predicts the eco route burns *more*, we hide the
  /// preview rather than scare the user.
  static double estimateLitersSaved({
    required double fastestDistanceKm,
    required double ecoDistanceKm,
    required double consumptionLPer100km,
  }) {
    if (fastestDistanceKm <= 0 || ecoDistanceKm <= 0) return 0.0;
    if (consumptionLPer100km <= 0) return 0.0;
    final fastestL = fastestDistanceKm * consumptionLPer100km / 100.0;
    final ecoConsumption =
        consumptionLPer100km / (1.0 + ecoEfficiencyLift);
    final ecoL = ecoDistanceKm * ecoConsumption / 100.0;
    final delta = fastestL - ecoL;
    return delta > 0 ? delta : 0.0;
  }
}
