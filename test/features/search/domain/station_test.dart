import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  group('Station.fromJson', () {
    late Map<String, dynamic> listResponse;

    setUpAll(() {
      final file = File('test/fixtures/list_response.json');
      listResponse = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses a standard station with all fields', () {
      final stations = listResponse['stations'] as List;
      final station = Station.fromJson(
        Map<String, dynamic>.from(stations[0] as Map),
      );

      expect(station.id, '51d4b660-a095-1aa0-e100-80009459e03a');
      expect(station.name, 'Aral Tankstelle');
      expect(station.brand, 'ARAL');
      expect(station.street, 'Hauptstraße');
      expect(station.houseNumber, '42');
      expect(station.place, 'Berlin');
      expect(station.lat, 52.521);
      expect(station.lng, 13.438);
      expect(station.dist, 2.3);
      expect(station.diesel, 1.359);
      expect(station.e5, 1.459);
      expect(station.e10, 1.439);
      expect(station.isOpen, true);
    });

    test('converts postCode integer to zero-padded string', () {
      final stations = listResponse['stations'] as List;

      // Berlin: postCode 10115 → "10115"
      final berlin = Station.fromJson(
        Map<String, dynamic>.from(stations[0] as Map),
      );
      expect(berlin.postCode, '10115');

      // Dresden: postCode 1067 → "01067" (leading zero preserved)
      final dresden = Station.fromJson(
        Map<String, dynamic>.from(stations[1] as Map),
      );
      expect(dresden.postCode, '01067');
    });

    test('handles null price fields gracefully', () {
      final stations = listResponse['stations'] as List;
      final station = Station.fromJson(
        Map<String, dynamic>.from(stations[1] as Map),
      );

      expect(station.e5, isNull);
      expect(station.e10, 1.429);
      expect(station.diesel, 1.349);
    });

    test('handles all-null prices for closed station', () {
      final stations = listResponse['stations'] as List;
      final station = Station.fromJson(
        Map<String, dynamic>.from(stations[2] as Map),
      );

      expect(station.e5, isNull);
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
      expect(station.isOpen, false);
    });

    test('handles null houseNumber', () {
      final stations = listResponse['stations'] as List;
      final station = Station.fromJson(
        Map<String, dynamic>.from(stations[2] as Map),
      );

      expect(station.houseNumber, isNull);
    });

    test('handles price as boolean false from prices.php', () {
      // Simulate what prices.php returns for closed stations
      final json = {
        'id': 'test-id',
        'name': 'Test',
        'brand': 'Test',
        'street': 'Test St.',
        'postCode': 10115,
        'place': 'Berlin',
        'lat': 52.0,
        'lng': 13.0,
        'isOpen': false,
        'e5': false,
        'e10': false,
        'diesel': false,
      };

      final station = Station.fromJson(json);
      expect(station.e5, isNull);
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
    });
  });

  group('OpeningTime.fromJson', () {
    test('parses opening time correctly', () {
      final json = {
        'text': 'Mo-Fr',
        'start': '06:00:00',
        'end': '22:00:00',
      };

      final ot = OpeningTime.fromJson(json);
      expect(ot.text, 'Mo-Fr');
      expect(ot.start, '06:00:00');
      expect(ot.end, '22:00:00');
    });
  });
}
