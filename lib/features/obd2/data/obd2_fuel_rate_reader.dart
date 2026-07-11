// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../vehicle/api.dart' show ReferenceVehicle, EtaVCurvePoint, defaultVolumetricEfficiency, etaVCurveFor;
import '../../../core/domain/vehicle_profile.dart';
import 'fuel_mixture_model.dart' as mixture_model;
import 'fuel_rate_diagnostics.dart';
import 'fuel_rate_estimator.dart' as estimator;
import 'obd2_breadcrumb_collector.dart';

/// Narrow read-port the fuel-rate fallback chain needs from [Obd2Service]
/// (#3540 — extracted from the service following the #811/#3528
/// collaborator pattern). The service implements this interface; tests can
/// hand the reader a small fake instead of a full service.
abstract interface class Obd2FuelRateReads {
  /// "Unknown ⇒ allow" support check (see `SupportedPidsResolver`).
  bool isPidSupported(int pid);

  /// STRICT support check for the #3416 precision PIDs — true only when
  /// the support set is RESOLVED and the bitmap claims [pid] (#3532).
  bool isPidKnownSupported(int pid);

  Future<double?> readEthanolPercent();
  Future<double?> readEngineFuelRateGramsPerSecond();
  Future<double?> readCylinderFuelRateMgPerStroke();
  Future<double?> readRpm();
  Future<double?> readMafSensorGramsPerSecond();
  Future<double?> readMafGramsPerSecond();
  Future<double?> readMeasuredPhi();
  Future<double?> readCommandedEquivalenceRatio();
  Future<double?> readManifoldPressureKpa();
  Future<double?> readIntakeAirTempCelsius();
  Future<double?> readBaroPressureKpa();
  Future<double?> readShortTermFuelTrimPercent();
  Future<double?> readLongTermFuelTrimPercent();
  Future<double?> readShortTermFuelTrimBank2Percent();
  Future<double?> readLongTermFuelTrimBank2Percent();

  /// One direct PID 0x5E read (`engine fuel rate`, L/h) — already
  /// post-trim on the ECU side, no correction applies.
  Future<double?> readDirectFuelRatePid5E();
}

/// The engine fuel-rate fallback chain (#717, #800, #3428), extracted from
/// [Obd2Service] in #3540. One instance per call is fine — the class holds
/// no state beyond its two collaborators.
///
/// Fallback order:
///
///   0. **PID 9D / A2** — ECU-reported fuel MASS (g/s or mg/stroke).
///      Top precision: only the fuel density touches the conversion —
///      no AFR / VE / φ / trim guess. 0xA2 additionally needs a known
///      cylinder count. A 9D-vs-5E divergence cross-check stamps the
///      breadcrumb trace (#3428).
///   1. **PID 5E** — direct `engine fuel rate` reading. Modern ECUs
///      (~2014+) answer directly. Best accuracy, preferred when supported.
///   2. **PID 10 MAF** — derive fuel rate from mass air flow:
///      `L/h = MAF_g_per_s × 3600 / (AFR × density)`. Accepted ~5–10 %
///      error, still very usable. Fails on cars without a MAF sensor.
///   3. **MAP + IAT + RPM speed-density** — when neither direct fuel
///      rate nor MAF is available (e.g. Peugeot 107 1.0L 1KR-FE), use
///      the ideal gas law to estimate air mass flow from intake
///      manifold pressure, intake air temperature, engine RPM, engine
///      displacement, and volumetric efficiency. Accepted ~10–15 %
///      error — still infinitely better than the `—` placeholder the
///      trip summary would otherwise show.
///
/// Pass the active [VehicleProfile] via `vehicle` to feed the step-3
/// speed-density fallback the car's real engine displacement and
/// volumetric efficiency (#812 phase 3); absent fields fall back to
/// `kDefaultEngineDisplacementCc` / `kDefaultVolumetricEfficiency` (the
/// 1.0 L NA petrol class that motivated the fallback), per-field.
///
/// Fuel-trim correction (#813) applies on the MAF and speed-density
/// branches — both compute air-mass at stoichiometric AFR while the ECU
/// trims the real mixture ±10 %; the `(1 + (STFT + LTFT) / 100)` factor
/// closes most of the gap. Skipped on the direct-5E path (already
/// post-trim). Both branches honour
/// [VehicleProfile.preferredFuelType] for AFR/density (#800); an absent
/// or unrecognised fuel type defaults to petrol.
///
/// #3427 / #3429 / #3430 — the mixture refinements mirror the live path:
/// a measured ethanol % (PID 0x52) blends the petrol↔E85 constants; a
/// MEASURED wideband φ (0x24–0x2B / 0x34–0x3B) beats the commanded 0x44;
/// and a diesel skips the trim + commanded-φ corrections entirely
/// (lean-burn — see `fuel_mixture_model.dart`).
class Obd2FuelRateReader {
  /// The live reads (implemented by `Obd2Service`).
  final Obd2FuelRateReads reads;

