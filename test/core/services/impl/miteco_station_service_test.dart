import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/miteco_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late MitecoStationService service;

  setUp(() {
    service = MitecoStationService();
  });

  group('MitecoStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('es-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions MITECO API', () async {
        try {
          await service.getStationDetail('es-test');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('MITECO'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['es-1', 'es-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.mitecoApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct metadata', () async {
        final result = await service.getPrices(['x']);
        expect(result.source, ServiceSource.mitecoApi);
        expect(result.fetchedAt, isA<DateTime>());
        expect(result.isStale, isFalse);
      });
    });
  });

  group('MITECO parsing edge cases', () {
    late _TestableMitecoParser parser;

    setUp(() {
      parser = _TestableMitecoParser();
    });

    group('parseCommaDouble additional', () {
      test('parses zero correctly', () {
        expect(parser.testParseCommaDouble('0'), closeTo(0.0, 0.001));
      });

      test('parses large Spanish price', () {
        expect(parser.testParseCommaDouble('123,456'), closeTo(123.456, 0.001));
      });

      test('handles multiple commas (only first replaced in tryParse)', () {
        // "1,234,567" -> "1.234.567" which double.tryParse returns null
        expect(parser.testParseCommaDouble('1,234,567'), isNull);
      });
    });

    group('parseStation additional', () {
      test('handles station with only E85 price', () {
        final record = {
          'IDEESS': '9999',
          'Rótulo': 'BIOSTATION',
          'Dirección': 'BIO ROAD 1',
          'Localidad': 'VALENCIA',
          'C.P.': '46001',
          'Latitud': '39,469',
          'Longitud (WGS84)': '-0,376',
          'Precio Gasolina 95 E85': '1,099',
          'Horario': 'L-D: 00:00-24:00',
        };

        final station = parser.testParseStation(record, 39.47, -0.38);
        expect(station, isNotNull);
        expect(station!.e85, closeTo(1.099, 0.001));
        expect(station.e5, isNull);
      });

      test('handles station with missing IDEESS', () {
        final record = {
          'Rótulo': 'Test',
          'Dirección': 'St',
          'Localidad': 'City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '-3,7',
          'Horario': 'Open',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNotNull);
        expect(station!.id, '');
      });

      test('handles station with all price fields populated', () {
        final record = {
          'IDEESS': '5555',
          'Rótulo': 'FULL',
          'Dirección': 'Full St',
          'Localidad': 'Madrid',
          'C.P.': '28001',
          'Latitud': '40,416',
          'Longitud (WGS84)': '-3,703',
          'Precio Gasolina 95 E5': '1,649',
          'Precio Gasolina 95 E10': '1,599',
          'Precio Gasolina 98 E5': '1,829',
          'Precio Gasoleo A': '1,459',
          'Precio Gasoleo Premium': '1,529',
          'Precio Gasolina 95 E85': '1,099',
          'Precio Gases licuados del petróleo': '0,899',
          'Precio Gas Natural Comprimido': '1,199',
          'Horario': '24H',
          'Margen': 'I',
        };

        final station = parser.testParseStation(record, 40.4, -3.7);
        expect(station, isNotNull);
        expect(station!.e5, isNotNull);
        expect(station.e10, isNotNull);
        expect(station.e98, isNotNull);
        expect(station.diesel, isNotNull);
        expect(station.dieselPremium, isNotNull);
        expect(station.e85, isNotNull);
        expect(station.lpg, isNotNull);
        expect(station.cng, isNotNull);
        expect(station.stationType, 'I');
        expect(station.isOpen, isTrue);
      });
    });

    group('findNearestProvince additional', () {
      test('returns Valencia for coordinates near Valencia', () {
        final id = parser.testFindNearestProvince(39.47, -0.38);
        expect(id, '46'); // Valencia
      });

      test('returns Vizcaya for Bilbao coordinates', () {
        final id = parser.testFindNearestProvince(43.26, -2.93);
        expect(id, '48'); // Vizcaya
      });

      test('returns Ceuta for Ceuta coordinates', () {
        final id = parser.testFindNearestProvince(35.89, -5.32);
        expect(id, '51'); // Ceuta
      });

      test('returns Melilla for Melilla coordinates', () {
        final id = parser.testFindNearestProvince(35.29, -2.94);
        expect(id, '52'); // Melilla
      });

      test('returns Baleares for Mallorca coordinates', () {
        final id = parser.testFindNearestProvince(39.57, 2.65);
        expect(id, '07'); // Baleares
      });
    });
  });

  group('MITECO parsing (via _TestableMitecoParser)', () {
    late _TestableMitecoParser parser;

    setUp(() {
      parser = _TestableMitecoParser();
    });

    group('parseCommaDouble', () {
      test('parses Spanish comma-separated number', () {
        expect(parser.testParseCommaDouble('1,817'), closeTo(1.817, 0.001));
      });

      test('parses number with dot decimal', () {
        expect(parser.testParseCommaDouble('1.817'), closeTo(1.817, 0.001));
      });

      test('returns null for empty string', () {
        expect(parser.testParseCommaDouble(''), isNull);
      });

      test('returns null for null input', () {
        expect(parser.testParseCommaDouble(null), isNull);
      });

      test('returns null for whitespace-only string', () {
        expect(parser.testParseCommaDouble('   '), isNull);
      });

      test('returns null for non-numeric string', () {
        expect(parser.testParseCommaDouble('abc'), isNull);
      });

      test('handles string with leading/trailing whitespace', () {
        expect(parser.testParseCommaDouble(' 1,234 '), closeTo(1.234, 0.001));
      });
    });

    group('parseStation', () {
      test('parses valid MITECO station record', () {
        final record = {
          'IDEESS': '1234',
          'Rótulo': 'REPSOL',
          'Dirección': 'CALLE MAYOR 1',
          'Localidad': 'MADRID',
          'C.P.': '28001',
          'Latitud': '40,416775',
          'Longitud (WGS84)': '-3,703790',
          'Precio Gasolina 95 E5': '1,649',
          'Precio Gasolina 95 E10': '1,599',
          'Precio Gasolina 98 E5': '1,829',
          'Precio Gasoleo A': '1,459',
          'Precio Gasoleo Premium': '1,529',
          'Precio Gases licuados del petróleo': '0,899',
          'Precio Gas Natural Comprimido': '1,199',
          'Horario': 'L-D: 06:00-22:00',
          'Margen': 'D',
        };

        final station = parser.testParseStation(record, 40.42, -3.70);
        expect(station, isNotNull);
        expect(station!.id, '1234');
        expect(station.name, 'REPSOL');
        expect(station.brand, 'REPSOL');
        expect(station.street, 'CALLE MAYOR 1');
        expect(station.place, 'MADRID');
        expect(station.postCode, '28001');
        expect(station.lat, closeTo(40.416775, 0.001));
        expect(station.lng, closeTo(-3.703790, 0.001));
        expect(station.e5, closeTo(1.649, 0.001));
        expect(station.e10, closeTo(1.599, 0.001));
        expect(station.e98, closeTo(1.829, 0.001));
        expect(station.diesel, closeTo(1.459, 0.001));
        expect(station.dieselPremium, closeTo(1.529, 0.001));
        expect(station.lpg, closeTo(0.899, 0.001));
        expect(station.cng, closeTo(1.199, 0.001));
        expect(station.isOpen, isTrue);
        expect(station.openingHoursText, 'L-D: 06:00-22:00');
        expect(station.stationType, 'D');
      });

      test('returns null when latitude is missing', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': 'Test',
          'Dirección': 'Test St',
          'Localidad': 'Test City',
          'C.P.': '00000',
          'Latitud': '',
          'Longitud (WGS84)': '-3,7',
          'Horario': 'L-D: 00:00-24:00',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNull);
      });

      test('returns null when longitude is missing', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': 'Test',
          'Dirección': 'Test St',
          'Localidad': 'Test City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '',
          'Horario': 'L-D: 00:00-24:00',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNull);
      });

      test('marks station as closed when horario is Cerrado', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': 'Test',
          'Dirección': 'St',
          'Localidad': 'City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '-3,7',
          'Horario': 'Cerrado',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNotNull);
        expect(station!.isOpen, isFalse);
      });

      test('marks station as closed when horario is empty', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': 'Test',
          'Dirección': 'St',
          'Localidad': 'City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '-3,7',
          'Horario': '',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNotNull);
        expect(station!.isOpen, isFalse);
      });

      test('uses address as name when brand is empty', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': '',
          'Dirección': 'CALLE MAYOR',
          'Localidad': 'City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '-3,7',
          'Horario': 'L-V: 08:00-20:00',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNotNull);
        expect(station!.name, 'CALLE MAYOR');
      });

      test('handles null price fields without crashing', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': 'Test',
          'Dirección': 'St',
          'Localidad': 'City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '-3,7',
          'Horario': 'L-D: 00:00-24:00',
          'Precio Gasolina 95 E5': null,
          'Precio Gasoleo A': null,
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNotNull);
        expect(station!.e5, isNull);
        expect(station.diesel, isNull);
      });

      test('sets openingHoursText to null when horario is empty', () {
        final record = {
          'IDEESS': '1',
          'Rótulo': 'Test',
          'Dirección': 'St',
          'Localidad': 'City',
          'C.P.': '00000',
          'Latitud': '40,4',
          'Longitud (WGS84)': '-3,7',
          'Horario': '',
        };

        final station = parser.testParseStation(record, 40.0, -3.0);
        expect(station, isNotNull);
        expect(station!.openingHoursText, isNull);
      });
    });

    group('findNearestProvince', () {
      test('returns Madrid for coordinates in center of Spain', () {
        final id = parser.testFindNearestProvince(40.4168, -3.7038);
        expect(id, '28'); // Madrid
      });

      test('returns Barcelona for coordinates near Barcelona', () {
        final id = parser.testFindNearestProvince(41.39, 2.17);
        expect(id, '08'); // Barcelona
      });

      test('returns Sevilla for coordinates near Seville', () {
        final id = parser.testFindNearestProvince(37.39, -5.98);
        expect(id, '41'); // Sevilla
      });

      test('returns Las Palmas for Canary Islands coordinates', () {
        final id = parser.testFindNearestProvince(28.1, -15.4);
        expect(id, '35'); // Las Palmas
      });

      test('returns a valid province ID for any coordinate', () {
        final id = parser.testFindNearestProvince(0, 0);
        expect(id, isNotEmpty);
        // Should still return something reasonable (likely a southern province)
      });
    });
  });
}

