import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/application/legacy_toggle_migration_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/data/legacy_toggle_migrator.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Runtime coverage for the post-#1421 follow-up that wires
/// [legacyToggleMigrationProvider] into `AppInitializer` so the legacy-toggle
/// migrators fire on every cold start.
///
/// We don't drive `AppInitializer.run` end-to-end here — that path needs a
/// real platform binding for HiveStorage, secure-storage, notifications,
/// etc. Instead this test exercises the smallest possible slice: a
/// [ProviderContainer] with a stubbed [FeatureFlagsRepository], the
/// `'settings'` Hive box opened with a known legacy value, and a manual
/// `container.read(legacyToggleMigrationProvider.future)` — which is
/// exactly the call `AppInitializer._deferPostFirstFrame` schedules.
///
/// If the migrators run, [Feature.hapticEcoCoach] (and its prerequisite
/// [Feature.obd2TripRecording]) land in the central feature-flag set and
/// the `*Migrated` gate flag flips to `true`. If the wiring is wrong (e.g.
/// reading the synchronous `AsyncValue` placeholder instead of `.future`),
/// neither side-effect fires and the test fails — protecting against the
/// regression that motivated this PR.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> settings;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync(
        'legacy_toggle_migration_at_startup_wiring_');
    Hive.init(tmpDir.path);
    // The provider hard-codes `'settings'` as its box name (its docstring
    // explains why hive_boxes.dart was off-limits during phase 3).
    settings = await Hive.openBox<dynamic>('settings');
    final suffix = DateTime.now().microsecondsSinceEpoch;
    flagsBox = await Hive.openBox<dynamic>('feature_flags_$suffix');
    repo = FeatureFlagsRepository(box: flagsBox);
  });

  tearDown(() async {
    await settings.deleteFromDisk();
    await flagsBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test(
    'reading legacyToggleMigrationProvider.future runs the legacy-toggle '
    'migrators — mirrors the AppInitializer post-first-frame kick-off',
    () async {
      // Seed the legacy key the same way a pre-#1373 install would have.
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.hapticEcoCoachEnabled, true);
      // Sanity-check the gate flag is absent so the migrator must run.
      expect(settings.get(hapticEcoCoachMigratedKey), isNull);

      final container = ProviderContainer(overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repo),
        featureManifestProvider
            .overrideWithValue(FeatureManifest.defaultManifest),
      ]);
      addTearDown(container.dispose);

      // This is the exact call AppInitializer._deferPostFirstFrame schedules.
      // Awaiting it here makes the assertion deterministic — production
      // fires it non-awaited because the migration is non-fatal and must
      // not delay other deferred work.
      await container.read(legacyToggleMigrationProvider.future);

      final after = await repo.loadEnabled();
      expect(
        after,
        contains(Feature.hapticEcoCoach),
        reason:
            'AppInitializer kicks legacyToggleMigrationProvider.future after '
            'first frame; reading it must fire migrateLegacyToggles, which '
            'promotes the legacy hapticEcoCoachEnabled=true into the central '
            'feature-flag set. Failure here means the wiring observed only '
            'the synchronous placeholder and never let the migrator '
            'microtask run — the regression this PR exists to prevent.',
      );
      expect(
        after,
        contains(Feature.obd2TripRecording),
        reason:
            'hapticEcoCoach requires obd2TripRecording per the manifest; the '
            'cascade must run as part of the same migration call.',
      );
      expect(
        settings.get(hapticEcoCoachMigratedKey),
        isTrue,
        reason:
            'The migration gate must be set so subsequent cold starts find '
            'the flag and short-circuit the migrator.',
      );
    },
  );
}
