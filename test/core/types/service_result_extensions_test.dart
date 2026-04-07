import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/types/result.dart';
import 'package:tankstellen/core/types/service_result_extensions.dart';

void main() {
  group('captureServiceResult', () {
    test('returns Success when call succeeds', () async {
      final serviceResult = ServiceResult<int>(
        data: 42,
        source: ServiceSource.cache,
        fetchedAt: DateTime(2024),
      );

      final result = await captureServiceResult(() async => serviceResult);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, same(serviceResult));
      expect(result.valueOrNull!.data, 42);
    });

    test('returns Failure when ServiceChainExhaustedException is thrown',
        () async {
      final errors = [
        ServiceError(
          source: ServiceSource.tankerkoenigApi,
          message: 'timeout',
          occurredAt: DateTime(2024),
        ),
      ];

      final result = await captureServiceResult<int>(
        () async => throw ServiceChainExhaustedException(errors: errors),
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ServiceFailure>());
      expect(result.errorOrNull!.errors, hasLength(1));
      expect(result.errorOrNull!.errors.first.message, 'timeout');
    });

    test('preserves ServiceResult metadata on success', () async {
      final now = DateTime.now();
      final serviceResult = ServiceResult<String>(
        data: 'hello',
        source: ServiceSource.prixCarburantsApi,
        fetchedAt: now,
        isStale: true,
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'fallback',
            occurredAt: now,
          ),
        ],
      );

      final result = await captureServiceResult(() async => serviceResult);

      final value = result.valueOrNull!;
      expect(value.data, 'hello');
      expect(value.source, ServiceSource.prixCarburantsApi);
      expect(value.isStale, isTrue);
      expect(value.hadFallbacks, isTrue);
    });

    test('does not catch non-ServiceChainExhaustedException', () async {
      expect(
        () => captureServiceResult<int>(
          () async => throw const ApiException(message: 'not found', statusCode: 404),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('pattern matching on captured result', () async {
      final serviceResult = ServiceResult<int>(
        data: 10,
        source: ServiceSource.cache,
        fetchedAt: DateTime(2024),
      );

      final result = await captureServiceResult(() async => serviceResult);

      final message = switch (result) {
        Success(:final value) => 'Got ${value.data} from ${value.source.displayName}',
        Failure(:final error) => 'Failed: ${error.message}',
      };

      expect(message, 'Got 10 from Cache');
    });

    test('fold on captured failure', () async {
      final result = await captureServiceResult<int>(
        () async => throw const ServiceChainExhaustedException(errors: []),
      );

      final message = result.fold(
        onSuccess: (sr) => 'data: ${sr.data}',
        onFailure: (f) => 'error: ${f.message}',
      );

      expect(message, contains('All services unavailable'));
    });
  });

  group('ServiceFailure', () {
    test('toString includes message', () {
      const failure = ServiceFailure(message: 'all failed');
      expect(failure.toString(), 'ServiceFailure: all failed');
    });

    test('stores accumulated errors', () {
      final errors = [
        ServiceError(
          source: ServiceSource.tankerkoenigApi,
          message: 'timeout',
          occurredAt: DateTime(2024),
        ),
        ServiceError(
          source: ServiceSource.cache,
          message: 'empty',
          occurredAt: DateTime(2024),
        ),
      ];

      final failure = ServiceFailure(message: 'all failed', errors: errors);
      expect(failure.errors, hasLength(2));
      expect(failure.errors[0].source, ServiceSource.tankerkoenigApi);
      expect(failure.errors[1].source, ServiceSource.cache);
    });

    test('defaults to empty error list', () {
      const failure = ServiceFailure(message: 'no details');
      expect(failure.errors, isEmpty);
    });
  });
}
