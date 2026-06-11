// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:geolocator/geolocator.dart';

import '../domain/station.dart';

/// State emitted by [ApproachDetector] (#2085 / ADR 0011) — split out of
/// `approach_detector.dart` so the state hierarchy lives apart from the
/// detector's logic (#3092). Re-exported by `approach_detector.dart`, so
/// existing imports of that file still see these types.
///
/// Sealed hierarchy — the consumer (the PiP overlay in #2084) picks
/// its UI on the runtime subtype:
///
/// - [ApproachIdle] — no GPS fix yet, or detector not running.
/// - [ApproachPolling] — GPS available, no station in radius. The
///   overlay shows the default "huge L/100 km" view from #2068.
/// - [ApproachInRadius] — driver is inside the configured radius of
///   a target station. The overlay flips to the huge-price view.
/// - [ApproachLeaving] — radius exit was detected, but the 5 s
///   grace window is still open. The overlay keeps showing the
///   price until the grace expires or the radius is re-entered.
sealed class ApproachState {
  const ApproachState();
}

/// No GPS fix / detector not yet receiving samples.
class ApproachIdle extends ApproachState {
  const ApproachIdle();
}

/// GPS is producing samples but no station is in the radius right now.
class ApproachPolling extends ApproachState {
  final Position gps;
  final Duration nextPollIn;
  const ApproachPolling({required this.gps, required this.nextPollIn});
}

/// A target station is in the configured radius.
class ApproachInRadius extends ApproachState {
  final Station station;
  final double distanceMeters;
  const ApproachInRadius({
    required this.station,
    required this.distanceMeters,
  });
}

/// Grace period after exit — the overlay keeps the price visible for
/// [ApproachDetector.exitGrace] before falling back to [ApproachPolling].
class ApproachLeaving extends ApproachState {
  final Station lastStation;
  const ApproachLeaving({required this.lastStation});
}
