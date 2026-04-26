import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/eco_route_candidate.dart';

/// Direct tests for the helpers extracted out of
/// `eco_route_search_strategy.dart`. The integration-level
/// behaviour is covered by the existing
/// `eco_route_search_strategy_test.dart`; here we pin the pure
/// mechanics so a refactor of one helper can't silently break
/// `toRouteInfo` downstream.
void main() {
  group('sampleAlongPolyline', () {
    test('returns empty list for an empty polyline', () {
      expect(sampleAlongPolyline(const <LatLng>[], 15.0), isEmpty);
    });

    test('returns a single-point polyline as itself', () {
      const input = <LatLng>[LatLng(48.0, 2.0)];
      final out = sampleAlongPolyline(input, 15.0);
      expect(out, equals(input));
    });

    test('always includes both first and last points', () {
      const input = [
        LatLng(48.0, 2.0),
        LatLng(48.001, 2.001), // ~140m apart — well below 15km interval
        LatLng(48.002, 2.002),
      ];
      final out = sampleAlongPolyline(input, 15.0);
      expect(out.first, equals(input.first));
      expect(out.last, equals(input.last));
    });

    test('emits intermediate samples roughly every intervalKm', () {
      // ~1° latitude ≈ 111 km. Step from 48° to 49° in 4 hops gives
      // ~28 km between hops — at 15 km interval, every hop should
      // trigger a sample.
      const input = [
        LatLng(48.00, 2.0),
        LatLng(48.25, 2.0),
        LatLng(48.50, 2.0),
        LatLng(48.75, 2.0),
        LatLng(49.00, 2.0),
      ];
      final out = sampleAlongPolyline(input, 15.0);
      // First + 3 intermediate hops cross the threshold + last.
      // Intermediate hops are added as soon as accumulated >= 15 km.
      expect(out.length, greaterThanOrEqualTo(4));
      expect(out.first, equals(input.first));
      expect(out.last, equals(input.last));
    });

    test('does not duplicate the last point when it matches a sample', () {
      // Two-point polyline 28 km apart — the threshold triggers on
      // the second point, which is already the last. The function
      // must NOT add it twice.
      const input = [
        LatLng(48.0, 2.0),
        LatLng(48.25, 2.0),
      ];
      final out = sampleAlongPolyline(input, 15.0);
      expect(out.length, 2);
      expect(out.first, equals(input.first));
      expect(out.last, equals(input.last));
    });
  });

  group('EcoRouteCandidate', () {
    test('default legSpeedsKmh is empty + elevation is null', () {
      const c = EcoRouteCandidate(
        geometry: <LatLng>[],
        distanceKm: 100,
        durationMinutes: 60,
      );
      expect(c.legSpeedsKmh, isEmpty);
      expect(c.elevationGainMeters, isNull);
    });

    test('toRouteInfo carries distance/duration/geometry through', () {
      const c = EcoRouteCandidate(
        geometry: [LatLng(48.0, 2.0), LatLng(48.5, 2.5)],
        distanceKm: 60,
        durationMinutes: 50,
        elevationGainMeters: 120,
      );
      final info = c.toRouteInfo();
      expect(info.distanceKm, 60);
      expect(info.durationMinutes, 50);
      expect(info.geometry.length, 2);
      // sample points always include first + last, even on a 2-point line.
      expect(info.samplePoints.first, equals(c.geometry.first));
      expect(info.samplePoints.last, equals(c.geometry.last));
    });
  });
}
