// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/event_channel_cancel.dart';

part 'geolocator_wrapper.g.dart';

/// Wraps Geolocator's static methods for testability.
///
/// All permission and location calls go through this provider instead of
/// calling Geolocator.checkPermission() etc. directly, so tests can
/// override the provider with a fake implementation.
@Riverpod(keepAlive: true)
GeolocatorWrapper geolocatorWrapper(Ref ref) {
  return GeolocatorWrapper();
}

class GeolocatorWrapper {
  /// When the app is built with `--dart-define=FORCE_LOCATION_MANAGER=true`
  /// (the F-Droid / GMS-free flavor, #2574), every location request is routed
  /// through Android's legacy [LocationManager] instead of the Play-Services
  /// `FusedLocationProviderClient`.
  ///
  /// The fdroid flavor excludes `com.google.android.gms` from the runtime
  /// classpath, so the fused provider class is simply absent. geolocator_android
  /// already falls back to the LocationManager when GMS is missing, but we set
  /// [AndroidSettings.forceLocationManager] explicitly so the behaviour is
  /// deterministic and does not depend on a runtime class-presence probe.
  ///
  /// Centralising the wrapping HERE keeps all four call sites
  /// (location_service.dart, movement_detection_provider.dart,
  /// approach_state_provider.dart, trip_gps_stream_controller.dart) free of any
  /// flavor branching — they keep passing a plain [LocationSettings].
  static const bool forceLocationManager =
      bool.fromEnvironment('FORCE_LOCATION_MANAGER');

  /// Copies the cross-platform fields of [settings] into an [AndroidSettings]
  /// with `forceLocationManager: true` when [forceLocationManager] is set;
  /// otherwise returns [settings] unchanged. A null in stays null out.
  static LocationSettings? _withForcedLocationManager(
    LocationSettings? settings,
  ) {
    if (!forceLocationManager) return settings;
    // Already an Android-specific settings object: respect its choice but
    // guarantee the LocationManager is forced in the GMS-free flavor.
    if (settings is AndroidSettings) {
      return AndroidSettings(
        forceLocationManager: true,
        accuracy: settings.accuracy,
        distanceFilter: settings.distanceFilter,
        intervalDuration: settings.intervalDuration,
        timeLimit: settings.timeLimit,
        foregroundNotificationConfig: settings.foregroundNotificationConfig,
        useMSLAltitude: settings.useMSLAltitude,
      );
    }
    return AndroidSettings(
      forceLocationManager: true,
      accuracy: settings?.accuracy ?? LocationAccuracy.best,
      distanceFilter: settings?.distanceFilter ?? 0,
      timeLimit: settings?.timeLimit,
    );
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getCurrentPosition(
      locationSettings: _withForcedLocationManager(locationSettings),
    );
  }

  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Returns a stream of position updates for continuous location tracking.
  ///
  /// Used by movement detection in driving mode. This is the bare
  /// per-call stream: every listener opens its OWN underlying
  /// `Geolocator.getPositionStream()` subscription. Non-trip callers
  /// (movement detection) want exactly that — they never run concurrently
  /// with a trip-recording consumer. Trip consumers must use
  /// [sharedPositionStream] instead (#2646).
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _withForcedLocationManager(locationSettings),
    );
  }

  /// #2646 — a single, refcounted, broadcast position source shared by all
  /// *trip* consumers (the GPS-only recorder and the live [ApproachDetector]).
  ///
  /// ## Why this exists
  ///
  /// `Geolocator.getPositionStream()` is backed by a single platform
  /// EventChannel (`flutter.baseflow.com/geolocator_updates_android`, see
  /// movement_detection_provider.dart). Two independent listeners contend on
  /// that one channel's onListen / onCancel lifecycle, and in GPS-only
  /// recording the recorder + the detector each opened a fresh
  /// [getPositionStream] in the SAME frame — the recorder won the channel and
  /// the detector was starved of fixes, so it never left `ApproachIdle`, the
  /// radar candidate list stayed empty, and swipe was a no-op.
  ///
  /// Routing both trip consumers through ONE underlying subscription,
  /// multiplexed via a broadcast controller, removes the race: every
  /// listener receives every fix the others receive.
  ///
  /// ## Lifecycle (refcounted)
  ///
  /// The underlying platform subscription opens lazily on the FIRST listener
  /// and is cancelled on the LAST — so the app only requests fixes while at
  /// least one trip consumer is active, preserving the battery cost-bound the
  /// per-consumer path had. The latest fix is replayed to late joiners so a
  /// detector that subscribes a frame after the recorder still leaves
  /// `ApproachIdle` on the most recent fix instead of waiting for the next.
  ///
  /// [recording] marks the caller as the trip recorder, whose fine,
  /// foreground-service-promoted [locationSettings] must win the cadence on
  /// the shared upstream (#2766). The underlying platform stream is opened
  /// with the most recent recording subscriber's settings if one is present,
  /// regardless of subscription order — so even when the live
  /// [ApproachDetector] opens the channel first with its coarse settings,
  /// the recorder's join re-opens the upstream at the fine ~1 s cadence.
  /// Non-recording consumers (the detector) join with whatever settings the
  /// upstream is already running.
  Stream<Position> sharedPositionStream({
    LocationSettings? locationSettings,
    bool recording = false,
  }) {
    final source = _shared ??= _SharedPositionSource(
      // Route through [getPositionStream] (not Geolocator directly) so the
      // single override seam tests already use stays intact and the
      // forceLocationManager wrapping (#2574) is applied in exactly one place.
      open: (settings) => getPositionStream(locationSettings: settings),
    );
    return source.subscribe(
      locationSettings: locationSettings,
      recording: recording,
    );
  }

  _SharedPositionSource? _shared;
}

