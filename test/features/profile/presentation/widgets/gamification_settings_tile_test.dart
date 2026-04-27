import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/presentation/widgets/gamification_settings_tile.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the gamification opt-out switch tile (#1194).
void main() {
  testWidgets('renders the title and subtitle when an active profile exists',
      (tester) async {
    final storage = _InMemoryHiveStorage();
    final repo = ProfileRepository(storage);
    await repo.createProfile(name: 'P1');

    await pumpApp(
      tester,
      const GamificationSettingsTile(),
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ],
    );

    expect(find.text('Show achievements & scores'), findsOneWidget);
    expect(
      find.textContaining('badges, scores and trophy icons'),
      findsOneWidget,
    );
    // Switch is on by default for new profiles.
    final switchWidget = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchWidget.value, isTrue);
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
      ],
    );

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Show achievements & scores'), findsNothing);
  });

  testWidgets('tapping the switch flips the gamification provider',
      (tester) async {
    final storage = _InMemoryHiveStorage();
    final repo = ProfileRepository(storage);
    await repo.createProfile(name: 'P1');

    await pumpApp(
      tester,
      const GamificationSettingsTile(),
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ],
    );

    // Initial state: switch is on, provider returns true.
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    // Verify the underlying profile + provider both updated. We rebuild
    // the ProviderContainer from the tree to assert the gamification
    // provider directly reflects the new flag.
    final element = tester.element(find.byType(GamificationSettingsTile));
    final container = ProviderScope.containerOf(element);
    expect(container.read(gamificationEnabledProvider), isFalse);
    expect(repo.getActiveProfile()?.gamificationEnabled, isFalse);
  });
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
