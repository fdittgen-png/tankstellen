// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4221 — a stationary engine-on stretch is avoidable idling only when it
/// runs this long without moving: longer than a traffic-light cycle or a
/// queue step. Shorter stops are traffic, not a lesson.
const double kAvoidableIdleMinSeconds = 120;

/// Accumulates idle time that is a lesson rather than traffic (#4221).
///
/// Feed every stationary engine-on interval to [addIdle] and call [endRun]
/// whenever the car moves (and once at the end of the trip). A run shorter
/// than [kAvoidableIdleMinSeconds] is discarded; longer runs add to
/// [seconds] / [liters].
class AvoidableIdle {
  AvoidableIdle({required this.fallbackRateLPerHour});

  /// Burn rate assumed for an interval with no measured fuel rate.
  final double fallbackRateLPerHour;

  double _seconds = 0;
  double _liters = 0;
  bool _measured = true;
  int _episodes = 0;

  double _runSeconds = 0;
  double _runLiters = 0;
  bool _runMeasured = true;

  /// Avoidable idle seconds.
  double get seconds => _seconds;

  /// Litres over [seconds] — measured where a rate was, assumed elsewhere.
  double get liters => _liters;

  /// True when every counted interval carried a measured fuel rate.
  bool get measured => _episodes > 0 && _measured;

  /// Long idle runs counted.
  int get episodes => _episodes;

  /// One stationary engine-on interval of [dt] seconds.
  void addIdle(double dt, double? rateLPerHour) {
    _runSeconds += dt;
    if (rateLPerHour != null && rateLPerHour > 0) {
      _runLiters += rateLPerHour * dt / 3600.0;
    } else {
      _runMeasured = false;
      _runLiters += fallbackRateLPerHour * dt / 3600.0;
    }
  }

  /// The car moved (or the trip ended): keep the run only if it was long.
  void endRun() {
    if (_runSeconds >= kAvoidableIdleMinSeconds) {
      _seconds += _runSeconds;
      _liters += _runLiters;
      _measured = _measured && _runMeasured;
      _episodes++;
    }
    _runSeconds = 0;
    _runLiters = 0;
    _runMeasured = true;
  }
}
