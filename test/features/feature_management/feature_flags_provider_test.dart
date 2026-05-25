// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_dependency_graph.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// A [FeatureFlagsRepository] whose [loadEnabled] always throws — used to
/// exercise the #1681 AsyncNotifier error path (the Hive read failing).
class _ThrowingRepo extends FeatureFlagsRepository {
  _ThrowingRepo(Box<dynamic> box) : super(box: box);

  @override
  Future<Set<Feature>> loadEnabled([
    BuildChannel channel = BuildChannel.production,
  ]) async =>
      throw StateError('simulated Hive read failure');
}

/// Minimal [TraceRecorder] fake — captures whatever [errorLogger] routes
/// to it so the test can assert the failure was surfaced, not swallowed.
class _FakeTraceRecorder implements TraceRecorder {
  Object? capturedError;
  int recordCount = 0;

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    capturedError = error;
    recordCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> box;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('feature_flags_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<dynamic>(
      'feature_flags_${DateTime.now().microsecondsSinceEpoch}',
    );
    repo = FeatureFlagsRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer({
    FeatureManifest? manifest,
    FeatureFlagsRepository? repository,
  }) {
    final c = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repository ?? repo),
      if (manifest != null)
        featureManifestProvider.overrideWithValue(manifest),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Awaits the AsyncNotifier `build()` so reads observe the persisted
  /// set rather than the synchronous manifest-default placeholder
  /// [enabledFeaturesProvider] returns during the load frame (#1681).
  Future<void> pumpLoad(ProviderContainer c) async {
    await c.read(featureFlagsProvider.future);
  }

  group('FeatureFlags initial state', () {
    test('matches defaultManifest defaults on an empty box', () async {
      final c = makeContainer();
      await pumpLoad(c);
      final state = c.read(enabledFeaturesProvider);
      expect(state, FeatureManifest.defaultManifest.defaultEnabledSet());
      // Sanity-check a few that should default true / false respectively.
      expect(state, contains(Feature.gamification));
      expect(state, contains(Feature.priceAlerts));
      expect(state, isNot(contains(Feature.obd2TripRecording)));
      expect(state, isNot(contains(Feature.tankSync)));
    });
  });

