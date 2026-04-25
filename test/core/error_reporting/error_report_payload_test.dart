import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/error_reporting/error_report_payload.dart';
import 'package:tankstellen/core/services/service_result.dart';

void main() {
  group('ErrorReportPayload constructor', () {
    final capturedAt = DateTime.utc(2026, 4, 15, 8, 46);

    test('populates all required fields', () {
      final payload = ErrorReportPayload(
        errorType: 'ApiException',
        errorMessage: 'Server timeout',
        appVersion: '4.3.0+4062',
        platform: 'Android 15 · samsung SM-G998B',
        locale: 'fr_FR',
        capturedAt: capturedAt,
      );

      expect(payload.errorType, 'ApiException');
      expect(payload.errorMessage, 'Server timeout');
      expect(payload.appVersion, '4.3.0+4062');
      expect(payload.platform, 'Android 15 · samsung SM-G998B');
      expect(payload.locale, 'fr_FR');
      expect(payload.capturedAt, capturedAt);
    });

    test('optional fields default to null and empty list', () {
      final payload = ErrorReportPayload(
        errorType: 'Exception',
        errorMessage: 'boom',
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
        capturedAt: capturedAt,
      );

      expect(payload.statusCode, isNull);
      expect(payload.countryCode, isNull);
      expect(payload.sourceLabel, isNull);
      expect(payload.fallbackChain, isEmpty);
      expect(payload.stackExcerpt, isNull);
      expect(payload.networkState, isNull);
      expect(payload.searchContext, isNull);
    });

    test('preserves provided optional fields verbatim', () {
      final payload = ErrorReportPayload(
        errorType: 'ServiceChainExhaustedException',
        errorMessage: 'All services failed',
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'de_DE',
        capturedAt: capturedAt,
        statusCode: 503,
        countryCode: 'DE',
        sourceLabel: 'Tankerkönig API',
        fallbackChain: const <String>[
          'Tankerkönig API: timeout (status 503)',
          'Cache: empty',
        ],
        stackExcerpt: '#0 _Foo (package:tankstellen/foo.dart:42)',
        networkState: 'wifi',
        searchContext: 'GPS search',
      );

      expect(payload.statusCode, 503);
      expect(payload.countryCode, 'DE');
      expect(payload.sourceLabel, 'Tankerkönig API');
      expect(payload.fallbackChain, hasLength(2));
      expect(payload.fallbackChain.first, contains('Tankerkönig'));
      expect(payload.stackExcerpt, contains('package:tankstellen/'));
      expect(payload.networkState, 'wifi');
      expect(payload.searchContext, 'GPS search');
    });
  });

  group('ErrorReportPayload.fromError', () {
    test('captures runtime type and sanitized message for plain exception', () {
      final payload = ErrorReportPayload.fromError(
        Exception('something broke'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      expect(payload.errorType, '_Exception');
      expect(payload.errorMessage, contains('something broke'));
      expect(payload.statusCode, isNull);
      expect(payload.sourceLabel, isNull);
      expect(payload.fallbackChain, isEmpty);
    });

    test('passes through context fields (countryCode, network, search)', () {
      final payload = ErrorReportPayload.fromError(
        const ApiException(message: 'Forbidden', statusCode: 403),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'fr_FR',
        countryCode: 'FR',
        networkState: 'mobile',
        searchContext: 'ZIP search 34120',
      );

      expect(payload.countryCode, 'FR');
      expect(payload.networkState, 'mobile');
      expect(payload.searchContext, 'ZIP search 34120');
    });

    test('extracts statusCode from ApiException', () {
      final payload = ErrorReportPayload.fromError(
        const ApiException(message: 'Not Found', statusCode: 404),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      expect(payload.errorType, 'ApiException');
      expect(payload.statusCode, 404);
      expect(payload.errorMessage, contains('Not Found'));
    });

    test('captures sourceLabel + statusCode + chain from ServiceChainExhaustedException', () {
      final occurredAt = DateTime.utc(2026, 4, 15, 8, 46);
      final exception = ServiceChainExhaustedException(
        errors: [
          ServiceError(
            source: ServiceSource.ukApi,
            message: 'gateway timeout',
            statusCode: 504,
            occurredAt: occurredAt,
          ),
          ServiceError(
            source: ServiceSource.cache,
            message: 'cache miss',
            occurredAt: occurredAt,
          ),
        ],
      );

      final payload = ErrorReportPayload.fromError(
        exception,
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_GB',
      );

      expect(payload.errorType, 'ServiceChainExhaustedException');
      // First service error wins for the "primary" label and status.
      expect(payload.sourceLabel, ServiceSource.ukApi.displayName);
      expect(payload.statusCode, 504);
      expect(payload.fallbackChain, hasLength(2));
      expect(
        payload.fallbackChain.first,
        equals('${ServiceSource.ukApi.displayName}: gateway timeout (status 504)'),
      );
      // Second entry has no statusCode → no parenthesised status suffix.
      expect(payload.fallbackChain.last, equals('${ServiceSource.cache.displayName}: cache miss'));
      // errorMessage collapses to the first chain entry, not the giant
      // "All services failed:\n…" toString().
      expect(payload.errorMessage, payload.fallbackChain.first);
      expect(payload.errorMessage, isNot(contains('All services failed')));
    });

    test('handles ServiceChainExhaustedException with non-ServiceError entries', () {
      final exception = ServiceChainExhaustedException(
        errors: [
          Exception('raw timeout'),
        ],
      );

      final payload = ErrorReportPayload.fromError(
        exception,
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      expect(payload.fallbackChain, hasLength(1));
      expect(payload.fallbackChain.single, contains('raw timeout'));
      // No ServiceError → sourceLabel and statusCode stay null.
      expect(payload.sourceLabel, isNull);
      expect(payload.statusCode, isNull);
      expect(payload.errorMessage, payload.fallbackChain.single);
    });

    test('empty ServiceChainExhaustedException keeps sanitized toString as message', () {
      const exception = ServiceChainExhaustedException(errors: []);

      final payload = ErrorReportPayload.fromError(
        exception,
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      expect(payload.fallbackChain, isEmpty);
      expect(payload.sourceLabel, isNull);
      expect(payload.statusCode, isNull);
      // With no inner errors, message stays the sanitized toString().
      expect(payload.errorMessage, contains('All services unavailable'));
    });

    test('sets capturedAt to roughly the current wall clock', () {
      final before = DateTime.now();
      final payload = ErrorReportPayload.fromError(
        Exception('x'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );
      final after = DateTime.now();

      // Allow generous slack for slow CI hosts.
      expect(payload.capturedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(payload.capturedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('ErrorReportPayload.fromError message sanitization', () {
    test('collapses newlines, carriage returns, and tabs to single spaces', () {
      final payload = ErrorReportPayload.fromError(
        Exception('line one\r\nline two\tcolumn'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      expect(payload.errorMessage, isNot(contains('\n')));
      expect(payload.errorMessage, isNot(contains('\r')));
      expect(payload.errorMessage, isNot(contains('\t')));
      // Multiple whitespace runs collapsed.
      expect(payload.errorMessage, isNot(contains('  ')));
      expect(payload.errorMessage, contains('line one'));
      expect(payload.errorMessage, contains('line two'));
      expect(payload.errorMessage, contains('column'));
    });

    test('truncates messages over 400 chars with an ellipsis', () {
      final huge = 'x' * 600;
      final payload = ErrorReportPayload.fromError(
        Exception(huge),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      // 400 char prefix + a single ellipsis (one rune). Length must be <= 401.
      expect(payload.errorMessage.length, lessThanOrEqualTo(401));
      expect(payload.errorMessage.endsWith('…'), isTrue);
    });

    test('leaves messages at or below 400 chars untouched (no ellipsis)', () {
      final exact = 'a' * 100;
      final payload = ErrorReportPayload.fromError(
        Exception(exact),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );

      expect(payload.errorMessage.endsWith('…'), isFalse);
      expect(payload.errorMessage, contains(exact));
    });
  });

  group('ErrorReportPayload.fromError stack excerpt', () {
    test('returns null when no stack trace provided', () {
      final payload = ErrorReportPayload.fromError(
        Exception('x'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );
      expect(payload.stackExcerpt, isNull);
    });

    test('keeps only package:tankstellen frames', () {
      final trace = StackTrace.fromString(
        '#0 _doSearch (package:tankstellen/features/search/data/repo.dart:120:8)\n'
        '#1 Future._propagate (dart:async/future_impl.dart:715:32)\n'
        '#2 _DioMixin.fetch (package:dio/src/dio_mixin.dart:454:14)\n'
        '#3 _onTap (package:tankstellen/features/search/presentation/screen.dart:42:9)\n',
      );
      final payload = ErrorReportPayload.fromError(
        Exception('boom'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
        stackTrace: trace,
      );

      expect(payload.stackExcerpt, isNotNull);
      final lines = payload.stackExcerpt!.split('\n');
      expect(lines, hasLength(2));
      // Privacy: third-party (dio) and SDK (dart:async) frames must NOT leak.
      expect(payload.stackExcerpt, isNot(contains('package:dio')));
      expect(payload.stackExcerpt, isNot(contains('dart:async')));
      expect(payload.stackExcerpt, contains('package:tankstellen/'));
      // Lines are trimmed (no leading whitespace).
      for (final line in lines) {
        expect(line, isNot(startsWith(' ')));
      }
    });

    test('limits to 8 lines even when many tankstellen frames present', () {
      final lots = List.generate(
        20,
        (i) => '#$i _frame$i (package:tankstellen/foo.dart:$i:1)',
      ).join('\n');
      final payload = ErrorReportPayload.fromError(
        Exception('boom'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
        stackTrace: StackTrace.fromString(lots),
      );

      final lines = payload.stackExcerpt!.split('\n');
      expect(lines, hasLength(8));
      // Order preserved: first eight tankstellen frames.
      expect(lines.first, contains('_frame0'));
      expect(lines.last, contains('_frame7'));
    });

    test('returns null when stack has no tankstellen frames', () {
      final trace = StackTrace.fromString(
        '#0 dart:core/_late_helper.dart:25:9\n'
        '#1 package:dio/src/dio_mixin.dart:1:1\n',
      );
      final payload = ErrorReportPayload.fromError(
        Exception('x'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
        stackTrace: trace,
      );

      expect(payload.stackExcerpt, isNull);
    });
  });

  group('ErrorReportPayload privacy invariants', () {
    test('does NOT carry GPS coords, API keys, or full URLs from third-party stack frames', () {
      // A realistic-but-tainted third-party frame that *would* leak coordinates,
      // a query-string API key, and the full URL if forwarded as-is. Privacy
      // boundary: only `package:tankstellen/` frames make it out.
      final trace = StackTrace.fromString(
        '#0 _DioMixin.fetch (package:dio/src/dio_mixin.dart:454:14) '
        'GET https://creativecommons.tankerkoenig.de/json/list.php'
        '?lat=43.4842&lng=3.4291&apikey=00000000-0000-0000-0000-000000000000\n'
        '#1 _doSearch (package:tankstellen/features/search/data/repo.dart:120:8)\n',
      );

      final payload = ErrorReportPayload.fromError(
        Exception('upstream timeout'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
        stackTrace: trace,
      );

      final excerpt = payload.stackExcerpt ?? '';
      // The dio frame (and its URL/key/coords) is filtered out.
      expect(excerpt, isNot(contains('apikey=')));
      expect(excerpt, isNot(contains('lat=')));
      expect(excerpt, isNot(contains('lng=')));
      expect(excerpt, isNot(contains('https://')));
      expect(excerpt, isNot(contains('package:dio')));
      // The legitimate first-party frame survives.
      expect(excerpt, contains('package:tankstellen/'));
    });

    test('countryCode and locale are present in the payload for support context', () {
      final payload = ErrorReportPayload.fromError(
        const ApiException(message: 'boom', statusCode: 500),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'fr_FR',
        countryCode: 'FR',
      );

      expect(payload.locale, 'fr_FR');
      expect(payload.countryCode, 'FR');
    });
  });
}

