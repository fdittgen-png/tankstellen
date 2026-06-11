// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
// #3153 — for the `.select` rebuild-slicing modifier (riverpod_annotation's
// internals export does not surface the extension).
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../obd2/api.dart';
import '../../consumption/providers/trip_recording_provider.dart';
import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';
import '../haptic_eco_coach.dart';

part 'haptic_eco_coach_provider.g.dart';

/// Persisted opt-in switch for the real-time eco-coaching haptic
/// (#1122). As of #1373 phase 3a this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.hapticEcoCoach]. The legacy
/// [StorageKeys.hapticEcoCoachEnabled] key is read once by the
/// `legacyToggleMigrationProvider` on first launch after upgrade and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// Lives for the app's lifetime — flipping the toggle invalidates
/// [hapticEcoCoachLifecycleProvider] so the subscription is torn down
/// or spun up immediately.
@Riverpod(keepAlive: true)
class HapticEcoCoachEnabled extends _$HapticEcoCoachEnabled
    with FeatureToggleNotifier {
  @override
  Feature get feature => Feature.hapticEcoCoach;

  /// When `obd2TripRecording` (the parent) is off, this surfaces as
  /// `false` regardless of the stored haptic-coach value (#1447); the
  /// lifecycle provider re-runs and tears down its subscription on the
  /// next frame. Build + `set` live in [FeatureToggleNotifier] (#3175).
  ///
  /// NOTE: #1608 had this shim's setter *surface* the dependency-
  /// violation StateError while every sibling swallowed it. #3175
  /// unifies all shims on the swallow variant (the safest — see the
  /// mixin doc); the #1608 guarantee that the violating enable never
  /// takes effect is unchanged, and the only call site (the
  /// driving-settings toggle) still pre-checks by disabling itself
  /// when the parent is off.
  @override
  bool build() => buildFromFeatureFlags();
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

  /// #3153 — test seam: the live bridge controller instance. Lets the
  /// churn regression test assert the coach + bridge are NOT torn down
  /// and recreated on every 4 Hz live-reading emit (only on an actual
  /// isActive / enabled flip). Null while no coach is armed.
  @visibleForTesting
  StreamController<TripLiveReading>? get debugBridge => _bridge;

  @override
  void build() {
    final enabled = ref.watch(hapticEcoCoachEnabledProvider);
    // #3153 — watch ONLY the isActive slice. The trip-recording provider
    // emits a full state ~4×/s while recording; watching the whole state
    // closed + recreated the bridge StreamController, the coach, and the
    // ref.listen forwarding on every emit. Live readings keep flowing
    // through the ref.listen below (listening doesn't rebuild).
    final tripActive =
        ref.watch(tripRecordingProvider.select((s) => s.isActive));

    // Tear down any previous subscription on every rebuild — Riverpod
    // re-runs `build` when either the enabled-toggle or the trip's
    // isActive slice changes, so we always start from a clean slate
    // before deciding whether to spin up a fresh coach.
    _teardown();

    if (!enabled) return;
    if (!tripActive) return;

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
        unawaited(_coachEventsController.close());
      }
    });
  }

  void _emitCoachEvent(CoachEvent event) {
    if (_coachEventsController.isClosed) return;
    _coachEventsController.add(event);
  }

  void _teardown() {
    unawaited(_coachSub?.cancel());
    _coachSub = null;
    unawaited(_bridge?.close());
    _bridge = null;
    _lastForwardedReading = null;
  }
}
