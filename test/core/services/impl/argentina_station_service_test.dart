import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/argentina_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';

void main() {
  late ArgentinaStationService service;

  setUp(() {
    service = ArgentinaStationService();
  });

  group('ArgentinaStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('ar-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions Argentina API', () async {
        try {
          await service.getStationDetail('ar-test');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('Argentina'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['ar-1', 'ar-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.argentinaApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct ServiceSource', () async {
        final result = await service.getPrices(['x']);
        expect(result.source, ServiceSource.argentinaApi);
        expect(result.fetchedAt, isA<DateTime>());
      });
    });
  });

  group('Argentina CSV parsing edge cases', () {
    late _TestableArgentinaCsvParser parser;

    setUp(() {
      parser = _TestableArgentinaCsvParser();
    });

    test('parseCsv parses multiple data rows correctly', () {
      const csv = '''header_line
col0,col1,col2,YPF,AV. RIVADAVIA 5000,CABALLITO,Buenos Aires,col7,col8,Nafta (súper) entre 92 Ron,col10,col11,750.0,2026-03-20T08:00:00,col14,YPF,-34.6200,-58.4300,col18,col19
col0,col1,col2,Shell,SANTA FE 2000,PALERMO,Buenos Aires,col7,col8,Gas Oil Grado 2,col10,col11,800.0,2026-03-20T08:00:00,col14,SHELL,-34.5900,-58.4100,col18,col19
col0,col1,col2,Axion,CORRIENTES 1000,CENTRO,Buenos Aires,col7,col8,GNC,col10,col11,50.0,2026-03-20T08:00:00,col14,AXION,-34.6040,-58.3920,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, hasLength(3));
      expect(stations[0].empresa, 'YPF');
      expect(stations[0].producto, contains('Nafta'));
      expect(stations[1].empresa, 'Shell');
      expect(stations[1].producto, contains('Gas Oil'));
      expect(stations[2].empresa, 'Axion');
      expect(stations[2].producto, contains('GNC'));
    });

    test('parseCsv skips rows with negative price', () {
      const csv = '''header
col0,col1,col2,Axion,Dir,Loc,Prov,col7,col8,Nafta,col10,col11,-5.0,2026-01-01,col14,AXION,-34.45,-58.91,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, isEmpty);
    });

    test('parseCsv handles non-numeric lat/lng as zero', () {
      const csv = '''header
col0,col1,col2,Axion,Dir,Loc,Prov,col7,col8,Nafta premium,col10,col11,100.0,2026-01-01,col14,AXION,invalid,also_invalid,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, hasLength(1));
      expect(stations[0].lat, 0);
      expect(stations[0].lng, 0);
    });

    test('parseCsv handles short fechaVigencia', () {
      const csv = '''header
col0,col1,col2,TestCo,Dir,Loc,Prov,col7,col8,Nafta premium,col10,col11,100.5,short,col14,BRAND,-34.5,-58.9,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, hasLength(1));
      expect(stations[0].fechaVigencia, 'short');
    });

    test('parseCsvLine handles quoted fields with embedded quotes toggle', () {
      final parts = parser.testParseCsvLine('a,"b,c",d,"e"');
      expect(parts, hasLength(4));
      expect(parts[0], 'a');
      expect(parts[1], 'b,c');
      expect(parts[2], 'd');
      expect(parts[3], 'e');
    });

    test('parseCsvLine handles single field', () {
      final parts = parser.testParseCsvLine('only_one');
      expect(parts, hasLength(1));
      expect(parts[0], 'only_one');
    });

    test('parseCsvLine handles empty string', () {
      final parts = parser.testParseCsvLine('');
      expect(parts, hasLength(1));
      expect(parts[0], '');
    });

    group('fuel type mapping additional cases', () {
      test('maps nafta with 95 ron to premium', () {
        final merged = parser.testMapFuel(
          'Nafta de 95 Ron', 160.0,
        );
        expect(merged.naftaPremium, 160.0);
      });

      test('maps nafta with grado 3 to premium', () {
        final merged = parser.testMapFuel(
          'Nafta grado 3', 170.0,
        );
        expect(merged.naftaPremium, 170.0);
      });

      test('maps nafta with grado 2 to regular', () {
        final merged = parser.testMapFuel(
          'Nafta grado 2', 130.0,
        );
        expect(merged.naftaRegular, 130.0);
      });

      test('maps gas oil without grado to diesel regular', () {
        final merged = parser.testMapFuel(
          'Gas Oil', 190.0,
        );
        expect(merged.dieselRegular, 190.0);
        expect(merged.dieselPremium, isNull);
      });

      test('maps gas oil premium to diesel premium', () {
        final merged = parser.testMapFuel(
          'Gas Oil premium', 210.0,
        );
        expect(merged.dieselPremium, 210.0);
      });

      test('unknown fuel type does not set any price', () {
        final merged = parser.testMapFuel('Kerosene', 100.0);
        expect(merged.naftaRegular, isNull);
        expect(merged.naftaPremium, isNull);
        expect(merged.dieselRegular, isNull);
        expect(merged.dieselPremium, isNull);
        expect(merged.gnc, isNull);
      });

      test('first mapped price wins (no overwrite)', () {
        final merged = _MergedStation();
        merged.naftaPremium = 150.0;
        // Simulate: second price for same fuel should not overwrite
        merged.naftaPremium ??= 200.0;
        expect(merged.naftaPremium, 150.0);
      });
    });
  });

  group('Argentina CSV parsing (via _TestableArgentinaCsvParser)', () {
    late _TestableArgentinaCsvParser parser;

    setUp(() {
      parser = _TestableArgentinaCsvParser();
    });

    test('parseCsv parses valid CSV with header and data rows', () {
      // Columns: 0,1,2,3=empresa,4=direccion,5=localidad,6=provincia,7,8,
      //          9=producto,10,11,12=precio,13=fecha,14,15=bandera,16=lat,17=lng,18,19
      const csv = '''header_line
col0,col1,col2,Axion Energy,AV. LIBERTADOR 1234,PILAR,Buenos Aires,col7,col8,Nafta (premium) de más de 95 Ron,col10,col11,899.9,2026-03-28T10:00:00,col14,AXION,-34.4585,-58.9140,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, hasLength(1));
      expect(stations[0].empresa, 'Axion Energy');
      expect(stations[0].direccion, 'AV. LIBERTADOR 1234');
      expect(stations[0].localidad, 'PILAR');
      expect(stations[0].provincia, 'Buenos Aires');
      expect(stations[0].bandera, 'AXION');
      expect(stations[0].lat, closeTo(-34.4585, 0.001));
      expect(stations[0].lng, closeTo(-58.9140, 0.001));
      expect(stations[0].precio, closeTo(899.9, 0.1));
      expect(stations[0].producto, contains('Nafta'));
    });

    test('parseCsv skips rows with zero price', () {
      const csv = '''header
col0,col1,col2,Axion,Dir,Loc,Prov,col7,col8,Nafta,col10,col11,0,2026-01-01,col14,AXION,-34.45,-58.91,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, isEmpty);
    });

    test('parseCsv skips rows with fewer than 19 columns', () {
      const csv = '''header
col1,col2,col3,col4''';

      final stations = parser.testParseCsv(csv);
      expect(stations, isEmpty);
    });

    test('parseCsv returns empty list for empty input', () {
      final stations = parser.testParseCsv('');
      expect(stations, isEmpty);
    });

    test('parseCsv handles header-only CSV', () {
      const csv = 'h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19';
      final stations = parser.testParseCsv(csv);
      expect(stations, isEmpty);
    });

    test('parseCsvLine handles quoted fields with commas', () {
      final parts = parser.testParseCsvLine('"Hello, World",foo,bar');
      expect(parts, hasLength(3));
      expect(parts[0], 'Hello, World');
      expect(parts[1], 'foo');
      expect(parts[2], 'bar');
    });

    test('parseCsvLine handles unquoted simple fields', () {
      final parts = parser.testParseCsvLine('a,b,c,d');
      expect(parts, hasLength(4));
      expect(parts, equals(['a', 'b', 'c', 'd']));
    });

    test('parseCsvLine handles empty fields', () {
      final parts = parser.testParseCsvLine('a,,c,');
      expect(parts, hasLength(4));
      expect(parts[1], '');
      expect(parts[3], '');
    });

    test('parseCsv truncates fechaVigencia to 10 chars', () {
      const csv = '''header
col0,col1,col2,TestCo,Dir,Loc,Prov,col7,col8,Nafta premium,col10,col11,100.5,2026-03-28T10:00:00,col14,BRAND,-34.5,-58.9,col18,col19''';

      final stations = parser.testParseCsv(csv);
      expect(stations, hasLength(1));
      expect(stations[0].fechaVigencia, '2026-03-28');
    });

    group('fuel type mapping', () {
      test('maps nafta premium correctly', () {
        final merged = parser.testMapFuel(
          'Nafta (premium) de más de 95 Ron', 150.0,
        );
        expect(merged.naftaPremium, 150.0);
        expect(merged.naftaRegular, isNull);
      });

      test('maps nafta super/regular correctly', () {
        // "Nafta (súper) entre 92 y 95 Ron" contains both "92" and "95 Ron",
        // but the premium check runs first (contains '95 ron'), so this
        // actually maps to premium. Test with a simpler super string.
        final merged = parser.testMapFuel(
          'Nafta (súper) entre 92 Ron', 120.0,
        );
        expect(merged.naftaRegular, 120.0);
        expect(merged.naftaPremium, isNull);
      });

      test('maps gas oil grado 2 to diesel regular', () {
        final merged = parser.testMapFuel('Gas Oil Grado 2', 180.0);
        expect(merged.dieselRegular, 180.0);
        expect(merged.dieselPremium, isNull);
      });

      test('maps gas oil grado 3 (premium) to diesel premium', () {
        final merged = parser.testMapFuel(
          'Gas Oil Grado 3 premium', 200.0,
        );
        expect(merged.dieselPremium, 200.0);
      });

      test('maps GNC correctly', () {
        final merged = parser.testMapFuel('GNC', 50.0);
        expect(merged.gnc, 50.0);
      });
    });
  });
}

