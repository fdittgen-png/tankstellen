import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/app_profile_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/app_profile_repository.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Provider-layer coverage for the AppProfile system (#1517).
///
/// Each test owns its own Hive boxes so the migration logic
/// (fresh vs pre-#1517 install) can be exercised in isolation. The
/// FeatureFlags repo's `loadEnabled` is asynchronous; tests that need
/// the post-load state pump two microtasks via [pumpLoad].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late Box<dynamic> profileBox;
  late FeatureFlagsRepository flagsRepo;
  late AppProfileRepository profileRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('app_profile_test_');
    Hive.init(tmpDir.path);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    flagsBox = await Hive.openBox<dynamic>('feature_flags_$stamp');
    profileBox = await Hive.openBox<dynamic>('app_profile_$stamp');
    flagsRepo = FeatureFlagsRepository(box: flagsBox);
    profileRepo = AppProfileRepository(box: profileBox);
  });

  tearDown(() async {
    await flagsBox.deleteFromDisk();
    await profileBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(flagsRepo),
      appProfileRepositoryProvider.overrideWithValue(profileRepo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pumpLoad(ProviderContainer c) async {
    c.read(featureFlagsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('build() — migration scenarios', () {
    test('fresh install (both boxes empty) → state is null', () {
      final c = makeContainer();
      expect(c.read(activeAppProfileProvider), isNull);
      // No write to the profile box on a fresh install — the wizard
      // will set it when the user taps a card.
      expect(profileRepo.load(), isNull);
    });

    test(
        'pre-#1517 install (flags populated, no profile) → state migrates to '
        'custom and persists', () async {
      // Simulate a pre-#1517 user who has explicitly toggled OBD2 on.
      await flagsRepo.saveEnabled({
        ...FeatureManifest.defaultManifest.defaultEnabledSet(),
        Feature.obd2TripRecording,
      });
      final c = makeContainer();
      expect(c.read(activeAppProfileProvider), AppProfile.custom);
      // The migration also writes — subsequent containers should see
      // the persisted value directly without re-running the heuristic.
      expect(profileRepo.load(), AppProfile.custom);
    });

    test('persisted profile is returned verbatim on subsequent boots', () {
      profileBox.put('profile', AppProfile.medium.name);
      final c = makeContainer();
      expect(c.read(activeAppProfileProvider), AppProfile.medium);
    });
  });

  group('select(profile) applies the bundle', () {
    test('basic enables only the discovery flags', () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.basic);
      final flags = c.read(featureFlagsProvider);
      expect(flags, appProfileBundles[AppProfile.basic]);
      expect(c.read(activeAppProfileProvider), AppProfile.basic);
      expect(profileRepo.load(), AppProfile.basic);
    });

    test('medium enables manualConsumption on top of basic', () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c
          .read(activeAppProfileProvider.notifier)
          .select(AppProfile.medium);
      final flags = c.read(featureFlagsProvider);
      expect(flags, contains(Feature.manualConsumption));
      expect(flags, contains(Feature.priceAlerts));
      expect(flags, isNot(contains(Feature.obd2TripRecording)));
    });

    test('full enables OBD2 stack and loyalty', () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.full);
      final flags = c.read(featureFlagsProvider);
      expect(flags, contains(Feature.obd2TripRecording));
      expect(flags, contains(Feature.gamification));
      expect(flags, contains(Feature.loyaltyCards));
      expect(flags, contains(Feature.consumptionAnalytics));
      expect(flags, contains(Feature.showConsumptionTab));
    });

    test(
        'switching from full to basic disables every full-only flag '
        '(idempotent — re-applying basic does not flip anything back on)',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.full);
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.basic);
      final flags = c.read(featureFlagsProvider);
      expect(flags, isNot(contains(Feature.obd2TripRecording)));
      expect(flags, isNot(contains(Feature.gamification)));
      expect(flags, isNot(contains(Feature.loyaltyCards)));
      expect(flags, isNot(contains(Feature.manualConsumption)));
      // Re-applying basic should be a no-op.
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.basic);
      final flagsAgain = c.read(featureFlagsProvider);
      expect(flagsAgain, flags);
    });

    test('select(custom) does not touch flags', () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.full);
      final beforeCustom = Set<Feature>.from(c.read(featureFlagsProvider));
      await c
          .read(activeAppProfileProvider.notifier)
          .select(AppProfile.custom);
      final afterCustom = c.read(featureFlagsProvider);
      expect(afterCustom, beforeCustom);
      expect(c.read(activeAppProfileProvider), AppProfile.custom);
    });
  });

  group('reconcileWithFlags', () {
    test('flips active profile to custom when user toggles a flag off-bundle',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c
          .read(activeAppProfileProvider.notifier)
          .select(AppProfile.medium);
      // User toggles a flag that is NOT in any preset bundle —
      // `unifiedSearchResults` is the canonical off-bundle flag,
      // kept off by every preset and reserved for explicit user
      // opt-in.
      final next = {
        ...appProfileBundles[AppProfile.medium]!,
        Feature.unifiedSearchResults,
      };
      await c
          .read(activeAppProfileProvider.notifier)
          .reconcileWithFlags(next);
      expect(c.read(activeAppProfileProvider), AppProfile.custom);
    });

    test('keeps active profile unchanged when flag set still matches preset',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c.read(activeAppProfileProvider.notifier).select(AppProfile.basic);
      // No-op reconcile (e.g. user toggled and untoggled in one frame).
      await c
          .read(activeAppProfileProvider.notifier)
          .reconcileWithFlags(appProfileBundles[AppProfile.basic]!);
      expect(c.read(activeAppProfileProvider), AppProfile.basic);
    });
  });
}
