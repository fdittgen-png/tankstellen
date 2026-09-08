// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/number_parsing.dart';

/// #3983 — one rule per input kind, instead of four private copies that
/// had drifted (the form accepted a decimal comma; the parsers did not).
void main() {
  group('parseLooseDouble (decoded payloads)', () {
    test('num passes through, dot-decimal strings parse, whitespace tolerated',
        () {
      expect(parseLooseDouble(12), 12.0);
      expect(parseLooseDouble(12.5), 12.5);
      expect(parseLooseDouble('12.5'), 12.5);
      expect(parseLooseDouble('  12.5 '), 12.5);
    });
    test('null, empty, garbage and other types are null — never a throw', () {
      expect(parseLooseDouble(null), isNull);
      expect(parseLooseDouble(''), isNull);
      expect(parseLooseDouble('   '), isNull);
      expect(parseLooseDouble('abc'), isNull);
      expect(parseLooseDouble(true), isNull);
      expect(parseLooseDouble(['1']), isNull);
    });

    // The docstring promises "never throws" — this is the fault-injection
    // test the #2349 ratchet requires behind that promise: hostile inputs
    // of every shape return normally.
    test('fault injection: hostile inputs return normally (never throws)',
        () {
      for (final hostile in <Object?>[
        Object(), <String, int>{}, double.nan, double.infinity, '1e999',
        '--1', '\u0000', 'NaN', '∞', StackTrace.current,
      ]) {
        expect(() => parseLooseDouble(hostile), returnsNormally,
            reason: 'threw on $hostile');
      }
    });
  });

  group('parseUserDouble (typed text)', () {
    test('a decimal comma is a decimal point — 1,5 and 1.5 are one number',
        () {
      expect(parseUserDouble('1,5'), 1.5);
      expect(parseUserDouble('1.5'), 1.5);
      expect(parseUserDouble(' 7,0 '), 7.0);
    });
    test('empty and garbage are null', () {
      expect(parseUserDouble(''), isNull);
      expect(parseUserDouble('  '), isNull);
      expect(parseUserDouble('1,5,0'), isNull);
    });

    test('fault injection: any string returns normally (never throws)', () {
      for (final hostile in ['1,5,0', ',,,', '.', '-', '1e999', '\u0000', '∞']) {
        expect(() => parseUserDouble(hostile), returnsNormally,
            reason: 'threw on $hostile');
      }
    });
  });
}
