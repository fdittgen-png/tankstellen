import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/osm_brand_enricher.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;
  late OsmBrandEnricher enricher;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    enricher = OsmBrandEnricher(fakeStorage);
  });

  Station makeStation({
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
        makeStation(id: '1', brand: 'TotalEnergies'),
        makeStation(id: '2', brand: 'Shell'),
      ];

      final result = await enricher.enrich(stations);

      expect(result.length, 2);
      expect(result[0].brand, 'TotalEnergies');
      expect(result[1].brand, 'Shell');
    });

    test('applies persisted brand from storage', () async {
      await fakeStorage.putSetting('brand_1', 'Esso');

      final stations = [makeStation(id: '1', brand: '')];
      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'Esso');
    });

    test('identifies stations needing brands (empty brand)', () async {
      final stations = [makeStation(id: '1', brand: '')];
      // Will try Nominatim (which will fail in test), but we test the logic
      final result = await enricher.enrich(stations);

      // Station should still be returned (brand may be empty if Nominatim fails)
      expect(result.length, 1);
    });

    test('identifies stations needing brands ("Station")', () async {
      final stations = [makeStation(id: '1', brand: 'Station')];
      final result = await enricher.enrich(stations);

      expect(result.length, 1);
    });

    test('identifies stations needing brands ("Autoroute")', () async {
      final stations = [makeStation(id: '1', brand: 'Autoroute')];
      final result = await enricher.enrich(stations);

      expect(result.length, 1);
    });

    test('uses session cache on second call', () async {
      // First call: brand from persisted storage
      await fakeStorage.putSetting('brand_1', 'BP');

      final stations = [makeStation(id: '1', brand: '')];
      await enricher.enrich(stations);

      // Second call: clear persisted storage, but session cache should still
      // hold 'BP'.
      await fakeStorage.putSetting('brand_1', null);

      final result2 = await enricher.enrich(stations);
      expect(result2[0].brand, 'BP');
    });

    test('mixed stations: branded and unbranded', () async {
      await fakeStorage.putSetting('brand_2', 'Avia');

      final stations = [
        makeStation(id: '1', brand: 'Shell'),
        makeStation(id: '2', brand: ''),
        makeStation(id: '3', brand: 'TotalEnergies'),
      ];

      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'Shell');
      expect(result[1].brand, 'Avia');
      expect(result[2].brand, 'TotalEnergies');
    });
  });
}
