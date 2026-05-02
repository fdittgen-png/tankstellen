import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/movement_detection_provider.dart';

/// Builds a [Position] with sensible defaults for tests.
Position _pos({
  required double lat,
  required double lng,
  DateTime? timestamp,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: timestamp ?? DateTime(2026, 4, 28, 12, 0, 0),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

/// Fake [GeolocatorWrapper] exposing a controllable stream so the test can
/// push position events and observe subscription lifecycle.
class _FakeGeolocator extends GeolocatorWrapper {
  final StreamController<Position> controller =
      StreamController<Position>.broadcast();

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return controller.stream;
  }

  void dispose() {
    if (!controller.isClosed) {
      controller.close();
    }
  }
}

void main() {
  group('MovementDetectionConfig', () {
    test('default constructor sets the documented defaults', () {
      const config = MovementDetectionConfig();

      expect(config.thresholdKm, 5.0);
      expect(config.minRefreshInterval, const Duration(minutes: 2));
      expect(config.accuracy, LocationAccuracy.low);
      expect(config.distanceFilterMeters, 100);
    });

    test('batterySaver constructor sets battery-saving defaults', () {
      const config = MovementDetectionConfig.batterySaver();

      expect(config.thresholdKm, 5.0);
      expect(config.minRefreshInterval, const Duration(minutes: 5));
      expect(config.accuracy, LocationAccuracy.lowest);
      expect(config.distanceFilterMeters, 200);
    });
  });

  group('MovementDetectionState', () {
    test('default constructor produces an inactive empty state', () {
      const state = MovementDetectionState();

      expect(state.isActive, isFalse);
      expect(state.lastRefreshPosition, isNull);
      expect(state.lastRefreshTime, isNull);
      expect(state.currentPosition, isNull);
    });

    test('copyWith updates each field independently', () {
      const empty = MovementDetectionState();
      final position = _pos(lat: 1, lng: 2);
      final time = DateTime(2026, 1, 1);
      final current = _pos(lat: 3, lng: 4);

      final activated = empty.copyWith(isActive: true);
      expect(activated.isActive, isTrue);
      expect(activated.lastRefreshPosition, isNull);

      final withRefreshPos = empty.copyWith(lastRefreshPosition: position);
      expect(withRefreshPos.lastRefreshPosition, position);
      expect(withRefreshPos.isActive, isFalse);

      final withTime = empty.copyWith(lastRefreshTime: time);
      expect(withTime.lastRefreshTime, time);

      final withCurrent = empty.copyWith(currentPosition: current);
      expect(withCurrent.currentPosition, current);
    });

    test('copyWith with no arguments returns an equal state', () {
      final original = MovementDetectionState(
        isActive: true,
        lastRefreshPosition: _pos(lat: 10, lng: 20),
        lastRefreshTime: DateTime(2026, 2, 2),
        currentPosition: _pos(lat: 11, lng: 21),
      );

      final copied = original.copyWith();

      expect(copied.isActive, original.isActive);
      expect(copied.lastRefreshPosition, original.lastRefreshPosition);
      expect(copied.lastRefreshTime, original.lastRefreshTime);
      expect(copied.currentPosition, original.currentPosition);
    });

    test('copyWith null arguments preserve existing values (?? semantics)', () {
      // copyWith uses `value ?? this.value`, so explicit nulls cannot clear
      // a previously-set field — they are passthroughs.
      final populated = MovementDetectionState(
        isActive: true,
        lastRefreshPosition: _pos(lat: 5, lng: 6),
        lastRefreshTime: DateTime(2026, 3, 3),
        currentPosition: _pos(lat: 7, lng: 8),
      );

      final preserved = populated.copyWith(
        isActive: null,
        lastRefreshPosition: null,
        lastRefreshTime: null,
        currentPosition: null,
      );

      expect(preserved.isActive, populated.isActive);
      expect(preserved.lastRefreshPosition, populated.lastRefreshPosition);
      expect(preserved.lastRefreshTime, populated.lastRefreshTime);
      expect(preserved.currentPosition, populated.currentPosition);
    });
  });

  group('MovementDetectionLogic', () {
    const config = MovementDetectionConfig(
      thresholdKm: 5.0,
      minRefreshInterval: Duration(minutes: 2),
    );
    const logic = MovementDetectionLogic(config);

    test('hasMovedBeyondThreshold treats null lastRefreshPosition as moved',
        () {
      expect(
        logic.hasMovedBeyondThreshold(_pos(lat: 0, lng: 0), null),
        isTrue,
      );
    });

    test('hasMovedBeyondThreshold returns false for sub-threshold distance',
        () {
      // ~0.1 km apart
      final last = _pos(lat: 48.000, lng: 3.0);
      final current = _pos(lat: 48.001, lng: 3.0);
      expect(logic.hasMovedBeyondThreshold(current, last), isFalse);
    });

    test('hasMovedBeyondThreshold returns true at or above threshold', () {
      // ~11 km apart
      final last = _pos(lat: 48.0, lng: 3.0);
      final current = _pos(lat: 48.1, lng: 3.0);
      expect(logic.hasMovedBeyondThreshold(current, last), isTrue);
    });

    test('hasRateLimitElapsed returns true when lastRefreshTime is null', () {
      expect(logic.hasRateLimitElapsed(DateTime(2026, 1, 1), null), isTrue);
    });

    test('hasRateLimitElapsed returns true when interval elapsed', () {
      final last = DateTime(2026, 1, 1, 12, 0, 0);
      final now = DateTime(2026, 1, 1, 12, 3, 0); // 3 min later
      expect(logic.hasRateLimitElapsed(now, last), isTrue);
    });

    test('hasRateLimitElapsed returns false when interval not elapsed', () {
      final last = DateTime(2026, 1, 1, 12, 0, 0);
      final now = DateTime(2026, 1, 1, 12, 1, 0); // 1 min later (< 2)
      expect(logic.hasRateLimitElapsed(now, last), isFalse);
    });

    test('shouldRefresh requires both branches to be true', () {
      final last = _pos(lat: 48.0, lng: 3.0);
      final far = _pos(lat: 48.1, lng: 3.0); // ~11 km
      final near = _pos(lat: 48.001, lng: 3.0); // ~0.1 km
      final lastTime = DateTime(2026, 1, 1, 12, 0, 0);
      final laterEnough = DateTime(2026, 1, 1, 12, 3, 0); // 3 min later
      final tooSoon = DateTime(2026, 1, 1, 12, 1, 0); // 1 min later

      // Both true -> refresh.
      expect(
        logic.shouldRefresh(
          currentPosition: far,
          lastRefreshPosition: last,
          now: laterEnough,
          lastRefreshTime: lastTime,
        ),
        isTrue,
      );

      // Distance branch false -> no refresh.
      expect(
        logic.shouldRefresh(
          currentPosition: near,
          lastRefreshPosition: last,
          now: laterEnough,
          lastRefreshTime: lastTime,
        ),
        isFalse,
      );

      // Rate-limit branch false -> no refresh.
      expect(
        logic.shouldRefresh(
          currentPosition: far,
          lastRefreshPosition: last,
          now: tooSoon,
          lastRefreshTime: lastTime,
        ),
        isFalse,
      );
    });
  });

  group('MovementDetection notifier', () {
    late _FakeGeolocator fake;
    late ProviderContainer container;

    setUp(() {
      fake = _FakeGeolocator();
      container = ProviderContainer(
        overrides: [
          geolocatorWrapperProvider.overrideWithValue(fake),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fake.dispose();
    });

    test('initial build returns the default state', () {
      final state = container.read(movementDetectionProvider);
      expect(state.isActive, isFalse);
      expect(state.currentPosition, isNull);
      expect(state.lastRefreshPosition, isNull);
      expect(state.lastRefreshTime, isNull);
    });

    test('start activates the notifier and subscribes to the stream', () {
      container.read(movementDetectionProvider.notifier).start();

      expect(container.read(movementDetectionProvider).isActive, isTrue);
      expect(
        fake.controller.hasListener,
        isTrue,
        reason: 'start() should subscribe to the position stream',
      );
    });

    test('stop resets state to defaults and cancels the subscription', () {
      final notifier = container.read(movementDetectionProvider.notifier);
      notifier.start();
      expect(fake.controller.hasListener, isTrue);

      notifier.stop();

      final state = container.read(movementDetectionProvider);
      expect(state.isActive, isFalse);
      expect(state.lastRefreshPosition, isNull);
      expect(state.lastRefreshTime, isNull);
      expect(state.currentPosition, isNull);
      expect(
        fake.controller.hasListener,
        isFalse,
        reason: 'stop() must cancel the position stream subscription',
      );
    });

    test(
        'large movement past rate limit updates lastRefreshPosition and lastRefreshTime',
        () async {
      final notifier = container.read(movementDetectionProvider.notifier);
      notifier.start(
        config: const MovementDetectionConfig(
          thresholdKm: 5.0,
          minRefreshInterval: Duration.zero,
        ),
      );

      // First emission triggers refresh because lastRefreshPosition is null.
      fake.controller.add(_pos(lat: 48.0, lng: 3.0));
      await Future<void>.delayed(Duration.zero);

      final firstState = container.read(movementDetectionProvider);
      expect(firstState.lastRefreshPosition, isNotNull);
      expect(firstState.lastRefreshTime, isNotNull);
      expect(firstState.currentPosition!.latitude, 48.0);

      final firstRefreshTime = firstState.lastRefreshTime!;

      // Wait so the next DateTime.now() advances.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Large movement (~11 km) triggers a second refresh.
      fake.controller.add(_pos(lat: 48.1, lng: 3.0));
      await Future<void>.delayed(Duration.zero);

      final secondState = container.read(movementDetectionProvider);
      expect(secondState.lastRefreshPosition!.latitude, 48.1);
      expect(secondState.currentPosition!.latitude, 48.1);
      expect(
        secondState.lastRefreshTime!.isAfter(firstRefreshTime),
        isTrue,
        reason: 'second refresh must produce a newer timestamp',
      );
    });

    test(
        'small movement updates currentPosition but not lastRefreshPosition',
        () async {
      final notifier = container.read(movementDetectionProvider.notifier);
      notifier.start(
        config: const MovementDetectionConfig(
          thresholdKm: 5.0,
          minRefreshInterval: Duration.zero,
        ),
      );

      // Anchor first refresh.
      fake.controller.add(_pos(lat: 48.0, lng: 3.0));
      await Future<void>.delayed(Duration.zero);

      final anchored = container.read(movementDetectionProvider);
      final anchoredRefreshPos = anchored.lastRefreshPosition;
      final anchoredRefreshTime = anchored.lastRefreshTime;

      // Tiny movement (~0.1 km, well below 5 km threshold).
      fake.controller.add(_pos(lat: 48.001, lng: 3.0));
      await Future<void>.delayed(Duration.zero);

      final after = container.read(movementDetectionProvider);
      expect(after.currentPosition!.latitude, 48.001);
      expect(after.lastRefreshPosition, same(anchoredRefreshPos));
      expect(after.lastRefreshTime, same(anchoredRefreshTime));
    });

    test('disposing the container cancels the position subscription', () {
      // Use a dedicated container so the shared tearDown doesn't double-dispose.
      final localFake = _FakeGeolocator();
      final localContainer = ProviderContainer(
        overrides: [
          geolocatorWrapperProvider.overrideWithValue(localFake),
        ],
      );
      addTearDown(localFake.dispose);

      localContainer.read(movementDetectionProvider.notifier).start();
      expect(localFake.controller.hasListener, isTrue);

      localContainer.dispose();

      expect(
        localFake.controller.hasListener,
        isFalse,
        reason: 'ref.onDispose should cancel the position subscription',
      );
    });
  });

  group('MovementDetection EventChannel cleanup (#1352)', () {
    // `Geolocator.getPositionStream()` is backed by the
    // `flutter.baseflow.com/geolocator_updates_android` EventChannel.
    // When the OS tears the broadcast down before the Dart cancel
    // (permission revoked, position service stopped), Flutter rethrows
    // the benign `PlatformException("No active stream to cancel")`
    // through cancel's future. Without `safeCancel` that exception
    // bubbles up into the privacy-dashboard error log (#1352) and
    // masks real bugs. These tests pin the migration so a future
    // rewrite that drops the `safeCancel()` call fails loudly.

    test(
        'stop() swallows the benign "No active stream to cancel" '
        'PlatformException raised by the EventChannel-backed cancel',
        () async {
      final fake = _ThrowingFakeGeolocator(
        cancelError: PlatformException(
          code: 'error',
          message: 'No active stream to cancel',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          geolocatorWrapperProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      final notifier = container.read(movementDetectionProvider.notifier);
      notifier.start();
      // Pump the listen so the underlying subscription is established
      // and `stop()` will actually invoke `cancel()`.
      await Future<void>.delayed(Duration.zero);

      // `stop()` must NOT rethrow — the PlatformException is benign
      // and `safeCancel` is responsible for swallowing it.
      expect(notifier.stop, returnsNormally);
      expect(fake.cancelCount, 1);
    });

    test(
        'stop() rethrows non-benign PlatformExceptions raised by cancel '
        '(safeCancel only swallows the exact "No active stream" message)',
        () async {
      final fake = _ThrowingFakeGeolocator(
        cancelError: PlatformException(
          code: 'error',
          message: 'Different platform error',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          geolocatorWrapperProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      final notifier = container.read(movementDetectionProvider.notifier);
      notifier.start();
      await Future<void>.delayed(Duration.zero);

      // The cancel happens through `unawaited(...safeCancel())` so the
      // synchronous `stop()` returns normally — but the unawaited
      // future must surface the rethrown error to the zone. Catch it
      // explicitly via runZonedGuarded so the test can assert on the
      // rethrown PlatformException without a leaked uncaught error.
      Object? caughtError;
      await runZonedGuarded<Future<void>>(() async {
        notifier.stop();
        // Allow microtasks for the unawaited safeCancel to settle.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }, (e, _) {
        caughtError = e;
      });

      expect(
        caughtError,
        isA<PlatformException>().having(
          (e) => e.message,
          'message',
          'Different platform error',
        ),
      );
      expect(fake.cancelCount, 1);
    });
  });
}

/// Variant of [_FakeGeolocator] whose subscription's `cancel()` throws.
/// Lets us prove the `safeCancel` migration in
/// [MovementDetection._stopListening] swallows the benign EventChannel
/// PlatformException (#1352) without removing real cancellation
/// semantics.
class _ThrowingFakeGeolocator extends GeolocatorWrapper {
  _ThrowingFakeGeolocator({required this.cancelError});

  final Object cancelError;
  int cancelCount = 0;
  StreamController<Position>? _controller;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    // Closed in [dispose] — owned by the test fake, not the production
    // notifier (the notifier only ever holds the subscription, never
    // the underlying controller).
    // ignore: close_sinks
    final controller = StreamController<Position>(
      onCancel: () async {
        cancelCount++;
        throw cancelError;
      },
    );
    _controller = controller;
    return controller.stream;
  }

  void dispose() {
    final c = _controller;
    if (c != null && !c.isClosed) {
      // Detach the throwing onCancel before disposing — tearDown must
      // not be the path that triggers the test's expected throw.
      c.onCancel = null;
      c.close();
    }
  }
}
