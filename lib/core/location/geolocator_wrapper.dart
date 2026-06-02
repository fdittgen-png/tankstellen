// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/consumption/data/obd2/event_channel_cancel.dart';

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
  /// [locationSettings] is read only the first time the underlying stream is
  /// opened (all trip consumers request `LocationAccuracy.high`); subsequent
  /// listeners join the existing stream regardless of the settings they pass.
  Stream<Position> sharedPositionStream({
    LocationSettings? locationSettings,
  }) {
    final source = _shared ??= _SharedPositionSource(
      // Route through [getPositionStream] (not Geolocator directly) so the
      // single override seam tests already use stays intact and the
      // forceLocationManager wrapping (#2574) is applied in exactly one place.
      open: () => getPositionStream(locationSettings: locationSettings),
    );
    return source.subscribe();
  }

  _SharedPositionSource? _shared;
}

/// Refcounted broadcast multiplexer over a single underlying position
/// stream (#2646). Owns the one platform subscription: opens it on the first
/// listener, cancels it on the last, and replays the latest fix to late
/// joiners. Constructed lazily by [GeolocatorWrapper.sharedPositionStream].
class _SharedPositionSource {
  _SharedPositionSource({required Stream<Position> Function() open})
      : _open = open;

  final Stream<Position> Function() _open;
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

  /// Hand a consumer a stream that seeds the latest fix (if any) then
  /// forwards every subsequent fix from the shared broadcast. Opening the
  /// underlying subscription on the first consumer and cancelling on the last
  /// is driven off the refcount kept here rather than the broadcast
  /// controller's own onListen / onCancel, so the seeded late-join replay
  /// does not perturb the refcount.
  Stream<Position> subscribe() {
    // Per-consumer controller. Closed in its own `onCancel` once the
    // consumer detaches, so there is no leak.
    // ignore: close_sinks
    late final StreamController<Position> ctl;
    StreamSubscription<Position>? relay;
    ctl = StreamController<Position>(
      onListen: () {
        _retain();
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
        await _release();
        if (!ctl.isClosed) await ctl.close();
      },
    );
    return ctl.stream;
  }

  void _retain() {
    _refCount++;
    if (_refCount == 1) {
      // Cancelled in [_release] when the refcount falls back to 0.
      _upstream = _open().listen(
        (p) {
          _last = p;
          if (!_out.isClosed) _out.add(p);
        },
        onError: (Object e, StackTrace st) {
          if (!_out.isClosed) _out.addError(e, st);
        },
      );
    }
  }

  Future<void> _release() async {
    if (_refCount == 0) return;
    _refCount--;
    if (_refCount == 0) {
      final up = _upstream;
      _upstream = null;
      _last = null;
      await up?.safeCancel();
    }
  }
}
