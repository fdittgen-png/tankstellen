// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4309 — Romania stamps `priceUpdatedAt` from the day-first `updatedate`.
///
/// RO declares `priceTimestamp: true`, but `priceUpdatedAt` was
/// `DateTime.tryParse("11/06/2026 00:19")`, which returns null — so the
/// freshness gate saw no price age for any Romanian station. These tests
/// pin the explicit parser and the REAL service over the recorded slices.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/romania/romania_response_parser.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/recorded_country_search.dart';

void main() {
  silenceErrorLoggerSpool();

  group('parseMonitorulUpdateDate (#4309)', () {
    test('a recorded updatedate (with its trailing space) parses', () {
      expect(parseMonitorulUpdateDate('11/06/2026 00:19 '),
          DateTime(2026, 6, 11, 0, 19));
    });

    test('day-first: 10/06 is the 10th of June, not the 6th of October', () {
      expect(parseMonitorulUpdateDate('10/06/2026 22:30')!.month, 6);
    });

    test('a trailing :ss is tolerated', () {
      expect(parseMonitorulUpdateDate('10/06/2026 20:05:30'),
          DateTime(2026, 6, 10, 20, 5, 30));
    });

    test('missing input is null', () {
      expect(parseMonitorulUpdateDate(null), isNull);
      expect(parseMonitorulUpdateDate(''), isNull);
      expect(parseMonitorulUpdateDate('  '), isNull);
    });

    test('malformed input is null, never a guessed date', () {
      for (final raw in [
        '11/06 00:19', // no year
        '11/06/2026', // no time
        '2026-06-11 00:19', // ISO, not the observatory shape
        '1/6/2026 0:19', // unpadded
        '30/02/2026 10:00', // no 30 February (DateTime would roll over)
        '11/13/2026 10:00', // month 13
        '11/06/2026 10:60', // minute 60
        'yesterday',
      ]) {
        expect(parseMonitorulUpdateDate(raw), isNull, reason: raw);
      }
    });
  });

  group('the REAL service over the recorded Monitorul slices (#4309)', () {
    late List<Station> stations;

    setUpAll(() async {
      stations = await searchRomaniaStations(
        recordedBodyByProductId: {
          '11': File('test/fixtures/ro_monitorul_benzina_standard_slice.json')
              .readAsStringSync(),
          '21': File('test/fixtures/ro_monitorul_motorina_standard_slice.json')
              .readAsStringSync(),
        },
        emptyProductIds: const {'12', '22', '31'},
        params: const SearchParams(lat: 44.43, lng: 26.10, radiusKm: 5),
      );
    });

    test('every recorded station carries a priceUpdatedAt', () {
      expect(stations, hasLength(3));
      for (final s in stations) {
        expect(s.priceUpdatedAt, isNotNull, reason: s.id);
      }
    });

    test('the instant matches the recorded stamp; the label is unchanged',
        () {
      final s = stations.singleWhere((s) => s.id == 'ro-041B11');
      expect(s.priceUpdatedAt, DateTime(2026, 6, 11, 0, 19));
      expect(s.updatedAt, '11/06/2026 00:19');
    });
  });
}
