import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/data/legacy_toggle_migrator.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

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

  group('migrateUserProfileToggles — gamification', () {
    UserProfile profileWith({required bool gamification}) {
      // The gamificationEnabled field is `@Deprecated` post-#1373
      // phase 3b. The migrator still reads it for the one-shot promotion
      // — see `legacy_toggle_migrator.dart` for the same suppression.
      // ignore: deprecated_member_use_from_same_package
      return UserProfile(
        id: 'p1',
        name: 'Test',
        // ignore: deprecated_member_use_from_same_package
        gamificationEnabled: gamification,
      );
    }

    test(
      'cascade-enables on activeProfile.gamificationEnabled = true — final '
      'feature set contains both obd2TripRecording AND gamification',
      () async {
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(gamification: true),
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.gamification),
          reason:
              'Legacy true must promote into the central feature-flag set '
              'so the user does not have to re-enable gamification after '
              'the migration.',
        );
        expect(
          after,
          contains(Feature.obd2TripRecording),
          reason:
              'Feature.gamification requires obd2TripRecording per the '
              'manifest; enabling the dependent without the prerequisite '
              'would leave the central state in a contract-violating shape.',
        );
        expect(
          settings.get(gamificationMigratedKey),
          isTrue,
          reason:
              'The migration gate must be set so a subsequent run is a '
              'no-op and a user who later disables gamification does not '
              'get it re-enabled on the next launch.',
        );
      },
    );

    test(
      'preserves legacy false — explicit opt-out survives the manifest '
      'default, migrated key written',
      () async {
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(gamification: false),
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.gamification)),
          reason:
              'Feature.gamification has manifest defaultEnabled=true, so '
              'a no-op (no write) would silently restore gamification for '
              'users who had explicitly opted out. The migrator must '
              'persist the user’s false choice by writing a state that '
              'excludes Feature.gamification — otherwise the explicit '
              'preference is lost across the migration.',
        );
        expect(
          settings.get(gamificationMigratedKey),
          isTrue,
          reason:
              'Even a legacy=false migration must set the gate so we '
              'never re-read the deprecated field on subsequent launches.',
        );
      },
    );

    test(
      'no-op on activeProfile == null — feature set unchanged AND migrated '
      'key NOT written (will retry next launch)',
      () async {
        // Seed central state to a known shape so we can detect any writes.
        await repo.saveEnabled(<Feature>{Feature.priceAlerts});

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: null,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          equals(<Feature>{Feature.priceAlerts}),
          reason:
              'Without an active profile the migrator must be a complete '
              'no-op — no central writes, the seeded state must be '
              'preserved verbatim.',
        );
        expect(
          settings.get(gamificationMigratedKey),
          isNull,
          reason:
              'The migrated-key flag MUST NOT be written when no profile '
              'is loaded — otherwise the next launch (when the profile '
              'IS loaded) would skip the migration and silently lose any '
              'explicit gamificationEnabled = false the user had set.',
        );
      },
    );

    test(
      'idempotent — running twice with the same inputs does NOT re-promote '
      '(second call exits at the migrated-key check)',
      () async {
        // First run promotes.
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(gamification: true),
        );
        final afterFirst = await repo.loadEnabled();
        expect(afterFirst, contains(Feature.gamification));
        expect(settings.get(gamificationMigratedKey), isTrue);

        // Simulate the user disabling gamification after the migration
        // (e.g. via the central settings UI). The second run must NOT
        // re-enable it.
        final disabled = {...afterFirst}..remove(Feature.gamification);
        await repo.saveEnabled(disabled);

        // Second run with same activeProfile (legacy still true).
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(gamification: true),
        );

        final afterSecond = await repo.loadEnabled();
        expect(
          afterSecond,
          isNot(contains(Feature.gamification)),
          reason:
              'A second migration run must not re-promote the legacy true '
              'value — the user has explicitly disabled gamification since '
              'and that choice must survive.',
        );
      },
    );

    test(
      'gate-skip when gamificationMigratedKey is already true — no read of '
      'activeProfile.gamificationEnabled',
      () async {
        await settings.put(gamificationMigratedKey, true);
        // Seed central state to a known shape so we can detect any writes.
        await repo.saveEnabled(<Feature>{Feature.priceAlerts});

        // Pass a profile with gamification=true; the migrator must skip
        // it entirely because the gate is set.
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(gamification: true),
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.gamification)),
          reason:
              'When the migration gate is already set, the legacy field '
              'must not be re-read and the central state must stay exactly '
              'as the user left it after the first migration.',
        );
        expect(
          after,
          contains(Feature.priceAlerts),
          reason:
              'The seeded central state must be preserved verbatim — the '
              'migrator must not write to the repository when the gate is '
              'set.',
        );
      },
    );
  });

  group('migrateLegacyToggles — unifiedSearchResults', () {
    test(
      'promotes legacy true → enables unifiedSearchResults; sets migration '
      'flag (no prerequisites in the manifest, so no cascade)',
      () async {
        // ignore: deprecated_member_use_from_same_package
        await settings.put(StorageKeys.unifiedSearchResultsEnabled, true);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.unifiedSearchResults),
          reason:
              'Legacy true must promote into the central feature-flag set '
              'so the user does not have to re-enable unifiedSearchResults '
              'after the migration.',
        );
        expect(
          settings.get(unifiedSearchResultsMigratedKey),
          isTrue,
          reason:
              'The migration gate must be set so a subsequent run is a '
              'no-op and a user who later disables unifiedSearchResults '
              'does not get it re-enabled on the next launch.',
        );
      },
    );

    test('legacy false → leaves central state untouched; sets migration flag',
        () async {
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.unifiedSearchResultsEnabled, false);

      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        isNot(contains(Feature.unifiedSearchResults)),
        reason:
            'A legacy explicit-false must not promote anything — the '
            'central system already defaults unifiedSearchResults to off '
            '(manifest defaultEnabled=false), so a no-op write would have '
            'been semantically equivalent anyway. Mirrors the haptic '
            'precedent.',
      );
      expect(
        settings.get(unifiedSearchResultsMigratedKey),
        isTrue,
        reason:
            'Even a no-op migration must set the gate so we never re-read '
            'the deprecated key on subsequent launches.',
      );
    });

    test(
      'legacy null (key never written) → no central state change; flag set',
      () async {
        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.unifiedSearchResults)),
          reason:
              'A first-launch profile (no legacy value) must land at '
              'central manifest defaults — unifiedSearchResults off.',
        );
        expect(
          settings.get(unifiedSearchResultsMigratedKey),
          isTrue,
          reason:
              'Absent legacy value still flips the gate so we do not '
              're-do the work each launch.',
        );
      },
    );

    test(
      'idempotent — running twice on legacy=true leaves the central state '
      'unchanged the second time',
      () async {
        // ignore: deprecated_member_use_from_same_package
        await settings.put(StorageKeys.unifiedSearchResultsEnabled, true);

        // First run promotes.
        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );
        final afterFirst = await repo.loadEnabled();
        expect(afterFirst, contains(Feature.unifiedSearchResults));
        expect(settings.get(unifiedSearchResultsMigratedKey), isTrue);

        // Simulate the user disabling unifiedSearchResults after the
        // migration (e.g. via the central settings UI). The second run
        // must NOT re-enable it.
        final disabled = {...afterFirst}..remove(Feature.unifiedSearchResults);
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
          isNot(contains(Feature.unifiedSearchResults)),
          reason:
              'A second migration run must not re-promote the legacy true '
              'value — the user has explicitly disabled '
              'unifiedSearchResults since and that choice must survive.',
        );
      },
    );
  });

  group('migrateLegacyToggles — syncBaselines', () {
    test(
      'promotes legacy true → cascade-enables both Feature.tankSync '
      '(prerequisite) AND Feature.baselineSync; sets migration flag',
      () async {
        // ignore: deprecated_member_use_from_same_package
        await settings.put(StorageKeys.syncBaselinesEnabled, true);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.baselineSync),
          reason:
              'Legacy true must promote into the central feature-flag set '
              'so the user does not have to re-enable baseline sync after '
              'the migration.',
        );
        expect(
          after,
          contains(Feature.tankSync),
          reason:
              'baselineSync requires tankSync per the manifest; enabling '
              'the dependent without the prerequisite would leave the '
              'central state in a contract-violating shape. Mirrors the '
              'haptic precedent which cascades obd2TripRecording.',
        );
        expect(
          settings.get(syncBaselinesMigratedKey),
          isTrue,
          reason:
              'The migration gate must be set so a subsequent run is a '
              'no-op and a user who later disables baselineSync does not '
              'get it re-enabled on the next launch.',
        );
      },
    );

    test('legacy false → leaves central state untouched; sets migration flag',
        () async {
      // ignore: deprecated_member_use_from_same_package
      await settings.put(StorageKeys.syncBaselinesEnabled, false);

      await migrateLegacyToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        isNot(contains(Feature.baselineSync)),
        reason:
            'A legacy explicit-false must not promote anything — the '
            'central system already defaults baselineSync to off '
            '(manifest defaultEnabled=false), so a no-op write is '
            'semantically equivalent.',
      );
      expect(
        after,
        isNot(contains(Feature.tankSync)),
        reason:
            'tankSync must NOT be cascade-enabled when the legacy value '
            'is false — the cascade only runs on the legacy=true branch.',
      );
      expect(
        settings.get(syncBaselinesMigratedKey),
        isTrue,
        reason:
            'Even a no-op migration must set the gate so we never '
            're-read the deprecated key on subsequent launches.',
      );
    });

    test(
      'legacy null (key never written) → no central state change; flag set',
      () async {
        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.baselineSync)),
          reason:
              'A first-launch profile (no legacy value) must land at '
              'central manifest defaults — baselineSync off.',
        );
        expect(
          settings.get(syncBaselinesMigratedKey),
          isTrue,
          reason:
              'Absent legacy value still flips the gate so we do not '
              're-do the work each launch.',
        );
      },
    );

    test(
      'idempotent — running twice on legacy=true leaves the central state '
      'unchanged the second time (user disable survives)',
      () async {
        // ignore: deprecated_member_use_from_same_package
        await settings.put(StorageKeys.syncBaselinesEnabled, true);

        // First run promotes (cascades tankSync + baselineSync).
        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );
        final afterFirst = await repo.loadEnabled();
        expect(afterFirst, contains(Feature.baselineSync));
        expect(afterFirst, contains(Feature.tankSync));
        expect(settings.get(syncBaselinesMigratedKey), isTrue);

        // Simulate the user disabling baselineSync after the migration
        // (e.g. via the central settings UI). The tankSync prereq stays
        // because favourite sync depends on it independently. The
        // second run must NOT re-enable baselineSync.
        final disabled = {...afterFirst}..remove(Feature.baselineSync);
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
          isNot(contains(Feature.baselineSync)),
          reason:
              'A second migration run must not re-promote the legacy '
              'true value — the user has explicitly disabled '
              'baselineSync since and that choice must survive.',
        );
        expect(
          afterSecond,
          contains(Feature.tankSync),
          reason:
              'tankSync must remain enabled — the user only disabled '
              'baselineSync, and the migrator must not touch unrelated '
              'features on the idempotent second run.',
        );
      },
    );
  });

  /// Phase-3d coverage for the per-vehicle [VehicleProfile.autoRecord]
  /// wrap migration.
  ///
  /// Distinct from earlier phases because it does NOT 1:1 promote a
  /// legacy value: the per-vehicle bool stays as the source of truth,
  /// and the central [Feature.autoRecord] is a master gate consulted
  /// FIRST. The migrator only flips the central feature OFF when
  /// EVERY existing vehicle had the per-vehicle bool off (explicit
  /// "no auto-record at all" intent). Otherwise the central feature
  /// stays at the manifest default of `true` and the per-vehicle
  /// bools continue to govern per-vehicle behaviour.
  group('migrateLegacyToggles — autoRecord (phase 3d wrap)', () {
    /// Persists [profiles] under [StorageKeys.vehicleProfiles] in the
    /// shape [VehicleProfileRepository] uses (List of JSON maps with
    /// String keys). Mirrors the production write path so the
    /// migrator's read code exercises the real serialised shape.
    Future<void> seedProfiles(List<VehicleProfile> profiles) async {
      await settings.put(
        StorageKeys.vehicleProfiles,
        profiles.map((p) => p.toJson()).toList(),
      );
    }

    VehicleProfile profile({
      required String id,
      required bool autoRecord,
    }) {
      return VehicleProfile(
        id: id,
        name: 'Vehicle $id',
        type: VehicleType.combustion,
        autoRecord: autoRecord,
      );
    }

    test(
      'all vehicles autoRecord=true → central feature stays at default '
      '(enabled); flag set',
      () async {
        await seedProfiles([
          profile(id: 'a', autoRecord: true),
          profile(id: 'b', autoRecord: true),
        ]);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.autoRecord),
          reason:
              'At least one vehicle had the per-vehicle bool on, so the '
              'master gate must stay at its manifest default of true. The '
              'per-vehicle bools continue to govern per-vehicle behaviour '
              'unchanged — this is a wrap, not a replacement.',
        );
        expect(
          settings.get(autoRecordMigratedKey),
          isTrue,
          reason:
              'The migration gate must be set so a subsequent run does '
              'not re-inspect the per-vehicle bools.',
        );
      },
    );

    test(
      'all vehicles autoRecord=false → central feature flips to disabled; '
      'flag set',
      () async {
        await seedProfiles([
          profile(id: 'a', autoRecord: false),
          profile(id: 'b', autoRecord: false),
        ]);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.autoRecord)),
          reason:
              'Every vehicle had the per-vehicle bool off — that is the '
              'only signal we can read at migration time meaning "user '
              'doesn\'t want auto-record at all". The master gate flips '
              'OFF so a future vehicle added with the per-vehicle '
              'default-on bool does NOT silently start recording.',
        );
        expect(settings.get(autoRecordMigratedKey), isTrue);
      },
    );

    test(
      'mixed (one true, one false) → central feature stays enabled '
      '(per-vehicle intent preserved); flag set',
      () async {
        await seedProfiles([
          profile(id: 'a', autoRecord: false),
          profile(id: 'b', autoRecord: true),
        ]);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.autoRecord),
          reason:
              'At least one vehicle wants auto-record, so the master gate '
              'must stay enabled. The per-vehicle bools (preserved) handle '
              'the disable-this-one-vehicle case.',
        );
        expect(settings.get(autoRecordMigratedKey), isTrue);
      },
    );

    test(
      'no vehicles → central feature stays at default (enabled); flag set',
      () async {
        // No `seedProfiles` call → key is absent / empty list.
        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.autoRecord),
          reason:
              'A fresh install (no vehicles yet) lands at manifest '
              'defaults — the master gate is enabled. The first vehicle '
              'the user adds will respect the per-vehicle default-off bool, '
              'so nothing records until they explicitly opt in per vehicle.',
        );
        expect(settings.get(autoRecordMigratedKey), isTrue);
      },
    );

    test(
      'idempotent — re-running after the gate is set is a no-op even when '
      'every vehicle had autoRecord=false',
      () async {
        // First run with all-false → migrator flips central off and sets
        // the gate.
        await seedProfiles([profile(id: 'a', autoRecord: false)]);
        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );
        expect(await repo.loadEnabled(), isNot(contains(Feature.autoRecord)));
        expect(settings.get(autoRecordMigratedKey), isTrue);

        // Simulate the user (or a follow-up provider write) re-enabling
        // the central feature. Then re-run the migrator.
        final nowEnabled = {
          ...await repo.loadEnabled(),
          Feature.autoRecord,
          // autoRecord requires obd2TripRecording per the manifest;
          // include it so the persisted set is dependency-consistent.
          Feature.obd2TripRecording,
        };
        await repo.saveEnabled(nowEnabled);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final afterSecond = await repo.loadEnabled();
        expect(
          afterSecond,
          contains(Feature.autoRecord),
          reason:
              'A second migration run must not re-disable the central '
              'feature — the user explicitly re-enabled it after the '
              'first migration and that choice must survive.',
        );
      },
    );

    test(
      'malformed vehicle entry is skipped without aborting the migration',
      () async {
        // Seed a list with one bogus entry and one valid all-false
        // profile. The bogus entry must not block the migration; the
        // single valid entry has autoRecord=false → all-vehicles-false
        // path → central flips off.
        await settings.put(StorageKeys.vehicleProfiles, <dynamic>[
          'not a map at all',
          profile(id: 'a', autoRecord: false).toJson(),
        ]);

        await migrateLegacyToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.autoRecord)),
          reason:
              'The valid profile (autoRecord=false) wins — the bogus row '
              'is skipped per the migrator\'s try/catch guard.',
        );
        expect(settings.get(autoRecordMigratedKey), isTrue);
      },
    );
  });

  /// Phase-3c orphan-deletion coverage for `UserProfile.showConsumptionTab`.
  ///
  /// Distinct from the gamification / haptic / sync precedents because
  /// the migrator does NOT promote anything into the central feature
  /// flag set — the field had zero consumers in `lib/` or `test/`
  /// (likely orphaned by #1342) so phase 3c is a pure deletion. The
  /// migrator only exists to strip the orphan key from any active
  /// profile that was persisted before the field was removed; one save
  /// through the repository writes a fresh JSON without the dropped key.
  group('migrateUserProfileToggles — showConsumptionTab drop (phase 3c)', () {
    test(
      'first run with an active profile invokes the saver and sets the '
      'gate flag',
      () async {
        const profile = UserProfile(id: 'p1', name: 'Test');
        var savedCount = 0;
        UserProfile? lastSaved;

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profile,
          saveActiveProfile: (p) async {
            savedCount += 1;
            lastSaved = p;
          },
        );

        expect(
          savedCount,
          1,
          reason:
              'The drop step must call the repository saver exactly once '
              'per upgrading user — the freshly-serialised JSON drops the '
              'orphan showConsumptionTab key.',
        );
        expect(
          lastSaved,
          same(profile),
          reason:
              'The saver must receive the active profile verbatim — the '
              'migrator does not mutate the profile, only triggers a '
              're-serialisation through repository.updateProfile so '
              'toJson() runs against the post-deletion shape.',
        );
        expect(
          settings.get(showConsumptionTabDroppedKey),
          isTrue,
          reason:
              'The migration gate must be set so a subsequent run does '
              'not re-enter the saver branch (idempotency + avoids '
              'invalidating Riverpod listeners on every launch).',
        );
      },
    );

    test(
      'second run after the gate is set is a no-op (saver not invoked)',
      () async {
        const profile = UserProfile(id: 'p1', name: 'Test');
        await settings.put(showConsumptionTabDroppedKey, true);
        var savedCount = 0;

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profile,
          saveActiveProfile: (p) async {
            savedCount += 1;
          },
        );

        expect(
          savedCount,
          0,
          reason:
              'When the gate flag is already set the migrator must not '
              're-save the profile — re-serialisation is idempotent on '
              'the wire, but invalidates the active-profile Riverpod '
              'listener and triggers spurious rebuilds.',
        );
      },
    );

    test(
      'no active profile → no save, gate NOT set (will retry next launch)',
      () async {
        var savedCount = 0;

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: null,
          saveActiveProfile: (p) async {
            savedCount += 1;
          },
        );

        expect(
          savedCount,
          0,
          reason:
              'Without an active profile there is nothing to re-serialise — '
              'the saver must not fire.',
        );
        expect(
          settings.get(showConsumptionTabDroppedKey),
          isNull,
          reason:
              'The gate flag MUST NOT be written when no profile is loaded '
              '— otherwise the next launch (when the profile IS loaded) '
              'would skip the drop step and the orphan key would survive '
              'on disk forever.',
        );
      },
    );

    test(
      'saver-failure does NOT set the gate so the next launch retries',
      () async {
        const profile = UserProfile(id: 'p1', name: 'Test');

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profile,
          saveActiveProfile: (p) async {
            throw StateError('disk full simulation');
          },
        );

        expect(
          settings.get(showConsumptionTabDroppedKey),
          isNull,
          reason:
              'A save failure must keep the gate unset — the orphan key '
              'is inert (no consumer reads it) so retrying on the next '
              'launch is the correct recovery, not silent gate-set.',
        );
      },
    );

    test(
      'no saver wired (callback null) → gate flag still set so test '
      'environments are not re-entered every provider rebuild',
      () async {
        const profile = UserProfile(id: 'p1', name: 'Test');

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profile,
          // saveActiveProfile omitted — covers the unit-test path that
          // doesn't wire the profile repository.
        );

        expect(
          settings.get(showConsumptionTabDroppedKey),
          isTrue,
          reason:
              'When no saver is wired the migrator cannot strip the orphan '
              'key — but it must still set the gate so a watcher in a unit '
              'test that rebuilds the provider does not re-enter this '
              'branch on every rebuild.',
        );
      },
    );
  });
}
