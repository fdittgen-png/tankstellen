import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/telemetry/error_classifier.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';

void main() {
  group('ErrorClassifier', () {
    test('classifies DioException connection error as network', () {
      final error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(ErrorClassifier.classify(error), ErrorCategory.network);
    });

    test('classifies DioException timeout as network', () {
      final error = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(ErrorClassifier.classify(error), ErrorCategory.network);
    });

    test('classifies DioException bad response as api', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(ErrorClassifier.classify(error), ErrorCategory.api);
    });

    test('classifies ApiException as api', () {
      const error = ApiException(message: 'test');
      expect(ErrorClassifier.classify(error), ErrorCategory.api);
    });

    test('classifies CacheException as cache', () {
      const error = CacheException(message: 'test');
      expect(ErrorClassifier.classify(error), ErrorCategory.cache);
    });

    test('classifies LocationException as platform', () {
      const error = LocationException(message: 'test');
      expect(ErrorClassifier.classify(error), ErrorCategory.platform);
    });

    test('classifies ServiceChainExhaustedException as serviceChain', () {
      const error = ServiceChainExhaustedException(errors: []);
      expect(ErrorClassifier.classify(error), ErrorCategory.serviceChain);
    });

    test('classifies unknown error as unknown', () {
      expect(ErrorClassifier.classify(Exception('random')), ErrorCategory.unknown);
    });
  });
}
