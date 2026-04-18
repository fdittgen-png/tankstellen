import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Uses a real [HiveStorage] wired to a temp Hive dir so the repository's
/// JSON round-trips exercise the real serialisation path.
void main() {
  late ProfileRepository repo;
  late HiveStorage storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('profile_repo_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    storage = HiveStorage();
    repo = ProfileRepository(storage);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('createProfile', () {
    test('creates a profile with a fresh UUID and persists it', () async {
      final p = await repo.createProfile(name: 'Daily');
      expect(p.name, 'Daily');
      expect(p.id, isNotEmpty);
      expect(p.preferredFuelType, FuelType.e10);
      expect(p.defaultSearchRadius, 10.0);
      expect(repo.getAllProfiles(), hasLength(1));
    });

    test('first profile becomes the active one automatically',
        () async {
      final p = await repo.createProfile(name: 'Only');
      expect(repo.getActiveProfile()?.id, p.id);
    });

    test('second profile does not unseat the first as active',
        () async {
      final a = await repo.createProfile(name: 'A');
      await repo.createProfile(name: 'B');
      expect(repo.getActiveProfile()?.id, a.id);
    });

    test('accepts country + language + radius + fuel overrides',
        () async {
      final p = await repo.createProfile(
        name: 'Travel',
        preferredFuelType: FuelType.diesel,
        defaultSearchRadius: 25,
        countryCode: 'DE',
        languageCode: 'de',
      );
      expect(p.preferredFuelType, FuelType.diesel);
      expect(p.defaultSearchRadius, 25);
      expect(p.countryCode, 'DE');
      expect(p.languageCode, 'de');
    });
  });

  group('getAllProfiles / getActiveProfile', () {
    test('empty store: both return null/empty', () {
      expect(repo.getActiveProfile(), isNull);
      expect(repo.getAllProfiles(), isEmpty);
    });

    test('legacy "search" landingScreen is rewritten to "nearest" on read',
        () async {
      // Write a raw profile map with the obsolete "search" value
      // bypassing createProfile (which only accepts current enum
      // values).
      const id = 'legacy-1';
      await storage.saveProfile(id, {
        'id': id,
        'name': 'Legacy',
        'preferredFuelType': 'e10',
        'defaultSearchRadius': 10.0,
        'landingScreen': 'search',
        'favoriteStationIds': <String>[],
      });
      await storage.setActiveProfileId(id);

      final p = repo.getActiveProfile();
      expect(p, isNotNull);
      expect(p!.landingScreen, LandingScreen.nearest);
    });
  });

  group('updateProfile', () {
    test('overwrites the existing profile in place', () async {
      final p = await repo.createProfile(name: 'Original');
      await repo.updateProfile(p.copyWith(name: 'Renamed'));
      expect(repo.getActiveProfile()?.name, 'Renamed');
      expect(repo.getAllProfiles(), hasLength(1));
    });
  });

  group('deleteProfile', () {
    test('deleting the active profile reassigns to the next one',
        () async {
      final a = await repo.createProfile(name: 'A');
      final b = await repo.createProfile(name: 'B');
      expect(repo.getActiveProfile()?.id, a.id);

      await repo.deleteProfile(a.id);

      expect(repo.getAllProfiles().map((p) => p.id).toList(), [b.id]);
      expect(repo.getActiveProfile()?.id, b.id);
    });

    test('deleting an inactive profile keeps the active pointer',
        () async {
      final a = await repo.createProfile(name: 'A');
      final b = await repo.createProfile(name: 'B');
      await repo.deleteProfile(b.id);
      expect(repo.getActiveProfile()?.id, a.id);
    });

    test('deleting the only profile leaves no active profile',
        () async {
      final a = await repo.createProfile(name: 'A');
      await repo.deleteProfile(a.id);
      expect(repo.getAllProfiles(), isEmpty);
      // activeProfileId is still set in storage but the profile is
      // gone; getActiveProfile returns null because the lookup fails.
      expect(repo.getActiveProfile(), isNull);
    });
  });

  group('setActiveProfile', () {
    test('switches the active profile id', () async {
      final a = await repo.createProfile(name: 'A');
      final b = await repo.createProfile(name: 'B');
      await repo.setActiveProfile(b.id);
      expect(repo.getActiveProfile()?.id, b.id);
      // Create another and confirm the new selection persists.
      await repo.createProfile(name: 'C');
      expect(repo.getActiveProfile()?.id, b.id);
      expect(a.id, isNot(b.id));
    });
  });

  group('ensureDefaultProfile', () {
    test('creates a "Standard" profile when none exist', () async {
      final p = await repo.ensureDefaultProfile();
      expect(p.name, 'Standard');
      expect(repo.getAllProfiles(), hasLength(1));
    });

    test('returns the active profile when one exists', () async {
      final a = await repo.createProfile(name: 'Existing');
      final p = await repo.ensureDefaultProfile();
      expect(p.id, a.id);
      expect(repo.getAllProfiles(), hasLength(1));
    });
  });

  group('migrateProfileCountryLanguage', () {
    test('backfills country and language from legacy global settings',
        () async {
      final p = await repo.createProfile(name: 'Old');
      // Pre-migration state: profile has no country/language, but
      // the old global settings carry them.
      await storage.putSetting('active_country_code', 'FR');
      await storage.putSetting('active_language_code', 'fr');

      await repo.migrateProfileCountryLanguage();

      final migrated = repo.getAllProfiles().firstWhere((x) => x.id == p.id);
      expect(migrated.countryCode, 'FR');
      expect(migrated.languageCode, 'fr');
    });

    test('does not overwrite fields the profile already has',
        () async {
      final p = await repo.createProfile(
        name: 'Already set',
        countryCode: 'DE',
        languageCode: 'de',
      );
      await storage.putSetting('active_country_code', 'FR');
      await storage.putSetting('active_language_code', 'fr');

      await repo.migrateProfileCountryLanguage();

      final after = repo.getAllProfiles().firstWhere((x) => x.id == p.id);
      expect(after.countryCode, 'DE');
      expect(after.languageCode, 'de');
    });

    test('no legacy settings → no-op', () async {
      final p = await repo.createProfile(name: 'As-is');
      await repo.migrateProfileCountryLanguage();
      final after = repo.getAllProfiles().firstWhere((x) => x.id == p.id);
      expect(after.countryCode, isNull);
      expect(after.languageCode, isNull);
    });
  });
}
