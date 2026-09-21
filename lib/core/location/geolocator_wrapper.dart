// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

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
///
/// TODO(#3476): location capability seam for the GMS-free F-Droid architecture
/// (epic #3473). `forceLocationManager` already routes the LIBRE build through
/// Android's LocationManager at runtime, but `geolocator_android`'s
/// `FusedLocationClient` still leaves compile-time `com.google.android.gms.*`
/// REFERENCES in the fdroid dex that `fdroid scanner` rejects. Plan (see
/// `.local-docs/fdroid-gms-free-refactor-notes.md`): vendor + patch
/// `geolocator_android` for the libre build, swapped in via a libre-only
/// `pubspec_overrides.yaml` — keeping this Dart API + all 11 call sites
/// unchanged. Refactor TODO: extract `_SharedPositionSource` to its own file
/// and split out a thin permissions seam.
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
  /// classpath, so the fused provider class is simply absent.
  /// geolocator_android already falls back to the LocationManager when GMS is
  /// missing, but we set [AndroidSettings.forceLocationManager] explicitly so
  /// the behaviour does not depend on a runtime class-presence probe.
  /// Centralising the wrapping HERE keeps the call sites (location_service,
  /// approach_state_provider, trip_gps_stream_controller) free of flavor
  /// branching — they keep passing a plain [LocationSettings].
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
  /// EventChannel (`flutter.baseflow.com/geolocator_updates_android`), and
  /// two independent listeners contend on that one channel's onListen /
  /// onCancel lifecycle: in GPS-only recording the recorder + the detector
  /// each opened a fresh [getPositionStream] in the SAME frame, the recorder
  /// won the channel, and the starved detector never left `ApproachIdle` —
  /// empty radar list, swipe a no-op. Routing both trip consumers through
  /// ONE underlying subscription, multiplexed via a broadcast controller,
  /// removes the race: every listener receives every fix.
  ///
  /// ## Lifecycle (refcounted)
  ///
  /// The platform subscription opens lazily on the FIRST listener and is
  /// cancelled on the LAST, preserving the per-consumer path's battery
  /// cost-bound. The latest fix is replayed to late joiners so a detector
  /// subscribing a frame after the recorder leaves `ApproachIdle` at once.
  ///
  /// [recording] marks the caller as the trip recorder, whose fine,
  /// foreground-service-promoted [locationSettings] must win the cadence on
  /// the shared upstream (#2766) regardless of subscription order — so even
  /// when the live [ApproachDetector] opens the channel first with its
  /// coarse settings, the recorder's join re-opens the upstream at the fine
  /// ~1 s cadence. Non-recording consumers join with whatever settings the
  /// upstream already runs, and one *leaving* never re-configures a live
  /// recording (#4353). That promotion is serialized and cancel-first (see
  /// [_SharedPositionSource._replaceUpstream]); whether it actually took
  /// effect is readable from [sharedPositionDiagnostics] — a request is not
  /// an application.
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

  /// #4353 — one atomic read of what the shared upstream was ASKED for, what
  /// is actually APPLIED, and whether a replacement is in flight. Distinct
  /// because a request is not an application: `requested != null &&
  /// effective == null` means the promotion failed (or the stream ended) and
  /// the recording runs on nothing; a mismatch with `inFlight: true` is
  /// mid-handover. The journal reports the APPLIED profile, only ever.
  ({LocationSettings? requested, LocationSettings? effective, bool inFlight})
      get sharedPositionDiagnostics => (
            requested: _shared?.requestedSettings,
            effective: _shared?.effectiveSettings,
            inFlight: _shared?.transitionInFlight ?? false,
          );

  _SharedPositionSource? _shared;
}

/// Refcounted broadcast multiplexer over a single underlying position
/// stream (#2646). Owns the one platform subscription: opens it on the first
/// listener, cancels it on the last, replays the latest fix to late joiners.
class _SharedPositionSource {
  _SharedPositionSource({
    required this._open,
  });

  final Stream<Position> Function(LocationSettings? settings) _open;
  // The shared bus lives for the wrapper's (keepAlive, app-lifetime)
  // lifetime — reused across trips so the platform subscription can re-open
  // on the next first-listener. The subscription it forwards IS torn down on
  // the last listener; the controller itself never needs closing.
  // ignore: close_sinks
  final StreamController<Position> _out = StreamController<Position>.broadcast();
  // The single underlying platform subscription.
  // ignore: cancel_subscriptions
  StreamSubscription<Position>? _upstream;
  Position? _last;
  int _refCount = 0;
  // The recorder's fine settings (#2766): the upstream is always (re)opened
  // with these while a `recording` consumer is present.
  LocationSettings? _recordingSettings;
  int _recordingRefCount = 0;

  // #4353 — three distinct facts, because a request is not an application:
  // the live consumer set's aggregate requirement; what the LIVE upstream
  // was actually opened with (null whenever nothing is applied — before the
  // first open, mid-replacement, after a failed open, after the stream
  // ended); and the single-flight replacement future.
  LocationSettings? _requestedSettings;
  LocationSettings? _effectiveSettings;
  Future<void>? _transitionInFlight;
  // Monotonic upstream generation: every listener callback captures the one
  // it was opened at and drops the event unless it is still live, so a late
  // data / error / done from a replaced (or still-cancelling) stream never
  // reaches the bus or mutates this source.
  int _generation = 0;

