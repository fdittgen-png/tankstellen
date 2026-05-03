import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/sync/providers/baseline_sync_enabled_provider.dart';

/// Provider-layer coverage for the [baselineSyncEnabledProvider]
/// (#780). As of #1373 phase 3e this provider is a thin shim that
/// delegates to [featureFlagsProvider]; tests assert that contract:
///
///   1. Default state mirrors the manifest default for
///      [Feature.baselineSync] (`false`).
///   2. Reads return the central enabled-set membership for
///      [Feature.baselineSync] when both the prereq and dependent
///      are seeded.
///   3. `set(true)` enables `baselineSync` AND keeps `tankSync`
///      (cascade enforced by the central provider).
///   4. `set(false)` disables `baselineSync` but the `tankSync`
///      prereq stays — only the dependent is removed.
///   5. `set(true)` is a no-op when the `tankSync` prerequisite is
///      missing — the dependency-violation StateError is swallowed.
///   6. External writes to [featureFlagsProvider] propagate to the
///      shim via `ref.watch`.
///   7. A dependency-violation StateError thrown by a fake notifier
///      is swallowed and the toggle stays at its prior state.
///
/// Migration concerns (the legacy [StorageKeys.syncBaselinesEnabled]
/// Hive key → central state promotion) are covered in
/// `test/features/feature_management/data/legacy_toggle_migrator_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('baseline_sync_shim_');
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

  group('baselineSyncEnabledProvider — shim over featureFlagsProvider', () {
    test('defaults to false on a fresh profile', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(baselineSyncEnabledProvider),
        isFalse,
        reason:
            'Default-OFF is the contract: a user who never toggles the '
            'switch must not silently upload driving data. Manifest '
            'declares baselineSync defaultEnabled=false.',
      );
    });

    test('reads the central enabled-set on build', () async {
      // Pre-seed central state with both the prerequisite (tankSync)
      // and the dependent (baselineSync). Without tankSync the central
      // provider would reject the seeded set.
      await repo.saveEnabled(<Feature>{
        Feature.tankSync,
        Feature.baselineSync,
      });

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(baselineSyncEnabledProvider),
        isTrue,
        reason:
            'The shim must surface the central provider state — a '
            'persisted-true in the central feature-flags repository is '
            'the source of truth post-#1373 phase 3e.',
      );
    });

    test('set(true) enables baselineSync AND keeps the tankSync prereq',
        () async {
      // Prerequisite must be on first or the central provider would
      // throw StateError (which the shim swallows). Seed it.
      await repo.saveEnabled(<Feature>{Feature.tankSync});

      final container = makeContainer();
      await pumpLoad(container);

      // Materialise so the read after `set` walks the in-memory state
      // path rather than re-running build.
      container.read(baselineSyncEnabledProvider);
      await container.read(baselineSyncEnabledProvider.notifier).set(true);

      final after = container.read(featureFlagsProvider);
      expect(
        after,
        contains(Feature.baselineSync),
        reason:
            'set(true) must route through featureFlagsProvider.enable so '
            'the central state is the single source of truth — the legacy '
            'StorageKeys.syncBaselinesEnabled is no longer the '
            'authoritative store.',
      );
      expect(
        after,
        contains(Feature.tankSync),
        reason:
            'tankSync is the manifest-declared prerequisite of '
            'baselineSync. Enabling baselineSync must NOT silently '
            'remove the prereq — the central provider preserves it.',
      );
      expect(
        container.read(baselineSyncEnabledProvider),
        isTrue,
        reason:
            'The shim state must reflect the central enable immediately '
            'so the next trip flush observes the new value via ref.read.',
      );
    });

    test('set(false) disables baselineSync but tankSync prereq stays',
        () async {
      // Seed both on so we can flip baselineSync off.
      await repo.saveEnabled(<Feature>{
        Feature.tankSync,
        Feature.baselineSync,
      });

      final container = makeContainer();
      await pumpLoad(container);

      container.read(baselineSyncEnabledProvider);
      await container.read(baselineSyncEnabledProvider.notifier).set(false);

      final after = container.read(featureFlagsProvider);
      expect(
        after,
        isNot(contains(Feature.baselineSync)),
      );
      expect(
        after,
        contains(Feature.tankSync),
        reason:
            'Disabling baselineSync must only remove the dependent — '
            'tankSync is independently useful (favourite sync, etc.) '
            'and must not be cascade-disabled when one of its '
            'dependents is turned off.',
      );
      expect(container.read(baselineSyncEnabledProvider), isFalse);
    });

    test(
      'set(true) is a no-op when the tankSync prerequisite is missing — '
      'does NOT throw',
      () async {
        // Prerequisite tankSync is OFF. Calling enable on the central
        // provider would throw StateError; the shim must swallow it
        // and leave the toggle at its prior state.
        final container = makeContainer();
        await pumpLoad(container);

        // No throw expected.
        await container.read(baselineSyncEnabledProvider.notifier).set(true);

        expect(
          container.read(baselineSyncEnabledProvider),
          isFalse,
          reason:
              'Dependency-violation must be silent at the shim layer — '
              'the settings UI is expected to pre-check `canEnable` '
              'before invoking the setter, so reaching this path means '
              'a programmatic / test caller bypassed the guard. The '
              'shim swallows so the widget tree stays standing rather '
              'than crashing on a developer mistake.',
        );
        expect(
          container.read(featureFlagsProvider),
          isNot(contains(Feature.baselineSync)),
        );
      },
    );

    test('rebuilds when featureFlagsProvider changes via override mutation',
        () async {
      // Use the synthetic FeatureFlags notifier override so we can
      // drive state changes from the test without going through the
      // dependency-cascade enforcement (the synthetic fake doesn't
      // enforce the manifest graph).
      final fake = _TestFeatureFlags(<Feature>{Feature.tankSync});
      final container = makeContainer(extraOverrides: [
        featureFlagsProvider.overrideWith(() => fake),
      ]);

      // Initial: baselineSync absent → shim is false.
      expect(container.read(baselineSyncEnabledProvider), isFalse);

      // External mutation: enable on the central provider directly.
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.baselineSync);

      expect(
        container.read(baselineSyncEnabledProvider),
        isTrue,
        reason:
            'External writes to featureFlagsProvider (e.g. from settings '
            'UI, a deep-link handler, or another shim) must propagate '
            'through the baselineSync shim because it watches the '
            'central state.',
      );

      // And back the other way.
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.baselineSync);
      expect(container.read(baselineSyncEnabledProvider), isFalse);
    });

    test(
      'set(true) swallows a dependency-violation StateError from the central '
      'provider — toggle stays at its prior state',
      () async {
        // Use a spy fake that always throws StateError to exercise the
        // defensive `on StateError` catch in the shim. The real central
        // provider throws this exact error when the manifest
        // prerequisite is missing.
        final fake = _ThrowingFeatureFlags();
        final container = makeContainer(extraOverrides: [
          featureFlagsProvider.overrideWith(() => fake),
        ]);

        // Sanity: starting state is false.
        expect(container.read(baselineSyncEnabledProvider), isFalse);

        // No throw expected — the shim's `on StateError` catch must
        // swallow the dependency-violation signal.
        await container.read(baselineSyncEnabledProvider.notifier).set(true);

        expect(
          container.read(baselineSyncEnabledProvider),
          isFalse,
          reason:
              'Dependency-violation must be silent at the shim layer — '
              'the settings UI pre-checks `canEnable`, so reaching this '
              'path means a programmatic / test caller bypassed the '
              'guard. The shim swallows so the widget tree stays '
              'standing rather than crashing on a developer mistake.',
        );
        expect(
          container.read(featureFlagsProvider),
          isNot(contains(Feature.baselineSync)),
        );
      },
    );
  });
}

/// Synthetic in-memory [FeatureFlags] notifier used to drive
/// external-mutation paths without going through the Hive-backed
/// repository AND without enforcing the manifest dependency graph.
/// Mirrors the equivalent test double in
/// `test/core/refuel/unified_search_results_enabled_test.dart`.
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

/// Spy fake that always throws [StateError] on `enable` / `disable` —
/// used to exercise the shim's defensive `on StateError` catch even
/// when the call would otherwise succeed (e.g. when the prereq is
/// satisfied but the central API is mocked to fail).
class _ThrowingFeatureFlags extends FeatureFlags {
  @override
  Set<Feature> build() => <Feature>{};

  @override
  Future<void> enable(Feature feature) async {
    throw StateError(
      'Cannot enable ${feature.name}: simulated dependency-violation',
    );
  }

  @override
  Future<void> disable(Feature feature) async {
    throw StateError(
      'Cannot disable ${feature.name}: simulated blockingDisable',
    );
  }
}