  /// Trip-scoped breadcrumb sink for the diagnostics side-channel; null
  /// outside a recording session.
  final Obd2BreadcrumbRecorder? collector;

  const Obd2FuelRateReader({required this.reads, this.collector});

  Future<double?> read({
    VehicleProfile? vehicle,
    ReferenceVehicle? referenceVehicle,
  }) async {
    // Precedence (#950 phase 2 + #1397):
    //   1. Manual override on the VehicleProfile (user typed a value
    //      into the "Advanced calibration" card — overrides everything).
    //   2. VehicleProfile field (set during onboarding / VIN decode).
    //   3. ReferenceVehicle catalog entry (data-driven defaults).
    //   4. Generic estimator constants (last-resort fallback).
    final engineDisplacementCc =
        vehicle?.manualEngineDisplacementCcOverride?.round() ??
            vehicle?.engineDisplacementCc ??
            referenceVehicle?.displacementCc ??
            estimator.kDefaultEngineDisplacementCc;
    // VE on VehicleProfile is a non-nullable double with its own
    // default (0.85). The manual override takes precedence so a user
    // can pin the value while the auto-learner is still bootstrapping.
    //
    // #1422 phase 1 — when the user's profile carries the legacy 0.85
    // default AND the VeLearner hasn't accumulated any samples yet,
    // fall through to the engine-tech-derived helper instead of the
    // raw catalog literal. This kicks Atkinson / VNT diesel / DI turbo
    // engines off 0.85 from day one, without disturbing existing
    // VeLearner-converged users (samples > 0 keeps the stored value)
    // or users who explicitly typed a non-default value through the
    // calibration card.
    final manualVe = vehicle?.manualVolumetricEfficiencyOverride;
    final profileVe =
        _resolveProfileVolumetricEfficiency(vehicle, referenceVehicle);
    final volumetricEfficiency = manualVe ??
        profileVe ??
        (referenceVehicle != null
            ? defaultVolumetricEfficiency(referenceVehicle)
            : estimator.kDefaultVolumetricEfficiency);
    // #1625 — the per-engine-class η_v(rpm) curve the speed-density
    // estimator interpolates. Applied ONLY when η_v came from the
    // catalog default: a manual override or a learned profile value
    // is a figure the user/learner pinned, so it is used flat. An
    // empty curve makes the estimator fall back to [volumetricEfficiency].
    final etaVCurve =
        (manualVe == null && profileVe == null && referenceVehicle != null)
            ? etaVCurveFor(referenceVehicle)
            : const <EtaVCurvePoint>[];
    // #2432 / #3429 / #3430 — single fuel-type lookup (manual overrides
    // win, else the measured-ethanol 0x52 blend, else the free-text fuel
    // key → AFR/density, else petrol default). When there is no profile
    // the reference-catalog fuel string is the fallback key, so that path
    // also gets E85/LPG/CNG coverage, not just diesel. Mirrors the live
    // path's `resolveMixtureConstants` so the two can't disagree.
    final ethanolPercent = reads.isPidKnownSupported(0x52)
        ? await reads.readEthanolPercent()
        : null;
    final afrDensity = mixture_model.resolveMixtureConstants(vehicle,
        fallbackFuelType: vehicle == null ? referenceVehicle?.fuelType : null,
        measuredEthanolPercent: ethanolPercent);
    final afr = afrDensity.afr;
    final fuelDensityGPerL = afrDensity.densityGPerL;
    // #3430 — diesel gate: skip STFT/LTFT + commanded-φ corrections; only
    // a measured wideband φ adjusts the AFR (see fuel_mixture_model.dart).
    final isDiesel = afrDensity.kind == mixture_model.ResolvedFuelKind.diesel;
    // #1395 / #2191 — the diagnostic side-channel (breadcrumb trace +
    // the suspicious-low / 5E-vs-MAF sanity bounds) lives in this
    // collaborator so the fallback chain below reads clean: compute
    // the value, delegate the diagnostics. It captures the per-call
    // resolved constants here (displacement pre-coerced to double for
    // the recorder, which renders it as a plain number) plus the
    // live-read tear-offs the cross-checks need.
    final diagnostics = FuelRateDiagnostics(
      collector: collector,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc.toDouble(),
      volumetricEfficiency: volumetricEfficiency,
      readRpm: reads.readRpm,
      isMafSupported: () => reads.isPidSupported(0x10),
      readMaf: reads.readMafGramsPerSecond,
    );

    // Step 0 (#3428): mass-based PIDs — ECU-reported FUEL MASS, so only
    // the density touches the conversion (no AFR / VE / φ / trim guess).
    // 0x9D outranks 0x5E (finer 0.02 g/s resolution, the SAE-designated
    // fuel-economy PID); 0xA2 needs RPM + a known cylinder count.
    if (reads.isPidKnownSupported(0x9D)) {
      final gPerS = await reads.readEngineFuelRateGramsPerSecond();
      final lph = gPerS == null
          ? null
          : mixture_model.fuelRateLPerHourFromGramsPerSecond(
              gPerS, fuelDensityGPerL);
      if (lph != null) {
        await diagnostics.recordMassRate(
          lph,
          isPid5ESupported: () => reads.isPidSupported(0x5E),
          readPid5E: reads.readDirectFuelRatePid5E,
        );
        return lph;
      }
    }
    final cylinders = vehicle?.engineCylinders;
    if (reads.isPidKnownSupported(0xA2) && cylinders != null) {
      final mgPerStroke = await reads.readCylinderFuelRateMgPerStroke();
      final rpmForCyl = mgPerStroke == null ? null : await reads.readRpm();
      final gPerS = (mgPerStroke == null || rpmForCyl == null)
          ? null
          : mixture_model.cylinderFuelRateToGramsPerSecond(
              mgPerStroke: mgPerStroke,
              rpm: rpmForCyl,
              cylinders: cylinders,
            );
      final lph = gPerS == null
          ? null
          : mixture_model.fuelRateLPerHourFromGramsPerSecond(
              gPerS, fuelDensityGPerL);
      if (lph != null) {
        await diagnostics.recordMassRate(lph);
        return lph;
      }
    }

    // Step 1: direct fuel-rate PID (already post-trim — no correction).
    // Skipped when #811 discovery proved the car doesn't implement PID 5E.
    double? directRate;
    if (reads.isPidSupported(0x5E)) {
      directRate = await reads.readDirectFuelRatePid5E();
    }
    if (directRate != null) {
      await diagnostics.recordPid5E(directRate);
      return directRate;
    }

    // Step 2: MAF-based estimate. Same short-circuit — a Peugeot 107
    // without a MAF sensor returns empty set on PID 10, saves the
    // Bluetooth round-trip on every tick. #3428 — the dual-sensor PID
    // 0x66 total is preferred over the legacy PID 0x10 when supported.
    if (reads.isPidKnownSupported(0x66) || reads.isPidSupported(0x10)) {
      double? maf;
      if (reads.isPidKnownSupported(0x66)) {
        maf = await reads.readMafSensorGramsPerSecond();
      }
      if (maf == null && reads.isPidSupported(0x10)) {
        maf = await reads.readMafGramsPerSecond();
      }
      if (maf != null) {
        // #2456 / #3427 / #3430 — divide by the mixture-resolved
        // effective AFR: freshest MEASURED wideband φ beats commanded
        // 0x44; diesel trusts only the measured value (commanded φ is
        // meaningless as a diesel load signal, and the 0x44 read is
        // skipped outright). Nothing available → effectiveAfr == afr.
        final measuredPhi = await reads.readMeasuredPhi();
        final commandedPhi =
            (!isDiesel && measuredPhi == null && reads.isPidSupported(0x44))
                ? await reads.readCommandedEquivalenceRatio()
                : null;
        final effectiveAfr = mixture_model.effectiveAfrForMixture(
          afr,
          measuredPhi: measuredPhi,
          commandedPhi: commandedPhi,
          isDiesel: isDiesel,
        );
        // L/h = MAF × 3600 / (effectiveAFR × density).
        final rate = maf * 3600.0 / (effectiveAfr * fuelDensityGPerL);
        // #3430 — STFT/LTFT are petrol stoich-feedback trims: skipped on
        // diesel.
        final corrected =
            isDiesel ? rate : await _applyFuelTrimCorrection(rate);
        diagnostics.recordMaf(corrected: corrected, maf: maf);
        return corrected;
      }
    }

    // Step 3: speed-density fallback. Requires all three of MAP / IAT
    // / RPM. If any one is known-unsupported, the step can't run and
    // we surface null — there's no partial correction worth shipping.
    if (!reads.isPidSupported(0x0B) ||
        !reads.isPidSupported(0x0F) ||
        !reads.isPidSupported(0x0C)) {
      diagnostics.recordNoBranch();
      return null;
    }
    final mapKpa = await reads.readManifoldPressureKpa();
    final iatCelsius = await reads.readIntakeAirTempCelsius();
    final rpm = await reads.readRpm();
    if (mapKpa == null || iatCelsius == null || rpm == null) {
      diagnostics.recordNoBranch(
        mapKpa: mapKpa,
        iatCelsius: iatCelsius,
        rpm: rpm,
      );
      return null;
    }
    // #2456 / #3427 / #3430 — refine with the measured baro (PID 0x33)
    // air-density term and the mixture-resolved effective AFR (measured
    // wideband φ preferred over commanded 0x44; diesel measured-only —
    // the 0x44 read is skipped there). All supportsPid-gated; absent →
    // the pre-#2456 result exactly. φ is passed pre-resolved
    // (`phi: null`) so the estimator can't double-apply it.
    final baroKpa =
        reads.isPidSupported(0x33) ? await reads.readBaroPressureKpa() : null;
    final sdMeasuredPhi = await reads.readMeasuredPhi();
    final sdCommandedPhi =
        (!isDiesel && sdMeasuredPhi == null && reads.isPidSupported(0x44))
            ? await reads.readCommandedEquivalenceRatio()
            : null;
    final sdEffectiveAfr = mixture_model.effectiveAfrForMixture(
      afr,
      measuredPhi: sdMeasuredPhi,
      commandedPhi: sdCommandedPhi,
      isDiesel: isDiesel,
    );
    final rate = estimator.estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
      afr: sdEffectiveAfr,
      fuelDensityGPerL: fuelDensityGPerL,
      etaVCurve: etaVCurve,
      baroKpa: baroKpa,
      phi: null,
    );
    if (rate == null) {
      diagnostics.recordNoBranch(
        mapKpa: mapKpa,
        iatCelsius: iatCelsius,
        rpm: rpm,
      );
      return null;
    }
    // #3430 — trim correction skipped on diesel (petrol stoich feedback).
    final corrected = isDiesel ? rate : await _applyFuelTrimCorrection(rate);
    diagnostics.recordSpeedDensity(
      corrected: corrected,
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
    );
    return corrected;
  }

  /// Multiply a stoichiometric-assumption fuel rate by
  /// `(1 + (STFT + LTFT) / 100)` when both trims are readable (#813).
  /// If either trim is missing or un-parseable, returns [raw]
  /// unchanged — better to ship the raw MAF/speed-density number
  /// than one corrected by half the signal.
  Future<double> _applyFuelTrimCorrection(double raw) async {
    final stft = await reads.readShortTermFuelTrimPercent();
    final ltft = await reads.readLongTermFuelTrimPercent();
    if (stft == null || ltft == null) return raw;
    // #2458 — fold in bank-2 trims (PIDs 08 / 09) when the car exposes
    // them so dual-bank engines get the bank-averaged correction. Both
    // supportsPid-gated; absent → null → bank-1-only, unchanged.
    final stft2 = reads.isPidSupported(0x08)
        ? await reads.readShortTermFuelTrimBank2Percent()
        : null;
    final ltft2 = reads.isPidSupported(0x09)
        ? await reads.readLongTermFuelTrimBank2Percent()
        : null;
    return estimator.applyFuelTrimCorrection(
      raw,
      stft: stft,
      ltft: ltft,
      stftBank2: stft2,
      ltftBank2: ltft2,
    );
  }
}

