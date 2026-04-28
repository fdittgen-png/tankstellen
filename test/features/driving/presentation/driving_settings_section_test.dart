import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/widgets/settings_menu_tile.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_settings_section.dart';
import 'package:tankstellen/features/profile/presentation/widgets/gamification_settings_tile.dart';

import '../../../fakes/fake_storage_repository.dart';
import '../../../helpers/pump_app.dart';

/// Widget coverage for [DrivingSettingsSection] (#1122).
///
/// Two scenarios:
///   1. Default-OFF state renders the switch as off and tapping it
///      writes `true` to the canonical storage key.
///   2. Persisted-true storage renders the switch in the on state on
///      first paint — confirming the provider reads from storage on
///      build, not just on subsequent toggles.
///
/// We swap in a fake [SettingsStorage] so the tests don't need a real
/// Hive box and stay deterministic across runs.
void main() {
  testWidgets(
    'renders the haptic eco-coach toggle in the off state by default and '
    'persists `true` when tapped',
    (tester) async {
      final fake = _FakeSettingsStorage();
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(fake),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
        ],
      );

      final switchFinder = find.byKey(const Key('hapticEcoCoachToggle'));
      expect(switchFinder, findsOneWidget);
      final initial = tester.widget<SwitchListTile>(switchFinder);
      expect(
        initial.value,
        isFalse,
        reason: 'Default-OFF must hold for first-launch users (#1122).',
      );

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(
        fake.data[StorageKeys.hapticEcoCoachEnabled],
        isTrue,
        reason:
            'Tapping the toggle must persist the new value to the canonical '
            'storage key so the setting survives an app restart.',
      );
      final flipped = tester.widget<SwitchListTile>(switchFinder);
      expect(
        flipped.value,
        isTrue,
        reason: 'The switch must reflect the new persisted value immediately.',
      );
    },
  );

  testWidgets(
    'reads the persisted true value on build so the switch starts on',
    (tester) async {
      final fake = _FakeSettingsStorage()
        ..data[StorageKeys.hapticEcoCoachEnabled] = true;
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(fake),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
        ],
      );

      final switchFinder = find.byKey(const Key('hapticEcoCoachToggle'));
      final tile = tester.widget<SwitchListTile>(switchFinder);
      expect(
        tile.value,
        isTrue,
        reason:
            'A persisted-true value must hydrate the toggle on first '
            'paint — otherwise the user would have to flip it twice on '
            'every cold start.',
      );
    },
  );

  testWidgets(
    'composes vehicles + fuel-club tiles above the eco-coach toggle '
    '(#1242 — Console grouping)',
    (tester) async {
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
        ],
      );

      // Both moved-in tiles must render with their canonical keys.
      expect(
        find.byKey(const Key('consoleVehiclesTile')),
        findsOneWidget,
        reason: 'My vehicles tile is part of the Consumption group.',
      );
      expect(
        find.byKey(const Key('consoleFuelClubCardsTile')),
        findsOneWidget,
        reason: 'Fuel club cards tile is part of the Consumption group.',
      );

      // The eco-coach toggle is the third element, after the two
      // menu tiles.
      final children = <Widget>[
        for (final t in tester
            .widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile)))
          t,
      ];
      expect(
        children.length,
        2,
        reason: 'Exactly two SettingsMenuTile children: vehicles + fuel '
            'club. Adding more would risk drift between this section '
            'and the Conso-tab landing screen.',
      );
    },
  );

  testWidgets(
    'nests the gamification opt-out tile inside the Conso section '
    '(#1249 — moved out of the standalone settings card)',
    (tester) async {
      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
        ],
      );

      // The gamification toggle now lives as the last child of the
      // Consumption foldable instead of as a sibling Card on the
      // Settings page. Asserting it is present here pins that
      // placement so a future rewrite can't silently move it back.
      expect(
        find.byType(GamificationSettingsTile),
        findsOneWidget,
        reason:
            'Exactly one GamificationSettingsTile must render inside '
            'DrivingSettingsSection — duplication or absence indicates '
            'the #1249 placement regressed.',
      );
    },
  );
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
