import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/driving/haptic_eco_coach.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

/// Provider-layer coverage for the [hapticEcoCoachEnabledProvider]
/// (#1122). As of #1373 phase 3a this provider is a thin shim that
/// delegates to [featureFlagsProvider]; tests assert that contract:
///
///   1. Reads return the central enabled-set membership for
///      [Feature.hapticEcoCoach].
///   2. `set(true)` enables `hapticEcoCoach` in the central provider.
///   3. `set(false)` disables it.
///   4. A dependency-violation is swallowed and the toggle stays at
///      its prior state — the central provider throws StateError when
///      `obd2TripRecording` is missing; the shim's catch must surface
///      that as "no-op" rather than a thrown error.
///
/// Migration concerns (the legacy `hapticEcoCoachEnabled` Hive key
/// → central state promotion) are covered in
/// `test/features/feature_management/data/legacy_toggle_migrator_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('haptic_shim_');
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
    c.read(featureFlagsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('hapticEcoCoachEnabledProvider — shim over featureFlagsProvider', () {
    test('defaults to false on a fresh profile', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(hapticEcoCoachEnabledProvider),
        isFalse,
        reason:
            'Default-OFF is the contract: a user who never toggles the '
            'switch must not get haptic nudges. Manifest declares '
            'hapticEcoCoach defaultEnabled=false.',
      );
    });

    test('reads the central enabled-set on build', () async {
      // Pre-seed central state with both prerequisite + dependent.
      await repo.saveEnabled(<Feature>{
        Feature.obd2TripRecording,
        Feature.hapticEcoCoach,
      });

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(hapticEcoCoachEnabledProvider),
        isTrue,
        reason:
            'The shim must surface the central provider state — a '
            'persisted-true in the central feature-flags repository is '
            'the source of truth post-#1373 phase 3a.',
      );
    });

    test('set(true) enables hapticEcoCoach in the central provider', () async {
      // Prerequisite must be on first or the central provider would
      // throw StateError (which the shim swallows). Seed it.
      await repo.saveEnabled(<Feature>{Feature.obd2TripRecording});

      final container = makeContainer();
      await pumpLoad(container);

      // Materialise so the read after `set` walks the in-memory state
      // path rather than re-running build.
      container.read(hapticEcoCoachEnabledProvider);
      await container
          .read(hapticEcoCoachEnabledProvider.notifier)
          .set(true);

      expect(
        container.read(featureFlagsProvider),
        contains(Feature.hapticEcoCoach),
        reason:
            'set(true) must route through featureFlagsProvider.enable so '
            'the central state is the single source of truth — the legacy '
            'settings key is no longer the authoritative store.',
      );
      expect(
        container.read(hapticEcoCoachEnabledProvider),
        isTrue,
        reason:
            'The shim state must reflect the central enable immediately so '
            'the lifecycle provider spins up the coach without waiting for '
            'the next provider invalidation.',
      );
    });

    test('set(false) disables hapticEcoCoach in the central provider',
        () async {
      // Seed both on so we can flip hapticEcoCoach off.
      await repo.saveEnabled(<Feature>{
        Feature.obd2TripRecording,
        Feature.hapticEcoCoach,
      });

      final container = makeContainer();
      await pumpLoad(container);

      container.read(hapticEcoCoachEnabledProvider);
      await container
          .read(hapticEcoCoachEnabledProvider.notifier)
          .set(false);

      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.hapticEcoCoach)),
      );
      expect(container.read(hapticEcoCoachEnabledProvider), isFalse);
    });

    test('set(true) is a no-op when prerequisite is missing — does NOT throw',
        () async {
      // Prerequisite obd2TripRecording is OFF. Calling enable on the
      // central provider would throw StateError; the shim must swallow
      // it and leave the toggle at its prior state.
      final container = makeContainer();
      await pumpLoad(container);

      // No throw expected.
      await container
          .read(hapticEcoCoachEnabledProvider.notifier)
          .set(true);

      expect(
        container.read(hapticEcoCoachEnabledProvider),
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
        isNot(contains(Feature.hapticEcoCoach)),
      );
    });
  });

  group('hapticEcoCoachLifecycleProvider.coachEvents (#1273)', () {
    test('emits no events when the toggle is OFF — even with an active trip',
        () async {
      final tripRecording = _ManualTripRecording();

      final container = ProviderContainer(overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repo),
        tripRecordingProvider.overrideWith(() => tripRecording),
      ]);
      addTearDown(container.dispose);
      await pumpLoad(container);

      // Materialise the lifecycle provider so its `build` runs and the
      // (empty, gated) bridge is created.
      container.read(hapticEcoCoachLifecycleProvider);
      final lifecycle =
          container.read(hapticEcoCoachLifecycleProvider.notifier);
      final received = <CoachEvent>[];
      final sub = lifecycle.coachEvents.listen(received.add);
      addTearDown(sub.cancel);

      // Activate the trip — emission still gated by the toggle.
      tripRecording.setActive(_recordingState());
      // Yield so any pending stream events propagate before we assert.
      await Future<void>.delayed(Duration.zero);

      expect(
        received,
        isEmpty,
        reason:
            'Toggle OFF must gate the emission path even when a trip is '
            'active — the visual surface only fires when the user opted '
            'in via the haptic-eco-coach toggle.',
      );
    });

    test('exposes a non-null broadcast stream so multiple subscribers can '
        'attach', () async {
      // The contract: `coachEvents` is a broadcast stream — the
      // recording screen subscribes once, but a multi-subscriber
      // shape future-proofs us for an additional surface (e.g.
      // an in-app diagnostics overlay) without redesign.
      final tripRecording = _ManualTripRecording();
      final container = ProviderContainer(overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repo),
        tripRecordingProvider.overrideWith(() => tripRecording),
      ]);
      addTearDown(container.dispose);
      await pumpLoad(container);

      container.read(hapticEcoCoachLifecycleProvider);
      final lifecycle =
          container.read(hapticEcoCoachLifecycleProvider.notifier);
      final stream = lifecycle.coachEvents;
      expect(stream.isBroadcast, isTrue,
          reason:
              'coachEvents must be a broadcast stream — single-subscription '
              'streams would break multi-surface fan-out.');

      // Verify two listeners can attach without throwing.
      final a = stream.listen((_) {});
      final b = stream.listen((_) {});
      addTearDown(a.cancel);
      addTearDown(b.cancel);
    });
  });
}

/// Manual `TripRecording` fake that lets the test flip phases without
/// any OBD2 / Hive dependency. Only what the lifecycle provider's
/// `build` reads (`isActive`, `live`) is exercised; the rest of the
/// surface is deliberately untouched.
class _ManualTripRecording extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState();

  void setActive(TripRecordingState s) {
    state = s;
  }
}

TripRecordingState _recordingState() {
  return const TripRecordingState(
    phase: TripRecordingPhase.recording,
    situation: DrivingSituation.highwayCruise,
    band: ConsumptionBand.normal,
    live: TripLiveReading(
      throttlePercent: 80,
      speedKmh: 110,
      distanceKmSoFar: 0,
      elapsed: Duration(seconds: 1),
    ),
  );
}
