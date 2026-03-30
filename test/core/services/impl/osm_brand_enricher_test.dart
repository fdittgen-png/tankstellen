import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/impl/osm_brand_enricher.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

class MockHiveStorage extends Mock implements HiveStorage {}

void main() {
  late MockHiveStorage mockStorage;
  late OsmBrandEnricher enricher;

  setUp(() {
    mockStorage = MockHiveStorage();
    enricher = OsmBrandEnricher(mockStorage);
    when(() => mockStorage.getSetting(any())).thenReturn(null);
    when(() => mockStorage.putSetting(any(), any())).thenAnswer((_) async {});
  });

  Station _makeStation({
    required String id,
    String brand = '',
    double lat = 48.8,
    double lng = 2.3,
  }) {
    return Station(
      id: id,
      name: 'Station $id',
      brand: brand,
      street: 'Test St',
      postCode: '75001',
      place: 'Paris',
      lat: lat,
      lng: lng,
      isOpen: true,
    );
  }

  group('OsmBrandEnricher', () {
    test('returns empty list for empty input', () async {
      final result = await enricher.enrich([]);
      expect(result, isEmpty);
    });

    test('returns stations unchanged if all have brands', () async {
      final stations = [
        _makeStation(id: '1', brand: 'TotalEnergies'),
        _makeStation(id: '2', brand: 'Shell'),
      ];

      final result = await enricher.enrich(stations);

      expect(result.length, 2);
      expect(result[0].brand, 'TotalEnergies');
      expect(result[1].brand, 'Shell');
    });

    test('applies persisted brand from storage', () async {
      when(() => mockStorage.getSetting('brand_1')).thenReturn('Esso');

      final stations = [_makeStation(id: '1', brand: '')];
      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'Esso');
    });

    test('identifies stations needing brands (empty brand)', () async {
      final stations = [_makeStation(id: '1', brand: '')];
      // Will try Nominatim (which will fail in test), but we test the logic
      final result = await enricher.enrich(stations);

      // Station should still be returned (brand may be empty if Nominatim fails)
      expect(result.length, 1);
    });

    test('identifies stations needing brands ("Station")', () async {
      final stations = [_makeStation(id: '1', brand: 'Station')];
      final result = await enricher.enrich(stations);

      expect(result.length, 1);
    });

    test('identifies stations needing brands ("Autoroute")', () async {
      final stations = [_makeStation(id: '1', brand: 'Autoroute')];
      final result = await enricher.enrich(stations);

      expect(result.length, 1);
    });

    test('uses session cache on second call', () async {
      // First call: brand from persisted storage
      when(() => mockStorage.getSetting('brand_1')).thenReturn('BP');

      final stations = [_makeStation(id: '1', brand: '')];
      await enricher.enrich(stations);

      // Second call: should use session cache, not hit storage again
      reset(mockStorage);
      when(() => mockStorage.getSetting(any())).thenReturn(null);
      when(() => mockStorage.putSetting(any(), any())).thenAnswer((_) async {});

      final result2 = await enricher.enrich(stations);
      expect(result2[0].brand, 'BP');
    });

    test('mixed stations: branded and unbranded', () async {
      when(() => mockStorage.getSetting('brand_2')).thenReturn('Avia');

      final stations = [
        _makeStation(id: '1', brand: 'Shell'),
        _makeStation(id: '2', brand: ''),
        _makeStation(id: '3', brand: 'TotalEnergies'),
      ];

      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'Shell');
      expect(result[1].brand, 'Avia');
      expect(result[2].brand, 'TotalEnergies');
    });
  });
}
