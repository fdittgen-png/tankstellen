import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';

/// Tests for [gamificationEnabledProvider] (#1194 — opt-out toggle).
///
/// The provider derives its value from the active [UserProfile.gamificationEnabled]
/// flag. A null profile (cold-launch / first-frame) defaults to `true`
/// so the existing UI keeps rendering until the profile resolves.
void main() {
  group('gamificationEnabledProvider', () {
    test('returns true when no profile is loaded', () {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      // No profile created → activeProfile is null → provider returns
      // the safe default.
      expect(container.read(activeProfileProvider), isNull);
      expect(container.read(gamificationEnabledProvider), isTrue);
    });

    test('returns true when profile has gamificationEnabled: true', () async {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      await repo.createProfile(name: 'P1');

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      // Default profile has gamificationEnabled: true.
      expect(container.read(activeProfileProvider)?.gamificationEnabled, isTrue);
      expect(container.read(gamificationEnabledProvider), isTrue);
    });

    test('returns false when profile has gamificationEnabled: false',
        () async {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      final profile = await repo.createProfile(name: 'P1');
      await repo.updateProfile(
        profile.copyWith(gamificationEnabled: false),
      );

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      expect(container.read(gamificationEnabledProvider), isFalse);
    });

    test('reactively flips when the active profile updates the flag',
        () async {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      final profile = await repo.createProfile(name: 'P1');

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      expect(container.read(gamificationEnabledProvider), isTrue);

      // Mutate the profile via the provider's notifier — that's the
      // path the settings UI uses.
      await container.read(activeProfileProvider.notifier).updateProfile(
            profile.copyWith(gamificationEnabled: false),
          );
      await Future.microtask(() {});

      expect(container.read(gamificationEnabledProvider), isFalse);

      // Flip back.
      await container.read(activeProfileProvider.notifier).updateProfile(
            profile.copyWith(gamificationEnabled: true),
          );
      await Future.microtask(() {});

      expect(container.read(gamificationEnabledProvider), isTrue);
    });
  });
}

/// Minimal in-memory HiveStorage stand-in. Mirrors the helper used in
/// `profile_provider_test.dart` so the two tests share a familiar shape.
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
  List<Map<String, dynamic>> getAllProfiles() {
    return _profiles.values
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

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
