// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/background/daily_collection.dart';

void main() {
  group('stationsToCollect (#2212)', () {
    test('always includes favorites and active alerts', () {
      final ids = stationsToCollect(
        favorites: ['f1', 'f2'],
        alerts: ['a1'],
        viewed: const [],
        collectedToday: (_) => false,
      );
      expect(ids.toSet(), {'f1', 'f2', 'a1'});
    });

    test('includes a viewed station only when not yet collected today', () {
      final ids = stationsToCollect(
        favorites: const [],
        alerts: const [],
        viewed: ['v1', 'v2'],
        collectedToday: (id) => id == 'v1', // v1 already has today's record
      );
      expect(ids, ['v2']);
    });

    test('viewed station collected daily, then skipped same day', () {
      // Before today's record: included.
      expect(
        stationsToCollect(
            favorites: const [],
            alerts: const [],
            viewed: ['v1'],
            collectedToday: (_) => false),
        ['v1'],
      );
      // After today's record: skipped.
      expect(
        stationsToCollect(
            favorites: const [],
            alerts: const [],
            viewed: ['v1'],
            collectedToday: (_) => true),
        isEmpty,
      );
    });

    test('de-dups across favorites / alerts / viewed', () {
      final ids = stationsToCollect(
        favorites: ['s1'],
        alerts: ['s1'],
        viewed: ['s1'],
        collectedToday: (_) => false,
      );
      expect(ids, ['s1']);
    });

    test('favorites are refreshed even if already collected today', () {
      // collectedToday only gates `viewed`; favorites always included.
      final ids = stationsToCollect(
        favorites: ['f1'],
        alerts: const [],
        viewed: ['f1'],
        collectedToday: (_) => true,
      );
      expect(ids, ['f1']);
    });
  });

  group('isSameDay', () {
    test('true for same calendar day, false across midnight', () {
      expect(isSameDay(DateTime(2026, 5, 29, 0, 1), DateTime(2026, 5, 29, 23, 59)),
          isTrue);
      expect(isSameDay(DateTime(2026, 5, 29, 23, 59), DateTime(2026, 5, 30, 0, 1)),
          isFalse);
    });
  });
}
