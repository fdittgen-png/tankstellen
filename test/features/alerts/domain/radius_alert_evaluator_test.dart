import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_evaluator.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  const evaluator = RadiusAlertEvaluator();

  // Center of Castelnau-de-Guers (~home coordinates for the dev).
  // Distances below are calibrated against haversine from here.
  const double centerLat = 43.4527;
  const double centerLng = 3.4892;

  RadiusAlert makeAlert({
    String id = 'r1',
    String fuelType = 'diesel',
    double threshold = 1.60,
    double lat = centerLat,
    double lng = centerLng,
    double radiusKm = 10,
    bool enabled = true,
  }) {
    return RadiusAlert(
      id: id,
      fuelType: fuelType,
      threshold: threshold,
      centerLat: lat,
      centerLng: lng,
      radiusKm: radiusKm,
      label: 'Test',
      createdAt: DateTime(2026, 1, 1),
      enabled: enabled,
    );
  }

  StationPriceSample sample({
    String stationId = 's1',
    double lat = centerLat,
    double lng = centerLng,
    String fuelType = 'diesel',
    double price = 1.50,
  }) {
    return StationPriceSample(
      stationId: stationId,
      lat: lat,
      lng: lng,
      fuelType: fuelType,
      pricePerLiter: price,
    );
  }

  group('RadiusAlertEvaluator.triggered — single-condition tests', () {
    test('triggers when price is strictly below threshold and inside radius',
        () {
      final alert = makeAlert(threshold: 1.60);
      final samples = [sample(price: 1.45)];
      expect(evaluator.triggered(alert, samples), isTrue);
    });

    test('triggers when price equals threshold exactly (<= boundary)', () {
      final alert = makeAlert(threshold: 1.50);
      final samples = [sample(price: 1.50)];
      expect(evaluator.triggered(alert, samples), isTrue);
    });

    test('does NOT trigger when the only sample is above threshold', () {
      final alert = makeAlert(threshold: 1.40);
      final samples = [sample(price: 1.55)];
      expect(evaluator.triggered(alert, samples), isFalse);
    });

    test('does NOT trigger when the only sample is outside the radius', () {
      // ~18 km north of the centre (~0.16 deg lat)
      final alert = makeAlert(radiusKm: 5);
      final samples = [sample(lat: centerLat + 0.16, price: 1.40)];
      expect(evaluator.triggered(alert, samples), isFalse);
    });

    test('does NOT trigger when the fuel type of the sample differs', () {
      final alert = makeAlert(fuelType: 'diesel', threshold: 1.60);
      final samples = [sample(fuelType: 'e10', price: 1.40)];
      expect(evaluator.triggered(alert, samples), isFalse);
    });

    test('does NOT trigger when the alert is disabled, even with a match',
        () {
      final alert = makeAlert(enabled: false);
      final samples = [sample(price: 1.30)];
      expect(evaluator.triggered(alert, samples), isFalse);
    });
  });

  group('RadiusAlertEvaluator.triggered — combined conditions', () {
    test(
        'triggers when one mixed-fuel sample matches, others differ in fuel or distance',
        () {
      final alert = makeAlert(fuelType: 'diesel', threshold: 1.60, radiusKm: 5);
      final samples = [
        sample(fuelType: 'e10', price: 1.30), // wrong fuel
        sample(lat: centerLat + 0.16, price: 1.20), // right fuel, out of range
        sample(price: 1.55), // perfect match
      ];
      expect(evaluator.triggered(alert, samples), isTrue);
    });

    test('does NOT trigger when every sample fails at least one condition',
        () {
      final alert = makeAlert(fuelType: 'diesel', threshold: 1.50, radiusKm: 5);
      final samples = [
        sample(fuelType: 'e10', price: 1.30), // wrong fuel
        sample(price: 1.80), // too expensive
        sample(lat: centerLat + 0.5, price: 1.30), // out of range
      ];
      expect(evaluator.triggered(alert, samples), isFalse);
    });

    test('empty sample list never triggers, even for an enabled alert', () {
      final alert = makeAlert();
      expect(evaluator.triggered(alert, const []), isFalse);
    });
  });

  group('RadiusAlertEvaluator.matches', () {
    test('returns only the samples that satisfy every condition', () {
      final alert = makeAlert(fuelType: 'diesel', threshold: 1.60, radiusKm: 5);
      final samples = [
        sample(stationId: 'wrong-fuel', fuelType: 'e10', price: 1.30),
        sample(stationId: 'too-expensive', price: 1.75),
        sample(stationId: 'out-of-range', lat: centerLat + 0.5, price: 1.40),
        sample(stationId: 'match-1', price: 1.55),
        sample(stationId: 'match-2', price: 1.60),
      ];

      final matches = evaluator.matches(alert, samples).toList();
      expect(matches.map((s) => s.stationId), ['match-1', 'match-2']);
    });

    test('returns empty when the alert is disabled', () {
      final alert = makeAlert(enabled: false);
      final samples = [sample(price: 1.00), sample(stationId: 's2', price: 0.99)];
      expect(evaluator.matches(alert, samples), isEmpty);
    });
  });

  group('StationPriceSample.fromStation', () {
    test('emits one sample per priced fuel on a Station', () {
      const station = Station(
        id: 'multi',
        name: 'Multi',
        brand: 'Brand',
        street: 'Street',
        postCode: '34120',
        place: 'Castelnau',
        lat: centerLat,
        lng: centerLng,
        isOpen: true,
        diesel: 1.55,
        e10: 1.72,
        e5: 1.80,
      );

      final samples = StationPriceSample.fromStation(station);

      final fuels = samples.map((s) => s.fuelType).toSet();
      expect(fuels, containsAll(<String>['diesel', 'e10', 'e5']));
      expect(samples.length, 3);
      // Every sample inherits the station's coordinates and id.
      expect(samples.every((s) => s.stationId == 'multi'), isTrue);
      expect(samples.every((s) => s.lat == centerLat), isTrue);
    });

    test('skips fuels that have no price on the station', () {
      const station = Station(
        id: 'diesel-only',
        name: '',
        brand: '',
        street: '',
        postCode: '34120',
        place: '',
        lat: centerLat,
        lng: centerLng,
        isOpen: true,
        diesel: 1.48,
      );

      final samples = StationPriceSample.fromStation(station);
      expect(samples, hasLength(1));
      expect(samples.single.fuelType, FuelType.diesel.apiValue);
      expect(samples.single.pricePerLiter, 1.48);
    });
  });
}
