import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
import 'obd2_transport.dart';

/// High-level OBD-II service for reading vehicle data.
///
/// Wraps [Obd2Transport] and [Elm327Protocol] to provide a clean API
/// for reading odometer, speed, and other vehicle parameters.
class Obd2Service {
  final Obd2Transport _transport;

  Obd2Service(this._transport);

  /// `true` when the underlying [Obd2Transport] currently has an open
  /// connection to the vehicle's ELM327 adapter.
  bool get isConnected => _transport.isConnected;

  /// Connect and initialize the ELM327 adapter.
  Future<bool> connect() async {
    try {
      await _transport.connect();

      // Run initialization sequence
      for (final cmd in Elm327Protocol.initCommands) {
        await _transport.sendCommand(cmd);
        // Brief delay between init commands
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return true;
    } catch (e) {
      debugPrint('OBD2 connect failed: $e');
      return false;
    }
  }

  /// Read the odometer value in km.
  ///
  /// Fallback chain (#719):
  ///   1. PID A6 (standard, only on cars from ~2018+)
  ///   2. PID 31 (distance since DTC cleared) — proxy, resets on DTC
  ///   3. Manufacturer Mode 22 PID resolved from the car's VIN
  ///
  /// Returns null when every layer fails, so callers can surface
  /// "odometer not readable for your car" instead of a zero.
  Future<double?> readOdometerKm() async {
    if (!_transport.isConnected) return null;

    try {
      // 1. Direct odometer (standard PID A6)
      final a6 =
          await _transport.sendCommand(Elm327Protocol.odometerCommand);
      final odometer = Elm327Protocol.parseOdometer(a6);
      if (odometer != null) return odometer;

      // 2. Distance since DTC cleared (standard PID 31)
      final pid31 = await _transport
          .sendCommand(Elm327Protocol.distanceSinceDtcClearedCommand);
      final distance = Elm327Protocol.parseDistanceSinceDtcCleared(pid31);
      if (distance != null) return distance.toDouble();

      // 3. Manufacturer Mode 22 fallback. Identify brand from VIN and
      //    iterate every catalog entry for that brand. Silent failure
      //    on unknown-brand is intentional — we'd rather return null
      //    than spam the car with commands it rejects.
      final vinResponse =
          await _transport.sendCommand(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(vinResponse);
      final brand = vehicleBrandFromVin(vin);
      if (brand == VehicleBrand.unknown) return null;

      for (final entry in Elm327Protocol.mfgOdometerCatalog) {
        if (entry.brand != brand) continue;
        final response = await _transport.sendCommand(entry.command);
        final value = switch (entry.kind) {
          MfgOdometerKind.threeBytesKm =>
            Elm327Protocol.parseMfgOdometer3Byte(
              response,
              expectedPidHi: entry.pidHi,
              expectedPidLo: entry.pidLo,
            ),
          MfgOdometerKind.twoBytesKm => Elm327Protocol.parseMfgOdometer2Byte(
              response,
              expectedPidHi: entry.pidHi,
              expectedPidLo: entry.pidLo,
            ),
          MfgOdometerKind.twoBytesMilesTimes10 =>
            Elm327Protocol.parseMfgOdometerMilesTimes10(
              response,
              expectedPidHi: entry.pidHi,
              expectedPidLo: entry.pidLo,
            ),
        };
        if (value != null) return value;
      }
      return null;
    } catch (e) {
      debugPrint('OBD2 readOdometer failed: $e');
      return null;
    }
  }

  /// Read current vehicle speed in km/h.
  Future<int?> readSpeedKmh() async {
    if (!_transport.isConnected) return null;

    try {
      final response =
          await _transport.sendCommand(Elm327Protocol.vehicleSpeedCommand);
      return Elm327Protocol.parseVehicleSpeed(response);
    } catch (e) {
      debugPrint('OBD2 readSpeed failed: $e');
      return null;
    }
  }

  /// Read current engine RPM.
  Future<double?> readRpm() async {
    if (!_transport.isConnected) return null;

    try {
      final response =
          await _transport.sendCommand(Elm327Protocol.engineRpmCommand);
      return Elm327Protocol.parseEngineRpm(response);
    } catch (e) {
      debugPrint('OBD2 readRpm failed: $e');
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

  /// Read engine fuel rate in L/h. Three-step fallback chain (#717, #800):
  ///
  ///   1. **PID 5E** — direct `engine fuel rate` reading. Modern ECUs
  ///      (~2014+) answer directly. Best accuracy, preferred when
  ///      supported.
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
  /// [engineDisplacementCc] and [volumetricEfficiency] are per-vehicle
  /// constants for the step-3 fallback. Defaults are tuned for a 1.0 L
  /// NA petrol engine (matches the Peugeot 107 / Aygo / C1 class and
  /// covers many other sub-1.2 L city cars). A follow-up PR will plumb
  /// per-vehicle overrides from the vehicle profile.
  Future<double?> readFuelRateLPerHour({
    int engineDisplacementCc = 1000,
    double volumetricEfficiency = 0.85,
  }) async {
    // Step 1: direct fuel-rate PID.
    final direct = await _readDouble(
      Elm327Protocol.engineFuelRateCommand,
      Elm327Protocol.parseFuelRateLPerHour,
      label: 'fuelRate',
    );
    if (direct != null) return direct;

    // Step 2: MAF-based estimate.
    final maf = await readMafGramsPerSecond();
    if (maf != null) {
      // Stoichiometric petrol: AFR 14.7, density ~740 g/L.
      // L/h = MAF × 3600 / (14.7 × 740).
      return maf * 3600.0 / (14.7 * 740.0);
    }

    // Step 3: speed-density fallback. Requires MAP + IAT + RPM.
    final mapKpa = await readManifoldPressureKpa();
    final iatCelsius = await readIntakeAirTempCelsius();
    final rpm = await readRpm();
    if (mapKpa == null || iatCelsius == null || rpm == null) return null;
    return estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
    );
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
  static double? estimateFuelRateLPerHourFromMap({
    required double mapKpa,
    required double iatCelsius,
    required double rpm,
    required int engineDisplacementCc,
    required double volumetricEfficiency,
    double afr = 14.7,
    double fuelDensityGPerL = 740.0,
  }) {
    final iatKelvin = iatCelsius + 273.15;
    if (mapKpa <= 0 ||
        iatKelvin <= 0 ||
        rpm <= 0 ||
        engineDisplacementCc <= 0 ||
        volumetricEfficiency <= 0) {
      return null;
    }
    const gasConstant = 287.0; // J/(kg·K), dry air
    final mapPa = mapKpa * 1000.0;
    final displacementM3 = engineDisplacementCc / 1_000_000.0;
    final intakesPerSecond = rpm / 120.0;
    // Kilograms of air per second (ideal gas law × VE).
    final airMassKgPerS =
        (mapPa * displacementM3 * intakesPerSecond * volumetricEfficiency) /
            (gasConstant * iatKelvin);
    final airMassGPerS = airMassKgPerS * 1000.0;
    return airMassGPerS * 3600.0 / (afr * fuelDensityGPerL);
  }

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

  /// Read fuel tank level, 0–100 %. (#717)
  Future<double?> readFuelLevelPercent() => _readDouble(
        Elm327Protocol.fuelTankLevelCommand,
        Elm327Protocol.parseFuelLevelPercent,
        label: 'fuelLevel',
      );

  /// Close the transport connection. Safe to call multiple times.
  Future<void> disconnect() async {
    await _transport.disconnect();
  }

  Future<double?> _readDouble(
    String command,
    double? Function(String raw) parser, {
    required String label,
  }) async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _transport.sendCommand(command);
      return parser(response);
    } catch (e) {
      debugPrint('OBD2 read $label failed: $e');
      return null;
    }
  }
}
