import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';

void main() {
  group('ApiException', () {
    test('can be created with message only', () {
      const e = ApiException(message: 'Server error');
      expect(e.message, 'Server error');
      expect(e.statusCode, isNull);
    });

    test('can be created with message and statusCode', () {
      const e = ApiException(message: 'Not found', statusCode: 404);
      expect(e.message, 'Not found');
      expect(e.statusCode, 404);
    });

    test('toString includes message and status', () {
      const e = ApiException(message: 'Timeout', statusCode: 504);
      expect(e.toString(), 'ApiException: Timeout (status: 504)');
    });

    test('toString shows null status when not provided', () {
      const e = ApiException(message: 'Oops');
      expect(e.toString(), 'ApiException: Oops (status: null)');
    });

    test('implements Exception', () {
      const e = ApiException(message: 'test');
      expect(e, isA<Exception>());
    });
  });

  group('CacheException', () {
    test('can be created with message', () {
      const e = CacheException(message: 'Cache corrupted');
      expect(e.message, 'Cache corrupted');
    });

    test('implements Exception', () {
      const e = CacheException(message: 'test');
      expect(e, isA<Exception>());
    });
  });

  group('LocationException', () {
    test('can be created with message', () {
      const e = LocationException(message: 'GPS unavailable');
      expect(e.message, 'GPS unavailable');
    });

    test('implements Exception', () {
      const e = LocationException(message: 'test');
      expect(e, isA<Exception>());
    });
  });

  group('NoApiKeyException', () {
    test('can be created', () {
      const e = NoApiKeyException();
      expect(e, isA<Exception>());
    });

    test('toString returns descriptive message', () {
      const e = NoApiKeyException();
      expect(
        e.toString(),
        'No API key configured. Please set up your Tankerkoenig API key.',
      );
    });
  });

  group('ServiceChainExhaustedException', () {
    test('can be created with empty errors', () {
      const e = ServiceChainExhaustedException(errors: []);
      expect(e.errors, isEmpty);
    });

    test('stores errors list', () {
      final errors = [
        const ApiException(message: 'timeout'),
        const CacheException(message: 'miss'),
      ];
      final e = ServiceChainExhaustedException(errors: errors);
      expect(e.errors.length, 2);
      expect(e.errors[0], isA<ApiException>());
      expect(e.errors[1], isA<CacheException>());
    });

    test('toString with empty errors shows generic message', () {
      const e = ServiceChainExhaustedException(errors: []);
      expect(e.toString(), 'All services unavailable.');
    });

    test('toString with errors lists each error', () {
      const e = ServiceChainExhaustedException(errors: [
        ApiException(message: 'down', statusCode: 500),
        CacheException(message: 'empty'),
      ]);
      final str = e.toString();
      expect(str, startsWith('All services failed:'));
      expect(str, contains('ApiException: down (status: 500)'));
      expect(str, contains('CacheException'));
    });

    test('implements Exception', () {
      const e = ServiceChainExhaustedException(errors: []);
      expect(e, isA<Exception>());
    });
  });

  group('Sealed AppException hierarchy', () {
    test('all exception types are AppException', () {
      expect(const ApiException(message: 'x'), isA<AppException>());
      expect(const CacheException(message: 'x'), isA<AppException>());
      expect(const LocationException(message: 'x'), isA<AppException>());
      expect(const NoApiKeyException(), isA<AppException>());
      expect(
          const ServiceChainExhaustedException(errors: []), isA<AppException>());
    });

    test('all exception types implement Exception', () {
      expect(const ApiException(message: 'x'), isA<Exception>());
      expect(const CacheException(message: 'x'), isA<Exception>());
      expect(const LocationException(message: 'x'), isA<Exception>());
      expect(const NoApiKeyException(), isA<Exception>());
      expect(
          const ServiceChainExhaustedException(errors: []), isA<Exception>());
    });

    test('NoApiKeyException message contains API key', () {
      const e = NoApiKeyException();
      expect(e.message, contains('API key'));
    });

    test('LocationException stores message', () {
      const e = LocationException(message: 'GPS disabled');
      expect(e.message, 'GPS disabled');
    });

    test('CacheException toString includes message', () {
      const e = CacheException(message: 'cache miss');
      expect(e.toString(), 'CacheException: cache miss');
    });

    test('LocationException toString includes message', () {
      const e = LocationException(message: 'GPS off');
      expect(e.toString(), 'LocationException: GPS off');
    });

    test('ServiceChainExhaustedException message with errors', () {
      const e = ServiceChainExhaustedException(errors: ['err1', 'err2']);
      expect(e.message, contains('err1'));
      expect(e.message, contains('err2'));
    });

    test('ServiceChainExhaustedException with empty errors', () {
      const e = ServiceChainExhaustedException(errors: []);
      expect(e.message, 'All services unavailable.');
    });

    test('switch on AppException is exhaustive', () {
      final exceptions = <AppException>[
        const ApiException(message: 'a'),
        const CacheException(message: 'b'),
        const LocationException(message: 'c'),
        const NoApiKeyException(),
        const NoEvApiKeyException(),
        const ServiceChainExhaustedException(errors: []),
      ];
      for (final e in exceptions) {
        // This switch must compile - proves exhaustiveness of sealed class
        final result = switch (e) {
          ApiException() => 'api',
          CacheException() => 'cache',
          LocationException() => 'location',
          NoApiKeyException() => 'nokey',
          NoEvApiKeyException() => 'noevkey',
          ServiceChainExhaustedException() => 'chain',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
