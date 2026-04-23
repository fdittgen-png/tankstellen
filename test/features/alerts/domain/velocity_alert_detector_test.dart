import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/data/models/price_snapshot.dart';
import 'package:tankstellen/features/alerts/domain/entities/velocity_alert_config.dart';
import 'package:tankstellen/features/alerts/domain/velocity_alert_detector.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Snapshot-based velocity detector (#579). Pure function. Input:
/// current nearby station observations + previous [PriceSnapshot]s
/// older than the lookback. Output: a [VelocityAlertEvent] when
/// enough nearby stations dropped by ≥ [minDropCents] on the
/// configured fuel type.
void main() {
  // User is in the middle of three stations roughly 2 km apart.
  const userLat = 43.5;
  const userLng = 3.5;
  final now = DateTime.utc(2026, 4, 22, 12);
  final hourPlusAgo =
      now.subtract(const Duration(hours: 1, minutes: 5));

  // Handy nearby coords — same lat as the user, varied lng so each
  // station lies a few kilometres away (≈8 km per 0.1°).
  const nearbyStations = <String, List<double>>{
    's1': [userLat, 3.52],
    's2': [userLat, 3.48],
    's3': [userLat, 3.54],
  };

  PriceSnapshot previousSnap({
    required String stationId,
    required double price,
    String fuel = 'e10',
    DateTime? at,
  }) {
    final coords = nearbyStations[stationId] ?? [userLat, userLng];
    return PriceSnapshot(
      stationId: stationId,
      fuelType: fuel,
      price: price,
      timestamp: at ?? hourPlusAgo,
      lat: coords[0],
      lng: coords[1],
    );
  }

  VelocityStationObservation observation({
    required String stationId,
    required double price,
    List<double>? coords,
  }) {
    final c = coords ?? nearbyStations[stationId] ?? [userLat, userLng];
    return VelocityStationObservation(
      stationId: stationId,
      price: price,
      lat: c[0],
      lng: c[1],
    );
  }

  group('VelocityAlertDetector (#579)', () {
    test('fires when 3 stations drop 4 ct each within radius', () {
      const config = VelocityAlertConfig(fuelType: FuelType.e10);
      final previous = [
        previousSnap(stationId: 's1', price: 1.900),
        previousSnap(stationId: 's2', price: 1.900),
        previousSnap(stationId: 's3', price: 1.900),
      ];
      final observations = [
        observation(stationId: 's1', price: 1.860), // -4 ct
        observation(stationId: 's2', price: 1.860), // -4 ct
        observation(stationId: 's3', price: 1.860), // -4 ct
      ];

      final event = VelocityAlertDetector.detect(
        config: config,
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );

      expect(event, isNotNull);
      expect(event!.stationCount, 3);
      expect(event.maxDropCents, closeTo(4, 0.01));
      expect(event.fuelType, FuelType.e10);
      expect(event.affectedStationIds, containsAll(['s1', 's2', 's3']));
    });

    test('returns null when fewer than minStations qualify', () {
      // Default minStations is 2 → only 1 station drops → null.
      const config = VelocityAlertConfig(fuelType: FuelType.e10);
      final previous = [
        previousSnap(stationId: 's1', price: 1.900),
        previousSnap(stationId: 's2', price: 1.850),
        previousSnap(stationId: 's3', price: 1.850),
      ];
      final observations = [
        observation(stationId: 's1', price: 1.850), // -5 ct ✓
        observation(stationId: 's2', price: 1.850), // 0 ✗
        observation(stationId: 's3', price: 1.850), // 0 ✗
      ];

      final event = VelocityAlertDetector.detect(
        config: config,
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );

      expect(event, isNull);
    });

    test('mixed drops count only those above the threshold', () {
      const config = VelocityAlertConfig(fuelType: FuelType.e10);
      final previous = [
        previousSnap(stationId: 's1', price: 1.900),
        previousSnap(stationId: 's2', price: 1.900),
        previousSnap(stationId: 's3', price: 1.900),
      ];
      final observations = [
        observation(stationId: 's1', price: 1.860), // -4 ct ✓
        observation(stationId: 's2', price: 1.860), // -4 ct ✓
        observation(stationId: 's3', price: 1.890), // -1 ct (below min=3)
      ];

      final event = VelocityAlertDetector.detect(
        config: config,
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );

      expect(event, isNotNull);
      expect(event!.stationCount, 2);
      expect(event.maxDropCents, closeTo(4, 0.01));
      expect(event.affectedStationIds, containsAll(['s1', 's2']));
      expect(event.affectedStationIds, isNot(contains('s3')));
    });

    test('stations outside radiusKm are excluded', () {
      // Tight 2 km radius — s1 is ≈1.6 km away, s_far ≈111 km away
      // (+1° latitude). If the filter weren't applied both drops
      // would qualify and an event would fire.
      const config =
          VelocityAlertConfig(fuelType: FuelType.e10, radiusKm: 2);
      final farCoords = [userLat + 1, userLng];
      final previous = [
        previousSnap(stationId: 's1', price: 1.900),
        PriceSnapshot(
          stationId: 's_far',
          fuelType: 'e10',
          price: 1.900,
          timestamp: hourPlusAgo,
          lat: farCoords[0],
          lng: farCoords[1],
        ),
      ];
      final observations = [
        observation(stationId: 's1', price: 1.860), // -4 ct ✓
        observation(
          stationId: 's_far',
          price: 1.860,
          coords: farCoords,
        ), // -4 ct, but filtered out
      ];

      final event = VelocityAlertDetector.detect(
        config: config,
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );
      // Only s1 qualifies after the radius filter → below
      // minStations=2 → null.
      expect(event, isNull);

      // Sanity-check: widen the radius → both qualify → event fires.
      final wide = VelocityAlertDetector.detect(
        config: const VelocityAlertConfig(
            fuelType: FuelType.e10, radiusKm: 200),
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );
      expect(wide, isNotNull);
      expect(wide!.stationCount, 2);
    });

    test('stations with no previous snapshot are excluded', () {
      const config = VelocityAlertConfig(fuelType: FuelType.e10);
      final previous = [
        previousSnap(stationId: 's1', price: 1.900),
        // No previous snapshot for s2 — first time we see it.
      ];
      final observations = [
        observation(stationId: 's1', price: 1.860), // -4 ct ✓
        observation(stationId: 's2', price: 1.860), // no baseline → skip
      ];

      final event = VelocityAlertDetector.detect(
        config: config,
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );

      // Only s1 qualifies → below minStations=2 → null.
      expect(event, isNull);
    });

    test('only the configured fuelType participates in drops', () {
      const config = VelocityAlertConfig(fuelType: FuelType.e10);
      final previous = [
        previousSnap(stationId: 's1', price: 1.900, fuel: 'e10'),
        previousSnap(stationId: 's2', price: 1.900, fuel: 'diesel'),
        previousSnap(stationId: 's3', price: 1.900, fuel: 'diesel'),
      ];
      final observations = [
        observation(stationId: 's1', price: 1.860), // e10 -4 ct ✓
        observation(stationId: 's2', price: 1.860),
        observation(stationId: 's3', price: 1.860),
        // Detector only compares against e10 baselines, so s2/s3 have
        // no baseline and drop out. Result: only s1 qualifies.
      ];

      final event = VelocityAlertDetector.detect(
        config: config,
        observations: observations,
        previousSnapshots: previous,
        now: now,
        userLat: userLat,
        userLng: userLng,
      );

      expect(event, isNull);
    });
  });
}
