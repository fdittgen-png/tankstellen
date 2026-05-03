/// ELM327 OBD-II protocol module.
///
/// The ELM327 is an OBD-to-serial interpreter chip. Commands are ASCII
/// strings sent over serial/Bluetooth/TCP. Responses are hex-encoded
/// bytes terminated by '>'.
///
/// This module is transport-agnostic — it only builds command strings
/// and parses response strings. The actual I/O is handled by
/// `Obd2Transport`.
///
/// Structure (split in #563 for readability — previously a single
/// 600-line file):
/// - [Elm327Commands] in `elm327_commands.dart` — AT setup + OBD-II PID
///   request strings + manufacturer odometer catalog.
/// - [Elm327Parsers] in `elm327_parsers.dart` — pure string→value
///   decoders for Mode 01, Mode 09 and Mode 22 responses.
/// - [Elm327Protocol] (this file) — backwards-compatible facade. Every
///   pre-split call site (`Elm327Protocol.xxxCommand`,
///   `Elm327Protocol.parseXxx(...)`) still resolves here and delegates
///   to [Elm327Commands] / [Elm327Parsers]. New code should import
///   the commands / parsers libraries directly.
library;

import 'elm327_commands.dart';
import 'elm327_parsers.dart';

export 'elm327_commands.dart';
export 'elm327_parsers.dart';

/// Backwards-compatible facade over [Elm327Commands] + [Elm327Parsers].
///
/// Kept static-only so existing call sites (`Elm327Protocol.xxx`) keep
/// working without edits. Prefer importing [Elm327Commands] or
/// [Elm327Parsers] directly in new code.
class Elm327Protocol {
  const Elm327Protocol();

  // ---------------------------------------------------------------------------
  // AT (adapter configuration) commands — delegated to [Elm327Commands].
  // ---------------------------------------------------------------------------

  static const resetCommand = Elm327Commands.resetCommand;
  static const echoOffCommand = Elm327Commands.echoOffCommand;
  static const autoProtocolCommand = Elm327Commands.autoProtocolCommand;
  static const lineFeedsOffCommand = Elm327Commands.lineFeedsOffCommand;
  static const headersOffCommand = Elm327Commands.headersOffCommand;
  static const initCommands = Elm327Commands.initCommands;

  // ---------------------------------------------------------------------------
  // OBD-II Mode 01 / Mode 09 PID commands — delegated to [Elm327Commands].
  // ---------------------------------------------------------------------------

  static const vehicleSpeedCommand = Elm327Commands.vehicleSpeedCommand;
  static const supportedPidsCommands = Elm327Commands.supportedPidsCommands;
  static const engineRpmCommand = Elm327Commands.engineRpmCommand;
  static const distanceSinceDtcClearedCommand =
      Elm327Commands.distanceSinceDtcClearedCommand;
  static const odometerCommand = Elm327Commands.odometerCommand;
  static const engineLoadCommand = Elm327Commands.engineLoadCommand;
  static const coolantTempCommand = Elm327Commands.coolantTempCommand;
  static const throttlePositionCommand = Elm327Commands.throttlePositionCommand;
  static const engineFuelRateCommand = Elm327Commands.engineFuelRateCommand;
  static const mafCommand = Elm327Commands.mafCommand;
  static const intakeManifoldPressureCommand =
      Elm327Commands.intakeManifoldPressureCommand;
  static const intakeAirTempCommand = Elm327Commands.intakeAirTempCommand;
  static const shortTermFuelTrimCommand =
      Elm327Commands.shortTermFuelTrimCommand;
  static const longTermFuelTrimCommand = Elm327Commands.longTermFuelTrimCommand;
  static const fuelTankLevelCommand = Elm327Commands.fuelTankLevelCommand;
  static const fuelTypeCommand = Elm327Commands.fuelTypeCommand;
  static const vinCommand = Elm327Commands.vinCommand;
  static const mfgOdometerCatalog = Elm327Commands.mfgOdometerCatalog;

  // ---------------------------------------------------------------------------
  // Response parsing — delegated to [Elm327Parsers].
  // ---------------------------------------------------------------------------

  static String? cleanResponse(String raw) => Elm327Parsers.cleanResponse(raw);

  static int? parseVehicleSpeed(String raw) =>
      Elm327Parsers.parseVehicleSpeed(raw);

  static double? parseEngineRpm(String raw) =>
      Elm327Parsers.parseEngineRpm(raw);

  static int? parseDistanceSinceDtcCleared(String raw) =>
      Elm327Parsers.parseDistanceSinceDtcCleared(raw);

  static double? parseOdometer(String raw) => Elm327Parsers.parseOdometer(raw);

  static double? parseEngineLoad(String raw) =>
      Elm327Parsers.parseEngineLoad(raw);

  static double? parseThrottlePercent(String raw) =>
      Elm327Parsers.parseThrottlePercent(raw);

  static double? parseFuelLevelPercent(String raw) =>
      Elm327Parsers.parseFuelLevelPercent(raw);

  static double? parseFuelRateLPerHour(String raw) =>
      Elm327Parsers.parseFuelRateLPerHour(raw);

  static double? parseMafGramsPerSecond(String raw) =>
      Elm327Parsers.parseMafGramsPerSecond(raw);

  static double? parseManifoldPressureKpa(String raw) =>
      Elm327Parsers.parseManifoldPressureKpa(raw);

  static double? parseIntakeAirTempCelsius(String raw) =>
      Elm327Parsers.parseIntakeAirTempCelsius(raw);

  static double? parseCoolantTempCelsius(String raw) =>
      Elm327Parsers.parseCoolantTempCelsius(raw);

  static double? parseShortTermFuelTrim(String raw) =>
      Elm327Parsers.parseShortTermFuelTrim(raw);

  static double? parseLongTermFuelTrim(String raw) =>
      Elm327Parsers.parseLongTermFuelTrim(raw);

  static Set<int>? parseSupportedPidsBitmap(String raw, int groupBase) =>
      Elm327Parsers.parseSupportedPidsBitmap(raw, groupBase);

  static double? parseMfgOdometer3Byte(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) =>
      Elm327Parsers.parseMfgOdometer3Byte(
        raw,
        expectedPidHi: expectedPidHi,
        expectedPidLo: expectedPidLo,
      );

  static double? parseMfgOdometer2Byte(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) =>
      Elm327Parsers.parseMfgOdometer2Byte(
        raw,
        expectedPidHi: expectedPidHi,
        expectedPidLo: expectedPidLo,
      );

  static double? parseMfgOdometerMilesTimes10(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) =>
      Elm327Parsers.parseMfgOdometerMilesTimes10(
        raw,
        expectedPidHi: expectedPidHi,
        expectedPidLo: expectedPidLo,
      );

  static String? parseVin(String raw) => Elm327Parsers.parseVin(raw);

  static String? parseFuelType(String raw) =>
      Elm327Parsers.parseFuelType(raw);

  static String? cleanResponse22(String raw) =>
      Elm327Parsers.cleanResponse22(raw);
}
