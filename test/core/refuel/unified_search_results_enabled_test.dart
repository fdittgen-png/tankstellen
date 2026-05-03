import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/refuel/unified_search_results_enabled.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

/// Provider-layer coverage for the [unifiedSearchResultsEnabledProvider]
/// (#1116). As of #1373 phase 3f this provider is a thin shim that
/// delegates to [featureFlagsProvider]; tests assert that contract:
///
///   1. Default state mirrors the manifest default for
///      [Feature.unifiedSearchResults] (`false`).
///   2. Reads return the central enabled-set membership for
///      [Feature.unifiedSearchResults].
///   3. `set(true)` enables `unifiedSearchResults` in the central provider.
///   4. `set(false)` disables it.
///   5. `toggle()` flips the current state.
///   6. Provider rebuilds when [featureFlagsProvider] changes externally.
///   7. A dependency-violation StateError thrown by a fake notifier is
///      swallowed and the toggle stays at its prior state — the real
///      central provider has no `requires:` for unifiedSearchResults so
///      this path is defensive-only, but the catch must still cover it.
///
/// Migration concerns (the legacy
/// `StorageKeys.unifiedSearchResultsEnabled` Hive key → central state
/// promotion) are covered in
/// `test/features/feature_management/data/legacy_toggle_migrator_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('unified_search_shim_');
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

  group('unifiedSearchResultsEnabledProvider — shim over featureFlagsProvider',
      () {
    test('defaults to false on a fresh profile', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(unifiedSearchResultsEnabledProvider),
        isFalse,
        reason:
            'Default-OFF is the contract: a user who never opted into the '
            'unified results UI must not see it. Manifest declares '
            'unifiedSearchResults defaultEnabled=false.',
      );
    });

    test('reads the central enabled-set on build', () async {
      // Pre-seed central state with the unifiedSearchResults flag on.
      await repo.saveEnabled(<Feature>{Feature.unifiedSearchResults});

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(unifiedSearchResultsEnabledProvider),
        isTrue,
        reason:
            'The shim must surface the central provider state — a '
            'persisted-true in the central feature-flags repository is '
            'the source of truth post-#1373 phase 3f.',
      );
    });

    test('set(true) enables unifiedSearchResults in the central provider',
        () async {
      final container = makeContainer();
      await pumpLoad(container);

      // Materialise so the read after `set` walks the in-memory state
      // path rather than re-running build.
      container.read(unifiedSearchResultsEnabledProvider);
      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .set(true);

      expect(
        container.read(featureFlagsProvider),
        contains(Feature.unifiedSearchResults),
        reason:
            'set(true) must route through featureFlagsProvider.enable so '
            'the central state is the single source of truth — the legacy '
            'StorageKeys.unifiedSearchResultsEnabled is no longer the '
            'authoritative store.',
      );
      expect(
        container.read(unifiedSearchResultsEnabledProvider),
        isTrue,
        reason:
            'The shim state must reflect the central enable immediately so '
            'unifiedSearchResultsProvider re-derives the merged fuel/EV '
            'list without waiting for the next provider invalidation.',
      );
    });

    test('set(false) disables unifiedSearchResults in the central provider',
        () async {
      // Seed it on so we can flip it off.
      await repo.saveEnabled(<Feature>{Feature.unifiedSearchResults});

      final container = makeContainer();
      await pumpLoad(container);

      container.read(unifiedSearchResultsEnabledProvider);
      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .set(false);

      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.unifiedSearchResults)),
      );
      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);
    });

    test('toggle() flips the current state', () async {
      final container = makeContainer();
      await pumpLoad(container);

      // Starts false (manifest default).
      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .toggle();
      expect(
        container.read(unifiedSearchResultsEnabledProvider),
        isTrue,
        reason:
            'toggle() from false must flip to true and route through the '
            'central provider so the persisted state and the in-memory '
            'state stay in sync.',
      );
      expect(
        container.read(featureFlagsProvider),
        contains(Feature.unifiedSearchResults),
      );

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .toggle();
      expect(
        container.read(unifiedSearchResultsEnabledProvider),
        isFalse,
        reason:
            'toggle() from true must flip back to false — round-tripping '
            'verifies both branches of the toggle delegate to set().',
      );
      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.unifiedSearchResults)),
      );
    });

    test('rebuilds when featureFlagsProvider changes via override mutation',
        () async {
      // Use the synthetic FeatureFlags notifier override so we can drive
      // state changes from the test.
      final fake = _TestFeatureFlags();
      final container = makeContainer(extraOverrides: [
        featureFlagsProvider.overrideWith(() => fake),
      ]);

      // Initial: unifiedSearchResults absent → shim is false.
      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);

      // External mutation: enable on the central provider directly.
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.unifiedSearchResults);

      expect(
        container.read(unifiedSearchResultsEnabledProvider),
        isTrue,
        reason:
            'External writes to featureFlagsProvider (e.g. from settings '
            'UI, a deep-link handler, or another shim) must propagate '
            'through the unifiedSearchResults shim because it watches the '
            'central state.',
      );

      // And back the other way.
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.unifiedSearchResults);
      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);
    });

    test(
      'set(true) swallows a dependency-violation StateError from the central '
      'provider — toggle stays at its prior state',
      () async {
        // unifiedSearchResults has no manifest prerequisites, so the
        // real central provider can't throw on enable. Use a spy fake
        // that throws StateError to exercise the defensive `on
        // StateError` catch in the shim.
        final fake = _ThrowingFeatureFlags();
        final container = makeContainer(extraOverrides: [
          featureFlagsProvider.overrideWith(() => fake),
        ]);

        // Sanity: starting state is false.
        expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);

        // No throw expected — the shim's `on StateError` catch must
        // swallow the dependency-violation signal.
        await container
            .read(unifiedSearchResultsEnabledProvider.notifier)
            .set(true);

        expect(
          container.read(unifiedSearchResultsEnabledProvider),
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
          isNot(contains(Feature.unifiedSearchResults)),
        );
      },
    );
  });
}

/// Synthetic in-memory [FeatureFlags] notifier used to drive
/// external-mutation paths without going through the Hive-backed
/// repository. Mirrors the equivalent test double in
/// `test/features/profile/providers/gamification_enabled_provider_test.dart`.
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
/// though [Feature.unifiedSearchResults] has no real manifest
/// prerequisite that could trigger one in production.
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
