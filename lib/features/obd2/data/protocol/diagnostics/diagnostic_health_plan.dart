// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4549 (Epic #4547) — the continuous health-recording plan of the opt-in
/// full diagnostic mode: which extra commands the trip scheduler polls,
/// and how often.
///
/// Pure Dart. The rates are the contract stated on #4549 (maintainer
/// directive 2026-10-31: record the car's health continuously, not as a
/// snapshot). The plan rides the deepest, first-demoted scheduler tier,
/// so on a slow adapter it is the health stream that thins out — never
/// speed or RPM.
library;

/// One command of the plan and its target rate.
class DiagnosticHealthCommand {
  const DiagnosticHealthCommand(this.command, this.hz, {this.priority = true});

  /// The ELM327 request, e.g. `0142` or `03`.
  final String command;

  /// Target reads per second.
  final double hz;

  /// True for the named health set (polled even when the car's
  /// supported-PID bitmap is unknown — a 3× `NO DATA` drops it); false
  /// for "every other PID the car advertises".
  final bool priority;

  @override
  String toString() => '$command@${hz}Hz';
}

/// Target rates of the plan (#4549).
abstract final class DiagnosticHealthRates {
  /// Control-module voltage and the current gear — the "not enough
  /// energy" sag and the 2→1 shift itself.
  static const double fast = 2;

  /// Mixture, O2, rail pressure, EVAP vapour pressure, pedal/throttle.
  static const double medium = 0.5;

  /// Slow-moving health state and every other advertised PID.
  static const double slow = 0.2;

  /// Stored + pending trouble codes: an intermittent fault appears in the
  /// trace within 30 s of the ECU logging it.
  static const double dtc = 1 / 30;

  /// The `ATRV` adapter-voltage watch in full diagnostic mode (normal
  /// recording reads it every 10 s).
  static const Duration batteryVoltageInterval = Duration(seconds: 1);
}

/// The named Mode 01 health set, by rate.
const Map<int, double> kDiagnosticHealthPids = {
  0x42: DiagnosticHealthRates.fast, // control-module voltage
  0xA4: DiagnosticHealthRates.fast, // transmission actual gear
  0x03: DiagnosticHealthRates.medium, // fuel-system status (open/closed loop)
  0x14: DiagnosticHealthRates.medium, // O2 B1S1 (narrowband) + STFT
  0x15: DiagnosticHealthRates.medium, // O2 B1S2
  0x16: DiagnosticHealthRates.medium, // O2 B1S3
  0x17: DiagnosticHealthRates.medium, // O2 B1S4
  0x18: DiagnosticHealthRates.medium, // O2 B2S1
  0x19: DiagnosticHealthRates.medium, // O2 B2S2
  0x1A: DiagnosticHealthRates.medium, // O2 B2S3
  0x1B: DiagnosticHealthRates.medium, // O2 B2S4
  0x22: DiagnosticHealthRates.medium, // fuel-rail pressure (rel. manifold)
  0x23: DiagnosticHealthRates.medium, // fuel-rail gauge pressure (diesel/GDI)
  0x32: DiagnosticHealthRates.medium, // EVAP system vapour pressure
  0x45: DiagnosticHealthRates.medium, // relative throttle position
  0x47: DiagnosticHealthRates.medium, // absolute throttle position B
  0x49: DiagnosticHealthRates.medium, // accelerator pedal position D
  0x01: DiagnosticHealthRates.slow, // MIL, DTC count, readiness monitors
  0x1F: DiagnosticHealthRates.slow, // run time since engine start
  0x21: DiagnosticHealthRates.slow, // distance with MIL on
  0x2E: DiagnosticHealthRates.slow, // commanded EVAP purge
  0x31: DiagnosticHealthRates.slow, // distance since codes cleared
  0x3C: DiagnosticHealthRates.slow, // catalyst temp B1S1
  0x3D: DiagnosticHealthRates.slow, // catalyst temp B2S1
  0x3E: DiagnosticHealthRates.slow, // catalyst temp B1S2
  0x3F: DiagnosticHealthRates.slow, // catalyst temp B2S2
  0x4D: DiagnosticHealthRates.slow, // time run with MIL on
  0x4E: DiagnosticHealthRates.slow, // time since codes cleared
  0x53: DiagnosticHealthRates.slow, // absolute EVAP vapour pressure
  0x54: DiagnosticHealthRates.slow, // EVAP vapour pressure (wide)
};

/// The trouble-code requests polled continuously (stored, pending).
const List<String> kDiagnosticDtcCommands = ['03', '07'];

/// The supported-PID bitmap PIDs themselves (0x00, 0x20, …) — never
/// polled as data.
bool _isBitmapPid(int pid) => pid % 0x20 == 0;

/// Mode 01 command string for [pid] (`0x42` → `0142`).
String mode01Command(int pid) =>
    '01${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}';

/// Build the plan.
///
/// * [alreadyPolled] — commands another tier subscribes already; they are
///   excluded (the raw trace records their every reply anyway).
/// * [advertised] — the car's supported-PID bitmap, or null when it is
///   not resolved. The named set is always included (a 3× `NO DATA`
///   drops an unsupported one); every OTHER Mode 01 PID is added at the
///   slow rate only when the bitmap advertises it.
List<DiagnosticHealthCommand> buildDiagnosticHealthPlan({
  required Set<String> alreadyPolled,
  bool Function(int pid)? advertised,
}) {
  final plan = <DiagnosticHealthCommand>[];
  for (final e in kDiagnosticHealthPids.entries) {
    final cmd = mode01Command(e.key);
    if (alreadyPolled.contains(cmd)) continue;
    plan.add(DiagnosticHealthCommand(cmd, e.value));
  }
  for (final cmd in kDiagnosticDtcCommands) {
    if (!alreadyPolled.contains(cmd)) {
      plan.add(DiagnosticHealthCommand(cmd, DiagnosticHealthRates.dtc));
    }
  }
  if (advertised != null) {
    for (var pid = 0x01; pid <= 0xC4; pid++) {
      if (_isBitmapPid(pid) || kDiagnosticHealthPids.containsKey(pid)) {
        continue;
      }
      final cmd = mode01Command(pid);
      if (alreadyPolled.contains(cmd) || !advertised(pid)) continue;
      plan.add(DiagnosticHealthCommand(cmd, DiagnosticHealthRates.slow,
          priority: false));
    }
  }
  return plan;
}

/// #4550 — the one-shot snapshot at trip start and stop: protocol,
/// supply voltage, MIL/readiness, permanent DTCs, the freeze frame and
/// the ECU identity. Static data — the continuous plan above covers
/// everything that changes while driving.
const List<String> kDiagnosticSnapshotCommands = [
  'ATDP', // protocol in use
  'ATRV', // adapter supply voltage
  '0101', // MIL, DTC count, readiness monitors
  '0A', // permanent DTCs
  '020200', // freeze-frame DTC
  '020400', '020500', '020C00', '020D00', '021100', '024200', // freeze frame
  '0902', // VIN
  '0904', // calibration id
  '0906', // calibration verification number
  '090A', // ECU name
];

/// #4550 — headers on, then the supported-PID request again: every ECU
/// that answers shows its CAN id, so the trace names the engine AND the
/// gearbox computer. Always followed by [kDiagnosticHeadersOffCommand].
const List<String> kDiagnosticEcuScanCommands = ['ATH1', '0100'];

/// Restores the header-less replies every parser expects.
const String kDiagnosticHeadersOffCommand = 'ATH0';
