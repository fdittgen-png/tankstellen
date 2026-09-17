// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_service.dart';

/// The typed PID read helpers extracted from [Obd2Service] as a `part`
/// mixin so they keep private-member access while `obd2_service.dart`
/// stays under the #1680 file-length cap (sanctioned #3760
/// decomposition — move-only, behaviour preserved): every `read*`
/// method plus the shared `_readDouble` parse/probation funnel.
mixin _Obd2ServiceReads on _Obd2ServiceLink {
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
  /// CONNECT livelock. The value feeds the power model through the session
  /// hook and returns for the recording loop's `bv` stamp. Null when not
  /// connected, unparsable, or out of bounds — #4325 counts the last.
  Future<double?> readBatteryVoltageV() async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _rawSend(Elm327Commands.readVoltageCommand);
      final volts = Elm327Protocol.decodeBatteryVoltage(response)
          .valueReporting(Obd2CommDiagnostics.instance.noteImplausibleFrame);
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

  /// Read mass air flow in g/s. (#717)
  Future<double?> readMafGramsPerSecond() => _readDouble(
        Elm327Protocol.mafCommand,
        Elm327Protocol.parseMafGramsPerSecond,
        label: 'maf',
      );

  /// Read intake manifold absolute pressure (kPa). (#800)
  Future<double?> readManifoldPressureKpa() => _readDouble(
        Elm327Protocol.intakeManifoldPressureCommand,
        Elm327Protocol.parseManifoldPressureKpa,
        label: 'manifoldPressure',
      );

  /// Read intake air temperature (°C). (#800)
  Future<double?> readIntakeAirTempCelsius() => _readDouble(
        Elm327Protocol.intakeAirTempCommand,
        Elm327Protocol.parseIntakeAirTempCelsius,
        label: 'intakeAirTemp',
      );

  /// Read short-term fuel trim bank 1 (%) (#813). Fast-feedback loop
  /// correction; the ECU adjusts this constantly to hit stoich.
  Future<double?> readShortTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.shortTermFuelTrimCommand,
        Elm327Protocol.parseShortTermFuelTrim,
        label: 'shortTermFuelTrim',
      );

  /// Read long-term fuel trim bank 1 (%) (#813). Slow-drifting
  /// correction that captures persistent offsets — altitude, air
  /// filter state, injector wear.
  Future<double?> readLongTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.longTermFuelTrimCommand,
        Elm327Protocol.parseLongTermFuelTrim,
        label: 'longTermFuelTrim',
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
