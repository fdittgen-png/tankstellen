import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

/// Verifies the [Feature.gpsTripPath]-gated GPS subscription wiring
/// inside [TripRecording.start] (#1374 phase 1).
///
/// Two cases must hold:
///
///   1. **flag off (default)** — no Geolocator subscription is ever
///      opened. Existing users see zero behaviour change: no battery
///      cost, no location-permission prompt, no plugin call. This is
///      the foundation of the "inert by default" promise in the
///      issue body.
///   2. **flag on** — the provider subscribes to the position
///      stream and routes each fix into the controller's
///      [TripRecordingController.updateGpsFix] latch, so the next
///      [TripSample] the recorder builds carries the coords.
///
/// We mock [GeolocatorWrapper] with a controllable stream so we can
/// drive both arms deterministically without touching the real
/// platform plugin (which is unavailable in unit tests).
void main() {
  group('TripRecording GPS gating (#1374 phase 1)', () {
    test(
        'flag OFF (default) — no Geolocator subscription is ever started; '
        'controller.debugLatestLatitude / debugLatestLongitude stay null '
        'across the whole trip', () async {
      final fakeGeo = _RecordingGeolocator();
      final container = ProviderContainer(overrides: [
        geolocatorWrapperProvider.overrideWithValue(fakeGeo),
      ]);
      addTearDown(container.dispose);
      addTearDown(fakeGeo.dispose);

      // Sanity check on the manifest default — if this ever flips, the
      // whole "inert by default" guarantee is gone and we want a loud
      // failure here, not a silent battery regression in production.
      expect(
        container.read(featureFlagsProvider.notifier)
            .isEnabled(Feature.gpsTripPath),
        isFalse,
        reason: 'gpsTripPath must default to false per the manifest',
      );

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);

      // The provider must NOT have called the plugin even once.
      expect(fakeGeo.positionStreamCallCount, 0,
          reason: 'flag-off path must never touch Geolocator');

      // And the controller's latch is still null — every TripSample
      // emitted on a flag-off recording carries lat/lng = null.
      final ctl = notifier.debugController;
      expect(ctl, isNotNull);
      expect(ctl!.debugLatestLatitude, isNull);
      expect(ctl.debugLatestLongitude, isNull);

      await notifier.stop();
    });

    test(
        'flag ON — provider opens a position stream and pushes each fix '
        'into the controller via updateGpsFix; subsequent samples carry '
        'the latest coords', () async {
      final fakeGeo = _RecordingGeolocator();
      final container = ProviderContainer(overrides: [
        geolocatorWrapperProvider.overrideWithValue(fakeGeo),
      ]);
      addTearDown(container.dispose);
      addTearDown(fakeGeo.dispose);

      // Flip the flag on for this container BEFORE start() — the
      // provider only checks the flag at trip-start (the subscription
      // is born then). Mid-trip toggles are out of scope for phase 1.
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.gpsTripPath);
      expect(
        container.read(featureFlagsProvider.notifier)
            .isEnabled(Feature.gpsTripPath),
        isTrue,
      );

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);

      // The provider must have asked Geolocator for a stream exactly once.
      expect(fakeGeo.positionStreamCallCount, 1,
          reason: 'flag-on path opens exactly one position stream');
      // And asked for HIGH accuracy — the eventual heatmap (Phase 3)
      // wants ~10 m precision; downgrades are a Phase 2 follow-up.
      expect(fakeGeo.lastAccuracy, LocationAccuracy.high);

      // Push a fix down the fake stream and let the listener run.
      fakeGeo.emit(_pos(43.4567, 3.5821));
      await Future<void>.delayed(Duration.zero);

      final ctl = notifier.debugController;
      expect(ctl, isNotNull);
      expect(ctl!.debugLatestLatitude, closeTo(43.4567, 1e-9));
      expect(ctl.debugLatestLongitude, closeTo(3.5821, 1e-9));

      // A second fix overwrites the first — the latch is "most-recent
      // wins", which matches the heatmap's per-tick semantics.
      fakeGeo.emit(_pos(43.4600, 3.5900));
      await Future<void>.delayed(Duration.zero);
      expect(ctl.debugLatestLatitude, closeTo(43.4600, 1e-9));
      expect(ctl.debugLatestLongitude, closeTo(3.5900, 1e-9));

      await notifier.stop();
      // After stop, the subscription must be cancelled. Pushing more
      // events to the controller would be silently swallowed — but
      // more importantly, the provider has nulled out the controller
      // so a leaked subscription would NPE on the next emit. The
      // recording counter drops back to zero on the next start().
      expect(fakeGeo.activeListeners, 0,
          reason: 'stop() must cancel the GPS subscription');
    });

    test(
        'flag ON but Geolocator stream errors mid-trip — error is '
        'logged + swallowed; the trip recording continues; subsequent '
        'samples carry whatever was in the latch (or null)', () async {
      // A permission revoke or platform-side stream death must NOT
      // derail an in-progress trip. The provider catches stream
      // errors and lets the OBD2 polling loop keep running — the
      // user's drive metrics are more important than the optional
      // GPS overlay.
      final fakeGeo = _RecordingGeolocator();
      final container = ProviderContainer(overrides: [
        geolocatorWrapperProvider.overrideWithValue(fakeGeo),
      ]);
      addTearDown(container.dispose);
      addTearDown(fakeGeo.dispose);

      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.gpsTripPath);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      // First push a real fix so we know the wiring works…
      fakeGeo.emit(_pos(50.0, 4.0));
      await Future<void>.delayed(Duration.zero);
      final ctl = notifier.debugController;
      expect(ctl, isNotNull);
      expect(ctl!.debugLatestLatitude, 50.0);

      // …then drop an error onto the stream. The provider's
      // onError handler must absorb it without rethrowing into the
      // trip-recording state machine.
      fakeGeo.emitError(Exception('permission revoked'));
      await Future<void>.delayed(Duration.zero);
      // The trip is still active — no phase regression.
      expect(container.read(tripRecordingProvider).isActive, isTrue);

      await notifier.stop();
    });
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// Test double for [GeolocatorWrapper] that captures every
/// `getPositionStream` call AND lets the test push positions / errors
/// down the returned stream on demand.
///
/// Mirrors `test/core/location/location_service_test.dart`'s
/// `_FakeGeolocator` but adds a controllable broadcast stream — the
/// production provider listens with a single subscriber, but using a
/// broadcast controller lets us count active listeners cleanly via
/// [activeListeners].
class _RecordingGeolocator extends GeolocatorWrapper {
  int positionStreamCallCount = 0;
  LocationAccuracy? lastAccuracy;
  // Re-created on each getPositionStream call so onListen / onCancel
  // hooks accurately reflect whether the production code is currently
  // subscribed (a single shared controller would conflate the two).
  StreamController<Position>? _controller;
  int activeListeners = 0;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    positionStreamCallCount++;
    lastAccuracy = locationSettings?.accuracy;
    // Close any prior controller so the analyzer's `close_sinks`
    // lint stays quiet across re-subscribes.
    final prev = _controller;
    if (prev != null && !prev.isClosed) {
      // Fire-and-forget — tests only re-call getPositionStream when
      // the previous subscription is already gone.
      prev.close();
    }
    _controller = StreamController<Position>(
      onListen: () => activeListeners++,
      onCancel: () => activeListeners--,
    );
    return _controller!.stream;
  }

  void emit(Position p) => _controller?.add(p);
  void emitError(Object error) => _controller?.addError(error);

  /// Close the underlying controller — call from a test tearDown to
  /// silence the `close_sinks` lint when the production code is the
  /// one cancelling the subscription (which leaves the controller
  /// open on the test side).
  Future<void> dispose() async {
    final c = _controller;
    if (c != null && !c.isClosed) await c.close();
  }
}
