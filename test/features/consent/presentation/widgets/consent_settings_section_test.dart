// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/consent/presentation/widgets/consent_settings_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  Widget buildWidget({
    bool location = false,
    bool errorReporting = false,
    bool cloudSync = false,
    bool vinOnlineDecode = false,
    bool syncTrips = false,
  }) {
    unawaited(fakeStorage.putSetting(StorageKeys.consentLocation, location));
    unawaited(fakeStorage.putSetting(StorageKeys.consentErrorReporting, errorReporting));
    unawaited(fakeStorage.putSetting(StorageKeys.consentCloudSync, cloudSync));
    unawaited(fakeStorage.putSetting(
        StorageKeys.consentVinOnlineDecode, vinOnlineDecode));
    unawaited(fakeStorage.putSetting(StorageKeys.consentSyncTrips, syncTrips));

    return ProviderScope(
      overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: ConsentSettingsSection()),
      ),
    );
  }

  group('ConsentSettingsSection', () {
    testWidgets('shows four toggle switches', (tester) async {
      // #1665 — the 5th toggle (Sync trip recordings) moved to the
      // TankSync settings section. #2063 — the community wait-time
      // toggle was removed alongside the wait-time feature. Four
      // consent toggles remain here.
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(4));
    });

    testWidgets('shows correct labels', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Error Reporting'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('VIN online decode'), findsOneWidget);
    });

    testWidgets('reflects stored consent values', (tester) async {
      await tester.pumpWidget(buildWidget(
        location: true,
        errorReporting: false,
        cloudSync: true,
        vinOnlineDecode: true,
      ));
      await tester.pumpAndSettle();

      final tiles =
          tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(tiles[0].value, isTrue); // location
      expect(tiles[1].value, isFalse); // error reporting
      expect(tiles[2].value, isTrue); // cloud sync
      expect(tiles[3].value, isTrue); // vin online decode
    });

    testWidgets('toggling location saves to storage', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap location toggle
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
    });

    testWidgets('toggling VIN online decode saves only that key (#1399)',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(3));
      await tester.pumpAndSettle();

      expect(
          fakeStorage.getSetting(StorageKeys.consentVinOnlineDecode), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), false);
      expect(fakeStorage.getSetting(StorageKeys.consentErrorReporting), false);
      expect(fakeStorage.getSetting(StorageKeys.consentCloudSync), false);
    });

    testWidgets('shows settings hint text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('change your privacy choices'),
        findsOneWidget,
      );
    });
  });
}
