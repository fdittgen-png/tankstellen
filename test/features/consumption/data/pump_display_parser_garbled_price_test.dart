// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2798 — salvage a glare-garbled unit price. A 7-segment LCD shows €/L as
// "1.999" but the decimal dot is frequently lost and the leading "1" misreads
// as a 1-lookalike letter ("L999"). The real failing trace
// (LITRES / L999 / PRIDX DU LJTRE / VOLUME / PRIX) derived nothing because
// "L999" was discarded as noise. The salvage is deliberately narrow: it fires
// only on a LEADING LETTER + 3 digits and band-checks the result, so a
// separator-less bare-digit total/volume can never be fabricated into a price.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';

void main() {
  const parser = PumpDisplayParser();

  group('PumpDisplayParser — garbled unit-price salvage (#2798)', () {
    test('recovers "L999" as 1.999 €/L', () {
      final r = parser.parse('PRIX DU LITRE L999');
      expect(r.pricePerLiter, closeTo(1.999, 0.0001));
    });

    test('recovers the real failing trace flat text', () {
      // The exact ML Kit flatText from the reported capture.
      final r = parser.parse('LITRES\nL999\nPRIDX DU LJTRE\nVOLUME\nPRIX');
      expect(r.pricePerLiter, closeTo(1.999, 0.0001),
          reason: 'the discarded L999 token is the 1,999 €/L unit price');
    });

    test('"I999" (capital-i lookalike) also recovers to 1.999', () {
      expect(parser.parse('I999').pricePerLiter, closeTo(1.999, 0.0001));
    });

    test('a bare-digit run with NO leading letter is NOT fabricated into a '
        'price (guards against misreading a total/volume)', () {
      // "1049" (a 10,49 € total whose dot was lost) and "5277" (52,77 L) must
      // never be salvaged as a unit price — the salvage requires a letter lead.
      expect(parser.parse('1049').pricePerLiter, isNull);
      expect(parser.parse('5277').pricePerLiter, isNull);
    });

    test('does not clobber a properly-labelled unit price', () {
      final r = parser.parse('PRIX DU LITRE 1,846 €/L');
      expect(r.pricePerLiter, closeTo(1.846, 0.0001));
    });
  });
}
