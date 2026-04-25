import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/chile_response_parser.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// One `data[]` entry from the CNE Bencina en Línea envelope. Mirrors
/// the documented shape on `ChileStationService` and is intentionally
/// duplicated from `chile_station_service_test.dart` so the parser
/// suite stands alone — no shared fixture should make this file's
/// failure mode depend on the service file's tests.
Map<String, dynamic> _cneStation({
  String codigo = '123456',
  String distribuidor = 'Copec',
  String name = 'Copec Providencia',
  String calle = 'Av. Providencia',
  String numero = '1234',
  String comuna = 'Providencia',
  double lat = -33.4254,
  double lng = -70.6115,
  Map<String, dynamic>? precios,
  String horario = '24_horas',
}) {
  return <String, dynamic>{
    'codigo': codigo,
    'distribuidor': <String, dynamic>{'nombre': distribuidor},
    'nombre_fantasia': name,
    'direccion_calle': calle,
    'direccion_numero': numero,
    'nombre_comuna': comuna,
    'ubicacion': <String, dynamic>{'latitud': lat, 'longitud': lng},
    'precios': precios ??
        <String, dynamic>{
          'gasolina_93': 1290.0,
          'gasolina_95': 1310.0,
          'gasolina_97': 1340.0,
          'diesel': 1150.0,
          'glp': 820.0,
          'kerosene': 1050.0,
        },
    'horario_atencion': horario,
  };
}

Map<String, dynamic> _envelope(List<Map<String, dynamic>> data) =>
    <String, dynamic>{'data': data};

