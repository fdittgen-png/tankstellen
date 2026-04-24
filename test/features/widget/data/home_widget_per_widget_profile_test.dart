// Tests the per-widget profile override (#610).
//
// The configure activity writes `profile_<appWidgetId>` into SharedPreferences
// when the user picks a profile at widget-placement time. On the Dart side,
// `HomeWidgetService._resolveDisplayContext` must prefer that per-widget
// profile over the active one when building the widget payload — so a user
// who sets a diesel profile on their widget sees diesel prices even while
// their phone's active profile is gasoline.
//
// The helper under test is `_resolvePerWidgetProfileId`, exposed for testing
// as `resolvePerWidgetProfileIdForTest`. The resolver must:
//   - return the per-widget id when the profile exists
//   - fall back to the active id when the per-widget id is unknown
//     (profile deleted since widget was placed)
//   - fall back to the active id when the per-widget id is null
//
// Integration with `updateWidget` + `updateNearestWidget` is covered by
// `home_widget_service_test.dart` and `nearest_widget_data_builder_test.dart`;
// here we focus on the override logic alone so the behaviour is locked
// independently of the widget JSON-encoding path.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';

class _FakeProfileStorage implements ProfileStorage {
  _FakeProfileStorage({
    required this.profiles,
    this.activeProfileId,
  });

  final Map<String, Map<String, dynamic>> profiles;
  String? activeProfileId;

  @override
  String? getActiveProfileId() => activeProfileId;

  @override
  Map<String, dynamic>? getProfile(String id) => profiles[id];

  @override
  List<Map<String, dynamic>> getAllProfiles() => profiles.values.toList();

  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) async {
    profiles[id] = profile;
  }

  @override
  Future<void> setActiveProfileId(String id) async {
    activeProfileId = id;
  }

  @override
  Future<void> deleteProfile(String id) async {
    profiles.remove(id);
  }

  @override
  int get profileCount => profiles.length;
}

void main() {
  group(
      'HomeWidgetService.resolvePerWidgetProfileIdForTest (#610 — per-widget '
      'profile)', () {
    late _FakeProfileStorage profiles;

    setUp(() {
      profiles = _FakeProfileStorage(
        activeProfileId: 'active',
        profiles: {
          'active': {
            'id': 'active',
            'name': 'Car',
            'preferredFuelType': 'e10',
          },
          'diesel-profile': {
            'id': 'diesel-profile',
            'name': 'Truck',
            'preferredFuelType': 'diesel',
          },
        },
      );
    });

    test(
        'prefers the per-widget id when it matches a known profile '
        '(even when active profile differs)', () {
      final resolved = HomeWidgetService.resolvePerWidgetProfileIdForTest(
        profiles,
        'diesel-profile',
      );
      expect(resolved, 'diesel-profile');
    });

    test('falls back to the active profile when per-widget id is null', () {
      final resolved = HomeWidgetService.resolvePerWidgetProfileIdForTest(
        profiles,
        null,
      );
      expect(resolved, 'active');
    });

    test(
        'falls back to the active profile when per-widget id no longer '
        'resolves (profile was deleted after widget placement)', () {
      final resolved = HomeWidgetService.resolvePerWidgetProfileIdForTest(
        profiles,
        'deleted-profile-id',
      );
      expect(resolved, 'active');
    });

    test('returns null when no active AND per-widget id is unknown', () {
      profiles.activeProfileId = null;
      final resolved = HomeWidgetService.resolvePerWidgetProfileIdForTest(
        profiles,
        'also-unknown',
      );
      expect(resolved, isNull);
    });
  });

  group(
      'HomeWidgetService.resolveDisplayContextForTest (#610 — propagates '
      'per-widget fuel)', () {
    test(
        'uses the per-widget profile fuel type, not the active profile, '
        'when both are present', () {
      final profiles = _FakeProfileStorage(
        activeProfileId: 'active',
        profiles: {
          'active': {
            'id': 'active',
            'name': 'Car',
            'preferredFuelType': FuelType.e10.apiValue,
          },
          'truck': {
            'id': 'truck',
            'name': 'Truck',
            'preferredFuelType': FuelType.diesel.apiValue,
          },
        },
      );

      final ctx = HomeWidgetService.resolveDisplayContextForTest(
        profileStorage: profiles,
        perWidgetProfileId: 'truck',
      );

      expect(ctx['preferredFuelType'], FuelType.diesel.apiValue,
          reason: 'widget must honour the per-widget profile fuel (#610), '
              'not the active profile fuel');
    });

    test('falls back to the active profile fuel when per-widget id is null',
        () {
      final profiles = _FakeProfileStorage(
        activeProfileId: 'active',
        profiles: {
          'active': {
            'id': 'active',
            'name': 'Car',
            'preferredFuelType': FuelType.e10.apiValue,
          },
        },
      );

      final ctx = HomeWidgetService.resolveDisplayContextForTest(
        profileStorage: profiles,
        perWidgetProfileId: null,
      );

      expect(ctx['preferredFuelType'], FuelType.e10.apiValue);
    });

    test(
        'falls back to the active profile when the per-widget id does not '
        'match any known profile (deleted profile)', () {
      final profiles = _FakeProfileStorage(
        activeProfileId: 'active',
        profiles: {
          'active': {
            'id': 'active',
            'name': 'Car',
            'preferredFuelType': FuelType.e10.apiValue,
          },
        },
      );

      final ctx = HomeWidgetService.resolveDisplayContextForTest(
        profileStorage: profiles,
        perWidgetProfileId: 'was-deleted',
      );

      expect(ctx['preferredFuelType'], FuelType.e10.apiValue,
          reason: 'unknown per-widget ids must not yield a null context; '
              'the widget should keep rendering with the active profile');
    });
  });
}
