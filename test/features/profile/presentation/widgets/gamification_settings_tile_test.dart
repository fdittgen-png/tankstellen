import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/presentation/widgets/gamification_settings_tile.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the gamification opt-out switch tile (#1194).
///
/// As of #1373 phase 3b the tile reads/writes through the central
/// [featureFlagsProvider] rather than mutating the active
/// [UserProfile.gamificationEnabled] field. The switch's KEY, label,
/// subtitle and null-profile guard are unchanged from the pre-3b
/// surface — this test file pins all four behaviours plus the new
/// reactive-rebuild path that fires when the central state mutates
/// via override.
///
/// Tests intentionally bypass the real Hive-backed
/// [FeatureFlagsRepository] via a synthetic [_TestFeatureFlags]
/// notifier — this matches the haptic-eco-coach test pattern from
/// `feedback_hive_widget_test_teardown.md` and avoids fire-and-forget
/// `box.put` hangs on Windows during `pumpAndSettle`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the title and subtitle when an active profile exists',
      (tester) async {
    final storage = _InMemoryHiveStorage();
    final repo = ProfileRepository(storage);
    await repo.createProfile(name: 'P1');
    final fakeFlags = _TestFeatureFlags(<Feature>{
      Feature.obd2TripRecording,
      Feature.gamification,
    });

    await pumpApp(
      tester,
      const GamificationSettingsTile(),
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        featureFlagsProvider.overrideWith(() => fakeFlags),
      ],
    );

    expect(find.text('Show achievements & scores'), findsOneWidget);
    expect(
      find.textContaining('badges, scores and trophy icons'),
      findsOneWidget,
    );
    final switchWidget = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(
      switchWidget.value,
      isTrue,
      reason:
          'Pre-seeded central state with Feature.gamification on must '
          'hydrate the switch on first paint — otherwise the user would '
          'have to flip it twice on every cold start.',
    );
  });

  testWidgets('renders nothing when there is no active profile',
      (tester) async {
    final storage = _InMemoryHiveStorage();
    final repo = ProfileRepository(storage);

    await pumpApp(
      tester,
      const GamificationSettingsTile(),
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        featureFlagsProvider.overrideWith(() => _TestFeatureFlags()),
      ],
    );

    expect(
      find.byType(SwitchListTile),
      findsNothing,
      reason:
          'The null-profile guard MUST stay even after the 3b migration '
          '— the wider Settings screen still requires a loaded profile '
          'to render and existing test fixtures rely on this null-guard '
          'behaviour.',
    );
    expect(find.text('Show achievements & scores'), findsNothing);
  });

  testWidgets('tapping the switch flips the central feature-flag set',
      (tester) async {
    final storage = _InMemoryHiveStorage();
    final repo = ProfileRepository(storage);
    await repo.createProfile(name: 'P1');
    // Seed prerequisite (obd2TripRecording) so the central enable
    // succeeds — without it the shim would silently swallow the
    // dependency-violation StateError and the switch would not flip.
    final fakeFlags = _TestFeatureFlags(<Feature>{Feature.obd2TripRecording});

    await pumpApp(
      tester,
      const GamificationSettingsTile(),
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        featureFlagsProvider.overrideWith(() => fakeFlags),
      ],
    );

    final switchFinder = find.byType(SwitchListTile);
    expect(
      tester.widget<SwitchListTile>(switchFinder).value,
      isFalse,
      reason: 'Initial: gamification absent from central set → switch off.',
    );

    await tester.tap(switchFinder);
    // Two pumps: drain microtasks then advance simulated time so the
    // notifier's `enable` Future settles before assertion. Pattern
    // mirrors `feedback_hive_widget_test_teardown.md`.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      fakeFlags.state,
      contains(Feature.gamification),
      reason:
          'Tapping the toggle must enable gamification in the central '
          'feature-flag set so the setting survives an app restart via '
          'the central repository (#1373 phase 3b). The legacy '
          'UserProfile.gamificationEnabled mutation path is gone.',
    );
    expect(
      tester.widget<SwitchListTile>(switchFinder).value,
      isTrue,
      reason: 'The switch must reflect the new central state immediately.',
    );
  });

  testWidgets(
    'reactively flips when featureFlagsProvider mutates externally',
    (tester) async {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      await repo.createProfile(name: 'P1');
      final fakeFlags = _TestFeatureFlags(<Feature>{
        Feature.obd2TripRecording,
        Feature.gamification,
      });

      await pumpApp(
        tester,
        const GamificationSettingsTile(),
        overrides: [
          profileRepositoryProvider.overrideWithValue(repo),
          featureFlagsProvider.overrideWith(() => fakeFlags),
        ],
      );

      final switchFinder = find.byType(SwitchListTile);
      expect(
        tester.widget<SwitchListTile>(switchFinder).value,
        isTrue,
        reason: 'Pre-seeded with gamification on → switch starts on.',
      );

      // External mutation: another consumer disables gamification on
      // the central provider (e.g. a different settings surface or a
      // deep-link handler). The tile must rebuild on the next frame.
      final element = tester.element(find.byType(GamificationSettingsTile));
      final container = ProviderScope.containerOf(element);
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.gamification);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.widget<SwitchListTile>(switchFinder).value,
        isFalse,
        reason:
            'External writes to featureFlagsProvider must propagate to '
            'the tile so the visible switch reflects the central state '
            'without requiring a manual rebuild trigger.',
      );
    },
  );
}

/// Synthetic in-memory [FeatureFlags] notifier for widget tests.
///
/// Mirrors the equivalent test double in
/// `test/features/driving/presentation/driving_settings_section_test.dart`
/// — the contract is the same: in-memory state, no Hive dependency,
/// no `pumpAndSettle` hangs on Windows.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags([Set<Feature>? initial])
      : _initial = initial ?? <Feature>{};

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

/// Minimal in-memory HiveStorage stand-in mirroring the helper used in
/// `profile_provider_test.dart`.
class _InMemoryHiveStorage extends Mock implements HiveStorage {
  final Map<String, Map<String, dynamic>> _profiles = {};
  String? _activeProfileId;
  final Map<String, dynamic> _settings = {};

  @override
  String? getActiveProfileId() => _activeProfileId;

  @override
  Future<void> setActiveProfileId(String id) async {
    _activeProfileId = id;
  }

  @override
  Map<String, dynamic>? getProfile(String id) {
    final data = _profiles[id];
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  @override
  List<Map<String, dynamic>> getAllProfiles() =>
      _profiles.values.map((p) => Map<String, dynamic>.from(p)).toList();

  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) async {
    _profiles[id] = Map<String, dynamic>.from(profile);
  }

  @override
  Future<void> deleteProfile(String id) async {
    _profiles.remove(id);
  }

  @override
  int get profileCount => _profiles.length;

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _settings[key] = value;
  }
}
