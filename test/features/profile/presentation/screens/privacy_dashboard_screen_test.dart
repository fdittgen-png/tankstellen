import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/profile/presentation/screens/privacy_dashboard_screen.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Stub TraceStorage that doesn't touch Hive — the privacy dashboard
/// reads `count` from the provider during build, and the production
/// implementation calls `Hive.box('error_traces')` which fails in
/// widget tests where Hive isn't initialised.
class _StubTraceStorage extends TraceStorage {
  _StubTraceStorage({
    this.stubCount = 0,
    this.stubParsedCount = 0,
    this.stubUnparsedCount = 0,
    this.stubExport = '{"traceCount":0,"traces":[]}',
  });

  final int stubCount;
  final int stubParsedCount;
  final int stubUnparsedCount;
  final String stubExport;

  @override
  int get count => stubCount;

  @override
  int get parsedCount => stubParsedCount;

  @override
  int get unparsedCount => stubUnparsedCount;

  @override
  String exportAsJson() => stubExport;
}

/// #519 — the Privacy Dashboard body grew with the
/// ConfigVerificationWidget card moved in from the Settings screen.
/// The default 800x600 test surface no longer fits LocalDataCard
/// below it, and find.text skips off-stage widgets by default. Tests
/// in this file widen the surface so everything lays out at once.
const _privacyDashboardTestSize = Size(1200, 2400);

