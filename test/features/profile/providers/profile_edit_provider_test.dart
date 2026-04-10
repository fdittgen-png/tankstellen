import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_edit_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
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
    showFuel: true,
    showElectric: false,
    ratingMode: 'local',
  );

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('initial state matches profile', () {
    final c = makeContainer();
    final s = c.read(profileEditControllerProvider(profile));

    expect(s.fuelType, FuelType.e10);
    expect(s.radius, 12);
    expect(s.landingScreen, LandingScreen.favorites);
    expect(s.countryCode, 'DE');
    expect(s.languageCode, 'de');
    expect(s.routeSegmentKm, 100);
    expect(s.avoidHighways, isFalse);
    expect(s.showFuel, isTrue);
    expect(s.showElectric, isFalse);
    expect(s.ratingMode, 'local');
  });

  test('mutators update state', () {
    final c = makeContainer();
    final ctrl =
        c.read(profileEditControllerProvider(profile).notifier);

    ctrl.setFuelType(FuelType.diesel);
    ctrl.setRadius(20);
    ctrl.setRouteSegmentKm(250);
    ctrl.setAvoidHighways(true);
    ctrl.setShowFuel(false);
    ctrl.setShowElectric(true);
    ctrl.setRatingMode('shared');
    ctrl.setLandingScreen(LandingScreen.cheapest);
    ctrl.setCountryCode('FR');
    ctrl.setLanguageCode('fr');

    final s = c.read(profileEditControllerProvider(profile));
    expect(s.fuelType, FuelType.diesel);
    expect(s.radius, 20);
    expect(s.routeSegmentKm, 250);
    expect(s.avoidHighways, isTrue);
    expect(s.showFuel, isFalse);
    expect(s.showElectric, isTrue);
    expect(s.ratingMode, 'shared');
    expect(s.landingScreen, LandingScreen.cheapest);
    expect(s.countryCode, 'FR');
    expect(s.languageCode, 'fr');
  });

  test('each profile id scope is independent', () {
    final c = makeContainer();
    const other = UserProfile(id: 'p2', name: 'Other');

    c
        .read(profileEditControllerProvider(profile).notifier)
        .setRadius(22);

    final otherState = c.read(profileEditControllerProvider(other));
    // Other scope is untouched and defaults to its own profile.
    expect(otherState.radius, other.defaultSearchRadius);
  });
}
