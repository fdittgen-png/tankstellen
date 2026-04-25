import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/mise_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late MiseStationService service;

  setUp(() {
    service = MiseStationService();
  });

  group('MiseStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('it-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions MISE API', () async {
        try {
          await service.getStationDetail('it-test');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('MISE'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['it-1', 'it-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.miseApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct metadata', () async {
        final result = await service.getPrices(['x']);
        expect(result.source, ServiceSource.miseApi);
        expect(result.fetchedAt, isA<DateTime>());
        expect(result.isStale, isFalse);
      });
    });
  });

  group('MISE CSV parsing edge cases', () {
    late _TestableMiseCsvParser parser;

    setUp(() {
      parser = _TestableMiseCsvParser();
    });

    group('parseStationsCsv edge cases', () {
      test('handles multiple stations and picks correct fields', () {
        const csv = '''Date header
Column headers
11111|G1|Q8|Stradale|Q8 Roma|Via Appia 10|Roma|RM|41.8800|12.5000
22222|G2|IP|Autostradale|IP Autostrada|A1 km 50|Napoli|NA|40.8500|14.2600''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, hasLength(2));
        expect(stations['11111']!.brand, 'Q8');
        expect(stations['11111']!.type, 'Stradale');
        expect(stations['22222']!.brand, 'IP');
        expect(stations['22222']!.type, 'Autostradale');
        expect(stations['22222']!.city, 'Napoli');
      });

      test('handles stations with only some coordinates zero', () {
        const csv = '''header
columns
12345|G|Brand|Type|Name|Addr|City|Prov|0|12.5''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, isEmpty); // lat is 0
      });

      test('handles stations with non-numeric coordinates', () {
        const csv = '''header
columns
12345|G|Brand|Type|Name|Addr|City|Prov|abc|xyz''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, isEmpty); // parsed as 0
      });
    });

    group('parsePricesCsv edge cases', () {
      test('handles GPL and metano fuel types', () {
        const csv = '''header
columns
12345|GPL|0.729|0|29/03/2026 08:00:00
12345|Metano|1.199|0|29/03/2026 08:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices['12345']!.gpl, closeTo(0.729, 0.001));
        expect(prices['12345']!.metano, closeTo(1.199, 0.001));
      });

      test('first price wins for same fuel type and service mode', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|29/03/2026 08:00:00
12345|Benzina|1.999|1|29/03/2026 09:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        // First self-service benzina price should stick
        expect(prices['12345']!.benzinaSelf, closeTo(1.879, 0.001));
      });

      test('handles date with missing time component gracefully', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|29/03/2026''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices['12345'], isNotNull);
        // Date without space doesn't split into 2 parts, so updatedAt stays null
        expect(prices['12345']!.updatedAt, isNull);
      });

      test('handles empty date string', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices['12345'], isNotNull);
        expect(prices['12345']!.updatedAt, isNull);
      });

      test('served benzina and gasolio prices are stored separately', () {
        const csv = '''header
columns
12345|Benzina|2.100|0|29/03/2026 10:00:00
12345|Gasolio|1.900|0|29/03/2026 10:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices['12345']!.benzinaServed, closeTo(2.100, 0.001));
        expect(prices['12345']!.gasolioServed, closeTo(1.900, 0.001));
        expect(prices['12345']!.benzinaSelf, isNull);
        expect(prices['12345']!.gasolioSelf, isNull);
      });
    });

    group('station name fallback', () {
      test('uses brand as name when name is empty', () {
        // In the real service: name.isNotEmpty ? name : brand
        // Simulate: if station name is empty, brand is used
        const name = '';
        const brand = 'Eni';
        final displayName = name.isNotEmpty ? name : brand;
        expect(displayName, 'Eni');
      });

      test('uses name when name is present', () {
        const name = 'Eni Rossi';
        const brand = 'Eni';
        final displayName = name.isNotEmpty ? name : brand;
        expect(displayName, 'Eni Rossi');
      });
    });
  });

  group('MISE CSV parsing (via _TestableMiseCsvParser)', () {
    late _TestableMiseCsvParser parser;

    setUp(() {
      parser = _TestableMiseCsvParser();
    });

    group('parseStationsCsv', () {
      test('parses valid station registry CSV', () {
        const csv = '''Data aggiornamento: 29/03/2026
idImpianto|Gestore|Bandiera|TipoImpianto|NomeImpianto|Indirizzo|Comune|Provincia|Latitudine|Longitudine
12345|ROSSI SRL|Eni|Stradale|Eni Rossi|Via Roma 1|Roma|RM|41.9028|12.4964
67890|BIANCHI SPA|Shell|Autostradale|Shell A1|Autostrada A1 km 123|Firenze|FI|43.7696|11.2558''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, hasLength(2));

        expect(stations['12345'], isNotNull);
        expect(stations['12345']!.brand, 'Eni');
        expect(stations['12345']!.name, 'Eni Rossi');
        expect(stations['12345']!.address, 'Via Roma 1');
        expect(stations['12345']!.city, 'Roma');
        expect(stations['12345']!.province, 'RM');
        expect(stations['12345']!.lat, closeTo(41.9028, 0.001));
        expect(stations['12345']!.lng, closeTo(12.4964, 0.001));
        expect(stations['12345']!.type, 'Stradale');

        expect(stations['67890'], isNotNull);
        expect(stations['67890']!.type, 'Autostradale');
      });

      test('skips stations with zero coordinates', () {
        const csv = '''header
columns
12345|ROSSI|Eni|Stradale|Eni|Via Roma|Roma|RM|0|0''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, isEmpty);
      });

      test('skips rows with fewer than 10 columns', () {
        const csv = '''header
columns
12345|ROSSI|Eni|Stradale''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, isEmpty);
      });

      test('returns empty map for empty CSV', () {
        final stations = parser.testParseStationsCsv('');
        expect(stations, isEmpty);
      });

      test('skips header rows and parses from line 3', () {
        const csv = '''This is the date line
This is the column headers line
12345|G|Brand|Type|Name|Addr|City|Prov|45.0|9.0''';

        final stations = parser.testParseStationsCsv(csv);
        expect(stations, hasLength(1));
      });
    });

    group('parsePricesCsv', () {
      test('parses valid prices CSV with multiple fuel types', () {
        const csv = '''Data aggiornamento: 29/03/2026
idImpianto|descCarburante|prezzo|isSelf|dtComu
12345|Benzina|1.879|1|29/03/2026 08:00:00
12345|Gasolio|1.659|1|29/03/2026 08:00:00
12345|GPL|0.729|0|29/03/2026 08:00:00
12345|Metano|1.199|0|29/03/2026 07:30:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices, hasLength(1));
        expect(prices['12345'], isNotNull);

        final p = prices['12345']!;
        expect(p.benzinaSelf, closeTo(1.879, 0.001));
        expect(p.gasolioSelf, closeTo(1.659, 0.001));
        expect(p.gpl, closeTo(0.729, 0.001));
        expect(p.metano, closeTo(1.199, 0.001));
      });

      test('distinguishes self-service from served prices', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|29/03/2026 08:00:00
12345|Benzina|1.979|0|29/03/2026 08:00:00
12345|Gasolio|1.659|1|29/03/2026 08:00:00
12345|Gasolio|1.759|0|29/03/2026 08:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        final p = prices['12345']!;
        expect(p.benzinaSelf, closeTo(1.879, 0.001));
        expect(p.benzinaServed, closeTo(1.979, 0.001));
        expect(p.gasolioSelf, closeTo(1.659, 0.001));
        expect(p.gasolioServed, closeTo(1.759, 0.001));
      });

      test('skips rows with invalid prices', () {
        const csv = '''header
columns
12345|Benzina|invalid|1|29/03/2026 08:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices, isEmpty);
      });

      test('skips rows with fewer than 5 columns', () {
        const csv = '''header
columns
12345|Benzina|1.5''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices, isEmpty);
      });

      test('returns empty map for empty CSV', () {
        final prices = parser.testParsePricesCsv('');
        expect(prices, isEmpty);
      });

      test('formats updatedAt as DD/MM HH:MM', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|29/03/2026 14:30:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices['12345']!.updatedAt, '29/03 14:30');
      });

      test('keeps most recent update time', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|28/03/2026 08:00:00
12345|Gasolio|1.659|1|29/03/2026 14:30:00''';

        final prices = parser.testParsePricesCsv(csv);
        // 29/03 is more recent than 28/03
        expect(prices['12345']!.updatedAt, '29/03 14:30');
      });

      test('aggregates prices from multiple stations', () {
        const csv = '''header
columns
12345|Benzina|1.879|1|29/03/2026 08:00:00
67890|Benzina|1.899|1|29/03/2026 08:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices, hasLength(2));
        expect(prices.containsKey('12345'), isTrue);
        expect(prices.containsKey('67890'), isTrue);
      });

      test('handles diesel keyword in fuel description', () {
        const csv = '''header
columns
12345|Diesel|1.659|1|29/03/2026 08:00:00''';

        final prices = parser.testParsePricesCsv(csv);
        expect(prices['12345']!.gasolioSelf, closeTo(1.659, 0.001));
      });
    });

    group('station type mapping', () {
      test('Autostradale maps to stationType A', () {
        // When a station has type "Autostradale", the service maps it to "A"
        expect(
          parser.mapStationType('Autostradale'),
          'A',
        );
      });

      test('other types map to stationType R', () {
        expect(parser.mapStationType('Stradale'), 'R');
        expect(parser.mapStationType(''), 'R');
      });
    });
  });

  // Live searchStations() coverage moved to test/core/services/italy_search_live_test.dart
  // (file-level @Tags(['network'])). The two tests previously here wrapped the
  // live call in try/catch that swallowed any non-ApiException, so they passed
  // silently when the runner could reach mimit.gov.it and FAILed only on
  // unrelated DioException timeouts — high noise, zero signal.

  group('MISE full station-building pipeline', () {
    late _TestableMiseCsvParser parser;

    setUp(() {
      parser = _TestableMiseCsvParser();
    });

    test('join stations and prices into Station objects', () {
      const stationsCsv = '''Data aggiornamento: 29/03/2026
idImpianto|Gestore|Bandiera|TipoImpianto|NomeImpianto|Indirizzo|Comune|Provincia|Latitudine|Longitudine
12345|ROSSI SRL|Eni|Stradale|Eni Rossi|Via Roma 1|Roma|RM|41.9028|12.4964
67890|BIANCHI SPA|Shell|Autostradale|Shell A1|Autostrada A1 km 123|Firenze|FI|43.7696|11.2558''';

      const pricesCsv = '''Data aggiornamento: 29/03/2026
idImpianto|descCarburante|prezzo|isSelf|dtComu
12345|Benzina|1.879|1|29/03/2026 08:00:00
12345|Gasolio|1.659|1|29/03/2026 08:00:00
12345|GPL|0.729|0|29/03/2026 08:00:00
12345|Metano|1.199|0|29/03/2026 08:00:00
67890|Benzina|1.999|1|29/03/2026 09:00:00
67890|Gasolio|1.799|1|29/03/2026 09:00:00''';

      final stations = parser.testParseStationsCsv(stationsCsv);
      final prices = parser.testParsePricesCsv(pricesCsv);

      expect(stations, hasLength(2));
      expect(prices, hasLength(2));

      // Build Station objects like the real service does
      final builtStations = <Station>[];

      for (final entry in stations.entries) {
        final s = entry.value;
        final p = prices[entry.key];

        builtStations.add(Station(
          id: entry.key,
          name: s.name.isNotEmpty ? s.name : s.brand,
          brand: s.brand,
          street: s.address,
          postCode: '',
          place: s.city,
          lat: s.lat,
          lng: s.lng,
          dist: 0,
          e5: p?.benzinaSelf ?? p?.benzinaServed,
          e10: p?.benzinaSelf ?? p?.benzinaServed,
          diesel: p?.gasolioSelf ?? p?.gasolioServed,
          lpg: p?.gpl,
          cng: p?.metano,
          isOpen: true,
          updatedAt: p?.updatedAt,
          stationType: s.type == 'Autostradale' ? 'A' : 'R',
        ));
      }

      expect(builtStations, hasLength(2));

      // Check station 12345
      final roma = builtStations.firstWhere((s) => s.id == '12345');
      expect(roma.name, 'Eni Rossi');
      expect(roma.brand, 'Eni');
      expect(roma.street, 'Via Roma 1');
      expect(roma.place, 'Roma');
      expect(roma.e5, closeTo(1.879, 0.001));
      expect(roma.diesel, closeTo(1.659, 0.001));
      expect(roma.lpg, closeTo(0.729, 0.001));
      expect(roma.cng, closeTo(1.199, 0.001));
      expect(roma.stationType, 'R');
      expect(roma.updatedAt, '29/03 08:00');

      // Check station 67890
      final firenze = builtStations.firstWhere((s) => s.id == '67890');
      expect(firenze.name, 'Shell A1');
      expect(firenze.brand, 'Shell');
      expect(firenze.stationType, 'A');
      expect(firenze.e5, closeTo(1.999, 0.001));
      expect(firenze.diesel, closeTo(1.799, 0.001));
    });

    test('station with empty name falls back to brand', () {
      const stationsCsv = '''header
columns
11111|G|Q8|Stradale||Via Test|Roma|RM|41.88|12.50''';

      final stations = parser.testParseStationsCsv(stationsCsv);
      final s = stations['11111']!;
      final displayName = s.name.isNotEmpty ? s.name : s.brand;
      expect(displayName, 'Q8');
    });

    test('self-service price preferred over served price', () {
      const pricesCsv = '''header
columns
12345|Benzina|2.100|0|29/03/2026 10:00:00
12345|Benzina|1.879|1|29/03/2026 10:00:00''';

      final prices = parser.testParsePricesCsv(pricesCsv);
      final p = prices['12345']!;
      // Self-service price should be used for e5
      final e5 = p.benzinaSelf ?? p.benzinaServed;
      expect(e5, closeTo(1.879, 0.001));
    });

    test('station with no prices gets null fuel fields', () {
      const stationsCsv = '''header
columns
99999|G|NoFuel|Stradale|NoFuel Station|Via Empty|Roma|RM|41.88|12.50''';

      final stations = parser.testParseStationsCsv(stationsCsv);
      final prices = <String, _PriceData>{};

      final s = stations['99999']!;
      final p = prices['99999'];

      final station = Station(
        id: '99999',
        name: s.name.isNotEmpty ? s.name : s.brand,
        brand: s.brand,
        street: s.address,
        postCode: '',
        place: s.city,
        lat: s.lat,
        lng: s.lng,
        dist: 0,
        e5: p?.benzinaSelf ?? p?.benzinaServed,
        diesel: p?.gasolioSelf ?? p?.gasolioServed,
        lpg: p?.gpl,
        cng: p?.metano,
        isOpen: true,
        updatedAt: p?.updatedAt,
        stationType: s.type == 'Autostradale' ? 'A' : 'R',
      );

      expect(station.e5, isNull);
      expect(station.diesel, isNull);
      expect(station.lpg, isNull);
      expect(station.cng, isNull);
      expect(station.updatedAt, isNull);
    });

    test('only served prices used when no self-service available', () {
      const pricesCsv = '''header
columns
12345|Benzina|2.100|0|29/03/2026 10:00:00
12345|Gasolio|1.900|0|29/03/2026 10:00:00''';

      final prices = parser.testParsePricesCsv(pricesCsv);
      final p = prices['12345']!;
      // No self-service prices, so served should be used
      final e5 = p.benzinaSelf ?? p.benzinaServed;
      final diesel = p.gasolioSelf ?? p.gasolioServed;
      expect(e5, closeTo(2.100, 0.001));
      expect(diesel, closeTo(1.900, 0.001));
    });
  });
}

/// Replicates MISE CSV parsing logic for isolated testing.
class _TestableMiseCsvParser {
  Map<String, _StationData> testParseStationsCsv(String csv) {
    final stations = <String, _StationData>{};
    final lines = csv.split('\n');

    for (var i = 2; i < lines.length; i++) {
      final parts = lines[i].split('|');
      if (parts.length < 10) continue;

      final id = parts[0].trim();
      final lat = double.tryParse(parts[8].trim()) ?? 0;
      final lng = double.tryParse(parts[9].trim()) ?? 0;
      if (lat == 0 || lng == 0) continue;

      stations[id] = _StationData(
        brand: parts[2].trim(),
        type: parts[3].trim(),
        name: parts[4].trim(),
        address: parts[5].trim(),
        city: parts[6].trim(),
        province: parts[7].trim(),
        lat: lat,
        lng: lng,
      );
    }
    return stations;
  }

  Map<String, _PriceData> testParsePricesCsv(String csv) {
    final prices = <String, _PriceData>{};
    final lines = csv.split('\n');

    for (var i = 2; i < lines.length; i++) {
      final parts = lines[i].split('|');
      if (parts.length < 5) continue;

      final id = parts[0].trim();
      final fuel = parts[1].trim().toLowerCase();
      final price = double.tryParse(parts[2].trim());
      final isSelf = parts[3].trim() == '1';
      final dateStr = parts[4].trim();

      if (price == null) continue;

      final existing = prices[id] ?? _PriceData();

      if (fuel.contains('benzina')) {
        if (isSelf) {
          existing.benzinaSelf ??= price;
        } else {
          existing.benzinaServed ??= price;
        }
      } else if (fuel.contains('gasolio') || fuel.contains('diesel')) {
        if (isSelf) {
          existing.gasolioSelf ??= price;
        } else {
          existing.gasolioServed ??= price;
        }
      } else if (fuel.contains('gpl')) {
        existing.gpl ??= price;
      } else if (fuel.contains('metano')) {
        existing.metano ??= price;
      }

      if (dateStr.isNotEmpty &&
          (existing.updatedAt == null ||
              dateStr.compareTo(existing.updatedAt!) > 0)) {
        final dtParts = dateStr.split(' ');
        if (dtParts.length >= 2) {
          final datePart = dtParts[0].split('/');
          final timePart = dtParts[1].split(':');
          if (datePart.length >= 2 && timePart.length >= 2) {
            existing.updatedAt =
                '${datePart[0]}/${datePart[1]} ${timePart[0]}:${timePart[1]}';
          }
        }
      }

      prices[id] = existing;
    }
    return prices;
  }

  String mapStationType(String type) {
    return type == 'Autostradale' ? 'A' : 'R';
  }
}

class _StationData {
  final String brand;
  final String type;
  final String name;
  final String address;
  final String city;
  final String province;
  final double lat;
  final double lng;

  const _StationData({
    required this.brand,
    required this.type,
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.lat,
    required this.lng,
  });
}

class _PriceData {
  double? benzinaSelf;
  double? benzinaServed;
  double? gasolioSelf;
  double? gasolioServed;
  double? gpl;
  double? metano;
  String? updatedAt;
}