/// Replicates MITECO parsing logic for isolated testing.
class _TestableMitecoParser {
  double? testParseCommaDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  Station? testParseStation(
    Map<String, dynamic> r,
    double searchLat,
    double searchLng,
  ) {
    try {
      final lat = testParseCommaDouble(r['Latitud']?.toString());
      final lng = testParseCommaDouble(r['Longitud (WGS84)']?.toString());
      if (lat == null || lng == null) return null;

      final brand = r['Rótulo']?.toString() ?? '';
      final address = r['Dirección']?.toString() ?? '';
      final city = r['Localidad']?.toString() ?? '';
      final postalCode = r['C.P.']?.toString() ?? '';
      final horario = r['Horario']?.toString() ?? '';

      final isOpen = horario.isNotEmpty && horario != 'Cerrado';

      return Station(
        id: r['IDEESS']?.toString() ?? '',
        name: brand.isNotEmpty ? brand : address,
        brand: brand,
        street: address,
        postCode: postalCode,
        place: city,
        lat: lat,
        lng: lng,
        dist: 0,
        e5: testParseCommaDouble(r['Precio Gasolina 95 E5']?.toString()),
        e10: testParseCommaDouble(r['Precio Gasolina 95 E10']?.toString()),
        e98: testParseCommaDouble(r['Precio Gasolina 98 E5']?.toString()),
        diesel: testParseCommaDouble(r['Precio Gasoleo A']?.toString()),
        dieselPremium:
            testParseCommaDouble(r['Precio Gasoleo Premium']?.toString()),
        e85: testParseCommaDouble(r['Precio Gasolina 95 E85']?.toString()),
        lpg: testParseCommaDouble(
            r['Precio Gases licuados del petróleo']?.toString()),
        cng: testParseCommaDouble(
            r['Precio Gas Natural Comprimido']?.toString()),
        isOpen: isOpen,
        openingHoursText: horario.isNotEmpty ? horario : null,
        stationType: r['Margen']?.toString(),
      );
    } on FormatException catch (_) {
      return null;
    }
  }

