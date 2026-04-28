import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../consumption/data/obd2/trip_live_reading.dart';
import '../../consumption/providers/trip_recording_provider.dart';
import '../coach_event.dart';
import '../haptic_eco_coach.dart';

part 'haptic_eco_coach_provider.g.dart';

/// Test seam: tests can override [debugCoachClock] to inject a
/// hand-cranked clock into the [HapticEcoCoach] the lifecycle
/// provider builds, so the rolling-window timing can be verified
/// without burning 5 s of wall time per case. Production never
/// sets this — `null` keeps `DateTime.now` as the default.
@visibleForTesting
DateTime Function()? debugCoachClock;

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

  /// Broadcast sink for [CoachEvent]s emitted by the underlying
  /// [HapticEcoCoach] (#1273). Owned by the lifecycle so it shares
  /// the same lifetime as the haptic subscription — when the toggle
  /// flips off or the trip ends, this controller is closed and the
  /// UI's `Stream<CoachEvent>` subscription wakes up to a `done`
  /// event. Re-created on the next `build` if both gates pass again.
  ///
  /// Broadcast (not single-subscriber) so multiple widgets — the
  /// recording screen's SnackBar today, a future debug overlay
  /// tomorrow — can listen without the first subscriber starving the
  /// rest. Late subscribers don't see past events; that matches the
  /// "show a transient SnackBar on the live reading" semantics.
  StreamController<CoachEvent>? _coachEvents;

  @override
  void build() {
    final enabled = ref.watch(hapticEcoCoachEnabledProvider);
    // We do NOT `watch` the trip provider here — its state mutates on
    // every live-reading tick (5 Hz), which would tear down + rebuild
    // the rolling window on every sample and the heuristic could
    // never accumulate the 5 s burst it needs. Instead we read the
    // initial `isActive` snapshot and `ref.listen` on subsequent
    // transitions to spin the coach up / down without re-running
    // `build`.
    final tripState = ref.read(tripRecordingProvider);
    final isActive = tripState.isActive;

    // Tear down any previous subscription on every rebuild — Riverpod
    // re-runs `build` when the enabled-toggle flips, so we always
    // start from a clean slate before deciding whether to spin up a
    // fresh coach. Trip-active transitions are handled inline below
    // via `ref.listen`.
    _teardown();

    if (!enabled) {
      // Even with the coach disabled, listen for a future re-enable
      // — but the simpler path is the user re-toggles the setting
      // which invalidates this provider. Nothing to listen for here.
      return;
    }
    if (!isActive) {
      // Toggle is on but no trip yet. Listen for the trip to become
      // active so we can spin the coach up without waiting for the
      // user to flip the toggle a second time.
      ref.listen(tripRecordingProvider, (prev, next) {
        if (next.isActive && (prev?.isActive ?? false) == false) {
          // Self-invalidate so `build` re-runs and walks the
          // active path below. Cheaper than reaching into
          // private state from the listener.
          ref.invalidateSelf();
        }
      });
      return;
    }

    // Closed in `_teardown` (called from ref.onDispose and from the
    // next `build` re-run before any new controller is opened).
    // ignore: close_sinks
    final bridge = StreamController<TripLiveReading>.broadcast();
    _bridge = bridge;
    // ignore: close_sinks — closed in `_teardown`.
    final events = StreamController<CoachEvent>.broadcast();
    _coachEvents = events;
    final coach = HapticEcoCoach(
      readings: bridge.stream,
      clock: debugCoachClock,
      onCoach: (event) {
        if (events.isClosed) return;
        events.add(event);
      },
    );
    _coachSub = coach.start();

    // Forward state updates into the bridge. `ref.listen` fires once
    // per state change; we only push the `live` reading when it
    // actually changed, so a phase-only flip (paused → recording)
    // doesn't replay the previous reading. Also self-invalidate on
    // an active→inactive transition so the coach + bridge are torn
    // down promptly when the trip stops.
    ref.listen(tripRecordingProvider, (prev, next) {
      if ((prev?.isActive ?? false) && !next.isActive) {
        ref.invalidateSelf();
        return;
      }
      final reading = next.live;
      if (reading == null) return;
      if (identical(reading, _lastForwardedReading)) return;
      _lastForwardedReading = reading;
      bridge.add(reading);
    });

    ref.onDispose(_teardown);
  }

  /// Stream of fire decisions emitted by the underlying coach (#1273).
  /// Returns an empty stream while the coach is down (toggle off or
  /// no active trip) so callers can subscribe unconditionally — no
  /// branching on `enabled` at the call site.
  Stream<CoachEvent> get events =>
      _coachEvents?.stream ?? const Stream<CoachEvent>.empty();

  void _teardown() {
    _coachSub?.cancel();
    _coachSub = null;
    _bridge?.close();
    _bridge = null;
    _coachEvents?.close();
    _coachEvents = null;
    _lastForwardedReading = null;
  }
}

/// UI-facing broadcast stream of [CoachEvent]s from the lifecycle
/// provider (#1273). Subscribers (the visual SnackBar on
/// [TripRecordingScreen]) read this rather than poking at the
/// [HapticEcoCoachLifecycle] notifier directly — it stays a stream
/// even while the coach is down, so the subscription site doesn't
/// branch on enabled/active.
@Riverpod(keepAlive: true)
Stream<CoachEvent> coachEvents(Ref ref) {
  // Watching the lifecycle ensures the stream is rebuilt when the
  // underlying broadcast controller is recreated (toggle flip or
  // trip-active flip). Without this watch, the first subscriber
  // would grab a stale reference to the original empty stream.
  ref.watch(hapticEcoCoachLifecycleProvider);
  return ref.read(hapticEcoCoachLifecycleProvider.notifier).events;
}
