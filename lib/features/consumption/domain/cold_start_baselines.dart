import 'situation_classifier.dart';

/// Fuel-type-specific typical consumption for every steady-state
/// driving situation (#768). Used as the cold-start baseline before
/// the Welford-based per-vehicle learned baseline (#769) has enough
/// samples to take over.
///
/// Numbers come from published fleet averages — adjusted slightly
/// up for urban because real-world urban traffic bunches worse than
/// WLTP implies, and down for highway cruise because modern cars
/// with 8+ gears spend most of their highway time in their efficient
/// envelope. Intentionally gasoline/diesel only — LPG/CNG mapped to
/// gasoline as a close-enough approximation because the rounding
/// error at cold start doesn't matter.
enum ConsumptionFuelFamily { gasoline, diesel }

/// Baseline envelope for one situation: a value plus its unit.
/// [unit] decides how the UI formats it — L/100 km for driving,
/// L/h for idle (because L/100 km explodes at zero speed).
enum BaselineUnit { lPer100Km, lPerHour }

class SituationBaseline {
  final double value;
  final BaselineUnit unit;
  const SituationBaseline(this.value, this.unit);
}

/// Typical consumption lookup. Callers pass the resolved fuel family
/// (from the active vehicle profile) + the current driving
/// situation, get back the expected consumption.
SituationBaseline coldStartBaseline(
  ConsumptionFuelFamily family,
  DrivingSituation situation,
) {
  switch (situation) {
    case DrivingSituation.idle:
      return family == ConsumptionFuelFamily.gasoline
          ? const SituationBaseline(0.8, BaselineUnit.lPerHour)
          : const SituationBaseline(0.6, BaselineUnit.lPerHour);
    case DrivingSituation.stopAndGo:
      return family == ConsumptionFuelFamily.gasoline
          ? const SituationBaseline(12.0, BaselineUnit.lPer100Km)
          : const SituationBaseline(9.0, BaselineUnit.lPer100Km);
    case DrivingSituation.urbanCruise:
      return family == ConsumptionFuelFamily.gasoline
          ? const SituationBaseline(7.5, BaselineUnit.lPer100Km)
          : const SituationBaseline(5.5, BaselineUnit.lPer100Km);
    case DrivingSituation.highwayCruise:
      return family == ConsumptionFuelFamily.gasoline
          ? const SituationBaseline(6.0, BaselineUnit.lPer100Km)
          : const SituationBaseline(4.8, BaselineUnit.lPer100Km);
    case DrivingSituation.deceleration:
      return family == ConsumptionFuelFamily.gasoline
          ? const SituationBaseline(3.0, BaselineUnit.lPer100Km)
          : const SituationBaseline(2.2, BaselineUnit.lPer100Km);
    case DrivingSituation.climbingOrLoaded:
      return family == ConsumptionFuelFamily.gasoline
          ? const SituationBaseline(10.0, BaselineUnit.lPer100Km)
          : const SituationBaseline(7.5, BaselineUnit.lPer100Km);
    // Transients don't have a meaningful "baseline" — they just
    // trigger a badge. Return a zero value with the distance unit
    // so callers don't have to special-case; the UI skips the
    // percentage-delta rendering for transients anyway.
    case DrivingSituation.hardAccel:
    case DrivingSituation.fuelCutCoast:
      return const SituationBaseline(0, BaselineUnit.lPer100Km);
  }
}

/// Classify a live reading against a baseline into a consumption
/// band. Used by the banner to pick a colour and by the screen to
/// render the headline metric.
///
/// Boundaries match the addendum on #767: eco ≤ 0.80 × baseline,
/// normal within 0.80–1.20 × baseline, heavy 1.20–1.60, very heavy
/// above 1.60. Transient situations yield [ConsumptionBand.transient].
enum ConsumptionBand { eco, normal, heavy, veryHeavy, transient }

ConsumptionBand classifyBand({
  required DrivingSituation situation,
  required double live,
  required SituationBaseline baseline,
}) {
  if (situation == DrivingSituation.hardAccel ||
      situation == DrivingSituation.fuelCutCoast) {
    return ConsumptionBand.transient;
  }
  if (baseline.value <= 0) return ConsumptionBand.normal;
  final ratio = live / baseline.value;
  if (ratio >= 1.60) return ConsumptionBand.veryHeavy;
  if (ratio >= 1.20) return ConsumptionBand.heavy;
  if (ratio <= 0.80) return ConsumptionBand.eco;
  return ConsumptionBand.normal;
}
