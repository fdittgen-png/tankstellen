// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/sync_account_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy/sync_account_overview_card.dart';
import 'package:tankstellen/features/profile/presentation/widgets/tank_sync_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../../fakes/fake_hive_storage.dart';
import '../../../../../../helpers/never_truncates.dart';
import '../../../../../../helpers/pump_app.dart';
import '../settings_test_harness.dart';
import 'privacy_test_support.dart';

/// #3911 (Epic #3907) — the ONE sync screen: status / mode / account /
/// user id (copyable) / host rows, the baseline switch, nothing truncated.
void main() {
  const userId = 'user-abcdef12-3456-7890-abcd-ef1234567890';

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required SyncState Function() sync,
    double width = 600,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      const SyncAccountScreen(),
      overrides: [
        hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
        featureFlagsRepositoryProvider.overrideWithValue(null),
        featureFlagsProvider
            .overrideWith(() => PinnedFeatureFlags(const {Feature.tankSync})),
        syncStateProvider.overrideWith(sync),
      ],
    );
    return AppLocalizations.of(tester.element(find.byType(SyncAccountScreen)));
  }

  String value(WidgetTester tester, String key) => (tester
          .widget<ListTile>(find.descendant(
              of: find.byKey(Key(key)), matching: find.byType(ListTile)))
          .subtitle! as Text)
      .data!;

  testWidgets('disconnected: status row says disabled, no mode / id rows, '
      'the TankSync section offers setup', (tester) async {
    final l = await pump(tester, sync: DisabledSyncState.new);
    expect(find.byType(SyncAccountOverviewCard), findsOneWidget);
    expect(value(tester, 'syncOverviewStatus'), l.configTankSyncDisabled);
    expect(find.byKey(const Key('syncOverviewMode')), findsNothing);
    expect(find.byKey(const Key('syncOverviewUserId')), findsNothing);
    expect(find.byKey(const Key('syncBaselinesToggle')), findsNothing);
    expect(find.byType(TankSyncSection), findsOneWidget);
    expect(find.text(l.setupCloudSync), findsOneWidget);
  });

  testWidgets('community + anonymous: every fact on its own line, in plain '
      'language, the full id, the host only', (tester) async {
    final l = await pump(tester, sync: () => EnabledSyncState());
    expect(value(tester, 'syncOverviewStatus'), l.configTankSyncConnected);
    expect(value(tester, 'syncOverviewMode'), l.privacySyncModeCommunity);
    expect(value(tester, 'syncOverviewAccount'), l.privacySyncAccountAnonymous);
    expect(value(tester, 'syncOverviewUserId'), userId,
        reason: 'the FULL id, not a truncated prefix');
    expect(value(tester, 'syncOverviewHost'), 'test.supabase.co',
        reason: 'host only — no scheme, no path');
    expect(find.byKey(const Key('syncBaselinesToggle')), findsOneWidget);
    expect(find.text(l.privacySyncDescription), findsOneWidget);
    // The TankSync section no longer repeats the status/mode/id tile.
    expect(find.text('Sparkilo Community'), findsNothing);
    expect(find.textContaining('Anonymous ·'), findsNothing);
  });

  testWidgets('self-hosted + email: mode and account wording follow',
      (tester) async {
    final l = await pump(tester,
        sync: () => EnabledSyncState(
            mode: SyncMode.private,
            email: 'x@y.example',
            url: 'https://db.example.org/rest/v1'));
    expect(value(tester, 'syncOverviewMode'), l.privacySyncModeSelfHosted);
    expect(value(tester, 'syncOverviewAccount'),
        l.privacySyncAccountEmail('x@y.example'));
    expect(value(tester, 'syncOverviewHost'), 'db.example.org');
  });

  testWidgets('the copy action puts the user id on the clipboard and '
      'confirms', (tester) async {
    Map<String, dynamic>? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        captured = Map<String, dynamic>.from(call.arguments as Map);
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final l = await pump(tester, sync: () => EnabledSyncState());
    final button = tester
        .widget<IconButton>(find.byKey(const Key('syncOverviewCopyUserId')));
    expect(button.tooltip, l.privacyCopyUserId);
    await tester.tap(find.byKey(const Key('syncOverviewCopyUserId')));
    await tester.pumpAndSettle();
    expect(captured?['text'], userId);
    expect(find.text(l.privacyUserIdCopied), findsOneWidget);
  });

  testWidgets('the baseline switch writes through its provider',
      (tester) async {
    await pump(tester, sync: () => EnabledSyncState());
    final before = tester
        .widget<SwitchListTile>(find.byKey(const Key('syncBaselinesToggle')))
        .value;
    await tester.tap(find.byKey(const Key('syncBaselinesToggle')));
    await tester.pumpAndSettle();
    final after = tester
        .widget<SwitchListTile>(find.byKey(const Key('syncBaselinesToggle')))
        .value;
    expect(after, !before);
  });

  testWidgets('no value truncates at 320 dp (long id + host)', (tester) async {
    await pump(tester,
        sync: () => EnabledSyncState(
            email: 'a.very.long.address@subdomain.example-domain.org',
            url: 'https://a-really-long-project-reference.supabase.co'),
        width: 320);
    expect(tester.takeException(), isNull);
    expectNoTextTruncates(tester,
        within: find.byType(SyncAccountOverviewCard));
  });
}
