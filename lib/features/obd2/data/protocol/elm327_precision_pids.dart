// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'elm327_decode_util.dart';

/// Commands + parsers for the consumption-precision PID families added by
/// Epic #3416 (kept out of the line-capped `elm327_commands.dart` /
/// `elm327_parsers.dart`, mirroring the `elm327_mode22_parsers.dart` split):
///
///   - **Wideband O2 equivalence ratio** — PIDs 0x24–0x2B (ratio + voltage)
///     and 0x34–0x3B (ratio + current), #3427. Bytes A/B carry the MEASURED
///     fuel–air equivalence ratio φ; C/D carry the sensor voltage / current
///     (not needed for fuel math, ignored here).
///   - **MAF sensor A/B** — PID 0x66 (#3428), the modern dual-sensor MAF.
///   - **Engine fuel rate (g/s)** — PID 0x9D (#3428), the direct mass-based
///     rate that needs no AFR / VE / λ guess at all.
///   - **Cylinder fuel rate (mg/stroke)** — PID 0xA2 (#3428).
///   - **Ethanol fuel %** — PID 0x52 (#3429), drives the dynamic petrol↔E85
///     AFR / density blend.
///
/// ## The equivalence-ratio convention (SAE J1979 / J1979-DA, #3426)
///
/// SAE J1979-DA names PIDs 0x24–0x2B / 0x34–0x3B / 0x44 the *"Fuel–Air
/// equivalence ratio"*: φ = (F/A)actual / (F/A)stoich. **φ > 1 is RICH**
/// (more fuel per unit air), **φ < 1 is LEAN**; λ (the excess-air ratio,
/// AFR_actual / AFR_stoich) is its reciprocal, λ = 1/φ. The wire encoding
/// for the ratio bytes is `(256·A + B) × 2 / 65536` (= `/ 32768`), range
/// 0 … <2, with 1.0 = stoichiometry. Every parser in this file returns the
/// raw φ value under that convention — see `effectiveAfrForPhi` in
/// `fuel_rate_estimator.dart` for how it becomes an effective AFR
/// (`stoichAFR / φ`, equivalently `stoichAFR × λ`).
class Elm327PrecisionPids {
  const Elm327PrecisionPids._();

  /// Wideband O2 sensor PIDs whose C/D bytes are the sensor VOLTAGE
  /// (0x24 = sensor 1 … 0x2B = sensor 8, #3427). Bank/sensor layout is
  /// ECU-specific, but sensor 1 (0x24) is bank-1-sensor-1 on virtually
  /// every production layout — the primary fuel-control sensor.
  static const List<int> widebandVoltagePids = [
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B,
  ];

  /// Wideband O2 sensor PIDs whose C/D bytes are the sensor CURRENT
  /// (0x34 = sensor 1 … 0x3B = sensor 8, #3427). Same ratio encoding in
  /// bytes A/B as [widebandVoltagePids]; only the paired electrical
  /// channel differs.
  static const List<int> widebandCurrentPids = [
    0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B,
  ];

  /// Every wideband equivalence-ratio PID, voltage-paired sensors first.
  /// Order matters: sensor 1 of each family leads, so "first fresh entry"
  /// scans give bank-1-sensor-1 priority (#3427).
  static const List<int> allWidebandPids = [
    ...widebandVoltagePids,
    ...widebandCurrentPids,
  ];

  /// Build the Mode 01 request for one wideband O2 PID (#3427), e.g.
  /// `0x24` → `"0124\r"`.
  static String widebandCommand(int pid) =>
      '01${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}\r';

  /// Request the dual-channel MAF sensor (g/s). Mode 01, PID 0x66 (#3428).
  /// Preferred over the legacy single-channel PID 0x10 when supported.
  static const mafSensorCommand = '0166\r';

  /// Request engine fuel rate in g/s. Mode 01, PID 0x9D (#3428). The
  /// direct MASS-based rate — the top-precision fuel branch (needs only a
  /// fuel density to become L/h; no AFR / VE / φ guess).
  static const engineFuelRateGramsCommand = '019D\r';

  /// Request cylinder fuel rate in mg/stroke. Mode 01, PID 0xA2 (#3428).
  static const cylinderFuelRateCommand = '01A2\r';

  /// Request ethanol fuel percentage. Mode 01, PID 0x52 (#3429).
  static const ethanolPercentCommand = '0152\r';

