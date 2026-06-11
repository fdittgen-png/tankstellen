// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_toggle_notifier.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/sync/providers/baseline_sync_enabled_provider.dart';

/// Coverage for the shared [FeatureToggleNotifier] mixin +
/// [watchEffectiveFeature] helper (#3175) — the single implementation
/// behind every per-feature toggle shim (gamification, baseline-sync,
/// the show-toggles, haptic-eco-coach, …).
///
/// Exercised through representative production shims
/// ([gamificationEnabledProvider], requires `obd2TripRecording`, default
/// ON; [baselineSyncEnabledProvider], requires `tankSync`, default OFF)
/// so the tests drive the real generated notifier + mixin composition,
/// not a synthetic stand-in:
///
///   1. `set(true)` / `set(false)` route through
///      [featureFlagsProvider]'s `enable` / `disable`.
///   2. A dependency-violation [StateError] (enabling while the
///      prerequisite is off) is swallowed — the unified-safest setter
///      semantics — and the toggle stays at its prior state.
///   3. [watchEffectiveFeature] gates on the *effective* state: the
///      stored flag surfaces as `false` while an ancestor is disabled.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('feature_toggle_shared_');
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

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Drains the post-build async load on featureFlagsProvider so reads
  /// observe the persisted set rather than the manifest-default
  /// placeholder.
  Future<void> pumpLoad(ProviderContainer c) async {
    c.read(enabledFeaturesProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('FeatureToggleNotifier (shared toggle-shim implementation, #3175)',
      () {
    test('set routes through the central enable/disable', () async {
      // Prerequisite on so enable is legal.
      await repo.saveEnabled(<Feature>{Feature.obd2TripRecording});

      final container = makeContainer();
      await pumpLoad(container);

      container.read(gamificationEnabledProvider);
      await container.read(gamificationEnabledProvider.notifier).set(true);

      expect(
        container.read(enabledFeaturesProvider),
        contains(Feature.gamification),
        reason: 'The mixin setter must delegate to '
            'featureFlagsProvider.enable — the central set is the single '
            'source of truth.',
      );
      expect(container.read(gamificationEnabledProvider), isTrue);

      await container.read(gamificationEnabledProvider.notifier).set(false);

      expect(
        container.read(enabledFeaturesProvider),
        isNot(contains(Feature.gamification)),
        reason: 'The mixin setter must delegate to '
            'featureFlagsProvider.disable.',
      );
      expect(container.read(gamificationEnabledProvider), isFalse);
    });

    test(
        'dependency-violation StateError is swallowed and the toggle '
        'stays at its prior state', () async {
      // Exercised through baselineSyncEnabled (manifest default-OFF,
      // requires tankSync — unlike gamification, whose default-ON would
      // mask the violation). The prerequisite tankSync is OFF, so
      // enable(baselineSync) throws a StateError inside the central
      // provider. The shared setter must swallow it (the safest unified
      // variant) so a programmatic caller never crashes, and the
      // violating enable must not take effect.
      final container = makeContainer();
      await pumpLoad(container);

      container.read(baselineSyncEnabledProvider);
      await container.read(baselineSyncEnabledProvider.notifier).set(true);

      expect(
        container.read(enabledFeaturesProvider),
        isNot(contains(Feature.baselineSync)),
        reason: 'The central provider throws before mutating — the '
            'violating enable must leave the flag set untouched.',
      );
      expect(container.read(baselineSyncEnabledProvider), isFalse);
    });

    test(
        'watchEffectiveFeature gates the stored flag on the requires '
        'chain', () async {
      // gamification stored ON, but its prerequisite obd2TripRecording
      // is OFF — the effective state must surface as false.
      await repo.saveEnabled(<Feature>{Feature.gamification});

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(gamificationEnabledProvider),
        isFalse,
        reason: 'An ancestor on the requires chain is disabled, so the '
            'effective state is false regardless of the stored value '
            '(#1447 semantics, now centralised in watchEffectiveFeature).',
      );
    });
  });
}
