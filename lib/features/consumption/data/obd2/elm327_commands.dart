/// Coarse vehicle brand used to pick a manufacturer-specific odometer
/// PID when the standard PID A6 isn't supported (#719). The VIN's WMI
/// prefix (first 3 chars) maps to one of these.
enum VehicleBrand {
  vwGroup, // VW / Audi / Škoda / Seat
  bmw,
  mercedes,
  ford,
  psa, // Peugeot / Citroën / DS / Opel-Vauxhall
  renault,
  unknown,
}

/// Decode encoding shape per brand.
enum MfgOdometerKind {
  /// Response payload is a big-endian 3-byte unsigned integer in km.
  threeBytesKm,

  /// Response payload is a big-endian 2-byte unsigned integer in km.
  twoBytesKm,

  /// Response payload is a big-endian 2-byte value in miles × 10.
  twoBytesMilesTimes10,
}

class MfgOdometerEntry {
  final VehicleBrand brand;
  final String command;
  final int pidHi;
  final int pidLo;
  final MfgOdometerKind kind;

  const MfgOdometerEntry({
    required this.brand,
    required this.command,
    required this.pidHi,
    required this.pidLo,
    required this.kind,
  });
}

/// Map a WMI (first 3 VIN characters) to a [VehicleBrand]. Only
/// covers the brands that have entries in [Elm327Commands.mfgOdometerCatalog].
VehicleBrand vehicleBrandFromVin(String? vin) {
  if (vin == null || vin.length < 3) return VehicleBrand.unknown;
  final wmi = vin.substring(0, 3).toUpperCase();
  // VW / Audi / Skoda / Seat
  if (wmi.startsWith('WVW') ||
      wmi.startsWith('WAU') ||
      wmi.startsWith('TMB') ||
      wmi.startsWith('VSS') ||
      wmi.startsWith('3VW')) {
    return VehicleBrand.vwGroup;
  }
  if (wmi.startsWith('WBA') || wmi.startsWith('WBS') || wmi.startsWith('WMW')) {
    return VehicleBrand.bmw;
  }
  if (wmi.startsWith('WDB') || wmi.startsWith('WDD') || wmi.startsWith('W1K')) {
    return VehicleBrand.mercedes;
  }
  if (wmi.startsWith('WF0') ||
      wmi.startsWith('1FA') ||
      wmi.startsWith('1FM') ||
      wmi.startsWith('1FT')) {
    return VehicleBrand.ford;
  }
  if (wmi.startsWith('VF3') ||
      wmi.startsWith('VF7') ||
      wmi.startsWith('VR3') ||
      wmi.startsWith('VX1') ||
      wmi.startsWith('W0L')) {
    return VehicleBrand.psa;
  }
  if (wmi.startsWith('VF1') || wmi.startsWith('VF8')) {
    return VehicleBrand.renault;
  }
  return VehicleBrand.unknown;
}

/// ELM327 command constants — AT (adapter configuration) + OBD-II
/// Mode 01 / Mode 09 / Mode 22 PID request strings.
///
/// Extracted from [Elm327Protocol] so the command catalog can be
/// consumed without pulling in the parser machinery (#563).
class Elm327Commands {
  const Elm327Commands._();

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

  /// Request the supported-PID bitmaps for Mode 01, in groups of 32
  /// (#811). A modern vehicle answers each of these with 4 bytes of
  /// bitmap: bit N set means the car implements PID
  /// `0x{group_start + N}`. Seven commands cover every PID from 01
  /// to FF. Knowing which PIDs are implemented lets callers skip
  /// querying unsupported ones — saves Bluetooth bandwidth on every
  /// tick of the trip loop, especially on older cars where most of
  /// the PIDs we'd try are NO-DATA misses anyway.
  static const supportedPidsCommands = <String>[
    '0100\r', // PIDs 01–20
    '0120\r', // PIDs 21–40
    '0140\r', // PIDs 41–60
    '0160\r', // PIDs 61–80
    '0180\r', // PIDs 81–A0
    '01A0\r', // PIDs A1–C0
    '01C0\r', // PIDs C1–E0
  ];

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

