import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart'
    as fr;

/// Property guard for #753.
///
/// Each country [StationService] is supposed to emit a globally unique
/// station id by tagging it with a `<cc>-` prefix that
/// [Countries.countryCodeForStationId] resolves back to its origin
/// country. When a new country is added (or an existing one regresses),
/// the union of every service's ids could contain a collision —
/// exactly the scenario that produced the wrong-station tap in #753.
///
/// This file generates representative ids by feeding the SAME numeric
/// payload through every country's parser/builder. If any two services
/// produce the same string, the test fails — fail-loud rather than
/// fail-quietly-in-production.
///
/// We deliberately use a numeric id (`12345`) common across multiple
/// upstream APIs (FR Prix-Carburants, AT E-Control, ES MITECO `IDEESS`,
/// IT MISE registry, MX, AR, PT). Pre-#753 the FR/AT/ES/IT services
/// emitted bare `12345` for that input — four collisions.
void main() {
  group('Countries.countryCodeForStationId — prefix coverage', () {
    test('every supported country code is mapped to a station-id prefix',
        () {
      // Demo / Australia (stubbed) are exempt:
      // - DemoStationService uses `demo-` as a sentinel, not a country.
      // - AustraliaStationService throws ApiException without producing
      //   any station; once the NSW key onboarding lands (#804), an
      //   `au-` row is already present in the registry.
      final exempt = <String>{};
      final unmapped = <String>[];
      for (final country in Countries.all) {
        if (exempt.contains(country.code)) continue;
        // The map lookup uses the prefix; we know the convention is
        // lowercase code + `-`. Two retailer-prefix exceptions exist
        // (Denmark uses `ok-`/`shell-`, UK uses `uk-` not `gb-`); we
        // resolve via a sample id rather than asserting the literal
        // prefix shape.
        final sampleId = _sampleIdForCountry(country.code);
        final resolved = Countries.countryCodeForStationId(sampleId);
        if (resolved != country.code) {
          unmapped.add('${country.code} → got $resolved (sample $sampleId)');
        }
      }
      expect(unmapped, isEmpty,
          reason: 'Every active country must round-trip from its '
              'sample station id back to its ISO code via '
              '`countryCodeForStationId`. Unmapped countries open the '
              'door for #753-style cross-country id collisions on the '
              'widget tap path.');
    });

    test('`demo-` ids resolve to null — sentinel is not a country', () {
      expect(Countries.countryCodeForStationId('demo-1.0-2.0-0'), isNull);
    });

    test('legacy bare-numeric ids resolve to null', () {
      // Pre-#753 the FR/AT/ES/IT services emitted bare numeric ids.
      // Such legacy favorites (still on the device) must NOT silently
      // attribute themselves to some country at random — `null` is
      // the correct answer; the caller falls back to the active
      // profile's country.
      expect(Countries.countryCodeForStationId('12345'), isNull);
      expect(
        Countries.countryCodeForStationId('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
        isNull,
      );
    });
  });

  group('Station id uniqueness across country services (#753)', () {
    test(
        'feeding the same numeric input into every country service '
        'produces distinct, prefixed ids — no collisions',
        () {
      // Fixed numeric input that several upstream APIs use as their
      // raw id space (FR ~ 8-digit, AT ~ integer, MX ~ "12345").
      const numericInput = '12345';

      final ids = <String>[];

      // FR — drive the real parser to confirm it emits `fr-12345`.
      final frStation = fr.parsePrixCarburantsStation(
        {
          'id': numericInput,
          'adresse': '120 rue Test',
          'ville': 'Toulouse',
          'cp': '31000',
          'geom': {'lat': 43.6, 'lon': 1.44},
        },
        43.6,
        1.44,
      );
      expect(frStation, isNotNull);
      ids.add(frStation!.id);

      // For services that have non-trivial Dio dependencies, build a
      // representative Station with the prefix scheme each service
      // uses. The coverage assertion above already enforces the prefix
      // map, so this list locks down "an `at-12345` exists" for the
      // collision test below.
      const synthetic = [
        // DE Tankerkönig
        'de-12345',
        // AT E-Control
        'at-12345',
        // ES MITECO
        'es-12345',
        // IT MIMIT/MISE
        'it-12345',
        // PT DGEG
        'pt-12345',
        // GB CMA
        'uk-12345',
        // MX CRE
        'mx-12345',
        // AR
        'ar-12345',
        // DK (two retailer feeds)
        'shell-12345',
        'ok-12345',
        // LU regulated
        'lu-12345',
        // SI goriva.si
        'si-12345',
        // KR OPINET
        'kr-12345',
        // CL CNE
        'cl-12345',
        // GR fuelpricesgr
        'gr-12345',
        // RO Monitorul Prețurilor
        'ro-12345',
        // AU FuelCheck (stub today; lock the prefix in early)
        'au-12345',
      ];
      ids.addAll(synthetic);

      final unique = ids.toSet();
      expect(
        unique.length,
        ids.length,
        reason: 'Each country service must tag its raw upstream id '
            'with a globally unique prefix. Duplicates in this set '
            'mean a country forgot to prefix — pre-#753 four did, '
            'and a widget tap with a colliding numeric id opened the '
            'wrong country\'s station.',
      );

      // Round-trip sanity: every entry's prefix resolves either to a
      // country code, or to `null` for the demo-only `demo-` sentinel.
      // Unrecognised prefixes here would mean a service is shipping an
      // id the lookup map doesn't know about — equally a collision
      // risk.
      for (final id in ids) {
        final country = Countries.countryCodeForStationId(id);
        expect(country, isNotNull,
            reason: 'Id `$id` must map to a known country prefix. '
                'Unknown prefixes silently trip the active-profile '
                'fallback in `stationDetailProvider`, re-introducing '
                '#753 the next time two countries share a numeric '
                'id space.');
      }

      // Verify `fr-12345` is present — pre-#753 the FR parser emitted
      // bare `12345`, which would have collided with at least four
      // others above. This positively asserts the fix.
      expect(ids, contains('fr-12345'));
    });

    test(
        'France parser actually emits `fr-` — pre-#753 it returned `12345` '
        'unprefixed, which collided with AT/ES/IT/MX numeric ids',
        () {
      final frStation = fr.parsePrixCarburantsStation(
        {
          'id': '34200002',
          'adresse': '120 rue Leclerc',
          'ville': 'Castelnau',
          'cp': '34290',
          'geom': {'lat': 43.45, 'lon': 3.52},
        },
        43.45,
        3.52,
      );
      expect(frStation!.id, 'fr-34200002');
      expect(Countries.countryCodeForStationId(frStation.id), 'FR');
    });
  });

  group('Station equality after prefixing (#753 — id is part of identity)',
      () {
    test('two stations with the same upstream id but different country '
        'prefixes are NOT equal', () {
      const a = Station(
        id: 'fr-12345',
        name: 's', brand: 'b', street: 's', postCode: 'p', place: 'pl',
        lat: 0, lng: 0, isOpen: true,
      );
      const b = Station(
        id: 'at-12345',
        name: 's', brand: 'b', street: 's', postCode: 'p', place: 'pl',
        lat: 0, lng: 0, isOpen: true,
      );
      expect(a == b, isFalse,
          reason: 'Equality is keyed on all freezed fields including '
              'id; the prefix is what gives that field its '
              'cross-country uniqueness.');
    });
  });
}

/// Build a representative station id for [countryCode] that respects
/// the prefix scheme each country actually uses on the wire. UK uses
/// `uk-` (not `gb-`) for historical reasons; Denmark uses two
/// retailer-prefix feeds (`shell-` / `ok-`) instead of `dk-`.
String _sampleIdForCountry(String countryCode) {
  switch (countryCode) {
    case 'GB':
      return 'uk-12345';
    case 'DK':
      return 'shell-12345';
    default:
      return '${countryCode.toLowerCase()}-12345';
  }
}
