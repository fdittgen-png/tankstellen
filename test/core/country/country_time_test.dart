// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_time.dart';

void main() {
  // Fixed instants well inside / outside the EU DST window.
  final summerUtc = DateTime.utc(2026, 6, 10, 12, 0); // June — DST active
  final winterUtc = DateTime.utc(2026, 1, 15, 12, 0); // January — standard

  group('utcOffsetMinutesFor (#3198)', () {
    test('CET countries: +60 winter, +120 summer', () {
      for (final c in ['DE', 'FR', 'AT', 'IT', 'ES', 'DK', 'LU', 'SI']) {
        expect(utcOffsetMinutesFor(c, winterUtc), 60, reason: c);
        expect(utcOffsetMinutesFor(c, summerUtc), 120, reason: c);
      }
    });

    test('WET countries (PT/GB): 0 winter, +60 summer', () {
      for (final c in ['PT', 'GB']) {
        expect(utcOffsetMinutesFor(c, winterUtc), 0, reason: c);
        expect(utcOffsetMinutesFor(c, summerUtc), 60, reason: c);
      }
    });

    test('EET countries (GR/RO): +120 winter, +180 summer', () {
      for (final c in ['GR', 'RO']) {
        expect(utcOffsetMinutesFor(c, winterUtc), 120, reason: c);
        expect(utcOffsetMinutesFor(c, summerUtc), 180, reason: c);
      }
    });

    test('fixed-offset countries never shift', () {
      expect(utcOffsetMinutesFor('KR', winterUtc), 9 * 60);
      expect(utcOffsetMinutesFor('KR', summerUtc), 9 * 60);
      expect(utcOffsetMinutesFor('AR', winterUtc), -3 * 60);
      expect(utcOffsetMinutesFor('AR', summerUtc), -3 * 60);
      expect(utcOffsetMinutesFor('MX', winterUtc), -6 * 60);
      expect(utcOffsetMinutesFor('MX', summerUtc), -6 * 60);
    });

    test('southern-hemisphere DST is inverted (CL, AU)', () {
      // January is southern summer; June is southern winter.
      expect(utcOffsetMinutesFor('CL', winterUtc), -3 * 60);
      expect(utcOffsetMinutesFor('CL', summerUtc), -4 * 60);
      expect(utcOffsetMinutesFor('AU', winterUtc), 11 * 60);
      expect(utcOffsetMinutesFor('AU', summerUtc), 10 * 60);
    });

    test('EU DST boundary: last Sunday of March 2026 at 01:00 UTC', () {
      // 2026-03-29 is the last Sunday of March.
      final before = DateTime.utc(2026, 3, 29, 0, 59);
      final after = DateTime.utc(2026, 3, 29, 1, 0);
      expect(utcOffsetMinutesFor('DE', before), 60);
      expect(utcOffsetMinutesFor('DE', after), 120);
    });

    test('EU DST boundary: last Sunday of October 2026 at 01:00 UTC', () {
      // 2026-10-25 is the last Sunday of October.
      final before = DateTime.utc(2026, 10, 25, 0, 59);
      final after = DateTime.utc(2026, 10, 25, 1, 0);
      expect(utcOffsetMinutesFor('DE', before), 120);
      expect(utcOffsetMinutesFor('DE', after), 60);
    });

    test('unknown / null country code → null (caller falls back)', () {
      expect(utcOffsetMinutesFor('XX', summerUtc), isNull);
      expect(utcOffsetMinutesFor(null, summerUtc), isNull);
    });
  });

  group('nowInCountry (#3198)', () {
    test('Seoul is 9h ahead of UTC regardless of season', () {
      final kr = nowInCountry('KR', utcNow: summerUtc);
      expect(kr.hour, 21);
      expect(kr.day, 10);
    });

    test('Berlin reads 14:00 when UTC is 12:00 in June', () {
      final de = nowInCountry('DE', utcNow: summerUtc);
      expect(de.hour, 14);
    });

    test('weekday rolls over with the offset', () {
      // 2026-06-10 23:30 UTC is already Thursday 08:30 in Seoul.
      final lateUtc = DateTime.utc(2026, 6, 10, 23, 30);
      final kr = nowInCountry('KR', utcNow: lateUtc);
      expect(kr.weekday, DateTime.thursday);
      expect(kr.hour, 8);
    });

    test('unknown country falls back to the device-local instant', () {
      final local = nowInCountry('XX', utcNow: summerUtc);
      expect(local, summerUtc.toLocal());
    });
  });
}