  /// Request intake manifold absolute pressure (kPa). Mode 01, PID 0B.
  /// Second-tier fallback for fuel-rate estimation (#800): when a car
  /// has neither PID 5E nor a MAF sensor (e.g. Peugeot 107 1.0L 1KR-FE,
  /// which is speed-density), combining MAP with IAT, RPM, engine
  /// displacement and volumetric efficiency yields an approximate MAF
  /// via the ideal gas law — which the existing MAF→fuel math can
  /// then consume.
  static const intakeManifoldPressureCommand = '010B\r';

  /// Request intake air temperature (°C). Mode 01, PID 0F. Required
  /// input to the speed-density fuel-rate estimation (#800). Formula:
  /// °C = A − 40 (one-byte response).
  static const intakeAirTempCommand = '010F\r';

  /// Request short-term fuel trim, bank 1 (%). Mode 01, PID 06. Used
  /// to correct the MAF- and speed-density-based fuel-rate formulas
  /// for the ECU's real-time mixture adjustment (#813). Formula:
  /// trim% = (A − 128) × 100 / 128 (one-byte response, 128 = 0%).
  static const shortTermFuelTrimCommand = '0106\r';

  /// Request long-term fuel trim, bank 1 (%). Mode 01, PID 07. Same
  /// formula as STFT. LTFT drifts slowly and captures persistent
  /// mixture offsets (dirty air filter, wrong fuel grade, altitude).
  static const longTermFuelTrimCommand = '0107\r';

  /// Request fuel tank level input (%). Mode 01, PID 2F. (#717)
  static const fuelTankLevelCommand = '012F\r';

  /// Request Vehicle Identification Number. Mode 09, PID 02. Used to
  /// pick a manufacturer-specific odometer PID on cars that do not
  /// support the standard PID A6 (#719).
  static const vinCommand = '0902\r';

  /// Manufacturer odometer PID catalog, keyed by coarse brand. Each
  /// entry is the full "22 XX YY" command and the byte-length class
  /// its response follows (#719).
  ///
  /// Values collected from AndrOBD's manufacturer XML; treat as
  /// best-effort — ECU firmware varies even within a brand.
  static const mfgOdometerCatalog = <MfgOdometerEntry>[
    MfgOdometerEntry(
      brand: VehicleBrand.vwGroup,
      command: '222203\r',
      pidHi: 0x22,
      pidLo: 0x03,
      kind: MfgOdometerKind.threeBytesKm,
    ),
    MfgOdometerEntry(
      brand: VehicleBrand.bmw,
      command: '223016\r',
      pidHi: 0x30,
      pidLo: 0x16,
      kind: MfgOdometerKind.threeBytesKm,
    ),
    MfgOdometerEntry(
      brand: VehicleBrand.mercedes,
      command: '22F15B\r',
      pidHi: 0xF1,
      pidLo: 0x5B,
      kind: MfgOdometerKind.twoBytesKm,
    ),
    MfgOdometerEntry(
      brand: VehicleBrand.ford,
      command: '22404D\r',
      pidHi: 0x40,
      pidLo: 0x4D,
      kind: MfgOdometerKind.twoBytesMilesTimes10,
    ),
    MfgOdometerEntry(
      brand: VehicleBrand.psa,
      command: '22D101\r',
      pidHi: 0xD1,
      pidLo: 0x01,
      kind: MfgOdometerKind.twoBytesKm,
    ),
    MfgOdometerEntry(
      brand: VehicleBrand.renault,
      command: '222102\r',
      pidHi: 0x21,
      pidLo: 0x02,
      kind: MfgOdometerKind.threeBytesKm,
    ),
  ];
}
