// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4309 — Italy stamps `priceUpdatedAt` from the full MIMIT `dtComu`.
///
/// IT declares `priceTimestamp: true`, but `priceUpdatedAt` was
/// `DateTime.tryParse` of the `dd/MM HH:mm` display label, which carries
/// no year and never parses — so the freshness gate saw no price age for
/// any Italian station. These tests pin the parser, the persisted-dataset
/// codec (including data written before the raw stamp existed), and the
/// REAL service over the recorded CSV slices.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/italy/mise_dataset.dart';

import '../support/recorded_country_search.dart';

void main() {
  group('parseMiseDtComu (#4309)', () {
    test('a recorded dtComu parses to its wall-clock fields', () {
      expect(parseMiseDtComu('04/06/2026 07:44:20'),
          DateTime(2026, 6, 4, 7, 44, 20));
    });

    test('day-first: 08/06 is the 8th of June, not the 6th of August', () {
      expect(parseMiseDtComu('08/06/2026 23:13:55')!.month, 6);
    });

    test('seconds are optional; surrounding whitespace is ignored', () {
      expect(parseMiseDtComu(' 04/06/2026 07:44 '), DateTime(2026, 6, 4, 7, 44));
    });

    test('missing input is null', () {
      expect(parseMiseDtComu(null), isNull);
      expect(parseMiseDtComu(''), isNull);
      expect(parseMiseDtComu('   '), isNull);
    });

    test('malformed input is null, never a guessed date', () {
      for (final raw in [
        '04/06 07:44', // the display label — no year
        '29/03/2026', // no time
        '2026-06-04 07:44:20', // ISO, not the MIMIT shape
        '4/6/2026 7:44:20', // unpadded
        '31/02/2026 10:00:00', // no 31 February (DateTime would roll over)
        '04/13/2026 10:00:00', // month 13
        '04/06/2026 24:00:00', // hour 24
        'Estrazione del 2026-06-09',
      ]) {
        expect(parseMiseDtComu(raw), isNull, reason: raw);
      }
    });
  });

  group('MisePriceData persistence (#4309)', () {
    test('the raw stamp round-trips and yields the instant', () {
      final data = MisePriceData()
        ..benzinaSelf = 1.929
        ..updatedAt = '04/06 07:44'
        ..updatedAtRaw = '04/06/2026 07:44:20';
      final back = MisePriceData.fromJson(data.toJson());
      expect(back.updatedAtRaw, '04/06/2026 07:44:20');
      expect(back.updatedAt, '04/06 07:44');
      expect(back.priceUpdatedAt, DateTime(2026, 6, 4, 7, 44, 20));
    });

    test('a dataset persisted before #4309 still loads, with no timestamp',
        () {
      // The exact pre-#4309 shape: the label under 'u', no 'ur' key.
      final legacy = deserializeMiseDataset({
        's': {
          '4384': {
            'b': 'Shell', 't': 'Stradale', 'n': 'SHELL STAZIONE BS',
            'a': 'Statale 42', 'c': 'SONICO', 'pv': 'BS',
            'la': 46.137, 'lo': 10.35,
          },
        },
        'p': {
          '4384': {'bs': 1.929, 'bv': 2.149, 'u': '04/06 07:44'},
        },
      });
      expect(legacy, isNotNull);
      final prices = legacy!.$2['4384']!;
      expect(prices.benzinaSelf, 1.929);
      expect(prices.updatedAt, '04/06 07:44',
          reason: 'the display label survives');
      expect(prices.updatedAtRaw, isNull);
      expect(prices.priceUpdatedAt, isNull,
          reason: 'no raw stamp → an absent age until the next download, '
              'never a label parsed into a guess');
    });
  });

  group('the REAL service over the recorded MIMIT slices (#4309)', () {
    late List<Station> stations;

    setUpAll(() async {
      stations = await searchItalyStations(
        anagraficaCsv:
            File('test/fixtures/it_anagrafica_slice.csv').readAsStringSync(),
        prezzoCsv:
            File('test/fixtures/it_prezzo_slice.csv').readAsStringSync(),
        params: const SearchParams(lat: 41.9, lng: 12.5, radiusKm: 700),
      );
    });

    Station byId(String id) => stations.singleWhere((s) => s.id == id);

    test('every recorded station carries a priceUpdatedAt', () {
      expect(stations, isNotEmpty);
      for (final s in stations) {
        expect(s.priceUpdatedAt, isNotNull, reason: s.id);
      }
    });

    test('the instant and the label describe the same stamp', () {
      final s = byId('it-4384');
      expect(s.priceUpdatedAt, DateTime(2026, 6, 4, 7, 44, 20));
      expect(s.updatedAt, '04/06 07:44');
    });

    test('the NEWEST row stamp wins, compared as instants', () {
      // 23778: Benzina 08/06 23:13:55 is listed BEFORE Gasolio 07:58:13 /
      // 07:56:08. The old string compare of the raw stamp against the
      // stored label kept the older 07:58.
      final s = byId('it-23778');
      expect(s.priceUpdatedAt, DateTime(2026, 6, 8, 23, 13, 55));
      expect(s.updatedAt, '08/06 23:13');
    });
  });
}
