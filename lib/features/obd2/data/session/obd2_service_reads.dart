// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_service.dart';

/// The typed PID read helpers extracted from [Obd2Service] as a `part`
/// mixin so they keep private-member access while `obd2_service.dart`
/// stays under the #1680 file-length cap (sanctioned #3760
/// decomposition — move-only, behaviour preserved): every `read*`
/// method plus the shared `_readDouble` parse/probation funnel.
mixin _Obd2ServiceReads on _Obd2ServiceLink {
  /// Optional fuel-rate diagnostic breadcrumb collector (#1395) — the
  /// class owns the field; the mixin reaches it through this getter.
  Obd2BreadcrumbRecorder? get breadcrumbCollector;

  /// Read the odometer value in km.
  ///
  /// #3540 — the fallback chain (standard A6 → PID 31 proxy →
  /// manufacturer Mode 22 catalog) lives in [Obd2OdometerReader]; this
  /// stays the public API and hands it the send/connectivity primitives.
  /// Returns null when every layer fails, so callers can surface
  /// "odometer not readable for your car" instead of a zero.
  Future<double?> readOdometerKm({
    ReferenceVehicle? referenceVehicle,
  }) =>
      Obd2OdometerReader(
        send: _send,
        isConnected: () => _transport.isConnected,
      ).read(odometerPidStrategy: referenceVehicle?.odometerPidStrategy);

  /// Read current vehicle speed in km/h.
  Future<int?> readSpeedKmh() async {
    if (!_transport.isConnected) return null;

    try {
      final response = await _send(Elm327Protocol.vehicleSpeedCommand);
      final value = Elm327Protocol.parseVehicleSpeed(response);
      _pids.noteMode01Reply(Elm327Protocol.vehicleSpeedCommand, response,
          parsed: value != null); // #3532
      // #3756 — a PARSED road speed only comes from an awake ECU. #3856:
      // awake is all it proves — a speed of 0 with the key on is
      // ignition-on/engine-off, so the engine-RUNNING stamp needs a
      // moving car (rpm is the authoritative running signal below).
      if (value != null) {
        Obd2VehiclePower.instance.noteBusAnswered();
        if (value > 0) Obd2EngineEvidence.instance.noteEngineOn();
      }
      return value;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readSpeed failed'); // #2855
      return null;
    }
  }

  /// Read current engine RPM.
  @override
  Future<double?> readRpm() async {
    if (!_transport.isConnected) return null;

    try {
      final response = await _send(Elm327Protocol.engineRpmCommand);
      final value = Elm327Protocol.parseEngineRpm(response);
      _pids.noteMode01Reply(Elm327Protocol.engineRpmCommand, response,
          parsed: value != null); // #3532
      // #3756 — rpm > 0 = the engine is literally turning. #3856 — rpm
      // is the authoritative power-state reading either way (0 = awake).
      if (value != null) {
        Obd2VehiclePower.instance.noteRpm(value);
        if (value > 0) Obd2EngineEvidence.instance.noteEngineOn();
      }
      return value;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readRpm failed'); // #2855
      return null;
    }
  }

  /// #3857 (Epic #3855) — read the adapter's own battery-voltage
  /// measurement (`ATRV`). An AT command: answered by the ELM chip
  /// without any vehicle-bus traffic, so it is safe to poll while the
  /// ECU is silent, mid protocol-search, and through the UNABLE-TO-
  /// CONNECT livelock — every case where PIDs say nothing. The parsed
  /// value feeds the vehicle power model through the session hook; this
  /// returns it for the caller's own bookkeeping (the recording loop's
  /// slow-cadence `bv` stamp). Null when not connected or unparsable.
  Future<double?> readBatteryVoltageV() async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _rawSend(Elm327Commands.readVoltageCommand);
      final volts = Elm327Protocol.parseBatteryVoltage(response);
      // The session hook already stamped the model when a session is
      // attached; a pre-session read (connect-time) stamps here.
      if (volts != null && _session.lastVoltageV != volts) {
        Obd2VehiclePower.instance.noteVoltage(volts);
      }
      return volts;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readBatteryVoltage failed');
      return null;
    }
  }

  /// Read calculated engine load, 0–100 %. (#717)
  Future<double?> readEngineLoad() => _readDouble(
        Elm327Protocol.engineLoadCommand,
        Elm327Protocol.parseEngineLoad,
        label: 'engineLoad',
      );

  /// Read absolute throttle position, 0–100 %. (#717)
  Future<double?> readThrottlePercent() => _readDouble(
        Elm327Protocol.throttlePositionCommand,
        Elm327Protocol.parseThrottlePercent,
        label: 'throttle',
      );

  /// Read engine fuel rate in L/h (#717, #800, #3428).
  ///
  /// #3540 — the full fallback chain (mass PIDs 9D/A2 → direct 5E → MAF →
  /// speed-density) plus the mixture/trim refinements live in
  /// [Obd2FuelRateReader]; this stays the public API and hands the reader
  /// the narrow [Obd2FuelRateReads] port this service implements. See the
  /// reader's class doc for the precedence rules and error bars.
  Future<double?> readFuelRateLPerHour({
    VehicleProfile? vehicle,
    ReferenceVehicle? referenceVehicle,
  }) =>
      Obd2FuelRateReader(reads: this, collector: breadcrumbCollector)
          .read(vehicle: vehicle, referenceVehicle: referenceVehicle);

  /// One direct PID 0x5E read (#3540 — the [Obd2FuelRateReads] port's
  /// step-1 primitive; already post-trim on the ECU side).
  @override
  Future<double?> readDirectFuelRatePid5E() => _readDouble(
        Elm327Protocol.engineFuelRateCommand,
        Elm327Protocol.parseFuelRateLPerHour,
        label: 'fuelRate',
      );

  /// Read mass air flow in g/s. (#717)
  @override
  Future<double?> readMafGramsPerSecond() => _readDouble(
        Elm327Protocol.mafCommand,
        Elm327Protocol.parseMafGramsPerSecond,
        label: 'maf',
      );

  /// Read intake manifold absolute pressure (kPa). (#800)
  @override
  Future<double?> readManifoldPressureKpa() => _readDouble(
        Elm327Protocol.intakeManifoldPressureCommand,
        Elm327Protocol.parseManifoldPressureKpa,
        label: 'manifoldPressure',
      );

  /// Read intake air temperature (°C). (#800)
  @override
  Future<double?> readIntakeAirTempCelsius() => _readDouble(
        Elm327Protocol.intakeAirTempCommand,
        Elm327Protocol.parseIntakeAirTempCelsius,
        label: 'intakeAirTemp',
      );

  /// Read absolute barometric pressure (kPa) via Mode 01 PID 0x33
  /// (#2456). Feeds the speed-density air-density correction so altitude
  /// / weather scale the air charge. Returns null when unsupported.
  @override
  Future<double?> readBaroPressureKpa() => _readDouble(
        Elm327Protocol.baroPressureCommand,
        Elm327Protocol.parseBaroPressureKpa,
        label: 'baroPressure',
      );

  /// Read the commanded fuel–air equivalence ratio φ via Mode 01 PID
  /// 0x44 (#2456; SAE convention verified #3426: φ > 1 rich, φ < 1
  /// lean). φ ≈ 1.0 at stoich; replaces the assumed stoich AFR in the
  /// MAF / speed-density fuel math via `effectiveAfrForPhi`. Returns
  /// null when unsupported.
  @override
  Future<double?> readCommandedEquivalenceRatio() => _readDouble(
        Elm327Protocol.commandedEquivalenceRatioCommand,
        Elm327Protocol.parseCommandedEquivalenceRatio,
        label: 'commandedEquivalenceRatio',
      );

  /// Read total MAF from the dual-sensor Mode 01 PID 0x66 (#3428).
  /// Preferred over the legacy PID 0x10 when supported. Null when
  /// unsupported / NO DATA.
  @override
  Future<double?> readMafSensorGramsPerSecond() => _readDouble(
        Elm327PrecisionPids.mafSensorCommand,
        Elm327PrecisionPids.parseMafSensorGramsPerSecond,
        label: 'mafSensor',
      );

  /// Read the direct engine fuel rate in g/s via Mode 01 PID 0x9D
  /// (#3428) — the top-precision mass-based branch (engine channel A/B
  /// only; the C/D vehicle channel is ignored, see the parser).
  @override
  Future<double?> readEngineFuelRateGramsPerSecond() => _readDouble(
        Elm327PrecisionPids.engineFuelRateGramsCommand,
        Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond,
        label: 'engineFuelRateGrams',
      );

  /// Read the cylinder fuel rate in mg/stroke via Mode 01 PID 0xA2
  /// (#3428). Needs RPM + cylinder count to become a mass flow.
  @override
  Future<double?> readCylinderFuelRateMgPerStroke() => _readDouble(
        Elm327PrecisionPids.cylinderFuelRateCommand,
        Elm327PrecisionPids.parseCylinderFuelRateMgPerStroke,
        label: 'cylinderFuelRate',
      );

  /// Read the measured ethanol fuel percentage via Mode 01 PID 0x52
  /// (#3429). Drives the dynamic petrol↔E85 AFR/density blend.
  @override
  Future<double?> readEthanolPercent() => _readDouble(
        Elm327PrecisionPids.ethanolPercentCommand,
        Elm327PrecisionPids.parseEthanolPercent,
        label: 'ethanolPercent',
      );

  /// Read one MEASURED wideband equivalence ratio φ (#3427): the first
  /// SUPPORTED sensor in bank-1-sensor-1-first order (0x24 / 0x34 lead
  /// their families). At most one Bluetooth round-trip — only the first
  /// supported PID is read; null when no wideband PID is supported or
  /// the read returned NO DATA.
  @override
  Future<double?> readMeasuredPhi() async {
    for (final pid in Elm327PrecisionPids.allWidebandPids) {
      if (!isPidKnownSupported(pid)) continue;
      return _readDouble(
        Elm327PrecisionPids.widebandCommand(pid),
        (raw) => Elm327PrecisionPids.parseEquivalenceRatioPhi(raw, pid),
        label: 'measuredPhi',
      );
    }
    return null;
  }

  /// Read short-term fuel trim bank 1 (%) (#813). Fast-feedback loop
  /// correction; the ECU adjusts this constantly to hit stoich.
  @override
  Future<double?> readShortTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.shortTermFuelTrimCommand,
        Elm327Protocol.parseShortTermFuelTrim,
        label: 'shortTermFuelTrim',
      );

  /// Read long-term fuel trim bank 1 (%) (#813). Slow-drifting
  /// correction that captures persistent offsets — altitude, air
  /// filter state, injector wear.
  @override
  Future<double?> readLongTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.longTermFuelTrimCommand,
        Elm327Protocol.parseLongTermFuelTrim,
        label: 'longTermFuelTrim',
      );

  /// Read short-term fuel trim bank 2 (%) via Mode 01 PID 0x08 (#2458).
  /// Only dual-bank (V / boxer) engines answer; inline engines return
  /// null and the correction stays on bank 1 alone.
  @override
  Future<double?> readShortTermFuelTrimBank2Percent() => _readDouble(
        Elm327Protocol.shortTermFuelTrimBank2Command,
        Elm327Protocol.parseShortTermFuelTrimBank2,
        label: 'shortTermFuelTrimBank2',
      );

  /// Read long-term fuel trim bank 2 (%) via Mode 01 PID 0x09 (#2458).
  /// Same dual-bank semantics as [readShortTermFuelTrimBank2Percent].
  @override
  Future<double?> readLongTermFuelTrimBank2Percent() => _readDouble(
        Elm327Protocol.longTermFuelTrimBank2Command,
        Elm327Protocol.parseLongTermFuelTrimBank2,
        label: 'longTermFuelTrimBank2',
      );

  /// Read absolute load value (%) via Mode 01 PID 0x43 (#2458). Exceeds
  /// 100 % on boosted engines under positive manifold pressure — a clean
  /// high-load proxy. Returns null when unsupported.
  Future<double?> readAbsoluteLoadPercent() => _readDouble(
        Elm327Protocol.absoluteLoadCommand,
        Elm327Protocol.parseAbsoluteLoad,
        label: 'absoluteLoad',
      );

  /// Read fuel tank level, 0–100 %. (#717)
  Future<double?> readFuelLevelPercent() => _readDouble(
        Elm327Protocol.fuelTankLevelCommand,
        Elm327Protocol.parseFuelLevelPercent,
        label: 'fuelLevel',
      );

  /// Read fuel type via Mode 01 PID 0x51 (#1399). Returns one of the
  /// project's `preferredFuelType` enum keys ("petrol", "diesel",
  /// "lpg", "cng", "electric") or null when:
  ///   * the adapter isn't connected,
  ///   * the ECU returned NO DATA (PID unsupported),
  ///   * the response carried a reserved / unknown fuel-type code.
  ///
  /// Used during the VIN-driven adapter-pair auto-population flow as
  /// the highest-priority signal — when this method returns a value,
  /// it overrides both the offline WMI decoder and the online vPIC
  /// `Fuel Type - Primary` field because PID 0x51 reports what the ECU
  /// is actually configured for at runtime.
  Future<String?> readFuelType() async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _send(Elm327Protocol.fuelTypeCommand);
      return Elm327Protocol.parseFuelType(response);
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readFuelType failed'); // #2855
      return null;
    }
  }

  /// Read the Vehicle Identification Number via Mode 09 PID 02 (#1399).
  ///
  /// Public wrapper around the same command path used internally by
  /// [_resolveVehicleCacheKey] (#811). Returns the parsed 17-character
  /// VIN, or null when the adapter isn't connected, the ECU returned
  /// NO DATA (most pre-2005 vehicles), or [Elm327Protocol.parseVin]
  /// could not extract 17 valid VIN characters from the response.
  ///
  /// The ELM327 typically auto-handles the multi-frame ISO-15765-2
  /// response — [Elm327Protocol.parseVin] strips the per-frame
  /// `49 02 NN` headers + padding and returns the trailing 17 ASCII
  /// chars.
  ///
  /// Errors are swallowed — every failure path returns null. The
  /// caller surfaces "couldn't read VIN" UX based on the null result;
  /// stack traces stay in the debug log via [debugPrint].
  Future<String?> readVin() async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _send(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(response);
      if (vin == null || vin.isEmpty) return null;
      return vin;
    } catch (e, st) {
      // #2763 — flaky readVin is expected: breadcrumb, not ERROR (see helper).
      recordObd2ReadFailure(e, st, where: 'OBD2 readVin');
      return null;
    }
  }

  Future<double?> _readDouble(
    String command,
    double? Function(String raw) parser, {
    required String label,
  }) async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _send(command);
      final value = parser(response);
      // #3532 — feed the probation state: a real NO DATA streak parks the
      // PID; any parsed value clears it. Transport faults (the catch
      // below) are link weather and deliberately count for nothing.
      _pids.noteMode01Reply(command, response, parsed: value != null);
      return value;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 read $label failed'); // #2855
      return null;
    }
  }
}
