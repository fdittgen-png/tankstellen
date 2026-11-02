// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'trip_fuel_source.dart';
import 'trip_sample.dart';

/// Air-derived flow cannot observe injector shutoff. A positive engine RPM
/// also prevents engine-off transport from being called fuel-cut coasting.
bool isFuelCutObservable(TripSample s) =>
    (s.rpm ?? 0) > 0 &&
    s.fuelRateLPerHour != null &&
    s.fuelRateLPerHour!.isFinite &&
    s.fuelRateLPerHour! >= 0 &&
    kMeasuredFuelSourceTags.contains(s.fuelSource);

bool isObservedFuelCut(
  TripSample s, {
  double maximumRate = 0.1,
  double minimumSpeed = 20,
}) =>
    isFuelCutObservable(s) &&
    s.fuelRateLPerHour! < maximumRate &&
    s.speedKmh > minimumSpeed;

/// Stored PID 44 is raw OBD lambda. True phi is its reciprocal.
/// Reject implausible replies rather than scoring them as enrichment.
bool isRichCommandedLambda(double? lambda, {double threshold = 1}) =>
    lambda != null &&
    lambda.isFinite &&
    lambda >= 1 / 1.5 &&
    lambda < threshold;
