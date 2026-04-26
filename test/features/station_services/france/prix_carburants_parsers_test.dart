import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';

void main() {
  // Pure-function tests for the Prix-Carburants parser module (#563
  // split). These exercise the JSON-shape contract directly without
  // any Dio fake — if the live endpoint shape drifts, the failure
  // localises here in ~50 ms instead of inside the integration tests.
  group('extractPrixCarburantsResults', () {
    test('returns the results array when present', () {
      final out = extractPrixCarburantsResults({
        'results': [
          {'id': '1'},
          {'id': '2'},
        ],
      });
      expect(out, hasLength(2));
      expect(out[0]['id'], '1');
    });

    test('returns empty list when results key missing', () {
      expect(extractPrixCarburantsResults(<String, dynamic>{}), isEmpty);
    });

    test('returns empty list when results is null', () {
      expect(
        extractPrixCarburantsResults(<String, dynamic>{'results': null}),
        isEmpty,
      );
    });

    test('returns empty list for non-map payload', () {
      expect(extractPrixCarburantsResults('not a map'), isEmpty);
      expect(extractPrixCarburantsResults(null), isEmpty);
      expect(extractPrixCarburantsResults(42), isEmpty);
    });
  });

  group('parsePrixCarburantsStation', () {
    test('parses a fully-populated record', () {
      final station = parsePrixCarburantsStation({
        'id': '34200002',
        'adresse': '120 RUE LECLERC',
        'ville': 'CASTELNAU',
        'cp': '34290',
        'geom': {'lat': 43.45, 'lon': 3.52},
        'sp95_prix': 1.879,
        'e10_prix': 1.799,
        'gazole_prix': 1.659,
        'sp98_prix': 1.929,
        'e85_prix': 0.899,
        'gplc_prix': 0.999,
        'services_service': ['Lavage automatique', 'DAB'],
        'horaires_automate_24_24': 'Oui',
        'carburants_disponibles': ['Gazole', 'SP95', 'E10'],
        'carburants_indisponibles': <dynamic>[],
        'pop': 'R',
        'departement': 'Hérault',
        'region': 'Occitanie',
      }, 43.4, 3.5);

      expect(station, isNotNull);
      expect(station!.id, '34200002');
      expect(station.name, '120 RUE LECLERC');
      expect(station.brand, 'E.Leclerc');
      expect(station.postCode, '34290');
      expect(station.place, 'CASTELNAU');
      expect(station.lat, 43.45);
      expect(station.lng, 3.52);
      expect(station.e5, 1.879);
      expect(station.e10, 1.799);
      expect(station.diesel, 1.659);
      expect(station.is24h, isTrue);
      expect(station.services, contains('DAB'));
      expect(station.availableFuels, contains('Gazole'));
      expect(station.stationType, 'R');
      expect(station.department, 'Hérault');
      expect(station.region, 'Occitanie');
      expect(station.dist, greaterThan(0));
    });

    test('falls back to legacy lat/lng when geom is missing', () {
      final station = parsePrixCarburantsStation({
        'id': '12345',
        'adresse': 'Test',
        'ville': 'TestVille',
        'cp': '75001',
        'geom': <String, dynamic>{},
        'latitude': '4345000',
        'longitude': '352000',
      }, 43.0, 3.0);

      expect(station, isNotNull);
      expect(station!.lat, closeTo(43.45, 0.01));
      expect(station.lng, closeTo(3.52, 0.01));
    });

    test('still emits a station for minimal/null record', () {
      final station = parsePrixCarburantsStation(<String, dynamic>{
        'id': null,
        'adresse': null,
        'ville': null,
        'cp': null,
      }, 0, 0);
      expect(station, isNotNull);
      expect(station!.id, '');
    });

    test('coerces null prices to null Station fields', () {
      final station = parsePrixCarburantsStation({
        'id': '1',
        'adresse': 'Test',
        'ville': 'Paris',
        'cp': '75001',
        'geom': {'lat': 48.8, 'lon': 2.3},
        'sp95_prix': null,
        'e10_prix': null,
        'gazole_prix': null,
      }, 48.8, 2.3);

      expect(station, isNotNull);
      expect(station!.e5, isNull);
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
    });
  });

  group('detectPrixCarburantsBrand', () {
    test('detects TotalEnergies from address', () {
      expect(
        detectPrixCarburantsBrand(
          'TOTALENERGIES RELAIS',
          null,
          {'ville': 'PARIS', 'cp': '75001'},
        ),
        'TotalEnergies',
      );
    });

    test('detects E.Leclerc from address', () {
      expect(
        detectPrixCarburantsBrand(
          'CC LECLERC SUD',
          null,
          {'ville': '', 'cp': ''},
        ),
        'E.Leclerc',
      );
    });

    test('detects brand from services list', () {
      expect(
        detectPrixCarburantsBrand(
          'GARAGE DU COIN',
          ['Vente de fioul domestique', 'TOTAL WASH'],
          {'ville': 'PARIS', 'cp': '75001'},
        ),
        'Total',
      );
    });

    test('detects brand from ville', () {
      expect(
        detectPrixCarburantsBrand(
          'RN7',
          null,
          {'ville': 'AUCHAN CENTRE COMMERCIAL', 'cp': '75001'},
        ),
        'Auchan',
      );
    });

    test('detects Autoroute via pop=A fallback', () {
      expect(
        detectPrixCarburantsBrand(
          'AIRE DE REPOS',
          null,
          {'ville': '', 'cp': '', 'pop': 'A'},
        ),
        'Autoroute',
      );
    });

    test('returns Independent sentinel for unknown addresses (#482)', () {
      expect(
        detectPrixCarburantsBrand(
          'SOME RANDOM GARAGE',
          null,
          {'ville': '', 'cp': ''},
        ),
        'Independent',
      );
    });
  });

  group('parsePrixCarburantsOpeningHours', () {
    test('formats hours and strips Automate-24-24 prefix', () {
      final out = parsePrixCarburantsOpeningHours(
        'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30',
      );
      expect(out, isNotNull);
      expect(out, contains('Lundi07:00-18:30'));
      expect(out, isNot(contains('Automate-24-24')));
      expect(out, isNot(contains(', ')));
    });

    test('returns null for null input', () {
      expect(parsePrixCarburantsOpeningHours(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parsePrixCarburantsOpeningHours(''), isNull);
    });
  });

  group('parsePrixCarburantsServices', () {
    test('returns list of strings for List input', () {
      expect(
        parsePrixCarburantsServices(['Lavage', 'DAB', 'Boutique']),
        ['Lavage', 'DAB', 'Boutique'],
      );
    });

    test('returns empty list for non-list input', () {
      expect(parsePrixCarburantsServices(null), isEmpty);
      expect(parsePrixCarburantsServices('string'), isEmpty);
      expect(parsePrixCarburantsServices(42), isEmpty);
    });
  });

  group('parsePrixCarburantsStringList', () {
    test('returns list of strings for List input', () {
      expect(
        parsePrixCarburantsStringList(['Gazole', 'SP95']),
        ['Gazole', 'SP95'],
      );
    });

    test('returns empty list for non-list input', () {
      expect(parsePrixCarburantsStringList(null), isEmpty);
      expect(parsePrixCarburantsStringList('string'), isEmpty);
    });
  });

  group('parsePrixCarburantsMostRecentUpdate', () {
    test('returns the most recent date formatted', () {
      final out = parsePrixCarburantsMostRecentUpdate({
        'gazole_maj': '2026-03-23T00:01:00+00:00',
        'sp95_maj': '2026-03-25T14:30:00+00:00',
        'e10_maj': '2026-03-24T10:00:00+00:00',
      });
      expect(out, isNotNull);
      expect(out, contains('25/03'));
      expect(out, contains('14:30'));
    });

    test('returns null when no dates present', () {
      expect(parsePrixCarburantsMostRecentUpdate(<String, dynamic>{}), isNull);
    });

    test('falls back to a trimmed substring on malformed input', () {
      final out = parsePrixCarburantsMostRecentUpdate({
        'gazole_maj': 'not-a-date-format',
      });
      expect(out, isNotNull);
    });
  });
}
