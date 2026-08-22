// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_provider.dart';

/// #3760 — the [TripRecording] notifier's collaborator + bookkeeping
/// fields and its small read helpers, split out of
/// `trip_recording_provider.dart` as a `part` mixin (move-only,
/// behaviour preserved). Constrained `on _$TripRecording` so the
/// `late` collaborator initializers keep capturing `ref`; `part`-file
/// privacy is library-level, so every private member stays reachable
/// from the sibling mixins and the host adapter.
mixin _TripRecordingCore on _$TripRecording {
  // #1932 — re-entrancy guard for [start]. `state` is only marked
  // active by the last line of `start()`, but `start()` has `await`s
  // before that, so a second start racing in the window between would
  // pass the `state.isActive` guard and orphan a controller. This flag
  // is set synchronously at the top of `start()` — before any await —
  // so the second call is rejected.
  bool _startInProgress = false;

  // #2190 / #2227 — the selected recording strategy. Both modes now run
  // a [RecordingPipeline]: `start(service)` installs an
  // [Obd2RecordingPipeline], the dongle-less #2025 flow installs a
  // [GpsOnlyRecordingPipeline]. The historical `_pipeline == null`
  // inline-OBD2 branch is gone — every lifecycle boundary dispatches
  // through `_pipeline`. A future third source (CarPlay / Android Auto
  // telemetry) becomes another implementation rather than another
  // `_xMode` bool (open/closed — the #2190 motivation). Null only
  // between trips and in the cold-start-recovered state (#1347), where
  // the WAL snapshot — not a live pipeline — is the source of truth.
  RecordingPipeline? _pipeline;

  /// The active OBD2 pipeline, or null when no trip is running, a
  /// GPS-only trip is running, or we're in the recovered-no-controller
  /// state. The notifier's WAL snapshot helpers, `pause` / `resume`, and
  /// `debugController` reach the live [TripRecordingController] through
  /// it (#2227).
  Obd2RecordingPipeline? get _obd2 {
    final p = _pipeline;
    return p is Obd2RecordingPipeline ? p : null;
  }

  // #1458 phase 2 — most recent app lifecycle state observed by the
  // wiring layer's [WidgetsBindingObserver]. Read by the GPS stream
  // listener every time a position fix arrives so the resulting
  // [GpsSampleDiagnostic] carries an accurate "was the phone awake?"
  // tag. Defaults to `resumed` so the very first sample on a freshly
  // started recording (where no lifecycle event has fired yet) is
  // tagged optimistically — the user just tapped Start, the app is
  // certainly foreground.
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  // #3465 — rolling foreground/background transition buffer, windowed to
  // the trip at save time so the GPS coverage report can attribute track
  // gaps. Fed from [onAppLifecycleStateChanged]; covers BOTH pipelines.
  final RecordingLifecycleMarksRecorder _lifecycleMarks =
      RecordingLifecycleMarksRecorder();

  /// #767 band-transition haptics, extracted into a focused
  /// collaborator (#1679). Constructed once and reused across
  /// recordings so the test counters accumulate exactly as the
  /// inlined fields did.
  final TripHapticController _haptics = TripHapticController();

  /// #1374 / #1125 / #1458 GPS concern — the opt-in Geolocator
  /// position stream, the per-fix cadence diagnostics, and the
  /// glide-coach evaluation hook — extracted into a focused
  /// collaborator (#1679). `late` so it can capture [ref] and the
  /// [_lifecycleState] getter.
  late final TripGpsStreamController _gps = TripGpsStreamController(
    ref: ref,
    lifecycleState: () => _lifecycleState,
  );

  /// #769 / #780 / #894 baseline-learning concern — the per-trip
  /// situation classifier, the learned-baseline store, and the
  /// classify → record → band → delta pipeline — extracted into a
  /// focused collaborator (#1679). `late` so it can capture [ref].
  late final TripBaselineRecorder _baselines = TripBaselineRecorder(ref);

  /// #1615 experimental OEM-PID exact-fuel-level concern — the slow
  /// poll that reads exact litres-in-tank via the OEM-PID registry and
  /// pushes them into the controller's fuel sampler. Inert unless the
  /// `experimentalOemPids` flag is on (the provider reads the flag and
  /// passes it to [TripOemFuelLevelController.start]) AND the connected
  /// adapter is OEM-PID-capable.
  final TripOemFuelLevelController _oemFuel = TripOemFuelLevelController();

  /// Tests count haptic fires via these instead of hooking the
  /// platform channel. The production path also still calls
  /// [HapticFeedback], so counting here doesn't short-circuit the
  /// real vibration on a device.
  @visibleForTesting
  int get hapticLightCount => _haptics.lightCount;
  @visibleForTesting
  int get hapticMediumCount => _haptics.mediumCount;

  /// Exposed for tests: the underlying [TripRecordingController] while
  /// a trip is active. Lets the #1040 sample-persistence test inject a
  /// deterministic buffer through [TripRecordingController.debugCaptureSample]
  /// without spinning up a real polling clock. Null between trips.
  @visibleForTesting
  TripRecordingController? get debugController => _obd2?.controller;

  /// Exposed for tests (#2190): true when an alternate GPS-only
  /// [RecordingPipeline] is the selected strategy (i.e. the trip was
  /// started via [startGpsOnly]), false for the inline OBD2 path or when
  /// no trip is running. Lets the strategy-selection test assert which
  /// pipeline the notifier picked without depending on the concrete type.
  @visibleForTesting
  bool get debugIsGpsOnlyActive => _pipeline?.isGpsOnly ?? false;

  /// Snapshot of the vehicle the last [startTrip] call was scoped to.
  /// Exposed so the save-as-fill-up path can figure out which
  /// trajets to auto-link (#888). Null before the first call, or
  /// after a [reset] / fresh [build].
  String? _lastTripVehicleId;
  DateTime? _lastTripStartedAt;
  // #3251 — the live trip's auto-record provenance, so the WAL seed stamps it
  // (the recovery badge + saved entry then know it was hands-free).
  bool _lastTripAutomatic = false;

  /// Most recent vehicle id this provider kicked a trip for.
  ///
  /// Readable by the consumption providers so the fill-up auto-link
  /// can filter trajets to the vehicle that was actually driven —
  /// decoupling the trajets flow from the fill-up flow (#888).
  String? get lastTripVehicleId => _lastTripVehicleId;

  /// Timestamp captured on the most recent [startTrip] call. Used by
  /// the auto-link window in the fill-up flow as a "latest-known
  /// driving activity" lower bound when no prior fill-up exists.
  DateTime? get lastTripStartedAt => _lastTripStartedAt;

  /// Read the active vehicle profile, swallowing provider-wiring errors
  /// (widget tests without the vehicle graph) — delegates to the shared
  /// [tryReadActiveVehicleProfile] guard (#3437). Null means "no vehicle";
  /// the [Obd2RecordingPipeline] falls back to its generic fuel defaults.
  VehicleProfile? _tryReadActiveVehicle() => tryReadActiveVehicleProfile(ref,
      where: 'TripRecording: active vehicle unavailable');

  /// #1615 — read the `experimentalOemPids` feature flag, swallowing
  /// any provider-wiring error the same way [_tryReadActiveVehicle]
  /// does. Widget tests that start a recording without overriding the
  /// feature-flags Riverpod graph then simply see the flag as off,
  /// which is the safe default (the OEM poll never arms).
  bool _readOemPidsFlag() {
    try {
      return ref
          .read(featureFlagsProvider.notifier)
          .isEnabled(Feature.experimentalOemPids);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording: feature flags unavailable'}));
      return false;
    }
  }

  /// #2459 — read the per-trip 'diagnostic capture' flag from
  /// `Feature.debugMode` (Developer mode). Not a user-facing consumption
  /// setting: it's the dev/diagnostics gate, so the raw mixture inputs
  /// are only persisted when a developer has explicitly enabled Developer
  /// mode. Swallows provider-wiring errors the same way [_readOemPidsFlag]
  /// does → safe default off.
  bool _readDiagnosticCaptureFlag() {
    try {
      return ref
          .read(featureFlagsProvider.notifier)
          .isEnabled(Feature.debugMode);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording: feature flags unavailable'}));
      return false;
    }
  }

  /// #1458 phase 2 — track every app-lifecycle transition so the GPS
  /// diagnostic recorder knows whether each fix arrived while the
  /// phone was foreground (`resumed`) or backgrounded (`paused` /
  /// `inactive` / `hidden`). Wired in from the same
  /// [WidgetsBindingObserver] that fires [onAppBackgrounded] so the
  /// two hooks stay in lock-step. Cheap (a single field write) so it's
  /// safe to fire on every transition regardless of recording state —
  /// reading [_lifecycleState] from the GPS stream listener is then a
  /// pure local read.
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    _lifecycleState = state;
    _lifecycleMarks.onLifecycleState(state); // #3465 — pure, never throws.
  }

  /// Exposed for tests — reads back the most recent lifecycle state
  /// pushed in via [onAppLifecycleStateChanged]. Lets a test verify
  /// that a diagnostic was tagged with the right state at the moment
  /// the GPS fix arrived without depending on platform-channel
  /// plumbing.
  @visibleForTesting
  AppLifecycleState get debugLifecycleState => _lifecycleState;
}
