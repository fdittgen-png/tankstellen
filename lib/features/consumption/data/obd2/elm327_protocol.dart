/// ELM327 OBD-II command builder and response parser.
///
/// The ELM327 is an OBD-to-serial interpreter chip. Commands are ASCII
/// strings sent over serial/Bluetooth/TCP. Responses are hex-encoded
/// bytes terminated by '>'.
///
/// This module is transport-agnostic — it only builds command strings
/// and parses response strings. The actual I/O is handled by
/// [Obd2Transport].
class Elm327Protocol {
  const Elm327Protocol();

  // ---------------------------------------------------------------------------
  // AT (adapter configuration) commands
  // ---------------------------------------------------------------------------

  /// Reset the ELM327 to factory defaults.
  static const resetCommand = 'ATZ\r';

  /// Turn echo off (cleaner responses).
  static const echoOffCommand = 'ATE0\r';

  /// Set protocol to automatic detection.
  static const autoProtocolCommand = 'ATSP0\r';

  /// Turn off line feeds.
  static const lineFeedsOffCommand = 'ATL0\r';

  /// Turn off headers in responses.
  static const headersOffCommand = 'ATH0\r';

  /// Standard initialization sequence for a new connection.
  static const initCommands = [
    resetCommand,
    echoOffCommand,
    lineFeedsOffCommand,
    headersOffCommand,
    autoProtocolCommand,
  ];

  // ---------------------------------------------------------------------------
  // OBD-II Mode 01 PID commands
  // ---------------------------------------------------------------------------

  /// Request vehicle speed (km/h). Mode 01, PID 0D.
  static const vehicleSpeedCommand = '010D\r';

  /// Request engine RPM. Mode 01, PID 0C.
  static const engineRpmCommand = '010C\r';

  /// Request distance since DTC cleared (km). Mode 01, PID 31.
  static const distanceSinceDtcClearedCommand = '0131\r';

  /// Request odometer (km). Mode 01, PID A6.
  /// Note: Not supported by all vehicles.
  static const odometerCommand = '01A6\r';

  /// Request calculated engine load (%). Mode 01, PID 04. (#717)
  static const engineLoadCommand = '0104\r';

  /// Request absolute throttle position (%). Mode 01, PID 11. (#717)
  static const throttlePositionCommand = '0111\r';

  /// Request engine fuel rate (L/h). Mode 01, PID 5E. Modern cars
  /// (>= 2014-ish) answer directly; older cars return NO DATA and the
  /// app falls back to deriving from MAF. (#717)
  static const engineFuelRateCommand = '015E\r';

  /// Request mass air flow rate (g/s). Mode 01, PID 10. Used as a
  /// fallback to estimate fuel rate on cars that do not support PID 5E.
  /// (#717)
  static const mafCommand = '0110\r';

  /// Request fuel tank level input (%). Mode 01, PID 2F. (#717)
  static const fuelTankLevelCommand = '012F\r';

  // ---------------------------------------------------------------------------
  // Response parsing
  // ---------------------------------------------------------------------------

  /// Parse a raw ELM327 response string into usable data.
  ///
  /// Strips whitespace, '>', echo, and extracts the hex payload.
  /// Returns null if the response indicates an error or no data.
  static String? cleanResponse(String raw) {
    final cleaned = raw
        .replaceAll('>', '')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .trim();

    if (cleaned.isEmpty ||
        cleaned.contains('NO DATA') ||
        cleaned.contains('UNABLE TO CONNECT') ||
        cleaned.contains('ERROR') ||
        cleaned.contains('?')) {
      return null;
    }

    // Remove echo (command echo before response)
    // Response starts with "41" for Mode 01 responses
    final idx = cleaned.indexOf('41');
    if (idx >= 0) return cleaned.substring(idx).trim();

    return cleaned;
  }

