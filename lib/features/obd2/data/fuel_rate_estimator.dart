// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../core/domain/vehicle_profile.dart';

/// Pure-math fuel-rate estimator + stoichiometric constants (#800,
/// #810, #812, #813). Extracted from `obd2_service.dart` as part of
/// the #563 service-split refactor so the speed-density math and the
/// AFR / density constants can be unit-tested in isolation, shared
/// across consumers ([TripRecordingController] re-implements the same
/// branches on cached live samples), and mutated without touching the
/// transport-coupled [Obd2Service].
///
/// `Obd2Service` still re-exposes the constants and functions as
/// static members so existing callers keep compiling — see the
/// forwarders in `obd2_service.dart`.

/// Stoichiometric AFR for petrol / gasoline (#800). Approximately
/// 14.7 kg of air per kg of fuel at perfect combustion.
const double kPetrolAfr = 14.7;

/// Stoichiometric AFR for diesel (#800). Slightly leaner burn than
/// petrol — ~14.5 kg of air per kg of diesel.
const double kDieselAfr = 14.5;

/// Petrol density in g/L at ~15 °C (#800). Published range
/// 720–775 g/L; 740 is the legacy Tankstellen constant, kept stable
/// so pre-#800 fuel-rate samples don't shift by ~0.7 % after the
/// diesel branch landed.
const double kPetrolDensityGPerL = 740.0;

/// Diesel density in g/L at ~15 °C (#800). Denser than petrol at
/// ~820–845 g/L; 832 is the EN 590 reference point.
const double kDieselDensityGPerL = 832.0;

/// Stoichiometric AFR for E85 (#2432). ~9.8 kg of air per kg of fuel —
/// far richer than petrol because ethanol is partially oxygenated and
/// needs much less air to burn completely. Sources put pure-ethanol
/// stoich at ~9.0 and the E85 blend (≈85 % ethanol / 15 % petrol) at
/// 9.7–9.9; 9.8 is the commonly cited blend figure. This low AFR is
/// the whole point of #2432: the old binary diesel/petrol branch sent
/// E85 down the petrol path (14.7), which divides the air-mass flow by
/// a ~50 % larger denominator and under-counts E85 L/h by ~33 %.
const double kE85Afr = 9.8;

/// E85 density in g/L at ~15 °C (#2432). Ethanol is ~789 g/L and the
/// petrol fraction is lighter, so the E85 blend lands near 781–785;
/// 785 is the representative value used here.
const double kE85DensityGPerL = 785.0;

/// Stoichiometric AFR for LPG / autogas (#2432). A propane/butane mix
/// burns at ~15.5–15.7 kg air per kg fuel; 15.6 is the common autogas
/// figure.
const double kLpgAfr = 15.6;

/// LPG (autogas) liquid density in g/L at ~15 °C (#2432). In the tank
/// LPG is a pressurised liquid at ~510–570 g/L depending on the
/// propane/butane ratio; 535 is a representative European autogas
/// value. The speed-density model emits L/h, and an LPG vehicle's
/// fuel system meters liquid from the tank, so the liquid density is
/// the correct denominator here.
const double kLpgDensityGPerL = 535.0;

/// Stoichiometric AFR for CNG (compressed natural gas, ~methane)
/// (#2432). ~17.2 kg air per kg fuel — the leanest of the common road
/// fuels.
///
/// NOTE: CNG is gaseous and is metered / sold by mass (kg) or by
/// standard cubic metre (m³ at a reference pressure), never by litre.
/// There is no meaningful "litres of CNG per hour" that maps onto a
/// liquid-density `g/L` denominator the way petrol / diesel / E85 / LPG
/// do: plugging a liquid-like density into
/// [estimateFuelRateLPerHourFromMap] would emit a number whose unit
/// isn't L/h at all. Rather than invent a fake density and silently
/// mis-scale (the exact failure #2432 fixes for E85),
/// [resolveAfrDensity] treats CNG as the petrol default (matching the
/// documented "unknown → petrol, safer to under-count" rule), so the
/// emitted figure stays a defined petrol-equivalent L/h rather than a
/// unit-less artefact. [kCngAfr] / [kCngEquivalentDensityGPerL] are
/// exposed for a future native-units (kg/m³) follow-up. See #2432.
const double kCngAfr = 17.2;

/// Petrol-equivalent density used for CNG (#2432). CNG has no
/// meaningful liquid g/L (see [kCngAfr]); we reuse the petrol density
/// so the L/h figure stays a defined petrol-equivalent rather than a
/// silently mis-scaled artefact.
const double kCngEquivalentDensityGPerL = kPetrolDensityGPerL;