  String testFindNearestProvince(double lat, double lng) {
    const provinceCenters = {
      '01': (42.8467, -2.6727),
      '02': (38.9943, -1.8585),
      '03': (38.3452, -0.4810),
      '04': (36.8340, -2.4637),
      '05': (40.6565, -4.6818),
      '06': (38.8794, -6.9707),
      '07': (39.5696, 2.6502),
      '08': (41.3851, 2.1734),
      '09': (42.3440, -3.6970),
      '10': (39.4753, -6.3724),
      '11': (36.5271, -6.2886),
      '12': (39.9864, -0.0513),
      '13': (38.9860, -3.9273),
      '14': (37.8882, -4.7794),
      '15': (43.3623, -8.4115),
      '16': (40.0704, -2.1374),
      '17': (41.9794, 2.8214),
      '18': (37.1773, -3.5986),
      '19': (40.6337, -3.1660),
      '20': (43.3183, -1.9812),
      '21': (37.2614, -6.9447),
      '22': (42.1318, -0.4078),
      '23': (37.7796, -3.7849),
      '24': (42.5987, -5.5671),
      '25': (41.6176, 0.6200),
      '26': (42.4650, -2.4500),
      '27': (43.0099, -7.5562),
      '28': (40.4168, -3.7038),
      '29': (36.7213, -4.4214),
      '30': (37.9922, -1.1307),
      '31': (42.8125, -1.6458),
      '32': (42.3358, -7.8639),
      '33': (43.3619, -5.8494),
      '34': (42.0097, -4.5288),
      '35': (28.1235, -15.4363),
      '36': (42.4310, -8.6446),
      '37': (40.9701, -5.6635),
      '38': (28.4636, -16.2518),
      '39': (43.4623, -3.8100),
      '40': (40.9429, -4.1088),
      '41': (37.3891, -5.9845),
      '42': (41.7636, -2.4649),
      '43': (41.1189, 1.2445),
      '44': (40.3456, -1.1065),
      '45': (39.8628, -4.0273),
      '46': (39.4699, -0.3763),
      '47': (41.6523, -4.7245),
      '48': (43.2630, -2.9350),
      '49': (41.5033, -5.7446),
      '50': (41.6488, -0.8891),
      '51': (35.8894, -5.3213),
      '52': (35.2923, -2.9381),
    };

    String bestId = '28';
    double bestDist = double.infinity;

    for (final entry in provinceCenters.entries) {
      final dlat = lat - entry.value.$1;
      final dlng = lng - entry.value.$2;
      final d = dlat * dlat + dlng * dlng; // Squared distance is fine for comparison
      if (d < bestDist) {
        bestDist = d;
        bestId = entry.key;
      }
    }

    return bestId;
  }
}
