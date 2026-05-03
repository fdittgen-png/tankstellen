import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/data/legacy_toggle_migrator.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Coverage for [migrateLegacyToggles] (#1373 phase 3a).
///
/// Five scenarios pin the contract:
///   1. legacy=true → cascade-enables both `obd2TripRecording`
///      (prerequisite) AND `hapticEcoCoach`, sets the migration flag.
///   2. legacy=false → no central state change; flag set.
///   3. legacy null/missing → no central state change; flag set.
///   4. Idempotent: running twice on legacy=true does not double-write
///      and does not toggle the user-disabled state back on.
///   5. Migration flag already true → migrator is a no-op even if the
///      legacy value is true (user may have toggled it off after a
///      previous migration).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> settings;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('legacy_toggle_migrator_');
    Hive.init(tmpDir.path);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    settings = await Hive.openBox<dynamic>('settings_$suffix');
    flagsBox = await Hive.openBox<dynamic>('feature_flags_$suffix');
    repo = FeatureFlagsRepository(box: flagsBox);
  });

  tearDown(() async {
    await settings.deleteFromDisk();
    await flagsBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('migrateLegacyToggles — hapticEcoCoach', () {
    test('promotes legacy true → enables hapticEcoCoach AND its prerequisite '
        'obd2TripRecording; sets migration flag', () async {
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.hapticEcoCoachEnabled, true);

      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        contains(Feature.hapticEcoCoach),
        reason:
            'Legacy true must promote into the central feature-flag set so '
            'the user does not have to re-enable haptic eco-coach after the '
            'migration.',
      );
      expect(
        after,
        contains(Feature.obd2TripRecording),
        reason:
            'hapticEcoCoach requires obd2TripRecording per the manifest; '
            'enabling the dependent without the prerequisite would leave '
            'the central state in a contract-violating shape.',
      );
      expect(
        settings.get(hapticEcoCoachMigratedKey),
        isTrue,
        reason:
            'The migration gate must be set so a subsequent run is a no-op '
            'and a user who later disables hapticEcoCoach does not get it '
            're-enabled on the next launch.',
      );
    });

    test('legacy false → leaves central state untouched; sets migration flag',
        () async {
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.hapticEcoCoachEnabled, false);

      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        isNot(contains(Feature.hapticEcoCoach)),
        reason:
            'A legacy explicit-false must not promote anything — the central '
            'system already defaults hapticEcoCoach to off.',
      );
      expect(
        settings.get(hapticEcoCoachMigratedKey),
        isTrue,
        reason:
            'Even a no-op migration must set the gate so we never re-read '
            'the deprecated key on subsequent launches.',
      );
    });

    test('legacy null (key never written) → no central state change; '
        'flag set', () async {
      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        isNot(contains(Feature.hapticEcoCoach)),
        reason:
            'A first-launch profile (no legacy value) must land at central '
            'manifest defaults — hapticEcoCoach off.',
      );
      expect(
        settings.get(hapticEcoCoachMigratedKey),
        isTrue,
        reason:
            'Absent legacy value still flips the gate so we do not re-do the '
            'work each launch.',
      );
    });

    test('idempotent — running twice on legacy=true leaves the central state '
        'unchanged the second time', () async {
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.hapticEcoCoachEnabled, true);

      // First run promotes.
      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );
      final afterFirst = await repo.loadEnabled();
      expect(afterFirst, contains(Feature.hapticEcoCoach));
      expect(settings.get(hapticEcoCoachMigratedKey), isTrue);

      // Simulate the user disabling hapticEcoCoach after the migration
      // (e.g. via the central settings UI). The second run must NOT
      // re-enable it.
      final disabled = {...afterFirst}..remove(Feature.hapticEcoCoach);
      await repo.saveEnabled(disabled);

      // Second run.
      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final afterSecond = await repo.loadEnabled();
      expect(
        afterSecond,
        isNot(contains(Feature.hapticEcoCoach)),
        reason:
            'A second migration run must not re-promote the legacy true '
            'value — the user has explicitly disabled hapticEcoCoach since '
            'and that choice must survive.',
      );
    });

    test('skipped when migration flag already true — central state untouched',
        () async {
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.hapticEcoCoachEnabled, true);
      await settings.put(hapticEcoCoachMigratedKey, true);

      // Seed central state to a known shape so we can detect any writes.
      await repo.saveEnabled(<Feature>{Feature.priceAlerts});

      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        isNot(contains(Feature.hapticEcoCoach)),
        reason:
            'When the migration gate is already set, the legacy value must '
            'not be re-read and the central state must stay exactly as the '
            'user left it after the first migration.',
      );
      expect(
        after,
        contains(Feature.priceAlerts),
        reason:
            'The seeded central state must be preserved verbatim — the '
            'migrator must not write to the repository when the gate is set.',
      );
    });
  });
}
