// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter/error_report_payload.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter/error_reporter.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../helpers/silence_error_logger.dart';

ErrorReportPayload _samplePayload() => ErrorReportPayload(
      errorType: 'ApiException',
      errorMessage: 'Not found',
      statusCode: 404,
      sourceLabel: 'CMA Fuel Finder',
      countryCode: 'GB',
      fallbackChain: const [],
      appVersion: '4.3.0+4062',
      platform: 'Android',
      locale: 'en_US',
      capturedAt: DateTime.utc(2026, 4, 15, 8, 46),
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  silenceErrorLoggerSpool();
  // The #1606 dedup ring buffer is process-static — reset it before
  // every test so a fingerprint recorded by one test does not bleed
  // into the next.
  setUp(ErrorReporter.resetDedupRingForTest);

  group('ErrorReporter.consentPreview', () {
    test('lists source, error type, status, app, platform, locale', () {
      final preview = ErrorReporter.consentPreview(_samplePayload());
      expect(preview, contains('Source: CMA Fuel Finder'));
      expect(preview, contains('Error: ApiException'));
      expect(preview, contains('HTTP: 404'));
      expect(preview, contains('App: 4.3.0+4062'));
      expect(preview, contains('Platform: Android'));
      expect(preview, contains('Locale: en_US'));
    });

    test('omits source and status when missing', () {
      final preview = ErrorReporter.consentPreview(
        ErrorReportPayload(
          errorType: 'X',
          errorMessage: 'y',
          appVersion: '4.3.0',
          platform: 'Android',
          locale: 'en',
          capturedAt: DateTime.utc(2026, 4, 15),
        ),
      );
      expect(preview, isNot(contains('Source:')));
      expect(preview, isNot(contains('HTTP:')));
      expect(preview, contains('Error: X'));
    });
  });

  group('ErrorReporter.reportError consent flow', () {
    testWidgets('does not launch URL when user cancels', (tester) async {
      Uri? launched;
      final reporter = ErrorReporter(
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      );

      late BuildContext captured;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox();
      })));

      final future =
          reporter.reportError(captured, _samplePayload());
      await tester.pumpAndSettle();

      // Dialog is up — tap Cancel.
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open GitHub'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await future, isFalse);
      expect(launched, isNull);
    });

    testWidgets('launches URL when user confirms', (tester) async {
      Uri? launched;
      final reporter = ErrorReporter(
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      );

      late BuildContext captured;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox();
      })));

      final future =
          reporter.reportError(captured, _samplePayload());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open GitHub'));
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(launched, isNotNull);
      expect(launched!.toString(), contains('issues/new'));
      expect(
        launched!.queryParameters['title'],
        contains('CMA Fuel Finder'),
      );
    });

    testWidgets('skips dialog when requireConsent is false', (tester) async {
      // This path exists only for tests and debug builds — production
      // code must always leave `requireConsent` at its default of true.
      Uri? launched;
      final reporter = ErrorReporter(
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      );

      late BuildContext captured;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox();
      })));

      final ok = await reporter.reportError(
        captured,
        _samplePayload(),
        requireConsent: false,
      );
      await tester.pumpAndSettle();

      expect(ok, isTrue);
      expect(launched, isNotNull);
    });

    testWidgets('returns false when the launcher throws', (tester) async {
      final reporter = ErrorReporter(
        launcher: (_) async => throw StateError('boom'),
      );

      late BuildContext captured;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox();
      })));

      final ok = await reporter.reportError(
        captured,
        _samplePayload(),
        requireConsent: false,
      );
      expect(ok, isFalse);
    });
  });

  group('ErrorReporter client-side dedup (#1606)', () {
    testWidgets('reporting the same error twice composes only one URL',
        (tester) async {
      final launched = <Uri>[];
      final reporter = ErrorReporter(launcher: (uri) async {
        launched.add(uri);
        return true;
      });

      late BuildContext captured;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox();
      })));

      final first = await reporter.reportError(captured, _samplePayload(),
          requireConsent: false);
      await tester.pumpAndSettle();
      final second = await reporter.reportError(captured, _samplePayload(),
          requireConsent: false);
      await tester.pumpAndSettle();

      expect(first, isTrue, reason: 'the first report launches');
      expect(second, isFalse,
          reason: 'the duplicate is suppressed — no second URL');
      expect(launched, hasLength(1),
          reason: 'only ONE issue URL composed for two identical reports');
      expect(find.text('You already reported this issue.'), findsOneWidget);
    });

    test('the dedup ring records a fingerprint only after a launch', () async {
      final fp = _samplePayload().fingerprint;
      expect(ErrorReporter.hasRecentlyReported(fp), isFalse);
    });

    testWidgets('a different error is not blocked by the dedup ring',
        (tester) async {
      final launched = <Uri>[];
      final reporter = ErrorReporter(launcher: (uri) async {
        launched.add(uri);
        return true;
      });

      late BuildContext captured;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox();
      })));

      await reporter.reportError(captured, _samplePayload(),
          requireConsent: false);
      final other = ErrorReportPayload(
        errorType: 'CacheException',
        errorMessage: 'a different failure',
        appVersion: '4.3.0',
        platform: 'Android',
        locale: 'en',
        capturedAt: DateTime.utc(2026, 4, 15),
      );
      final ok = await reporter.reportError(captured, other,
          requireConsent: false);
      await tester.pumpAndSettle();

      expect(ok, isTrue);
      expect(launched, hasLength(2),
          reason: 'distinct fingerprints each compose their own URL');
    });
  });
}
