import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart' as et;
import 'package:tankstellen/core/telemetry/pii_scrubber.dart';

void main() {
  group('PiiScrubber.scrubText', () {
    test('returns null for null input', () {
      expect(PiiScrubber.scrubText(null), isNull);
    });

    test('returns empty string unchanged', () {
      expect(PiiScrubber.scrubText(''), '');
    });

    test('leaves typical exception messages intact', () {
      const msg = 'Cache miss for key prices_de_44.5_8.2 — falling back';
      // The coordinate-shaped substring 44.5_8.2 is underscore-separated, not
      // comma-separated, so it is not a coordinate match. The trailing word
      // "44.5_8.2" is too short for token redaction.
      final out = PiiScrubber.scrubText(msg);
      // Some scrubbing may still happen (token rule) but the human-readable
      // English text must be preserved.
      expect(out, contains('Cache miss for key'));
      expect(out, contains('falling back'));
    });

    test('redacts a single email', () {
      const msg = 'Failed to authenticate user foo.bar+baz@example.co.uk on /sync';
      final out = PiiScrubber.scrubText(msg)!;
      expect(out, contains(PiiScrubber.emailMarker));
      expect(out, isNot(contains('foo.bar+baz@example.co.uk')));
      expect(out, isNot(contains('foo.bar')));
    });

    test('redacts multiple emails in one string', () {
      const msg = 'cc list: alice@a.com, bob@b.org, carol@c.io';
      final out = PiiScrubber.scrubText(msg)!;
      expect(out, isNot(contains('alice@a.com')));
      expect(out, isNot(contains('bob@b.org')));
      expect(out, isNot(contains('carol@c.io')));
      // Three replacements expected.
      expect(PiiScrubber.emailMarker.allMatches(out).length, 3);
    });

    test('redacts a lat/lng pair', () {
      const msg = 'Last known location: 48.8566, 2.3522 (Paris)';
      final out = PiiScrubber.scrubText(msg)!;
      expect(out, contains(PiiScrubber.coordMarker));
      expect(out, isNot(contains('48.8566')));
      expect(out, isNot(contains('2.3522')));
    });

    test('redacts multiple coordinate pairs', () {
      const msg = 'route: 48.8566, 2.3522 -> -33.8688, 151.2093 done';
      final out = PiiScrubber.scrubText(msg)!;
      expect(PiiScrubber.coordMarker.allMatches(out).length, 2);
    });

    test('redacts token-like alphanumeric strings (>=20 chars)', () {
      const tok = 'AbCdEfGhIjKlMnOpQrStUv1234'; // 26 chars
      final out = PiiScrubber.scrubText('Bearer $tok expired')!;
      expect(out, contains(PiiScrubber.tokenMarker));
      expect(out, isNot(contains(tok)));
    });

    test('does NOT redact short identifiers (<20 chars)', () {
      const msg = 'station_id=DE-12345 missing';
      final out = PiiScrubber.scrubText(msg);
      expect(out, equals(msg));
    });

    test('combined: email + coord + token in one message', () {
      const msg =
          'user a@b.co at 48.8566, 2.3522 with token ZZZZZZZZZZZZZZZZZZZZZZZZZZ';
      final out = PiiScrubber.scrubText(msg)!;
      expect(out, contains(PiiScrubber.emailMarker));
      expect(out, contains(PiiScrubber.coordMarker));
      expect(out, contains(PiiScrubber.tokenMarker));
      expect(out, isNot(contains('a@b.co')));
      expect(out, isNot(contains('48.8566')));
    });
  });

  group('PiiScrubber.scrubBreadcrumbMessage', () {
    test('truncates messages longer than the cap', () {
      final long = 'x' * (PiiScrubber.maxBreadcrumbMessageLength + 1);
      expect(PiiScrubber.scrubBreadcrumbMessage(long),
          equals(PiiScrubber.truncatedMarker));
    });

    test('keeps short messages but still scrubs them', () {
      const msg = 'tap on user@example.com';
      final out = PiiScrubber.scrubBreadcrumbMessage(msg)!;
      expect(out, contains(PiiScrubber.emailMarker));
      expect(out, isNot(contains('user@example.com')));
    });

    test('returns null for null input', () {
      expect(PiiScrubber.scrubBreadcrumbMessage(null), isNull);
    });
  });

  group('PiiScrubber.scrubSentryEvent', () {
    test('strips event.user and event.request', () {
      final event = SentryEvent()
        ..user = SentryUser(
          id: 'abc',
          email: 'leak@example.com',
          ipAddress: '203.0.113.7',
        )
        ..request = SentryRequest(
          url: 'https://api.example.com/secret',
          queryString: 'q=foo',
        );

      final scrubbed = PiiScrubber.scrubSentryEvent(event);
      expect(scrubbed.user, isNull);
      expect(scrubbed.request, isNull);
    });

    test('redacts email in exception value', () {
      final event = SentryEvent(exceptions: [
        SentryException(
          type: 'StateError',
          value: 'No profile for owner@gmail.com — re-auth needed',
        ),
      ]);

      final scrubbed = PiiScrubber.scrubSentryEvent(event);
      expect(scrubbed.exceptions, isNotEmpty);
      final value = scrubbed.exceptions!.first.value!;
      expect(value, contains(PiiScrubber.emailMarker));
      expect(value, isNot(contains('owner@gmail.com')));
    });

    test('redacts coord in event.message', () {
      final event = SentryEvent(
        message: SentryMessage('crash near 48.8566, 2.3522'),
      );

      final scrubbed = PiiScrubber.scrubSentryEvent(event);
      expect(scrubbed.message!.formatted, contains(PiiScrubber.coordMarker));
      expect(scrubbed.message!.formatted, isNot(contains('48.8566')));
    });

    test('truncates long breadcrumb messages and scrubs short ones', () {
      final long = 'route=${'a' * 600}';
      final event = SentryEvent(breadcrumbs: [
        Breadcrumb(message: long, timestamp: DateTime.now()),
        Breadcrumb(
          message: 'tap user@example.com',
          timestamp: DateTime.now(),
        ),
      ]);

      final scrubbed = PiiScrubber.scrubSentryEvent(event);
      expect(scrubbed.breadcrumbs![0].message, PiiScrubber.truncatedMarker);
      expect(scrubbed.breadcrumbs![1].message,
          contains(PiiScrubber.emailMarker));
    });

    test('leaves typical exception untouched (no PII shape)', () {
      final event = SentryEvent(exceptions: [
        SentryException(type: 'FormatException', value: 'Unexpected token <'),
      ]);
      final scrubbed = PiiScrubber.scrubSentryEvent(event);
      expect(scrubbed.exceptions!.first.value, 'Unexpected token <');
    });
  });

  group('PiiScrubber.scrubErrorTrace', () {
    test('redacts errorMessage, appState fields, attempts, breadcrumbs', () {
      final trace = et.ErrorTrace(
        id: 'id-1',
        timestamp: DateTime.utc(2026, 1, 1),
        timezoneOffset: '+00:00',
        category: et.ErrorCategory.unknown,
        errorType: 'Exception',
        errorMessage: 'login failed for x@y.com',
        stackTrace: '#0 main',
        deviceInfo: const et.DeviceInfo(
          os: 'test',
          osVersion: '1',
          platform: 'test',
          locale: 'en',
          screenWidth: 400,
          screenHeight: 800,
          appVersion: '1',
        ),
        appState: const et.AppStateSnapshot(
          activeRoute: '/profile/owner@example.com',
          lastApiEndpoint:
              'https://api.example.com?token=ZZZZZZZZZZZZZZZZZZZZZZZZZZ',
          lastSearchParams: 'q=Paris @ 48.8566, 2.3522',
        ),
        serviceChainState: et.ServiceChainSnapshot(attempts: [
          et.ServiceAttempt(
            serviceName: 'tankerkoenig',
            succeeded: false,
            errorMessage: '401 for user a@b.co',
            attemptedAt: DateTime.utc(2026, 1, 1),
          ),
        ]),
        networkState: const et.NetworkSnapshot(isOnline: true),
        breadcrumbs: [
          et.Breadcrumb(
            timestamp: DateTime.utc(2026, 1, 1),
            action: 'tap',
            detail: 'visited /map @ 48.8566, 2.3522',
          ),
        ],
      );

      final scrubbed = PiiScrubber.scrubErrorTrace(trace);

      expect(scrubbed.errorMessage, contains(PiiScrubber.emailMarker));
      expect(scrubbed.errorMessage, isNot(contains('x@y.com')));

      expect(scrubbed.appState.activeRoute, contains(PiiScrubber.emailMarker));
      expect(scrubbed.appState.lastApiEndpoint,
          contains(PiiScrubber.tokenMarker));
      expect(scrubbed.appState.lastSearchParams,
          contains(PiiScrubber.coordMarker));

      expect(scrubbed.serviceChainState!.attempts.first.errorMessage,
          contains(PiiScrubber.emailMarker));

      expect(scrubbed.breadcrumbs.first.detail,
          contains(PiiScrubber.coordMarker));
    });

    test('preserves stackTrace verbatim', () {
      final trace = et.ErrorTrace(
        id: 'id-2',
        timestamp: DateTime.utc(2026, 1, 1),
        timezoneOffset: '+00:00',
        category: et.ErrorCategory.unknown,
        errorType: 'Exception',
        errorMessage: 'plain',
        stackTrace:
            '#0 PathStuff (package:tankstellen/foo/bar/baz_handler.dart:123)',
        deviceInfo: const et.DeviceInfo(
          os: 'test',
          osVersion: '1',
          platform: 'test',
          locale: 'en',
          screenWidth: 400,
          screenHeight: 800,
          appVersion: '1',
        ),
        appState: const et.AppStateSnapshot(),
        networkState: const et.NetworkSnapshot(isOnline: true),
      );

      final scrubbed = PiiScrubber.scrubErrorTrace(trace);
      expect(scrubbed.stackTrace, trace.stackTrace);
    });

    test('handles null serviceChainState', () {
      final trace = et.ErrorTrace(
        id: 'id-3',
        timestamp: DateTime.utc(2026, 1, 1),
        timezoneOffset: '+00:00',
        category: et.ErrorCategory.unknown,
        errorType: 'Exception',
        errorMessage: 'plain',
        stackTrace: '#0 main',
        deviceInfo: const et.DeviceInfo(
          os: 'test',
          osVersion: '1',
          platform: 'test',
          locale: 'en',
          screenWidth: 400,
          screenHeight: 800,
          appVersion: '1',
        ),
        appState: const et.AppStateSnapshot(),
        networkState: const et.NetworkSnapshot(isOnline: true),
      );

      final scrubbed = PiiScrubber.scrubErrorTrace(trace);
      expect(scrubbed.serviceChainState, isNull);
    });
  });
}
