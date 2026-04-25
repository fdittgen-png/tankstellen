import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/feedback/feedback_consent.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter_provider.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parse_result.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_report_sheet.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [BadScanReportSheet].
///
/// Phase 1 (#751) verified the i18n contract. Phase 2 (#952) adds the
/// GitHub-ticket submission path — those tests live here and swap the
/// [githubIssueReporterProvider] with provider overrides.
void main() {
  const outcome = ReceiptScanOutcome(
    parse: ReceiptParseResult(
      liters: 32.5,
      totalCost: 55.12,
      pricePerLiter: 1.695,
      stationName: 'Shell',
      brandLayout: 'generic',
    ),
    ocrText: 'TOTAL 55,12\n32,5 L\nSP95',
    imagePath: '/tmp/fake.jpg',
  );

  const pumpOutcome = PumpDisplayScanOutcome(
    parse: PumpDisplayParseResult(
      liters: 40.0,
      totalCost: 70.0,
      pricePerLiter: 1.75,
      pumpNumber: 3,
      confidence: 0.9,
    ),
    ocrText: 'Betrag 70.00\nAbgabe 40.00\nPreis/L 1.75',
    imagePath: '/tmp/fake-pump.jpg',
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    List<Object> overrides = const [],
    ShareFallback? shareFallback,
    UrlLauncher? urlLauncher,
    ImageBytesReader? imageBytesReader,
    ConsentPrompter? consentPrompter,
    ConsentReader? consentReader,
    ConsentWriter? consentWriter,
    ScanKind kind = ScanKind.receipt,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BadScanReportSheet(
              kind: kind,
              scan: kind == ScanKind.receipt ? outcome : null,
              pumpScan: kind == ScanKind.pumpDisplay ? pumpOutcome : null,
              enteredLiters: 32.5,
              enteredTotalCost: 55.12,
              appVersion: '4.3.0+1',
              shareFallback: shareFallback,
              urlLauncher: urlLauncher,
              imageBytesReader: imageBytesReader,
              consentPrompter: consentPrompter,
              consentReader: consentReader,
              consentWriter: consentWriter,
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> stubImageReader(String path) async =>
      Uint8List.fromList(const [1, 2, 3]);

  group('i18n (phase 1 regression)', () {
    testWidgets('renders the English ARB strings on the en locale',
        (tester) async {
      await pumpSheet(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Report a scan error — Receipt'),
        findsOneWidget,
        reason: '#953 — receipt kind must use the kind-specific title.',
      );
      expect(
        find.textContaining('share the receipt photo'),
        findsOneWidget,
      );
      expect(find.text('Create issue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Table headers
      expect(find.text('Field'), findsOneWidget);
      expect(find.text('Scanned'), findsOneWidget);
      expect(find.text('You typed'), findsOneWidget);
      // Row labels
      expect(find.text('Brand layout'), findsOneWidget);
      expect(find.text('Liters'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Price/L'), findsOneWidget);
      expect(find.text('Station'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('renders the German ARB strings on the de locale',
        (tester) async {
      await pumpSheet(tester, locale: const Locale('de'));
      await tester.pumpAndSettle();

      expect(
        find.text('Scan-Fehler melden — Beleg'),
        findsOneWidget,
        reason: '#953 — German receipt kind also uses kind-specific title.',
      );
      expect(find.text('Ticket erstellen'), findsOneWidget);
      expect(find.text('Feld'), findsOneWidget);
      expect(find.text('Gescannt'), findsOneWidget);
      expect(find.text('Eingegeben'), findsOneWidget);
      expect(find.text('Marken-Layout'), findsOneWidget);
      expect(find.text('Gesamt'), findsOneWidget);
      expect(find.text('Tankstelle'), findsOneWidget);
      expect(find.text('Kraftstoff'), findsOneWidget);
      expect(find.text('Datum'), findsOneWidget);
    });
  });

  group('pump-display kind (#953)', () {
    testWidgets('renders pump-display title on en locale', (tester) async {
      await pumpSheet(tester, kind: ScanKind.pumpDisplay);
      await tester.pumpAndSettle();

      expect(
        find.text('Report a scan error — Pump display'),
        findsOneWidget,
        reason: 'Pump-display kind must use the kind-specific title — '
            'separates pump issues from receipt issues at first glance.',
      );
      // Pump-display kind hides receipt-only diff rows (brand layout,
      // station, fuel, date) — only the three transaction numbers
      // make it onto the diff table.
      expect(find.text('Brand layout'), findsNothing);
      expect(find.text('Station'), findsNothing);
      expect(find.text('Fuel'), findsNothing);
      expect(find.text('Date'), findsNothing);
      // Common rows survive.
      expect(find.text('Liters'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Price/L'), findsOneWidget);
    });

    testWidgets('renders pump-display title on de locale', (tester) async {
      await pumpSheet(
        tester,
        locale: const Locale('de'),
        kind: ScanKind.pumpDisplay,
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan-Fehler melden — Zapfsäule'), findsOneWidget);
    });

    testWidgets(
        'submitting forwards ScanKind.pumpDisplay to the reporter (#953)',
        (tester) async {
      ScanKind? capturedKind;
      final reporter = _FakeReporter(
        onCall: () async =>
            Uri.parse('https://github.com/fdittgen-png/tankstellen/issues/953'),
      );
      reporter.onKindCaptured = (k) => capturedKind = k;

      await pumpSheet(
        tester,
        kind: ScanKind.pumpDisplay,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.granted,
        consentWriter: (_) async {},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        capturedKind,
        ScanKind.pumpDisplay,
        reason: 'GithubIssueReporter must receive ScanKind.pumpDisplay so '
            'the issue title reads "[Scan] Pump display OCR failure".',
      );
      expect(reporter.callCount, 1);
    });
  });

  group('GitHub submission (#952 phase 2)', () {
    testWidgets('reporter success surfaces issue URL + open-in-browser action',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async =>
            Uri.parse('https://github.com/fdittgen-png/tankstellen/issues/42'),
      );
      final launcherCalls = <Uri>[];

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        urlLauncher: (uri) async {
          launcherCalls.add(uri);
          return true;
        },
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.granted,
        consentWriter: (_) async {},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      // Pump enough frames for: read-provider future → read file bytes
      // → call fake reporter → setState. Avoid pumpAndSettle because
      // the in-button spinner animates indefinitely while submitting.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(reporter.callCount, 1);
      expect(
        find.text(
            'https://github.com/fdittgen-png/tankstellen/issues/42'),
        findsOneWidget,
      );
      expect(find.text('Open in browser'), findsOneWidget);

      await tester.tap(find.text('Open in browser'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(launcherCalls, hasLength(1));
      expect(launcherCalls.single.path, endsWith('/42'));
    });

    testWidgets(
        'reporter throws GithubReporterException → SharePlus fallback + snackbar',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async => throw const GithubReporterException(
          'boom',
          statusCode: 500,
        ),
      );
      final sharedParams = <ShareParams>[];

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        shareFallback: (params) async {
          sharedParams.add(params);
        },
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.granted,
        consentWriter: (_) async {},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      // Several frames to drive the async fallback chain through:
      // reporter throws → share() fires → snackbar shows → pop().
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(reporter.callCount, 1);
      expect(sharedParams, hasLength(1));
      expect(
        find.text('Submission failed — manual share'),
        findsOneWidget,
      );
    });

    testWidgets(
        'null reporter (token missing) → SharePlus fallback silently',
        (tester) async {
      final sharedParams = <ShareParams>[];

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => null,
          ),
        ],
        shareFallback: (params) async {
          sharedParams.add(params);
        },
        imageBytesReader: stubImageReader,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(sharedParams, hasLength(1));
      // Silent fallback — no snackbar.
      expect(
        find.text('Submission failed — manual share'),
        findsNothing,
      );
    });
  });

  group('consent gate (#952 phase 3)', () {
    testWidgets(
        'consent unset → user grants → reporter is called and persisted',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async =>
            Uri.parse('https://github.com/fdittgen-png/tankstellen/issues/77'),
      );
      final writes = <FeedbackConsentState>[];
      var promptCount = 0;

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.unset,
        consentWriter: (state) async {
          writes.add(state);
        },
        consentPrompter: (_) async {
          promptCount++;
          return FeedbackConsentChoice.granted;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(promptCount, 1);
      expect(writes, [FeedbackConsentState.granted]);
      expect(reporter.callCount, 1);
      expect(find.text('Open in browser'), findsOneWidget);
    });

    testWidgets(
        'consent unset → user denies → no reporter call, falls back to share',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async =>
            throw StateError('reporter must NOT be called when denied'),
      );
      final sharedParams = <ShareParams>[];
      final writes = <FeedbackConsentState>[];

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        shareFallback: (params) async {
          sharedParams.add(params);
        },
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.unset,
        consentWriter: (state) async {
          writes.add(state);
        },
        consentPrompter: (_) async => FeedbackConsentChoice.denied,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(reporter.callCount, 0);
      expect(writes, [FeedbackConsentState.denied]);
      expect(sharedParams, hasLength(1));
    });

    testWidgets(
        'consent already granted → no prompt, reporter is called',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async =>
            Uri.parse('https://github.com/fdittgen-png/tankstellen/issues/88'),
      );
      var promptCount = 0;
      final writes = <FeedbackConsentState>[];

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.granted,
        consentWriter: (state) async {
          writes.add(state);
        },
        consentPrompter: (_) async {
          promptCount++;
          return FeedbackConsentChoice.granted;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(promptCount, 0);
      expect(writes, isEmpty);
      expect(reporter.callCount, 1);
    });

    testWidgets(
        'consent already denied → no prompt, no reporter call, falls back',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async =>
            throw StateError('reporter must NOT be called when denied'),
      );
      final sharedParams = <ShareParams>[];
      var promptCount = 0;

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        shareFallback: (params) async {
          sharedParams.add(params);
        },
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.denied,
        consentWriter: (_) async {},
        consentPrompter: (_) async {
          promptCount++;
          return FeedbackConsentChoice.granted;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(promptCount, 0);
      expect(reporter.callCount, 0);
      expect(sharedParams, hasLength(1));
    });

    testWidgets(
        'Later → no persistence, falls back, next attempt re-asks',
        (tester) async {
      final reporter = _FakeReporter(
        onCall: () async =>
            throw StateError('reporter must NOT be called on later'),
      );
      final sharedParams = <ShareParams>[];
      final writes = <FeedbackConsentState>[];
      var promptCount = 0;

      await pumpSheet(
        tester,
        overrides: [
          githubIssueReporterProvider.overrideWith(
            (ref) async => reporter,
          ),
        ],
        shareFallback: (params) async {
          sharedParams.add(params);
        },
        imageBytesReader: stubImageReader,
        consentReader: () async => FeedbackConsentState.unset,
        consentWriter: (state) async {
          writes.add(state);
        },
        consentPrompter: (_) async {
          promptCount++;
          return FeedbackConsentChoice.later;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create issue'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(promptCount, 1);
      expect(writes, isEmpty); // "Later" must NOT persist.
      expect(reporter.callCount, 0);
      expect(sharedParams, hasLength(1));
    });
  });
}

// -----------------------------------------------------------------------------
// Test doubles

/// Minimal fake that swaps the real [GithubIssueReporter]'s
/// network-backed [reportBadScan] for an in-memory callback. Extends
/// the real class so the existing provider signature stays unchanged.
class _FakeReporter extends GithubIssueReporter {
  _FakeReporter({required this.onCall})
      : super(
          httpClient: _NoopClient(),
          token: 'fake',
          repoOwner: 'fdittgen-png',
          repoName: 'tankstellen',
        );

  final Future<Uri> Function() onCall;
  int callCount = 0;

  /// Optional sink for the [ScanKind] received by [reportBadScan]. The
  /// pump-display test (#953) uses this to assert the kind crosses the
  /// widget boundary verbatim.
  void Function(ScanKind kind)? onKindCaptured;

  @override
  Future<Uri> reportBadScan({
    required ScanKind kind,
    required String rawOcrText,
    required Map<String, String?> parsedFields,
    required Map<String, String?> userCorrections,
    required Uint8List imageBytes,
    String? userNote,
  }) async {
    callCount++;
    onKindCaptured?.call(kind);
    return await onCall();
  }
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('_NoopClient should not be called by tests');
  }
}
