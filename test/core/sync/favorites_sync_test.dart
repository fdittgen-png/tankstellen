import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/favorites_sync.dart';

/// Contract tests for [FavoritesSync] (#727 extract — retires the
/// former SyncService). Pins the unauthenticated guard.
void main() {
  group('FavoritesSync auth guards', () {
    test('merge returns the input list unchanged when unauthenticated',
        () async {
      final local = ['st-1', 'st-2', 'st-3'];
      final result = await FavoritesSync.merge(local);
      expect(result, equals(local));
    });

    test('merge handles an empty list without errors', () async {
      final result = await FavoritesSync.merge(const <String>[]);
      expect(result, isEmpty);
    });

    test('delete is a no-op when unauthenticated', () async {
      await FavoritesSync.delete('st-1');
    });
  });
}
