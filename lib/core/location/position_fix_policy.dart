// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/geo_utils.dart';

/// How old a RETURNED sample may be and still count as "where I am"
/// (#4432).
///
/// A location call returning is not a promise of a new measurement —
/// Android's fused provider documents that a current-location request
/// may be answered from a recent cached fix, and the shared position
/// stream replays its last fix to a late joiner — so only
/// `Position.timestamp` is evidence of freshness. At 130 km/h a vehicle
/// covers ~2.2 km a minute, so 90 s is ~3 km of uncertainty: enough to
/// keep a warm fix, far too little to let the 37-minute snapshot of the
/// field report through.
///
/// Lives in core (not in route_search) because two features judge fixes
/// by it: the route origin resolver and the route map's device marker.
const Duration kRouteOriginMaxFixAge = Duration(seconds: 90);

/// Worst estimated horizontal accuracy, in metres, a fix may carry and
/// still stand as the current position (#4432).
///
/// The location service asks for `medium` accuracy on purpose (~100 m is
/// ample for a road-snapped route start). 500 m allows for a
/// cell-assisted first fix and still rejects the coarse network guesses
/// that would snap the origin onto the wrong road. A non-positive
/// accuracy means the platform did not estimate one; that is unknown,
/// not good, but it is not on its own a reason to reject a fix whose
/// timestamp is fresh.
const double kRouteOriginMaxAccuracyMeters = 500;

/// Why a sample may not stand as the current position (#4432).
enum FixRejection {
  /// `(0,0)`, a one-axis-unacquired `(lat,0)`, NaN or out of range
  /// (#2872).
  unusableCoordinate,

  /// Measured longer than [kRouteOriginMaxFixAge] ago.
  tooOld,

  /// Timestamped further in the future than clock skew explains — a
  /// broken clock, not a fresh fix.
  fromTheFuture,

  /// Estimated accuracy worse than [kRouteOriginMaxAccuracyMeters].
  tooCoarse,
}

/// The reason [position], measured at its own `timestamp`, may NOT stand
/// as "where the vehicle is" at [now] — or null when it may.
FixRejection? rejectFix(Position position, DateTime now) {
  if (!isUsableCoord(position.latitude, position.longitude)) {
    return FixRejection.unusableCoordinate;
  }
  final accuracy = position.accuracy;
  if (accuracy.isFinite &&
      accuracy > 0 &&
      accuracy > kRouteOriginMaxAccuracyMeters) {
    return FixRejection.tooCoarse;
  }
  final age = now.difference(position.timestamp);
  // Allow only the small skew a device/GPS clock difference can produce.
  if (age.isNegative) {
    return age.abs() <= kRouteOriginMaxFixAge
        ? null
        : FixRejection.fromTheFuture;
  }
  return age <= kRouteOriginMaxFixAge ? null : FixRejection.tooOld;
}

/// Whether [position] may stand as the current position at [now]
/// (#4432). Exposed so the thresholds can be tested on both sides of
/// each bound without driving a location service.
bool acceptAsCurrentFix(Position position, DateTime now) =>
    rejectFix(position, now) == null;

/// A device position that passed [rejectFix] when it arrived (#4432).
///
/// Carries its own measurement time so a surface can keep asking "is it
/// still current?" — a fix accepted a minute ago is not current forever.
@immutable
class AcceptedDeviceFix {
  const AcceptedDeviceFix({
    required this.position,
    required this.measuredAt,
    this.accuracyMeters,
  });

  /// Accept [position] if it may stand as current at [now], else null.
  static AcceptedDeviceFix? tryAccept(Position position, DateTime now) {
    if (rejectFix(position, now) != null) return null;
    final accuracy = position.accuracy;
    return AcceptedDeviceFix(
      position: LatLng(position.latitude, position.longitude),
      measuredAt: position.timestamp,
      accuracyMeters: accuracy.isFinite && accuracy > 0 ? accuracy : null,
    );
  }

  final LatLng position;
  final DateTime measuredAt;

  /// Null when the platform did not estimate one.
  final double? accuracyMeters;

  /// How long this fix stays current, measured from [now]. Zero or
  /// negative once it has aged past [kRouteOriginMaxFixAge].
  Duration remainingAt(DateTime now) =>
      measuredAt.add(kRouteOriginMaxFixAge).difference(now);

  bool isCurrentAt(DateTime now) => !remainingAt(now).isNegative;
}
