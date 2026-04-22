import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/ignored_stations_sync.dart';

/// Contract tests for [IgnoredStationsSync] (#727 extract). The real
/// bidirectional-merge path talks to Supabase; a pure unit test can
/// only exercise the unauthenticated guard. Higher-fidelity coverage
/// lives at the repository layer in
/// `test/core/data/supabase_sync_repository_test.dart`.
void main() {
  group('IgnoredStationsSync auth guards', () {
    test('merge returns the input list unchanged when unauthenticated',
        () async {
      final local = ['st-1', 'st-2', 'st-3'];
      final result = await IgnoredStationsSync.merge(local);
      expect(result, equals(local));
    });

    test('merge handles an empty list without errors', () async {
      final result = await IgnoredStationsSync.merge(const <String>[]);
      expect(result, isEmpty);
    });
  });
}