/// Refcounted broadcast multiplexer over a single underlying position
/// stream (#2646). Owns the one platform subscription: opens it on the first
/// listener, cancels it on the last, and replays the latest fix to late
/// joiners. Constructed lazily by [GeolocatorWrapper.sharedPositionStream].
class _SharedPositionSource {
  _SharedPositionSource({
    required Stream<Position> Function(LocationSettings? settings) open,
  }) : _open = open;

  final Stream<Position> Function(LocationSettings? settings) _open;
  // The shared bus lives for the wrapper's (keepAlive, app-lifetime)
  // lifetime — it is reused across trips so the underlying platform
  // subscription can re-open on the next first-listener without rebuilding
  // the multiplexer. The underlying subscription it forwards IS torn down on
  // the last listener (refcount → 0); the controller itself never needs
  // closing.
  // ignore: close_sinks
  final StreamController<Position> _out = StreamController<Position>.broadcast();
  // The single underlying platform subscription. Cancelled in [_release]
  // when the last consumer leaves (refcount → 0).
  // ignore: cancel_subscriptions
  StreamSubscription<Position>? _upstream;
  Position? _last;
  int _refCount = 0;
  // The settings the live [_upstream] was opened with, and the recorder's
  // fine settings to prefer (#2766). The recorder marks itself `recording`,
  // and we always (re)open the upstream with `_recordingSettings` when one is
  // present — so the fine ~1 s cadence wins regardless of who opened the
  // channel first.
  LocationSettings? _activeSettings;
  LocationSettings? _recordingSettings;
  int _recordingRefCount = 0;