/// Fallback engine displacement used by the speed-density fuel-rate
/// estimator when the active vehicle profile doesn't expose one
/// (#810, #812). 1000 cc = 1.0 L NA petrol — matches the Peugeot 107
/// / Aygo / C1 class that originally motivated the fallback. Kept as
/// a named constant so the no-profile case is obvious at a glance
/// and easy to update if the default assumption ever changes.
const int kDefaultEngineDisplacementCc = 1000;

/// Fallback volumetric efficiency for the speed-density estimator
/// (#810, #812). 0.85 is a sensible midpoint for a NA petrol engine
/// at cruise; adaptive calibration (#815) will later narrow this per
/// vehicle from tankful reconciliation.
const double kDefaultVolumetricEfficiency = 0.85;

/// Specific gas constant for dry air in J/(kg·K). Used by the
/// ideal-gas-law air-mass step of [estimateFuelRateLPerHourFromMap].
const double _gasConstant = 287.0;

/// Reference sea-level barometric pressure (kPa) for the speed-density
/// air-density correction (#2456). When PID 0x33 (absolute baro) is
/// available, the air charge is scaled by `baroKpa / kSeaLevelBaroKpa`
/// so altitude / weather correctly reduce (or raise) the air mass — and
/// therefore the fuel — versus the implicit sea-level assumption the
/// pre-#2456 formula carried. 101.325 kPa is the ISA standard.
const double kSeaLevelBaroKpa = 101.325;

/// Lower clamp for the commanded equivalence ratio λ (PID 0x44, #2456).
/// Real mixtures never run leaner than ~0.5 in normal operation; a value
/// below this is garbage (stuck sensor / parse noise) and is rejected so
/// it can't blow up the effective-AFR denominator.
const double kMinLambda = 0.5;

/// Upper clamp for the commanded equivalence ratio λ (#2456). Power
/// enrichment rarely exceeds ~1.3–1.4; 1.5 is a generous ceiling that
/// still rejects obvious garbage.
const double kMaxLambda = 1.5;

/// Translate a stoichiometric AFR into the effective AFR the ECU is
/// actually commanding, given the commanded equivalence ratio λ
/// (PID 0x44, #2456).
///
/// Convention used here (matching the SAE PID 0x44 semantics the app
/// targets): λ > 1 is power-enrichment — the engine is burning a richer
/// mixture, i.e. *more* fuel per unit air, so the effective AFR is
/// *lower*; λ < 1 is a lean cruise mixture (less fuel, higher AFR).
/// Because the fuel-rate math divides the air mass by the AFR, an
/// effective AFR of `stoichAfr / λ` makes the derived fuel scale up with
/// λ (λ = 1.2 → ~20 % more fuel) and down for lean cruise — the
/// accuracy win this PID buys on cars without a direct fuel-rate or MAF
/// PID (the Peugeot speed-density path).
///
/// [lambda] is clamped to [kMinLambda] … [kMaxLambda] to reject garbage
/// before it reaches the denominator. A null [lambda] returns
/// [stoichAfr] unchanged so a car that doesn't expose PID 0x44 derives
/// fuel exactly as it did before #2456.
double effectiveAfrForLambda(double stoichAfr, double? lambda) {
  if (lambda == null) return stoichAfr;
  final clamped = lambda.clamp(kMinLambda, kMaxLambda);
  return stoichAfr / clamped;
}

/// Single source of truth for the (AFR, density) pair the MAF /
/// speed-density fuel-rate math divides by (#2432). Both
/// [Obd2Service.readFuelRateLPerHour] and
/// [LiveSampleSnapshot.deriveFuelRateLPerHour] call this so the live
/// integrator and the pull-mode estimator can never disagree on which
/// fuel a tick is scaled for.
///
/// Resolution order:
///   1. [VehicleProfile.manualAfrOverride] /
///      [VehicleProfile.manualFuelDensityGPerLOverride] win whenever
///      set — the user pinned them through the calibration card and
///      they must beat any inferred value. Either can be set
///      independently; an unset one falls through to the mapped value.
///   2. otherwise the free-text [VehicleProfile.preferredFuelType] (or
///      the optional [fallbackFuelType], used when there is no profile
///      but a reference-catalog row carries a fuel string) is normalised
///      and mapped to the matching constants.
///   3. null / empty / unrecognised → petrol defaults. Petrol is the
///      safe default the pre-#800 path used: at the same MAF it produces
///      slightly lower L/h than diesel, so an unknown fuel under-counts
///      rather than over-counts.
///
/// Matching is on the normalised string rather than a typed enum
/// because `preferredFuelType` is free text populated from several
/// sources (user onboarding, VIN decoder, home-widget mirror) using a
/// handful of key spellings. `contains` is used for diesel so the
/// `"dieselPremium"` variant matches; the other branches match the
/// known key spellings explicitly.
///
/// Before #2432 the callers used a binary diesel-vs-petrol branch, so
/// E85 / LPG / CNG silently fell into the petrol default and
/// under-counted (E85 by ~33 %). This lookup fixes that under-count.
({double afr, double densityGPerL}) resolveAfrDensity(
  VehicleProfile? vehicle, {
  String? fallbackFuelType,
}) {
  final overrideAfr = vehicle?.manualAfrOverride;
  final overrideDensity = vehicle?.manualFuelDensityGPerLOverride;

  final key = (vehicle?.preferredFuelType ?? fallbackFuelType)
      ?.trim()
      .toLowerCase();
  final mapped = _afrDensityForFuelKey(key);

  return (
    afr: overrideAfr ?? mapped.afr,
    densityGPerL: overrideDensity ?? mapped.densityGPerL,
  );
}

