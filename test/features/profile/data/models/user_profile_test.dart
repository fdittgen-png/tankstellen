import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

/// Pin the post-#1373-phase-3c shape of [UserProfile]:
///   - the orphan `showConsumptionTab` field is GONE (it had no consumers
///     in `lib/` or `test/`, likely orphaned by #1342 when the
///     carbon/Achievements tab was removed).
///   - JSON containing a stray `showConsumptionTab` key from a profile
///     persisted before the deletion still deserialises — Freezed /
///     json_serializable silently ignore unknown keys, so an upgrading
///     user's stored profile does NOT crash on first read.
void main() {
  group('UserProfile — phase 3c orphan field deletion', () {
    test('UserProfile no longer exposes a showConsumptionTab member', () {
      const profile = UserProfile(id: 'p1', name: 'Default');
      // Round-trip the profile through JSON and confirm the key is not
      // emitted on write either. Without the field declaration toJson
      // cannot synthesise the key, so this assertion would have been
      // impossible before phase 3c.
      final encoded = profile.toJson();
      expect(
        encoded.containsKey('showConsumptionTab'),
        isFalse,
        reason:
            'Phase 3c removed UserProfile.showConsumptionTab as a pure '
            'orphan deletion (no consumers in lib/ or test/). The '
            'serialised JSON must not carry the dropped key — otherwise '
            'the field is effectively still alive on the wire and a '
            'future reader could revive it.',
      );
    });

    test(
      'legacy profile JSON with a stray showConsumptionTab: true key '
      'deserialises (silently ignored)',
      () {
        // Mirrors the shape of a profile persisted before the field was
        // removed: every required key plus the dropped `showConsumptionTab`.
        // The migrator's safety pass (in legacy_toggle_migrator.dart) will
        // re-save the profile back so the orphan key gets stripped on
        // disk; here we only guarantee the in-memory decode path does
        // not throw.
        final legacyJson = <String, dynamic>{
          'id': 'legacy-1',
          'name': 'Upgraded user',
          'showConsumptionTab': true,
        };

        final decoded = UserProfile.fromJson(legacyJson);

        expect(
          decoded.id,
          'legacy-1',
          reason:
              'Required fields must round-trip even when the JSON carries '
              'orphan keys from a previous schema.',
        );
        expect(
          decoded.toJson().containsKey('showConsumptionTab'),
          isFalse,
          reason:
              'Re-serialising the decoded profile must drop the orphan '
              'key — the migrator depends on this so that one save through '
              'the repository removes the legacy row from disk.',
        );
      },
    );

    test(
      'legacy profile JSON with showConsumptionTab: false also deserialises',
      () {
        // Belt-and-braces: the false branch matters too because the
        // pre-deletion default was false, so most upgrading users will
        // have the explicit-false value persisted.
        final legacyJson = <String, dynamic>{
          'id': 'legacy-2',
          'name': 'Upgraded user',
          'showConsumptionTab': false,
        };

        final decoded = UserProfile.fromJson(legacyJson);

        expect(decoded.id, 'legacy-2');
      },
    );
  });
}
