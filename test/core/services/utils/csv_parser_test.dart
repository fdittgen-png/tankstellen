import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/utils/csv_parser.dart';

void main() {
  group('CsvParser.parseLine', () {
    test('plain CSV without quotes uses fast path', () {
      expect(
        CsvParser.parseLine('a,b,c'),
        <String>['a', 'b', 'c'],
      );
    });

    test('trims whitespace on fast path', () {
      expect(
        CsvParser.parseLine(' a , b , c '),
        <String>['a', 'b', 'c'],
      );
    });

    test('handles quoted fields with embedded comma', () {
      expect(
        CsvParser.parseLine('"field1","field with, comma","field3"'),
        <String>['field1', 'field with, comma', 'field3'],
      );
    });

    test('supports custom separator (semicolon)', () {
      expect(
        CsvParser.parseLine('a;b;c', separator: ';'),
        <String>['a', 'b', 'c'],
      );
    });

    test('handles custom separator with quotes', () {
      expect(
        CsvParser.parseLine('"a";"b;with semi";"c"', separator: ';'),
        <String>['a', 'b;with semi', 'c'],
      );
    });

    test('returns empty fields as empty strings', () {
      expect(
        CsvParser.parseLine('a,,c'),
        <String>['a', '', 'c'],
      );
    });

    test('handles trailing empty field', () {
      expect(
        CsvParser.parseLine('a,b,'),
        <String>['a', 'b', ''],
      );
    });

    test('single field, no separator', () {
      expect(CsvParser.parseLine('hello'), <String>['hello']);
    });

    test('handles empty string as single empty field', () {
      expect(CsvParser.parseLine(''), <String>['']);
    });

    test('quoted empty fields produce empty strings', () {
      expect(
        CsvParser.parseLine('"","b",""'),
        <String>['', 'b', ''],
      );
    });

    test('mixed quoted + unquoted fields', () {
      expect(
        CsvParser.parseLine('a,"b, quoted",c'),
        <String>['a', 'b, quoted', 'c'],
      );
    });

    test('quoted field trims surrounding whitespace', () {
      expect(
        CsvParser.parseLine(' "a" , "b" '),
        <String>['a', 'b'],
      );
    });
  });

  group('CsvParser.parseAll', () {
    test('skips 1 header line by default', () {
      const csv = 'col1,col2\na,b\nc,d';
      expect(
        CsvParser.parseAll(csv),
        <List<String>>[
          <String>['a', 'b'],
          <String>['c', 'd'],
        ],
      );
    });

    test('skipLines=0 includes every line', () {
      const csv = 'a,b\nc,d';
      expect(
        CsvParser.parseAll(csv, skipLines: 0),
        <List<String>>[
          <String>['a', 'b'],
          <String>['c', 'd'],
        ],
      );
    });

    test('skipLines=2 skips multiple header rows', () {
      const csv = 'meta\ncol1,col2\na,b\nc,d';
      expect(
        CsvParser.parseAll(csv, skipLines: 2),
        <List<String>>[
          <String>['a', 'b'],
          <String>['c', 'd'],
        ],
      );
    });

    test('respects custom separator', () {
      const csv = 'col1;col2\na;b\nc;d';
      expect(
        CsvParser.parseAll(csv, separator: ';'),
        <List<String>>[
          <String>['a', 'b'],
          <String>['c', 'd'],
        ],
      );
    });

    test('skips empty lines inside the body', () {
      const csv = 'col1,col2\na,b\n\nc,d\n   \n';
      expect(
        CsvParser.parseAll(csv),
        <List<String>>[
          <String>['a', 'b'],
          <String>['c', 'd'],
        ],
      );
    });

    test('handles CRLF line endings via LineSplitter', () {
      const csv = 'col1,col2\r\na,b\r\nc,d';
      expect(
        CsvParser.parseAll(csv),
        <List<String>>[
          <String>['a', 'b'],
          <String>['c', 'd'],
        ],
      );
    });

    test('handles a CSV body with quoted commas', () {
      const csv = 'col1,col2\n"hello, world","x"\n"a","b"';
      expect(
        CsvParser.parseAll(csv),
        <List<String>>[
          <String>['hello, world', 'x'],
          <String>['a', 'b'],
        ],
      );
    });

    test('returns empty list when CSV only has the header', () {
      const csv = 'col1,col2';
      expect(CsvParser.parseAll(csv), <List<String>>[]);
    });

    test('returns empty list for empty input', () {
      expect(CsvParser.parseAll(''), <List<String>>[]);
    });
  });

  group('CsvParser.parseCommaDouble', () {
    test('null input returns null', () {
      expect(CsvParser.parseCommaDouble(null), isNull);
    });

    test('empty string returns null', () {
      expect(CsvParser.parseCommaDouble(''), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(CsvParser.parseCommaDouble('   '), isNull);
    });

    test('comma decimal "1,817" parses to 1.817', () {
      expect(CsvParser.parseCommaDouble('1,817'), closeTo(1.817, 1e-9));
    });

    test('dot decimal "1.817" parses to 1.817', () {
      expect(CsvParser.parseCommaDouble('1.817'), closeTo(1.817, 1e-9));
    });

    test('integer string "2" parses to 2.0', () {
      expect(CsvParser.parseCommaDouble('2'), 2.0);
    });

    test('invalid numeric returns null', () {
      expect(CsvParser.parseCommaDouble('abc'), isNull);
    });

    test('leading/trailing whitespace', () {
      // trim().isEmpty check is the only trim; the actual number parse uses
      // the raw string (minus replaced commas). double.tryParse accepts
      // surrounding whitespace.
      expect(CsvParser.parseCommaDouble(' 1,5 '), closeTo(1.5, 1e-9));
    });

    test('negative comma decimal', () {
      expect(CsvParser.parseCommaDouble('-0,5'), closeTo(-0.5, 1e-9));
    });

    test('two commas produce invalid double → null', () {
      // "1,8,17" → "1.8.17" → not a valid double
      expect(CsvParser.parseCommaDouble('1,8,17'), isNull);
    });
  });
}
