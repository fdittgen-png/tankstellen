import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/user_data_sync.dart';

/// Contract tests for [UserDataSync] (#727 extract — retires the
/// former SyncService).
void main() {
  group('UserDataSync auth guards', () {
    test('fetchAll returns an error payload when unauthenticated',
        () async {
      final data = await UserDataSync.fetchAll();
      expect(data.containsKey('error'), isTrue);
      expect(data['error'], contains('Not authenticated'));
    });

    test('deleteAll is a no-op when unauthenticated', () async {
      // Silent on failure by design — shouldn't throw, shouldn't
      // leave the process in a bad state.
      await UserDataSync.deleteAll();
    });
  });
}
