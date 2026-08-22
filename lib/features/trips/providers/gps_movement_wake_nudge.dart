// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3570 — sustained-movement wake nudge for a parked OBD2 link.
///
/// A supervisor parked in `engineOff` never re-arms on its own; sustained
/// supra-threshold GPS speed during an active GPS-only recording is proof
/// the engine is running, so the recording pipeline nudges `wake()`.
/// Throttled so a genuinely absent adapter costs one dial ladder per
/// [nudgeInterval], not one per GPS fix. Pure counter + clock state —
/// the pipeline injects the [wake] callback (and tests a fake [now]),
/// keeping this file free of any OBD2 import.
class GpsMovementWakeNudge {
  GpsMovementWakeNudge({
    required this.wake,
    this.speedThresholdKmh = 10,
    this.consecutiveSamples = 5,
    this.nudgeInterval = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Invoked on a sustained-movement window. The caller wires this to
  /// `Obd2LinkSupervisor.wake()`, which no-ops unless parked.
  final void Function() wake;

  final double speedThresholdKmh;
  final int consecutiveSamples;
  final Duration nudgeInterval;
  final DateTime Function() _now;

  int _supraCount = 0;
  DateTime? _lastNudge;

  /// Feed one GPS ground-speed sample (km/h).
  void onSpeed(double speedKmh) {
    if (speedKmh < speedThresholdKmh) {
      _supraCount = 0;
      return;
    }
    if (++_supraCount < consecutiveSamples) return;
    final now = _now();
    final last = _lastNudge;
    if (last != null && now.difference(last) < nudgeInterval) return;
    _lastNudge = now;
    wake();
  }
}
