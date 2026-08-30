// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'live_sample_snapshot.dart';

/// The tier-1/2/3 fuel-rate derivation extracted from
/// [LiveSampleSnapshot] as a `part` mixin so it keeps private-member
/// access while `live_sample_snapshot.dart` stays under the #1680
/// file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved): the branch/provenance latches, the snapshot
/// fallback chain, and the trim / η_v / IAT-staleness helpers.
mixin _LiveSampleSnapshotFuelRate on _LiveSampleSnapshotLatches {
  /// #1858 — the branch [deriveFuelRateLPerHour] resolved on its most
  /// recent call. Lets the controller tell η_v-derived fuel (the
  /// [Obd2BranchTag.speedDensity] branch) from fuel that does not use
  /// η_v (PID 5E / MAF) so it can stamp the trip's recompute
  /// provenance. Null before the first call.
  Obd2BranchTag? _lastFuelRateBranch;
  Obd2BranchTag? get lastFuelRateBranch => _lastFuelRateBranch;

  /// #3428 / #3433 — the fine-grained fuel-source provenance of the most
  /// recent [deriveFuelRateLPerHour] call. Distinguishes the new 0x9D /
  /// 0xA2 mass branches and 0x66-vs-0x10 MAF, which [lastFuelRateBranch]
  /// (whose `Obd2BranchTag` vocabulary is frozen — the breadcrumb overlay
  /// switches on it exhaustively in presentation code owned by the
  /// #3431/#3432 agent) cannot express. The controller stamps it onto
  /// each TripSample so the driving-analysis export can report which
  /// branch DOMINATED the trip. Null before the first call.
  FuelRateSourceTag? _lastFuelRateSource;
  FuelRateSourceTag? get lastFuelRateSource => _lastFuelRateSource;

  /// #1858 — the volumetric efficiency applied on the most recent
  /// [deriveFuelRateLPerHour] call. Only meaningful when
  /// [lastFuelRateBranch] is [Obd2BranchTag.speedDensity]; null
  /// otherwise (PID 5E / MAF / no rate do not use η_v).
  double? _lastFuelRateVe;
  double? get lastFuelRateVe => _lastFuelRateVe;

  /// Derive the current fuel rate (L/h) from whatever snapshot
  /// values have landed so far. Mirrors the fallback chain in
  /// [Obd2Service.readFuelRateLPerHour], but over snapshot values
  /// instead of live I/O — the scheduler has already done the
  /// reads. Returns null when not enough inputs have arrived yet
  /// (e.g. first 200 ms of a trip before MAP/IAT both land).
  ///
  /// Branch order (#3428): mass-based 0x9D / 0xA2 (density-only) →
  /// direct 0x5E → MAF (0x66 preferred over 0x10, mixture-corrected) →
  /// speed-density (MAP + IAT + RPM).
  ///
  /// AFR + density come from [resolveMixtureConstants] (#800, #2432,
  /// #3429): manual overrides win, then a measured-ethanol (0x52) blend,
  /// then the session 0x51 / profile fuel key → constants; diesel
  /// 14.5 / 832, E85 9.8 / 785, LPG 15.6 / 535, CNG 17.2 / petrol-equiv;
  /// null / unknown stays on the pre-#800 petrol defaults. Diesel skips
  /// the trim + commanded-φ corrections entirely (#3430).
  double? deriveFuelRateLPerHour() {
    // #1858 — provenance defaults; each branch below overrides them.
    _lastFuelRateBranch = Obd2BranchTag.none;
    _lastFuelRateSource = FuelRateSourceTag.none;
    _lastFuelRateVe = null;
    // #1397 / #2432 / #3429 / #3430 — single fuel-type lookup (manual
    // override → measured-ethanol blend → session 0x51 key → fuel-key
    // AFR/density → petrol default), mirroring
    // [Obd2Service.readFuelRateLPerHour] so the live integrator and the
    // pull-mode estimator agree on every scalar. With no 0x51 / 0x52
    // signal this is byte-for-byte the old `resolveAfrDensity` result.
    final mixture = resolveMixtureConstants(
      _vehicle,
      sessionFuelTypeKey: sessionFuelTypeKey,
      measuredEthanolPercent: _precision.ethanolPercent,
    );
    final afr = mixture.afr;
    final density = mixture.densityGPerL;
    // #3430 — diesel gate: skip the petrol stoich-feedback corrections
    // (STFT/LTFT trims + commanded φ); only a measured wideband φ is
    // trusted. See the accuracy-limit doc in `fuel_mixture_model.dart`.
    final isDiesel = mixture.kind == ResolvedFuelKind.diesel;
    // #3888 — on an ethanol fuel the enrichment is already in the AFR the
    // air mass is divided by; the ECU's +25 % trims on E85 are the SAME
    // correction, so applying both counts it twice.
    final skipTrim = isDiesel ||
        mixture.kind == ResolvedFuelKind.e85 ||
        (_precision.ethanolPercent ?? 0) >= 30;
    // #3887 — the pump-anchored gain on every ESTIMATED branch.
    final pumpGain = _vehicle?.pumpGain ?? 1.0;
    final displacement = _vehicle?.manualEngineDisplacementCcOverride
            ?.round() ??
        _vehicle?.engineDisplacementCc ??
        1000;
    // #1422 phase 1 — same precedence as Obd2Service.readFuelRateLPerHour:
    // manual override → stored profile (when learned or non-default) →
    // engine-tech helper on the reference catalog row → hard 0.85 fallback.
    // Both paths must agree so live + pull-mode produce identical numbers.
    final ve = _vehicle?.manualVolumetricEfficiencyOverride ??
        _resolveControllerProfileVe() ??
        (_referenceVehicle != null
            ? defaultVolumetricEfficiency(_referenceVehicle)
            : 0.85);
    final collector = _breadcrumbCollector;

    // Step 0 (#3428): the mass-based PIDs — the ECU reports FUEL MASS
    // directly, so only the density touches the conversion (no AFR / VE /
    // φ / trim guess). Above 0x5E because 0x9D carries more resolution
    // (0.02 g/s ≈ 0.1 L/h petrol vs 0x5E's 0.05 L/h) and is the SAE-
    // designated fuel-economy PID on modern ECUs. Breadcrumb rows use the
    // frozen pid5E tag (the overlay's Obd2BranchTag switch lives in
    // presentation code owned by the #3431/#3432 agent); the true source
    // is stamped via [lastFuelRateSource].
    final rate9dGPerS = _precision.engineFuelRate9dGPerS;
    if (rate9dGPerS != null) {
      final lph = fuelRateLPerHourFromGramsPerSecond(rate9dGPerS, density);
      if (lph != null) {
        collector?.record(
          branch: Obd2BranchTag.pid5E,
          fuelRateLPerHour: lph,
          pid5ELPerHour: _latestDirectFuelRate,
          rpm: _latestRpm,
          afr: afr,
          fuelDensityGPerL: density,
          engineDisplacementCc: displacement.toDouble(),
          volumetricEfficiency: ve,
        );
        // #3428 — 9D-vs-5E cross-check: both are ECU-reported fuel, so a
        // > 50 % divergence flags a mis-scaled 0x9D or a stuck 0x5E.
        final direct5e = _latestDirectFuelRate;
        if (direct5e != null &&
            direct5e > 0 &&
            (lph - direct5e).abs() / direct5e > 0.5) {
          collector?.recordFlag(
            Obd2BreadcrumbCollector.flag9dVs5eDivergent,
            'rate9d=${lph.toStringAsFixed(2)};'
                'pid5e=${direct5e.toStringAsFixed(2)}',
          );
        }
        _lastFuelRateBranch = Obd2BranchTag.pid5E;
        _lastFuelRateSource = FuelRateSourceTag.pid9D;
        return lph;
      }
    }
    // 0xA2 (mg per cylinder per stroke) needs RPM + the cylinder count to
    // become a mass flow; gated on a known [VehicleProfile.engineCylinders]
    // so the conversion is never guessed (#3428).
    final cylRate = _precision.cylinderFuelRateMgPerStroke;
    final cylinders = _vehicle?.engineCylinders;
    final rpmForCyl = _latestRpm;
    if (cylRate != null && cylinders != null && rpmForCyl != null) {
      final gPerS = cylinderFuelRateToGramsPerSecond(
        mgPerStroke: cylRate,
        rpm: rpmForCyl,
        cylinders: cylinders,
      );
      final lph = gPerS == null
          ? null
          : fuelRateLPerHourFromGramsPerSecond(gPerS, density);
      if (lph != null) {
        collector?.record(
          branch: Obd2BranchTag.pid5E,
          fuelRateLPerHour: lph,
          rpm: rpmForCyl,
          afr: afr,
          fuelDensityGPerL: density,
          engineDisplacementCc: displacement.toDouble(),
          volumetricEfficiency: ve,
        );
        _lastFuelRateBranch = Obd2BranchTag.pid5E;
        _lastFuelRateSource = FuelRateSourceTag.pidA2;
        return lph;
      }
    }

    // Step 1: direct PID 5E. Already post-trim, no correction.
    final direct = _latestDirectFuelRate;
    if (direct != null) {
      // #1395 — sanity bound A: implausibly-low at non-idle RPM.
      // Same threshold as Obd2Service.readFuelRateLPerHour but evaluated
      // on the controller's most-recent RPM snapshot so this works
      // even when the trip is being driven by raw scheduler callbacks
      // rather than the readFuelRate API.
      String? lowFlag;
      String? lowDetail;
      final rpm = _latestRpm;
      if (direct < 0.3 && rpm != null && rpm > 1500) {
        lowFlag = Obd2BreadcrumbCollector.flagSuspiciousLow;
        lowDetail = 'directRate=${direct.toStringAsFixed(2)};'
            'rpm=${rpm.toStringAsFixed(0)}';
      }
      collector?.record(
        branch: Obd2BranchTag.pid5E,
        fuelRateLPerHour: direct,
        pid5ELPerHour: direct,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
        flag: lowFlag,
        flagDetail: lowDetail,
      );
      // Sanity bound B: 5E vs MAF cross-check on the controller's
      // cached MAF snapshot. Evaluated AFTER the breadcrumb is
      // pushed so [recordFlag] mutates the same row.
      final mafSnapshot = _latestMaf;
      if (mafSnapshot != null) {
        final mafDerived = mafSnapshot * 3600.0 / (afr * density);
        if (mafDerived > 0 &&
            (direct - mafDerived).abs() / mafDerived > 0.5) {
          collector?.recordFlag(
            Obd2BreadcrumbCollector.flag5eVsMafDivergent,
            'direct=${direct.toStringAsFixed(2)};'
                'mafDerived=${mafDerived.toStringAsFixed(2)};'
                'maf=${mafSnapshot.toStringAsFixed(2)}',
          );
        }
      }
      _lastFuelRateBranch = Obd2BranchTag.pid5E;
      _lastFuelRateSource = FuelRateSourceTag.pid5E;
      return direct;
    }

    // Step 2: MAF-based. L/h = MAF × 3600 / (effectiveAFR × density).
    // #3428 — the dual-sensor PID 0x66 total is preferred over the legacy
    // PID 0x10 when both landed (0x66 carries per-bank resolution).
    // #2456 / #3427 / #3430 — the assumed stoich AFR is replaced with the
    // mixture-resolved effective AFR: freshest MEASURED wideband φ beats
    // commanded φ (0x44); diesel trusts only the measured value. All
    // null → `effectiveAfr == afr`, i.e. unchanged.
    final maf66 = _precision.mafSensorGPerS;
    final maf = maf66 ?? _latestMaf;
    if (maf != null) {
      final effectiveAfr = effectiveAfrForMixture(
        afr,
        measuredPhi: latestMeasuredPhi,
        commandedPhi: _latestCommandedPhi,
        isDiesel: isDiesel,
      );
      final raw = maf * 3600.0 / (effectiveAfr * density);
      // #3430 — STFT/LTFT are petrol stoich-feedback trims; skipped on
      // diesel (they don't model a lean-burn mixture).
      final corrected = (skipTrim ? raw : _applyTrim(raw)) * pumpGain;
      collector?.record(
        branch: Obd2BranchTag.maf,
        fuelRateLPerHour: corrected,
        mafGramsPerSecond: maf,
        rpm: _latestRpm,
        afr: effectiveAfr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      _lastFuelRateBranch = Obd2BranchTag.maf;
      _lastFuelRateSource =
          maf66 != null ? FuelRateSourceTag.maf66 : FuelRateSourceTag.maf;
      return corrected;
    }

    // Step 3: speed-density from MAP+IAT+RPM. Feeds the pre-#810
    // estimator with the active vehicle's displacement + VE (#812).
    // #2505 — MAP + RPM must be same-tick current, but IAT is reused up
    // to [_iatStaleness] old (the #2457 governor reads it slowly).
    final mapKpa = _latestMapKpa;
    final iat = _freshIatCelsius();
    final rpm = _latestRpm;
    void recordNone() => collector?.record(
          branch: Obd2BranchTag.none,
          mapKpa: mapKpa,
          iatCelsius: iat,
          rpm: rpm,
          afr: afr,
          fuelDensityGPerL: density,
          engineDisplacementCc: displacement.toDouble(),
          volumetricEfficiency: ve,
        );
    if (mapKpa == null || iat == null || rpm == null) {
      recordNone();
      return null;
    }
    // #2456 / #3427 / #3430 — feed the measured baro (PID 0x33) + the
    // mixture-resolved effective AFR into the speed-density math when
    // available: baro scales the air charge for altitude / weather; the
    // effective AFR prefers measured wideband φ over commanded 0x44
    // (diesel: measured only — see fuel_mixture_model.dart for why an
    // unthrottled engine's speed-density fuel is otherwise an upper
    // bound). All null → byte-for-byte the pre-#2456 result. The
    // effective AFR is recorded in the breadcrumb so diagnostics reflect
    // the real denominator; φ is passed pre-resolved (`phi: null`) so the
    // estimator can't double-apply it.
    final baroKpa = _latestBaroKpa;
    final effectiveAfr = effectiveAfrForMixture(
      afr,
      measuredPhi: latestMeasuredPhi,
      commandedPhi: _latestCommandedPhi,
      isDiesel: isDiesel,
    );
    final raw = Obd2Service.estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      engineDisplacementCc: displacement,
      volumetricEfficiency: ve,
      afr: effectiveAfr,
      fuelDensityGPerL: density,
      baroKpa: baroKpa,
      phi: null,
    );
    if (raw == null) {
      recordNone();
      return null;
    }
    // #3430 — trim correction skipped on diesel (petrol stoich feedback).
    final corrected = (skipTrim ? raw : _applyTrim(raw)) * pumpGain;
    collector?.record(
      branch: Obd2BranchTag.speedDensity,
      fuelRateLPerHour: corrected,
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      afr: effectiveAfr,
      fuelDensityGPerL: density,
      engineDisplacementCc: displacement.toDouble(),
      volumetricEfficiency: ve,
    );
    // #1858 — the only η_v-derived branch: record the η_v applied so
    // the controller can stamp the trip's recompute provenance.
    _lastFuelRateBranch = Obd2BranchTag.speedDensity;
    _lastFuelRateSource = FuelRateSourceTag.speedDensity;
    _lastFuelRateVe = ve;
    return corrected;
  }

  /// Returns the user profile's η_v that should beat the engine-tech
  /// helper, or null when the helper should kick in instead (#1422
  /// phase 1). Mirrors the rules in [_resolveProfileVolumetricEfficiency]
  /// in `obd2_service.dart` so both the live integrator and the
  /// pull-mode estimator agree on a per-tick basis.
  ///
  /// Profile null → null (caller will use the helper or hard fallback).
  /// Without a reference catalog row the stored profile value is the
  /// best we can do, even if it equals the legacy 0.85 default.
  /// Otherwise: keep the stored value when the VeLearner has logged at
  /// least one sample OR when the value differs from the legacy 0.85
  /// default. A cold-start profile sitting on 0.85 with zero samples
  /// returns null, letting the engine-tech helper provide a closer
  /// initial guess (e.g. 0.95 for a Dacia dCi VNT diesel).
  double? _resolveControllerProfileVe() {
    final v = _vehicle;
    if (v == null) return null;
    if (_referenceVehicle == null) return v.volumetricEfficiency;
    if (v.volumetricEfficiencySamples > 0) return v.volumetricEfficiency;
    if (v.volumetricEfficiency != 0.85) return v.volumetricEfficiency;
    return null;
  }

  /// Apply the STFT + LTFT correction used on the MAF / speed-density
  /// branches (#813; bank-2 #2458). Returns [raw] unchanged when either
  /// bank-1 trim hasn't landed yet — better an uncorrected estimate than
  /// one shifted by half the real signal. When the car also exposes
  /// bank-2 trims (PIDs 0x08 / 0x09), they're folded in so dual-bank
  /// engines get the bank-averaged correction; null bank-2 trims fall
  /// back to bank-1-only (byte-for-byte the pre-#2458 result).
  double _applyTrim(double raw) {
    final stft = _latestStft;
    final ltft = _latestLtft;
    if (stft == null || ltft == null) return raw;
    return Obd2Service.applyFuelTrimCorrection(
      raw,
      stft: stft,
      ltft: ltft,
      stftBank2: _latestStftBank2,
      ltftBank2: _latestLtftBank2,
    );
  }

  /// How long a latched IAT (#2505) stays usable for speed-density fuel.
  /// The #2457 governor reads IAT (0x0F) on the demotable ~0.5 Hz tier, so
  /// it is rarely fresh on the tick MAP + RPM land; intake-air temperature
  /// drifts on a minutes scale, so a few-seconds-old value is physically
  /// fine. 12 s spans a few throttled IAT periods yet rejects a dead link.
  static const Duration _iatStaleness = Duration(seconds: 12);

  /// The last-known IAT (°C) if it landed within [_iatStaleness], else
  /// null (#2505) — keeps speed-density fuel flowing between sparse reads.
  double? _freshIatCelsius() {
    final iat = _latestIatCelsius;
    final at = _latestIatAt;
    if (iat == null || at == null) return null;
    return _clock().difference(at) > _iatStaleness ? null : iat;
  }
}
