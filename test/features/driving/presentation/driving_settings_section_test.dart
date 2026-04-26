import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_settings_section.dart';

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
