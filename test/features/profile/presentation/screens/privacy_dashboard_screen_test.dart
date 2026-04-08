import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/profile/presentation/screens/privacy_dashboard_screen.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

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
      when(() => mockStorage.hasEvApiKey()).thenReturn(false);
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

    List<Object> _overrides() => [
          storageRepositoryProvider.overrideWithValue(mockStorage),
          syncStateProvider.overrideWith(() => _DisabledSyncState()),
        ];

    testWidgets('shows local data counts', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
      );

      expect(find.text('5'), findsOneWidget); // favorites
      expect(find.text('2'), findsAtLeast(1)); // ignored or alerts or price history
      expect(find.text('1'), findsAtLeast(1)); // ratings or profiles or itineraries
      expect(find.text('15'), findsOneWidget); // cache entries
    });

    testWidgets('shows API key status', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
      );

      // API key stored should show Yes
      expect(find.text('Yes'), findsOneWidget);
      // EV API key should show No
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('shows sync disabled message when sync is off', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
      );

      expect(
        find.textContaining('Cloud sync is disabled'),
        findsOneWidget,
      );
    });

    testWidgets('shows sync info when sync is enabled', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: [
          storageRepositoryProvider.overrideWithValue(mockStorage),
          syncStateProvider.overrideWith(() => _EnabledSyncState()),
        ],
      );

      expect(find.text('Tankstellen Community'), findsOneWidget);
      expect(find.textContaining('user-abc'), findsOneWidget);
      expect(find.text('View server data'), findsOneWidget);
    });

    testWidgets('shows export button', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Export all data as JSON'),
        200,
      );
      expect(find.text('Export all data as JSON'), findsOneWidget);
    });

    testWidgets('shows delete button', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Delete all data'),
        200,
      );
      expect(find.text('Delete all data'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
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
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
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
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
      );

      expect(
        find.textContaining('Your data belongs to you'),
        findsOneWidget,
      );
    });

    testWidgets('shows estimated storage size', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDashboardScreen(),
        overrides: _overrides(),
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
