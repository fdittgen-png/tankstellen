// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Fuel-mixture policy for the consumption-precision Epic #3416: the
/// fuel-kind resolution + ethanol blend (#3429), the diesel-aware
/// effective-AFR rule (#3430), the measured-φ preference (#3427) and the
/// mass-based rate conversions (#3428). Pure math / policy — no I/O — so
/// both fuel derivation paths ([LiveSampleSnapshot.deriveFuelRateLPerHour]
/// and [Obd2Service.readFuelRateLPerHour]) call the SAME functions and can
/// never disagree on a scalar.
///
/// ## Diesel accuracy limits (#3430)
///
/// Diesels are lean-burn and (mostly) UNTHROTTLED: load is controlled by
/// injected fuel quantity, not by an intake throttle, so
///   - stoichiometric-AFR division of the air mass does NOT model diesel
///     fuel (the real mixture runs λ ≈ 1.2 … 6 depending on load);
///   - STFT / LTFT closed-loop trims are a petrol stoich-feedback concept
///     and are skipped ([effectiveAfrForMixture] callers gate on
///     [ResolvedFuelKind.diesel]);
///   - COMMANDED equivalence ratio (PID 0x44) is meaningless as a load
///     signal on diesel and is never applied;
///   - the SPEED-DENSITY branch on a diesel yields an AIR-mass-derived
///     UPPER BOUND, not the real fuel: with no throttle plate, MAP ≈ baro
///     at every load, so the air term barely varies while fuel varies
///     ~5×. Only a MEASURED wideband φ (PIDs 0x24–0x2B / 0x34–0x3B) makes
///     the air→fuel step honest — fuel = air × φ / AFR_stoich — which is
///     why diesel uses measured φ when present and otherwise leaves the
///     stoich AFR untouched (a documented over-estimate at part load).
///   Direct mass PIDs (0x9D / 0xA2 / 0x5E) are unaffected — the ECU
///   reports fuel mass itself.
library;

import '../../../core/domain/vehicle_profile.dart';
import 'fuel_rate_estimator.dart';

/// Which fuel-chain branch actually produced a derived rate (#3428 /
/// #3433). The trip recorder stamps this per sample so the
/// driving-analysis export can report the branch that DOMINATED a trip.
///
/// Deliberately a separate enum from the breadcrumb overlay's
/// `Obd2BranchTag` — that enum is switched exhaustively by presentation
/// code owned by the #3431/#3432 agent, so it stays frozen here; this one
/// carries the finer-grained provenance the export needs.
enum FuelRateSourceTag {
  /// PID 0x9D engine fuel rate (g/s → L/h via density only).
  pid9D,

  /// PID 0xA2 cylinder fuel rate (mg/stroke × RPM × cylinders).
  pidA2,

  /// PID 0x5E direct fuel rate (L/h, post-trim).
  pid5E,

  /// MAF-derived, air mass from the dual-sensor PID 0x66.
  maf66,

  /// MAF-derived, air mass from the legacy PID 0x10.
  maf,

  /// Speed-density estimate (MAP + IAT + RPM ideal-gas air mass).
  speedDensity,

  /// No branch resolved this tick.
  none,
}

/// Coarse fuel kind resolved from the free-text fuel key (#3429 / #3430).
/// [cng] keeps its identity for gating even though its (AFR, density)
/// pair maps to the petrol-equivalent constants (see [kCngAfr]).
enum ResolvedFuelKind { petrol, diesel, e85, lpg, cng }

/// Map a free-text fuel key to a [ResolvedFuelKind]. Matching rules are
/// IDENTICAL to `_afrDensityForFuelKey` in `fuel_rate_estimator.dart`
/// (diesel via `contains` so `"dieselPremium"` matches; unknown / null /
/// electric → petrol, the documented "safer to under-count" default).
/// Parity with [resolveAfrDensity] is locked by
/// `fuel_mixture_model_test.dart` so the two can't drift.
ResolvedFuelKind fuelKindForKey(String? key) {
  final k = key?.trim().toLowerCase();
  if (k == null || k.isEmpty) return ResolvedFuelKind.petrol;
  if (k.contains('diesel')) return ResolvedFuelKind.diesel;
  if (k.contains('e85') || k.contains('ethanol')) return ResolvedFuelKind.e85;
  if (k.contains('lpg') || k.contains('autogas')) return ResolvedFuelKind.lpg;
  if (k.contains('cng')) return ResolvedFuelKind.cng;
  return ResolvedFuelKind.petrol;
}

