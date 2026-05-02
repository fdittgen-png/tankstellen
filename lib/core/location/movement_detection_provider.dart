import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/consumption/data/obd2/event_channel_cancel.dart';
import '../utils/geo_utils.dart';
import 'geolocator_wrapper.dart';

part 'movement_detection_provider.g.dart';

/// Configuration for movement-based station refresh in driving mode.
class MovementDetectionConfig {
  /// Distance threshold in km before triggering a refresh.
  final double thresholdKm;

  /// Minimum interval between refreshes.
  final Duration minRefreshInterval;

  /// Location accuracy setting (low power for battery savings).
  final LocationAccuracy accuracy;

  /// Distance filter for the position stream (meters).
  /// Filters out tiny GPS jitter at the platform level.
  final int distanceFilterMeters;

  const MovementDetectionConfig({
    this.thresholdKm = 5.0,
    this.minRefreshInterval = const Duration(minutes: 2),
    this.accuracy = LocationAccuracy.low,
    this.distanceFilterMeters = 100,
  });

  /// Battery-saver mode: larger threshold, longer interval.
  const MovementDetectionConfig.batterySaver()
      : thresholdKm = 5.0,
        minRefreshInterval = const Duration(minutes: 5),
        accuracy = LocationAccuracy.lowest,
        distanceFilterMeters = 200;
}

/// Tracks the state of movement detection: last refresh position and timestamp.
class MovementDetectionState {
  /// Whether driving mode and movement detection are active.
  final bool isActive;

  /// The position at the last station refresh.
  final Position? lastRefreshPosition;

  /// Timestamp of the last station refresh triggered by movement.
  final DateTime? lastRefreshTime;

  /// The latest known position from the GPS stream.
  final Position? currentPosition;

  const MovementDetectionState({
    this.isActive = false,
    this.lastRefreshPosition,
    this.lastRefreshTime,
    this.currentPosition,
  });

  MovementDetectionState copyWith({
    bool? isActive,
    Position? lastRefreshPosition,
    DateTime? lastRefreshTime,
    Position? currentPosition,
  }) {
    return MovementDetectionState(
      isActive: isActive ?? this.isActive,
      lastRefreshPosition: lastRefreshPosition ?? this.lastRefreshPosition,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

/// Pure logic for movement detection decisions.
///
/// Extracted from the provider so it can be unit-tested without Riverpod.
class MovementDetectionLogic {
  final MovementDetectionConfig config;

  const MovementDetectionLogic(this.config);

  /// Returns true if the user has moved far enough from [lastRefreshPosition]
  /// to warrant a station refresh.
  bool hasMovedBeyondThreshold(Position current, Position? lastRefreshPosition) {
    if (lastRefreshPosition == null) return true;

    final km = distanceKm(
      lastRefreshPosition.latitude,
      lastRefreshPosition.longitude,
      current.latitude,
      current.longitude,
    );
    return km >= config.thresholdKm;
  }

  /// Returns true if enough time has passed since [lastRefreshTime]
  /// to respect the rate limit.
  bool hasRateLimitElapsed(DateTime now, DateTime? lastRefreshTime) {
    if (lastRefreshTime == null) return true;
    return now.difference(lastRefreshTime) >= config.minRefreshInterval;
  }

  /// Returns true if a refresh should be triggered based on both
  /// distance threshold and rate limit.
  bool shouldRefresh({
    required Position currentPosition,
    required Position? lastRefreshPosition,
    required DateTime now,
    required DateTime? lastRefreshTime,
  }) {
    return hasMovedBeyondThreshold(currentPosition, lastRefreshPosition) &&
        hasRateLimitElapsed(now, lastRefreshTime);
  }
}

/// Callback type for when movement detection triggers a station refresh.
typedef OnMovementRefresh = void Function(double lat, double lng);

/// Provides movement detection state for driving mode.
///
/// When active, monitors GPS position changes and determines when the user
/// has moved far enough to warrant a station refresh. Consumers should
/// watch this provider and trigger their own search when
/// [MovementDetectionState.lastRefreshTime] changes.
@Riverpod(keepAlive: true)
class MovementDetection extends _$MovementDetection {
  StreamSubscription<Position>? _positionSubscription;
  MovementDetectionLogic _logic = const MovementDetectionLogic(
    MovementDetectionConfig(),
  );

  @override
  MovementDetectionState build() {
    ref.onDispose(_stopListening);
    return const MovementDetectionState();
  }

  /// Start movement detection with the given configuration.
  ///
  /// Subscribes to the platform position stream and evaluates each update
  /// against the distance threshold and rate limit.
  void start({
    MovementDetectionConfig config = const MovementDetectionConfig(),
  }) {
    _stopListening();
    _logic = MovementDetectionLogic(config);

    final geolocator = ref.read(geolocatorWrapperProvider);
    final locationSettings = LocationSettings(
      accuracy: config.accuracy,
      distanceFilter: config.distanceFilterMeters,
    );

    _positionSubscription = geolocator
        .getPositionStream(locationSettings: locationSettings)
        .listen(
      _onPositionUpdate,
      onError: (Object error) {
        debugPrint('Movement detection stream error: $error');
      },
    );

    state = state.copyWith(isActive: true);
  }

  /// Stop movement detection and clean up the position stream.
  void stop() {
    _stopListening();
    state = const MovementDetectionState();
  }

  /// Process a new position from the GPS stream.
  void _onPositionUpdate(Position position) {
    final now = DateTime.now();
    state = state.copyWith(currentPosition: position);

    if (_logic.shouldRefresh(
      currentPosition: position,
      lastRefreshPosition: state.lastRefreshPosition,
      now: now,
      lastRefreshTime: state.lastRefreshTime,
    )) {
      state = state.copyWith(
        lastRefreshPosition: position,
        lastRefreshTime: now,
      );
      // State change notifies watchers — they trigger the actual search.
    }
  }

  void _stopListening() {
    // #1352 — `Geolocator.getPositionStream()` is backed by the
    // `flutter.baseflow.com/geolocator_updates_android` EventChannel.
    // When the user revokes the location permission mid-stream, or the
    // OS kills the position service, the platform side tears the
    // broadcast down before we cancel — Flutter then rethrows a benign
    // `PlatformException("No active stream to cancel")` that would
    // otherwise pollute the privacy-dashboard error log.
    unawaited(_positionSubscription?.safeCancel());
    _positionSubscription = null;
  }
}
