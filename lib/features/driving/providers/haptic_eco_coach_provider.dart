import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../consumption/data/obd2/trip_live_reading.dart';
import '../../consumption/providers/trip_recording_provider.dart';
import '../haptic_eco_coach.dart';

part 'haptic_eco_coach_provider.g.dart';

/// Persisted opt-in switch for the real-time eco-coaching haptic
/// (#1122). Stored in the Hive `settings` box under
/// [StorageKeys.hapticEcoCoachEnabled]; defaults to **false** so the
/// haptic only fires for users who explicitly turned it on in the
/// settings screen. Lives for the app's lifetime — flipping the
/// toggle invalidates [hapticEcoCoachLifecycleProvider] so the
/// subscription is torn down or spun up immediately.
@Riverpod(keepAlive: true)
class HapticEcoCoachEnabled extends _$HapticEcoCoachEnabled {
  @override
  bool build() {
    final settings = ref.watch(settingsStorageProvider);
    return settings.getSetting(StorageKeys.hapticEcoCoachEnabled) == true;
  }

  /// Persist [value] and update the in-memory state. The lifecycle
  /// provider invalidates on any state flip, so a `set(true)` while a
  /// trip is recording starts the coach immediately, and a `set(false)`
  /// cancels its subscription on the next frame.
  Future<void> set(bool value) async {
    final settings = ref.read(settingsStorageProvider);
    await settings.putSetting(StorageKeys.hapticEcoCoachEnabled, value);
    state = value;
  }
}

/// Active subscription that bridges the trip-recording state stream
/// to a [HapticEcoCoach]. Held by Riverpod for the duration of an
/// active trip with the eco-coach setting enabled; cancelled when
/// either condition flips.
///
/// Implementation detail: the trip-recording provider exposes its
/// live readings only through its [TripRecordingState.live] field
/// (no public `Stream<TripLiveReading>` getter). We bridge that
/// state-change shape into a stream by feeding readings into a local
/// [StreamController], then hand the controller's stream to
/// [HapticEcoCoach]. This keeps the coach service stream-agnostic
/// (it can still be exercised in tests with a synthetic stream)
/// while avoiding any modification to the trip-recording controller's
/// public API.
///
/// `keepAlive: true` because we need it to survive widget rebuilds
/// while the user navigates around the app mid-trip — the trip
/// itself is `keepAlive`, so the haptic coach must be too.
@Riverpod(keepAlive: true)
class HapticEcoCoachLifecycle extends _$HapticEcoCoachLifecycle {
  StreamController<TripLiveReading>? _bridge;
  StreamSubscription<TripLiveReading>? _coachSub;
  TripLiveReading? _lastForwardedReading;

  /// Long-lived broadcast controller for [CoachEvent]s (#1273). Stays
  /// open for the app's lifetime — cleaning it up on `_teardown`
  /// would race the recording screen, which subscribes once in
  /// `initState` and unsubscribes in `dispose`. Multiple subscribers
  /// (haptic isn't one — that path is direct in [HapticEcoCoach]) can
  /// attach safely; today there's exactly one (the trip-recording
  /// screen).
  // ignore: close_sinks — broadcast lives for the app's lifetime; see
  //   the comment on [coachEvents] for why we don't close it on each
  //   trip teardown.
  final StreamController<CoachEvent> _coachEventsController =
      StreamController<CoachEvent>.broadcast();

  /// Public broadcast stream of fire decisions (#1273). The trip
  /// recording screen subscribes in `initState`, shows a SnackBar per
  /// event, and cancels in `dispose`. Other routes (summary, history,
  /// home) DO NOT subscribe — that's how we guarantee the visual
  /// surface only fires while the user is on the recording screen.
  Stream<CoachEvent> get coachEvents => _coachEventsController.stream;

  @override
  void build() {
    final enabled = ref.watch(hapticEcoCoachEnabledProvider);
    final tripState = ref.watch(tripRecordingProvider);

    // Tear down any previous subscription on every rebuild — Riverpod
    // re-runs `build` when either the enabled-toggle or the trip state
    // changes, so we always start from a clean slate before deciding
    // whether to spin up a fresh coach.
    _teardown();

    if (!enabled) return;
    if (!tripState.isActive) return;

    // Closed in `_teardown` (called from ref.onDispose and from the
    // next `build` re-run before any new controller is opened).
    // ignore: close_sinks
    final bridge = StreamController<TripLiveReading>.broadcast();
    _bridge = bridge;
    final coach = HapticEcoCoach(
      readings: bridge.stream,
      onFire: _emitCoachEvent,
    );
    _coachSub = coach.start();

    // Forward state updates into the bridge. `ref.listen` fires once
    // per state change; we only push the `live` reading when it
    // actually changed, so a phase-only flip (paused → recording)
    // doesn't replay the previous reading.
    ref.listen(tripRecordingProvider, (prev, next) {
      final reading = next.live;
      if (reading == null) return;
      if (identical(reading, _lastForwardedReading)) return;
      _lastForwardedReading = reading;
      bridge.add(reading);
    });

    ref.onDispose(() {
      _teardown();
      // The broadcast controller for coach events stays open across
      // trip-teardown / re-arm cycles — its lifecycle matches the
      // provider's `keepAlive: true`. We only close it if the
      // provider itself is being disposed permanently (e.g. test
      // ProviderContainer.dispose).
      if (!_coachEventsController.isClosed) {
        _coachEventsController.close();
      }
    });
  }

  void _emitCoachEvent(CoachEvent event) {
    if (_coachEventsController.isClosed) return;
    _coachEventsController.add(event);
  }

  void _teardown() {
    _coachSub?.cancel();
    _coachSub = null;
    _bridge?.close();
    _bridge = null;
    _lastForwardedReading = null;
  }
}
