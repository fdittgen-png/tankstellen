import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/osm_brand_enricher.dart';

/// Regression guards for #481 — the OSM `name` field was previously
/// written directly to the persistent brand cache without validation,
/// so garbage values like "ff" could leak into the chip filter as
/// mystery labels. The fix adds `OsmBrandEnricher.sanitizeOsmBrand`
/// which rejects short / non-letter / phone-number / time-range /
/// repetitive-punctuation strings.
void main() {
  group('OsmBrandEnricher.sanitizeOsmBrand (regression #481)', () {
    test('accepts strings that already match a canonical brand or alias', () {
      expect(OsmBrandEnricher.sanitizeOsmBrand('Total'), 'Total');
      expect(OsmBrandEnricher.sanitizeOsmBrand('Esso Express'), 'Esso Express');
      expect(OsmBrandEnricher.sanitizeOsmBrand('TotalEnergies'), 'TotalEnergies');
      expect(OsmBrandEnricher.sanitizeOsmBrand('bft'), 'bft');
    });

    test('accepts plausible unknown brands that at least look like a name', () {
      // Not in the registry but passes the letter / length / punctuation checks.
      expect(
        OsmBrandEnricher.sanitizeOsmBrand('Station service Dupont'),
        'Station service Dupont',
      );
      expect(
        OsmBrandEnricher.sanitizeOsmBrand('Relais du Soleil'),
        'Relais du Soleil',
      );
    });

    test('rejects strings shorter than 3 characters', () {
      expect(OsmBrandEnricher.sanitizeOsmBrand('ff'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('x'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand(''), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('  '), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('??'), isNull);
    });

    test('rejects strings with no letters (pure digits, symbols, coordinates)',
        () {
      expect(OsmBrandEnricher.sanitizeOsmBrand('1234'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('???'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('---'), isNull);
    });

    test('rejects phone numbers and similar contact-info payloads', () {
      expect(OsmBrandEnricher.sanitizeOsmBrand('+33 4 67 90 12 34'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('04.67.90.12.34'), isNull);
    });

    test('rejects opening-hours-looking strings', () {
      expect(OsmBrandEnricher.sanitizeOsmBrand('08:00-20:00'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('Mo-Fr 07:30-19:30'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('24:00'), isNull);
    });

    test('rejects strings where less than 3 characters are letters', () {
      // 2 letters + punctuation → should still be rejected
      expect(OsmBrandEnricher.sanitizeOsmBrand('X-Y'), isNull);
      expect(OsmBrandEnricher.sanitizeOsmBrand('xx.'), isNull);
      // 3+ letters → accepted
      expect(OsmBrandEnricher.sanitizeOsmBrand('XYZ'), 'XYZ');
    });

    test('trims leading and trailing whitespace before validating', () {
      expect(
        OsmBrandEnricher.sanitizeOsmBrand('  Total  '),
        'Total',
      );
      expect(
        OsmBrandEnricher.sanitizeOsmBrand('\tEsso\n'),
        'Esso',
      );
    });

    test('accepts accented Latin characters (French brand names)', () {
      expect(
        OsmBrandEnricher.sanitizeOsmBrand('Intermarché'),
        'Intermarché',
      );
      expect(
        OsmBrandEnricher.sanitizeOsmBrand('Système U'),
        'Système U',
      );
    });
  });
}
