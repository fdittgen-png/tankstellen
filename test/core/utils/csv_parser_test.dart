import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/utils/csv_parser.dart';

void main() {
  group('CsvParser.parseLine', () {
    test('parses simple comma-separated values', () {
      final result = CsvParser.parseLine('a,b,c');
      expect(result, ['a', 'b', 'c']);
    });

    test('trims whitespace around fields', () {
      final result = CsvParser.parseLine(' a , b , c ');
      expect(result, ['a', 'b', 'c']);
    });

    test('handles quoted fields with commas', () {
      final result = CsvParser.parseLine('"field1","field with, comma","field3"');
      expect(result, ['field1', 'field with, comma', 'field3']);
    });

    test('handles mixed quoted and unquoted fields', () {
      final result = CsvParser.parseLine('plain,"quoted, field",another');
      expect(result, ['plain', 'quoted, field', 'another']);
    });

    test('handles empty fields', () {
      final result = CsvParser.parseLine('a,,c');
      expect(result, ['a', '', 'c']);
    });

    test('handles single field', () {
      final result = CsvParser.parseLine('onlyone');
      expect(result, ['onlyone']);
    });

    test('handles semicolon separator', () {
      final result = CsvParser.parseLine('a;b;c', separator: ';');
      expect(result, ['a', 'b', 'c']);
    });

    test('handles quoted fields with semicolon separator', () {
      final result = CsvParser.parseLine('"a;b";c;d', separator: ';');
      expect(result, ['a;b', 'c', 'd']);
    });
  });

  group('CsvParser.parseAll', () {
    test('parses CSV with header row skipped', () {
      const csv = 'name,price,city\nShell,1.85,Berlin\nAral,1.79,Munich';
      final rows = CsvParser.parseAll(csv);

      expect(rows, hasLength(2));
      expect(rows[0], ['Shell', '1.85', 'Berlin']);
      expect(rows[1], ['Aral', '1.79', 'Munich']);
    });

    test('skips multiple header lines', () {
      const csv = 'comment line\nheader\ndata1,data2';
      final rows = CsvParser.parseAll(csv, skipLines: 2);

      expect(rows, hasLength(1));
      expect(rows[0], ['data1', 'data2']);
    });

    test('skips empty lines', () {
      const csv = 'header\nfirst,row\n\nsecond,row\n  \nthird,row';
      final rows = CsvParser.parseAll(csv);

      expect(rows, hasLength(3));
      expect(rows[0], ['first', 'row']);
      expect(rows[1], ['second', 'row']);
      expect(rows[2], ['third', 'row']);
    });

    test('empty CSV returns no rows', () {
      final rows = CsvParser.parseAll('');
      expect(rows, isEmpty);
    });

    test('CSV with only header returns no rows', () {
      final rows = CsvParser.parseAll('header1,header2');
      expect(rows, isEmpty);
    });

    test('handles semicolon separator', () {
      const csv = 'h1;h2\nval1;val2';
      final rows = CsvParser.parseAll(csv, separator: ';');

      expect(rows, hasLength(1));
      expect(rows[0], ['val1', 'val2']);
    });

    test('handles quoted fields in full CSV', () {
      const csv = 'name,address\n"Shell","Hauptstr. 1, Berlin"\n"Aral","Am Markt 5"';
      final rows = CsvParser.parseAll(csv);

      expect(rows, hasLength(2));
      expect(rows[0][1], 'Hauptstr. 1, Berlin');
    });

    test('skipLines 0 includes all lines', () {
      const csv = 'a,b\nc,d';
      final rows = CsvParser.parseAll(csv, skipLines: 0);

      expect(rows, hasLength(2));
    });
  });

  group('CsvParser.parseCommaDouble', () {
    test('parses comma decimal notation', () {
      expect(CsvParser.parseCommaDouble('1,817'), closeTo(1.817, 0.001));
    });

    test('parses dot decimal notation', () {
      expect(CsvParser.parseCommaDouble('1.817'), closeTo(1.817, 0.001));
    });

    test('parses integer string', () {
      expect(CsvParser.parseCommaDouble('42'), 42.0);
    });

    test('returns null for null input', () {
      expect(CsvParser.parseCommaDouble(null), isNull);
    });

    test('returns null for empty string', () {
      expect(CsvParser.parseCommaDouble(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(CsvParser.parseCommaDouble('   '), isNull);
    });

    test('returns null for non-numeric string', () {
      expect(CsvParser.parseCommaDouble('abc'), isNull);
    });

    test('handles leading/trailing whitespace', () {
      expect(CsvParser.parseCommaDouble(' 1,50 '), closeTo(1.50, 0.01));
    });
  });

  group('CsvParser adoption regression', () {
    test('Argentina service uses CsvParser instead of inline parser', () {
      final source = File(
        'lib/features/station_services/argentina/argentina_station_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('CsvParser.parseLine'),
        isTrue,
        reason: 'Argentina service should use CsvParser.parseLine',
      );
      expect(
        source.contains('_parseCsvLine'),
        isFalse,
        reason: 'Argentina service should not have a private _parseCsvLine method',
      );
    });

    test('Argentina CSV parsing runs in compute() isolate', () {
      final source = File(
        'lib/features/station_services/argentina/argentina_station_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('compute(_parseCsv'),
        isTrue,
        reason: 'Argentina CSV parsing should use compute() for background isolate',
      );
    });

    test('MISE service uses CsvParser instead of inline parser', () {
      final source = File(
        'lib/features/station_services/italy/mise_station_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('CsvParser.parseAll'),
        isTrue,
        reason: 'MISE service should use CsvParser.parseAll',
      );
      expect(
        source.contains('LineSplitter'),
        isFalse,
        reason: 'MISE service should not use LineSplitter directly',
      );
    });

    test('both services import csv_parser.dart', () {
      final argSource = File(
        'lib/features/station_services/argentina/argentina_station_service.dart',
      ).readAsStringSync();
      final miseSource = File(
        'lib/features/station_services/italy/mise_station_service.dart',
      ).readAsStringSync();

      expect(argSource, contains('csv_parser.dart'));
      expect(miseSource, contains('csv_parser.dart'));
    });
  });
}
