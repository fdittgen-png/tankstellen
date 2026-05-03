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
    bool communityWaitTime = false,
    bool vinOnlineDecode = false,
  }) {
    fakeStorage.putSetting(StorageKeys.consentLocation, location);
    fakeStorage.putSetting(StorageKeys.consentErrorReporting, errorReporting);
    fakeStorage.putSetting(StorageKeys.consentCloudSync, cloudSync);
    fakeStorage.putSetting(
        StorageKeys.consentCommunityWaitTime, communityWaitTime);
    fakeStorage.putSetting(
        StorageKeys.consentVinOnlineDecode, vinOnlineDecode);

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
    testWidgets('shows five toggle switches', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(5));
    });

    testWidgets('shows correct labels', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Error Reporting'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('Community Wait Times'), findsOneWidget);
      expect(find.text('VIN online decode'), findsOneWidget);
    });

    testWidgets('reflects stored consent values', (tester) async {
      await tester.pumpWidget(buildWidget(
        location: true,
        errorReporting: false,
        cloudSync: true,
        communityWaitTime: true,
        vinOnlineDecode: true,
      ));
      await tester.pumpAndSettle();

      final tiles =
          tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(tiles[0].value, isTrue); // location
      expect(tiles[1].value, isFalse); // error reporting
      expect(tiles[2].value, isTrue); // cloud sync
      expect(tiles[3].value, isTrue); // community wait time
      expect(tiles[4].value, isTrue); // vin online decode
    });

    testWidgets('toggling location saves to storage', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap location toggle
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
    });

    testWidgets('toggling community wait-time saves only that key',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(3));
      await tester.pumpAndSettle();

      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), false);
      expect(fakeStorage.getSetting(StorageKeys.consentErrorReporting), false);
      expect(fakeStorage.getSetting(StorageKeys.consentCloudSync), false);
      expect(
          fakeStorage.getSetting(StorageKeys.consentVinOnlineDecode), false);
    });

    testWidgets('toggling VIN online decode saves only that key (#1399)',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(4));
      await tester.pumpAndSettle();

      expect(
          fakeStorage.getSetting(StorageKeys.consentVinOnlineDecode), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), false);
      expect(fakeStorage.getSetting(StorageKeys.consentErrorReporting), false);
      expect(fakeStorage.getSetting(StorageKeys.consentCloudSync), false);
      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), false);
    });

    testWidgets(
        'toggling location preserves existing communityWaitTime value',
        (tester) async {
      await tester.pumpWidget(buildWidget(communityWaitTime: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), true);
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
