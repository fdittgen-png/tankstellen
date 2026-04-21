import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/ratings_sync.dart';

/// Shape-only contract tests for [RatingsSync] (#727 extract).
///
/// The real behaviour talks to Supabase; the only surface a pure
/// unit test can exercise without a live client is the
/// client-null / user-null auth guard that gates every method.
/// Higher-fidelity tests live under
/// `test/core/data/supabase_sync_repository_test.dart`.
void main() {
  group('RatingsSync auth guards', () {
    test('upsert is a no-op when TankSync client is not configured',
        () async {
      // No throw, no return value to check — success is that the
      // early-return on `client == null` actually fires.
      await RatingsSync.upsert('st-1', 4);
    });

    test('upsert honours the shared flag signature', () async {
      // Signature regression guard: the shared named arg was
      // renamed from `SyncService.syncRating`'s identical parameter.
      // Any future rename would break this call site.
      await RatingsSync.upsert('st-1', 5, shared: true);
    });

    test('delete is a no-op when unauthenticated', () async {
      await RatingsSync.delete('st-1');
    });

    test('fetchAll returns an empty map when unauthenticated', () async {
      final map = await RatingsSync.fetchAll();
      expect(map, isEmpty);
    });
  });
}
