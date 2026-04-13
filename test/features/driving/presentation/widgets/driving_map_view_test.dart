import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_map_view.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

Station _station({
  required String id,
  double lat = 52.0,
  double lng = 13.0,
  double dist = 1.0,
  double? e10 = 1.799,
  double? diesel = 1.659,
}) {
  return Station(
    id: id,
    name: id,
    brand: 'BRAND',
    street: 'Street',
    houseNumber: '1',
    postCode: '10000',
    place: 'Place',
    lat: lat,
    lng: lng,
    dist: dist,
    e5: 1.859,
    e10: e10,
    diesel: diesel,
    isOpen: true,
  );
}

void main() {
  group('DrivingMapView.computeCenter', () {
    test('returns the geographic centroid of the given stations', () {
      final stations = [
        _station(id: 'a', lat: 50.0, lng: 10.0),
        _station(id: 'b', lat: 52.0, lng: 12.0),
      ];

      final center = DrivingMapView.computeCenter(stations);

      expect(center.latitude, closeTo(51.0, 1e-9));
      expect(center.longitude, closeTo(11.0, 1e-9));
    });

    test('handles a single station', () {
      final center = DrivingMapView.computeCenter([
        _station(id: 'a', lat: 48.137, lng: 11.575),
      ]);
      expect(center.latitude, closeTo(48.137, 1e-9));
      expect(center.longitude, closeTo(11.575, 1e-9));
    });
  });

  group('DrivingMapView.computePriceRange', () {
    test('returns (min, max) across stations that price the active fuel', () {
      final stations = [
        _station(id: 'a', e10: 1.799),
        _station(id: 'b', e10: 1.659),
        _station(id: 'c', e10: 1.749),
      ];

      final (min, max) = DrivingMapView.computePriceRange(
        stations,
        FuelType.e10,
      );

      expect(min, closeTo(1.659, 1e-9));
      expect(max, closeTo(1.799, 1e-9));
    });

    test('returns (0, 0) when no station has a price for the active fuel', () {
      final stations = [
        _station(id: 'a', e10: null, diesel: 1.6),
        _station(id: 'b', e10: null, diesel: 1.7),
      ];

      final (min, max) = DrivingMapView.computePriceRange(
        stations,
        FuelType.e10,
      );

      expect(min, 0);
      expect(max, 0);
    });

    test('ignores stations missing the active fuel price', () {
      final stations = [
        _station(id: 'a', e10: null),
        _station(id: 'b', e10: 1.50),
      ];

      final (min, max) = DrivingMapView.computePriceRange(
        stations,
        FuelType.e10,
      );

      expect(min, closeTo(1.50, 1e-9));
      expect(max, closeTo(1.50, 1e-9));
    });
  });
}
