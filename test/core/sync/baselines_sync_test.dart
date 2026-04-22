import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/baselines_sync.dart';

/// Contract tests for [BaselinesSync] (#727 extract). The real
/// bidirectional merge talks to Supabase + runs `mergeBaselineJson`;
/// a pure unit test can only exercise the unauthenticated guard
/// (TankSyncClient null → inputs passed through).
void main() {
  group('BaselinesSync auth guards', () {
    test('merge returns the localJson unchanged when unauthenticated',
        () async {
      const localJson = '{"cruise-flat":{"samples":12,"lPer100":6.1}}';
      final result = await BaselinesSync.merge(
        vehicleId: 'veh-1',
        localJson: localJson,
      );
      expect(result, localJson);
    });

    test('merge returns null when localJson is null and unauthenticated',
        () async {
      final result = await BaselinesSync.merge(
        vehicleId: 'veh-1',
        localJson: null,
      );
      expect(result, isNull);
    });

    test('delete is a no-op when unauthenticated', () async {
      // Silent on failure by design — shouldn't throw, shouldn't
      // leave the process in a bad state.
      await BaselinesSync.delete('veh-1');
    });
  });
}
