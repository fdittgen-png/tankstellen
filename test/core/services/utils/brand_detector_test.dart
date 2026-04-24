import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/utils/brand_detector.dart';

void main() {
  group('BrandDetector.detect — international brands', () {
    test('TOTALENERGIES → TotalEnergies', () {
      expect(BrandDetector.detect('TOTALENERGIES Station A75'), 'TotalEnergies');
    });

    test('"TOTAL " (trailing space) → Total', () {
      expect(BrandDetector.detect('TOTAL Station'), 'Total');
    });

    test('SHELL → Shell', () {
      expect(BrandDetector.detect('SHELL Highway'), 'Shell');
    });

    test('"BP " (trailing space) → BP', () {
      expect(BrandDetector.detect('BP Station 42'), 'BP');
    });

    test('ESSO → Esso', () {
      expect(BrandDetector.detect('ESSO Express'), 'Esso');
    });

    test('AVIA → AVIA', () {
      expect(BrandDetector.detect('AVIA XPress'), 'AVIA');
    });
  });

  group('BrandDetector.detect — France', () {
    test('LECLERC → E.Leclerc', () {
      expect(BrandDetector.detect('E.LECLERC Béziers'), 'E.Leclerc');
    });

    test('CARREFOUR → Carrefour', () {
      expect(BrandDetector.detect('CARREFOUR Market'), 'Carrefour');
    });

    test('INTERMARCHE (no accent) → Intermarché', () {
      expect(BrandDetector.detect('INTERMARCHE Contact'), 'Intermarché');
    });

    test('INTERMARCHÉ (with accent) → Intermarché', () {
      expect(BrandDetector.detect('INTERMARCHÉ Super'), 'Intermarché');
    });

    test('AUCHAN → Auchan', () {
      expect(BrandDetector.detect('AUCHAN Drive'), 'Auchan');
    });

    test('SUPER U → Super U', () {
      expect(BrandDetector.detect('SUPER U Pezenas'), 'Super U');
    });

    test('SYSTEME U (no accent) → Système U', () {
      expect(BrandDetector.detect('SYSTEME U Distrib'), 'Système U');
    });

    test('SYSTÈME U (with accent) → Système U', () {
      expect(BrandDetector.detect('SYSTÈME U Market'), 'Système U');
    });

    test('CASINO → Casino', () {
      expect(BrandDetector.detect('CASINO Shop'), 'Casino');
    });

    test('VITO → Vito', () {
      expect(BrandDetector.detect('VITO Station'), 'Vito');
    });

    test('NETTO → Netto', () {
      expect(BrandDetector.detect('NETTO Discount'), 'Netto');
    });

    test('DYNEFF → Dyneff', () {
      expect(BrandDetector.detect('DYNEFF Languedoc'), 'Dyneff');
    });
  });

  group('BrandDetector.detect — Austria', () {
    test('OMV → OMV', () {
      expect(BrandDetector.detect('OMV Wien'), 'OMV');
    });

    test('JET → Jet', () {
      expect(BrandDetector.detect('JET Tankstelle'), 'Jet');
    });

    test('ENI → Eni', () {
      expect(BrandDetector.detect('ENI Station'), 'Eni');
    });

    test('AVANTI → Avanti', () {
      expect(BrandDetector.detect('AVANTI Autobahn'), 'Avanti');
    });

    test('TURMÖL → Turmöl', () {
      expect(BrandDetector.detect('TURMÖL Graz'), 'Turmöl');
    });

    test('IQ → IQ', () {
      expect(BrandDetector.detect('IQ Station'), 'IQ');
    });

    test('GENOL → Genol', () {
      expect(BrandDetector.detect('GENOL Salzburg'), 'Genol');
    });

    test('LAGERHAUS → Lagerhaus', () {
      expect(BrandDetector.detect('LAGERHAUS Country'), 'Lagerhaus');
    });
  });

  group('BrandDetector.detect — Spain', () {
    test('REPSOL → Repsol', () {
      expect(BrandDetector.detect('REPSOL Madrid'), 'Repsol');
    });

    test('CEPSA → Cepsa', () {
      expect(BrandDetector.detect('CEPSA Barcelona'), 'Cepsa');
    });

    test('GALP → Galp', () {
      expect(BrandDetector.detect('GALP Lisboa'), 'Galp');
    });
  });

  group('BrandDetector.detect — Italy', () {
    test('IP → IP', () {
      expect(BrandDetector.detect('IP Milano'), 'IP');
    });

    test('Q8 → Q8', () {
      expect(BrandDetector.detect('Q8 Torino'), 'Q8');
    });

    test('TOTALERG → TotalErg', () {
      expect(BrandDetector.detect('TOTALERG Italia'), 'TotalErg');
    });

    test('TAMOIL → Tamoil', () {
      expect(BrandDetector.detect('TAMOIL Napoli'), 'Tamoil');
    });
  });

  group('BrandDetector.detect — Germany', () {
    test('ARAL → ARAL', () {
      expect(BrandDetector.detect('ARAL Autobahn'), 'ARAL');
    });

    test('STAR → STAR', () {
      expect(BrandDetector.detect('STAR Tankstelle'), 'STAR');
    });

    test('HEM → HEM', () {
      expect(BrandDetector.detect('HEM Berlin'), 'HEM');
    });
  });

  group('BrandDetector.detect — case insensitivity', () {
    test('lowercase "total " matches', () {
      expect(BrandDetector.detect('total station'), 'Total');
    });

    test('mixed case "Shell" matches', () {
      expect(BrandDetector.detect('Shell Highway'), 'Shell');
    });

    test('mixed case "Carrefour" matches', () {
      expect(BrandDetector.detect('Carrefour Express'), 'Carrefour');
    });
  });

  group('BrandDetector.detect — priority / iteration order', () {
    test('TOTALENERGIES beats CARREFOUR when both appear', () {
      // Map iteration order: TOTALENERGIES is first (international bucket)
      // and matches before CARREFOUR.
      expect(
        BrandDetector.detect('TOTALENERGIES Carrefour Market'),
        'TotalEnergies',
      );
    });

    test('SHELL beats LECLERC when both appear', () {
      expect(
        BrandDetector.detect('Shell partnership Leclerc'),
        'Shell',
      );
    });

    test('TOTALENERGIES beats the "TOTAL " fallback', () {
      // "TOTALENERGIES" is checked before "TOTAL ". Because the text also
      // contains "TOTAL " (followed by a space) we verify the first-key wins.
      expect(
        BrandDetector.detect('TOTALENERGIES TOTAL Supplier'),
        'TotalEnergies',
      );
    });
  });

  group('BrandDetector.detect — fallback behaviour', () {
    test('empty string returns default fallback "Station"', () {
      expect(BrandDetector.detect(''), 'Station');
    });

    test('empty string honors a custom fallback', () {
      expect(BrandDetector.detect('', fallback: 'Unknown'), 'Unknown');
    });

    test('unrecognised text returns first word (space split)', () {
      expect(BrandDetector.detect('Zebra Crossing 123'), 'Zebra');
    });

    test('unrecognised text returns first word (dash split)', () {
      expect(BrandDetector.detect('Foo-Bar'), 'Foo');
    });

    test('unrecognised text returns first word (mixed space+dash)', () {
      expect(BrandDetector.detect('Alpha Beta-Gamma'), 'Alpha');
    });

    test('single unrecognised word returns itself', () {
      expect(BrandDetector.detect('Zzzz'), 'Zzzz');
    });
  });
}
