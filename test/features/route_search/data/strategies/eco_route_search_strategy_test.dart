import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/eco_route_search_strategy.dart';

/// Build a synthetic OSRM `routes[]` JSON entry with the metadata
/// the strategy actually reads — geometry coordinates, distance,
/// duration, optional per-leg distance/duration, and optional
/// `summary.elevation_gain` on each leg. Keeps the contrived test
/// fixtures in one place so the assertions read cleanly.
Map<String, dynamic> buildOsrmRoute({
  required List<List<double>> coordsLngLat,
  required double distanceM,
  required double durationS,
  List<({double distM, double durS, double? elevGain})> legs = const [],
}) {
  return {
    'distance': distanceM,
    'duration': durationS,
    'geometry': {
      'coordinates': coordsLngLat,
    },
    'legs': [
      for (final l in legs)
        {
          'distance': l.distM,
          'duration': l.durS,
          if (l.elevGain != null)
            'summary': {'elevation_gain': l.elevGain},
        },
    ],
  };
}

void main() {
  group('EcoRouteSearchStrategy.scoreCandidate', () {
    test('time-only when no elevation and single leg', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
      );
      // Variance over <2 legs is 0; score collapses to durationMinutes.
      expect(EcoRouteSearchStrategy.scoreCandidate(c), 60.0);
    });

    test('elevation gain adds α × meters to the score', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 200,
      );
      // 60 + 0.05 × 200 = 70.
      expect(EcoRouteSearchStrategy.scoreCandidate(c), closeTo(70.0, 1e-9));
    });

    test('speed variance adds β × variance to the score', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        // Population variance of [40, 120] is ((40-80)² + (120-80)²)/2 = 1600.
        legSpeedsKmh: [40, 120],
      );
      // 60 + 0.02 × 1600 = 92.
      expect(EcoRouteSearchStrategy.scoreCandidate(c), closeTo(92.0, 1e-9));
    });
  });

  group('EcoRouteSearchStrategy.selectEcoRoute', () {
    test('returns the only candidate when the list has one entry', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 999,
      );
      expect(
        identical(EcoRouteSearchStrategy.selectEcoRoute([c]), c),
        isTrue,
      );
    });

    test('hilly contrived: prefers the flatter alternative', () {
      // Two routes: one short + steep (60 min, 800 m climb),
      // one slightly longer + flat (66 min, 50 m climb).
      const steep = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 95,
        durationMinutes: 60,
        elevationGainMeters: 800,
        legSpeedsKmh: [30, 110],
      );
      const flat = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 105,
        durationMinutes: 66,
        elevationGainMeters: 50,
        legSpeedsKmh: [115, 118],
      );

      final picked = EcoRouteSearchStrategy.selectEcoRoute([steep, flat]);
      expect(
        identical(picked, flat),
        isTrue,
        reason: 'Eco strategy should pick the flatter, steadier alternative '
            'over the short-but-steep one within the 15 % slowdown cap.',
      );
    });

    test('flat-symmetric: falls back to the fastest gracefully', () {
      // Two routes with equal elevation and similar legs but the
      // second is 5 % slower for no reason. Fastest should win
      // because there's no eco signal to chase.
      const a = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 30,
        legSpeedsKmh: [110, 115],
      );
      const b = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 63,
        elevationGainMeters: 30,
        legSpeedsKmh: [110, 115],
      );

      final picked = EcoRouteSearchStrategy.selectEcoRoute([a, b]);
      expect(
        identical(picked, a),
        isTrue,
        reason: 'Without an elevation or variance edge, eco should fall '
            'back to the fastest candidate (no fuel signal to chase).',
      );
    });

    test('respects 15 % slowdown cap: rejects wildly slower flat route', () {
      // Flat candidate is 30 % slower — beyond the cap. Even if its
      // raw eco score is lower, the strategy must reject it.
      const fastest = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 400,
        legSpeedsKmh: [40, 130],
      );
      const tooSlow = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 80, // 33 % slower than fastest
        elevationGainMeters: 30,
        legSpeedsKmh: [110, 115],
      );

      final picked =
          EcoRouteSearchStrategy.selectEcoRoute([fastest, tooSlow]);
      expect(
        identical(picked, fastest),
        isTrue,
        reason: 'tooSlow exceeds the 15 % slowdown cap and must be rejected '
            'even though its raw eco score is lower.',
      );
    });

    test('throws ArgumentError on empty list', () {
      expect(
        () => EcoRouteSearchStrategy.selectEcoRoute(const []),
        throwsArgumentError,
      );
    });
  });

  group('EcoRouteSearchStrategy.parseOsrmAlternatives', () {
    test('parses a hilly OSRM response with two alternatives correctly', () {
      // First alternative: short + steep (60 min, 800 m climb,
      // wildly variable leg speeds).
      // Second: longer + flat (66 min, 30 m climb, steady).
      final json = {
        'code': 'Ok',
        'routes': [
          buildOsrmRoute(
            coordsLngLat: const [
              [2.0, 48.0],
              [2.05, 48.05],
              [2.1, 48.1],
            ],
            distanceM: 95000,
            durationS: 3600,
            legs: const [
              (distM: 30000, durS: 3600, elevGain: 800.0),
            ],
          ),
          buildOsrmRoute(
            coordsLngLat: const [
              [2.0, 48.0],
              [2.06, 48.06],
              [2.12, 48.12],
            ],
            distanceM: 105000,
            durationS: 3960,
            legs: const [
              (distM: 50000, durS: 1800, elevGain: 15.0),
              (distM: 55000, durS: 2160, elevGain: 15.0),
            ],
          ),
        ],
      };

      final candidates = EcoRouteSearchStrategy.parseOsrmAlternatives(json);
      expect(candidates.length, 2);

      expect(candidates[0].distanceKm, closeTo(95.0, 1e-6));
      expect(candidates[0].durationMinutes, closeTo(60.0, 1e-6));
      expect(candidates[0].elevationGainMeters, 800.0);

      expect(candidates[1].distanceKm, closeTo(105.0, 1e-6));
      expect(candidates[1].durationMinutes, closeTo(66.0, 1e-6));
      expect(candidates[1].elevationGainMeters, 30.0);
    });

    test('returns empty list when OSRM code != "Ok"', () {
      final candidates = EcoRouteSearchStrategy.parseOsrmAlternatives({
        'code': 'NoRoute',
        'routes': [],
      });
      expect(candidates, isEmpty);
    });

    test('handles missing elevation data (public OSRM demo) gracefully', () {
      final json = {
        'code': 'Ok',
        'routes': [
          buildOsrmRoute(
            coordsLngLat: const [
              [2.0, 48.0],
              [2.1, 48.1],
            ],
            distanceM: 100000,
            durationS: 3600,
            // Leg with no elevation_gain summary.
            legs: const [
              (distM: 100000, durS: 3600, elevGain: null),
            ],
          ),
        ],
      };

      final candidates = EcoRouteSearchStrategy.parseOsrmAlternatives(json);
      expect(candidates.length, 1);
      expect(
        candidates[0].elevationGainMeters,
        isNull,
        reason: 'Falls back to time + variance only when elevation absent.',
      );
      // Score should still be well-defined and equal duration (no variance
      // signal with a single leg).
      expect(
        EcoRouteSearchStrategy.scoreCandidate(candidates[0]),
        60.0,
      );
    });

    test('hilly fixture end-to-end: parse + select picks the flat route', () {
      // Mirrors the acceptance test in the issue: feed a contrived hilly
      // OSRM response with two alternatives — short-steep vs longer-flat —
      // and assert the eco strategy returns the flat one.
      final json = {
        'code': 'Ok',
        'routes': [
          buildOsrmRoute(
            coordsLngLat: const [
              [2.0, 48.0],
              [2.1, 48.1],
            ],
            distanceM: 95000,
            durationS: 3600,
            legs: const [
              (distM: 47500, durS: 720, elevGain: 400.0), // 237 km/h?
              (distM: 47500, durS: 2880, elevGain: 400.0), // ~59 km/h
            ],
          ),
          buildOsrmRoute(
            coordsLngLat: const [
              [2.0, 48.0],
              [2.1, 48.1],
            ],
            distanceM: 105000,
            durationS: 3960,
            legs: const [
              (distM: 52500, durS: 1980, elevGain: 25.0), // ~95 km/h
              (distM: 52500, durS: 1980, elevGain: 25.0), // ~95 km/h
            ],
          ),
        ],
      };

      final candidates = EcoRouteSearchStrategy.parseOsrmAlternatives(json);
      final picked = EcoRouteSearchStrategy.selectEcoRoute(candidates);
      expect(picked.elevationGainMeters, 50.0);
      expect(picked.distanceKm, closeTo(105.0, 1e-6));
    });
  });

  group('EcoRouteCandidate.toRouteInfo', () {
    test('preserves geometry and produces non-empty sample points', () {
      const c = EcoRouteCandidate(
        geometry: [
          LatLng(48.0, 2.0),
          LatLng(48.5, 2.5),
          LatLng(49.0, 3.0),
        ],
        distanceKm: 80,
        durationMinutes: 60,
      );
      final info = c.toRouteInfo();
      expect(info.geometry.length, 3);
      expect(info.distanceKm, 80);
      expect(info.durationMinutes, 60);
      expect(info.samplePoints, isNotEmpty);
    });
  });

  group('EcoSavingsEstimator', () {
    test('returns 0 for non-positive distances', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 0,
          ecoDistanceKm: 100,
          consumptionLPer100km: 7,
        ),
        0.0,
      );
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 100,
          ecoDistanceKm: -1,
          consumptionLPer100km: 7,
        ),
        0.0,
      );
    });

    test('returns 0 when consumption baseline is non-positive', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 100,
          ecoDistanceKm: 100,
          consumptionLPer100km: 0,
        ),
        0.0,
      );
    });

    test('predicts a non-trivial saving for a 400 km trip at 7 L/100km', () {
      // Fastest: 400 × 7 / 100 = 28 L
      // Eco @ 7 % uplift: 28 / 1.07 ≈ 26.17 L
      // Delta ≈ 1.83 L.
      final saved = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 400,
        ecoDistanceKm: 400,
        consumptionLPer100km: 7,
      );
      expect(saved, greaterThan(1.5));
      expect(saved, lessThan(2.5));
    });

    test('clamps to 0 when the eco route is much longer than the fastest', () {
      // Pathological input: eco route 50 % longer than fastest.
      // Even the 7 % efficiency uplift cannot offset the extra distance,
      // so the predicted "savings" would be negative — estimator clamps
      // to 0 to avoid misleading the user.
      final saved = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 100,
        ecoDistanceKm: 150,
        consumptionLPer100km: 7,
      );
      expect(saved, 0.0);
    });
  });
}
