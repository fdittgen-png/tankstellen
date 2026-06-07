// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Engine-power scaling for the hard-acceleration penalty (Epic #3015).
///
/// ## Why hard-accel waste depends on engine power
///
/// At the SAME acceleration intensity, a lower-powered car is operating at a
/// higher fraction of its maximum capability than a higher-powered one. To
/// deliver that torque it sits closer to wide-open throttle, in a less
/// efficient region of its brake-specific-fuel-consumption (BSFC) map, and is
/// more likely to drift into mixture enrichment (λ < 1) for component
/// protection. A strong engine produces the same acceleration well within its
/// efficient mid-load island, with little to no enrichment.
///
/// So an identical "hard pull" costs a small engine proportionally MORE fuel
/// than a big one — exactly the maintainer's requirement: *"ein niedrig
/// motorisiertes Fahrzeug verbraucht beim harten Beschleunigen proportional
/// mehr als ein hochmotorisiertes"*. The hard-accel penalty (and the linked
/// hard-accel wasted-fuel estimate) is therefore weighted by a factor that
/// scales INVERSELY with engine power.
///
/// ## The factor
///
/// `f = clamp(kReferenceEnginePowerKw / enginePowerKw, fMin, fMax)`
///
///   * a car at the reference power gets `f == 1.0` — today's penalty, unchanged;
///   * a low-power car gets `f > 1` — a bigger penalty per event;
///   * a high-power car gets `f < 1` — a smaller penalty per event.
///
/// The clamp keeps the weight physically defensible at the catalog extremes
/// (a 33 kW city car would otherwise reach 3× and a future 400 kW outlier
/// would vanish to near zero).
///
/// ## Backward compatibility
///
/// When `enginePowerKw` is unknown (`null`) or non-physical (`<= 0`), the
/// factor is exactly `1.0`, so every score computed before the user set an
/// engine-power value — and every car whose power we cannot resolve — keeps
/// its current, byte-identical penalty. This is the safe identity element.
library;

/// Neutral reference engine power, in kW. A car at this power keeps today's
/// hard-accel penalty unchanged (`f == 1.0`).
///
/// Calibrated from the shipped reference-vehicle catalog (Epic #3015 added
/// kW to all 328 non-EV rows): median 82 kW, mean 86 kW, p75 103 kW. The
/// catalog over-represents small European city cars, so the central tendency
/// of *cars people actually drive hard* sits a little higher. 100 kW (≈ 136
/// PS) is the round mainstream value just above the catalog mean — a typical
/// modern compact/family petrol — and gives intuitive ratios (a 50 kW car →
/// 2×, a 200 kW car → 0.5× before clamping).
const int kReferenceEnginePowerKw = 100;

/// Lower bound on the power factor (applied to strong engines). 0.6 means a
/// hard pull in a very powerful car still carries 60 % of the reference
/// penalty — it is more efficient, not free. Reached around ~167 kW
/// (`100 / 0.6`), i.e. the top of the current catalog and above.
const double kEnginePowerFactorMin = 0.6;

/// Upper bound on the power factor (applied to weak engines). 1.8 means the
/// smallest engines are penalised up to 80 % more per hard-accel event than
/// the reference, without the runaway 3×+ a 33 kW kei-class car would
/// otherwise hit. Reached at/below ~56 kW (`100 / 1.8`).
const double kEnginePowerFactorMax = 1.8;

/// The inverse-power weight for the hard-acceleration penalty / waste
/// (Epic #3015). See the library doc-comment for the model.
///
/// Returns exactly `1.0` (the identity) when [enginePowerKw] is `null` or
/// non-physical (`<= 0`) — so legacy / power-unknown trips are unchanged.
/// Otherwise `clamp(kReferenceEnginePowerKw / enginePowerKw,
/// kEnginePowerFactorMin, kEnginePowerFactorMax)`.
double enginePowerAccelFactor(int? enginePowerKw) {
  if (enginePowerKw == null || enginePowerKw <= 0) return 1.0;
  final raw = kReferenceEnginePowerKw / enginePowerKw;
  if (raw < kEnginePowerFactorMin) return kEnginePowerFactorMin;
  if (raw > kEnginePowerFactorMax) return kEnginePowerFactorMax;
  return raw;
}
