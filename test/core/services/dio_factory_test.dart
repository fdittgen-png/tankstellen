import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/services/dio_factory.dart';

void main() {
  group('DioFactory.create', () {
    test('sets User-Agent header', () {
      final dio = DioFactory.create();
      expect(dio.options.headers['User-Agent'], AppConstants.userAgent);
    });

    test('uses default connect timeout of 10 seconds', () {
      final dio = DioFactory.create();
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
    });

    test('uses default receive timeout of 10 seconds', () {
      final dio = DioFactory.create();
      expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    });

    test('uses custom timeouts', () {
      final dio = DioFactory.create(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      );
      expect(dio.options.connectTimeout, const Duration(seconds: 30));
      expect(dio.options.receiveTimeout, const Duration(seconds: 60));
    });

    test('sets custom baseUrl', () {
      final dio = DioFactory.create(baseUrl: 'https://api.example.com');
      expect(dio.options.baseUrl, 'https://api.example.com');
    });

    test('uses empty baseUrl by default', () {
      final dio = DioFactory.create();
      expect(dio.options.baseUrl, '');
    });

    test('sets responseType', () {
      final dio = DioFactory.create(responseType: ResponseType.plain);
      expect(dio.options.responseType, ResponseType.plain);
    });

    test('uses default JSON responseType', () {
      final dio = DioFactory.create();
      expect(dio.options.responseType, ResponseType.json);
    });

    test('adds interceptors', () {
      final interceptor = LogInterceptor();
      final dio = DioFactory.create(interceptors: [interceptor]);
      expect(dio.interceptors, contains(interceptor));
    });

    test('adds multiple interceptors', () {
      final interceptor1 = LogInterceptor();
      final interceptor2 = LogInterceptor();
      final dio =
          DioFactory.create(interceptors: [interceptor1, interceptor2]);
      expect(dio.interceptors, contains(interceptor1));
      expect(dio.interceptors, contains(interceptor2));
    });

    test('has no custom interceptors by default', () {
      final dio = DioFactory.create();
      // Dio always has some built-in interceptors, but none of ours
      expect(
          dio.interceptors.whereType<LogInterceptor>().length, equals(0));
    });

    test('returns a Dio instance', () {
      final dio = DioFactory.create();
      expect(dio, isA<Dio>());
    });
  });
}
