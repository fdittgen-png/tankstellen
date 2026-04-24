import '../../../vehicle/domain/entities/vehicle_profile.dart';

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

/// `true` when [vehicle]'s preferred fuel type reads like a diesel
/// variant (#800). Matching is done on the normalised string instead
/// of a typed enum because `preferredFuelType` is a free-text field
/// populated from several sources (user onboarding, VIN decoder,
/// home-widget mirror) — all of which use `"diesel"` /
/// `"dieselPremium"` as the key. Returns `false` for null, empty, or
/// any non-diesel value (which is the safe default — petrol AFR /
/// density produce slightly lower L/h numbers than diesel at the
/// same MAF, so under-counting is preferable to over-counting).
bool isDieselProfile(VehicleProfile? vehicle) {
  final key = vehicle?.preferredFuelType?.trim().toLowerCase();
  if (key == null || key.isEmpty) return false;
  return key.contains('diesel');
}

/// Pure-math fuel-trim correction factor (#813). Exposed for unit
/// tests and for callers that already hold the trim values.
///
/// Formula: `corrected = raw × (1 + (STFT + LTFT) / 100)`. Positive
/// trims mean the ECU is enriching the mixture — real fuel flow is
/// higher than what stoichiometric math predicts. Negative trims
/// mean the opposite. Summing STFT and LTFT is standard practice
/// (HEM Data's canonical formula); they capture fast and slow
/// corrections respectively.
double applyFuelTrimCorrection(
  double raw, {
  required double stft,
  required double ltft,
}) {
  return raw * (1.0 + (stft + ltft) / 100.0);
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
}) {
  final iatKelvin = iatCelsius + 273.15;
  if (mapKpa <= 0 ||
      iatKelvin <= 0 ||
      rpm <= 0 ||
      engineDisplacementCc <= 0 ||
      volumetricEfficiency <= 0) {
    return null;
  }
  final mapPa = mapKpa * 1000.0;
  final displacementM3 = engineDisplacementCc / 1_000_000.0;
  final intakesPerSecond = rpm / 120.0;
  // Kilograms of air per second (ideal gas law × VE).
  final airMassKgPerS =
      (mapPa * displacementM3 * intakesPerSecond * volumetricEfficiency) /
          (_gasConstant * iatKelvin);
  final airMassGPerS = airMassKgPerS * 1000.0;
  return airMassGPerS * 3600.0 / (afr * fuelDensityGPerL);
}