  LocationSettings? get requestedSettings => _requestedSettings;
  LocationSettings? get effectiveSettings => _effectiveSettings;
  bool get transitionInFlight => _transitionInFlight != null;

  /// Hand a consumer a stream that seeds the latest fix (if any) then
  /// forwards every subsequent fix from the shared broadcast. Open-on-first
  /// / cancel-on-last is driven off the refcount kept here rather than the
  /// broadcast controller's own onListen / onCancel, so the seeded late-join
  /// replay does not perturb the refcount.
  Stream<Position> subscribe({
    LocationSettings? locationSettings,
    bool recording = false,
  }) {
    // Per-consumer controller, closed in its own `onCancel` — no leak.
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
    // The recorder's fine settings win while a recording consumer is
    // present; otherwise the settings the channel was opened with. A coarse
    // consumer joining an open channel never re-configures it (#2766/#4353).
    _requestedSettings = _recordingRefCount > 0
        ? _recordingSettings
        : (_refCount == 1 ? locationSettings : _requestedSettings);
    if (_refCount == 1 && _upstream == null && _transitionInFlight == null) {
      _openUpstream(_requestedSettings);
      return;
    }
    if (!identical(_effectiveSettings, _requestedSettings)) {
      unawaited(_replaceUpstream());
    }
  }

  /// #4353 — replace the live upstream so it actually runs at
  /// [_requestedSettings]. Cancel-FIRST, and the cancel is **awaited**:
  /// `geolocator_android` hands a cached `_positionStream` back verbatim,
  /// dropping the new `locationSettings`, until the LAST listener's cancel
  /// clears the cache (`geolocator_android-5.0.3/lib/src/
  /// geolocator_android.dart:169-171`, `asBroadcastStream(onCancel:)` at
  /// `:207-212`), so the old open-new-before-cancel-old ordering left the
  /// recorder on the detector's coarse, foreground-service-LESS stream. The
  /// brief fix gap cancel-first costs is bridged by the bus + `_last`.
  ///
  /// Single-flight: concurrent promotions coalesce onto the one in-flight
  /// future, whose loop re-reads [_requestedSettings] after each cancel, so
  /// there is only ever one upstream and it settles at the LATEST aggregate
  /// requirement, never on an intermediate one. This never throws — a failed
  /// cancel or open is surfaced on the shared bus and leaves
  /// [_effectiveSettings] null (nothing applied) — so callers may fire it
  /// with `unawaited`. Fault paths are pinned by
  /// `test/core/location/geolocator_wrapper_test.dart`.
  Future<void> _replaceUpstream() {
    return _transitionInFlight ??=
        _runReplacement().whenComplete(() => _transitionInFlight = null);
  }

  Future<void> _runReplacement() async {
    while (_refCount > 0 &&
        !identical(_effectiveSettings, _requestedSettings)) {
      final old = _upstream;
      _upstream = null;
      // Retire the generation BEFORE awaiting the cancel: the old stream
      // stays live until the platform acknowledges, and none of its events
      // may reach the bus or the next generation's state.
      _generation++;
      _effectiveSettings = null;
      try {
        await old?.safeCancel();
      } catch (e, st) {
        // Already fenced off by the retirement. Surface and carry on —
        // refusing to re-open would strand the recording with no source.
        if (!_out.isClosed) _out.addError(e, st);
      }
      // Stop-during-promotion: the last consumer left mid-cancel, so opening
      // now would leak an upstream nobody listens to.
      if (_refCount == 0) return;
      // The requirement is re-read AFTER the cancel, so promotions that
      // arrived mid-flight coalesce into this one open.
      if (!_openUpstream(_requestedSettings)) return;
    }
  }

  /// Opens the platform stream at [settings] and makes it the live
  /// generation (cancelled by [_release], replaced by [_replaceUpstream]).
  /// Returns false when the open failed: the error goes on the bus and
  /// [_effectiveSettings] stays null — requested, but NOT applied.
  bool _openUpstream(LocationSettings? settings) {
    final gen = ++_generation;
    try {
      _upstream = _open(settings).listen(
        (p) {
          if (gen != _generation) return;
          _last = p;
          if (!_out.isClosed) _out.add(p);
        },
        onError: (Object e, StackTrace st) {
          if (gen != _generation) return;
          if (!_out.isClosed) _out.addError(e, st);
        },
        onDone: () {
          if (gen != _generation) return;
          // Ended (permission revoked, provider disabled, plugin teardown):
          // nothing is applied any more, and diagnostics must say so.
          _upstream = null;
          _effectiveSettings = null;
        },
      );
      _effectiveSettings = settings;
      return true;
    } catch (e, st) {
      _upstream = null;
      _effectiveSettings = null;
      if (!_out.isClosed) _out.addError(e, st);
      return false;
    }
  }

  Future<void> _release({required bool recording}) async {
    if (_refCount == 0) return;
    _refCount--;
    if (recording && _recordingRefCount > 0) {
      _recordingRefCount--;
      if (_recordingRefCount == 0) _recordingSettings = null;
    }
    // #4353 — a consumer leaving never re-configures the upstream, so
    // dropping the radar can never downgrade a live recording.
    if (_refCount == 0) {
      final up = _upstream;
      _upstream = null;
      _last = null;
      _generation++;
      _requestedSettings = null;
      _effectiveSettings = null;
      await up?.safeCancel();
    }
  }
}
