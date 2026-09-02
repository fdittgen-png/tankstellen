// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/profile_routes.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_choices_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_device_data_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_export_delete_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy_data_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../../fakes/fake_hive_storage.dart';
import '../../../../../../helpers/pump_app.dart';
import 'privacy_test_support.dart';

/// #3908 (Epic #3907) — the Privacy & data entry: summary card lines,
/// the four topic tiles with live status lines, their navigation, and
/// the retired dashboard route's redirect.
void main() {
  late FakeHiveStorage storage;

  setUp(() {
    storage = FakeHiveStorage();
    unawaited(storage.putSetting(StorageKeys.consentLocation, true));
    unawaited(storage.putSetting(StorageKeys.consentErrorReporting, false));
    unawaited(storage.putSetting(StorageKeys.consentCloudSync, true));
    unawaited(storage.putSetting(StorageKeys.consentVinOnlineDecode, true));
    unawaited(storage.putSetting(StorageKeys.consentSyncTrips, false));
    unawaited(storage.setFavoriteIds(['f1', 'f2']));
    unawaited(storage.setIgnoredIds(['i1']));
    storage.statsOverride = (box) => box == 'favorites' ? 2048 : 0;
  });

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    bool syncOn = false,
    String? email,
    int errorLogCount = 29,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      const PrivacyDataScreen(),
      overrides: [
        hiveStorageProvider.overrideWithValue(storage),
        syncStateProvider.overrideWith(
            () => syncOn ? EnabledSyncState(email: email) : DisabledSyncState()),
        traceStorageProvider
            .overrideWithValue(StubTraceStorage(stubCount: errorLogCount)),
      ],
    );
    return AppLocalizations.of(tester.element(find.byType(PrivacyDataScreen)));
  }

  testWidgets('summary card: local-only data location, sync off, storage line',
      (tester) async {
    final l = await pump(tester);
    expect(find.byKey(const Key('privacySummaryCard')), findsOneWidget);
    expect(find.text(l.privacyDataLocationLocal), findsOneWidget);
    expect(find.text(l.privacySyncLineDisabled), findsNWidgets(2),
        reason: 'summary line + the Sync & account tile status');
    expect(find.text(l.privacyStorageLine('2,0 KB')), findsOneWidget);
  });

  testWidgets('summary card with sync on: synced location + anonymous account',
      (tester) async {
    final l = await pump(tester, syncOn: true);
    expect(find.text(l.privacyDataLocationSynced), findsOneWidget);
    expect(find.text(l.privacySyncLineEnabledAnonymous), findsNWidgets(2));
  });

  testWidgets('sync line names the email account when signed in',
      (tester) async {
    final l = await pump(tester, syncOn: true, email: 'x@y.example');
    expect(find.text(l.privacySyncLineEnabledEmail), findsNWidgets(2));
  });

  testWidgets('the four topic tiles carry live status lines', (tester) async {
    final l = await pump(tester);
    expect(find.byKey(const Key('privacyTopic_choices')), findsOneWidget);
    expect(find.text(l.privacyTopicChoicesTitle), findsOneWidget);
    expect(find.text(l.privacyChoicesStatus(3, 5)), findsOneWidget,
        reason: 'location + cloud sync + VIN decode are on');

    expect(find.byKey(const Key('privacyTopic_deviceData')), findsOneWidget);
    expect(find.text(l.privacyLocalData), findsOneWidget);
    // favorites (2), ignored (1) and settings are the non-empty categories.
    expect(find.text(l.privacyDeviceDataStatus('2,0 KB', 3)), findsOneWidget);

    expect(find.byKey(const Key('privacyTopic_sync')), findsOneWidget);
    expect(find.text(l.settingsTopicSyncTitle), findsOneWidget);

    expect(find.byKey(const Key('privacyTopic_exportDelete')), findsOneWidget);
    expect(find.text(l.privacyTopicExportDeleteTitle), findsOneWidget);
    expect(find.text(l.privacyExportDeleteStatus(29)), findsOneWidget);
  });

  testWidgets('tiles push their topic screens', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('privacyTopic_choices')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyChoicesScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('privacyTopic_deviceData')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyDeviceDataScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('privacyTopic_exportDelete')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyExportDeleteScreen), findsOneWidget);
  });

  test('the retired dashboard route redirects to Settings → Privacy & data',
      () {
    final route = profileRoutes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == RoutePaths.privacyDashboard);
    expect(route.builder, isNull);
    expect(route.redirect, isNotNull);
  });
}