  /// Parse the MEASURED fuel–air equivalence ratio φ from a wideband O2
  /// response (#3427). Response: `"41 <pid> AA BB CC DD"`; the ratio is
  /// `(256·A + B) × 2 / 65536` (dimensionless, 0 … <2, 1.0 = stoich;
  /// φ > 1 rich, φ < 1 lean — SAE J1979-DA, see the class doc). The C/D
  /// voltage / current bytes are ignored. Only the A/B bytes are required
  /// (`minBytes: 4`) so an adapter that clips the trailing electrical
  /// channel still yields the ratio.
  ///
  /// Returns null on NO DATA / malformed frames AND on an all-zero ratio:
  /// φ = 0 encodes "ratio not available from this sensor right now", not a
  /// real mixture, and letting it through would zero the derived fuel.
  static double? parseEquivalenceRatioPhi(String raw, int pid) {
    final bytes = parseModeOneBody(raw, pid, minBytes: 4);
    if (bytes == null) return null;
    final phi = ((bytes[2] * 256) + bytes[3]) * 2.0 / 65536.0;
    return phi <= 0 ? null : phi;
  }

  /// Parse total mass air flow (g/s) from a Mode 01 PID 0x66 response
  /// (#3428). Response: `"41 66 A B C D E"` where A is the
  /// supported-sensor bitmap (bit 0 = sensor A, bit 1 = sensor B) and each
  /// sensor reads `(256·hi + lo) / 32` g/s.
  ///
  /// When BOTH sensors are flagged the two readings are **summed**: a
  /// production dual-MAF installation meters one intake bank per sensor
  /// (V-engines), so total engine airflow — what the fuel math divides —
  /// is the sum. (A redundant same-duct twin-sensor layout would want the
  /// mean, but that layout is not used on production dual-MAF engines;
  /// documented per #3428.) A single flagged sensor returns its own value.
  /// Returns null when no sensor is flagged or the frame is malformed.
  static double? parseMafSensorGramsPerSecond(String raw) {
    final bytes = parseModeOneBody(raw, 0x66, minBytes: 3);
    if (bytes == null) return null;
    final support = bytes[2];
    double? total;
    if ((support & 0x01) != 0 && bytes.length >= 5) {
      total = ((bytes[3] * 256) + bytes[4]) / 32.0;
    }
    if ((support & 0x02) != 0 && bytes.length >= 7) {
      total = (total ?? 0.0) + ((bytes[5] * 256) + bytes[6]) / 32.0;
    }
    return total;
  }

  /// Parse ENGINE fuel rate in g/s from a Mode 01 PID 0x9D response
  /// (#3428). SAE J1979-DA defines 0x9D as TWO 2-byte channels at
  /// 0.02 g/s resolution: bytes A/B = **engine** fuel rate (fuel consumed
  /// by the engine itself) and bytes C/D = **vehicle** fuel rate (engine +
  /// fuel-fired auxiliaries). The channels are NOT summed — the engine
  /// channel alone is the figure the trip fuel math wants, so this parser
  /// returns `(256·A + B) × 0.02` and ignores C/D. Only A/B are required
  /// (`minBytes: 4`).
  static double? parseEngineFuelRateGramsPerSecond(String raw) {
    final bytes = parseModeOneBody(raw, 0x9D, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) * 0.02;
  }

  /// Parse cylinder fuel rate in mg/stroke from a Mode 01 PID 0xA2
  /// response (#3428). Formula: `(256·A + B) / 32` mg per cylinder per
  /// intake stroke. Converting to g/s needs RPM + the cylinder count —
  /// see `cylinderFuelRateToGramsPerSecond` in `fuel_mixture_model.dart`.
  static double? parseCylinderFuelRateMgPerStroke(String raw) {
    final bytes = parseModeOneBody(raw, 0xA2, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) / 32.0;
  }

  /// Parse ethanol fuel percentage from a Mode 01 PID 0x52 response
  /// (#3429). Formula: `A × 100 / 255` (%). Flexfuel ECUs report the
  /// measured blend so E10 reads ~10 %, E85 ~85 %.
  static double? parseEthanolPercent(String raw) {
    final bytes = parseModeOneBody(raw, 0x52, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2] * 100.0 / 255.0;
  }
}
