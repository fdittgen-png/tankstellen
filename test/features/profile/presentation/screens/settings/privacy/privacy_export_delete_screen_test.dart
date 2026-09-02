// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_export_actions.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_export_delete_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../../helpers/pump_app.dart';
import '../../../../../../mocks/mocks.dart';
import 'privacy_test_support.dart';

/// #3912 (Epic #3907) — "Export or delete": the format chooser routes to
/// the right export, the error-log row keeps its size-gated export
/// (#1301) and clear (#1971), the delete flow keeps its confirmation.
void main() {
  late MockStorageRepository mockStorage;

  setUp(() {
    // #2146 — catches route through errorLogger; in tests Hive isn't
    // initialised so the spool's default path throws — point the override
    // at a no-op recorder.
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
    addTearDown(errorLogger.resetForTest);

    mockStorage = MockStorageRepository();
    when(() => mockStorage.getFavoriteIds()).thenReturn(['fav1']);
    when(() => mockStorage.getAllFavoriteStationData()).thenReturn({});
    when(() => mockStorage.getIgnoredIds()).thenReturn([]);
    when(() => mockStorage.getRatings()).thenReturn({});
    when(() => mockStorage.getAllProfiles()).thenReturn([]);
    when(() => mockStorage.getAlerts()).thenReturn([]);
    when(() => mockStorage.getItineraries()).thenReturn([]);
    when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);
    when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);
  });

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    StubTraceStorage? traces,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      const PrivacyExportDeleteScreen(),
      overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(DisabledSyncState.new),
        traceStorageProvider.overrideWithValue(traces ?? StubTraceStorage()),
      ],
    );
    return AppLocalizations.of(
        tester.element(find.byType(PrivacyExportDeleteScreen)));
  }

  void wireClipboardCapture(void Function(Map<String, dynamic>) onCopy) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        onCopy(Map<String, dynamic>.from(call.arguments as Map));
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  group('export sheet', () {
    testWidgets('one export button opens the three-format sheet',
        (tester) async {
      final l = await pump(tester);
      expect(find.byKey(const ValueKey('privacy-export-button')), findsOneWidget);
      expect(find.text(l.privacyExportMyData), findsOneWidget);
      // The three former buttons are gone from the screen itself.
      expect(find.byKey(const Key('privacyExportZipOption')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('privacy-export-button')));
      await tester.pumpAndSettle();
      expect(find.text(l.privacyExportSheetTitle), findsOneWidget);
      expect(find.byKey(const Key('privacyExportZipOption')), findsOneWidget);
      expect(find.byKey(const Key('privacyExportJsonOption')), findsOneWidget);
      expect(find.byKey(const Key('privacyExportCsvOption')), findsOneWidget);
      expect(find.text(l.privacyExportZipSubtitle), findsOneWidget);
      expect(find.text(l.privacyExportJsonSubtitle), findsOneWidget);
      expect(find.text(l.privacyExportCsvSubtitle), findsOneWidget);
    });

    testWidgets('JSON option runs the JSON export (clipboard + Downloads)',
        (tester) async {
      Map<String, dynamic>? copied;
      wireClipboardCapture((m) => copied = m);
      final saved = <String>[];
      debugPublicFileExporterOverride =
          ({required bytes, required fileName, required mimeType}) async {
        saved.add('$fileName|$mimeType');
        return '/Downloads/$fileName';
      };
      addTearDown(() => debugPublicFileExporterOverride = null);

      final l = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('privacy-export-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacyExportJsonOption')));
      await tester.pumpAndSettle();

      expect(copied?['text'], contains('"favorites"'));
      expect(saved, ['tankstellen-data.json|application/json']);
      expect(find.text(l.savedToDownloadsFolder), findsOneWidget);
      // #3611 — let the sensitive-clipboard auto-clear timer elapse.
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('CSV option runs the CSV export', (tester) async {
      Map<String, dynamic>? copied;
      wireClipboardCapture((m) => copied = m);
      final saved = <String>[];
      debugPublicFileExporterOverride =
          ({required bytes, required fileName, required mimeType}) async {
        saved.add('$fileName|$mimeType');
        return '/Downloads/$fileName';
      };
      addTearDown(() => debugPublicFileExporterOverride = null);

      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('privacy-export-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacyExportCsvOption')));
      await tester.pumpAndSettle();

      expect(copied?['text'], startsWith('# '));
      expect(saved, ['tankstellen-data.csv|text/csv']);
      await tester.pump(const Duration(seconds: 61));
    });
  });

  group('error log row', () {
    testWidgets('shows the count; Clear is disabled when the log is empty',
        (tester) async {
      final l = await pump(tester);
      expect(find.text(l.privacyErrorLogCount(0)), findsOneWidget);
      final clear = tester.widget<TextButton>(
          find.byKey(const ValueKey('privacy-clear-error-log-button')));
      expect(clear.onPressed, isNull);
    });

    testWidgets('Clear empties the traces and confirms (#1971)',
        (tester) async {
      final stub = StubTraceStorage(stubCount: 7);
      final l = await pump(tester, traces: stub);
      expect(find.text(l.privacyErrorLogCount(7)), findsOneWidget);
      await tester
          .tap(find.byKey(const ValueKey('privacy-clear-error-log-button')));
      await tester.pumpAndSettle();
      expect(stub.clearAllCalled, isTrue);
      expect(find.text(l.privacyErrorLogCleared), findsOneWidget);
    });

    Future<void> tapSave(WidgetTester tester, bool Function() done) async {
      // Tap inside runAsync so the export's real-time Futures (disk IO +
      // share sink) resolve; the fake clock cannot pump them. Poll for the
      // outcome instead of sleeping a fixed interval — an 80 KB temp-file
      // write under a loaded test host outruns any constant delay.
      await tester.runAsync(() async {
        await tester
            .tap(find.byKey(const ValueKey('privacy-export-error-log-button')));
        var waited = 0;
        while (!done() && waited < 5000) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          waited += 25;
        }
        // The outcome landed; let the handler's tail (snackbar, temp-file
        // cleanup) finish before the frame is pumped.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('small log: Save copies to the clipboard, no share sheet '
        '(#1301)', (tester) async {
      Map<String, dynamic>? copied;
      wireClipboardCapture((m) => copied = m);
      ShareParams? shared;
      debugPrivacyShareSinkOverride = (params) async => shared = params;
      debugPrivacyTempDirectoryOverride = () async =>
          Directory.systemTemp.createTempSync('privacy_export_test_');
      addTearDown(() {
        debugPrivacyShareSinkOverride = null;
        debugPrivacyTempDirectoryOverride = null;
      });

      const smallJson = '{"traceCount":1,"traces":[{"id":"a"}]}';
      await pump(tester,
          traces: StubTraceStorage(
              stubCount: 1, stubParsedCount: 1, stubExport: smallJson));
      await tapSave(tester, () => copied != null);

      expect(copied?['text'], smallJson);
      expect(shared, isNull);
      expect(find.textContaining('Error log copied to clipboard'),
          findsOneWidget);
    });

    testWidgets('large log: Save hands off to the share sheet with a JSON '
        'file (#1301)', (tester) async {
      wireClipboardCapture((_) {});
      ShareParams? shared;
      debugPrivacyShareSinkOverride = (params) async => shared = params;
      debugPrivacyTempDirectoryOverride = () async =>
          Directory.systemTemp.createTempSync('privacy_export_test_');
      addTearDown(() {
        debugPrivacyShareSinkOverride = null;
        debugPrivacyTempDirectoryOverride = null;
      });

      final bigPayload = '{"traceCount":1,"big":"${'x' * (80 * 1024)}"}';
      await pump(tester,
          traces: StubTraceStorage(
              stubCount: 1, stubParsedCount: 1, stubExport: bigPayload));
      await tapSave(tester, () => shared != null);

      expect(shared?.files, hasLength(1));
      expect(shared!.files!.first.path, endsWith('tankstellen-error-log.json'));
      expect(find.textContaining('Error log shared'), findsOneWidget);
    });
  });

  group('danger zone', () {
    testWidgets('explains the scope; the red button opens the shared confirm '
        'dialog; Cancel keeps everything', (tester) async {
      final l = await pump(tester);
      expect(find.text(l.privacyDangerZoneBody), findsOneWidget);
      expect(find.byKey(const ValueKey('privacy-delete-all-button')),
          findsOneWidget);
      expect(find.text(l.privacyDeleteAllMyData), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('privacy-delete-all-button')));
      await tester.pumpAndSettle();
      expect(find.text(l.privacyDeleteTitle), findsOneWidget);
      expect(find.textContaining('permanently delete'), findsOneWidget);
      expect(find.text(l.privacyDeleteConfirm), findsOneWidget);

      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyExportDeleteScreen), findsOneWidget);
      verifyNever(() => mockStorage.clearCache());
    });
  });
}
