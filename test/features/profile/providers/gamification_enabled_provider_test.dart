import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';

/// Provider-layer coverage for the [gamificationEnabledProvider]
/// (#1194). As of #1373 phase 3b this provider is a thin shim that
/// delegates to [featureFlagsProvider]; tests assert that contract:
///
///   1. Default state mirrors `featureFlagsProvider.contains(Feature.gamification)`
///      (manifest default = `true`).
///   2. `set(true)` enables `gamification` in the central provider.
///   3. `set(false)` disables it.
///   4. Cascade prerequisite: when the central provider is given a
///      pre-seeded state with `obd2TripRecording` plus `gamification`,
///      the shim surfaces the persisted-true state.
///   5. A dependency-violation is swallowed and the toggle stays at
///      its prior state — the central provider throws StateError when
///      `obd2TripRecording` is missing; the shim's catch must surface
///      that as "no-op" rather than a thrown error.
///   6. Provider rebuilds when [featureFlagsProvider] changes externally.
///   7. `keepAlive: true` survives consumer-tree teardown — the shim
///      must not rebuild when its dependencies are unchanged across
///      consumer detach/reattach cycles.
///
/// Migration concerns (the legacy `UserProfile.gamificationEnabled`
/// → central state promotion) are covered in
/// `test/features/feature_management/data/legacy_toggle_migrator_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('gamification_shim_');
    Hive.init(tmpDir.path);
    flagsBox = await Hive.openBox<dynamic>(
      'feature_flags_${DateTime.now().microsecondsSinceEpoch}',
    );
    repo = FeatureFlagsRepository(box: flagsBox);
  });

  tearDown(() async {
    await flagsBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer({List<Object> extraOverrides = const []}) {
    final c = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repo),
      ...extraOverrides.cast(),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Drains the post-build async load on featureFlagsProvider so reads
  /// observe the persisted set rather than the manifest-default
  /// placeholder.
  Future<void> pumpLoad(ProviderContainer c) async {
    c.read(featureFlagsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('gamificationEnabledProvider — shim over featureFlagsProvider', () {
    test('defaults to true on a fresh install (manifest default)', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(gamificationEnabledProvider),
        isTrue,
        reason:
            'Default-ON is the contract: existing users see no behaviour '
            'change. Manifest declares Feature.gamification defaultEnabled=true.',
      );
    });

    test('reads the central enabled-set on build', () async {
      // Pre-seed central state with both prerequisite + dependent.
      await repo.saveEnabled(<Feature>{
        Feature.obd2TripRecording,
        Feature.gamification,
      });

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(gamificationEnabledProvider),
        isTrue,
        reason:
            'The shim must surface the central provider state — a '
            'persisted-true in the central feature-flags repository is '
            'the source of truth post-#1373 phase 3b.',
      );

      // And mirrors a persisted-false explicitly.
      await repo.saveEnabled(<Feature>{Feature.obd2TripRecording});
      // Force a fresh container so the new persisted state is reloaded.
      final container2 = makeContainer();
      await pumpLoad(container2);
      expect(
        container2.read(gamificationEnabledProvider),
        isFalse,
        reason:
            'A persisted central state without Feature.gamification must '
            'surface as false, not the manifest default.',
      );
    });

    test('set(true) enables gamification in the central provider', () async {
      // Prerequisite must be on first or the central provider would
      // throw StateError (which the shim swallows). Seed it.
      await repo.saveEnabled(<Feature>{Feature.obd2TripRecording});

      final container = makeContainer();
      await pumpLoad(container);

      // Materialise so the read after `set` walks the in-memory state
      // path rather than re-running build.
      container.read(gamificationEnabledProvider);
      await container
          .read(gamificationEnabledProvider.notifier)
          .set(true);

      expect(
        container.read(featureFlagsProvider),
        contains(Feature.gamification),
        reason:
            'set(true) must route through featureFlagsProvider.enable so '
            'the central state is the single source of truth — the legacy '
            'UserProfile.gamificationEnabled field is no longer the '
            'authoritative store.',
      );
      expect(
        container.read(gamificationEnabledProvider),
        isTrue,
        reason:
            'The shim state must reflect the central enable immediately so '
            'consumers (BadgeShelf, achievement tabs, …) re-render without '
            'waiting for the next provider invalidation.',
      );
    });

    test('set(false) disables gamification in the central provider',
        () async {
      // Seed both on so we can flip gamification off.
      await repo.saveEnabled(<Feature>{
        Feature.obd2TripRecording,
        Feature.gamification,
      });

      final container = makeContainer();
      await pumpLoad(container);

      container.read(gamificationEnabledProvider);
      await container
          .read(gamificationEnabledProvider.notifier)
          .set(false);

      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.gamification)),
      );
      expect(container.read(gamificationEnabledProvider), isFalse);
    });

    test('set(true) is a no-op when prerequisite is missing — does NOT throw',
        () async {
      // Prerequisite obd2TripRecording is OFF AND we also ensure
      // gamification is OFF in the persisted set to defeat the manifest
      // default that would otherwise mask the dependency-violation
      // path. Calling enable on the central provider would throw
      // StateError; the shim must swallow it and leave the toggle at
      // its prior state.
      await repo.saveEnabled(<Feature>{});

      final container = makeContainer();
      await pumpLoad(container);

      // Sanity: starting state is false (no obd2TripRecording, no
      // gamification persisted).
      expect(container.read(gamificationEnabledProvider), isFalse);

      // No throw expected.
      await container
          .read(gamificationEnabledProvider.notifier)
          .set(true);

      expect(
        container.read(gamificationEnabledProvider),
        isFalse,
        reason:
            'Dependency-violation must be silent at the shim layer — the '
            'Phase 2 settings UI pre-checks `canEnable`, so reaching this '
            'path means a programmatic / test caller bypassed the guard. '
            'The shim swallows so the widget tree stays standing rather '
            'than crashing on a developer mistake.',
      );
      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.gamification)),
      );
    });

    test('rebuilds when featureFlagsProvider changes via override mutation',
        () async {
      // Use the synthetic FeatureFlags notifier override so we can drive
      // state changes from the test.
      final fake = _TestFeatureFlags(<Feature>{Feature.obd2TripRecording});
      final container = makeContainer(extraOverrides: [
        featureFlagsProvider.overrideWith(() => fake),
      ]);

      // Initial: gamification absent → shim is false.
      expect(container.read(gamificationEnabledProvider), isFalse);

      // External mutation: enable gamification on the central provider.
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.gamification);

      expect(
        container.read(gamificationEnabledProvider),
        isTrue,
        reason:
            'External writes to featureFlagsProvider (e.g. from settings '
            'UI, a deep-link handler, or another shim) must propagate '
            'through the gamification shim because it watches the central '
            'state.',
      );
    });

    test(
      'keepAlive: true does not rebuild on repeat reads when no dependency '
      'changed',
      () async {
        // We can't directly inspect ProviderElement identity (the API is
        // @internal in riverpod 3.x), so we use a build-counting fake on
        // the upstream featureFlagsProvider to assert that the shim does
        // not re-trigger the upstream's `build` on consecutive reads.
        // A non-keepAlive shim would dispose between reads and re-watch
        // the upstream, bumping the counter.
        final fake = _BuildCountingFlags(<Feature>{Feature.gamification});
        final container = makeContainer(extraOverrides: [
          featureFlagsProvider.overrideWith(() => fake),
        ]);

        // Materialise the shim once.
        expect(container.read(gamificationEnabledProvider), isTrue);
        final buildsAfterFirstRead = fake.buildCount;
        expect(
          buildsAfterFirstRead,
          1,
          reason: 'Initial materialisation should run the upstream build once.',
        );

        // A microtask hop and a second read — the shim must not have
        // disposed in between (keepAlive:true), so the upstream build
        // counter stays at 1.
        await Future<void>.microtask(() {});
        expect(container.read(gamificationEnabledProvider), isTrue);
        expect(
          fake.buildCount,
          buildsAfterFirstRead,
          reason:
              'keepAlive:true must keep the shim alive across reads — '
              'a re-trigger of the upstream `build` would mean the shim '
              'disposed and re-subscribed, which would lose any in-flight '
              'enable() call and racey-flicker the UI.',
        );
      },
    );
  });
}