/// Maps a normalised free-text fuel key to its (AFR, density) pair
/// (#2432). Returns the petrol defaults for null / empty / unknown.
({double afr, double densityGPerL}) _afrDensityForFuelKey(String? key) {
  if (key == null || key.isEmpty) {
    return (afr: kPetrolAfr, densityGPerL: kPetrolDensityGPerL);
  }
  // Diesel uses `contains` so the `"dieselPremium"` variant matches.
  if (key.contains('diesel')) {
    return (afr: kDieselAfr, densityGPerL: kDieselDensityGPerL);
  }
  if (key.contains('e85') || key.contains('ethanol')) {
    return (afr: kE85Afr, densityGPerL: kE85DensityGPerL);
  }
  if (key.contains('lpg') || key.contains('autogas')) {
    return (afr: kLpgAfr, densityGPerL: kLpgDensityGPerL);
  }
  // CNG is gaseous (no meaningful liquid g/L) → petrol default, matching
  // the documented "unknown → petrol, safer to under-count" rule
  // (obd2_service_maf_fallback_test). [kCngAfr] is exposed for a future
  // native-units (kg/m³) follow-up — see #2432.
  // petrol / e10 / e5 / super / gasoline / cng / any unknown value.
  return (afr: kPetrolAfr, densityGPerL: kPetrolDensityGPerL);
}

/// Pure-math fuel-trim correction factor (#813, bank-2 #2458). Exposed
/// for unit tests and for callers that already hold the trim values.
///
/// Formula: `corrected = raw × (1 + meanTrim / 100)`, where `meanTrim`
/// is the bank-averaged sum of short- + long-term trims. Positive trims
/// mean the ECU is enriching the mixture — real fuel flow is higher than
/// what stoichiometric math predicts. Negative trims mean the opposite.
/// Summing STFT and LTFT is standard practice (HEM Data's canonical
/// formula); they capture fast and slow corrections respectively.
///
/// #2458 — when the car exposes bank-2 trims ([stftBank2] / [ltftBank2],
/// PIDs 08 / 09), the two banks' (STFT + LTFT) totals are averaged so a
/// V / boxer engine running asymmetric correction (e.g. bank 1 +6 %,
/// bank 2 −2 %) gets the true mean (+2 %) instead of only bank 1. Either
/// bank-2 trim being null (inline engine, or it hasn't landed yet) falls
/// back to the bank-1-only total — byte-for-byte the pre-#2458 result.
double applyFuelTrimCorrection(
  double raw, {
  required double stft,
  required double ltft,
  double? stftBank2,
  double? ltftBank2,
}) {
  final bank1Total = stft + ltft;
  if (stftBank2 == null || ltftBank2 == null) {
    return raw * (1.0 + bank1Total / 100.0);
  }
  final bank2Total = stftBank2 + ltftBank2;
  final meanTotal = (bank1Total + bank2Total) / 2.0;
  return raw * (1.0 + meanTotal / 100.0);
}

/// Linearly interpolates an η_v(rpm) curve (#1625) at engine speed
/// [rpm].
///
/// The curve must be sorted ascending by `rpm` (as [etaVCurveFor]
/// produces it). Engine speeds below the first point or above the
/// last clamp to that point's η_v — extrapolating a coarse 3-point
/// curve past its span would be guesswork. Returns `null` for an
/// empty curve so callers can fall back to a flat cruise η_v.
double? interpolateEtaV(List<EtaVCurvePoint> curve, double rpm) {
  if (curve.isEmpty) return null;
  if (rpm <= curve.first.rpm) return curve.first.etaV;
  if (rpm >= curve.last.rpm) return curve.last.etaV;
  for (var i = 0; i < curve.length - 1; i++) {
    final a = curve[i];
    final b = curve[i + 1];
    if (rpm >= a.rpm && rpm <= b.rpm) {
      final t = (rpm - a.rpm) / (b.rpm - a.rpm);
      return a.etaV + (b.etaV - a.etaV) * t;
    }
  }
  return curve.last.etaV; // defensive — unreachable for a sorted curve
}

