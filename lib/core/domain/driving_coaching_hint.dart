// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Eco-driving coaching hint emitted from a live OBD2 reading (#2007).
///
/// Three conservative hints; everything else (silence) is the default
/// outcome of `coachingHint`. False suggestions are worse than missed
/// ones — the user is supposed to trust the chip when it shows.
///
/// #3743 — moved from `consumption/domain/driving_coaching.dart` into the
/// domain kernel: the obd2 recording controller exposes the latest hint
/// through its `TripGpsEstimateOverlay` seam, and a shared value type in
/// `lib/core/domain` is the sanctioned way to break that cross-feature
/// import (the #3614 BrandRegistry pattern). Consumption re-exports it
/// from `driving_coaching.dart` so its existing import sites are
/// unchanged.
enum DrivingCoachingHint {
  /// Engine is spinning much higher than needed for the cruising
  /// speed → next gear up would drop RPM into a more efficient range.
  shiftUp,

  /// Engine is bogging at very low RPM while the driver is asking for
  /// real torque — the car is in too high a gear under load.
  shiftDown,

  /// Throttle is wide open during an aggressive cruise / acceleration
  /// AND the live consumption band is already heavy. Backing off the
  /// pedal would cut burn rate without losing real progress.
  easePedal,

  /// GPS-only coaching (#2058) — fires when the driver is at cruise
  /// speed and the altitude trace is descending, with no recent brake
  /// event. Suggests lifting off the throttle to coast.
  gpsLiftOffCoast,

  /// GPS-only (#2058) — fires when a brake event > 2 m/s² was
  /// detected in the last few seconds. Suggests reading the road
  /// further ahead and starting the lift-off earlier next time.
  gpsAnticipateBrake,

  /// GPS-only (#2058) — fires when an acceleration event > 2 m/s²
  /// was detected in the last few seconds. Suggests a gentler ramp.
  gpsSmoothAccel,
}
