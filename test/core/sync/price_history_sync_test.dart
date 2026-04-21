import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/price_history_sync.dart';

/// Shape-only smoke tests for [PriceHistorySync] (#727 extract).
///
/// The method wraps a Supabase query; the ONLY behaviour this test
/// can exercise without a live Supabase stack is the "client is
/// null → return empty list" guard. That guard is the contract the
/// rest of the codebase depends on (see
/// `supabase_sync_repository_test.dart` for the same test at the
/// repository layer) — any refactor that loses it is a regression.
///
/// Tests that require a real Supabase client live under
/// `test/core/data/sync_repository_test.dart` with a `@Tags(['network'])`
/// guard; we don't duplicate those here.
void main() {
  group('PriceHistorySync', () {
    test('returns empty list when TankSync client is not configured',
        () async {
      // TankSyncClient isn't initialised in unit-test context, so
      // `.client` resolves to null and `.fetch` takes the early return.
      final rows = await PriceHistorySync.fetch('st-1');
      expect(rows, isEmpty);
    });

    test('honours custom days parameter without throwing', () async {
      // Days is passed to the server-side filter; the client-null guard
      // still kicks in first. Any widening of the guard that breaks the
      // named argument would trip this test.
      final rows = await PriceHistorySync.fetch('st-1', days: 7);
      expect(rows, isEmpty);
    });
  });
}