/// Pure-math speed-density fuel-rate estimator (#800). Split out so
/// unit tests can verify the formula without mocking the transport.
///
/// Formula:
///   air_flow_g_per_s = (MAP_Pa × displacement_m³ × (RPM / 120) × η_v)
///                      / (R × IAT_K)
///   fuel_rate_L_per_h = air_flow_g_per_s × 3600 / (AFR × density)
///
/// R = 287 J/(kg·K) is the specific gas constant for dry air.
/// `RPM / 120` converts crank revolutions to intake strokes per
/// second on a 4-stroke engine (one intake per 2 crank revs).
///
/// #1625 — when [etaVCurve] is non-empty the η_v term is interpolated
/// from it at [rpm] (see [interpolateEtaV]) instead of using the flat
/// [volumetricEfficiency]; an empty curve keeps the flat cruise value,
/// so existing callers are unaffected. [volumetricEfficiency] remains
/// the fallback whenever the curve yields nothing.
///
/// #2456 — two optional ECU signals refine the estimate when available
/// and leave it byte-for-byte unchanged when absent:
///   - [lambda] (commanded equivalence ratio, PID 0x44): the [afr] is
///     replaced with [effectiveAfrForLambda]`(afr, lambda)`, so a richer
///     commanded mixture (λ > 1) yields proportionally more fuel and a
///     lean cruise (λ < 1) less. Null → the assumed stoich [afr].
///   - [baroKpa] (absolute barometric pressure, PID 0x33): the air mass
///     is scaled by `baroKpa / kSeaLevelBaroKpa` so altitude / weather
///     correctly thin (or enrich) the charge versus the implicit
///     sea-level assumption. Null → factor 1.0 (today's behaviour). The
///     factor is clamped to a sane 0.6 … 1.1 band so a malformed baro
///     reading can't invert or explode the result.
///
/// Returns null when any input is non-positive — the ideal gas law
/// breaks down at 0 K / 0 pressure and callers should surface "no
/// data" rather than a bogus number.
double? estimateFuelRateLPerHourFromMap({
  required double mapKpa,
  required double iatCelsius,
  required double rpm,
  required int engineDisplacementCc,
  required double volumetricEfficiency,
  double afr = kPetrolAfr,
  double fuelDensityGPerL = kPetrolDensityGPerL,
  List<EtaVCurvePoint> etaVCurve = const [],
  double? baroKpa,
  double? lambda,
}) {
  final iatKelvin = iatCelsius + 273.15;
  if (mapKpa <= 0 ||
      iatKelvin <= 0 ||
      rpm <= 0 ||
      engineDisplacementCc <= 0 ||
      volumetricEfficiency <= 0) {
    return null;
  }
  // #1625 — RPM-aware η_v when a curve is supplied, else the flat value.
  final etaV = interpolateEtaV(etaVCurve, rpm) ?? volumetricEfficiency;
  final mapPa = mapKpa * 1000.0;
  final displacementM3 = engineDisplacementCc / 1_000_000.0;
  final intakesPerSecond = rpm / 120.0;
  // Kilograms of air per second (ideal gas law × VE).
  final airMassKgPerS =
      (mapPa * displacementM3 * intakesPerSecond * etaV) /
          (_gasConstant * iatKelvin);
  // #2456 — ambient air-density correction. A measured baro below sea
  // level (altitude) thins the charge, above raises it; clamped so a
  // garbage reading can't invert or blow up the air mass. Null → 1.0,
  // i.e. the pre-#2456 sea-level assumption, unchanged.
  final baroFactor = baroKpa == null
      ? 1.0
      : (baroKpa / kSeaLevelBaroKpa).clamp(0.6, 1.1);
  final airMassGPerS = airMassKgPerS * 1000.0 * baroFactor;
  // #2456 — when λ (PID 0x44) is present, divide by the ECU's commanded
  // effective AFR instead of the assumed stoich AFR. Null → [afr].
  final effectiveAfr = effectiveAfrForLambda(afr, lambda);
  return airMassGPerS * 3600.0 / (effectiveAfr * fuelDensityGPerL);
}
