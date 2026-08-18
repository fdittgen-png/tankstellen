// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../obd2/api.dart';

/// One live eco-coaching nudge class (#3432, epic #3416 task 7).
///
/// Each maps 1:1 to a fuel-cost event class the post-trip
/// `fuel_event_attribution.dart` detector attributes litres to — the
/// nudge is the in-the-moment version of the same coaching.
enum EcoNudgeType { idleWaste, harshAccel, highRpmCruise }

/// Pure in-trip nudge decision engine (#3432).
///
/// Consumes the live readings the recording provider already emits and
/// decides — at most rarely — when to nudge the driver about fuel
/// being wasted *right now*. Deliberately pure (no timers, no streams,
/// no providers): the caller feeds `onReading(reading, now)` and shows
/// whatever non-null [EcoNudgeType] comes back. This is the exact shape
/// `HapticEcoCoach` (#1122) uses, minus the platform channel, so the
/// rate-limit logic is unit-testable with a fake clock.
///
/// ## Rate limiting (the anti-nag contract)
/// * ≥ [minGap] (default 60 s) between any two nudges, regardless of
///   class.
/// * At most [maxPerTrip] (default 3) nudges per trip — after that the
///   engine goes silent until [reset].
/// * One nudge per EPISODE: a continuing idle / pedal-mash / high-RPM
///   phase never re-fires; the condition must clear and re-occur.
///
/// ## Detection heuristics (mirroring the post-trip detector's
/// thresholds in `fuel_event_attribution.dart`)
/// * [EcoNudgeType.idleWaste] — stationary (≤ 2 km/h) with the engine
///   running for ≥ [idleThreshold] (30 s).
/// * [EcoNudgeType.harshAccel] — pedal (throttle fallback) ≥ 85 %
///   sustained ≥ [pedalSpikeSustain].
/// * [EcoNudgeType.highRpmCruise] — RPM ≥ 2800 at ≥ 30 km/h with
///   moderate throttle sustained ≥ [highRpmSustain].
///
/// The surface (a dismissible SnackBar on the recording screen) is
/// mounted only while that screen is in the foreground, so nudges are
/// structurally OFF when the recording runs in the background.
class EcoNudgeEngine {
  EcoNudgeEngine({
    this.minGap = const Duration(seconds: 60),
    this.maxPerTrip = 3,
    this.idleThreshold = const Duration(seconds: 30),
    this.pedalSpikeSustain = const Duration(seconds: 2),
    this.highRpmSustain = const Duration(seconds: 6),
  });

  /// Minimum wall-clock spacing between two nudges (any class).
  final Duration minGap;

  /// Hard cap on nudges per trip.
  final int maxPerTrip;

  /// Stationary-with-engine-on dwell before the idle nudge fires.
  final Duration idleThreshold;

  /// How long the pedal must stay pinned before the harsh-accel nudge.
  final Duration pedalSpikeSustain;

  /// How long the high-RPM cruise must persist before the shift nudge.
  final Duration highRpmSustain;

  int _fired = 0;
  DateTime? _lastFiredAt;

  DateTime? _idleSince;
  bool _idleNudgedThisEpisode = false;
  DateTime? _pedalHighSince;
  bool _pedalNudgedThisEpisode = false;
  DateTime? _highRpmSince;
  bool _highRpmNudgedThisEpisode = false;

  /// Nudges fired so far this trip (diagnostics / tests).
  int get firedCount => _fired;

  /// Feed one live reading; returns the nudge to show, or null.
  EcoNudgeType? onReading(TripLiveReading reading, DateTime now) {
    final candidate = _updateEpisodes(reading, now);
    if (candidate == null) return null;
    if (!_allowedNow(now)) return null;
    _fired++;
    _lastFiredAt = now;
    _markEpisodeNudged(candidate);
    return candidate;
  }

  /// Forget all trip state — call when a new recording starts.
  void reset() {
    _fired = 0;
    _lastFiredAt = null;
    _idleSince = null;
    _idleNudgedThisEpisode = false;
    _pedalHighSince = null;
    _pedalNudgedThisEpisode = false;
    _highRpmSince = null;
    _highRpmNudgedThisEpisode = false;
  }

  bool _allowedNow(DateTime now) {
    if (_fired >= maxPerTrip) return false;
    final last = _lastFiredAt;
    if (last != null && now.difference(last) < minGap) return false;
    return true;
  }

  void _markEpisodeNudged(EcoNudgeType type) {
    switch (type) {
      case EcoNudgeType.idleWaste:
        _idleNudgedThisEpisode = true;
      case EcoNudgeType.harshAccel:
        _pedalNudgedThisEpisode = true;
      case EcoNudgeType.highRpmCruise:
        _highRpmNudgedThisEpisode = true;
    }
  }

  /// Advance the three episode state machines and return the first
  /// candidate whose dwell threshold is crossed and whose episode has
  /// not nudged yet. Priority: harsh accel (most immediate waste) >
  /// high-RPM cruise > idle.
  EcoNudgeType? _updateEpisodes(TripLiveReading r, DateTime now) {
    final speed = r.speedKmh;
    final rpm = r.rpm;
    final pedal = r.pedalPercent ?? r.throttlePercent;

    // -- harsh accel episode ------------------------------------------
    final pedalHigh = pedal != null && pedal >= 85.0;
    if (pedalHigh) {
      _pedalHighSince ??= now;
    } else {
      _pedalHighSince = null;
      _pedalNudgedThisEpisode = false;
    }

    // -- high-RPM cruise episode --------------------------------------
    final highRpmCruise = rpm != null &&
        rpm >= 2800 &&
        speed != null &&
        speed >= 30 &&
        (pedal == null || pedal < 50);
    if (highRpmCruise) {
      _highRpmSince ??= now;
    } else {
      _highRpmSince = null;
      _highRpmNudgedThisEpisode = false;
    }

    // -- idle episode ---------------------------------------------------
    final idling = speed != null && speed <= 2.0 && rpm != null && rpm > 0;
    if (idling) {
      _idleSince ??= now;
    } else {
      _idleSince = null;
      _idleNudgedThisEpisode = false;
    }

    if (!_pedalNudgedThisEpisode &&
        _pedalHighSince != null &&
        now.difference(_pedalHighSince!) >= pedalSpikeSustain) {
      return EcoNudgeType.harshAccel;
    }
    if (!_highRpmNudgedThisEpisode &&
        _highRpmSince != null &&
        now.difference(_highRpmSince!) >= highRpmSustain) {
      return EcoNudgeType.highRpmCruise;
    }
    if (!_idleNudgedThisEpisode &&
        _idleSince != null &&
        now.difference(_idleSince!) >= idleThreshold) {
      return EcoNudgeType.idleWaste;
    }
    return null;
  }
}