  /// Parse vehicle speed from Mode 01 PID 0D response.
  /// Response format: "41 0D XX" where XX is speed in km/h.
  static int? parseVehicleSpeed(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = _parseHexBytes(clean);
    if (bytes.length < 3 || bytes[0] != 0x41 || bytes[1] != 0x0D) return null;

    return bytes[2]; // Speed in km/h (0-255)
  }

  /// Parse engine RPM from Mode 01 PID 0C response.
  /// Response format: "41 0C XX YY" where RPM = ((XX * 256) + YY) / 4.
  static double? parseEngineRpm(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = _parseHexBytes(clean);
    if (bytes.length < 4 || bytes[0] != 0x41 || bytes[1] != 0x0C) return null;

    return ((bytes[2] * 256) + bytes[3]) / 4.0;
  }

  /// Parse distance since DTC cleared from Mode 01 PID 31 response.
  /// Response format: "41 31 XX YY" where distance = (XX * 256) + YY km.
  static int? parseDistanceSinceDtcCleared(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = _parseHexBytes(clean);
    if (bytes.length < 4 || bytes[0] != 0x41 || bytes[1] != 0x31) return null;

    return (bytes[2] * 256) + bytes[3];
  }

  /// Parse odometer from Mode 01 PID A6 response.
  /// Response format: "41 A6 XX YY ZZ WW" where odometer = value / 10 km.
  static double? parseOdometer(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = _parseHexBytes(clean);
    if (bytes.length < 6 || bytes[0] != 0x41 || bytes[1] != 0xA6) return null;

    final value = (bytes[2] << 24) | (bytes[3] << 16) | (bytes[4] << 8) | bytes[5];
    return value / 10.0; // Odometer in km (1/10 km resolution)
  }

  /// Parse calculated engine load from Mode 01 PID 04 response (#717).
  /// Formula: load% = value × 100 / 255. Response: "41 04 XX".
  static double? parseEngineLoad(String raw) =>
      _parse1BytePercent(raw, 0x04);

  /// Parse absolute throttle position from Mode 01 PID 11 response
  /// (#717). Formula: throttle% = value × 100 / 255. Response:
  /// "41 11 XX".
  static double? parseThrottlePercent(String raw) =>
      _parse1BytePercent(raw, 0x11);

  /// Parse fuel tank level from Mode 01 PID 2F response (#717).
  /// Formula: level% = value × 100 / 255. Response: "41 2F XX".
  static double? parseFuelLevelPercent(String raw) =>
      _parse1BytePercent(raw, 0x2F);

  /// Parse engine fuel rate from Mode 01 PID 5E response (#717).
  /// Formula: L/h = ((A × 256) + B) × 0.05. Response: "41 5E XX YY".
  static double? parseFuelRateLPerHour(String raw) {
    final bytes = _parseModeOneBody(raw, 0x5E, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) * 0.05;
  }

  /// Parse mass air flow from Mode 01 PID 10 response (#717).
  /// Formula: g/s = ((A × 256) + B) × 0.01. Response: "41 10 XX YY".
  static double? parseMafGramsPerSecond(String raw) {
    final bytes = _parseModeOneBody(raw, 0x10, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) * 0.01;
  }

  /// Helper for every "1 byte, scaled to percent" PID (04, 11, 2F).
  static double? _parse1BytePercent(String raw, int expectedPid) {
    final bytes = _parseModeOneBody(raw, expectedPid, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2] * 100.0 / 255.0;
  }

  /// Shared plumbing: clean the response, verify the Mode 01 echo
  /// + expected PID, and return the byte array — or null when the
  /// response is missing / malformed.
  static List<int>? _parseModeOneBody(
    String raw,
    int expectedPid, {
    required int minBytes,
  }) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;
    final bytes = _parseHexBytes(clean);
    if (bytes.length < minBytes) return null;
    if (bytes[0] != 0x41 || bytes[1] != expectedPid) return null;
    return bytes;
  }

  /// Parse hex string "41 0D FF" into list of byte values [0x41, 0x0D, 0xFF].
  static List<int> _parseHexBytes(String hex) {
    return hex
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s, radix: 16))
        .whereType<int>()
        .toList();
  }
}
