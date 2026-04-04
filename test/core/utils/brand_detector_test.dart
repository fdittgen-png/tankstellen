import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/utils/brand_detector.dart';

void main() {
  group('BrandDetector.detect', () {
    group('international brands', () {
      test('detects TotalEnergies', () {
        expect(BrandDetector.detect('TOTALENERGIES Station Paris'), 'TotalEnergies');
      });

      test('detects Total', () {
        expect(BrandDetector.detect('Total Access Marseille'), 'Total');
      });

      test('detects Shell', () {
        expect(BrandDetector.detect('Shell Tankstelle Berlin'), 'Shell');
      });

      test('detects BP', () {
        expect(BrandDetector.detect('BP Station Hamburg'), 'BP');
      });

      test('detects Esso', () {
        expect(BrandDetector.detect('Esso Tankstelle'), 'Esso');
      });

      test('detects AVIA', () {
        expect(BrandDetector.detect('AVIA Tankstelle Freiburg'), 'AVIA');
      });
    });

    group('French brands', () {
      test('detects E.Leclerc', () {
        expect(BrandDetector.detect('LECLERC DRIVE Montpellier'), 'E.Leclerc');
      });

      test('detects Carrefour', () {
        expect(BrandDetector.detect('Carrefour Market'), 'Carrefour');
      });

      test('detects Intermarche with accent', () {
        expect(BrandDetector.detect('INTERMARCHÉ Super'), 'Intermarché');
      });

      test('detects Intermarche without accent', () {
        expect(BrandDetector.detect('INTERMARCHE Contact'), 'Intermarché');
      });

      test('detects Super U', () {
        expect(BrandDetector.detect('Super U Saint-Jean'), 'Super U');
      });
    });

    group('Austrian brands', () {
      test('detects OMV', () {
        expect(BrandDetector.detect('OMV Tankstelle Wien'), 'OMV');
      });

      test('detects Jet', () {
        expect(BrandDetector.detect('JET Graz'), 'Jet');
      });
    });

    group('Spanish brands', () {
      test('detects Repsol', () {
        expect(BrandDetector.detect('REPSOL Gasolinera Madrid'), 'Repsol');
      });

      test('detects Cepsa', () {
        expect(BrandDetector.detect('CEPSA Barcelona'), 'Cepsa');
      });
    });

    group('German brands', () {
      test('detects ARAL', () {
        expect(BrandDetector.detect('ARAL Tankstelle'), 'ARAL');
      });

      test('detects HEM', () {
        expect(BrandDetector.detect('HEM Tankstelle Dresden'), 'HEM');
      });
    });

    group('case insensitivity', () {
      test('detects lowercase brand names', () {
        expect(BrandDetector.detect('shell station'), 'Shell');
      });

      test('detects mixed case brand names', () {
        expect(BrandDetector.detect('Repsol Gasolinera'), 'Repsol');
      });
    });

    group('unknown brands', () {
      test('returns first word for unrecognized station', () {
        expect(BrandDetector.detect('Kleintankstelle Dorf'), 'Kleintankstelle');
      });

      test('returns fallback for empty string', () {
        expect(BrandDetector.detect(''), 'Station');
      });

      test('returns custom fallback for empty string', () {
        expect(BrandDetector.detect('', fallback: 'Unknown'), 'Unknown');
      });

      test('returns first word split by hyphen', () {
        expect(BrandDetector.detect('Dorftank-Express'), 'Dorftank');
      });
    });
  });
}
