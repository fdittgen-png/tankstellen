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

  /// Read engine fuel rate in L/h (#717). Falls back to deriving from
  /// MAF when PID 5E is unsupported — MAF's fuel-rate estimate is a
  /// useful approximation on older cars.
  Future<double?> readFuelRateLPerHour() async {
    final direct = await _readDouble(
      Elm327Protocol.engineFuelRateCommand,
      Elm327Protocol.parseFuelRateLPerHour,
      label: 'fuelRate',
    );
    if (direct != null) return direct;
    final maf = await readMafGramsPerSecond();
    if (maf == null) return null;
    // Stoichiometric petrol: ~14.7 g air per g fuel; petrol density
    // ~0.74 kg/L. Fuel rate (L/h) = MAF (g/s) * 3600 / (14.7 * 740).
    // Returns an approximation; good enough for trip averages on
    // vehicles that lack direct PID 5E.
    return maf * 3600.0 / (14.7 * 740.0);
  }

  /// Read mass air flow in g/s. (#717)
  Future<double?> readMafGramsPerSecond() => _readDouble(
        Elm327Protocol.mafCommand,
        Elm327Protocol.parseMafGramsPerSecond,
        label: 'maf',
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
