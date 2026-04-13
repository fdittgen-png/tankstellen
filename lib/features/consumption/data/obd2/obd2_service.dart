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

  /// Close the transport connection. Safe to call multiple times.
  Future<void> disconnect() async {
    await _transport.disconnect();
  }
}
