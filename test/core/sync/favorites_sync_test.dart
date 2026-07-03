// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/favorites_sync.dart';

/// Contract tests for [FavoritesSync] (#727 extract — retires the
/// former SyncService). Pins the unauthenticated guard, plus the #3452
/// record-shape invariants ([FavoriteKind] routing).
void main() {
  group('FavoritesSync auth guards', () {
    test('merge returns the input records unchanged when unauthenticated',
        () async {
      final local = [
        const FavoriteRecord(id: 'st-1', kind: FavoriteKind.fuel),
        const FavoriteRecord(
            id: 'st-2', kind: FavoriteKind.fuel, data: {'name': 'Shell'}),
        const FavoriteRecord(id: 'ocm-3', kind: FavoriteKind.ev),
      ];
      final result = await FavoritesSync.merge(local);
      expect(result, equals(local));
    });

    test('merge handles an empty list without errors', () async {
      final result = await FavoritesSync.merge(const <FavoriteRecord>[]);
      expect(result, isEmpty);
    });

    test('delete is a no-op when unauthenticated', () async {
      await FavoritesSync.delete('st-1');
    });
  });

  group('FavoriteKind.of (#3452/#3455 routing guard)', () {
    test('an ocm-* id is ALWAYS ev, even when the column says fuel', () {
      expect(FavoriteKind.of(id: 'ocm-196522', wire: 'fuel'),
          FavoriteKind.ev);
      expect(FavoriteKind.of(id: 'ocm-196522'), FavoriteKind.ev);
    });

    test('fuel ids follow the wire kind, defaulting to fuel', () {
      expect(FavoriteKind.of(id: 'fr-1', wire: 'ev'), FavoriteKind.ev);
      expect(FavoriteKind.of(id: 'fr-1', wire: 'fuel'), FavoriteKind.fuel);
      expect(FavoriteKind.of(id: 'de-2'), FavoriteKind.fuel);
      expect(FavoriteKind.of(id: 'de-2', wire: 'garbage'), FavoriteKind.fuel);
    });
  });
}
