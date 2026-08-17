// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/export/_csv_encoder.dart';

void main() {
  group('encodeCsv', () {
    test('returns empty string for empty input', () {
      expect(encodeCsv(const []), '');
    });

    test('joins simple cells with commas and terminates with CRLF', () {
      expect(
        encodeCsv(const [
          ['a', 'b', 'c'],
        ]),
        'a,b,c\r\n',
      );
    });

    test('emits CRLF between rows including after the last row', () {
      expect(
        encodeCsv(const [
          ['a', 'b'],
          ['c', 'd'],
        ]),
        'a,b\r\nc,d\r\n',
      );
    });

    test('renders null cell as empty', () {
      expect(
        encodeCsv(const [
          ['a', null, 'c'],
        ]),
        'a,,c\r\n',
      );
    });

    test('quotes a cell that contains a comma', () {
      expect(
        encodeCsv(const [
          ['a,b', 'c'],
        ]),
        '"a,b",c\r\n',
      );
    });

    test('quotes a cell that contains a double quote and doubles the quote', () {
      expect(
        encodeCsv(const [
          ['he said "hi"', 'next'],
        ]),
        '"he said ""hi""",next\r\n',
      );
    });

    test('quotes a cell that contains a newline', () {
      expect(
        encodeCsv(const [
          ['line1\nline2'],
        ]),
        '"line1\nline2"\r\n',
      );
    });

    test('quotes a cell that contains a carriage return', () {
      expect(
        encodeCsv(const [
          ['has\rCR'],
        ]),
        '"has\rCR"\r\n',
      );
    });

    test('coerces non-string cells via toString', () {
      expect(
        encodeCsv(const [
          [1, 2.5, true, null],
        ]),
        '1,2.5,true,\r\n',
      );
    });

    test('handles single-cell rows without a separator', () {
      expect(
        encodeCsv(const [
          ['solo'],
        ]),
        'solo\r\n',
      );
    });

    test('preserves spaces and does not quote them when no special chars', () {
      expect(
        encodeCsv(const [
          ['  leading and trailing  ', 'plain'],
        ]),
        '  leading and trailing  ,plain\r\n',
      );
    });

    test('handles every quoting trigger combined in one cell', () {
      expect(
        encodeCsv(const [
          ['"quote", comma\nnewline\rcr'],
        ]),
        '"""quote"", comma\nnewline\rcr"\r\n',
      );
    });

    test('preserves empty string as a non-quoted empty cell', () {
      expect(
        encodeCsv(const [
          ['', 'x'],
        ]),
        ',x\r\n',
      );
    });

    group('formula-injection defusal (#3740, OWASP CSV injection)', () {
      test("prefixes ' on a cell starting with =", () {
        expect(
          encodeCsv(const [
            ['=SUM(A1:A3)', 'safe'],
          ]),
          "'=SUM(A1:A3),safe\r\n",
        );
      });

      test("prefixes ' on a cell starting with +", () {
        expect(
          encodeCsv(const [
            ['+49 Tank & Rast'],
          ]),
          "'+49 Tank & Rast\r\n",
        );
      });

      test("prefixes ' on a cell starting with -", () {
        expect(
          encodeCsv(const [
            ['-2+3+cmd|"/C calc"!A0'],
          ]),
          '"\'-2+3+cmd|""/C calc""!A0"\r\n',
        );
      });

      test("prefixes ' on a cell starting with @", () {
        expect(
          encodeCsv(const [
            ['@SUM(1+9)'],
          ]),
          "'@SUM(1+9)\r\n",
        );
      });

      test("prefixes ' on a cell starting with a tab", () {
        expect(
          encodeCsv(const [
            ['\t=1+1'],
          ]),
          "'\t=1+1\r\n",
        );
      });

      test("prefixes ' on a cell starting with a CR and still quotes it", () {
        expect(
          encodeCsv(const [
            ['\r=1+1'],
          ]),
          '"\'\r=1+1"\r\n',
        );
      });

      test('formula-shaped station name with a comma is defused AND quoted',
          () {
        expect(
          encodeCsv(const [
            ['=HYPERLINK("http://evil", "Aral Nord")'],
          ]),
          '"\'=HYPERLINK(""http://evil"", ""Aral Nord"")"\r\n',
        );
      });

      test('negative numbers are NOT defused (they cannot be formulas)', () {
        expect(
          encodeCsv(const [
            [-3.7038, -12, 'lat'],
          ]),
          '-3.7038,-12,lat\r\n',
        );
      });

      test('a formula trigger mid-cell is left alone', () {
        expect(
          encodeCsv(const [
            ['Aral =Nord', 'a+b'],
          ]),
          'Aral =Nord,a+b\r\n',
        );
      });
    });

    test('handles ragged rows (different column counts per row)', () {
      expect(
        encodeCsv(const [
          ['a', 'b', 'c'],
          ['d', 'e'],
          ['f'],
        ]),
        'a,b,c\r\nd,e\r\nf\r\n',
      );
    });
  });
}