  group('FeatureFlags.enable / disable', () {
    test('enable(gamification) throws when obd2TripRecording is disabled',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      // Defaults: gamification is in the set but obd2TripRecording is not.
      // To trigger the guard we first remove gamification, then attempt to
      // re-enable it without its prerequisite.
      await c.read(featureFlagsProvider.notifier).disable(Feature.gamification);
      expect(
        () => c.read(featureFlagsProvider.notifier).enable(Feature.gamification),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('Cannot enable gamification'),
              contains('obd2TripRecording')),
        )),
      );
    });

    test('enable(obd2TripRecording) then enable(gamification) succeeds',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c
          .read(featureFlagsProvider.notifier)
          .disable(Feature.gamification);
      await c
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      await c
          .read(featureFlagsProvider.notifier)
          .enable(Feature.gamification);

      final state = c.read(enabledFeaturesProvider);
      expect(state, contains(Feature.obd2TripRecording));
      expect(state, contains(Feature.gamification));
    });

    test(
        'disable(obd2TripRecording) succeeds while gamification is enabled — '
        'gamification stays in stored set but is effectively disabled (#1447)',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      expect(c.read(enabledFeaturesProvider), contains(Feature.gamification));

      // Cascading-disable: parent comes off, child stays in storage so the
      // user's preference is preserved, but the user-visible "is this
      // surface available" answer is false.
      await c
          .read(featureFlagsProvider.notifier)
          .disable(Feature.obd2TripRecording);

      final state = c.read(enabledFeaturesProvider);
      expect(state, isNot(contains(Feature.obd2TripRecording)));
      expect(
        state,
        contains(Feature.gamification),
        reason:
            'Child stored state must be preserved on parent-disable so '
            're-enabling the parent restores the prior setup.',
      );
      expect(
        isEffectivelyEnabled(
          Feature.gamification,
          FeatureManifest.defaultManifest,
          state,
        ),
        isFalse,
        reason:
            'With obd2TripRecording off, gamification is not effectively '
            'enabled regardless of its stored value.',
      );

      // Re-enabling the parent flips the child back to effectively-on
      // without any explicit child re-toggle.
      await c
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      expect(
        isEffectivelyEnabled(
          Feature.gamification,
          FeatureManifest.defaultManifest,
          c.read(enabledFeaturesProvider),
        ),
        isTrue,
      );
    });

    test('isEnabled mirrors the current state', () async {
      final c = makeContainer();
      await pumpLoad(c);
      final notifier = c.read(featureFlagsProvider.notifier);
      expect(notifier.isEnabled(Feature.priceAlerts), isTrue);
      expect(notifier.isEnabled(Feature.tankSync), isFalse);
      await notifier.enable(Feature.tankSync);
      expect(notifier.isEnabled(Feature.tankSync), isTrue);
    });
  });

  group('FeatureFlags persistence round-trip', () {
    test('enable -> save -> reload still enabled', () async {
      final c1 = makeContainer();
      await pumpLoad(c1);
      await c1.read(featureFlagsProvider.notifier).enable(Feature.tankSync);
      expect(c1.read(enabledFeaturesProvider), contains(Feature.tankSync));

      // Fresh container, same Hive box → persisted set wins over defaults.
      final c2 = makeContainer();
      await pumpLoad(c2);
      final state = c2.read(enabledFeaturesProvider);
      expect(state, contains(Feature.tankSync));
      // Things on by default that were never touched stay on.
      expect(state, contains(Feature.priceAlerts));
    });

    test('disable -> save -> reload stays disabled', () async {
      final c1 = makeContainer();
      await pumpLoad(c1);
      // priceAlerts defaults true; disabling it must survive a reload.
      await c1
          .read(featureFlagsProvider.notifier)
          .disable(Feature.priceAlerts);

      final c2 = makeContainer();
      await pumpLoad(c2);
      expect(c2.read(enabledFeaturesProvider),
          isNot(contains(Feature.priceAlerts)));
    });
  });

  group('FeatureFlags cycle detection', () {
    test('build throws when the manifest contains a cycle', () async {
      const cyclic = FeatureManifest({
        Feature.gamification: FeatureManifestEntry.allChannels(
          feature: Feature.gamification,
          defaultOn: false,
          requires: {Feature.hapticEcoCoach},
          displayName: 'gamification',
          description: 'cycle test',
        ),
        Feature.hapticEcoCoach: FeatureManifestEntry.allChannels(
          feature: Feature.hapticEcoCoach,
          defaultOn: false,
          requires: {Feature.gamification},
          displayName: 'hapticEcoCoach',
          description: 'cycle test',
        ),
      });
      final c = makeContainer(manifest: cyclic);
      // `assertNoCycles` throws inside the async `build()`, so the
      // failure surfaces as a rejected `future` rather than a
      // synchronous throw. The contract we care about is that the
      // StateError naming the cycle surfaces (matched by message).
      await expectLater(
        c.read(featureFlagsProvider.future),
        throwsA(predicate(
          (e) => e.toString().contains('Feature dependency cycle'),
          'wraps a StateError naming the cycle',
        )),
      );
    });
  });

  group('FeatureFlags Hive-read failure (#1681)', () {
    test('a failed loadEnabled is logged and falls back to manifest defaults',
        () async {
      final recorder = _FakeTraceRecorder();
      errorLogger.testRecorderOverride = recorder;
      addTearDown(errorLogger.resetForTest);

      final c = makeContainer(repository: _ThrowingRepo(box));

      // build() catches the throwing loadEnabled, logs it, and resolves
      // to the manifest defaults — the future completes, never rejects.
      final state = await c.read(featureFlagsProvider.future);
      expect(state, FeatureManifest.defaultManifest.defaultEnabledSet());
      expect(c.read(enabledFeaturesProvider),
          FeatureManifest.defaultManifest.defaultEnabledSet());

      // The failure was surfaced through the central error pipeline,
      // tagged as a storage-layer error — not silently swallowed.
      expect(recorder.recordCount, greaterThan(0));
      final captured = recorder.capturedError;
      expect(captured, isA<ContextualError>());
      expect((captured! as ContextualError).layer, ErrorLayer.storage);
    });
  });
}
