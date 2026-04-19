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
  /// Tries PID A6 (direct odometer) first, then falls back to PID 31
  /// (distance since DTC cleared) if not supported.
  Future<double?> readOdometerKm() async {
    if (!_transport.isConnected) return null;

    try {
      // Try direct odometer first (PID A6)
      final odometerResponse =
          await _transport.sendCommand(Elm327Protocol.odometerCommand);
      final odometer = Elm327Protocol.parseOdometer(odometerResponse);
      if (odometer != null) return odometer;

      // Fallback: distance since DTC cleared (PID 31)
      final distResponse = await _transport.sendCommand(
          Elm327Protocol.distanceSinceDtcClearedCommand);
      final distance = Elm327Protocol.parseDistanceSinceDtcCleared(distResponse);
      if (distance != null) return distance.toDouble();

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
