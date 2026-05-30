// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  /// Describe the currently-active protocol as a NUMBER (#2261 concern
  /// 3). After ATSP0 has auto-negotiated, `ATDPN` returns the resolved
  /// protocol digit — prefixed with `A` when it was reached via the
  /// auto-search (e.g. `A6` ⇒ auto-found protocol 6, `6` ⇒ pinned 6).
  static const describeProtocolNumberCommand = 'ATDPN\r';

  /// Pin the ELM327 to protocol [n] directly (#2261 concern 3) — a warm
  /// connect skips the multi-second ATSP0 auto-search by replaying the
  /// protocol cached from the previous session. [n] is the bare ELM327
  /// protocol digit (1–9, A–C), i.e. the ATDPN value with the `A`
  /// auto-flag stripped.
  static String setProtocolCommand(String n) => 'ATSP$n\r';

  /// Turn off line feeds.
  static const lineFeedsOffCommand = 'ATL0\r';

  /// Turn off headers in responses.
  static const headersOffCommand = 'ATH0\r';

  /// Enable adaptive timing (#1904, mode corrected in #1918). `ATAT1`
  /// is the ELM327's **default and documented-recommended** adaptive
  /// mode: it sets each request's timeout from the vehicle's actual
  /// response times and re-learns as bus load changes. `ATAT2` (the
  /// more *aggressive* variant #1904 originally shipped) cut ECU
  /// replies short on some adapters — a recording regression — so the
  /// init sequence pins the recommended `ATAT1` explicitly.
  static const adaptiveTimingCommand = 'ATAT1\r';

  /// Standard initialization sequence for a new connection. `ATAT1` is
  /// sent last, after the protocol is selected, so the adaptive-timing
  /// algorithm is in effect for the very first OBD request.
  static const initCommands = [
    resetCommand,
    echoOffCommand,
    lineFeedsOffCommand,
    headersOffCommand,
    autoProtocolCommand,
    adaptiveTimingCommand,
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

  /// Request engine coolant temperature (°C). Mode 01, PID 05.
  /// Formula: °C = A − 40 (one-byte response). Used by the cold-start
  /// surcharge heuristic (#1262) to flag short trips where the engine
  /// never reached operating temperature and consumed proportionally
  /// more fuel for warm-up than for forward motion.
  static const coolantTempCommand = '0105\r';

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

  /// Request commanded equivalence ratio / λ. Mode 01, PID 44 (#2456).
  /// Formula: λ = (256·A + B) / 32768 (dimensionless). λ ≈ 1.0 at
  /// stoichiometry; <1 is a lean cruise mixture, >1 is power-enrichment.
  /// Replacing the assumed-stoich AFR with `stoichAFR × λ` is the biggest
  /// fuel-estimate accuracy win on the no-MAF speed-density path (the
  /// Peugeot). Response: "41 44 XX YY".
  static const commandedEquivalenceRatioCommand = '0144\r';

  /// Request absolute barometric pressure (kPa). Mode 01, PID 33 (#2456).
  /// Single-byte raw value. Already read best-effort by
  /// `broken_map_detector`; now promoted to a first-class parser so the
  /// speed-density estimator can feed measured ambient pressure
  /// (altitude / weather) into the ideal-gas air-mass term instead of an
  /// assumed sea-level value. Response: "41 33 XX".
  static const baroPressureCommand = '0133\r';

  /// Request short-term fuel trim, bank 2 (%). Mode 01, PID 08 (#2458).
  /// Same formula as bank-1 STFT (`trim% = (A − 128) × 100 / 128`).
  /// Only V-engines / boxer layouts run a second bank; on inline engines
  /// the PID is absent and the fuel derivation stays on the bank-1
  /// correction. Response: "41 08 XX".
  static const shortTermFuelTrimBank2Command = '0108\r';

  /// Request long-term fuel trim, bank 2 (%). Mode 01, PID 09 (#2458).
  /// Same formula / bank-2 semantics as [shortTermFuelTrimBank2Command].
  /// Captures the slow per-bank mixture offset on dual-bank engines.
  /// Response: "41 09 XX".
  static const longTermFuelTrimBank2Command = '0109\r';

  /// Request absolute load value (%). Mode 01, PID 43 (#2458). Formula:
  /// `load% = (256·A + B) × 100 / 255`. Unlike calculated engine load
  /// (PID 04, capped at 100 %), absolute load is normalised against a
  /// naturally-aspirated reference and so **exceeds 100 %** on boosted
  /// engines under positive manifold pressure — a clean high-load proxy.
  /// Response: "41 43 XX YY".
  static const absoluteLoadCommand = '0143\r';

  /// Request accelerator-pedal position D (%). Mode 01, PID 49 (#2458).
  /// Formula: `% = A × 100 / 255`. One of three pedal channels the ECU
  /// may expose (D/E/F, PIDs 49/4A/4B); the snapshot subscribes whichever
  /// the car supports and takes the max as driver intent. Response:
  /// "41 49 XX".
  static const acceleratorPedalDCommand = '0149\r';

  /// Request accelerator-pedal position E (%). Mode 01, PID 4A (#2458).
  /// Same `A × 100 / 255` encoding as [acceleratorPedalDCommand].
  /// Response: "41 4A XX".
  static const acceleratorPedalECommand = '014A\r';

  /// Request accelerator-pedal position F (%). Mode 01, PID 4B (#2458).
  /// Same `A × 100 / 255` encoding as [acceleratorPedalDCommand].
  /// Response: "41 4B XX".
  static const acceleratorPedalFCommand = '014B\r';

  /// Request engine oil temperature (°C). Mode 01, PID 5C (#2459).
  /// Formula: °C = A − 40 (one-byte response, same encoding as coolant /
  /// IAT). Persisted as an optional diagnostic context signal — slower
  /// thermal mass than coolant, useful for warm-up modelling. Response:
  /// "41 5C XX".
  static const engineOilTempCommand = '015C\r';

  /// Request ambient air temperature (°C). Mode 01, PID 46 (#2459).
  /// Formula: °C = A − 40 (one-byte response). The true outside-air
  /// temperature (vs IAT, which sits behind the intake and reads warm);
  /// persisted as optional diagnostic context for air-density modelling.
  /// Response: "41 46 XX".
  static const ambientAirTempCommand = '0146\r';

  /// Request fuel type. Mode 01, PID 51. (#1399). Single-byte response
  /// per SAE-J1979 Table 6 — see [Elm327Parsers.parseFuelType] for the
  /// mapping. Used during the VIN-driven adapter-pair auto-population
  /// flow as a confirmation/override signal: when the ECU reports a
  /// fuel type via PID 0x51, that wins over both the offline WMI
  /// decoder and the online vPIC response.
  static const fuelTypeCommand = '0151\r';

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
