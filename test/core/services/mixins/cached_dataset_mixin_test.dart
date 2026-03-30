import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/mixins/cached_dataset_mixin.dart';

class _TestCached with CachedDatasetMixin {}

void main() {
  late _TestCached cached;

  setUp(() => cached = _TestCached());

  group('CachedDatasetMixin', () {
    test('isDatasetFresh returns false initially', () {
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), false);
    });

    test('isDatasetFresh returns true after marking refreshed', () {
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
    });

    test('isDatasetFresh returns false after TTL expires', () {
      cached.markDatasetRefreshed();
      // Duration.zero means the data is always stale immediately
      expect(cached.isDatasetFresh(Duration.zero), false);
    });

    test('markDatasetRefreshed can be called multiple times', () {
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
    });

    test('isDatasetFresh with very large TTL returns true after mark', () {
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(days: 365)), true);
    });

    test('separate instances have independent state', () {
      final other = _TestCached();
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
      expect(other.isDatasetFresh(const Duration(minutes: 5)), false);
    });
  });
}
