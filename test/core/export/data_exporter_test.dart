import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/export/data_exporter.dart';

void main() {
  group('DataExporter JSON', () {
    test('exports an empty but well-formed document when storage is empty', () {
      final exporter = DataExporter(
        _FakeStorage(),
        appVersion: '9.9.9',
        now: () => DateTime.utc(2026, 4, 8, 12, 0, 0),
      );
      final json = exporter.exportToJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['exportedAt'], '2026-04-08T12:00:00.000Z');
      expect(decoded['appVersion'], '9.9.9');
      expect(decoded['favorites'], isEmpty);
      expect(decoded['favoriteStationData'], isEmpty);
      expect(decoded['ignoredStations'], isEmpty);
      expect(decoded['ratings'], isEmpty);
      expect(decoded['profiles'], isEmpty);
      expect(decoded['alerts'], isEmpty);
      expect(decoded['fillUps'], isEmpty);
      expect(decoded['itineraries'], isEmpty);
      expect(decoded['priceHistory'], isEmpty);
    });

    test('never includes API keys in the output', () {
      final storage = _FakeStorage()
        ..apiKey = 'SECRET_KEY_123'
        ..evApiKey = 'EV_SECRET_456';
      final exporter = DataExporter(storage);
      final json = exporter.exportToJson();

      expect(json.contains('SECRET_KEY_123'), isFalse);
      expect(json.contains('EV_SECRET_456'), isFalse);
      expect(json.contains('apiKey'), isFalse);
    });

    test('serialises favorites, ratings, alerts, fill-ups, and price history', () {
      final storage = _FakeStorage()
        ..favoriteIds = ['s1', 's2']
        ..favoriteData = {
          's1': {'name': 'Alpha', 'brand': 'Aral', 'lat': 48.1, 'lng': 11.5},
        }
        ..ratings = {'s1': 4}
        ..alerts = [
          {'id': 'a1', 'stationId': 's1', 'fuelType': 'e5', 'thresholdPrice': 1.699},
        ]
        ..priceHistoryKeys = ['s1']
        ..priceRecords = {
          's1': [
            {'timestamp': '2026-04-01T08:00:00Z', 'fuelType': 'e5', 'price': 1.72},
          ],
        }
        ..settings = {
          'fillUps': [
            {
              'id': 'f1',
              'stationId': 's1',
              'timestamp': '2026-04-02T10:00:00Z',
              'fuelType': 'e5',
              'liters': 42.5,
              'pricePerLiter': 1.70,
              'totalCost': 72.25,
            },
          ],
        };

      final json = jsonDecode(DataExporter(storage).exportToJson())
          as Map<String, dynamic>;
      expect(json['favorites'], ['s1', 's2']);
      expect((json['favoriteStationData'] as Map)['s1']['name'], 'Alpha');
      expect((json['ratings'] as Map)['s1'], 4);
      expect((json['alerts'] as List).length, 1);
      expect((json['fillUps'] as List).length, 1);
      expect((json['fillUps'] as List).first['liters'], 42.5);
      expect((json['priceHistory'] as Map)['s1'], isA<List>());
    });
  });

  group('DataExporter CSV', () {
    test('RFC 4180 escaping: quotes, commas, newlines, carriage returns', () {
      final storage = _FakeStorage()
        ..favoriteIds = ['s1']
        ..favoriteData = {
          's1': {
            'name': 'Shell, "Downtown"',
            'brand': 'line1\nline2',
            'street': 'a\rb',
            'place': 'plain',
            'lat': 1.0,
            'lng': 2.0,
          },
        };
      final csv = DataExporter(storage).exportToCsv(ExportCategory.favorites);
      final lines = csv.split('\r\n');

      // Header + data + trailing empty from final CRLF
      expect(lines.first,
          'station_id,name,brand,street,place,postcode,lat,lng');
      // Quoted because of comma and quote
      expect(lines[1].contains('"Shell, ""Downtown"""'), isTrue);
      // Quoted because of newline
      expect(lines[1].contains('"line1\nline2"'), isTrue);
      // Quoted because of CR
      expect(lines[1].contains('"a\rb"'), isTrue);
      // Plain field remains unquoted
      expect(lines[1].contains(',plain,'), isTrue);
    });

    test('empty category returns header-only CSV', () {
      final csv = DataExporter(_FakeStorage())
          .exportToCsv(ExportCategory.favorites);
      // One header row + trailing CRLF -> split yields 2 entries
      expect(csv.endsWith('\r\n'), isTrue);
      final lines = csv.split('\r\n');
      expect(lines.length, 2);
      expect(lines.first,
          'station_id,name,brand,street,place,postcode,lat,lng');
      expect(lines.last, '');
    });

    test('null cells render as empty strings', () {
      final storage = _FakeStorage()
        ..favoriteIds = ['s1']
        ..favoriteData = {'s1': <String, dynamic>{}};
      final csv = DataExporter(storage).exportToCsv(ExportCategory.favorites);
      final dataLine = csv.split('\r\n')[1];
      // 8 columns => 7 commas, all empty except the id
      expect(dataLine, 's1,,,,,,,');
    });

    test('price history flattens fuelType maps into rows', () {
      final storage = _FakeStorage()
        ..priceHistoryKeys = ['s1']
        ..priceRecords = {
          's1': [
            {
              'timestamp': '2026-04-01T08:00:00Z',
              'fuelType': {'e5': 1.72, 'e10': 1.70, 'diesel': 1.60},
            },
          ],
        };
      final csv =
          DataExporter(storage).exportToCsv(ExportCategory.priceHistory);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();
      expect(lines.first, 'station_id,timestamp,fuel_type,price');
      expect(lines.length, 4); // header + 3 fuel rows
      expect(lines.any((l) => l.contains('e5,1.72')), isTrue);
      expect(lines.any((l) => l.contains('diesel,1.6')), isTrue);
    });

    test('large dataset does not drop rows', () {
      final records = List.generate(
        5000,
        (i) => {
          'timestamp': '2026-04-01T08:00:00Z',
          'fuelType': 'e5',
          'price': 1.5 + (i % 100) / 1000,
        },
      );
      final storage = _FakeStorage()
        ..priceHistoryKeys = ['s1']
        ..priceRecords = {'s1': records};
      final csv =
          DataExporter(storage).exportToCsv(ExportCategory.priceHistory);
      final dataLines =
          csv.split('\r\n').where((l) => l.isNotEmpty).toList();
      expect(dataLines.length, 5001); // header + 5000 rows
    });

    test('exportAllAsCsv returns one entry per category', () {
      final parts = DataExporter(_FakeStorage()).exportAllAsCsv();
      expect(parts.keys.toSet(),
          ExportCategory.values.map((c) => c.name).toSet());
      for (final csv in parts.values) {
        expect(csv.endsWith('\r\n'), isTrue);
      }
    });

    test('ratings CSV contains station_id,rating rows', () {
      final storage = _FakeStorage()..ratings = {'s1': 5, 's2': 3};
      final csv = DataExporter(storage).exportToCsv(ExportCategory.ratings);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();
      expect(lines.first, 'station_id,rating');
      expect(lines.contains('s1,5'), isTrue);
      expect(lines.contains('s2,3'), isTrue);
    });

    test('alerts CSV maps expected columns', () {
      final storage = _FakeStorage()
        ..alerts = [
          {
            'id': 'a1',
            'stationId': 's1',
            'fuelType': 'e5',
            'thresholdPrice': 1.699,
            'direction': 'below',
            'enabled': true,
            'createdAt': '2026-04-01T00:00:00Z',
          },
        ];
      final csv = DataExporter(storage).exportToCsv(ExportCategory.alerts);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();
      expect(lines.first,
          'id,station_id,fuel_type,threshold_price,direction,enabled,created_at');
      expect(
        lines[1],
        'a1,s1,e5,1.699,below,true,2026-04-01T00:00:00Z',
      );
    });
  });
}

