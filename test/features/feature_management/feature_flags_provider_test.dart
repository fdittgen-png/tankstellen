import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

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

  ProviderContainer makeContainer({FeatureManifest? manifest}) {
    final c = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repo),
      if (manifest != null)
        featureManifestProvider.overrideWithValue(manifest),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Drains the post-build async load so reads observe the persisted set
  /// rather than the synchronous manifest-default placeholder.
  Future<void> pumpLoad(ProviderContainer c) async {
    c.read(featureFlagsProvider);
    // Two microtask drains — one for repo.loadEnabled().then, one for the
    // setter. A single delay covers both in practice.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('FeatureFlags initial state', () {
    test('matches defaultManifest defaults on an empty box', () async {
      final c = makeContainer();
      await pumpLoad(c);
      final state = c.read(featureFlagsProvider);
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

      final state = c.read(featureFlagsProvider);
      expect(state, contains(Feature.obd2TripRecording));
      expect(state, contains(Feature.gamification));
    });

    test('disable(obd2TripRecording) throws when gamification is enabled',
        () async {
      final c = makeContainer();
      await pumpLoad(c);
      await c
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      // gamification is on by default; ensure it's still set after the
      // pre-condition above.
      expect(c.read(featureFlagsProvider), contains(Feature.gamification));

      expect(
        () => c
            .read(featureFlagsProvider.notifier)
            .disable(Feature.obd2TripRecording),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('Cannot disable obd2TripRecording'),
              contains('gamification')),
        )),
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
      expect(c1.read(featureFlagsProvider), contains(Feature.tankSync));

      // Fresh container, same Hive box → persisted set wins over defaults.
      final c2 = makeContainer();
      await pumpLoad(c2);
      final state = c2.read(featureFlagsProvider);
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
      expect(c2.read(featureFlagsProvider), isNot(contains(Feature.priceAlerts)));
    });
  });

  group('FeatureFlags cycle detection', () {
    test('build throws when the manifest contains a cycle', () async {
      const cyclic = FeatureManifest({
        Feature.gamification: FeatureManifestEntry(
          feature: Feature.gamification,
          defaultEnabled: false,
          requires: {Feature.hapticEcoCoach},
          displayName: 'gamification',
          description: 'cycle test',
        ),
        Feature.hapticEcoCoach: FeatureManifestEntry(
          feature: Feature.hapticEcoCoach,
          defaultEnabled: false,
          requires: {Feature.gamification},
          displayName: 'hapticEcoCoach',
          description: 'cycle test',
        ),
      });
      final c = makeContainer(manifest: cyclic);
      // Riverpod wraps build-time throws inside ProviderException; the
      // contract we care about is that the StateError surfaces (matched
      // by message), not the wrapper class.
      expect(
        () => c.read(featureFlagsProvider),
        throwsA(predicate(
          (e) => e.toString().contains('Feature dependency cycle'),
          'wraps a StateError naming the cycle',
        )),
      );
    });
  });
}