Future<void> _setTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_privacyDashboardTestSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('PrivacyDashboardScreen', () {
    late MockStorageRepository mockStorage;

    setUp(() {
      mockStorage = MockStorageRepository();

      when(() => mockStorage.favoriteCount).thenReturn(5);
      when(() => mockStorage.getIgnoredIds()).thenReturn(['a', 'b']);
      when(() => mockStorage.getRatings()).thenReturn({'s1': 4});
      when(() => mockStorage.alertCount).thenReturn(2);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn(['k1', 'k2']);
      when(() => mockStorage.profileCount).thenReturn(1);
      when(() => mockStorage.cacheEntryCount).thenReturn(15);
      when(() => mockStorage.getItineraries()).thenReturn([{'id': 'r1'}]);
      when(() => mockStorage.hasApiKey()).thenReturn(true);
      when(() => mockStorage.hasCustomApiKey()).thenReturn(true);
      when(() => mockStorage.getApiKey()).thenReturn('key');
      when(() => mockStorage.hasEvApiKey()).thenReturn(false);
      when(() => mockStorage.hasCustomEvApiKey()).thenReturn(false);
      when(() => mockStorage.storageStats).thenReturn((
        settings: 512,
        profiles: 1024,
        favorites: 320,
        cache: 30720,
        priceHistory: 2048,
        alerts: 512,
        total: 35136,
      ));
    });

    List<Object> overrides() => [
          storageRepositoryProvider.overrideWithValue(mockStorage),
          syncStateProvider.overrideWith(() => _DisabledSyncState()),
          traceStorageProvider.overrideWithValue(_StubTraceStorage()),
        ];

    testWidgets('shows local data counts', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      expect(find.text('5'), findsOneWidget); // favorites
      expect(find.text('2'), findsAtLeast(1)); // ignored or alerts or price history
      expect(find.text('1'), findsAtLeast(1)); // ratings or profiles or itineraries
      expect(find.text('15'), findsOneWidget); // cache entries
    });

    testWidgets('shows API key status', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      // API key stored should show Yes
      expect(find.text('Yes'), findsOneWidget);
      // EV API key should show No
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('shows sync disabled message when sync is off', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      expect(
        find.textContaining('Cloud sync is disabled'),
        findsOneWidget,
      );
    });

    testWidgets('shows sync info when sync is enabled', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: [
          storageRepositoryProvider.overrideWithValue(mockStorage),
          syncStateProvider.overrideWith(() => _EnabledSyncState()),
          traceStorageProvider.overrideWithValue(_StubTraceStorage()),
        ],
      );

      expect(find.text('Tankstellen Community'), findsOneWidget);
      expect(find.textContaining('user-abc'), findsOneWidget);
      expect(find.text('View server data'), findsOneWidget);
    });

    testWidgets(
        'shows the "Copy error log to clipboard" button labelled with the '
        'current trace count (#476)', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      // The button lives in the ListView below the fold — scroll it
      // into view first.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('privacy-export-error-log-button')),
        50.0,
      );

      // The new button is keyed for stable lookup; the label includes the
      // count from the (stubbed) TraceStorage which returns 0.
      expect(
        find.byKey(const ValueKey('privacy-export-error-log-button')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Copy error log to clipboard (0)'),
        findsOneWidget,
      );
    });

    testWidgets('shows export button', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Export all data as JSON'),
        200,
      );
      expect(find.text('Export all data as JSON'), findsOneWidget);
    });

    testWidgets('shows delete button', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Delete all data'),
        200,
      );
      expect(find.text('Delete all data'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Delete all data'),
        200,
      );
      await tester.tap(find.text('Delete all data'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete all data?'), findsOneWidget);
      expect(find.textContaining('permanently delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete everything'), findsOneWidget);
    });

    testWidgets('cancel in delete dialog does not delete', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Delete all data'),
        200,
      );
      await tester.tap(find.text('Delete all data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should still be on the dashboard - check something visible
      expect(find.text('Privacy Dashboard'), findsOneWidget);
    });

    testWidgets('shows privacy banner', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      expect(
        find.textContaining('Your data belongs to you'),
        findsOneWidget,
      );
    });

    testWidgets('shows estimated storage size', (tester) async {
      await _setTallSurface(tester);
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: overrides(),
      );

      expect(find.text('Estimated storage'), findsOneWidget);
      // 35136 bytes = 34.3 KB
      expect(find.text('34.3 KB'), findsOneWidget);
    });

    /// #1301 — `_exportErrorLog` must (a) write the JSON to the system
    /// clipboard when the payload is small, (b) hand off via
    /// share_plus when it's large, and (c) surface unparsed entries in
    /// the snackbar so users know why a 21-entry log looks empty.
    group('_exportErrorLog (#1301)', () {
      Map<String, dynamic>? capturedClipboard;
      ShareParams? capturedShareParams;

      setUp(() {
        capturedClipboard = null;
        capturedShareParams = null;
      });

      void wireClipboardCapture(WidgetTester tester) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform,
                (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            capturedClipboard = Map<String, dynamic>.from(call.arguments as Map);
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding
              .instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });
      }

      void wireShareCapture() {
        debugPrivacyShareSinkOverride = (params) async {
          capturedShareParams = params;
        };
        debugPrivacyTempDirectoryOverride = () async =>
            Directory.systemTemp.createTempSync('privacy_dashboard_test_');
        addTearDown(() {
          debugPrivacyShareSinkOverride = null;
          debugPrivacyTempDirectoryOverride = null;
        });
      }

      Future<void> tapExportButton(WidgetTester tester) async {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('privacy-export-error-log-button')),
          50.0,
        );
        // Tap inside runAsync so the export's real-time Futures
        // (writeAsString + share sink) actually resolve. tester.tap
        // itself is sync, but the onPressed callback kicks off an
        // async chain that the fake clock can't pump.
        await tester.runAsync(() async {
          await tester.tap(
            find.byKey(const ValueKey('privacy-export-error-log-button')),
          );
          // Give the disk IO + share sink real wall-clock time.
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        // Surface the resulting snackbar in the widget tree.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }

      testWidgets(
          'small JSON path writes to Clipboard.setData and skips share_plus',
          (tester) async {
        wireClipboardCapture(tester);
        wireShareCapture();
        await _setTallSurface(tester);

        const smallJson = '{"traceCount":1,"traces":[{"id":"a"}]}';
        final stub = _StubTraceStorage(
          stubCount: 1,
          stubParsedCount: 1,
          stubExport: smallJson,
        );
        await pumpApp(
          tester,
          const PrivacyDashboardScreen(),
          overrides: [
            storageRepositoryProvider.overrideWithValue(mockStorage),
            syncStateProvider.overrideWith(() => _DisabledSyncState()),
            traceStorageProvider.overrideWithValue(stub),
          ],
        );

        await tapExportButton(tester);

        expect(capturedClipboard, isNotNull,
            reason: 'small payload should reach the clipboard channel');
        expect(capturedClipboard!['text'], smallJson);
        expect(capturedShareParams, isNull,
            reason: 'small payload should NOT trigger share_plus');
        // Snackbar reports byte size + entry count.
        expect(find.textContaining('Error log copied to clipboard'),
            findsOneWidget);
        expect(find.textContaining('1 entries'), findsOneWidget);
      });

      testWidgets(
          'large JSON path hands off to share_plus with a JSON file attachment',
          (tester) async {
        wireClipboardCapture(tester);
        wireShareCapture();
        await _setTallSurface(tester);

        // 80 KB > 64 KB threshold.
        final bigPayload = '{"traceCount":1,"big":"${'x' * (80 * 1024)}"}';
        final stub = _StubTraceStorage(
          stubCount: 1,
          stubParsedCount: 1,
          stubExport: bigPayload,
        );
        await pumpApp(
          tester,
          const PrivacyDashboardScreen(),
          overrides: [
            storageRepositoryProvider.overrideWithValue(mockStorage),
            syncStateProvider.overrideWith(() => _DisabledSyncState()),
            traceStorageProvider.overrideWithValue(stub),
          ],
        );

        await tapExportButton(tester);

        expect(capturedShareParams, isNotNull,
            reason: 'payload above 64 KB threshold must use share sheet');
        expect(capturedShareParams!.files, isNotNull);
        expect(capturedShareParams!.files!, hasLength(1));
        expect(
          capturedShareParams!.files!.first.path,
          endsWith('tankstellen-error-log.json'),
        );
        expect(capturedClipboard, isNull,
            reason: 'large payload skips clipboard');
        // Snackbar mentions "shared".
        expect(find.textContaining('Error log shared'), findsOneWidget);
      });

      testWidgets(
          'snackbar surfaces parsed-vs-unparsed split when Hive has '
          'schema drift', (tester) async {
        wireClipboardCapture(tester);
        wireShareCapture();
        await _setTallSurface(tester);

        const mixedJson = '{"traceCount":3,"parsedCount":1,'
            '"unparsedCount":2,"traces":[],"unparsedRaw":[{"id":"x"}]}';
        final stub = _StubTraceStorage(
          stubCount: 3,
          stubParsedCount: 1,
          stubUnparsedCount: 2,
          stubExport: mixedJson,
        );
        await pumpApp(
          tester,
          const PrivacyDashboardScreen(),
          overrides: [
            storageRepositoryProvider.overrideWithValue(mockStorage),
            syncStateProvider.overrideWith(() => _DisabledSyncState()),
            traceStorageProvider.overrideWithValue(stub),
          ],
        );

        await tapExportButton(tester);

        expect(capturedClipboard, isNotNull);
        // Snackbar tells the user the breakdown explicitly.
        expect(
          find.textContaining(
              'Error log copied (1 parsed + 2 raw entries'),
          findsOneWidget,
        );
        expect(
          find.textContaining('some entries failed to parse'),
          findsOneWidget,
        );
      });
    });
  });
}

class _DisabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}

class _EnabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'test-key',
        userId: 'user-abcdef12-3456-7890',
        mode: SyncMode.community,
      );
}
