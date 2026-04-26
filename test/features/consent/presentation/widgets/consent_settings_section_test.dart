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
  }) {
    fakeStorage.putSetting(StorageKeys.consentLocation, location);
    fakeStorage.putSetting(StorageKeys.consentErrorReporting, errorReporting);
    fakeStorage.putSetting(StorageKeys.consentCloudSync, cloudSync);

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
    testWidgets('shows three toggle switches', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(3));
    });

    testWidgets('shows correct labels', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Error Reporting'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
    });

    testWidgets('reflects stored consent values', (tester) async {
      await tester.pumpWidget(buildWidget(
        location: true,
        errorReporting: false,
        cloudSync: true,
      ));
      await tester.pumpAndSettle();

      final tiles =
          tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(tiles[0].value, isTrue); // location
      expect(tiles[1].value, isFalse); // error reporting
      expect(tiles[2].value, isTrue); // cloud sync
    });

    testWidgets('toggling location saves to storage', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap location toggle
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
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