/// Hand-rolled fake that only implements the methods the exporter touches.
class _FakeStorage extends Fake implements StorageRepository {
  List<String> favoriteIds = [];
  Map<String, dynamic> favoriteData = {};
  List<String> ignoredIds = [];
  Map<String, int> ratings = {};
  List<Map<String, dynamic>> profiles = [];
  List<Map<String, dynamic>> alerts = [];
  List<Map<String, dynamic>> itineraries = [];
  List<String> priceHistoryKeys = [];
  Map<String, List<Map<String, dynamic>>> priceRecords = {};
  Map<String, dynamic> settings = {};
  String? apiKey;
  String? evApiKey;

  @override
  List<String> getFavoriteIds() => favoriteIds;
  @override
  Map<String, dynamic> getAllFavoriteStationData() => favoriteData;
  @override
  List<String> getIgnoredIds() => ignoredIds;
  @override
  Map<String, int> getRatings() => ratings;
  @override
  List<Map<String, dynamic>> getAllProfiles() => profiles;
  @override
  List<Map<String, dynamic>> getAlerts() => alerts;
  @override
  List<Map<String, dynamic>> getItineraries() => itineraries;
  @override
  List<String> getPriceHistoryKeys() => priceHistoryKeys;
  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) =>
      priceRecords[stationId] ?? const [];
  @override
  dynamic getSetting(String key) => settings[key];
  @override
  String? getApiKey() => apiKey;
  @override
  String? getEvApiKey() => evApiKey;
}