/// The (stoichiometric AFR, density g/L) pair for a [ResolvedFuelKind].
/// Same constants [resolveAfrDensity] maps to; CNG deliberately reuses the
/// petrol-equivalent pair (gaseous fuel has no meaningful liquid g/L —
/// see [kCngAfr]).
({double afr, double densityGPerL}) afrDensityForKind(ResolvedFuelKind kind) {
  switch (kind) {
    case ResolvedFuelKind.diesel:
      return (afr: kDieselAfr, densityGPerL: kDieselDensityGPerL);
    case ResolvedFuelKind.e85:
      return (afr: kE85Afr, densityGPerL: kE85DensityGPerL);
    case ResolvedFuelKind.lpg:
      return (afr: kLpgAfr, densityGPerL: kLpgDensityGPerL);
    case ResolvedFuelKind.petrol:
    case ResolvedFuelKind.cng:
      return (afr: kPetrolAfr, densityGPerL: kPetrolDensityGPerL);
  }
}

/// Blend (AFR, density) linearly between the petrol and E85 constants by
/// the MEASURED ethanol fraction (PID 0x52, #3429). Anchored at the two
/// points the project's constants define — 0 % → petrol (14.7 / 740) and
/// 85 % → E85 (9.8 / 785) — and extrapolated on the same line above 85 %,
/// which lands within ~1 % of the published pure-ethanol figures at 100 %
/// (stoich ≈ 9.0, density ≈ 789 g/L), so E100 markets stay honest.
/// [ethanolPercent] is clamped to 0 … 100.
({double afr, double densityGPerL}) blendedAfrDensityForEthanol(
  double ethanolPercent,
) {
  final t = ethanolPercent.clamp(0.0, 100.0) / 85.0;
  return (
    afr: kPetrolAfr + (kE85Afr - kPetrolAfr) * t,
    densityGPerL:
        kPetrolDensityGPerL + (kE85DensityGPerL - kPetrolDensityGPerL) * t,
  );
}

/// Session-aware superset of [resolveAfrDensity] (#3429 / #3430): resolves
/// the (AFR, density) pair PLUS the [ResolvedFuelKind] that gates the
/// diesel-aware corrections.
///
/// Resolution order:
///   1. [VehicleProfile.manualAfrOverride] /
///      [VehicleProfile.manualFuelDensityGPerLOverride] win whenever set —
///      exactly as in [resolveAfrDensity]; nothing measured ever
///      overwrites a user-pinned value.
///   2. When [measuredEthanolPercent] (PID 0x52) is present AND the kind
///      is petrol/E85, the fixed constants are replaced by
///      [blendedAfrDensityForEthanol] — the measured blend beats the
///      free-text guess. Diesel / LPG / CNG kinds ignore ethanol (a
///      flexfuel PID on those would be garbage).
///   3. The fuel KEY resolves as [sessionFuelTypeKey] (the ECU's own
///      PID 0x51 answer read at comm-session start — runtime truth) →
///      [VehicleProfile.preferredFuelType] → [fallbackFuelType]
///      (reference-catalog row) → petrol default.
///
/// With [sessionFuelTypeKey] and [measuredEthanolPercent] both null this
/// returns byte-for-byte what [resolveAfrDensity] returns (parity-locked
/// by test), so cars without the new PIDs are untouched.
({double afr, double densityGPerL, ResolvedFuelKind kind})
    resolveMixtureConstants(
  VehicleProfile? vehicle, {
  String? fallbackFuelType,
  String? sessionFuelTypeKey,
  double? measuredEthanolPercent,
}) {
  final key =
      sessionFuelTypeKey ?? vehicle?.preferredFuelType ?? fallbackFuelType;
  final kind = fuelKindForKey(key);
  var mapped = afrDensityForKind(kind);
  final ethanolApplies = kind == ResolvedFuelKind.petrol ||
      kind == ResolvedFuelKind.e85;
  if (measuredEthanolPercent != null && ethanolApplies) {
    mapped = blendedAfrDensityForEthanol(measuredEthanolPercent);
  }
  return (
    afr: vehicle?.manualAfrOverride ?? mapped.afr,
    densityGPerL:
        vehicle?.manualFuelDensityGPerLOverride ?? mapped.densityGPerL,
    kind: kind,
  );
}

