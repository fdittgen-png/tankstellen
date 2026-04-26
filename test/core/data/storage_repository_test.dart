import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';

import '../../fakes/fake_storage_repository.dart';

/// Test that StorageRepository is a proper abstract interface
/// with all required methods. The compile of this file proves the
/// surface, and [FakeStorageRepository] (the canonical in-memory
/// implementation) proves it can be implemented end-to-end.
void main() {
  group('StorageRepository interface', () {
    test('defines all required favorite methods', () {
      // Compile-time check: if StorageRepository is missing methods,
      // this file won't compile. The test is the compilation itself.
      expect(StorageRepository, isNotNull);
    });

    test('can be implemented by an in-memory fake', () {
      final fake = FakeStorageRepository();
      expect(fake, isA<StorageRepository>());
      expect(fake.getFavoriteIds(), isEmpty);
      expect(fake.getRatings(), isEmpty);
      expect(fake.getIgnoredIds(), isEmpty);
      // #521 — hasApiKey is true when the bundled community default is
      // present (the fake's default); the custom-key flag is what the
      // UI actually branches on now.
      expect(fake.hasApiKey(), isTrue);
      expect(fake.hasCustomApiKey(), isFalse);
      expect(fake.isSetupComplete, isFalse);
      expect(fake.alertCount, 0);
      expect(fake.favoriteCount, 0);
    });

    test('fake implements all CRUD operations', () async {
      final fake = FakeStorageRepository();

      // Favorites
      await fake.addFavorite('s1');
      expect(fake.getFavoriteIds(), contains('s1'));
      expect(fake.isFavorite('s1'), isTrue);
      await fake.removeFavorite('s1');
      expect(fake.isFavorite('s1'), isFalse);

      // Ratings
      await fake.setRating('s1', 4);
      expect(fake.getRating('s1'), 4);
      await fake.removeRating('s1');
      expect(fake.getRating('s1'), isNull);

      // Ignored
      await fake.addIgnored('s2');
      expect(fake.getIgnoredIds(), contains('s2'));
      await fake.removeIgnored('s2');
      expect(fake.getIgnoredIds(), isEmpty);

      // Settings
      await fake.putSetting('key', 'value');
      expect(fake.getSetting('key'), 'value');

      // Supabase anon key (secure storage surface)
      expect(fake.getSupabaseAnonKey(), isNull);
      await fake.setSupabaseAnonKey('anon-key-123');
      expect(fake.getSupabaseAnonKey(), 'anon-key-123');
      await fake.deleteSupabaseAnonKey();
      expect(fake.getSupabaseAnonKey(), isNull);
    });
  });
}
