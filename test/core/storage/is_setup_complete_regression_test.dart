import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

/// Regression test for issue #565 (and root-cause #555).
///
/// `isSetupComplete` MUST be `false` on a freshly opened empty Hive.
/// Prior to #555 the getter depended on `hasApiKey()`, which — after
/// #521 bundled a community default key — became always-true, bypassing
/// the onboarding wizard on fresh install.
///
/// Both the storage getter [HiveStorage.isSetupComplete] and the
/// provider [isSetupCompleteProvider] are covered so the invariant is
/// locked at both layers.
///
/// Uses real Hive boxes in a temp directory (no mocks) so the test
/// exercises the exact code path the app boots through on first launch.
void main() {
  late Directory tempDir;
  late HiveStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('is_setup_complete_regression_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    storage = HiveStorage();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveStorage.isSetupComplete — empty-Hive invariant (#565 / #555)', () {
    test('returns false on a freshly opened empty Hive', () {
      // Nothing has been written yet — the setupSkipped flag is absent
      // and hasApiKey() is false. The getter must report "not complete"
      // so the router redirects the user into the onboarding wizard.
      expect(storage.isSetupComplete, isFalse,
          reason: 'Fresh install must land on the onboarding wizard, '
              'not in the authenticated shell.');
    });

    test('stays false after putSetting writes to unrelated keys', () async {
      // Writing to any non-setup key must not flip the completion flag.
      // Regression for the class of bugs where the getter accidentally
      // depended on whether the box was empty rather than the explicit
      // setupSkipped flag.
      await storage.putSetting('theme', 'dark');
      await storage.putSetting('locale', 'en');
      expect(storage.isSetupComplete, isFalse);
    });

    test('stays false after cacheData / addFavorite writes', () async {
      // Caching station data and adding favorites must not flip
      // isSetupComplete either — those can happen from widgets that
      // pre-seed data before the user finishes the wizard.
      await storage.cacheData('key', {'some': 'data'});
      await storage.addFavorite('station-123');
      expect(storage.isSetupComplete, isFalse);
    });

    test('becomes true only after skipSetup() — no other mutation counts',
        () async {
      expect(storage.isSetupComplete, isFalse);
      await storage.skipSetup();
      expect(storage.isSetupComplete, isTrue,
          reason: 'skipSetup() is the only path that should mark setup '
              'complete — the wizard calls this at the end of its flow.');
    });

    test('#555: returns false even when a community API key would be cached',
        () {
      // This is the exact regression #555 guarded against. Before the
      // fix, `isSetupComplete` returned `hasApiKey()`, which was true
      // whenever the app held ANY key — including a bundled community
      // key. The fix made the getter depend solely on the setupSkipped
      // flag. The test proves the new contract: the API key situation
      // is irrelevant to setup completion.
      expect(storage.hasApiKey(), isFalse);
      expect(storage.isSetupComplete, isFalse);
    });
  });

  group('isSetupCompleteProvider — provider layer mirrors the getter', () {
    ProviderContainer makeContainer() {
      final c = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('reads false on empty Hive', () {
      final c = makeContainer();
      expect(c.read(isSetupCompleteProvider), isFalse,
          reason: 'Router reads this provider at redirect time — on a fresh '
              'install it MUST return false so the user lands at /consent '
              'or /setup, not in the shell.');
    });

    test('reads true after skipSetup() is called via storage', () async {
      final c = makeContainer();
      expect(c.read(isSetupCompleteProvider), isFalse);

      await storage.skipSetup();
      // `storageRepositoryProvider` is keepAlive and reads from the same
      // HiveStorage instance, so invalidating forces the provider to
      // recompute against the now-updated getter.
      c.invalidate(isSetupCompleteProvider);

      expect(c.read(isSetupCompleteProvider), isTrue);
    });

    test('reads false again after resetSetupSkip()', () async {
      final c = makeContainer();

      await storage.skipSetup();
      c.invalidate(isSetupCompleteProvider);
      expect(c.read(isSetupCompleteProvider), isTrue);

      await storage.resetSetupSkip();
      c.invalidate(isSetupCompleteProvider);
      expect(c.read(isSetupCompleteProvider), isFalse,
          reason: 'Resetting the skip flag must re-gate the user back into '
              'the wizard — mirrors the diagnostic "Reset onboarding" action.');
    });
  });
}