void main() {
  group('fuelForChileProductKey', () {
    test('canonical product keys map to fuel slots', () {
      expect(fuelForChileProductKey('gasolina_93'), FuelType.e5);
      expect(fuelForChileProductKey('gasolina_95'), FuelType.e5);
      expect(fuelForChileProductKey('gasolina_97'), FuelType.e98);
      expect(fuelForChileProductKey('diesel'), FuelType.diesel);
      expect(fuelForChileProductKey('glp'), FuelType.lpg);
      expect(fuelForChileProductKey('gas_licuado'), FuelType.lpg);
    });

    test('case-insensitive', () {
      expect(fuelForChileProductKey('GASOLINA_93'), FuelType.e5);
      expect(fuelForChileProductKey('Diesel'), FuelType.diesel);
    });

    test('kerosene + parafina are intentionally unmapped', () {
      expect(fuelForChileProductKey('kerosene'), isNull);
      expect(fuelForChileProductKey('parafina'), isNull);
      expect(chileDroppedProductKeys, contains('kerosene'));
      expect(chileDroppedProductKeys, contains('parafina'));
    });

    test('unknown product keys return null', () {
      expect(fuelForChileProductKey('hidrogeno'), isNull);
      expect(fuelForChileProductKey(''), isNull);
    });
  });

  group('parseChileStationsResponse', () {
    test('maps a typical CNE envelope into a Station with cl- prefix', () {
      final stations = parseChileStationsResponse(
        _envelope([_cneStation()]),
        fromLat: -33.4254,
        fromLng: -70.6115,
      );
      expect(stations, hasLength(1));
      final s = stations.single;
      expect(s.id, 'cl-123456');
      expect(s.brand, 'Copec');
      expect(s.name, 'Copec Providencia');
      expect(s.street, contains('Providencia'));
      expect(s.place, 'Providencia');
      expect(s.lat, closeTo(-33.4254, 0.0001));
      expect(s.lng, closeTo(-70.6115, 0.0001));
      // 95 should win over 93 for the e5 slot.
      expect(s.e5, closeTo(1310.0, 0.001));
      expect(s.e98, closeTo(1340.0, 0.001));
      expect(s.diesel, closeTo(1150.0, 0.001));
      expect(s.lpg, closeTo(820.0, 0.001));
      // Kerosene is dropped, so no assertion changes other slots.
    });

    test('codigo already prefixed `cl-` is not double-prefixed', () {
      final stations = parseChileStationsResponse(
        _envelope([_cneStation(codigo: 'cl-987654')]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.id, 'cl-987654');
    });

    test('drops kerosene silently while keeping other slots', () {
      final stations = parseChileStationsResponse(
        _envelope([
          _cneStation(precios: <String, dynamic>{
            'diesel': 1150.0,
            'kerosene': 1050.0,
          }),
        ]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.diesel, closeTo(1150.0, 0.001));
      expect(stations.single.e5, isNull);
      expect(stations.single.e98, isNull);
      expect(stations.single.lpg, isNull);
    });

    test('93 alone fills e5; 95 wins over 93 when both are quoted', () {
      final only93 = parseChileStationsResponse(
        _envelope([
          _cneStation(precios: <String, dynamic>{'gasolina_93': 1250.0}),
        ]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(only93.single.e5, closeTo(1250.0, 0.001));

      final both = parseChileStationsResponse(
        _envelope([
          _cneStation(precios: <String, dynamic>{
            'gasolina_93': 1250.0,
            'gasolina_95': 1299.0,
          }),
        ]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(both.single.e5, closeTo(1299.0, 0.001));
    });

    test('skips entries with missing or 0/0 coords', () {
      final stations = parseChileStationsResponse(
        <String, dynamic>{
          'data': [
            <String, dynamic>{
              'codigo': 'X01',
              // no ubicacion
              'precios': <String, dynamic>{'diesel': 1100.0},
            },
            _cneStation(codigo: 'Z01', lat: 0, lng: 0),
            _cneStation(codigo: 'OK1'),
          ],
        },
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations, hasLength(1));
      expect(stations.single.id, 'cl-OK1');
    });

    test('flat latitud/longitud on the station is accepted', () {
      final stations = parseChileStationsResponse(
        <String, dynamic>{
          'data': [
            <String, dynamic>{
              'codigo': 'A2',
              'latitud': -33.40,
              'longitud': -70.55,
              'precios': <String, dynamic>{'diesel': 1160.0},
            },
          ],
        },
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.lat, closeTo(-33.40, 0.0001));
    });

    test('distribuidor can be a flat string (older payloads)', () {
      final stations = parseChileStationsResponse(
        <String, dynamic>{
          'data': [
            <String, dynamic>{
              'codigo': 'A1',
              'distribuidor': 'Petrobras',
              'nombre_fantasia': 'Petrobras Las Condes',
              'ubicacion': <String, dynamic>{
                'latitud': -33.40,
                'longitud': -70.55,
              },
              'precios': <String, dynamic>{'diesel': 1160.0},
            },
          ],
        },
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.brand, 'Petrobras');
    });

    test('falls back to "Independent" when no brand info is present', () {
      final stations = parseChileStationsResponse(
        <String, dynamic>{
          'data': [
            <String, dynamic>{
              'codigo': 'NB1',
              'ubicacion': <String, dynamic>{
                'latitud': -33.40,
                'longitud': -70.55,
              },
              'precios': <String, dynamic>{'diesel': 1100.0},
            },
          ],
        },
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.brand, 'Independent');
    });

    test('non-numeric price strings drop only that price', () {
      final stations = parseChileStationsResponse(
        _envelope([
          _cneStation(precios: <String, dynamic>{
            'diesel': 'N/A',
            'gasolina_95': 1299.0,
          }),
        ]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.diesel, isNull);
      expect(stations.single.e5, closeTo(1299.0, 0.001));
    });

    test('empty / missing data array yields empty list', () {
      expect(
        parseChileStationsResponse(
          _envelope([]),
          fromLat: -33.45,
          fromLng: -70.67,
        ),
        isEmpty,
      );
      expect(
        parseChileStationsResponse(
          <String, dynamic>{},
          fromLat: -33.45,
          fromLng: -70.67,
        ),
        isEmpty,
      );
    });

    test('horario containing "cerrado" marks station as closed', () {
      final stations = parseChileStationsResponse(
        _envelope([
          _cneStation(horario: 'Temporalmente CERRADO por mantenimiento'),
        ]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.isOpen, isFalse);
    });

    test('default horario "24_horas" is treated as open', () {
      final stations = parseChileStationsResponse(
        _envelope([_cneStation()]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.isOpen, isTrue);
    });

    test('unparseable top-level body raises ApiException', () {
      expect(
        () => parseChileStationsResponse(
          'garbage',
          fromLat: -33.45,
          fromLng: -70.67,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('CNE error field without data raises ApiException', () {
      expect(
        () => parseChileStationsResponse(
          <String, dynamic>{'error': 'invalid token'},
          fromLat: -33.45,
          fromLng: -70.67,
        ),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('CNE'),
        )),
      );
    });

    test('joins direccion_calle + direccion_numero into a single street', () {
      final stations = parseChileStationsResponse(
        _envelope([
          _cneStation(calle: 'Av. Apoquindo', numero: '4500'),
        ]),
        fromLat: -33.45,
        fromLng: -70.67,
      );
      expect(stations.single.street, 'Av. Apoquindo 4500');
    });

    test('distance is rounded to 1 decimal', () {
      final stations = parseChileStationsResponse(
        _envelope([_cneStation()]),
        fromLat: -33.50,
        fromLng: -70.70,
      );
      final dist = stations.single.dist;
      expect(dist >= 0, isTrue);
      // Rounded to 1 decimal: re-rounding must equal itself.
      expect(double.parse(dist.toStringAsFixed(1)), dist);
    });
  });
}
