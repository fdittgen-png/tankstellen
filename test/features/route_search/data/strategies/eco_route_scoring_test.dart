import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/eco_route_candidate.dart';
import 'package:tankstellen/features/route_search/data/strategies/eco_route_scoring.dart';

/// Direct tests against the pure scoring helpers extracted out of
/// `eco_route_search_strategy.dart`. The integration tests in
/// `eco_route_search_strategy_test.dart` continue to drive scoring
/// through the strategy class — these tests pin the math itself so
/// future tuning changes can be reviewed against explicit
/// numerical fixtures.
void main() {
  group('EcoRouteScoring constants', () {
    test('alpha, beta, maxSlowdownRatio retain documented defaults', () {
      // If these change, the issue acceptance bullets need re-tuning.
      // Pin them here so a "try a different alpha" experiment is
      // forced to update the test deliberately.
      expect(EcoRouteScoring.alpha, 0.05);
      expect(EcoRouteScoring.beta, 0.02);
      expect(EcoRouteScoring.maxSlowdownRatio, 1.15);
    });
  });

  group('EcoRouteScoring.speedVariance', () {
    test('returns 0 for empty list', () {
      expect(EcoRouteScoring.speedVariance(const <double>[]), 0.0);
    });

    test('returns 0 for a single-element list (no signal)', () {
      expect(EcoRouteScoring.speedVariance(const [110.0]), 0.0);
    });

    test('returns 0 for a constant-speed list', () {
      expect(EcoRouteScoring.speedVariance(const [110.0, 110.0, 110.0]), 0.0);
    });

    test('matches population variance (not sample variance) for two values', () {
      // [40, 120]: mean = 80, deviations = [-40, +40], sumSq = 3200.
      // population variance = 3200 / 2 = 1600.
      // sample variance     = 3200 / 1 = 3200 — would fail.
      expect(
        EcoRouteScoring.speedVariance(const [40.0, 120.0]),
        closeTo(1600.0, 1e-9),
      );
    });

    test('matches population variance for three highway-mixed values', () {
      // [60, 90, 120]: mean = 90; deviations = [-30, 0, +30].
      // sumSq = 900 + 0 + 900 = 1800; variance = 1800 / 3 = 600.
      expect(
        EcoRouteScoring.speedVariance(const [60.0, 90.0, 120.0]),
        closeTo(600.0, 1e-9),
      );
    });
  });

  group('EcoRouteScoring.scoreCandidate', () {
    test('drops the elevation term entirely when null', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
      );
      // 60 + 0 + 0 = 60 (no variance, no elevation).
      expect(EcoRouteScoring.scoreCandidate(c), 60.0);
    });

    test('combines elevation + variance terms additively', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 200,
        legSpeedsKmh: [40, 120], // variance = 1600
      );
      // 60 + 0.05 × 200 + 0.02 × 1600 = 60 + 10 + 32 = 102.
      expect(EcoRouteScoring.scoreCandidate(c), closeTo(102.0, 1e-9));
    });
  });

  group('EcoRouteScoring.selectEcoRoute', () {
    test('throws ArgumentError on empty list', () {
      expect(
        () => EcoRouteScoring.selectEcoRoute(const []),
        throwsArgumentError,
      );
    });

    test('returns the only candidate when given a one-element list', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
      );
      expect(identical(EcoRouteScoring.selectEcoRoute([c]), c), isTrue);
    });

    test('rejects candidates above the 15 % slowdown cap', () {
      const fastest = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 500,
        legSpeedsKmh: [40, 130],
      );
      // 20 % slower — must be rejected even though its eco score is great.
      const tooSlowFlat = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 72,
        elevationGainMeters: 10,
        legSpeedsKmh: [110, 115],
      );

      final picked =
          EcoRouteScoring.selectEcoRoute([fastest, tooSlowFlat]);
      expect(identical(picked, fastest), isTrue);
    });

    test('picks the lower-scoring candidate within the slowdown cap', () {
      // Both within 15 % of each other, eco wins on flat + steady.
      const steep = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
        elevationGainMeters: 500,
        legSpeedsKmh: [40, 130], // variance ~2025
      );
      const flat = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 65, // 8 % slower — under cap
        elevationGainMeters: 30,
        legSpeedsKmh: [110, 115], // variance ~6.25
      );
      final picked = EcoRouteScoring.selectEcoRoute([steep, flat]);
      expect(identical(picked, flat), isTrue);
    });
  });
}
