import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

void main() {
  group('LandingScreen.localizedName', () {
    test('returns a German name for every enum value', () {
      for (final s in LandingScreen.values) {
        final de = s.localizedName('de');
        expect(de, isNotEmpty, reason: '${s.name} missing DE translation');
        expect(de, isNot(s.key), reason: '${s.name} returned key fallback');
      }
    });

    test('returns a French name for every enum value', () {
      for (final s in LandingScreen.values) {
        final fr = s.localizedName('fr');
        expect(fr, isNotEmpty);
        expect(fr, isNot(s.key));
      }
    });

    test('English is the final fallback for an unknown locale', () {
      // Icelandic is not in the translation table.
      expect(LandingScreen.map.localizedName('is'),
          LandingScreen.map.localizedName('en'));
    });

    test('distinct names across landing screens', () {
      // Two different screens must never share the same label in a
      // given locale, otherwise the dropdown becomes ambiguous.
      for (final locale in ['en', 'de', 'fr']) {
        final names =
            LandingScreen.values.map((s) => s.localizedName(locale)).toSet();
        expect(names.length, LandingScreen.values.length,
            reason: '$locale has ambiguous names');
      }
    });

    test('favorites / map / cheapest / nearest are the known values', () {
      // Guards that a future rename without updating the switch
      // in persistence layer stays obvious.
      expect(LandingScreen.values.map((s) => s.key).toSet(),
          {'favorites', 'map', 'cheapest', 'nearest'});
    });
  });

  group('LandingScreen.displayName', () {
    test('equals the English localizedName', () {
      for (final s in LandingScreen.values) {
        expect(s.displayName, s.localizedName('en'));
      }
    });

    test('is non-empty for every value', () {
      for (final s in LandingScreen.values) {
        expect(s.displayName, isNotEmpty);
      }
    });
  });
}
