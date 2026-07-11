// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';

/// The odometer fallback chain (#719, refactored in #950 phase 2),
/// extracted from [Obd2Service] in #3540. Holds no state — the service
/// hands it the send tear-off and the connectivity probe (primitives, not
/// the service itself).
///
/// Fallback chain:
///   1. PID A6 (standard, only on cars from ~2018+)
///   2. PID 31 (distance since DTC cleared) — proxy, resets on DTC
///   3. Manufacturer Mode 22 PID — resolution depends on
///      `odometerPidStrategy` (a primitive so this helper never imports
///      the vehicle feature — the service extracts it from the
///      `ReferenceVehicle`):
///        * When non-null (#950 path), dispatch on the strategy code
///          (`stdA6` / `psaUds` / `bmwCan` / `vwUds` / `unknown`).
///          `stdA6` and `unknown` short-circuit to null after the
///          standard PIDs fail; the others walk only the matching
///          catalog entry.
///        * When null (legacy path — no reference vehicle), identify
///          brand from the VIN and iterate every catalog entry for
///          that brand. Preserves pre-#950 behaviour for callers that
///          haven't been migrated yet.
///
/// Returns null when every layer fails, so callers can surface
/// "odometer not readable for your car" instead of a zero.
class Obd2OdometerReader {
  /// Sends one ELM command and returns the raw reply (the service's
  /// adapter-aware `_send`).
  final Future<String> Function(String command) send;

  /// Live transport connectivity — a disconnected link short-circuits
  /// to null without sending anything.
  final bool Function() isConnected;

  const Obd2OdometerReader({required this.send, required this.isConnected});

  Future<double?> read({String? odometerPidStrategy}) async {
    if (!isConnected()) return null;

    try {
      // 1. Direct odometer (standard PID A6)
      final a6 = await send(Elm327Protocol.odometerCommand);
      final odometer = Elm327Protocol.parseOdometer(a6);
      if (odometer != null) return odometer;

      // 2. Distance since DTC cleared (standard PID 31)
      final pid31 = await send(Elm327Protocol.distanceSinceDtcClearedCommand);
      final distance = Elm327Protocol.parseDistanceSinceDtcCleared(pid31);
      if (distance != null) return distance.toDouble();

      // 3. Manufacturer Mode 22 fallback.
      if (odometerPidStrategy != null) {
        return _readByStrategy(odometerPidStrategy);
      }

      // Legacy path: identify brand from VIN and iterate catalog.
      // Silent failure on unknown-brand is intentional — we'd rather
      // return null than spam the car with commands it rejects.
      final vinResponse = await send(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(vinResponse);
      final brand = vehicleBrandFromVin(vin);
      if (brand == VehicleBrand.unknown) return null;
      return _readFromCatalogByBrand(brand);
    } catch (_) {
      // #2379 — best-effort one-shot: an engine-off car times this out
      // routinely. NOT an error; the null return is the signal, no trace.
      return null;
    }
  }

  /// Resolve a `ReferenceVehicle.odometerPidStrategy` code to the
  /// corresponding manufacturer-catalog brand and walk that brand's
  /// entries. `stdA6` / `unknown` return null without sending any
  /// further commands — the standard PIDs already exhausted that path.
  /// `bmwCan` / `vwUds` route to the existing catalog rows; raw-CAN
  /// support beyond Mode 22 is a separate issue.
  Future<double?> _readByStrategy(String strategy) async {
    switch (strategy) {
      case 'psaUds':
        return _readFromCatalogByBrand(VehicleBrand.psa);
      case 'vwUds':
        return _readFromCatalogByBrand(VehicleBrand.vwGroup);
      case 'bmwCan':
        // Catalog ships a Mode 22 fallback for BMW; raw-CAN broadcast
        // (the literal "bmwCan" name) is a separate issue. Walk the
        // catalog entry — better than returning null for cars that
        // would otherwise answer 22 30 16.
        return _readFromCatalogByBrand(VehicleBrand.bmw);
      case 'stdA6':
      case 'unknown':
        return null;
      default:
        debugPrint('OBD2 readOdometer: unrecognised strategy "$strategy" — '
            'falling back to null');
        return null;
    }
  }

  Future<double?> _readFromCatalogByBrand(VehicleBrand brand) async {
    for (final entry in Elm327Protocol.mfgOdometerCatalog) {
      if (entry.brand != brand) continue;
      final response = await send(entry.command);
      final value = switch (entry.kind) {
        MfgOdometerKind.threeBytesKm => Elm327Protocol.parseMfgOdometer3Byte(
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
  }
}
