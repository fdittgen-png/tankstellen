import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';

void main() {
  group('ServiceResult', () {
    test('freshnessLabel shows < 1 min for recent data', () {
      final result = ServiceResult(
        data: 'test',
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(result.freshnessLabel, '< 1 min');
    });

    test('freshnessLabel shows minutes for older data', () {
      final result = ServiceResult(
        data: 'test',
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      );
      expect(result.freshnessLabel, '12 min');
    });

    test('freshnessLabel shows hours for very old data', () {
      final result = ServiceResult(
        data: 'test',
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(result.freshnessLabel, '3 h');
    });

    test('hadFallbacks is false when no errors', () {
      final result = ServiceResult(
        data: 'test',
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
      expect(result.hadFallbacks, false);
    });

    test('hadFallbacks is true when errors present', () {
      final result = ServiceResult(
        data: 'test',
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'timeout',
            occurredAt: DateTime.now(),
          ),
        ],
      );
      expect(result.hadFallbacks, true);
    });

    test('fallbackSummary describes failed services', () {
      final result = ServiceResult(
        data: 'test',
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'timeout',
            occurredAt: DateTime.now(),
          ),
        ],
      );
      expect(
        result.fallbackSummary,
        contains('Tankerkönig API'),
      );
      expect(
        result.fallbackSummary,
        contains('Cache'),
      );
    });
  });

  group('ServiceSource', () {
    test('all sources have display names', () {
      for (final source in ServiceSource.values) {
        expect(source.displayName.isNotEmpty, true);
      }
    });
  });
}
