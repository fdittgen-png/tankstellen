/// ELM327 response parsers — pure string→value decoders for Mode 01,
/// Mode 09 and Mode 22 responses.
///
/// Extracted from [Elm327Protocol] so the parser logic lives next to
/// its own unit tests without dragging in the command catalog (#563).
class Elm327Parsers {
  const Elm327Parsers._();

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

  /// Parse intake manifold absolute pressure from Mode 01 PID 0B
  /// response (#800). Formula: kPa = A (single byte, raw value).
  /// Response: "41 0B XX". Physical range 0–255 kPa — idle around
  /// 30–40 kPa, wide-open throttle approaches atmospheric (~100 kPa)
  /// on NA engines, and up to 200+ kPa on turbocharged engines.
  static double? parseManifoldPressureKpa(String raw) {
    final bytes = _parseModeOneBody(raw, 0x0B, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble();
  }

  /// Parse intake air temperature from Mode 01 PID 0F response (#800).
  /// Formula: °C = A − 40 (single byte). Response: "41 0F XX". Range
  /// −40 °C to 215 °C covers every drivable condition the sensor sees.
  static double? parseIntakeAirTempCelsius(String raw) {
    final bytes = _parseModeOneBody(raw, 0x0F, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble() - 40.0;
  }

  /// Parse short-term fuel trim bank 1 from Mode 01 PID 06 response
  /// (#813). Formula: `trim% = (A − 128) × 100 / 128`. Midpoint 128
  /// = 0 % (stoichiometric); <128 means the ECU is leaning the
  /// mixture (adding less fuel than stoich), >128 means it's
  /// enriching. Response: "41 06 XX". Valid range roughly
  /// −100 % … +99 %.
  static double? parseShortTermFuelTrim(String raw) =>
      _parseFuelTrim(raw, 0x06);

  /// Parse long-term fuel trim bank 1 from Mode 01 PID 07 response
  /// (#813). Same formula as STFT — captures persistent mixture
  /// offsets rather than the fast-feedback loop.
  static double? parseLongTermFuelTrim(String raw) =>
      _parseFuelTrim(raw, 0x07);

  /// Shared fuel-trim decoder used by PIDs 06 / 07 (and 08 / 09 when
  /// we add bank-2 support). Returns null on NO DATA.
  static double? _parseFuelTrim(String raw, int expectedPid) {
    final bytes = _parseModeOneBody(raw, expectedPid, minBytes: 3);
    if (bytes == null) return null;
    return (bytes[2] - 128) * 100.0 / 128.0;
  }

  /// Helper for every "1 byte, scaled to percent" PID (04, 11, 2F).
  static double? _parse1BytePercent(String raw, int expectedPid) {
    final bytes = _parseModeOneBody(raw, expectedPid, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2] * 100.0 / 255.0;
  }

  /// Parse a supported-PIDs bitmap response (#811).
  ///
  /// For a `01 XX` request where `XX ∈ {00, 20, 40, 60, 80, A0, C0}`,
  /// the response is `41 XX AA BB CC DD` with AA–DD a 32-bit
  /// big-endian bitmap. Bit-N of the bitmap (MSB = bit 31) set means
  /// PID `(XX + 1 + (31 − N))` is supported. Equivalently: PID
  /// `(groupBase + 1 + bitIndexFromLeft)`.
  ///
  /// Returns the concrete set of supported PID integers, or null on
  /// NO DATA / malformed response. Each bitmap covers PIDs
  /// `groupBase+1` through `groupBase+32` inclusive.
  ///
  /// The last bit of each bitmap is conventionally "are PIDs in the
  /// next range also supported?"; callers use that to decide whether
  /// to query the next `01 {next_group}` command.
  static Set<int>? parseSupportedPidsBitmap(String raw, int groupBase) {
    final bytes = _parseModeOneBody(raw, groupBase, minBytes: 6);
    if (bytes == null) return null;
    final supported = <int>{};
    // Iterate the four payload bytes, most-significant bit first.
    for (var byteIndex = 0; byteIndex < 4; byteIndex++) {
      final payload = bytes[2 + byteIndex];
      for (var bit = 0; bit < 8; bit++) {
        final mask = 1 << (7 - bit);
        if ((payload & mask) != 0) {
          // First bit of the first byte → PID groupBase+1, etc.
          supported.add(groupBase + 1 + (byteIndex * 8) + bit);
        }
      }
    }
    return supported;
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

  /// Parse a 3-byte (big-endian, km) manufacturer odometer — used by
  /// VW group (22 22 03), BMW (22 30 16), Renault (22 21 02), etc.
  /// Expected response: `62 PH PL A B C` → km = (A*65536)+(B*256)+C.
  /// Returns null on NO DATA or a PID-echo mismatch. (#719)
  static double? parseMfgOdometer3Byte(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) {
    final bytes = _parseMode22Body(raw, expectedPidHi, expectedPidLo,
        minBytes: 6);
    if (bytes == null) return null;
    final value = (bytes[3] << 16) | (bytes[4] << 8) | bytes[5];
    return value.toDouble();
  }

  /// Parse a 2-byte (big-endian, km) manufacturer odometer — used by
  /// Mercedes (22 F1 5B), PSA (22 D1 01). Expected response:
  /// `62 PH PL A B` → km = (A*256)+B. (#719)
  static double? parseMfgOdometer2Byte(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) {
    final bytes = _parseMode22Body(raw, expectedPidHi, expectedPidLo,
        minBytes: 5);
    if (bytes == null) return null;
    final value = (bytes[3] << 8) | bytes[4];
    return value.toDouble();
  }

  /// Parse a Ford-style 2-byte miles-times-10 odometer (22 40 4D).
  /// Response: `62 40 4D A B` → miles_x10 = (A*256)+B. The raw value
  /// is miles × 10, so divide by 10 before converting to km. (#719)
  static double? parseMfgOdometerMilesTimes10(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) {
    final bytes = _parseMode22Body(raw, expectedPidHi, expectedPidLo,
        minBytes: 5);
    if (bytes == null) return null;
    final milesTimes10 = (bytes[3] << 8) | bytes[4];
    return (milesTimes10 / 10.0) * 1.609344;
  }

  /// Parse the ASCII VIN from a Mode 09 PID 02 response. ELM frames
  /// the 17-byte VIN across 4–5 CAN frames, each prefixed with the
  /// 3-byte header `49 02 NN` (where NN is a frame counter).
  ///
  /// We concatenate the hex payload and decode as ASCII, skipping:
  /// - frame-header bytes (0x49 'I' — not a valid VIN char anyway,
  ///   VIN excludes I/O/Q to avoid confusion with 1/0);
  /// - padding zeros;
  /// - any other non-printable byte.
  ///
  /// Returns the last 17 printable characters, which is the VIN for
  /// well-formed responses. Returns null on NO DATA or < 17 chars. (#719)
  static String? parseVin(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;
    final tokens =
        clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final chars = <int>[];
    for (final token in tokens) {
      final byte = int.tryParse(token, radix: 16);
      if (byte == null) continue;
      // Digits 0-9.
      if (byte >= 0x30 && byte <= 0x39) {
        chars.add(byte);
        continue;
      }
      // Upper-case letters A-Z, except I/O/Q (reserved — the 'I' that
      // appears in frame headers is excluded by this rule).
      if (byte >= 0x41 &&
          byte <= 0x5A &&
          byte != 0x49 &&
          byte != 0x4F &&
          byte != 0x51) {
        chars.add(byte);
      }
    }
    if (chars.length < 17) return null;
    return String.fromCharCodes(chars.sublist(chars.length - 17));
  }

  static List<int>? _parseMode22Body(
    String raw,
    int expectedPidHi,
    int expectedPidLo, {
    required int minBytes,
  }) {
    final clean = cleanResponse22(raw);
    if (clean == null) return null;
    final bytes = _parseHexBytes(clean);
    if (bytes.length < minBytes) return null;
    if (bytes[0] != 0x62 ||
        bytes[1] != expectedPidHi ||
        bytes[2] != expectedPidLo) {
      return null;
    }
    return bytes;
  }

  /// Mode 22 response cleaner. Same as [cleanResponse] but anchors on
  /// the "62" Mode 22 echo instead of "41".
  static String? cleanResponse22(String raw) {
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
    final idx = cleaned.indexOf('62');
    if (idx >= 0) return cleaned.substring(idx).trim();
    return cleaned;
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
