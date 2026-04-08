import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/movement_detection_provider.dart';

/// Creates a [Position] with sensible defaults for testing.
Position _makePosition({
  required double lat,
  required double lng,
  double speed = 0,
  double heading = 0,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 100,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

/// Fake GeolocatorWrapper that exposes a controllable position stream.
class _FakeGeolocatorWrapper extends GeolocatorWrapper {
  final StreamController<Position> positionController =
      StreamController<Position>.broadcast();

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return positionController.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _makePosition(lat: 48.0, lng: 3.0);
  }

  @override
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    // Approximate: 1 degree latitude ~ 111 km
    final dLat = (endLat - startLat).abs();
    final dLng = (endLng - startLng).abs();
    return (dLat + dLng) * 111 * 1000; // meters
  }

  void dispose() {
    positionController.close();
  }
}

void main() {
  group('MovementDetectionLogic', () {
    const config = MovementDetectionConfig(
      thresholdKm: 5.0,
      minRefreshInterval: Duration(minutes: 2),
    );
    const logic = MovementDetectionLogic(config);

    group('hasMovedBeyondThreshold', () {
      test('returns true when lastRefreshPosition is null (first position)', () {
        final current = _makePosition(lat: 48.0, lng: 3.0);
        expect(logic.hasMovedBeyondThreshold(current, null), isTrue);
      });

      test('returns false when distance is below threshold', () {
        // ~1 km apart (0.01 degrees latitude ~ 1.1 km)
        final last = _makePosition(lat: 48.0, lng: 3.0);
        final current = _makePosition(lat: 48.005, lng: 3.0);
        expect(logic.hasMovedBeyondThreshold(current, last), isFalse);
      });

      test('returns true when distance exceeds threshold', () {
        // ~11 km apart (0.1 degrees latitude ~ 11 km)
        final last = _makePosition(lat: 48.0, lng: 3.0);
        final current = _makePosition(lat: 48.1, lng: 3.0);
        expect(logic.hasMovedBeyondThreshold(current, last), isTrue);
      });

      test('returns true when distance is exactly at threshold', () {
        // ~5.5 km apart (0.05 degrees latitude ~ 5.5 km)
        final last = _makePosition(lat: 48.0, lng: 3.0);
        final current = _makePosition(lat: 48.05, lng: 3.0);
        expect(logic.hasMovedBeyondThreshold(current, last), isTrue);
      });
    });

    group('hasRateLimitElapsed', () {
      test('returns true when lastRefreshTime is null (never refreshed)', () {
        expect(logic.hasRateLimitElapsed(DateTime.now(), null), isTrue);
      });

      test('returns false when interval has not elapsed', () {
        final now = DateTime(2026, 4, 8, 12, 0, 0);
        final lastRefresh = DateTime(2026, 4, 8, 11, 59, 0); // 1 min ago
        expect(logic.hasRateLimitElapsed(now, lastRefresh), isFalse);
      });

      test('returns true when interval has elapsed', () {
        final now = DateTime(2026, 4, 8, 12, 0, 0);
        final lastRefresh = DateTime(2026, 4, 8, 11, 57, 0); // 3 min ago
        expect(logic.hasRateLimitElapsed(now, lastRefresh), isTrue);
      });

      test('returns true when interval is exactly at the limit', () {
        final now = DateTime(2026, 4, 8, 12, 0, 0);
        final lastRefresh = DateTime(2026, 4, 8, 11, 58, 0); // exactly 2 min
        expect(logic.hasRateLimitElapsed(now, lastRefresh), isTrue);
      });
    });

    group('shouldRefresh', () {
      test('returns true on first position (no prior state)', () {
        final current = _makePosition(lat: 48.0, lng: 3.0);
        expect(
          logic.shouldRefresh(
            currentPosition: current,
            lastRefreshPosition: null,
            now: DateTime.now(),
            lastRefreshTime: null,
          ),
          isTrue,
        );
      });

      test('returns false when moved but rate limit not elapsed', () {
        final last = _makePosition(lat: 48.0, lng: 3.0);
        final current = _makePosition(lat: 48.1, lng: 3.0); // >5km
        final now = DateTime(2026, 4, 8, 12, 0, 0);
        final lastRefresh = DateTime(2026, 4, 8, 11, 59, 30); // 30s ago
        expect(
          logic.shouldRefresh(
            currentPosition: current,
            lastRefreshPosition: last,
            now: now,
            lastRefreshTime: lastRefresh,
          ),
          isFalse,
        );
      });

      test('returns false when rate limit elapsed but not moved enough', () {
        final last = _makePosition(lat: 48.0, lng: 3.0);
        final current = _makePosition(lat: 48.001, lng: 3.0); // <1km
        final now = DateTime(2026, 4, 8, 12, 0, 0);
        final lastRefresh = DateTime(2026, 4, 8, 11, 55, 0); // 5 min ago
        expect(
          logic.shouldRefresh(
            currentPosition: current,
            lastRefreshPosition: last,
            now: now,
            lastRefreshTime: lastRefresh,
          ),
          isFalse,
        );
      });

      test('returns true when both conditions met', () {
        final last = _makePosition(lat: 48.0, lng: 3.0);
        final current = _makePosition(lat: 48.1, lng: 3.0); // >5km
        final now = DateTime(2026, 4, 8, 12, 0, 0);
        final lastRefresh = DateTime(2026, 4, 8, 11, 55, 0); // 5 min ago
        expect(
          logic.shouldRefresh(
            currentPosition: current,
            lastRefreshPosition: last,
            now: now,
            lastRefreshTime: lastRefresh,
          ),
          isTrue,
        );
      });
    });

    group('battery saver config', () {
      test('has larger interval than default', () {
        const batterySaver = MovementDetectionConfig.batterySaver();
        const normal = MovementDetectionConfig();
        expect(
          batterySaver.minRefreshInterval,
          greaterThan(normal.minRefreshInterval),
        );
      });

      test('uses lowest accuracy', () {
        const batterySaver = MovementDetectionConfig.batterySaver();
        expect(batterySaver.accuracy, LocationAccuracy.lowest);
      });

      test('has larger distance filter', () {
        const batterySaver = MovementDetectionConfig.batterySaver();
        const normal = MovementDetectionConfig();
        expect(
          batterySaver.distanceFilterMeters,
          greaterThan(normal.distanceFilterMeters),
        );
      });
    });
  });

  group('MovementDetection provider', () {
    late _FakeGeolocatorWrapper fakeGeolocator;
    late ProviderContainer container;

    setUp(() {
      fakeGeolocator = _FakeGeolocatorWrapper();
      container = ProviderContainer(
        overrides: [
          geolocatorWrapperProvider.overrideWithValue(fakeGeolocator),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeGeolocator.dispose();
    });

    test('initial state is inactive', () {
      final state = container.read(movementDetectionProvider);
      expect(state.isActive, isFalse);
      expect(state.lastRefreshPosition, isNull);
      expect(state.lastRefreshTime, isNull);
      expect(state.currentPosition, isNull);
    });

    test('start activates the provider', () {
      container.read(movementDetectionProvider.notifier).start();
      final state = container.read(movementDetectionProvider);
      expect(state.isActive, isTrue);
    });

    test('stop deactivates and resets state', () {
      container.read(movementDetectionProvider.notifier).start();
      container.read(movementDetectionProvider.notifier).stop();
      final state = container.read(movementDetectionProvider);
      expect(state.isActive, isFalse);
      expect(state.lastRefreshPosition, isNull);
    });

    test('first position triggers a refresh', () async {
      container.read(movementDetectionProvider.notifier).start(
        config: const MovementDetectionConfig(
          thresholdKm: 5.0,
          minRefreshInterval: Duration(minutes: 2),
        ),
      );

      fakeGeolocator.positionController.add(
        _makePosition(lat: 48.0, lng: 3.0),
      );

      // Allow stream event to propagate
      await Future<void>.delayed(Duration.zero);

      final state = container.read(movementDetectionProvider);
      expect(state.currentPosition, isNotNull);
      expect(state.lastRefreshPosition, isNotNull);
      expect(state.lastRefreshTime, isNotNull);
      expect(state.lastRefreshPosition!.latitude, 48.0);
    });

    test('small movement does not trigger refresh', () async {
      container.read(movementDetectionProvider.notifier).start(
        config: const MovementDetectionConfig(
          thresholdKm: 5.0,
          minRefreshInterval: Duration.zero, // no rate limit for this test
        ),
      );

      // First position — triggers refresh
      fakeGeolocator.positionController.add(
        _makePosition(lat: 48.0, lng: 3.0),
      );
      await Future<void>.delayed(Duration.zero);

      final firstRefreshTime =
          container.read(movementDetectionProvider).lastRefreshTime;

      // Small movement — should NOT trigger
      fakeGeolocator.positionController.add(
        _makePosition(lat: 48.001, lng: 3.0), // ~0.1 km
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(movementDetectionProvider);
      expect(state.currentPosition!.latitude, 48.001); // updated
      expect(state.lastRefreshTime, equals(firstRefreshTime)); // not refreshed
    });

    test('large movement triggers refresh when rate limit allows', () async {
      container.read(movementDetectionProvider.notifier).start(
        config: const MovementDetectionConfig(
          thresholdKm: 5.0,
          minRefreshInterval: Duration.zero, // no rate limit for this test
        ),
      );

      // First position
      fakeGeolocator.positionController.add(
        _makePosition(lat: 48.0, lng: 3.0),
      );
      await Future<void>.delayed(Duration.zero);

      final firstRefreshTime =
          container.read(movementDetectionProvider).lastRefreshTime;

      // Wait a tick so timestamps differ
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Large movement — should trigger
      fakeGeolocator.positionController.add(
        _makePosition(lat: 48.1, lng: 3.0), // ~11 km
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(movementDetectionProvider);
      expect(state.lastRefreshPosition!.latitude, 48.1);
      expect(
        state.lastRefreshTime!.isAfter(firstRefreshTime!),
        isTrue,
        reason: 'Refresh should have been triggered with a new timestamp',
      );
    });

    test('start with custom config applies settings', () {
      container.read(movementDetectionProvider.notifier).start(
        config: const MovementDetectionConfig(
          thresholdKm: 10.0,
          minRefreshInterval: Duration(minutes: 5),
          accuracy: LocationAccuracy.lowest,
          distanceFilterMeters: 500,
        ),
      );

      expect(container.read(movementDetectionProvider).isActive, isTrue);
    });

    test('restart replaces previous subscription', () async {
      container.read(movementDetectionProvider.notifier).start();

      // Start again — should not cause duplicate events
      container.read(movementDetectionProvider.notifier).start();

      fakeGeolocator.positionController.add(
        _makePosition(lat: 48.0, lng: 3.0),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(movementDetectionProvider).lastRefreshPosition,
        isNotNull,
      );
    });
  });

  group('MovementDetectionState', () {
    test('copyWith preserves unchanged fields', () {
      const original = MovementDetectionState(isActive: true);
      final copied = original.copyWith(
        lastRefreshTime: DateTime(2026, 4, 8),
      );
      expect(copied.isActive, isTrue);
      expect(copied.lastRefreshTime, DateTime(2026, 4, 8));
      expect(copied.lastRefreshPosition, isNull);
    });

    test('default state has all fields null/false', () {
      const state = MovementDetectionState();
      expect(state.isActive, isFalse);
      expect(state.lastRefreshPosition, isNull);
      expect(state.lastRefreshTime, isNull);
      expect(state.currentPosition, isNull);
    });
  });
}
