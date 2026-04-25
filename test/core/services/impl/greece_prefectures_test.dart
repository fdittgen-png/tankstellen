import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/greece_prefectures.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests cover the helpers extracted in PR #1030:
///   * [GreekPrefecture] entity
///   * [GreeceObservatoryKeys.lookup]
///   * [GreeceObservatoryKeys.fuelForObservatoryKey]
///   * [GreeceObservatoryKeys.droppedObservatoryKeys]
///   * [GreeceObservatoryKeys.parsePrices]
///   * [kGreekPrefectures] const list
///   * [prefecturesForQuery] top-level helper
///
/// note: `parsePrices` operates on the inner `data: [...]` array of a
/// `PriceResponse` envelope (NOT the date-wrapped outer list). The
/// "newer-date wins" logic does not live in this helper — date
/// selection happens upstream in `GreeceStationService`. Tests below
/// reflect what the source actually does.
void main() {
  group('GreekPrefecture', () {
    test('constructor populates all fields verbatim', () {
      const p = GreekPrefecture(
        apiName: 'ATTICA',
        id: 'gr-attica',
        displayName: 'Αττική / Attica',
        place: 'Αθήνα',
        lat: 37.9838,
        lng: 23.7275,
      );
      expect(p.apiName, 'ATTICA');
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
    test('contains the four documented mappings', () {
      const map = GreeceObservatoryKeys.fuelForObservatoryKey;
      expect(map['unleaded_95'], FuelType.e5);
      expect(map['unleaded_100'], FuelType.e98);
      expect(map['diesel'], FuelType.diesel);
      expect(map['gas'], FuelType.lpg);
    });

    test('does NOT contain dropped keys (DIESEL_HEATING / SUPER)', () {
      // note: source stores keys lowercase. Dropped keys are the policy
      // pinned in [droppedObservatoryKeys], not in this map.
      const map = GreeceObservatoryKeys.fuelForObservatoryKey;
      expect(map.containsKey('diesel_heating'), isFalse);
      expect(map.containsKey('super'), isFalse);
    });

    test('has exactly four entries (no silent additions)', () {
      // Lock the surface: any new mapping needs an explicit test update.
      expect(GreeceObservatoryKeys.fuelForObservatoryKey, hasLength(4));
    });
  });

  group('GreeceObservatoryKeys.droppedObservatoryKeys', () {
    test('contains the documented dropped keys', () {
      expect(
        GreeceObservatoryKeys.droppedObservatoryKeys,
        containsAll(<String>['diesel_heating', 'super']),
      );
    });

    test('has exactly two entries (policy lock)', () {
      expect(GreeceObservatoryKeys.droppedObservatoryKeys, hasLength(2));
    });
  });

  group('GreeceObservatoryKeys.lookup', () {
    test('lowercase known key returns the mapped FuelType', () {
      expect(GreeceObservatoryKeys.lookup('unleaded_95'), FuelType.e5);
      expect(GreeceObservatoryKeys.lookup('unleaded_100'), FuelType.e98);
      expect(GreeceObservatoryKeys.lookup('diesel'), FuelType.diesel);
      expect(GreeceObservatoryKeys.lookup('gas'), FuelType.lpg);
    });

    test('uppercase key is normalised via toLowerCase', () {
      // Source: `fuelForObservatoryKey[key.toLowerCase()]`.
      expect(GreeceObservatoryKeys.lookup('UNLEADED_95'), FuelType.e5);
      expect(GreeceObservatoryKeys.lookup('Diesel'), FuelType.diesel);
      expect(GreeceObservatoryKeys.lookup('GAS'), FuelType.lpg);
    });

    test('mixed-case key is normalised via toLowerCase', () {
      expect(GreeceObservatoryKeys.lookup('UnLeAdEd_100'), FuelType.e98);
    });

    test('empty string returns null', () {
      expect(GreeceObservatoryKeys.lookup(''), isNull);
    });

    test('unknown key returns null', () {
      expect(GreeceObservatoryKeys.lookup('petrol'), isNull);
      expect(GreeceObservatoryKeys.lookup('e85'), isNull);
    });

    test('dropped keys (DIESEL_HEATING, SUPER) return null', () {
      // Same return value as "unknown", which is the deliberate policy.
      expect(GreeceObservatoryKeys.lookup('DIESEL_HEATING'), isNull);
      expect(GreeceObservatoryKeys.lookup('diesel_heating'), isNull);
      expect(GreeceObservatoryKeys.lookup('SUPER'), isNull);
      expect(GreeceObservatoryKeys.lookup('super'), isNull);
    });

    test('whitespace is NOT trimmed (source only lowercases)', () {
      // note: `lookup` only does `.toLowerCase()`. Surrounding whitespace
      // is kept, so 'unleaded_95 ' / ' diesel' miss the map.
      expect(GreeceObservatoryKeys.lookup(' unleaded_95'), isNull);
      expect(GreeceObservatoryKeys.lookup('diesel '), isNull);
    });
  });

  group('GreeceObservatoryKeys.parsePrices', () {
    test('non-list input returns an empty map', () {
      expect(GreeceObservatoryKeys.parsePrices(null), isEmpty);
      expect(GreeceObservatoryKeys.parsePrices(<String, dynamic>{}), isEmpty);
      expect(GreeceObservatoryKeys.parsePrices('oops'), isEmpty);
      expect(GreeceObservatoryKeys.parsePrices(42), isEmpty);
    });

    test('empty list returns an empty map', () {
      expect(GreeceObservatoryKeys.parsePrices(<dynamic>[]), isEmpty);
    });

    test('parses a typical Observatory data array', () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'UNLEADED_95', 'price': 1.721},
        <String, dynamic>{'fuel_type': 'UNLEADED_100', 'price': 2.005},
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': 1.499},
        <String, dynamic>{'fuel_type': 'GAS', 'price': 0.999},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out, hasLength(4));
      expect(out[FuelType.e5], closeTo(1.721, 1e-9));
      expect(out[FuelType.e98], closeTo(2.005, 1e-9));
      expect(out[FuelType.diesel], closeTo(1.499, 1e-9));
      expect(out[FuelType.lpg], closeTo(0.999, 1e-9));
    });

    test('non-Map entries are silently dropped', () {
      final raw = <dynamic>[
        'oops',
        42,
        null,
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': 1.499},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out, hasLength(1));
      expect(out[FuelType.diesel], closeTo(1.499, 1e-9));
    });

    test('rows with missing fuel_type are dropped', () {
      final raw = <dynamic>[
        <String, dynamic>{'price': 1.5},
        <String, dynamic>{'fuel_type': '', 'price': 1.5},
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': 1.499},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out.keys, [FuelType.diesel]);
    });

    test('dropped Observatory keys (DIESEL_HEATING, SUPER) are filtered out',
        () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'DIESEL_HEATING', 'price': 1.20},
        <String, dynamic>{'fuel_type': 'SUPER', 'price': 1.85},
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': 1.499},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out.keys, [FuelType.diesel]);
    });

    test('unknown fuel_type values are dropped', () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'HYDROGEN', 'price': 9.99},
        <String, dynamic>{'fuel_type': 'UNLEADED_95', 'price': 1.721},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out.keys, [FuelType.e5]);
    });

    test('zero / negative prices are filtered (num path)', () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'UNLEADED_95', 'price': 0},
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': -1.0},
        <String, dynamic>{'fuel_type': 'GAS', 'price': 0.999},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out, hasLength(1));
      expect(out[FuelType.lpg], closeTo(0.999, 1e-9));
    });

    test('numeric string prices are parsed', () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': '1.499'},
        <String, dynamic>{'fuel_type': 'UNLEADED_95', 'price': '  1.721  '},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out[FuelType.diesel], closeTo(1.499, 1e-9));
      expect(out[FuelType.e5], closeTo(1.721, 1e-9));
    });

    test('blank / non-numeric / null string prices are dropped', () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': ''},
        <String, dynamic>{'fuel_type': 'GAS', 'price': '   '},
        <String, dynamic>{'fuel_type': 'UNLEADED_95', 'price': 'TBD'},
        <String, dynamic>{'fuel_type': 'UNLEADED_100', 'price': null},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out, isEmpty);
    });

    test('zero-string price is filtered', () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': '0'},
        <String, dynamic>{'fuel_type': 'GAS', 'price': '-2.5'},
      ];
      expect(GreeceObservatoryKeys.parsePrices(raw), isEmpty);
    });

    test('duplicate fuel_type rows: last write wins', () {
      // note: source iterates in order and overwrites, so the LAST
      // valid row for a given FuelType is the one that sticks.
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': 1.40},
        <String, dynamic>{'fuel_type': 'DIESEL', 'price': 1.55},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out[FuelType.diesel], closeTo(1.55, 1e-9));
    });

    test('case-insensitive fuel_type keys are accepted (lookup lowercases)',
        () {
      final raw = <dynamic>[
        <String, dynamic>{'fuel_type': 'unleaded_95', 'price': 1.721},
        <String, dynamic>{'fuel_type': 'Diesel', 'price': 1.499},
      ];
      final out = GreeceObservatoryKeys.parsePrices(raw);
      expect(out[FuelType.e5], closeTo(1.721, 1e-9));
      expect(out[FuelType.diesel], closeTo(1.499, 1e-9));
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

    test('every apiName is uppercase / non-empty', () {
      for (final p in kGreekPrefectures) {
        expect(p.apiName, isNotEmpty);
        expect(p.apiName, p.apiName.toUpperCase(),
            reason: 'apiName must be the Observatory enum value');
      }
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
          apiName: 'HERAKLION',
          id: 'gr-heraklion',
          displayName: 'Ηράκλειο / Heraklion',
          place: 'Ηράκλειο',
          lat: 35.3387,
          lng: 25.1442,
        ),
        GreekPrefecture(
          apiName: 'ATTICA',
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
