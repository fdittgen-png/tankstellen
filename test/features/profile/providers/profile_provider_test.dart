// `gamificationEnabled` is `@Deprecated` post-#1373 phase 3b but the
// field is still around (kept for the one-shot migration read in
// `legacy_toggle_migrator.dart`). These tests pin the persistence /
// copyWith semantics that the migrator relies on, so they read the
// deprecated field deliberately.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests for ProfileRepository (the core logic behind the provider).
///
/// The ActiveProfile provider is a thin Riverpod wrapper around the
/// repository, so we test the repository directly with a stubbed HiveStorage.
void main() {
  group('ProfileRepository', () {
    late _InMemoryHiveStorage storage;
    late ProfileRepository repo;

    setUp(() {
      storage = _InMemoryHiveStorage();
      repo = ProfileRepository(storage);
    });

    // -----------------------------------------------------------------------
    // getActiveProfile
    // -----------------------------------------------------------------------
    group('getActiveProfile', () {
      test('returns null when no profile exists', () {
        expect(repo.getActiveProfile(), isNull);
      });

      test('returns null when active ID is set but profile missing', () {
        storage.setActiveProfileIdSync('nonexistent');
        expect(repo.getActiveProfile(), isNull);
      });

      test('returns correct profile when active ID matches', () async {
        final profile = await repo.createProfile(name: 'Test');
        final active = repo.getActiveProfile();
        expect(active, isNotNull);
        expect(active!.id, profile.id);
        expect(active.name, 'Test');
      });
    });

    // -----------------------------------------------------------------------
    // createProfile
    // -----------------------------------------------------------------------
    group('createProfile', () {
      test('creates profile with default values', () async {
        final profile = await repo.createProfile(name: 'Default');
        expect(profile.name, 'Default');
        expect(profile.preferredFuelType, FuelType.e10);
        expect(profile.defaultSearchRadius, 10.0);
        expect(profile.landingScreen, LandingScreen.nearest);
      });

      test('creates profile with custom values', () async {
        final profile = await repo.createProfile(
          name: 'Custom',
          preferredFuelType: FuelType.diesel,
          defaultSearchRadius: 25.0,
          landingScreen: LandingScreen.favorites,
          homeZipCode: '10115',
          countryCode: 'DE',
          languageCode: 'de',
        );
        expect(profile.preferredFuelType, FuelType.diesel);
        expect(profile.defaultSearchRadius, 25.0);
        expect(profile.landingScreen, LandingScreen.favorites);
        expect(profile.homeZipCode, '10115');
        expect(profile.countryCode, 'DE');
        expect(profile.languageCode, 'de');
      });

      test('first profile becomes active automatically', () async {
        final profile = await repo.createProfile(name: 'First');
        expect(storage.getActiveProfileId(), profile.id);
      });

      test('second profile does not change active profile', () async {
        final first = await repo.createProfile(name: 'First');
        await repo.createProfile(name: 'Second');
        expect(storage.getActiveProfileId(), first.id);
      });

      test('generates unique IDs for each profile', () async {
        final p1 = await repo.createProfile(name: 'P1');
        final p2 = await repo.createProfile(name: 'P2');
        expect(p1.id, isNot(p2.id));
      });
    });

    // -----------------------------------------------------------------------
    // getAllProfiles
    // -----------------------------------------------------------------------
    group('getAllProfiles', () {
      test('returns empty list when no profiles exist', () {
        expect(repo.getAllProfiles(), isEmpty);
      });

      test('returns all created profiles', () async {
        await repo.createProfile(name: 'P1');
        await repo.createProfile(name: 'P2');
        await repo.createProfile(name: 'P3');

        final all = repo.getAllProfiles();
        expect(all, hasLength(3));
        expect(
            all.map((p) => p.name).toList(), containsAll(['P1', 'P2', 'P3']));
      });
    });

    // -----------------------------------------------------------------------
    // setActiveProfile
    // -----------------------------------------------------------------------
    group('setActiveProfile', () {
      test('changes active profile ID', () async {
        await repo.createProfile(name: 'P1');
        final p2 = await repo.createProfile(name: 'P2');

        await repo.setActiveProfile(p2.id);
        final active = repo.getActiveProfile();
        expect(active!.id, p2.id);
        expect(active.name, 'P2');
      });
    });

    // -----------------------------------------------------------------------
    // updateProfile
    // -----------------------------------------------------------------------
    group('updateProfile', () {
      test('persists changes', () async {
        final original = await repo.createProfile(name: 'Original');
        final updated = original.copyWith(
          name: 'Updated',
          preferredFuelType: FuelType.diesel,
        );

        await repo.updateProfile(updated);

        final fetched = repo.getActiveProfile();
        expect(fetched!.name, 'Updated');
        expect(fetched.preferredFuelType, FuelType.diesel);
      });

      test('preserves other fields when updating one', () async {
        final original = await repo.createProfile(
          name: 'Test',
          homeZipCode: '75001',
          countryCode: 'FR',
        );
        final updated = original.copyWith(name: 'Renamed');

        await repo.updateProfile(updated);

        final fetched = repo.getActiveProfile();
        expect(fetched!.name, 'Renamed');
        expect(fetched.homeZipCode, '75001');
        expect(fetched.countryCode, 'FR');
      });
    });

    // -----------------------------------------------------------------------
    // deleteProfile
    // -----------------------------------------------------------------------
    group('deleteProfile', () {
      test('removes profile from storage', () async {
        final profile = await repo.createProfile(name: 'ToDelete');
        await repo.deleteProfile(profile.id);

        final all = repo.getAllProfiles();
        expect(all, isEmpty);
      });

      test('switches active to remaining profile when active is deleted',
          () async {
        final p1 = await repo.createProfile(name: 'P1');
        final p2 = await repo.createProfile(name: 'P2');

        // p1 is active (first created)
        await repo.deleteProfile(p1.id);

        // Active should switch to p2.
        expect(storage.getActiveProfileId(), p2.id);
      });
    });

    // -----------------------------------------------------------------------
    // ensureDefaultProfile
    // -----------------------------------------------------------------------
    group('ensureDefaultProfile', () {
      test('creates Standard profile when none exist', () async {
        final profile = await repo.ensureDefaultProfile();
        expect(profile.name, 'Standard');
        expect(repo.getAllProfiles(), hasLength(1));
      });

      test('returns existing active profile when profiles exist', () async {
        final existing = await repo.createProfile(name: 'Existing');
        final result = await repo.ensureDefaultProfile();
        expect(result.id, existing.id);
        expect(repo.getAllProfiles(), hasLength(1));
      });
    });
  });

  // -------------------------------------------------------------------------
  // UserProfile model tests
  // -------------------------------------------------------------------------
  group('UserProfile', () {
    test('copyWith creates a modified copy', () {
      const profile = UserProfile(id: 'abc', name: 'Test');
      final copy = profile.copyWith(name: 'Changed');
      expect(copy.name, 'Changed');
      expect(copy.id, 'abc');
    });

    test('default values are correct', () {
      const profile = UserProfile(id: 'abc', name: 'Test');
      expect(profile.preferredFuelType, FuelType.e10);
      expect(profile.defaultSearchRadius, 10.0);
      expect(profile.landingScreen, LandingScreen.nearest);
      expect(profile.favoriteStationIds, isEmpty);
      expect(profile.autoUpdatePosition, isFalse);
      expect(profile.showFuel, isTrue);
      expect(profile.showElectric, isTrue);
      expect(profile.ratingMode, 'local');
      // #1194 — gamification toggle defaults to ON so existing users
      // see no behaviour change.
      expect(profile.gamificationEnabled, isTrue);
    });

    test('gamificationEnabled defaults to true on legacy JSON missing the key',
        () {
      // Mirrors the migration path for users upgrading from a build
      // that didn't persist this field — fromJson must not throw and
      // must default to true.
      final json = <String, dynamic>{
        'id': 'legacy',
        'name': 'Legacy',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.gamificationEnabled, isTrue);
    });

    test('copyWith preserves and overrides gamificationEnabled', () {
      const profile = UserProfile(id: 'abc', name: 'Test');
      // Default flips through copyWith.
      final disabled = profile.copyWith(gamificationEnabled: false);
      expect(disabled.gamificationEnabled, isFalse);
      expect(disabled.id, 'abc');
      // copyWith without the field preserves the previous value.
      final preserved = disabled.copyWith(name: 'Renamed');
      expect(preserved.gamificationEnabled, isFalse);
      expect(preserved.name, 'Renamed');
    });

    test('JSON roundtrip preserves gamificationEnabled', () {
      const enabled = UserProfile(id: 'a', name: 'A');
      const disabled = UserProfile(
        id: 'b',
        name: 'B',
        gamificationEnabled: false,
      );

      final restoredEnabled = UserProfile.fromJson(enabled.toJson());
      final restoredDisabled = UserProfile.fromJson(disabled.toJson());

      expect(restoredEnabled.gamificationEnabled, isTrue);
      expect(restoredDisabled.gamificationEnabled, isFalse);
    });

    test('toJson and fromJson roundtrip', () {
      const profile = UserProfile(
        id: 'test-id',
        name: 'Test Profile',
        preferredFuelType: FuelType.diesel,
        defaultSearchRadius: 25.0,
        homeZipCode: '10115',
        countryCode: 'DE',
        languageCode: 'de',
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.preferredFuelType, profile.preferredFuelType);
      expect(restored.defaultSearchRadius, profile.defaultSearchRadius);
      expect(restored.homeZipCode, profile.homeZipCode);
      expect(restored.countryCode, profile.countryCode);
      expect(restored.languageCode, profile.languageCode);
    });
  });

  // -------------------------------------------------------------------------
  // LandingScreen
  // -------------------------------------------------------------------------
  group('LandingScreen', () {
    test('has correct English display names', () {
      expect(LandingScreen.nearest.displayName, 'Nearest stations');
      expect(LandingScreen.favorites.displayName, 'Favorites');
      expect(LandingScreen.map.displayName, 'Map');
      expect(LandingScreen.cheapest.displayName, 'Cheapest nearby');
    });

    test('localizedName returns German for de', () {
      expect(LandingScreen.nearest.localizedName('de'), 'Nächste Tankstellen');
      expect(LandingScreen.favorites.localizedName('de'), 'Favoriten');
    });

    test('localizedName returns French for fr', () {
      expect(LandingScreen.nearest.localizedName('fr'), 'À proximité');
      expect(LandingScreen.favorites.localizedName('fr'), 'Favoris');
    });

    test('localizedName falls back to English for unknown language', () {
      expect(LandingScreen.nearest.localizedName('xx'), 'Nearest stations');
    });

    test('search is removed from the enum', () {
      final names = LandingScreen.values.map((v) => v.name).toList();
      expect(names, isNot(contains('search')));
      expect(LandingScreen.values, hasLength(4));
    });
  });

  // -------------------------------------------------------------------------
  // Legacy `search` landing migration
  // -------------------------------------------------------------------------
  group('ProfileRepository legacy landingScreen migration', () {
    late _InMemoryHiveStorage storage;
    late ProfileRepository repo;

    setUp(() {
      storage = _InMemoryHiveStorage();
      repo = ProfileRepository(storage);
    });

    test('getActiveProfile rewrites legacy "search" value to "nearest"',
        () async {
      // Simulate a profile saved before LandingScreen.search was removed.
      const id = 'legacy-profile';
      storage._profiles[id] = {
        'id': id,
        'name': 'Legacy',
        'landingScreen': 'search',
      };
      storage._activeProfileId = id;

      final profile = repo.getActiveProfile();
      expect(profile, isNotNull);
      expect(profile!.landingScreen, LandingScreen.nearest);
    });

    test('getAllProfiles rewrites legacy "LandingScreen.search" form',
        () async {
      storage._profiles['legacy'] = {
        'id': 'legacy',
        'name': 'Legacy',
        'landingScreen': 'LandingScreen.search',
      };
      storage._profiles['fresh'] = {
        'id': 'fresh',
        'name': 'Fresh',
        'landingScreen': 'favorites',
      };

      final all = repo.getAllProfiles();
      expect(all, hasLength(2));
      final legacy = all.firstWhere((p) => p.id == 'legacy');
      final fresh = all.firstWhere((p) => p.id == 'fresh');
      expect(legacy.landingScreen, LandingScreen.nearest);
      expect(fresh.landingScreen, LandingScreen.favorites);
    });
  });
}

// ---------------------------------------------------------------------------
// In-memory HiveStorage fake
// ---------------------------------------------------------------------------

/// Extends Mock to satisfy the HiveStorage type while providing real
/// in-memory implementations for the methods ProfileRepository uses.
class _InMemoryHiveStorage extends Mock implements HiveStorage {
  final Map<String, Map<String, dynamic>> _profiles = {};
  String? _activeProfileId;
  final Map<String, dynamic> _settings = {};

  void setActiveProfileIdSync(String id) => _activeProfileId = id;

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
