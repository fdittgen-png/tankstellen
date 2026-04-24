import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/data/models/price_snapshot.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('PriceSnapshot', () {
    final baseTs = DateTime.utc(2026, 4, 1, 12, 0, 0);

    PriceSnapshot makeSnapshot({
      String stationId = 'st-1',
      String fuelType = 'e10',
      double price = 1.859,
      double lat = 43.123,
      double lng = 3.456,
      DateTime? timestamp,
    }) {
      return PriceSnapshot(
        stationId: stationId,
        fuelType: fuelType,
        price: price,
        timestamp: timestamp ?? baseTs,
        lat: lat,
        lng: lng,
      );
    }

    test('construction populates every field', () {
      final snap = makeSnapshot();
      expect(snap.stationId, 'st-1');
      expect(snap.fuelType, 'e10');
      expect(snap.price, 1.859);
      expect(snap.timestamp, baseTs);
      expect(snap.lat, 43.123);
      expect(snap.lng, 3.456);
    });

    test('equality and hashCode are value-based', () {
      final a = makeSnapshot();
      final b = makeSnapshot();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('instances with different fields are not equal', () {
      final a = makeSnapshot();
      final b = makeSnapshot(price: 1.999);
      expect(a, isNot(equals(b)));
    });

    test('copyWith mutates only the named field', () {
      final a = makeSnapshot();
      final b = a.copyWith(price: 2.099);
      expect(b.price, 2.099);
      expect(b.stationId, a.stationId);
      expect(b.fuelType, a.fuelType);
      expect(b.timestamp, a.timestamp);
      expect(b.lat, a.lat);
      expect(b.lng, a.lng);
    });

    test('toJson/fromJson roundtrip preserves every field', () {
      final snap = makeSnapshot();
      final json = snap.toJson();
      expect(json['stationId'], 'st-1');
      expect(json['fuelType'], 'e10');
      expect(json['price'], 1.859);
      expect(json['lat'], 43.123);
      expect(json['lng'], 3.456);
      // timestamp is serialized as ISO-8601 string by json_serializable.
      expect(json['timestamp'], isA<String>());

      final restored = PriceSnapshot.fromJson(json);
      expect(restored, equals(snap));
    });

    group('forFuel', () {
      test('maps FuelType.e10 to apiValue "e10"', () {
        final snap = PriceSnapshot.forFuel(
          stationId: 'st-2',
          fuelType: FuelType.e10,
          price: 1.799,
          timestamp: baseTs,
          lat: 48.0,
          lng: 2.0,
        );
        expect(snap.fuelType, 'e10');
        expect(snap.fuelType, FuelType.e10.apiValue);
        expect(snap.stationId, 'st-2');
        expect(snap.price, 1.799);
      });

      test('maps FuelType.diesel to apiValue "diesel"', () {
        final snap = PriceSnapshot.forFuel(
          stationId: 'st-3',
          fuelType: FuelType.diesel,
          price: 1.699,
          timestamp: baseTs,
          lat: 48.0,
          lng: 2.0,
        );
        expect(snap.fuelType, 'diesel');
        expect(snap.fuelType, FuelType.diesel.apiValue);
      });

      test('maps FuelType.dieselPremium to apiValue "diesel_premium"', () {
        final snap = PriceSnapshot.forFuel(
          stationId: 'st-4',
          fuelType: FuelType.dieselPremium,
          price: 1.999,
          timestamp: baseTs,
          lat: 48.0,
          lng: 2.0,
        );
        expect(snap.fuelType, 'diesel_premium');
      });
    });
  });
}
