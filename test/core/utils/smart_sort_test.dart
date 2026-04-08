import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_utils.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  group('compareByOpen24h', () {
    const station24h = Station(
      id: 's-24h',
      name: '24h Station',
      brand: 'JET',
      street: 'Hauptstr.',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.40,
      dist: 3.0,
      isOpen: true,
      is24h: true,
    );

    const stationNormal = Station(
      id: 's-normal',
      name: 'Normal Station',
      brand: 'ARAL',
      street: 'Nebenstr.',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.53,
      lng: 13.41,
      dist: 1.0,
      isOpen: true,
      is24h: false,
    );

    const stationNormal2 = Station(
      id: 's-normal-2',
      name: 'Normal Station 2',
      brand: 'SHELL',
      street: 'Dritte Str.',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.54,
      lng: 13.42,
      dist: 5.0,
      isOpen: true,
      is24h: false,
    );

    test('24h stations sort before non-24h stations', () {
      // 24h station is farther but should come first
      expect(compareByOpen24h(station24h, stationNormal), lessThan(0));
      expect(compareByOpen24h(stationNormal, station24h), greaterThan(0));
    });

    test('stations with same 24h status sort by distance', () {
      expect(
        compareByOpen24h(stationNormal, stationNormal2),
        lessThan(0), // dist 1.0 < 5.0
      );
    });

    test('two 24h stations sort by distance', () {
      const another24h = Station(
        id: 's-24h-2',
        name: 'Another 24h',
        brand: 'BP',
        street: 'Vierte Str.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.55,
        lng: 13.43,
        dist: 1.0,
        isOpen: true,
        is24h: true,
      );
      // another24h (dist 1.0) before station24h (dist 3.0)
      expect(compareByOpen24h(another24h, station24h), lessThan(0));
    });

    test('sorting a list puts 24h first then by distance', () {
      final stations = [stationNormal2, stationNormal, station24h];
      stations.sort((a, b) => compareByOpen24h(a, b));

      expect(stations[0].id, 's-24h'); // 24h first
      expect(stations[1].id, 's-normal'); // dist 1.0
      expect(stations[2].id, 's-normal-2'); // dist 5.0
    });
  });

  group('compareByRating', () {
    const stationA = Station(
      id: 'rated-5',
      name: 'Great Station',
      brand: 'JET',
      street: 'Str. A',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.40,
      dist: 5.0,
      isOpen: true,
    );

    const stationB = Station(
      id: 'rated-3',
      name: 'OK Station',
      brand: 'ARAL',
      street: 'Str. B',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.53,
      lng: 13.41,
      dist: 2.0,
      isOpen: true,
    );

    const stationC = Station(
      id: 'unrated',
      name: 'Unrated Station',
      brand: 'SHELL',
      street: 'Str. C',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.54,
      lng: 13.42,
      dist: 1.0,
      isOpen: true,
    );

    final ratings = <String, int>{
      'rated-5': 5,
      'rated-3': 3,
    };

    test('higher rated station sorts first', () {
      expect(compareByRating(stationA, stationB, ratings), lessThan(0));
      expect(compareByRating(stationB, stationA, ratings), greaterThan(0));
    });

    test('rated stations sort before unrated', () {
      expect(compareByRating(stationB, stationC, ratings), lessThan(0));
    });

    test('unrated stations sort by distance', () {
      const unrated2 = Station(
        id: 'unrated-2',
        name: 'Unrated 2',
        brand: 'BP',
        street: 'Str. D',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.55,
        lng: 13.43,
        dist: 3.0,
        isOpen: true,
      );
      // Both unrated (rating 0), so tie breaks by distance
      expect(compareByRating(stationC, unrated2, ratings), lessThan(0));
    });

    test('sorting a list orders by rating descending then distance', () {
      final stations = [stationC, stationB, stationA];
      stations.sort((a, b) => compareByRating(a, b, ratings));

      expect(stations[0].id, 'rated-5');
      expect(stations[1].id, 'rated-3');
      expect(stations[2].id, 'unrated');
    });

    test('empty ratings map sorts all by distance', () {
      final empty = <String, int>{};
      final stations = [stationA, stationC, stationB];
      stations.sort((a, b) => compareByRating(a, b, empty));

      expect(stations[0].id, 'unrated'); // dist 1.0
      expect(stations[1].id, 'rated-3'); // dist 2.0
      expect(stations[2].id, 'rated-5'); // dist 5.0
    });
  });

  group('compareByPriceDistance', () {
    const stationCheapNear = Station(
      id: 'cheap-near',
      name: 'Cheap Near',
      brand: 'JET',
      street: 'Str. A',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.40,
      dist: 1.0,
      e10: 1.50,
      isOpen: true,
    );

    const stationCheapFar = Station(
      id: 'cheap-far',
      name: 'Cheap Far',
      brand: 'ARAL',
      street: 'Str. B',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.53,
      lng: 13.41,
      dist: 10.0,
      e10: 1.40,
      isOpen: true,
    );

    const stationExpensiveNear = Station(
      id: 'expensive-near',
      name: 'Expensive Near',
      brand: 'SHELL',
      street: 'Str. C',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.54,
      lng: 13.42,
      dist: 0.5,
      e10: 1.80,
      isOpen: true,
    );

    const stationNoPrice = Station(
      id: 'no-price',
      name: 'No Price',
      brand: 'BP',
      street: 'Str. D',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.55,
      lng: 13.43,
      dist: 0.3,
      isOpen: true,
    );

    const fuelType = FuelType.e10;

    test('cheaper-far has better ratio than expensive-near', () {
      // cheap-far: 1.40 / 10.0 = 0.14
      // expensive-near: 1.80 / 0.5 = 3.60
      expect(
        compareByPriceDistance(stationCheapFar, stationExpensiveNear, fuelType),
        lessThan(0),
      );
    });

    test('nearby cheap station has lower ratio', () {
      // cheap-near: 1.50 / 1.0 = 1.50
      // expensive-near: 1.80 / 0.5 = 3.60
      expect(
        compareByPriceDistance(stationCheapNear, stationExpensiveNear, fuelType),
        lessThan(0),
      );
    });

    test('stations without price sort last', () {
      expect(
        compareByPriceDistance(stationNoPrice, stationCheapNear, fuelType),
        greaterThan(0),
      );
    });

    test('two stations without price compare as equal', () {
      const noPrice2 = Station(
        id: 'no-price-2',
        name: 'No Price 2',
        brand: 'TOTAL',
        street: 'Str. E',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.56,
        lng: 13.44,
        dist: 2.0,
        isOpen: true,
      );
      expect(
        compareByPriceDistance(stationNoPrice, noPrice2, fuelType),
        equals(0),
      );
    });

    test('station at distance 0 uses clamped minimum of 0.1', () {
      const atZero = Station(
        id: 'at-zero',
        name: 'At Zero',
        brand: 'JET',
        street: 'Here',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        dist: 0.0,
        e10: 1.50,
        isOpen: true,
      );
      // Should not throw / produce infinity; ratio = 1.50 / 0.1 = 15.0
      expect(
        compareByPriceDistance(atZero, stationCheapFar, fuelType),
        greaterThan(0), // 15.0 > 0.14
      );
    });

    test('sorting a list orders by best price/distance ratio', () {
      final stations = [
        stationExpensiveNear,
        stationNoPrice,
        stationCheapFar,
        stationCheapNear,
      ];
      stations.sort((a, b) => compareByPriceDistance(a, b, fuelType));

      expect(stations[0].id, 'cheap-far'); // 0.14
      expect(stations[1].id, 'cheap-near'); // 1.50
      expect(stations[2].id, 'expensive-near'); // 3.60
      expect(stations[3].id, 'no-price'); // sentinel
    });
  });
}
