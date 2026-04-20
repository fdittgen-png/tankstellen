import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

/// #694 — UserProfile must carry an optional defaultVehicleId so the Add
/// fill-up form can pre-select the user's primary car. Legacy profiles
/// without the key must decode with null.
void main() {
  group('UserProfile.defaultVehicleId', () {
    test('is null by default', () {
      const profile = UserProfile(id: 'p1', name: 'Default');
      expect(profile.defaultVehicleId, isNull);
    });

    test('preserves the supplied value', () {
      const profile =
          UserProfile(id: 'p1', name: 'Default', defaultVehicleId: 'v-7');
      expect(profile.defaultVehicleId, 'v-7');
    });

    test('JSON round-trip preserves defaultVehicleId', () {
      const original =
          UserProfile(id: 'p1', name: 'Default', defaultVehicleId: 'v-7');
      final decoded = UserProfile.fromJson(original.toJson());
      expect(decoded, equals(original));
      expect(decoded.defaultVehicleId, 'v-7');
    });

    test('legacy profile JSON without defaultVehicleId decodes with null',
        () {
      final legacyJson = {
        'id': 'p1',
        'name': 'Default',
      };
      final decoded = UserProfile.fromJson(legacyJson);
      expect(decoded.defaultVehicleId, isNull);
    });

    test('copyWith(defaultVehicleId: ...) updates only that field', () {
      const original = UserProfile(id: 'p1', name: 'Default');
      final updated = original.copyWith(defaultVehicleId: 'v-9');
      expect(updated.defaultVehicleId, 'v-9');
      expect(updated.id, 'p1');
      expect(updated.name, 'Default');
    });
  });
}
