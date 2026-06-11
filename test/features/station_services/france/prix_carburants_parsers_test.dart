// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();
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
      // #753 — parser now prefixes the upstream numeric id with `fr-`
      // for global uniqueness across countries. The bare `34200002`
      // form would have collided with AT/ES/IT services that emit raw
      // numeric ids in the same range.
      expect(station!.id, 'fr-34200002');
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

    test(
        'drops the record when BOTH coordinate sources are missing — '
        'no (0,0) phantom station (#3175)', () {
      // No `geom` and no legacy `latitude`/`longitude`: the parser used
      // to emit a Station at (0,0) — a phantom in the Gulf of Guinea
      // that survived radius filtering only because distanceKm
      // short-circuits (0,0) to 0, i.e. "closest station ever".
      final station = parsePrixCarburantsStation(<String, dynamic>{
        'id': null,
        'adresse': null,
        'ville': null,
        'cp': null,
      }, 43.0, 3.0);
      expect(station, isNull);
    });

    test('drops the record when geom and legacy lat/lng are all zero '
        '(#3175)', () {
      final station = parsePrixCarburantsStation({
        'id': '99999',
        'adresse': 'Test',
        'ville': 'TestVille',
        'cp': '75001',
        'geom': <String, dynamic>{},
        'latitude': '0',
        'longitude': '0',
      }, 43.0, 3.0);
      expect(station, isNull);
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
    test('formats hours, strips Automate-24-24, and un-glues the day↔clock',
        () {
      final out = parsePrixCarburantsOpeningHours(
        'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30',
      );
      expect(out, isNotNull);
      // #2710 — the missing-space bug is fixed: the day name is separated
      // from its first clock (`Lundi 07:00-18:30`), never glued.
      expect(out, contains('Lundi 07:00-18:30'));
      expect(out, isNot(contains('Lundi07:00')));
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

  group('parsePrixCarburantsHoursInput never throws (#3219 fault injection)',
      () {
    test('malformed structured horaires shapes all return normally and '
        'degrade to a null schedule', () {
      // Broken JSON string.
      expect(() => parsePrixCarburantsHoursInput({'horaires': '{not json'}),
          returnsNormally);
      // Non-string, non-map column value.
      expect(() => parsePrixCarburantsHoursInput({'horaires': 42}),
          returnsNormally);
      // `jour` is a scalar instead of list/map.
      expect(
          () => parsePrixCarburantsHoursInput(
              {'horaires': '{"jour": "weird"}'}),
          returnsNormally);
      // `horaire` entries are scalars.
      expect(
          () => parsePrixCarburantsHoursInput({
                'horaires':
                    '{"jour": [{"@nom": "Lundi", "horaire": ["x", 1]}]}',
              }),
          returnsNormally);

      final out = parsePrixCarburantsHoursInput({'horaires': '{not json'});
      expect(out['horaires_jour'], isNull);
      expect(out['horaires_automate_24_24'], 'Non');
    });

    test('a structured column with usable ranges resolves when the derived '
        'column is null', () {
      final out = parsePrixCarburantsHoursInput({
        'horaires_jour': null,
        'horaires':
            '{"@automate-24-24": "", "jour": [{"@nom": "Lundi", "@ferme": "", '
                '"horaire": {"@ouverture": "07.00", "@fermeture": "18.30"}}]}',
      });
      expect(out['horaires_jour'], 'Lundi07.00-18.30');
      expect(out['horaires_automate_24_24'], 'Non');
    });

    test('the derived column wins when both are present (byte-for-byte '
        'back-compat)', () {
      final out = parsePrixCarburantsHoursInput({
        'horaires_jour': 'Lundi 06.30-14.00 et 14.00-21.30',
        'horaires':
            '{"jour": [{"@nom": "Mardi", "horaire": {"@ouverture": "01.00", '
                '"@fermeture": "02.00"}}]}',
      });
      expect(out['horaires_jour'], 'Lundi 06.30-14.00 et 14.00-21.30');
    });
  });
}
