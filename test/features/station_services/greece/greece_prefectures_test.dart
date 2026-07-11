// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/greece/greece_prefectures.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// Tests cover the helpers extracted in PR #1030, rewritten for the
/// #3539 emvouvakis-mirror shape:
///   * [GreekPrefecture] entity
///   * [GreeceObservatoryKeys.lookup]
///   * [GreeceObservatoryKeys.fuelForObservatoryKey]
///   * [GreeceObservatoryKeys.droppedObservatoryKeys]
///   * [GreeceObservatoryKeys.parsePrices]
///   * [kGreekPrefectures] const list
///   * [prefecturesForQuery] top-level helper
///
/// note: since #3539 `parsePrices` operates on ONE prefecture-day ROW
/// (a map with one COLUMN per fuel), not the old `data: [...]` array
/// of `{fuel_type, price}` objects. The "newer-date wins" logic does
/// not live in this helper — date selection happens upstream in
/// `GreeceStationService.parsePrefectureResponse`.
void main() {
  group('GreekPrefecture', () {
    test('constructor populates all fields verbatim', () {
      const p = GreekPrefecture(
        apiName: 'N. ATHINON',
        id: 'gr-attica',
        displayName: 'Αττική / Attica',
        place: 'Αθήνα',
        lat: 37.9838,
        lng: 23.7275,
      );
      expect(p.apiName, 'N. ATHINON');
      expect(p.id, 'gr-attica');
      expect(p.displayName, 'Αττική / Attica');
      expect(p.place, 'Αθήνα');
      expect(p.lat, 37.9838);
      expect(p.lng, 23.7275);
    });

    test('two prefectures with the same args are value-equivalent via const',
        () {
      const a = GreekPrefecture(
        apiName: 'X',
        id: 'gr-x',
        displayName: 'X',
        place: 'X',
        lat: 1.0,
        lng: 2.0,
      );
      const b = GreekPrefecture(
        apiName: 'X',
        id: 'gr-x',
        displayName: 'X',
        place: 'X',
        lat: 1.0,
        lng: 2.0,
      );
      // note: GreekPrefecture does not override == / hashCode — Dart's
      // const canonicalisation makes identical literals share the same
      // instance, so identity holds for two const expressions with the
      // same args.
      expect(identical(a, b), isTrue);
    });
  });

  group('GreeceObservatoryKeys.fuelForObservatoryKey', () {
    test('contains the four documented column mappings (#3539)', () {
      const map = GreeceObservatoryKeys.fuelForObservatoryKey;
      expect(map['unleaded_95_octane'], FuelType.e5);
      expect(map['unleaded_100_octane'], FuelType.e98);
      expect(map['automotive_diesel'], FuelType.diesel);
      expect(map['autogas'], FuelType.lpg);
    });

    test('does NOT contain dropped columns (HOME_HEATING_DIESEL / Super)',
        () {
      // note: source stores keys lowercase. Dropped columns are the
      // policy pinned in [droppedObservatoryKeys], not in this map.
      const map = GreeceObservatoryKeys.fuelForObservatoryKey;
      expect(map.containsKey('home_heating_diesel'), isFalse);
      expect(map.containsKey('super'), isFalse);
    });

    test('does NOT contain the DATE / REGION envelope columns', () {
      const map = GreeceObservatoryKeys.fuelForObservatoryKey;
      expect(map.containsKey('date'), isFalse);
      expect(map.containsKey('region'), isFalse);
    });

    test('has exactly four entries (no silent additions)', () {
      // Lock the surface: any new mapping needs an explicit test update.
      expect(GreeceObservatoryKeys.fuelForObservatoryKey, hasLength(4));
    });
  });

  group('GreeceObservatoryKeys.droppedObservatoryKeys', () {
    test('contains the documented dropped columns', () {
      expect(
        GreeceObservatoryKeys.droppedObservatoryKeys,
        containsAll(<String>['home_heating_diesel', 'super', 'date', 'region']),
      );
    });

    test('has exactly four entries (policy lock)', () {
      expect(GreeceObservatoryKeys.droppedObservatoryKeys, hasLength(4));
    });
  });

  group('GreeceObservatoryKeys.lookup', () {
    test('lowercase known column returns the mapped FuelType', () {
      expect(GreeceObservatoryKeys.lookup('unleaded_95_octane'), FuelType.e5);
      expect(
          GreeceObservatoryKeys.lookup('unleaded_100_octane'), FuelType.e98);
      expect(
          GreeceObservatoryKeys.lookup('automotive_diesel'), FuelType.diesel);
      expect(GreeceObservatoryKeys.lookup('autogas'), FuelType.lpg);
    });

    test('the API\'s own mixed-case spellings are normalised', () {
      // The real rows spell them `UNLEADED_95_Octane` /
      // `UNLEADED_100_OCTANE` / `AUTOMOTIVE_DIESEL` / `AUTOGAS`.
      expect(GreeceObservatoryKeys.lookup('UNLEADED_95_Octane'), FuelType.e5);
      expect(
          GreeceObservatoryKeys.lookup('UNLEADED_100_OCTANE'), FuelType.e98);
      expect(
          GreeceObservatoryKeys.lookup('AUTOMOTIVE_DIESEL'), FuelType.diesel);
      expect(GreeceObservatoryKeys.lookup('AUTOGAS'), FuelType.lpg);
    });

    test('mixed-case column is normalised via toLowerCase', () {
      expect(
          GreeceObservatoryKeys.lookup('UnLeAdEd_100_OcTaNe'), FuelType.e98);
    });

    test('empty string returns null', () {
      expect(GreeceObservatoryKeys.lookup(''), isNull);
    });

    test('unknown column returns null', () {
      expect(GreeceObservatoryKeys.lookup('petrol'), isNull);
      expect(GreeceObservatoryKeys.lookup('e85'), isNull);
    });

    test('dropped columns (HOME_HEATING_DIESEL, Super, DATE, REGION) '
        'return null', () {
      // Same return value as "unknown", which is the deliberate policy.
      expect(GreeceObservatoryKeys.lookup('HOME_HEATING_DIESEL'), isNull);
      expect(GreeceObservatoryKeys.lookup('home_heating_diesel'), isNull);
      expect(GreeceObservatoryKeys.lookup('Super'), isNull);
      expect(GreeceObservatoryKeys.lookup('super'), isNull);
      expect(GreeceObservatoryKeys.lookup('DATE'), isNull);
      expect(GreeceObservatoryKeys.lookup('REGION'), isNull);
    });

    test('whitespace is NOT trimmed (source only lowercases)', () {
      // note: `lookup` only does `.toLowerCase()`. Surrounding whitespace
      // is kept, so 'autogas ' / ' autogas' miss the map.
      expect(GreeceObservatoryKeys.lookup(' unleaded_95_octane'), isNull);
      expect(GreeceObservatoryKeys.lookup('autogas '), isNull);
    });
  });

  group('GreeceObservatoryKeys.parsePrices', () {
    test('non-Map input returns an empty map', () {
      expect(GreeceObservatoryKeys.parsePrices(null), isEmpty);
      expect(GreeceObservatoryKeys.parsePrices(<dynamic>[]), isEmpty);
      expect(GreeceObservatoryKeys.parsePrices('oops'), isEmpty);
      expect(GreeceObservatoryKeys.parsePrices(42), isEmpty);
    });

    test('empty map returns an empty map', () {
      expect(GreeceObservatoryKeys.parsePrices(<String, dynamic>{}), isEmpty);
    });

    test('parses a typical prefecture-day row', () {
      final row = <String, dynamic>{
        'DATE': '2026-07-09',
        'REGION': 'N. ATHINON',
        'UNLEADED_95_Octane': 1.943,
        'UNLEADED_100_OCTANE': 2.16,
        'AUTOMOTIVE_DIESEL': 1.787,
        'AUTOGAS': 0.907,
        'HOME_HEATING_DIESEL': null,
        'Super': null,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out, hasLength(4));
      expect(out[FuelType.e5], closeTo(1.943, 1e-9));
      expect(out[FuelType.e98], closeTo(2.16, 1e-9));
      expect(out[FuelType.diesel], closeTo(1.787, 1e-9));
      expect(out[FuelType.lpg], closeTo(0.907, 1e-9));
    });

    test('the DATE / REGION envelope columns never leak as prices', () {
      final row = <String, dynamic>{
        'DATE': '2026-07-09',
        'REGION': 'N. ATHINON',
        'AUTOMOTIVE_DIESEL': 1.787,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out.keys, [FuelType.diesel]);
    });

    test('dropped columns (HOME_HEATING_DIESEL, Super) are filtered out',
        () {
      final row = <String, dynamic>{
        'HOME_HEATING_DIESEL': 1.20,
        'Super': 1.85,
        'AUTOMOTIVE_DIESEL': 1.787,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out.keys, [FuelType.diesel]);
    });

    test('unknown columns are dropped', () {
      final row = <String, dynamic>{
        'HYDROGEN': 9.99,
        'UNLEADED_95_Octane': 1.943,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out.keys, [FuelType.e5]);
    });

    test('null fuel values are dropped (API publishes null for '
        'unreported fuels)', () {
      final row = <String, dynamic>{
        'UNLEADED_95_Octane': 1.943,
        'UNLEADED_100_OCTANE': null,
        'AUTOGAS': null,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out.keys, [FuelType.e5]);
    });

    test('zero / negative prices are filtered (num path)', () {
      final row = <String, dynamic>{
        'UNLEADED_95_Octane': 0,
        'AUTOMOTIVE_DIESEL': -1.0,
        'AUTOGAS': 0.907,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out, hasLength(1));
      expect(out[FuelType.lpg], closeTo(0.907, 1e-9));
    });

    test('numeric string prices are parsed', () {
      final row = <String, dynamic>{
        'AUTOMOTIVE_DIESEL': '1.787',
        'UNLEADED_95_Octane': '  1.943  ',
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out[FuelType.diesel], closeTo(1.787, 1e-9));
      expect(out[FuelType.e5], closeTo(1.943, 1e-9));
    });

    test('blank / non-numeric string prices are dropped', () {
      final row = <String, dynamic>{
        'AUTOMOTIVE_DIESEL': '',
        'AUTOGAS': '   ',
        'UNLEADED_95_Octane': 'TBD',
      };
      expect(GreeceObservatoryKeys.parsePrices(row), isEmpty);
    });

    test('zero-string / negative-string prices are filtered', () {
      final row = <String, dynamic>{
        'AUTOMOTIVE_DIESEL': '0',
        'AUTOGAS': '-2.5',
      };
      expect(GreeceObservatoryKeys.parsePrices(row), isEmpty);
    });

    test('case-insensitive column names are accepted (lookup lowercases)',
        () {
      final row = <String, dynamic>{
        'unleaded_95_octane': 1.943,
        'Automotive_Diesel': 1.787,
      };
      final out = GreeceObservatoryKeys.parsePrices(row);
      expect(out[FuelType.e5], closeTo(1.943, 1e-9));
      expect(out[FuelType.diesel], closeTo(1.787, 1e-9));
    });
  });

  group('kGreekPrefectures', () {
    test('is non-empty', () {
      expect(kGreekPrefectures, isNotEmpty);
    });

    test('contains Attica and Thessaloniki by stable id', () {
      final ids = kGreekPrefectures.map((p) => p.id).toList();
      expect(ids, contains('gr-attica'));
      expect(ids, contains('gr-thessaloniki'));
    });

    test('every entry uses the gr- id prefix', () {
      // Required by Countries.countryCodeForStationId — flagged in the
      // source comment.
      for (final p in kGreekPrefectures) {
        expect(p.id, startsWith('gr-'),
            reason: '${p.apiName} must use gr- prefix');
      }
    });

    test('every apiName is an uppercase `N. <NAME>` REGION code (#3539)',
        () {
      for (final p in kGreekPrefectures) {
        expect(p.apiName, isNotEmpty);
        expect(p.apiName, startsWith('N. '),
            reason: 'apiName must be the mirror REGION code '
                '(N. = Νομός, transliterated)');
        expect(p.apiName, p.apiName.toUpperCase(),
            reason: 'apiName must match the uppercase REGION column');
      }
    });

    test('the eight REGION codes match the mirror feed', () {
      expect(
        kGreekPrefectures.map((p) => p.apiName),
        containsAll(<String>[
          'N. ATHINON',
          'N. THESSALONIKIS',
          'N. ACHAIAS',
          'N. LARISAS',
          'N. IRAKLIOU',
          'N. IOANNINON',
          'N. DODEKANISON',
          'N. CHANION',
        ]),
      );
    });

    test('coordinates fall within mainland-Greece + Aegean bbox', () {
      // Loose bbox sanity check: lat 34..42, lng 19..29 — covers the
      // mainland plus the eastern Aegean (Dodecanese ~28°E).
      for (final p in kGreekPrefectures) {
        expect(p.lat, inInclusiveRange(34.0, 42.0),
            reason: '${p.apiName} latitude out of range');
        expect(p.lng, inInclusiveRange(19.0, 29.0),
            reason: '${p.apiName} longitude out of range');
      }
    });
  });

  group('prefecturesForQuery', () {
    test('returns at most four entries', () {
      const params = SearchParams(lat: 37.9838, lng: 23.7275);
      // Anchor: Athens.
      final picked = prefecturesForQuery(params, kGreekPrefectures);
      expect(picked.length, lessThanOrEqualTo(4));
      expect(picked, isNotEmpty);
    });

    test('puts Attica first when querying from Athens', () {
      const params = SearchParams(lat: 37.9838, lng: 23.7275);
      final picked = prefecturesForQuery(params, kGreekPrefectures);
      expect(picked.first.id, 'gr-attica');
    });

    test('puts Thessaloniki first when querying from Thessaloniki', () {
      const params = SearchParams(lat: 40.6401, lng: 22.9444);
      final picked = prefecturesForQuery(params, kGreekPrefectures);
      expect(picked.first.id, 'gr-thessaloniki');
    });

    test('puts Heraklion first when querying from central Crete', () {
      // Heraklion 35.3387, 25.1442 — should beat Chania (35.5138, 24.0180).
      const params = SearchParams(lat: 35.3387, lng: 25.1442);
      final picked = prefecturesForQuery(params, kGreekPrefectures);
      expect(picked.first.id, 'gr-heraklion');
    });

    test('does NOT filter by radius — far-away anchor still returns 4', () {
      // note: the helper takes the four closest unconditionally. There
      // is no radius gate. Berlin → still 4 Greek prefectures.
      const params = SearchParams(lat: 52.5200, lng: 13.4050, radiusKm: 5);
      final picked = prefecturesForQuery(params, kGreekPrefectures);
      expect(picked, hasLength(4));
    });

    test('with fewer than four inputs, returns all of them in distance order',
        () {
      const params = SearchParams(lat: 37.9838, lng: 23.7275);
      const subset = <GreekPrefecture>[
        GreekPrefecture(
          apiName: 'N. IRAKLIOU',
          id: 'gr-heraklion',
          displayName: 'Ηράκλειο / Heraklion',
          place: 'Ηράκλειο',
          lat: 35.3387,
          lng: 25.1442,
        ),
        GreekPrefecture(
          apiName: 'N. ATHINON',
          id: 'gr-attica',
          displayName: 'Αττική / Attica',
          place: 'Αθήνα',
          lat: 37.9838,
          lng: 23.7275,
        ),
      ];
      final picked = prefecturesForQuery(params, subset);
      expect(picked.map((p) => p.id), ['gr-attica', 'gr-heraklion']);
    });

    test('empty input returns empty output', () {
      const params = SearchParams(lat: 37.9838, lng: 23.7275);
      expect(prefecturesForQuery(params, const <GreekPrefecture>[]), isEmpty);
    });

    test('does not mutate the input list (sorts a copy)', () {
      const params = SearchParams(lat: 37.9838, lng: 23.7275);
      // Take a snapshot of the const list's original order.
      final originalOrder = kGreekPrefectures.map((p) => p.id).toList();
      prefecturesForQuery(params, kGreekPrefectures);
      expect(kGreekPrefectures.map((p) => p.id).toList(), originalOrder);
    });
  });
}
