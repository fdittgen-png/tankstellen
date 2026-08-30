// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// #3883 — the rolling "last N s" consumption stamp of the emit loop,
/// split out of `trip_recording_controller_emit.dart` (400-line cap).
mixin _TripRecordingWindowStamp on _TripRecordingSessionState {
  /// Fold this tick into the rolling window (the recording screen's
  /// headline) and stamp the figures. The measured fuel rate feeds it;
  /// on a car without a fuel PID the GPS-physics estimate the overlay
  /// just folded in does (L/100 km × speed → L/h), so the window is
  /// populated on every kind of trip.
  TripLiveReading _stampRollingWindow(
    TripLiveReading reading, {
    required DateTime nowTs,
    required double? fuelRate,
    required double? speedKmh,
  }) {
    final est = fuelRate == null ? reading.gpsEstimatedLPer100Km : null;
    final feedRate = fuelRate ??
        (est != null && speedKmh != null ? est / 100.0 * speedKmh : null);
    _rollingWindow.add(
        now: nowTs, fuelRateLPerHour: feedRate, speedKmh: speedKmh);
    final seconds = readLiveConsumptionWindowSeconds();
    final window = _rollingWindow.read(Duration(seconds: seconds));
    if (window == null) return reading;
    return reading.copyWith(
      windowLPer100Km: window.lPer100Km,
      windowLPerHour: window.lPerHour,
      windowIsIdle: window.isIdle,
      windowSeconds: seconds,
    );
  }
}
