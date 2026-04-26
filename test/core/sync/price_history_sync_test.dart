import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/price_history_sync.dart';

/// Shape-only smoke tests for [PriceHistorySync] (#727 extract). Runs
/// fully offline — exercises the "TankSync client is null → return empty
/// list" guard without touching Supabase.
///
/// Live counterpart sits at `test/core/data/sync_repository_test.dart`
/// under `@Tags(['network'])`; rerun that file (not this one) when the
/// `price_snapshots` table schema or the TankSync RPC contract changes.
/// See `docs/guides/NETWORK_TESTS.md`.
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
