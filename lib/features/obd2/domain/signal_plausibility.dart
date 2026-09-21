// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'fuel_mixture_model.dart';
import 'fuel_rate_estimator.dart';

/// Whether a reading's value sits inside the band its consumer trusts
/// (#4159).
///
/// A band check MARKS a value; it never replaces it. The fuel math keeps
/// its clamps — the numbers it produces do not change — but a value the
/// clamp would pull in is an adapter or sensor fault worth seeing, so the
/// unclamped value travels with this mark instead of disappearing into
/// the clamp.
enum SignalPlausibility {
  /// No band is defined for this signal (most signals).
  notChecked,

  /// Inside the band.
  plausible,

  /// Outside the band — the consumer's clamp would have hidden it.
  implausible,
}

SignalPlausibility _inBand(double v, double min, double max) =>
    v >= min && v <= max
        ? SignalPlausibility.plausible
        : SignalPlausibility.implausible;

/// A commanded (or petrol measured) equivalence ratio φ against the band
/// `effectiveAfrForPhi` clamps to: [kMinCommandedPhi] … [kMaxCommandedPhi],
/// inclusive.
SignalPlausibility classifyCommandedPhi(double phi) =>
    _inBand(phi, kMinCommandedPhi, kMaxCommandedPhi);

/// A MEASURED wideband φ against the band `effectiveAfrForMixture` clamps
/// it to: the diesel band ([kMinDieselMeasuredPhi] …
/// [kMaxDieselMeasuredPhi]) when the resolved fuel is diesel, else the
/// commanded band.
SignalPlausibility classifyMeasuredPhi(double phi, {required bool isDiesel}) =>
    isDiesel
        ? _inBand(phi, kMinDieselMeasuredPhi, kMaxDieselMeasuredPhi)
        : classifyCommandedPhi(phi);

/// An absolute barometric pressure against the air-density factor band
/// `estimateFuelRateLPerHourFromMap` clamps `baroKpa / kSeaLevelBaroKpa`
/// to: [kMinBaroDensityFactor] … [kMaxBaroDensityFactor], inclusive.
SignalPlausibility classifyBaroKpa(double baroKpa) => _inBand(
      baroKpa / kSeaLevelBaroKpa,
      kMinBaroDensityFactor,
      kMaxBaroDensityFactor,
    );
