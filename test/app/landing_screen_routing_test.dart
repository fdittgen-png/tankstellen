import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

class _FakeStorage extends Mock implements StorageRepository {
  final Map<String, Map<String, dynamic>> _profiles = {};
  String? _activeId;

  void setActiveProfile(String id, Map<String, dynamic> profile) {
    _profiles[id] = profile;
    _activeId = id;
  }

  @override
  String? getActiveProfileId() => _activeId;

  @override
  Map<String, dynamic>? getProfile(String id) => _profiles[id];
}

void main() {
  group('resolveLandingLocation', () {
    test('no active profile → /', () {
      final storage = _FakeStorage();
      expect(resolveLandingLocation(storage), '/');
    });

    test('favorites landing → /favorites', () {
      final storage = _FakeStorage()
        ..setActiveProfile('p', {'landingScreen': 'favorites'});
      expect(resolveLandingLocation(storage), '/favorites');
    });

    test('legacy "LandingScreen.favorites" prefixed form → /favorites', () {
      final storage = _FakeStorage()
        ..setActiveProfile('p', {'landingScreen': 'LandingScreen.favorites'});
      expect(resolveLandingLocation(storage), '/favorites');
    });

    test('map landing → /map', () {
      final storage = _FakeStorage()
        ..setActiveProfile('p', {'landingScreen': 'map'});
      expect(resolveLandingLocation(storage), '/map');
    });

    test('cheapest landing → / (sort is handled separately)', () {
      final storage = _FakeStorage()
        ..setActiveProfile('p', {'landingScreen': 'cheapest'});
      expect(resolveLandingLocation(storage), '/');
    });

    test('nearest landing → /', () {
      final storage = _FakeStorage()
        ..setActiveProfile('p', {'landingScreen': 'nearest'});
      expect(resolveLandingLocation(storage), '/');
    });

    test('unknown landing value falls through to /', () {
      final storage = _FakeStorage()
        ..setActiveProfile('p', {'landingScreen': 'somethingElse'});
      expect(resolveLandingLocation(storage), '/');
    });

    test('missing landingScreen field → /', () {
      final storage = _FakeStorage()..setActiveProfile('p', {'name': 'X'});
      expect(resolveLandingLocation(storage), '/');
    });
  });

  group('LandingScreen enum', () {
    test('no longer contains search', () {
      final names = LandingScreen.values.map((v) => v.name).toList();
      expect(names, unorderedEquals(['favorites', 'map', 'cheapest', 'nearest']));
    });

    test('every remaining value resolves to a valid route', () {
      final storage = _FakeStorage();
      for (final screen in LandingScreen.values) {
        storage.setActiveProfile('p', {'landingScreen': screen.name});
        final route = resolveLandingLocation(storage);
        expect(
          route,
          anyOf('/', '/favorites', '/map'),
          reason: '$screen should map to a valid route',
        );
      }
    });
  });
}
