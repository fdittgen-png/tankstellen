import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter/error_reporter_context.dart';

/// Helper that hands [ErrorReporterContext.currentLocale] a real
/// BuildContext seeded with the given locale via `Localizations`.
Future<String> _localeFor(
  WidgetTester tester,
  Locale locale,
) async {
  late String captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('fr', 'FR'),
        Locale('en', 'GB'),
        Locale('de'),
        Locale('es'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (ctx) {
          captured = ErrorReporterContext.currentLocale(ctx);
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('ErrorReporterContext.currentLocale', () {
    testWidgets('formats as "language_COUNTRY" when country is set',
        (tester) async {
      expect(await _localeFor(tester, const Locale('fr', 'FR')), 'fr_FR');
      expect(await _localeFor(tester, const Locale('en', 'GB')), 'en_GB');
    });

    testWidgets('falls back to bare language code when country is null',
        (tester) async {
      expect(await _localeFor(tester, const Locale('de')), 'de');
    });

    testWidgets('empty country string collapses to bare language',
        (tester) async {
      expect(await _localeFor(tester, const Locale('es', '')), 'es');
    });
  });

  group('ErrorReporterContext.currentPlatform', () {
    test('returns a non-empty platform label for the host OS', () {
      // Tests run under `flutter test`, which uses the host OS.
      // We don't pin the exact string because tests run on
      // Linux / macOS / Windows CI; the contract is just that it's
      // stable and non-empty so report payloads are never blank.
      final label = ErrorReporterContext.currentPlatform();
      expect(label, isNotEmpty);
      // Happy-path mapping: when host is Android / iOS the label
      // is the nicer name; otherwise it's Platform.operatingSystem.
      if (Platform.isAndroid) {
        expect(label, 'Android');
      } else if (Platform.isIOS) {
        expect(label, 'iOS');
      } else {
        expect(label, Platform.operatingSystem);
      }
    });
  });

  group('ErrorReporterContext.currentAppVersion', () {
    test('delegates to AppConstants.appVersion', () {
      expect(ErrorReporterContext.currentAppVersion(),
          AppConstants.appVersion);
    });

    test('is non-empty so a report payload always has a version', () {
      expect(ErrorReporterContext.currentAppVersion(), isNotEmpty);
    });
  });
}
