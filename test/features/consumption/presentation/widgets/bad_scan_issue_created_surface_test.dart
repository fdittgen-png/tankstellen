import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_issue_created_surface.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [BadScanIssueCreatedSurface] — the confirmation
/// surface shown after a GitHub issue is created from a bad scan
/// report. Refs #561 (zero-coverage backlog).
void main() {
  Future<void> pumpSurface(
    WidgetTester tester, {
    required Uri issueUrl,
    required Future<void> Function() onOpenInBrowser,
    required VoidCallback onClose,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BadScanIssueCreatedSurface(
            issueUrl: issueUrl,
            onOpenInBrowser: onOpenInBrowser,
            onClose: onClose,
          ),
        ),
      ),
    );
  }

  group('BadScanIssueCreatedSurface', () {
    final issueUrl = Uri.parse(
      'https://github.com/example/tankstellen/issues/12345',
    );

    Future<void> noopOpen() async {}
    void noopClose() {}

    testWidgets('renders check_circle icon', (tester) async {
      await pumpSurface(
        tester,
        issueUrl: issueUrl,
        onOpenInBrowser: noopOpen,
        onClose: noopClose,
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders the issueUrl as text', (tester) async {
      await pumpSurface(
        tester,
        issueUrl: issueUrl,
        onOpenInBrowser: noopOpen,
        onClose: noopClose,
      );

      expect(find.text(issueUrl.toString()), findsOneWidget);
    });

    testWidgets(
      'long URL text uses ellipsis overflow with maxLines=2',
      (tester) async {
        final longUrl = Uri.parse(
          'https://github.com/very-long-org-name/very-long-repository-name/'
          'issues/9999999?something=foo&another=bar&yet=baz',
        );

        await pumpSurface(
          tester,
          issueUrl: longUrl,
          onOpenInBrowser: noopOpen,
          onClose: noopClose,
        );

        final textWidget = tester.widget<Text>(
          find.text(longUrl.toString()),
        );
        expect(textWidget.overflow, TextOverflow.ellipsis);
        expect(textWidget.maxLines, 2);
      },
    );

    testWidgets(
      'renders Open in browser FilledButton with open_in_new icon',
      (tester) async {
        await pumpSurface(
          tester,
          issueUrl: issueUrl,
          onOpenInBrowser: noopOpen,
          onClose: noopClose,
        );

        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
        expect(find.text('Open in browser'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Open in browser invokes onOpenInBrowser callback',
      (tester) async {
        var openCalls = 0;
        Future<void> onOpen() async {
          openCalls++;
        }

        await pumpSurface(
          tester,
          issueUrl: issueUrl,
          onOpenInBrowser: onOpen,
          onClose: noopClose,
        );

        await tester.tap(find.text('Open in browser'));
        await tester.pump();

        expect(openCalls, 1);
      },
    );

    testWidgets('renders Close TextButton', (tester) async {
      await pumpSurface(
        tester,
        issueUrl: issueUrl,
        onOpenInBrowser: noopOpen,
        onClose: noopClose,
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets(
      'tapping Close invokes onClose callback',
      (tester) async {
        var closeCalls = 0;
        void onClose() {
          closeCalls++;
        }

        await pumpSurface(
          tester,
          issueUrl: issueUrl,
          onOpenInBrowser: noopOpen,
          onClose: onClose,
        );

        await tester.tap(find.text('Close'));
        await tester.pump();

        expect(closeCalls, 1);
      },
    );
  });
}
