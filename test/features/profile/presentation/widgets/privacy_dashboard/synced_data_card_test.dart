import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/privacy_data_row.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/synced_data_card.dart';
import 'package:tankstellen/features/profile/providers/privacy_data_provider.dart';
import 'package:tankstellen/features/sync/providers/baseline_sync_enabled_provider.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/pump_app.dart';

PrivacyDataSnapshot _snapshot({
  bool syncEnabled = false,
  String? syncMode,
  String? syncUserId,
}) =>
    PrivacyDataSnapshot(
      favoritesCount: 0,
      ignoredCount: 0,
      ratingsCount: 0,
      alertsCount: 0,
      priceHistoryStationCount: 0,
      profileCount: 1,
      cacheEntryCount: 0,
      itineraryCount: 0,
      hasApiKey: false,
      hasEvApiKey: false,
      syncEnabled: syncEnabled,
      syncMode: syncMode,
      syncUserId: syncUserId,
      estimatedTotalBytes: 1024,
    );

/// Override [baselineSyncEnabledProvider] with a fixed boolean. Used
/// instead of seeding the legacy [StorageKeys.syncBaselinesEnabled]
/// Hive key after the #1373 phase 3e migration — the canonical state
/// now lives in the central feature-flag set.
Object _baselineSyncOverride(bool value) {
  return baselineSyncEnabledProvider.overrideWith(() => _FakeBaselineSync(value));
}

class _FakeBaselineSync extends BaselineSyncEnabled {
  _FakeBaselineSync(this._value);

  final bool _value;

  @override
  bool build() => _value;

  @override
  Future<void> set(bool value) async {
    state = value;
  }
}

void main() {
  group('SyncedDataCard', () {
    testWidgets('header renders cloud icon + bold title', (tester) async {
      final overrides = standardTestOverrides();
      // Default the toggle to false so the disabled-body branch is
      // exercised cleanly.
      await pumpApp(
        tester,
        SyncedDataCard(snapshot: _snapshot()),
        overrides: [...overrides.overrides, _baselineSyncOverride(false)],
      );

      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);

      final title =
          tester.widget<Text>(find.text('Cloud sync (TankSync)'));
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('disabled snapshot shows the cloud_off banner + message',
        (tester) async {
      final overrides = standardTestOverrides();
      await pumpApp(
        tester,
        SyncedDataCard(snapshot: _snapshot(syncEnabled: false)),
        overrides: [...overrides.overrides, _baselineSyncOverride(false)],
      );

      // Disabled banner has the cloud_off icon + the disabled copy.
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.textContaining('Cloud sync is disabled'),
        findsOneWidget,
      );

      // No sync details should leak through when disabled — e.g. the
      // "View server data" CTA and the baseline switch live in the
      // enabled body only.
      expect(find.text('View server data'), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets(
        'enabled snapshot renders sync mode, masked user id, and CTA',
        (tester) async {
      final overrides = standardTestOverrides();
      // syncBaselinesToggle starts as false (default per manifest).
      // Stub out generic getSetting calls to keep mocktail happy if the
      // widget reads any unrelated settings.
      when(() => overrides.mockStorage.getSetting(any()))
          .thenReturn(null);

      await pumpApp(
        tester,
        SyncedDataCard(
          snapshot: _snapshot(
            syncEnabled: true,
            syncMode: 'anonymous',
            // 8-char prefix is rendered, rest truncated to "...".
            syncUserId: 'abcd1234-aaaa-bbbb-cccc-deadbeefcafe',
          ),
        ),
        overrides: [...overrides.overrides, _baselineSyncOverride(false)],
      );

      // Two PrivacyDataRows: sync mode + user id.
      expect(find.byType(PrivacyDataRow), findsNWidgets(2));
      expect(find.text('Sync mode'), findsOneWidget);
      expect(find.text('anonymous'), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);
      // Only the first 8 chars of the id are rendered, followed by "...".
      expect(find.text('abcd1234...'), findsOneWidget);

      // Baseline switch + CTA both visible.
      expect(find.byKey(const Key('syncBaselinesToggle')), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.text('View server data'), findsOneWidget);

      // Disabled banner must be absent in the enabled path.
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets(
        'enabled snapshot with null sync mode/user id renders dash placeholders',
        (tester) async {
      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getSetting(any()))
          .thenReturn(null);

      await pumpApp(
        tester,
        SyncedDataCard(
          snapshot: _snapshot(syncEnabled: true),
        ),
        overrides: [...overrides.overrides, _baselineSyncOverride(false)],
      );

      // Two rows still render — but their values fall back to "-".
      expect(find.byType(PrivacyDataRow), findsNWidgets(2));
      expect(find.text('-'), findsNWidgets(2));
    });

    testWidgets(
        'baseline-sync toggle reflects the central feature-flag value (true)',
        (tester) async {
      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getSetting(any()))
          .thenReturn(null);

      await pumpApp(
        tester,
        SyncedDataCard(snapshot: _snapshot(syncEnabled: true)),
        overrides: [...overrides.overrides, _baselineSyncOverride(true)],
      );

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('syncBaselinesToggle')),
      );
      expect(
        toggle.value,
        isTrue,
        reason:
            'After #1373 phase 3e the toggle reads from '
            'baselineSyncEnabledProvider — a true override must surface '
            'as a checked switch.',
      );
    });

    testWidgets(
        'baseline-sync toggle is OFF when the central feature-flag is false',
        (tester) async {
      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getSetting(any()))
          .thenReturn(null);

      await pumpApp(
        tester,
        SyncedDataCard(snapshot: _snapshot(syncEnabled: true)),
        overrides: [...overrides.overrides, _baselineSyncOverride(false)],
      );

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('syncBaselinesToggle')),
      );
      expect(toggle.value, isFalse);

      // Toggle title + subtitle should be visible.
      expect(find.text('Share learned vehicle profiles'), findsOneWidget);
      expect(
        find.textContaining('per-vehicle consumption baselines'),
        findsOneWidget,
      );
    });

    testWidgets('enabled body surfaces the descriptive helper text',
        (tester) async {
      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getSetting(any()))
          .thenReturn(null);

      await pumpApp(
        tester,
        SyncedDataCard(snapshot: _snapshot(syncEnabled: true)),
        overrides: [...overrides.overrides, _baselineSyncOverride(false)],
      );

      expect(
        find.textContaining('When sync is enabled'),
        findsOneWidget,
      );
    });
  });
}
