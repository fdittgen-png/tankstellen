import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/error_reporting/error_report_formatter.dart';
import 'package:tankstellen/core/error_reporting/error_report_payload.dart';
import 'package:tankstellen/core/services/service_result.dart';

ErrorReportPayload _payload({
  String errorType = 'ApiException',
  String errorMessage = 'Test error message',
  int? statusCode,
  String? countryCode,
  String? sourceLabel,
  List<String> fallbackChain = const [],
}) {
  return ErrorReportPayload(
    errorType: errorType,
    errorMessage: errorMessage,
    statusCode: statusCode,
    countryCode: countryCode,
    sourceLabel: sourceLabel,
    fallbackChain: fallbackChain,
    appVersion: '4.3.0+4062',
    platform: 'Android',
    locale: 'fr_FR',
    capturedAt: DateTime.utc(2026, 4, 15, 8, 46),
  );
}

void main() {
  group('ErrorReportFormatter.buildTitle', () {
    test('uses source label + error type when no status code', () {
      final title = ErrorReportFormatter.buildTitle(
        _payload(
          sourceLabel: 'CMA Fuel Finder',
          errorType: 'ApiException',
          errorMessage: 'Server timeout',
        ),
      );
      expect(title, 'bug: CMA Fuel Finder — Server timeout');
    });

    test('includes HTTP status when available', () {
      final title = ErrorReportFormatter.buildTitle(
        _payload(
          sourceLabel: 'CMA Fuel Finder',
          errorType: 'ApiException',
          statusCode: 404,
        ),
      );
      expect(title, 'bug: CMA Fuel Finder — ApiException (HTTP 404)');
    });

    test('falls back to country code when source label is missing', () {
      final title = ErrorReportFormatter.buildTitle(
        _payload(
          countryCode: 'gb',
          errorType: 'ApiException',
          statusCode: 500,
        ),
      );
      expect(title, 'bug: GB — ApiException (HTTP 500)');
    });

    test('truncates long error messages by falling back to type', () {
      final title = ErrorReportFormatter.buildTitle(
        _payload(
          sourceLabel: 'Foo',
          errorType: 'ApiException',
          errorMessage: 'x' * 200,
        ),
      );
      expect(title, 'bug: Foo — ApiException');
    });
  });

  group('ErrorReportFormatter.buildBody', () {
    test('renders a markdown body with all core fields', () {
      final body = ErrorReportFormatter.buildBody(
        _payload(
          sourceLabel: 'CMA Fuel Finder',
          errorType: 'ApiException',
          statusCode: 404,
          countryCode: 'gb',
          errorMessage: 'Not found',
        ),
      );

      expect(body, contains('## What happened'));
      expect(body, contains('Not found'));
      expect(body, contains('## Environment'));
      expect(body, contains('- **App version:** 4.3.0+4062'));
      expect(body, contains('- **Platform:** Android'));
      expect(body, contains('- **Locale:** fr_FR'));
      expect(body, contains('- **Country API:** GB'));
      expect(body, contains('- **Source:** CMA Fuel Finder'));
      expect(body, contains('- **HTTP status:** 404'));
      expect(body, contains('- **Captured at:** 2026-04-15T08:46:00.000Z'));
      expect(body, contains('## Steps to reproduce'));
      expect(body, contains('No GPS, API keys, or personal data'));
    });

    test('body never contains GPS coordinates', () {
      // Even if an error message accidentally has lat/lng-looking numbers,
      // they are preserved (we don't lie about what happened), but the
      // body must never ADD coordinates on its own.
      final body = ErrorReportFormatter.buildBody(_payload());
      expect(body, isNot(contains('latitude')));
      expect(body, isNot(contains('longitude')));
    });

    test('body never contains API key field labels', () {
      final body = ErrorReportFormatter.buildBody(_payload());
      expect(body, isNot(contains('apiKey')));
      expect(body, isNot(contains('api_key')));
      expect(body.toLowerCase(), isNot(contains('authorization')));
    });

    test('includes fallback chain section when present', () {
      final body = ErrorReportFormatter.buildBody(
        _payload(
          fallbackChain: [
            'CMA Fuel Finder: 404 (status 404)',
            'Cache: empty',
          ],
        ),
      );
      expect(body, contains('## Fallback chain'));
      expect(body, contains('- CMA Fuel Finder: 404 (status 404)'));
      expect(body, contains('- Cache: empty'));
    });

    test('omits fallback chain section when empty', () {
      final body = ErrorReportFormatter.buildBody(_payload());
      expect(body, isNot(contains('## Fallback chain')));
    });
  });

  group('ErrorReportFormatter.buildIssueUrl', () {
    test('targets github issues/new for the correct repo', () {
      final url = ErrorReportFormatter.buildIssueUrl(_payload());
      expect(url.toString(), startsWith(AppConstants.githubRepoUrl));
      expect(url.path, endsWith('/issues/new'));
    });

    test('passes title, body, and labels as query params', () {
      final url = ErrorReportFormatter.buildIssueUrl(
        _payload(
          sourceLabel: 'CMA Fuel Finder',
          statusCode: 404,
          errorType: 'ApiException',
        ),
      );
      expect(url.queryParameters['labels'], 'type/bug,needs-triage');
      expect(
        url.queryParameters['title'],
        'bug: CMA Fuel Finder — ApiException (HTTP 404)',
      );
      expect(url.queryParameters['body'], contains('## What happened'));
    });

    test('does NOT set a template query param (#506)', () {
      // GitHub ignores ?body= whenever ?template= is present, so the
      // reporter must never pass a template — otherwise the rich body
      // built by buildBody silently never reaches the issue form.
      final url = ErrorReportFormatter.buildIssueUrl(_payload());
      expect(url.queryParameters.containsKey('template'), isFalse);
    });

    test('body query param matches buildBody output verbatim (#506)', () {
      final payload = _payload(
        sourceLabel: 'CMA Fuel Finder',
        statusCode: 404,
        errorType: 'ApiException',
      );
      final url = ErrorReportFormatter.buildIssueUrl(payload);
      expect(
        url.queryParameters['body'],
        ErrorReportFormatter.buildBody(payload),
      );
    });

    test('body query param is non-trivially populated (#506)', () {
      // Regression guard: if a future refactor drops body again, this
      // test will fire before the bug reaches users.
      final url = ErrorReportFormatter.buildIssueUrl(
        _payload(
          sourceLabel: 'CMA Fuel Finder',
          statusCode: 404,
          errorMessage: 'Upstream 404',
        ),
      );
      final body = url.queryParameters['body']!;
      expect(body.length, greaterThan(200));
      expect(body, contains('## What happened'));
      expect(body, contains('## Environment'));
      expect(body, contains('App version'));
    });

    test('url-encodes the title and body safely', () {
      final url = ErrorReportFormatter.buildIssueUrl(
        _payload(
          sourceLabel: 'Foo & Bar',
          errorType: 'X',
          errorMessage: 'Line 1\nLine 2 & stuff',
        ),
      );
      // The sanitizer collapses newlines into spaces before the body is
      // built, and Uri.replace handles URL encoding for us.
      final raw = url.toString();
      expect(raw, isNot(contains('\n')));
      expect(raw, contains('%26')); // '&' encoded
    });
  });

  group('ErrorReportPayload.fromError', () {
    test('extracts status code from ApiException', () {
      final payload = ErrorReportPayload.fromError(
        const ApiException(message: 'Not found', statusCode: 404),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );
      expect(payload.statusCode, 404);
      expect(payload.errorType, 'ApiException');
    });

    test('sanitizes newlines and control chars out of the message', () {
      final payload = ErrorReportPayload.fromError(
        const ApiException(message: 'Line 1\n\nLine 2\tmore'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );
      expect(payload.errorMessage, isNot(contains('\n')));
      expect(payload.errorMessage, isNot(contains('\t')));
      expect(payload.errorMessage, contains('Line 1'));
      expect(payload.errorMessage, contains('Line 2'));
    });

    test('truncates very long messages', () {
      final long = 'x' * 1000;
      final payload = ErrorReportPayload.fromError(
        ApiException(message: long),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );
      expect(payload.errorMessage.length, lessThanOrEqualTo(500));
      expect(payload.errorMessage, endsWith('…'));
    });

    test('unrolls a ServiceChainExhaustedException into fallbackChain', () {
      final chain = ServiceChainExhaustedException(
        errors: [
          ServiceError(
            source: ServiceSource.ukApi,
            message: 'HTTP 404',
            statusCode: 404,
            occurredAt: DateTime.utc(2026, 4, 15, 8, 0),
          ),
          ServiceError(
            source: ServiceSource.cache,
            message: 'empty',
            occurredAt: DateTime.utc(2026, 4, 15, 8, 1),
          ),
        ],
      );
      final payload = ErrorReportPayload.fromError(
        chain,
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
      );
      expect(payload.fallbackChain, hasLength(2));
      expect(payload.fallbackChain.first, contains('CMA Fuel Finder'));
      expect(payload.fallbackChain.first, contains('HTTP 404'));
      expect(payload.fallbackChain.first, contains('status 404'));
      expect(payload.sourceLabel, 'CMA Fuel Finder');
      expect(payload.statusCode, 404);
    });

    test('passes country code through as-is', () {
      final payload = ErrorReportPayload.fromError(
        const ApiException(message: 'x'),
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en_US',
        countryCode: 'GB',
      );
      expect(payload.countryCode, 'GB');
    });
  });
}
