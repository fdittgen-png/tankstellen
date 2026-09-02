// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/favorites/domain/stale_price_policy.dart';

void main() {
  // A mid-month Tuesday at noon — nothing lands on a month boundary.
  final now = DateTime(2026, 9, 1, 12, 0);

  group('kStalePriceThreshold (#3905)', () {
    test('is pinned to 7 days', () {
      expect(kStalePriceThreshold, const Duration(days: 7));
    });
  });

  group('isStalePrice', () {
    test('a 6-day-old ISO stamp is NOT stale', () {
      final stamp = now.subtract(const Duration(days: 6)).toIso8601String();
      expect(isStalePrice(stamp, now: now), isFalse);
    });

    test('an 8-day-old ISO stamp IS stale', () {
      final stamp = now.subtract(const Duration(days: 8)).toIso8601String();
      expect(isStalePrice(stamp, now: now), isTrue);
    });

    test('exactly 7 days is the last fresh instant (strictly older = stale)',
        () {
      final exact = now.subtract(kStalePriceThreshold).toIso8601String();
      expect(isStalePrice(exact, now: now), isFalse);
      final justOver = now
          .subtract(kStalePriceThreshold + const Duration(minutes: 1))
          .toIso8601String();
      expect(isStalePrice(justOver, now: now), isTrue);
    });

    test('the French year-less "dd/MM HH:mm" form six weeks back is stale',
        () {
      // The reported case: "Mis à jour 16/07 11:00" read on 1 September.
      expect(isStalePrice('16/07 11:00', now: now), isTrue);
      expect(isStalePrice('27/07 09:08', now: now), isTrue);
    });

    test('a year-less stamp two days back is fresh', () {
      expect(isStalePrice('30/08 09:08', now: now), isFalse);
    });

    test('null / unknown shapes never flag (no false "old price")', () {
      expect(isStalePrice(null, now: now), isFalse);
      expect(isStalePrice('', now: now), isFalse);
      expect(isStalePrice('gestern', now: now), isFalse);
      expect(isStalePrice('99/99 00:00', now: now), isFalse);
    });
  });

  group('parseStationUpdatedAt', () {
    test('reads ISO-8601 with offset (fixture form)', () {
      final parsed = parseStationUpdatedAt(
        '2026-03-27T10:00:00+01:00',
        now: now,
      );
      expect(parsed, isNotNull);
      expect(parsed!.isAtSameMomentAs(DateTime.utc(2026, 3, 27, 9)), isTrue);
    });

    test('reads dd/MM/yyyy with and without a time', () {
      expect(
        parseStationUpdatedAt('16/07/2026 11:00', now: now),
        DateTime(2026, 7, 16, 11, 0),
      );
      expect(
        parseStationUpdatedAt('16/07/2026', now: now),
        DateTime(2026, 7, 16),
      );
      expect(
        parseStationUpdatedAt('16.07.2026 11:00', now: now),
        DateTime(2026, 7, 16, 11, 0),
      );
    });

    test('year-less dd/MM resolves to this year when not in the future', () {
      expect(
        parseStationUpdatedAt('16/07 11:00', now: now),
        DateTime(2026, 7, 16, 11, 0),
      );
    });

    test('year-less dd/MM after today resolves to LAST year', () {
      // "28/12 09:00" read on 3 January is the previous December.
      final january = DateTime(2027, 1, 3, 8, 0);
      expect(
        parseStationUpdatedAt('28/12 09:00', now: january),
        DateTime(2026, 12, 28, 9, 0),
      );
      expect(isStalePrice('28/12 09:00', now: january), isFalse);
    });

    test('rejects impossible calendar fields instead of rolling over', () {
      expect(parseStationUpdatedAt('31/02 10:00', now: now), isNull);
      expect(parseStationUpdatedAt('10/13/2026', now: now), isNull);
      expect(parseStationUpdatedAt('16/07 25:00', now: now), isNull);
    });
  });
}