/// Build-counting variant of [_TestFeatureFlags] for the keepAlive
/// regression test — counts how many times `build` runs so the test
/// can assert the shim does not re-subscribe to its upstream on
/// consecutive reads.
class _BuildCountingFlags extends FeatureFlags {
  _BuildCountingFlags([Set<Feature>? initial])
      : _initial = initial ?? <Feature>{};

  final Set<Feature> _initial;
  int buildCount = 0;

  @override
  Set<Feature> build() {
    buildCount++;
    return {..._initial};
  }

  @override
  Future<void> enable(Feature feature) async {
    if (state.contains(feature)) return;
    state = {...state, feature};
  }

  @override
  Future<void> disable(Feature feature) async {
    if (!state.contains(feature)) return;
    state = {...state}..remove(feature);
  }
}

/// Synthetic in-memory [FeatureFlags] notifier used to drive
/// dependency-violation and external-mutation paths without going
/// through the Hive-backed repository. Mirrors the equivalent test
/// double in `test/features/driving/presentation/driving_settings_section_test.dart`.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags([Set<Feature>? initial])
      : _initial = initial ?? <Feature>{};

  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};

  @override
  Future<void> enable(Feature feature) async {
    if (state.contains(feature)) return;
    state = {...state, feature};
  }

  @override
  Future<void> disable(Feature feature) async {
    if (!state.contains(feature)) return;
    state = {...state}..remove(feature);
  }
}