  /// Hand a consumer a stream that seeds the latest fix (if any) then
  /// forwards every subsequent fix from the shared broadcast. Opening the
  /// underlying subscription on the first consumer and cancelling on the last
  /// is driven off the refcount kept here rather than the broadcast
  /// controller's own onListen / onCancel, so the seeded late-join replay
  /// does not perturb the refcount.
  Stream<Position> subscribe({
    LocationSettings? locationSettings,
    bool recording = false,
  }) {
    // Per-consumer controller. Closed in its own `onCancel` once the
    // consumer detaches, so there is no leak.
    // ignore: close_sinks
    late final StreamController<Position> ctl;
    StreamSubscription<Position>? relay;
    ctl = StreamController<Position>(
      onListen: () {
        _retain(locationSettings: locationSettings, recording: recording);
        // Replay the most recent fix so a late joiner (e.g. the detector
        // subscribing a frame after the recorder) acts on it immediately.
        final last = _last;
        if (last != null && !ctl.isClosed) ctl.add(last);
        relay = _out.stream.listen(
          (p) {
            if (!ctl.isClosed) ctl.add(p);
          },
          onError: (Object e, StackTrace st) {
            if (!ctl.isClosed) ctl.addError(e, st);
          },
        );
      },
      onCancel: () async {
        await relay?.cancel();
        relay = null;
        await _release(recording: recording);
        if (!ctl.isClosed) await ctl.close();
      },
    );
    return ctl.stream;
  }

  void _retain({
    required LocationSettings? locationSettings,
    required bool recording,
  }) {
    _refCount++;
    if (recording) {
      _recordingRefCount++;
      _recordingSettings = locationSettings;
    }
    // The effective settings: the recorder's fine settings always win while a
    // recording consumer is present; otherwise the joining consumer's.
    final wanted = _recordingRefCount > 0 ? _recordingSettings : locationSettings;
    if (_refCount == 1) {
      _openUpstream(wanted);
      return;
    }
    // Already open. If a recording consumer just joined a channel that was
    // opened with coarser (non-recording) settings, re-open it at the fine
    // cadence so the recorder's cadence wins even when the detector opened
    // first (#2766). Identity compare is enough: the same settings object is
    // never re-passed, and re-opening on every coarse join is harmless but
    // unwanted, so we gate strictly on the recorder arriving.
    if (recording && !identical(_activeSettings, wanted)) {
      _reopenUpstream(wanted);
    }
  }

  void _openUpstream(LocationSettings? settings) {
    _activeSettings = settings;
    // Cancelled in [_release] when the refcount falls back to 0, or replaced
    // by [_reopenUpstream] when the recorder upgrades the cadence.
    _upstream = _open(settings).listen(
      (p) {
        _last = p;
        if (!_out.isClosed) _out.add(p);
      },
      onError: (Object e, StackTrace st) {
        if (!_out.isClosed) _out.addError(e, st);
      },
    );
  }

  void _reopenUpstream(LocationSettings? settings) {
    final old = _upstream;
    _upstream = null;
    _openUpstream(settings);
    // Cancel the superseded coarse subscription after the fine one is live so
    // there is no gap in fixes; the broadcast bus + `_last` replay bridge it.
    //
    // #3249 — KNOWN LIMITATION (verified against geolocator 14.0.2): opening
    // the new stream BEFORE cancelling the old means geolocator_android can
    // hand back its CACHED first-caller stream (the coarse one), so the
    // "recorder cadence wins on a late join" guarantee above is not reliable
    // when a coarse consumer opened the channel first. The correct fix is
    // cancel-THEN-reopen (accepting a brief fix gap that `_last` replay
    // bridges), but it changes the live GPS continuity of every trip and so
    // needs on-device validation before shipping — deliberately deferred (the
    // #3249 primary fix routes the recorder to `recording: true`, which wins
    // when it opens the channel first, the common case).
    unawaited(old?.safeCancel());
  }

  Future<void> _release({required bool recording}) async {
    if (_refCount == 0) return;
    _refCount--;
    if (recording && _recordingRefCount > 0) {
      _recordingRefCount--;
      if (_recordingRefCount == 0) _recordingSettings = null;
    }
    if (_refCount == 0) {
      final up = _upstream;
      _upstream = null;
      _last = null;
      _activeSettings = null;
      await up?.safeCancel();
    }
  }
}
