import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_edit_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  // Fully-populated fixture so every field has a non-default, distinguishable
  // value. Tests that mutate one field can then assert the rest survived
  // unchanged, catching future drift in copyWith / fromProfile.
  //
  // Note (#1373 phase 3c): `showFuel` / `showElectric` no longer round-
  // trip through ProfileEditState — they live in the central feature-flag
  // set and are read+written via the shim providers from the edit sheet
  // directly. The legacy [UserProfile.showFuel] / `showElectric` fields
  // are preserved for the one-shot migration and still settable here, but
  // the values do NOT propagate into ProfileEditState.
  const profile = UserProfile(
    id: 'p1',
    name: 'Test',
    preferredFuelType: FuelType.e10,
    defaultSearchRadius: 12,
    landingScreen: LandingScreen.favorites,
    countryCode: 'DE',
    languageCode: 'de',
    routeSegmentKm: 100,
    avoidHighways: false,
    ratingMode: 'local',
    defaultVehicleId: 'veh-1',
  );

  // Baseline state derived from the fixture profile, used as the
  // "untouched" reference in copyWith per-field tests.
  ProfileEditState baseState() => ProfileEditState.fromProfile(profile);

  /// Asserts every ProfileEditState field other than [skip] equals the
  /// matching field on [reference]. Catches accidental cross-field mutation
  /// in copyWith.
  void expectAllFieldsExcept(
    ProfileEditState actual,
    ProfileEditState reference, {
    required String skip,
  }) {
    if (skip != 'fuelType') expect(actual.fuelType, reference.fuelType);
    if (skip != 'radius') expect(actual.radius, reference.radius);
    if (skip != 'landingScreen') {
      expect(actual.landingScreen, reference.landingScreen);
    }
    if (skip != 'countryCode') {
      expect(actual.countryCode, reference.countryCode);
    }
    if (skip != 'languageCode') {
      expect(actual.languageCode, reference.languageCode);
    }
    if (skip != 'routeSegmentKm') {
      expect(actual.routeSegmentKm, reference.routeSegmentKm);
    }
    if (skip != 'avoidHighways') {
      expect(actual.avoidHighways, reference.avoidHighways);
    }
    if (skip != 'ratingMode') {
      expect(actual.ratingMode, reference.ratingMode);
    }
    if (skip != 'defaultVehicleId') {
      expect(actual.defaultVehicleId, reference.defaultVehicleId);
    }
  }

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('ProfileEditState.fromProfile', () {
    test('mirrors every field of the source profile', () {
      final s = ProfileEditState.fromProfile(profile);

      expect(s.fuelType, profile.preferredFuelType);
      expect(s.radius, profile.defaultSearchRadius);
      expect(s.landingScreen, profile.landingScreen);
      expect(s.countryCode, profile.countryCode);
      expect(s.languageCode, profile.languageCode);
      expect(s.routeSegmentKm, profile.routeSegmentKm);
      expect(s.avoidHighways, profile.avoidHighways);
      expect(s.ratingMode, profile.ratingMode);
      expect(s.defaultVehicleId, profile.defaultVehicleId);
    });

    test('preserves null countryCode / languageCode / defaultVehicleId', () {
      const minimal = UserProfile(id: 'p3', name: 'Minimal');
      final s = ProfileEditState.fromProfile(minimal);

      expect(s.countryCode, isNull);
      expect(s.languageCode, isNull);
      expect(s.defaultVehicleId, isNull);
      // And defaults from UserProfile flow through.
      expect(s.fuelType, FuelType.e10);
      expect(s.radius, 10.0);
      expect(s.landingScreen, LandingScreen.nearest);
      expect(s.routeSegmentKm, 50.0);
      expect(s.avoidHighways, isFalse);
      expect(s.ratingMode, 'local');
    });
  });

  group('ProfileEditState.copyWith', () {
    test('no arguments returns a state equal in every field', () {
      final base = baseState();
      final copy = base.copyWith();
      expectAllFieldsExcept(copy, base, skip: '__none__');
    });

    test('fuelType only changes fuelType', () {
      final base = baseState();
      final copy = base.copyWith(fuelType: FuelType.diesel);
      expect(copy.fuelType, FuelType.diesel);
      expectAllFieldsExcept(copy, base, skip: 'fuelType');
    });

    test('radius only changes radius', () {
      final base = baseState();
      final copy = base.copyWith(radius: 25);
      expect(copy.radius, 25);
      expectAllFieldsExcept(copy, base, skip: 'radius');
    });

    test('landingScreen only changes landingScreen', () {
      final base = baseState();
      final copy = base.copyWith(landingScreen: LandingScreen.map);
      expect(copy.landingScreen, LandingScreen.map);
      expectAllFieldsExcept(copy, base, skip: 'landingScreen');
    });

    test('countryCode only changes countryCode', () {
      final base = baseState();
      final copy = base.copyWith(countryCode: 'FR');
      expect(copy.countryCode, 'FR');
      expectAllFieldsExcept(copy, base, skip: 'countryCode');
    });

    test('clearCountry: true overrides any countryCode and nulls the field',
        () {
      final base = baseState();
      // Even if a non-null value is also passed, clearCountry wins.
      final copy = base.copyWith(countryCode: 'FR', clearCountry: true);
      expect(copy.countryCode, isNull);
      expectAllFieldsExcept(copy, base, skip: 'countryCode');
    });

    test('clearCountry: false with no countryCode keeps existing value', () {
      final base = baseState();
      final copy = base.copyWith();
      expect(copy.countryCode, base.countryCode);
    });

    test('languageCode only changes languageCode', () {
      final base = baseState();
      final copy = base.copyWith(languageCode: 'fr');
      expect(copy.languageCode, 'fr');
      expectAllFieldsExcept(copy, base, skip: 'languageCode');
    });

    test('clearLanguage: true overrides any languageCode and nulls the field',
        () {
      final base = baseState();
      final copy = base.copyWith(languageCode: 'fr', clearLanguage: true);
      expect(copy.languageCode, isNull);
      expectAllFieldsExcept(copy, base, skip: 'languageCode');
    });

    test('routeSegmentKm only changes routeSegmentKm', () {
      final base = baseState();
      final copy = base.copyWith(routeSegmentKm: 250);
      expect(copy.routeSegmentKm, 250);
      expectAllFieldsExcept(copy, base, skip: 'routeSegmentKm');
    });

    test('avoidHighways only changes avoidHighways', () {
      final base = baseState();
      final copy = base.copyWith(avoidHighways: true);
      expect(copy.avoidHighways, isTrue);
      expectAllFieldsExcept(copy, base, skip: 'avoidHighways');
    });

    test('ratingMode only changes ratingMode', () {
      final base = baseState();
      final copy = base.copyWith(ratingMode: 'shared');
      expect(copy.ratingMode, 'shared');
      expectAllFieldsExcept(copy, base, skip: 'ratingMode');
    });

    test('defaultVehicleId only changes defaultVehicleId', () {
      final base = baseState();
      final copy = base.copyWith(defaultVehicleId: 'veh-2');
      expect(copy.defaultVehicleId, 'veh-2');
      expectAllFieldsExcept(copy, base, skip: 'defaultVehicleId');
    });

    test(
        'clearDefaultVehicle: true overrides any defaultVehicleId and nulls '
        'the field', () {
      final base = baseState();
      final copy = base.copyWith(
        defaultVehicleId: 'veh-2',
        clearDefaultVehicle: true,
      );
      expect(copy.defaultVehicleId, isNull);
      expectAllFieldsExcept(copy, base, skip: 'defaultVehicleId');
    });
  });

  group('ProfileEditController', () {
    test('build() returns state derived from the family-keyed profile', () {
      final c = makeContainer();
      final s = c.read(profileEditControllerProvider(profile));

      expect(s.fuelType, FuelType.e10);
      expect(s.radius, 12);
      expect(s.landingScreen, LandingScreen.favorites);
      expect(s.countryCode, 'DE');
      expect(s.languageCode, 'de');
      expect(s.routeSegmentKm, 100);
      expect(s.avoidHighways, isFalse);
      expect(s.ratingMode, 'local');
      expect(s.defaultVehicleId, 'veh-1');
    });

    test('setFuelType updates fuelType only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setFuelType(FuelType.diesel);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.fuelType, FuelType.diesel);
      expectAllFieldsExcept(s, baseState(), skip: 'fuelType');
    });

    test('setRadius updates radius only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setRadius(20);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.radius, 20);
      expectAllFieldsExcept(s, baseState(), skip: 'radius');
    });

    test('setRouteSegmentKm updates routeSegmentKm only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setRouteSegmentKm(250);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.routeSegmentKm, 250);
      expectAllFieldsExcept(s, baseState(), skip: 'routeSegmentKm');
    });

    test('setAvoidHighways updates avoidHighways only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setAvoidHighways(true);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.avoidHighways, isTrue);
      expectAllFieldsExcept(s, baseState(), skip: 'avoidHighways');
    });

    test('setRatingMode updates ratingMode only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setRatingMode('shared');
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.ratingMode, 'shared');
      expectAllFieldsExcept(s, baseState(), skip: 'ratingMode');
    });

    test('setLandingScreen updates landingScreen only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setLandingScreen(LandingScreen.cheapest);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.landingScreen, LandingScreen.cheapest);
      expectAllFieldsExcept(s, baseState(), skip: 'landingScreen');
    });

    test('setCountryCode with non-null value updates countryCode only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setCountryCode('FR');
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.countryCode, 'FR');
      expectAllFieldsExcept(s, baseState(), skip: 'countryCode');
    });

    test('setCountryCode(null) clears countryCode', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setCountryCode(null);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.countryCode, isNull);
      expectAllFieldsExcept(s, baseState(), skip: 'countryCode');
    });

    test('setLanguageCode with non-null value updates languageCode only', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setLanguageCode('fr');
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.languageCode, 'fr');
      expectAllFieldsExcept(s, baseState(), skip: 'languageCode');
    });

    test('setLanguageCode(null) clears languageCode', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setLanguageCode(null);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.languageCode, isNull);
      expectAllFieldsExcept(s, baseState(), skip: 'languageCode');
    });

    test('setDefaultVehicleId with non-null value updates the field only',
        () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setDefaultVehicleId('veh-2');
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.defaultVehicleId, 'veh-2');
      expectAllFieldsExcept(s, baseState(), skip: 'defaultVehicleId');
    });

    test('setDefaultVehicleId(null) clears defaultVehicleId', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);
      ctrl.setDefaultVehicleId(null);
      final s = c.read(profileEditControllerProvider(profile));
      expect(s.defaultVehicleId, isNull);
      expectAllFieldsExcept(s, baseState(), skip: 'defaultVehicleId');
    });

    test('multiple mutators compose without dropping prior mutations', () {
      final c = makeContainer();
      final ctrl = c.read(profileEditControllerProvider(profile).notifier);

      ctrl.setFuelType(FuelType.diesel);
      ctrl.setRadius(20);
      ctrl.setRouteSegmentKm(250);
      ctrl.setAvoidHighways(true);
      ctrl.setRatingMode('shared');
      ctrl.setLandingScreen(LandingScreen.cheapest);
      ctrl.setCountryCode('FR');
      ctrl.setLanguageCode('fr');
      ctrl.setDefaultVehicleId('veh-2');

      final s = c.read(profileEditControllerProvider(profile));
      expect(s.fuelType, FuelType.diesel);
      expect(s.radius, 20);
      expect(s.routeSegmentKm, 250);
      expect(s.avoidHighways, isTrue);
      expect(s.ratingMode, 'shared');
      expect(s.landingScreen, LandingScreen.cheapest);
      expect(s.countryCode, 'FR');
      expect(s.languageCode, 'fr');
      expect(s.defaultVehicleId, 'veh-2');
    });

    test(
        'each profile id has its own state; mutating one does not affect '
        'another', () {
      final c = makeContainer();
      const other = UserProfile(id: 'p2', name: 'Other');

      c
          .read(profileEditControllerProvider(profile).notifier)
          .setRadius(22);

      final otherState = c.read(profileEditControllerProvider(other));
      expect(otherState.radius, other.defaultSearchRadius);
      expect(otherState.fuelType, other.preferredFuelType);
      expect(otherState.defaultVehicleId, other.defaultVehicleId);
    });
  });
}
