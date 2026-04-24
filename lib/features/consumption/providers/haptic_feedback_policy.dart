import '../domain/cold_start_baselines.dart';

/// Haptic strength emitted when the consumption band changes (#767).
enum HapticIntensity { none, light, medium }

/// Decide which haptic (if any) fires when [previous] transitions to
/// [current]. Pure function: no platform calls, easily unit-tested.
/// Only escalations vibrate — heavy or worse. Positive transitions
/// (eco / normal) stay silent so the feedback is a corrective nudge,
/// not constant noise.
HapticIntensity hapticForBandTransition(
  ConsumptionBand previous,
  ConsumptionBand current,
) {
  if (previous == current) return HapticIntensity.none;
  if (current == ConsumptionBand.veryHeavy &&
      previous != ConsumptionBand.veryHeavy) {
    return HapticIntensity.medium;
  }
  if (current == ConsumptionBand.heavy &&
      previous != ConsumptionBand.heavy &&
      previous != ConsumptionBand.veryHeavy) {
    return HapticIntensity.light;
  }
  return HapticIntensity.none;
}
