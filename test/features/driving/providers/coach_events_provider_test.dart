import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/driving/coach_event.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';

/// Hand-cranked clock the coach uses inside [HapticEcoCoachLifecycle]
/// when injected via [debugCoachClock]. Tests advance it explicitly
/// alongside each pushed reading so the heuristic's rolling window
/// resolves in microseconds-of-wall-time instead of waiting on real
/// timers.
class _Clock {
  _Clock(this._now);
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// #1273 — coach events are surfaced through a UI-facing
/// [Stream<CoachEvent>] so the trip-recording screen can show a
/// SnackBar on the same fire decision the haptic vibrates on. The
/// stream MUST honour the same gates as the haptic:
///
///   * Toggle off → no events emitted, ever.
///   * Toggle on but no active trip → still no events (lifecycle's
///     bridge is down, nothing reaches the heuristic).
///   * Toggle on + active trip → events arrive on every heuristic
///     match, sharing the haptic's 30 s cooldown.
///
/// We exercise the lifecycle provider directly with a manually
/// driven [TripRecording] notifier so the tests don't need a real
/// OBD2 stack — pushing a `TripLiveReading` into the trip state is
/// enough to drive the bridge → coach → onCoach path.

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

/// Synthetic [TripRecording] that lets tests push readings directly
/// into the state. The real [TripRecording.start] hammers the OBD2
/// stack — we only need the `live` field to flow through.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState initial;
  _FakeTripRecording({required this.initial});

  @override
  TripRecordingState build() => initial;

  /// Push a fresh live reading. The lifecycle provider's `ref.listen`
  /// fires per state change and forwards `next.live` into the bridge,
  /// so each `pushReading` call lands in the heuristic.
  void pushReading(TripLiveReading reading) {
    state = state.copyWith(live: reading);
  }

  void setActive() {
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  void setIdle() {
    state = state.copyWith(phase: TripRecordingPhase.idle);
  }
}

const TripRecordingState _activeState = TripRecordingState(
  phase: TripRecordingPhase.recording,
  situation: DrivingSituation.highwayCruise,
  band: ConsumptionBand.normal,
);

const TripRecordingState _idleState = TripRecordingState(
  phase: TripRecordingPhase.idle,
  situation: DrivingSituation.idle,
  band: ConsumptionBand.normal,
);

/// Push the canonical 6 s sustained-stab burst onto the trip state.
/// Mirrors the helper in `haptic_eco_coach_test.dart` but operates
/// through the live state instead of `debugFeed` — the lifecycle
/// provider's bridge is what we want to exercise. Advances [clock]
/// in lock-step so the heuristic's rolling window resolves
/// deterministically without waiting on real timers.
Future<void> _pushSustainedStabBurst(
  _FakeTripRecording notifier,
  _Clock clock,
) async {
  // 30 readings @ 200 ms = 6 s. Throttle 80 %, speed steady at 110.
  for (var i = 0; i < 30; i++) {
    notifier.pushReading(TripLiveReading(
      throttlePercent: 80.0,
      speedKmh: 110.0,
      distanceKmSoFar: 0,
      elapsed: Duration(milliseconds: 200 * i),
    ));
    clock.advance(const Duration(milliseconds: 200));
    // Yield so the lifecycle provider's `ref.listen` callback fires
    // before the next state mutation — without this the listener
    // batches updates and the heuristic only sees the last reading.
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // Bind the test framework so [HapticFeedback.mediumImpact] resolves
  // to the test platform channel (silently no-op) instead of crashing
  // with a missing-binding assertion. Without this the coach's
  // default haptic call throws and the error spills through
  // [errorLogger], which in turn needs Hive — none of which we want
  // to wire into this provider-only test.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('coachEventsProvider (#1273)', () {
    late _Clock clock;

    setUp(() {
      clock = _Clock(DateTime(2026, 1, 1, 12, 0, 0));
      debugCoachClock = clock.now;
    });

    tearDown(() {
      debugCoachClock = null;
    });

    test('toggle ON + active trip → emits an event on a sustained stab',
        () async {
      final settings = _FakeSettingsStorage()
        ..data[StorageKeys.hapticEcoCoachEnabled] = true;
      final tripNotifier = _FakeTripRecording(initial: _activeState);
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(settings),
        tripRecordingProvider.overrideWith(() => tripNotifier),
      ]);
      addTearDown(container.dispose);

      // Materialise the lifecycle so its bridge + onCoach are wired.
      container.read(hapticEcoCoachLifecycleProvider);

      final received = <CoachEvent>[];
      final sub = container.listen<AsyncValue<CoachEvent>>(
        coachEventsProvider,
        (prev, next) {
          final value = next.value;
          if (value != null) received.add(value);
        },
        fireImmediately: false,
      );
      addTearDown(sub.close);

      await _pushSustainedStabBurst(tripNotifier, clock);
      // One last yield so the broadcast controller's add reaches the
      // listenManual callback.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        received,
        hasLength(1),
        reason:
            'A 6 s sustained-high-throttle window with the toggle on '
            'and a live trip must surface exactly one CoachEvent on '
            'the UI-facing stream.',
      );
    });

    test('toggle OFF → no events even on a sustained stab', () async {
      final settings = _FakeSettingsStorage();
      // Default-OFF: no `hapticEcoCoachEnabled` key.
      final tripNotifier = _FakeTripRecording(initial: _activeState);
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(settings),
        tripRecordingProvider.overrideWith(() => tripNotifier),
      ]);
      addTearDown(container.dispose);

      container.read(hapticEcoCoachLifecycleProvider);

      final received = <CoachEvent>[];
      final sub = container.listen<AsyncValue<CoachEvent>>(
        coachEventsProvider,
        (prev, next) {
          final value = next.value;
          if (value != null) received.add(value);
        },
      );
      addTearDown(sub.close);

      await _pushSustainedStabBurst(tripNotifier, clock);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        received,
        isEmpty,
        reason:
            'When the eco-coach toggle is off, the lifecycle provider '
            'must not spin up the bridge at all — no CoachEvents on '
            'the UI stream regardless of what the trip is doing.',
      );
    });

    test('toggle ON but no active trip → no events', () async {
      final settings = _FakeSettingsStorage()
        ..data[StorageKeys.hapticEcoCoachEnabled] = true;
      final tripNotifier = _FakeTripRecording(initial: _idleState);
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(settings),
        tripRecordingProvider.overrideWith(() => tripNotifier),
      ]);
      addTearDown(container.dispose);

      container.read(hapticEcoCoachLifecycleProvider);

      final received = <CoachEvent>[];
      final sub = container.listen<AsyncValue<CoachEvent>>(
        coachEventsProvider,
        (prev, next) {
          final value = next.value;
          if (value != null) received.add(value);
        },
      );
      addTearDown(sub.close);

      // Push readings even though the trip is idle — the lifecycle
      // provider's `isActive` gate must keep them out.
      await _pushSustainedStabBurst(tripNotifier, clock);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        received,
        isEmpty,
        reason:
            'Without an active trip, the lifecycle provider tears the '
            'bridge down — no CoachEvents reach UI subscribers.',
      );
    });
  });
}
