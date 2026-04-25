import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/south_korea_response_parser.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests cover the helpers extracted in PR #1035:
///   * [OpinetProductCodes.fuelForProductCode]
///   * [OpinetProductCodes.lookup]
///   * [OpinetStationAccumulator.absorbBase]
///   * [OpinetStationAccumulator.toStation]
///   * [mergeOpinetProductResponse] top-level helper
///
/// Source: `lib/core/services/impl/south_korea_response_parser.dart`. The
/// kerosene product code (`C004`) is intentionally absent from the
/// product-code map — the upstream service never asks for it, and the
/// parser silently drops anything that arrives.
void main() {
  group('OpinetProductCodes.fuelForProductCode', () {
    test('contains the four documented mappings', () {
      const map = OpinetProductCodes.fuelForProductCode;
      expect(map['B027'], FuelType.e5);
      expect(map['B034'], FuelType.e98);
      expect(map['D047'], FuelType.diesel);
      expect(map['K015'], FuelType.lpg);
    });

    test('does NOT contain kerosene (C004) — intentionally dropped', () {
      // note: source comment pins this. C004 has no FuelType yet, so the
      // parser silently skips any response that arrives.
      expect(
        OpinetProductCodes.fuelForProductCode.containsKey('C004'),
        isFalse,
      );
    });

    test('has exactly four entries (no silent additions)', () {
      // Lock the surface: any new mapping needs an explicit test update.
      expect(OpinetProductCodes.fuelForProductCode, hasLength(4));
    });
  });

  group('OpinetProductCodes.lookup', () {
    test('known codes return the mapped FuelType', () {
      expect(OpinetProductCodes.lookup('B027'), FuelType.e5);
      expect(OpinetProductCodes.lookup('B034'), FuelType.e98);
      expect(OpinetProductCodes.lookup('D047'), FuelType.diesel);
      expect(OpinetProductCodes.lookup('K015'), FuelType.lpg);
    });

    test('unknown codes return null', () {
      expect(OpinetProductCodes.lookup('X999'), isNull);
      expect(OpinetProductCodes.lookup('C004'), isNull); // kerosene
      expect(OpinetProductCodes.lookup('foo'), isNull);
    });

    test('empty string returns null', () {
      expect(OpinetProductCodes.lookup(''), isNull);
    });

    test('lowercase variants are NOT normalised — source does no case fold',
        () {
      // note: `lookup` is a plain map read. Map keys are uppercase, so
      // 'b027' / 'd047' miss. Mirrors the source — no `.toUpperCase()`.
      expect(OpinetProductCodes.lookup('b027'), isNull);
      expect(OpinetProductCodes.lookup('d047'), isNull);
    });

    test('whitespace is NOT trimmed', () {
      // note: same reason as case — lookup is a raw map read.
      expect(OpinetProductCodes.lookup(' B027'), isNull);
      expect(OpinetProductCodes.lookup('B027 '), isNull);
    });
  });

  group('OpinetStationAccumulator constructor', () {
    test('initial state has only uniId set, prices map empty', () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      expect(acc.uniId, 'A0001');
      expect(acc.brandCode, isNull);
      expect(acc.name, isNull);
      expect(acc.address, isNull);
      expect(acc.lat, isNull);
      expect(acc.lng, isNull);
      expect(acc.apiDistanceKm, isNull);
      expect(acc.prices, isEmpty);
    });
  });

  group('OpinetStationAccumulator.absorbBase', () {
    test('populates brand / name / address / coords / distance from raw map',
        () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'SKE',
        'OS_NM': '서울SK주유소',
        'NEW_ADR': '서울특별시 강남구 테헤란로 123',
        'GIS_Y_COOR': 37.5,
        'GIS_X_COOR': 127.0,
        'DISTANCE': 1234.0, // metres
      });
      expect(acc.brandCode, 'SKE');
      expect(acc.name, '서울SK주유소');
      expect(acc.address, '서울특별시 강남구 테헤란로 123');
      expect(acc.lat, closeTo(37.5, 1e-9));
      expect(acc.lng, closeTo(127.0, 1e-9));
      // 1234 m → 1.234 km → rounded to 1 decimal = 1.2.
      expect(acc.apiDistanceKm, closeTo(1.2, 1e-9));
    });

    test('subsequent absorbBase calls do NOT overwrite existing fields', () {
      // note: every base field uses `??=` — first non-null write wins.
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'SKE',
        'OS_NM': 'First Name',
        'NEW_ADR': 'First Address',
        'GIS_Y_COOR': 37.5,
        'GIS_X_COOR': 127.0,
        'DISTANCE': 1234.0,
      });
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'GSC', // would overwrite SKE
        'OS_NM': 'Second Name',
        'NEW_ADR': 'Second Address',
        'GIS_Y_COOR': 38.0,
        'GIS_X_COOR': 128.0,
        'DISTANCE': 9999.0,
      });
      expect(acc.brandCode, 'SKE');
      expect(acc.name, 'First Name');
      expect(acc.address, 'First Address');
      expect(acc.lat, closeTo(37.5, 1e-9));
      expect(acc.lng, closeTo(127.0, 1e-9));
      expect(acc.apiDistanceKm, closeTo(1.2, 1e-9));
    });

    test('trims whitespace from name and address', () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'OS_NM': '  서울SK  ',
        'NEW_ADR': '\t서울특별시\n',
      });
      expect(acc.name, '서울SK');
      expect(acc.address, '서울특별시');
    });

    test('parses string-encoded coords and distance', () {
      // OPINET often encodes numerics as strings. `_parseDouble` accepts
      // both num and trimmed strings.
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'GIS_Y_COOR': '37.5',
        'GIS_X_COOR': '127.0',
        'DISTANCE': '500',
      });
      expect(acc.lat, closeTo(37.5, 1e-9));
      expect(acc.lng, closeTo(127.0, 1e-9));
      // 500 m → 0.5 km.
      expect(acc.apiDistanceKm, closeTo(0.5, 1e-9));
    });

    test('zero / non-positive DISTANCE is dropped (apiDistanceKm stays null)',
        () {
      // note: source guards `distMeters > 0` — exactly zero or negative
      // is treated as "no distance reported".
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{'DISTANCE': 0});
      expect(acc.apiDistanceKm, isNull);
      acc.absorbBase(<String, dynamic>{'DISTANCE': -10});
      expect(acc.apiDistanceKm, isNull);
    });

    test('missing / null fields leave accumulator state untouched', () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{}); // empty map
      expect(acc.brandCode, isNull);
      expect(acc.name, isNull);
      expect(acc.address, isNull);
      expect(acc.lat, isNull);
      expect(acc.lng, isNull);
      expect(acc.apiDistanceKm, isNull);
    });

    test('non-string / non-num values fall back via toString or null', () {
      // note: brandCode/name/address use `toString()` so non-strings
      // become their default representation. Coords go through
      // `_parseDouble` which only accepts num/String.
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 42, // non-string → toString
        'GIS_Y_COOR': true, // unsupported by _parseDouble → null
        'GIS_X_COOR': <String, dynamic>{}, // unsupported → null
      });
      expect(acc.brandCode, '42');
      expect(acc.lat, isNull);
      expect(acc.lng, isNull);
    });
  });

  group('OpinetStationAccumulator.toStation', () {
    test('returns null when coords are missing', () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'SKE',
        'OS_NM': 'No Coords',
      });
      // No GIS_Y_COOR / GIS_X_COOR fed in.
      expect(acc.toStation(37.5, 127.0), isNull);
    });

    test('returns null when both coords are exactly zero', () {
      // note: documented "bad upstream data — silently dropped".
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'GIS_Y_COOR': 0,
        'GIS_X_COOR': 0,
      });
      expect(acc.toStation(37.5, 127.0), isNull);
    });

    test('returns a Station with id prefix kr-<uniId> and ingested fields',
        () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'SKE',
        'OS_NM': '서울SK주유소',
        'NEW_ADR': '강남구 테헤란로 123',
        'GIS_Y_COOR': 37.5,
        'GIS_X_COOR': 127.0,
        'DISTANCE': 1500, // → 1.5 km
      });
      acc.prices[FuelType.e5] = 1689.0;
      acc.prices[FuelType.diesel] = 1499.0;

      final station = acc.toStation(37.5, 127.0);
      expect(station, isNotNull);
      expect(station!.id, 'kr-A0001');
      expect(station.name, '서울SK주유소');
      expect(station.brand, 'SK에너지'); // mapped from 'SKE'
      expect(station.street, '강남구 테헤란로 123');
      expect(station.postCode, '');
      expect(station.place, '');
      expect(station.lat, closeTo(37.5, 1e-9));
      expect(station.lng, closeTo(127.0, 1e-9));
      expect(station.dist, closeTo(1.5, 1e-9));
      expect(station.e5, closeTo(1689.0, 1e-9));
      expect(station.diesel, closeTo(1499.0, 1e-9));
      expect(station.e98, isNull);
      expect(station.lpg, isNull);
      expect(station.isOpen, isTrue);
    });

    test('falls back to brand label as station name when OS_NM is missing',
        () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'GSC',
        'GIS_Y_COOR': 37.5,
        'GIS_X_COOR': 127.0,
      });
      final station = acc.toStation(37.5, 127.0)!;
      expect(station.name, 'GS칼텍스');
      expect(station.brand, 'GS칼텍스');
    });

    test('uses Independent label when brand code is null / empty / ETC', () {
      for (final code in <Object?>[null, '', 'ETC']) {
        final acc = OpinetStationAccumulator(uniId: 'A0001');
        acc.absorbBase(<String, dynamic>{
          'POLL_DIV_CD': ?code,
          'GIS_Y_COOR': 37.5,
          'GIS_X_COOR': 127.0,
        });
        final station = acc.toStation(37.5, 127.0)!;
        expect(station.brand, 'Independent',
            reason: 'code=$code should map to Independent');
      }
    });

    test('passes through unknown brand code verbatim', () {
      // note: `_brandFromCode` falls through to `default: code` for any
      // unrecognised non-empty string.
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'ZZZ',
        'GIS_Y_COOR': 37.5,
        'GIS_X_COOR': 127.0,
      });
      final station = acc.toStation(37.5, 127.0)!;
      expect(station.brand, 'ZZZ');
    });

    test('maps SOL / HDO / RTO / NHO to Korean brand labels', () {
      const expected = <String, String>{
        'HDO': '현대오일뱅크',
        'SOL': 'S-OIL',
        'RTO': '알뜰주유소',
        'NHO': 'NH농협',
      };
      expected.forEach((code, label) {
        final acc = OpinetStationAccumulator(uniId: 'A0001');
        acc.absorbBase(<String, dynamic>{
          'POLL_DIV_CD': code,
          'GIS_Y_COOR': 37.5,
          'GIS_X_COOR': 127.0,
        });
        final station = acc.toStation(37.5, 127.0)!;
        expect(station.brand, label, reason: 'code $code');
      });
    });

    test(
        'uses haversine fallback distance when API DISTANCE is missing or zero',
        () {
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      // Station ~5 km north of origin; no DISTANCE field given.
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'SKE',
        'GIS_Y_COOR': 37.5450, // ~5 km north of 37.5
        'GIS_X_COOR': 127.0,
      });
      final station = acc.toStation(37.5, 127.0)!;
      // Haversine should land in the 4.5–5.5 km band, rounded to 1 dp.
      expect(station.dist, inInclusiveRange(4.5, 5.5));
    });

    test('uses API-provided distance when present (no haversine fallback)',
        () {
      // note: API distance has 1-dp precision applied at absorb time
      // (e.g. 1500 m → 1.5 km), and is preferred over the haversine
      // fallback when non-null.
      final acc = OpinetStationAccumulator(uniId: 'A0001');
      acc.absorbBase(<String, dynamic>{
        'POLL_DIV_CD': 'SKE',
        'GIS_Y_COOR': 38.0, // would haversine to ~55 km
        'GIS_X_COOR': 127.0,
        'DISTANCE': 1500, // but API says 1.5 km
      });
      final station = acc.toStation(37.5, 127.0)!;
      expect(station.dist, closeTo(1.5, 1e-9));
    });
  });

  group('mergeOpinetProductResponse', () {
    test('non-map top-level payload throws ApiException', () {
      final byId = <String, OpinetStationAccumulator>{};
      expect(
        () => mergeOpinetProductResponse('garbage', byId, FuelType.e5),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('unparseable'))),
      );
      expect(
        () => mergeOpinetProductResponse(<dynamic>[], byId, FuelType.e5),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => mergeOpinetProductResponse(null, byId, FuelType.e5),
        throwsA(isA<ApiException>()),
      );
    });

    test('OPINET ERROR field at top level throws ApiException', () {
      final byId = <String, OpinetStationAccumulator>{};
      expect(
        () => mergeOpinetProductResponse(
          <String, dynamic>{'ERROR': 'AUTH_FAIL'},
          byId,
          FuelType.e5,
        ),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('AUTH_FAIL'),
        )),
      );
    });

    test('missing RESULT or non-map RESULT is tolerated (no-op)', () {
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{},
        byId,
        FuelType.e5,
      );
      mergeOpinetProductResponse(
        <String, dynamic>{'RESULT': 'oops'},
        byId,
        FuelType.e5,
      );
      expect(byId, isEmpty);
    });

    test('RESULT.OIL missing or non-list is tolerated (no-op)', () {
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{},
        },
        byId,
        FuelType.e5,
      );
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{'OIL': 'oops'},
        },
        byId,
        FuelType.e5,
      );
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{'OIL': <dynamic>[]},
        },
        byId,
        FuelType.e5,
      );
      expect(byId, isEmpty);
    });

    test('absorbs a single OPINET row into the accumulator', () {
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'POLL_DIV_CD': 'SKE',
                'OS_NM': '서울SK',
                'NEW_ADR': '강남구',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': '1689',
              },
            ],
          },
        },
        byId,
        FuelType.e5,
      );
      expect(byId, hasLength(1));
      final acc = byId['A0001']!;
      expect(acc.uniId, 'A0001');
      expect(acc.brandCode, 'SKE');
      expect(acc.lat, closeTo(37.5, 1e-9));
      expect(acc.prices[FuelType.e5], closeTo(1689.0, 1e-9));
    });

    test('merges multiple product responses into the same UNI_ID', () {
      final byId = <String, OpinetStationAccumulator>{};
      // First call: gasoline.
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'POLL_DIV_CD': 'SKE',
                'OS_NM': '서울SK',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': '1689',
              },
            ],
          },
        },
        byId,
        FuelType.e5,
      );
      // Second call: diesel — same station.
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'POLL_DIV_CD': 'GSC', // would overwrite, but ??= protects
                'GIS_Y_COOR': 38.0,
                'GIS_X_COOR': 128.0,
                'PRICE': '1499',
              },
            ],
          },
        },
        byId,
        FuelType.diesel,
      );
      expect(byId, hasLength(1));
      final acc = byId['A0001']!;
      expect(acc.brandCode, 'SKE'); // unchanged from first absorb
      expect(acc.lat, closeTo(37.5, 1e-9));
      expect(acc.prices[FuelType.e5], closeTo(1689.0, 1e-9));
      expect(acc.prices[FuelType.diesel], closeTo(1499.0, 1e-9));
    });

    test('duplicate rows for the same product code: last write wins on price',
        () {
      // note: source iterates in order; `acc.prices[fuelType] = price`
      // is a plain map write, so a second valid row for the same fuel
      // overwrites the first.
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'POLL_DIV_CD': 'SKE',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': '1600',
              },
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'POLL_DIV_CD': 'SKE',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': '1700',
              },
            ],
          },
        },
        byId,
        FuelType.e5,
      );
      expect(byId['A0001']!.prices[FuelType.e5], closeTo(1700.0, 1e-9));
    });

    test('non-map and non-id rows are skipped silently', () {
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              'nope',
              42,
              null,
              <String, dynamic>{}, // missing UNI_ID
              <String, dynamic>{'UNI_ID': ''}, // empty UNI_ID
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': '1689',
              },
            ],
          },
        },
        byId,
        FuelType.e5,
      );
      expect(byId.keys, ['A0001']);
      expect(byId['A0001']!.prices[FuelType.e5], closeTo(1689.0, 1e-9));
    });

    test('zero / negative / blank PRICE is dropped — accumulator base still set',
        () {
      // note: `_parseWonPerLitre` filters out 0, negative, blank, and
      // unparseable strings. The row's identity / coords still land via
      // `absorbBase`, just no price is added.
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': 0,
              },
              <String, dynamic>{
                'UNI_ID': 'A0002',
                'GIS_Y_COOR': 37.6,
                'GIS_X_COOR': 127.1,
                'PRICE': '-5',
              },
              <String, dynamic>{
                'UNI_ID': 'A0003',
                'GIS_Y_COOR': 37.7,
                'GIS_X_COOR': 127.2,
                'PRICE': '   ',
              },
              <String, dynamic>{
                'UNI_ID': 'A0004',
                'GIS_Y_COOR': 37.8,
                'GIS_X_COOR': 127.3,
                'PRICE': 'TBD',
              },
              <String, dynamic>{
                'UNI_ID': 'A0005',
                'GIS_Y_COOR': 37.9,
                'GIS_X_COOR': 127.4,
                // no PRICE field at all
              },
            ],
          },
        },
        byId,
        FuelType.e5,
      );
      expect(byId.keys.toList()..sort(),
          ['A0001', 'A0002', 'A0003', 'A0004', 'A0005']);
      for (final acc in byId.values) {
        expect(acc.prices[FuelType.e5], isNull,
            reason: '${acc.uniId} should have no e5 price');
      }
    });

    test('numeric PRICE (num, not string) is accepted', () {
      final byId = <String, OpinetStationAccumulator>{};
      mergeOpinetProductResponse(
        <String, dynamic>{
          'RESULT': <String, dynamic>{
            'OIL': <dynamic>[
              <String, dynamic>{
                'UNI_ID': 'A0001',
                'GIS_Y_COOR': 37.5,
                'GIS_X_COOR': 127.0,
                'PRICE': 1689, // int
              },
              <String, dynamic>{
                'UNI_ID': 'A0002',
                'GIS_Y_COOR': 37.6,
                'GIS_X_COOR': 127.1,
                'PRICE': 1499.5, // double
              },
            ],
          },
        },
        byId,
        FuelType.diesel,
      );
      expect(byId['A0001']!.prices[FuelType.diesel], closeTo(1689.0, 1e-9));
      expect(byId['A0002']!.prices[FuelType.diesel], closeTo(1499.5, 1e-9));
    });

    test('full four-call merge → toStation produces a Station with all fuels',
        () {
      // End-to-end: simulate the four product-code calls the service
      // makes and confirm a single Station materialises with all four
      // prices, the right brand, and address from the first payload.
      final byId = <String, OpinetStationAccumulator>{};
      Map<String, dynamic> envelope(double price) => <String, dynamic>{
            'RESULT': <String, dynamic>{
              'OIL': <dynamic>[
                <String, dynamic>{
                  'UNI_ID': 'A0001',
                  'POLL_DIV_CD': 'SKE',
                  'OS_NM': '서울SK주유소',
                  'NEW_ADR': '강남구 테헤란로 1',
                  'GIS_Y_COOR': 37.5,
                  'GIS_X_COOR': 127.0,
                  'DISTANCE': 1500,
                  'PRICE': price,
                },
              ],
            },
          };
      mergeOpinetProductResponse(envelope(1689), byId, FuelType.e5);
      mergeOpinetProductResponse(envelope(1900), byId, FuelType.e98);
      mergeOpinetProductResponse(envelope(1499), byId, FuelType.diesel);
      mergeOpinetProductResponse(envelope(1099), byId, FuelType.lpg);

      expect(byId, hasLength(1));
      final station = byId['A0001']!.toStation(37.5, 127.0)!;
      expect(station.id, 'kr-A0001');
      expect(station.brand, 'SK에너지');
      expect(station.name, '서울SK주유소');
      expect(station.street, '강남구 테헤란로 1');
      expect(station.dist, closeTo(1.5, 1e-9));
      expect(station.e5, closeTo(1689.0, 1e-9));
      expect(station.e98, closeTo(1900.0, 1e-9));
      expect(station.diesel, closeTo(1499.0, 1e-9));
      expect(station.lpg, closeTo(1099.0, 1e-9));
      expect(station.isOpen, isTrue);
    });
  });
}