/// Returns the user-profile η_v that should beat the catalog helper, or
/// null when the engine-tech default should kick in instead (#1422 phase 1).
///
/// Resolution rules:
///   - Profile is null → null (caller falls back to catalog helper).
///   - Profile carries a learned EWMA value
///     (`volumetricEfficiencySamples > 0`) → return the stored value, no
///     matter what it is. The user's own car beats the table.
///   - Profile carries a non-default value (anything ≠ 0.85) → return it.
///     This covers users who typed a non-default value somewhere upstream
///     even though the sample counter never bumped.
///   - Profile sits at the cold-start default 0.85 with zero learned
///     samples → null. Caller resolves
///     `defaultVolumetricEfficiency(reference)` instead so a Dacia dCi
///     gets 0.95 from day one rather than being stuck at 0.85 until
///     VeLearner converges over several plein cycles.
double? _resolveProfileVolumetricEfficiency(
  VehicleProfile? vehicle,
  ReferenceVehicle? referenceVehicle,
) {
  if (vehicle == null) return null;
  // Without a reference vehicle to derive a better default from, the
  // stored value is the best we have — even if it equals 0.85.
  if (referenceVehicle == null) return vehicle.volumetricEfficiency;
  if (vehicle.volumetricEfficiencySamples > 0) {
    return vehicle.volumetricEfficiency;
  }
  if (vehicle.volumetricEfficiency != estimator.kDefaultVolumetricEfficiency) {
    return vehicle.volumetricEfficiency;
  }
  return null;
}
