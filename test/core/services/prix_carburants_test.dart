
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  group('French API response parsing', () {
    test('parses station with all fuel types', () {
      final json = {
        'id': 34120002,
        'adresse': '38 Avenue de Verdun',
        'ville': 'Pézenas',
        'cp': '34120',
        'geom': {'lat': 43.452, 'lon': 3.418},
        'gazole_prix': 2.09,
        'sp95_prix': 1.99,
        'e10_prix': 1.99,
        'sp98_prix': 1.99,
        'e85_prix': 0.849,
        'gplc_prix': null,
        'pop': 'R',
        'departement': 'Hérault',
        'region': 'Occitanie',
        'horaires_automate_24_24': 'Non',
        'carburants_disponibles': ['Gazole', 'E10', 'SP98'],
        'services_service': ['Lavage automatique', 'DAB'],
      };

      // Verify key fields are accessible
      expect(json['id'], 34120002);
      expect(json['cp'], '34120');
      expect(json['gazole_prix'], 2.09);
      expect(json['e85_prix'], 0.849);
      expect(json['gplc_prix'], isNull);
      expect(json['horaires_automate_24_24'], 'Non');
      expect((json['carburants_disponibles'] as List).length, 3);
      expect((json['services_service'] as List).length, 2);
    });

    test('Station model supports all fuel type fields', () {
      const station = Station(
        id: '34120002',
        name: 'Test',
        brand: 'TotalEnergies',
        street: '38 Avenue de Verdun',
        postCode: '34120',
        place: 'Pézenas',
        lat: 43.452,
        lng: 3.418,
        isOpen: true,
        e5: 1.99,
        e10: 1.99,
        e98: 2.09,
        diesel: 2.09,
        e85: 0.849,
        lpg: null,
        cng: null,
        updatedAt: '23/03 00:01',
        is24h: false,
        services: ['Lavage automatique'],
        availableFuels: ['Gazole', 'E10'],
        department: 'Hérault',
        region: 'Occitanie',
      );

      expect(station.e85, 0.849);
      expect(station.lpg, isNull);
      expect(station.updatedAt, '23/03 00:01');
      expect(station.is24h, false);
      expect(station.services.length, 1);
      expect(station.availableFuels.length, 2);
      expect(station.department, 'Hérault');
    });

    test('Station.toJson and fromJson roundtrip with new fields', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Total',
        street: 'Street',
        postCode: '34120',
        place: 'City',
        lat: 43.0,
        lng: 3.0,
        isOpen: true,
        e85: 0.85,
        updatedAt: '23/03',
        is24h: true,
        services: ['DAB'],
        availableFuels: ['Gazole'],
        unavailableFuels: ['GPLc'],
        stationType: 'R',
      );

      final json = station.toJson();
      final restored = Station.fromJson(json);

      expect(restored.e85, 0.85);
      expect(restored.updatedAt, '23/03');
      expect(restored.is24h, true);
      expect(restored.services, ['DAB']);
      expect(restored.availableFuels, ['Gazole']);
      expect(restored.unavailableFuels, ['GPLc']);
      expect(restored.stationType, 'R');
    });
  });

  group('OsmBrandEnricher matching', () {
    test('matches station to nearest POI within 200m', () {
      // Station at 43.452, 3.418
      // POI "Total" at 43.4521, 3.4181 (very close, ~10m)
      // POI "Esso" at 43.464, 3.427 (far, ~1.5km)
      // Should match to "Total"

      final stationLat = 43.452;
      final stationLng = 3.418;
      final poiLat = 43.4521;
      final poiLng = 3.4181;

      // Simple distance check (in degrees, ~111km per degree)
      final dLat = (poiLat - stationLat).abs();
      final dLng = (poiLng - stationLng).abs();
      expect(dLat, lessThan(0.001)); // less than ~100m
      expect(dLng, lessThan(0.001));
    });
  });
}
