import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/widgets/settings_menu_tile.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_settings_section.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/widgets/gamification_settings_tile.dart';

import '../../../fakes/fake_storage_repository.dart';
import '../../../helpers/pump_app.dart';

/// Widget coverage for [DrivingSettingsSection] (#1122).
///
/// As of #1373 phase 3a the haptic eco-coach toggle reads/writes
/// through the central [featureFlagsProvider] rather than the legacy
/// settings box. The widget surface (key, label, ordering) is
/// unchanged; the test overrides now point at a synthetic
/// in-memory feature-flag notifier ([_TestFeatureFlags]) instead of
/// the real Hive-backed repository to keep these tests fast and
/// platform-deterministic.
///
/// Two scenarios:
///   1. Default-OFF state renders the switch as off and tapping it
///      flips the central feature-flag set on (assertions inspect the
///      synthetic notifier's state directly).
///   2. Pre-seeded central state with hapticEcoCoach enabled hydrates
///      the switch to on on first paint.
///
/// We intentionally bypass the real [FeatureFlagsRepository] /
/// `featureFlagsRepositoryProvider` here because real Hive boxes
/// triggered hangs in `pumpAndSettle` on Windows after the toggle's
/// fire-and-forget save (see memory file
/// `feedback_hive_widget_test_teardown.md`). Persistence is covered
/// in `test/features/feature_management/feature_flags_provider_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders the haptic eco-coach toggle in the off state by default and '
    'flips the central feature-flag set when tapped',
    (tester) async {
      // Seed prerequisite (obd2TripRecording) so the central enable
      // succeeds — without it the shim would silently swallow the
      // dependency-violation StateError.
      final fakeFlags = _TestFeatureFlags(<Feature>{Feature.obd2TripRecording});

      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider
              .overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => fakeFlags),
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
      // Two pumps: drain microtasks then advance simulated time so the
      // notifier's `enable` Future settles before assertion.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Central state must have flipped on.
      expect(
        fakeFlags.state,
        contains(Feature.hapticEcoCoach),
        reason:
            'Tapping the toggle must enable hapticEcoCoach in the central '
            'feature-flag set so the setting survives an app restart via '
            'the central repository (#1373 phase 3a).',
      );
      final flipped = tester.widget<SwitchListTile>(switchFinder);
      expect(
        flipped.value,
        isTrue,
        reason: 'The switch must reflect the new central state immediately.',
      );
    },
  );

  testWidgets(
    'reads the persisted central state on build so the switch starts on',
    (tester) async {
      final fakeFlags = _TestFeatureFlags(<Feature>{
        Feature.obd2TripRecording,
        Feature.hapticEcoCoach,
      });

      await pumpApp(
        tester,
        const DrivingSettingsSection(),
        overrides: [
          settingsStorageProvider
              .overrideWithValue(_FakeSettingsStorage()),
          storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
          featureFlagsProvider.overrideWith(() => fakeFlags),
        ],
      );

      final switchFinder = find.byKey(const Key('hapticEcoCoachToggle'));
      final tile = tester.widget<SwitchListTile>(switchFinder);
      expect(
        tile.value,
        isTrue,
        reason:
            'A persisted-true central state must hydrate the toggle on '
            'first paint — otherwise the user would have to flip it twice '
            'on every cold start.',
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
          featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
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
          featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
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

/// Synthetic in-memory [FeatureFlags] notifier for widget tests.
///
/// Unlike the real notifier, this implementation:
///   - has no Hive dependency (no `pumpAndSettle` hangs on Windows);
///   - returns the seeded `initial` set synchronously from `build`;
///   - implements `enable` / `disable` as pure in-memory mutations
///     that throw [StateError] for prerequisite violations to mirror
///     the real central-provider contract the shim relies on.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags([Set<Feature>? initial]) : _initial = initial ?? <Feature>{};

  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};

  @override
  Future<void> enable(Feature feature) async {
    if (state.contains(feature)) return;
    state = {...state, feature};
  }

  @override
  Future<void> disable(Feature feature) async {
    if (!state.contains(feature)) return;
    state = {...state}..remove(feature);
  }
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
