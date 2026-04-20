import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error_tracing/storage/trace_storage.dart';
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
  @override
  int get count => 0;

  @override
  String exportAsJson() => '{"traceCount":0,"traces":[]}';
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
