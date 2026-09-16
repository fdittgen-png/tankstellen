// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';

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
    test('deleting the active profile reassigns to a survivor', () async {
      final a = await repo.createProfile(name: 'A');
      final b = await repo.createProfile(name: 'B');
      expect(repo.getActiveProfile()?.id, a.id);

      await repo.deleteProfile(a.id);

      expect(repo.getAllProfiles().map((p) => p.id).toList(), [b.id]);
      expect(repo.getActiveProfile()?.id, b.id);
    });

    // #4267 — the successor used to be `remaining.first` over an unordered
    // Hive read, so the user's active COUNTRY could land anywhere.
    test('the successor is the same whatever order the profiles were '
        'created in', () async {
      Future<String> winnerFor(List<String> countries) async {
        // Fresh store per permutation.
        for (final p in repo.getAllProfiles()) {
          await repo.deleteProfile(p.id);
        }
        final active = await repo.createProfile(name: 'Active', countryCode: 'ZZ');
        await repo.setActiveProfile(active.id);
        for (final c in countries) {
          await repo.createProfile(name: 'P-$c', countryCode: c);
        }
        await repo.deleteProfile(active.id);
        return repo.getActiveProfile()!.countryCode!;
      }

      final forward = await winnerFor(['IT', 'AT', 'FR']);
      final reverse = await winnerFor(['FR', 'AT', 'IT']);
      final shuffled = await winnerFor(['AT', 'FR', 'IT']);

      expect(forward, reverse);
      expect(forward, shuffled);
      expect(forward, 'AT',
          reason: 'ordered by country code, so AT wins over FR and IT '
              'regardless of insertion order');
    });

    test('a country-bound profile outranks a country-less one', () async {
      final active = await repo.createProfile(name: 'Active', countryCode: 'ZZ');
      await repo.setActiveProfile(active.id);
      await repo.createProfile(name: 'AAA no country');
      await repo.createProfile(name: 'ZZZ with country', countryCode: 'FR');

      await repo.deleteProfile(active.id);

      expect(repo.getActiveProfile()?.countryCode, 'FR',
          reason: 'a profile with no country gives the user no country '
              'context, so it is the last resort');
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

  // #4268 — activation must be the caller's decision, not a side effect.
  group('createProfile activateIfNone', () {
    test('activateIfNone: false leaves an empty active slot empty', () async {
      final p = await repo.createProfile(name: 'Route-created',
          countryCode: 'AT', activateIfNone: false);
      expect(repo.getAllProfiles().map((x) => x.id), contains(p.id));
      expect(repo.getActiveProfile(), isNull,
          reason: 'an automatic country setup must not claim the active '
              'country just because none was set');
    });

    test('activateIfNone: false never unseats an existing active profile',
        () async {
      final first = await repo.createProfile(name: 'First');
      await repo.createProfile(name: 'Second', activateIfNone: false);
      expect(repo.getActiveProfile()?.id, first.id);
    });

    test('the default still activates the first profile — onboarding is '
        'unchanged', () async {
      final p = await repo.createProfile(name: 'Onboarding');
      expect(repo.getActiveProfile()?.id, p.id);
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

  // #2597 — one profile per country.
  group('isCountryTaken', () {
    test('false when no profile owns the country', () async {
      await repo.createProfile(name: 'DE', countryCode: 'DE');
      expect(repo.isCountryTaken('FR'), isFalse);
    });

    test('true when another profile owns the country', () async {
      await repo.createProfile(name: 'DE', countryCode: 'DE');
      expect(repo.isCountryTaken('DE'), isTrue);
    });

    test('excludeProfileId lets a profile keep its own country', () async {
      final p = await repo.createProfile(name: 'DE', countryCode: 'DE');
      expect(repo.isCountryTaken('DE', excludeProfileId: p.id), isFalse,
          reason: 'the profile being edited must not count itself as a clash');
    });

    test('empty / unset country is never taken', () async {
      await repo.createProfile(name: 'No country');
      expect(repo.isCountryTaken(''), isFalse);
    });
  });

  group('dedupeCountryProfiles (#2597 migration)', () {
    test('keeps the ACTIVE profile and clears the others for that country',
        () async {
      final a = await repo.createProfile(name: 'DE-A', countryCode: 'DE');
      final b = await repo.createProfile(name: 'DE-B', countryCode: 'DE');
      final c = await repo.createProfile(name: 'DE-C', countryCode: 'DE');
      // Make B the active one — it must be the keeper.
      await repo.setActiveProfile(b.id);

      final cleared = await repo.dedupeCountryProfiles();
      expect(cleared, 2);

      UserProfile byId(String id) =>
          repo.getAllProfiles().firstWhere((p) => p.id == id);
      expect(byId(b.id).countryCode, 'DE', reason: 'active keeper retains DE');
      expect(byId(a.id).countryCode, isNull);
      expect(byId(c.id).countryCode, isNull);
      // No profile was deleted — only the country binding cleared.
      expect(repo.getAllProfiles(), hasLength(3));
    });

    test(
        'with no active profile in the group, keeps EXACTLY ONE for the '
        'country and clears the rest', () async {
      final a = await repo.createProfile(name: 'DE-A', countryCode: 'DE');
      final b = await repo.createProfile(name: 'DE-B', countryCode: 'DE');
      // First profile (a) is active by createProfile; switch active away to a
      // DIFFERENT country so neither DE profile is the active one.
      final other = await repo.createProfile(name: 'FR', countryCode: 'FR');
      await repo.setActiveProfile(other.id);

      final cleared = await repo.dedupeCountryProfiles();
      expect(cleared, 1);

      // The keeper identity is an implementation tie-break (storage order),
      // so assert the INVARIANT, not which one survives: exactly one of the
      // two DE profiles still owns DE, the other is cleared.
      final deOwners = repo
          .getAllProfiles()
          .where((p) => (p.id == a.id || p.id == b.id) && p.countryCode == 'DE')
          .toList();
      expect(deOwners, hasLength(1),
          reason: 'exactly one DE profile keeps its country');
    });

    test('leaves a country with a single profile untouched', () async {
      final a = await repo.createProfile(name: 'DE', countryCode: 'DE');
      final fr = await repo.createProfile(name: 'FR', countryCode: 'FR');

      final cleared = await repo.dedupeCountryProfiles();
      expect(cleared, 0);
      expect(repo.getAllProfiles().firstWhere((p) => p.id == a.id).countryCode,
          'DE');
      expect(repo.getAllProfiles().firstWhere((p) => p.id == fr.id).countryCode,
          'FR');
    });

    test('is idempotent — a second run clears nothing', () async {
      await repo.createProfile(name: 'DE-A', countryCode: 'DE');
      await repo.createProfile(name: 'DE-B', countryCode: 'DE');

      final first = await repo.dedupeCountryProfiles();
      expect(first, 1);
      final second = await repo.dedupeCountryProfiles();
      expect(second, 0, reason: 'rerun on already-deduped data is a no-op');
    });

    test('ignores profiles with no country', () async {
      await repo.createProfile(name: 'No country A');
      await repo.createProfile(name: 'No country B');
      final cleared = await repo.dedupeCountryProfiles();
      expect(cleared, 0,
          reason: 'null country is exempt from the one-per-country rule');
    });
  });

  // #4259 (Epic #4257) — cloning a profile for another country.
  group('cloneProfileForCountry', () {
    /// A source profile with NON-DEFAULT values in the fields
    /// `createProfile()` cannot express. Asserting defaults would prove
    /// nothing — the point is that these survive the clone.
    Future<UserProfile> richSource() async {
      final base = await repo.createProfile(
        name: 'France',
        preferredFuelType: FuelType.e10,
        countryCode: 'FR',
        languageCode: 'fr',
      );
      final rich = base.copyWith(
        defaultSearchRadius: 27.5,
        landingScreen: LandingScreen.map,
        routeSegmentKm: 80,
        avoidHighways: true,
        routeDetourBudgetKm: 12.5,
        minRouteSavingPerLiter: 0.07,
        routeSearchTopNPerSamplePoint: 3,
        routeSearchCriterion: RouteSearchCriterion.nearest,
        preferredAmenities: const [StationAmenity.carWash],
        defaultVehicleId: 'veh-1',
        hybridFuelChoice: FuelType.electric,
        approachRadiusKm: 2.5,
        approachPriceMode: ApproachPriceMode.cheapestInRadius,
        approachMinPollSeconds: 9,
        widgetColorScheme: 'green',
        widgetVariant: 'predictive',
        favoriteStationIds: const ['fr-123'],
        ratingMode: 'private',
        autoUpdatePosition: true,
        homeZipCode: '75001',
      );
      await repo.updateProfile(rich);
      return rich;
    }

    test('carries every country-independent setting to the clone', () async {
      final source = await richSource();
      final clone = repo.cloneProfileForCountry(
        source: source,
        countryCode: 'AT',
        fuel: FuelType.e5,
        name: 'Österreich',
      );

      expect(clone.defaultSearchRadius, 27.5);
      expect(clone.landingScreen, LandingScreen.map);
      expect(clone.routeSegmentKm, 80);
      expect(clone.avoidHighways, isTrue);
      expect(clone.routeDetourBudgetKm, 12.5);
      expect(clone.minRouteSavingPerLiter, 0.07);
      expect(clone.routeSearchTopNPerSamplePoint, 3);
      expect(clone.routeSearchCriterion, RouteSearchCriterion.nearest);
      expect(clone.preferredAmenities, const [StationAmenity.carWash]);
      expect(clone.defaultVehicleId, 'veh-1');
      expect(clone.hybridFuelChoice, FuelType.electric);
      expect(clone.approachRadiusKm, 2.5);
      expect(clone.approachPriceMode, ApproachPriceMode.cheapestInRadius);
      expect(clone.approachMinPollSeconds, 9);
      expect(clone.widgetColorScheme, 'green');
      expect(clone.widgetVariant, 'predictive');
      expect(clone.favoriteStationIds, const ['fr-123']);
      expect(clone.ratingMode, 'private');
      expect(clone.autoUpdatePosition, isTrue);
      expect(clone.homeZipCode, '75001');
    });

    test('changes only country, fuel, name and id', () async {
      final source = await richSource();
      final clone = repo.cloneProfileForCountry(
        source: source,
        countryCode: 'AT',
        fuel: FuelType.e5,
        name: 'Österreich',
      );
      expect(clone.countryCode, 'AT');
      expect(clone.preferredFuelType, FuelType.e5);
      expect(clone.name, 'Österreich');
      expect(clone.id, isNot(source.id));
      expect(clone.id, isNotEmpty);
    });

    test('keeps the source language — the UI language is not a property '
        'of the country being added', () async {
      final source = await richSource();
      final clone = repo.cloneProfileForCountry(
        source: source,
        countryCode: 'AT',
        fuel: FuelType.e5,
        name: 'Österreich',
      );
      expect(clone.languageCode, 'fr');
    });

    test('writes nothing by itself', () async {
      final source = await richSource();
      repo.cloneProfileForCountry(
        source: source,
        countryCode: 'AT',
        fuel: FuelType.e5,
        name: 'Österreich',
      );
      expect(repo.getAllProfiles(), hasLength(1),
          reason: 'the clone is a pure model build; the caller persists it');
    });
  });

  group('createMissingCountryProfiles', () {
    Future<UserProfile> frSource() => repo.createProfile(
          name: 'France',
          preferredFuelType: FuelType.e10,
          countryCode: 'FR',
          languageCode: 'fr',
        );

    CountryProfileProposal proposal(UserProfile src, String code,
            [FuelType fuel = FuelType.e5]) =>
        CountryProfileProposal(
          source: src,
          countryCode: code,
          fuel: fuel,
          name: code,
        );

    test('creates a profile per proposal', () async {
      final src = await frSource();
      final result = await repo.createMissingCountryProfiles(
          [proposal(src, 'AT'), proposal(src, 'IT')]);

      expect(result.created, hasLength(2));
      expect(result.skipped, isEmpty);
      expect(result.failed, isEmpty);
      expect(result.isComplete, isTrue);
      expect(result.hasChanges, isTrue);
      expect(repo.getAllProfiles().map((p) => p.countryCode),
          containsAll(['FR', 'AT', 'IT']));
    });

    test('does NOT change the active profile', () async {
      final src = await frSource();
      expect(repo.getActiveProfile()?.id, src.id);

      await repo.createMissingCountryProfiles(
          [proposal(src, 'AT'), proposal(src, 'IT')]);

      expect(repo.getActiveProfile()?.id, src.id,
          reason: 'Epic #4257 §C — creating profiles never activates them');
    });

    test('with NO active profile, still activates nothing (#4268)', () async {
      // Build a source without going through createProfile, so no
      // activation happens and the active id stays unset.
      const src = UserProfile(id: 'src-1', name: 'FR', countryCode: 'FR');
      await repo.updateProfile(src);
      expect(repo.getActiveProfile(), isNull);

      final result =
          await repo.createMissingCountryProfiles([proposal(src, 'AT')]);

      expect(result.created, hasLength(1));
      expect(repo.getActiveProfile(), isNull,
          reason: 'a route-created profile must not become the active '
              'country just because none was set');
    });

    test('an already-taken country is skipped, not duplicated', () async {
      final src = await frSource();
      await repo.createProfile(name: 'Austria', countryCode: 'AT');

      final result =
          await repo.createMissingCountryProfiles([proposal(src, 'AT')]);

      expect(result.created, isEmpty);
      expect(result.skipped, ['AT']);
      expect(result.isComplete, isTrue, reason: 'a skip is not a failure');
      expect(result.hasChanges, isFalse);
      expect(
          repo.getAllProfiles().where((p) => p.countryCode == 'AT'),
          hasLength(1));
    });

    test('is idempotent — a second identical batch creates nothing',
        () async {
      final src = await frSource();
      final proposals = [proposal(src, 'AT'), proposal(src, 'IT')];

      final first = await repo.createMissingCountryProfiles(proposals);
      final second = await repo.createMissingCountryProfiles(proposals);

      expect(first.created, hasLength(2));
      expect(second.created, isEmpty);
      expect(second.skipped, ['AT', 'IT']);
      expect(repo.getAllProfiles(), hasLength(3),
          reason: 'double tap / retry must not duplicate a country');
    });

    test('a duplicate country WITHIN one batch is caught by the per-write '
        'recheck', () async {
      final src = await frSource();
      final result = await repo.createMissingCountryProfiles(
          [proposal(src, 'AT'), proposal(src, 'AT')]);

      expect(result.created, hasLength(1));
      expect(result.skipped, ['AT']);
      expect(
          repo.getAllProfiles().where((p) => p.countryCode == 'AT'),
          hasLength(1));
    });

    test('an empty proposal list is a no-op', () async {
      await frSource();
      final result = await repo.createMissingCountryProfiles([]);
      expect(result.created, isEmpty);
      expect(result.skipped, isEmpty);
      expect(result.isComplete, isTrue);
      expect(result.hasChanges, isFalse);
      expect(repo.getAllProfiles(), hasLength(1));
    });
  });
}
