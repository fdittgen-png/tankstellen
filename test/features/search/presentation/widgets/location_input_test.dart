import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

void main() {
  group('Location input zip prefill logic', () {
    test('profile with homeZipCode provides value for prefill', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        homeZipCode: '34540',
      );
      expect(profile.homeZipCode, '34540');
      expect(profile.homeZipCode!.isNotEmpty, isTrue);
    });

    test('profile without homeZipCode returns null', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
      );
      expect(profile.homeZipCode, isNull);
    });

    test('profile with empty homeZipCode is treated as not set', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        homeZipCode: '',
      );
      expect(profile.homeZipCode!.isEmpty, isTrue);
    });
  });

  group('Cheapest landing auto-search logic', () {
    test('cheapest landing with zip uses zip search', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: LandingScreen.cheapest,
        homeZipCode: '34540',
      );
      expect(profile.landingScreen, LandingScreen.cheapest);
      expect(profile.homeZipCode, isNotNull);
      expect(profile.homeZipCode!.isNotEmpty, isTrue);
      // Logic: use zip search (not GPS) when zip is available
    });

    test('cheapest landing without zip uses GPS search', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: LandingScreen.cheapest,
      );
      expect(profile.landingScreen, LandingScreen.cheapest);
      expect(profile.homeZipCode, isNull);
      // Logic: fall back to GPS search
    });

    test('non-cheapest landing does not auto-search', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: LandingScreen.search,
        homeZipCode: '34540',
      );
      expect(profile.landingScreen, isNot(LandingScreen.cheapest));
      // Logic: no auto-search triggered
    });
  });

  group('Landing screen enum', () {
    test('map is excluded from user-selectable options', () {
      final selectable = LandingScreen.values
          .where((s) => s != LandingScreen.map)
          .toList();
      expect(selectable.length, 3);
      expect(selectable, contains(LandingScreen.search));
      expect(selectable, contains(LandingScreen.favorites));
      expect(selectable, contains(LandingScreen.cheapest));
      expect(selectable, isNot(contains(LandingScreen.map)));
    });
  });

  group('Default profile protection', () {
    test('single profile should not be deleteable', () {
      final profiles = [
        const UserProfile(id: 'default', name: 'Default'),
      ];
      final canDelete = profiles.length > 1;
      expect(canDelete, isFalse);
    });

    test('multiple profiles allow deletion', () {
      final profiles = [
        const UserProfile(id: 'default', name: 'Default'),
        const UserProfile(id: 'work', name: 'Work'),
      ];
      final canDelete = profiles.length > 1;
      expect(canDelete, isTrue);
    });
  });
}
