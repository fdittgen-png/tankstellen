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

  /// Phase-3c coverage for the bundled `showFuel` + `showElectric` +
  /// `showConsumptionTab` migrations. All three live on UserProfile; the
  /// first two have manifest defaultEnabled=true with no prerequisites,
  /// so they mirror the gamification precedent's preserve-explicit-false
  /// shape. `showConsumptionTab` defaults to true with a hard prerequisite
  /// on `obd2TripRecording`, so a legacy=true cascades both into the
  /// central set.
  group('migrateUserProfileToggles — showFuel (phase 3c)', () {
    UserProfile profileWith({required bool showFuel}) {
      // ignore: deprecated_member_use_from_same_package
      return UserProfile(
        id: 'p1',
        name: 'Test',
        // ignore: deprecated_member_use_from_same_package
        showFuel: showFuel,
      );
    }

    test('legacy true → central state contains showFuel; flag set',
        () async {
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showFuel: true),
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        contains(Feature.showFuel),
        reason:
            'Legacy true must promote into the central feature-flag set '
            'so the user does not have to re-enable showFuel after the '
            'migration. Manifest default is also true, so this is a '
            'no-op-but-explicit write that preserves the user intent.',
      );
      expect(settings.get(showFuelMigratedKey), isTrue);
    });

    test('legacy false → central state excludes showFuel; flag set',
        () async {
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showFuel: false),
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        isNot(contains(Feature.showFuel)),
        reason:
            'Feature.showFuel has manifest defaultEnabled=true. A no-op '
            '(no write) on legacy=false would silently restore the fuel-'
            'station surface for users who explicitly turned it off. '
            'The migrator must persist a state that excludes the feature '
            'so the user preference survives the migration.',
      );
      expect(settings.get(showFuelMigratedKey), isTrue);
    });

    test(
      'no-op when activeProfile is null — gate flag NOT written, retries '
      'next launch',
      () async {
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
          settings.get(showFuelMigratedKey),
          isNull,
          reason:
              'The migrated-key flag MUST NOT be written when no profile '
              'is loaded — otherwise the next launch (when the profile '
              'IS loaded) would skip the migration and silently lose any '
              'explicit showFuel = false the user had set.',
        );
      },
    );

    test('idempotent — second run after user re-enable preserves the choice',
        () async {
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showFuel: false),
      );
      expect(await repo.loadEnabled(), isNot(contains(Feature.showFuel)));
      expect(settings.get(showFuelMigratedKey), isTrue);

      // User re-enables via the central settings UI.
      await repo.saveEnabled(<Feature>{Feature.showFuel});

      // Second run with the same legacy=false profile must NOT undo the
      // user's explicit re-enable.
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showFuel: false),
      );

      expect(
        await repo.loadEnabled(),
        contains(Feature.showFuel),
        reason:
            'The gate flag short-circuits the second run; the user\'s '
            'explicit re-enable must survive.',
      );
    });

    test('skipped when migration flag already true — central state untouched',
        () async {
      await settings.put(showFuelMigratedKey, true);
      await repo.saveEnabled(<Feature>{Feature.priceAlerts});

      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showFuel: false),
      );

      final after = await repo.loadEnabled();
      expect(
        after,
        contains(Feature.priceAlerts),
        reason:
            'When the migration gate is already set, the legacy field '
            'must not be re-read and the central state must stay exactly '
            'as the user left it after the first migration.',
      );
    });
  });

  group('migrateUserProfileToggles — showElectric (phase 3c)', () {
    UserProfile profileWith({required bool showElectric}) {
      // ignore: deprecated_member_use_from_same_package
      return UserProfile(
        id: 'p1',
        name: 'Test',
        // ignore: deprecated_member_use_from_same_package
        showElectric: showElectric,
      );
    }

    test('legacy true → central state contains showElectric; flag set',
        () async {
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showElectric: true),
      );

      final after = await repo.loadEnabled();
      expect(after, contains(Feature.showElectric));
      expect(settings.get(showElectricMigratedKey), isTrue);
    });

    test(
      'legacy false → central state excludes showElectric (preserves the '
      'explicit opt-out against the manifest default-true); flag set',
      () async {
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(showElectric: false),
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.showElectric)),
          reason:
              'Mirrors the showFuel rationale — manifest defaultEnabled='
              'true means no-op writes silently re-enable, so the '
              'explicit-false branch must persist the exclusion.',
        );
        expect(settings.get(showElectricMigratedKey), isTrue);
      },
    );

    test('idempotent — second run after user re-enable preserves the choice',
        () async {
      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showElectric: false),
      );
      expect(await repo.loadEnabled(), isNot(contains(Feature.showElectric)));

      await repo.saveEnabled(<Feature>{Feature.showElectric});

      await migrateUserProfileToggles(
        settings: settings,
        featureFlags: repo,
        manifest: FeatureManifest.defaultManifest,
        activeProfile: profileWith(showElectric: false),
      );

      expect(await repo.loadEnabled(), contains(Feature.showElectric));
    });
  });

  group('migrateUserProfileToggles — showConsumptionTab (phase 3c)', () {
    UserProfile profileWith({required bool showConsumptionTab}) {
      // ignore: deprecated_member_use_from_same_package
      return UserProfile(
        id: 'p1',
        name: 'Test',
        // ignore: deprecated_member_use_from_same_package
        showConsumptionTab: showConsumptionTab,
      );
    }

    test(
      'legacy true → cascade-enables both Feature.obd2TripRecording '
      '(prerequisite) AND Feature.showConsumptionTab; flag set',
      () async {
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(showConsumptionTab: true),
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          contains(Feature.showConsumptionTab),
          reason:
              'Legacy true must promote — the user explicitly enabled the '
              'consumption tab in their profile and that intent must '
              'survive the migration.',
        );
        expect(
          after,
          contains(Feature.obd2TripRecording),
          reason:
              'Feature.showConsumptionTab requires obd2TripRecording per '
              'the manifest; enabling the dependent without the '
              'prerequisite would leave the central state in a '
              'contract-violating shape.',
        );
        expect(settings.get(showConsumptionTabMigratedKey), isTrue);
      },
    );

    test(
      'legacy false → central state excludes showConsumptionTab '
      '(preserves the original hidden default against the new '
      'manifest default-true); flag set',
      () async {
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(showConsumptionTab: false),
        );

        final after = await repo.loadEnabled();
        expect(
          after,
          isNot(contains(Feature.showConsumptionTab)),
          reason:
              'The legacy field defaulted to false — most users never '
              'flipped it. The new manifest defaults Feature.show'
              'ConsumptionTab to true, so a no-op write would silently '
              'reveal the tab for users who never had it on. The '
              'migrator persists a state that excludes the feature so '
              'the original user-facing shape (tab hidden) is preserved.',
        );
        // Note: obd2TripRecording may still be enabled in `after` if the
        // gamification migrator (which runs first inside
        // migrateUserProfileToggles) cascade-enabled it from the
        // default-true UserProfile.gamificationEnabled. That is the
        // gamification migrator's contract, not this branch's. The
        // assertion we DO care about is that the showConsumptionTab
        // migration did not promote the dependent.
        expect(settings.get(showConsumptionTabMigratedKey), isTrue);
      },
    );

    test(
      'no-op when activeProfile is null — gate flag NOT written, retries '
      'next launch',
      () async {
        await repo.saveEnabled(<Feature>{Feature.priceAlerts});

        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: null,
        );

        expect(settings.get(showConsumptionTabMigratedKey), isNull);
      },
    );

    test(
      'idempotent — second run with same inputs after user disable '
      'preserves the disable',
      () async {
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(showConsumptionTab: true),
        );
        expect(
          await repo.loadEnabled(),
          contains(Feature.showConsumptionTab),
        );

        // User disables in the central settings UI.
        final stillEnabled = {...await repo.loadEnabled()}
          ..remove(Feature.showConsumptionTab);
        await repo.saveEnabled(stillEnabled);

        // Second run must NOT re-promote.
        await migrateUserProfileToggles(
          settings: settings,
          featureFlags: repo,
          manifest: FeatureManifest.defaultManifest,
          activeProfile: profileWith(showConsumptionTab: true),
        );

        expect(
          await repo.loadEnabled(),
          isNot(contains(Feature.showConsumptionTab)),
          reason:
              'The gate flag short-circuits the second run; the user\'s '
              'explicit disable must survive.',
        );
      },
    );
  });
}