/// Lower clamp for a MEASURED wideband φ on a DIESEL (#3430). Diesels run
/// deep-lean by design — idle sits near φ ≈ 0.1 (λ ≈ 10 is possible on
/// modern common-rail at no-load) — so the petrol clamp band
/// ([kMinCommandedPhi] = 0.5) would destroy exactly the signal the
/// wideband sensor exists to provide. 0.05 still rejects the all-zero /
/// near-zero garbage frames the parser lets through as tiny positives.
const double kMinDieselMeasuredPhi = 0.05;

/// Upper clamp for a measured diesel φ (#3430). Full-load smoke limit is
/// around φ ≈ 0.9; 1.2 leaves margin for transient overshoot while still
/// rejecting a stuck-rich garbage reading.
const double kMaxDieselMeasuredPhi = 1.2;

/// Resolve the effective AFR the fuel math divides by, from whatever
/// mixture signals are available (#3427 / #3430):
///
///   - **Diesel**: only a MEASURED wideband φ is trusted —
///     `stoichAFR / φ` with the wide diesel clamp band, because the real
///     mixture legitimately runs φ ≈ 0.1 … 0.9. COMMANDED φ (PID 0x44) is
///     never applied (meaningless as a diesel load signal, #3430), and
///     with no wideband the stoich AFR passes through untouched.
///   - **Everything else** (stoich-controlled spark engines): prefer the
///     freshest MEASURED φ over the COMMANDED one; either goes through
///     [effectiveAfrForPhi] with its garbage-rejecting petrol clamp band.
///     Both null → the assumed stoich AFR, i.e. pre-#3427 behaviour.
double effectiveAfrForMixture(
  double stoichAfr, {
  double? measuredPhi,
  double? commandedPhi,
  required bool isDiesel,
}) {
  if (isDiesel) {
    if (measuredPhi == null) return stoichAfr;
    final clamped =
        measuredPhi.clamp(kMinDieselMeasuredPhi, kMaxDieselMeasuredPhi);
    return stoichAfr / clamped;
  }
  return effectiveAfrForPhi(stoichAfr, measuredPhi ?? commandedPhi);
}

/// Convert a fuel MASS flow (g/s — PID 0x9D, or 0xA2 after
/// [cylinderFuelRateToGramsPerSecond]) into L/h via the fuel density
/// (#3428): `L/h = g/s × 3600 / (g/L)`. The one remaining scalar is the
/// density — no AFR, VE, λ or trim guess touches this branch, which is
/// what makes it the top-precision tier. Returns null on non-positive
/// density or a negative flow (garbage frame).
double? fuelRateLPerHourFromGramsPerSecond(
  double gramsPerSecond,
  double densityGPerL,
) {
  if (densityGPerL <= 0 || gramsPerSecond < 0) return null;
  return gramsPerSecond * 3600.0 / densityGPerL;
}

/// Convert a PID 0xA2 cylinder fuel rate (mg per cylinder per intake
/// stroke) into a total-engine g/s (#3428):
///
///   g/s = mg/stroke × (RPM / 60) / 2 × cylinders / 1000
///
/// `RPM / 60 / 2` is the intake strokes per second **per cylinder** on a
/// 4-stroke engine (one intake stroke every two crank revolutions), and
/// the per-cylinder quantity scales by the cylinder count. Returns null
/// when RPM / cylinders are non-positive (the conversion is undefined) —
/// callers therefore gate the 0xA2 branch on a known
/// [VehicleProfile.engineCylinders].
double? cylinderFuelRateToGramsPerSecond({
  required double mgPerStroke,
  required double rpm,
  required int cylinders,
}) {
  if (mgPerStroke < 0 || rpm <= 0 || cylinders <= 0) return null;
  return mgPerStroke * (rpm / 60.0) / 2.0 * cylinders / 1000.0;
}