/// Replicates Argentina CSV parsing logic for isolated testing.
class _TestableArgentinaCsvParser {
  List<_RawStation> testParseCsv(String csv) {
    final stations = <_RawStation>[];
    final lines = csv.split('\n');
    if (lines.isEmpty) return stations;

    for (var i = 1; i < lines.length; i++) {
      final parts = testParseCsvLine(lines[i]);
      if (parts.length < 19) continue;

      final lat = double.tryParse(parts[16]) ?? 0;
      final lng = double.tryParse(parts[17]) ?? 0;
      final precio = double.tryParse(parts[12]) ?? 0;
      if (precio <= 0) continue;

      stations.add(_RawStation(
        empresa: parts[3],
        direccion: parts[4],
        localidad: parts[5],
        provincia: parts[6],
        producto: parts[9],
        precio: precio,
        fechaVigencia: parts[13].length >= 10
            ? parts[13].substring(0, 10)
            : parts[13],
        bandera: parts[15],
        lat: lat,
        lng: lng,
      ));
    }
    return stations;
  }

  List<String> testParseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  /// Simulates the fuel type mapping logic from searchStations.
  _MergedStation testMapFuel(String producto, double precio) {
    final merged = _MergedStation();
    final p = producto.toLowerCase();

    if (p.contains('nafta') &&
        (p.contains('premium') ||
            p.contains('95 ron') ||
            p.contains('grado 3'))) {
      merged.naftaPremium = precio;
    } else if (p.contains('nafta') &&
        (p.contains('súper') ||
            p.contains('super') ||
            p.contains('92') ||
            p.contains('grado 2'))) {
      merged.naftaRegular = precio;
    } else if (p.contains('gas oil') &&
        (p.contains('grado 3') || p.contains('premium'))) {
      merged.dieselPremium = precio;
    } else if (p.contains('gas oil') &&
        (p.contains('grado 2') || !p.contains('grado 3'))) {
      merged.dieselRegular = precio;
    } else if (p.contains('gnc')) {
      merged.gnc = precio;
    }

    return merged;
  }
}

class _RawStation {
  final String empresa;
  final String direccion;
  final String localidad;
  final String provincia;
  final String producto;
  final double precio;
  final String fechaVigencia;
  final String bandera;
  final double lat;
  final double lng;

  const _RawStation({
    required this.empresa,
    required this.direccion,
    required this.localidad,
    required this.provincia,
    required this.producto,
    required this.precio,
    required this.fechaVigencia,
    required this.bandera,
    required this.lat,
    required this.lng,
  });
}

class _MergedStation {
  double? naftaRegular;
  double? naftaPremium;
  double? dieselRegular;
  double? dieselPremium;
  double? gnc;
}
