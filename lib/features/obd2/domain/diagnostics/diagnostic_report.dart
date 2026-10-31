// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4552 (Epic #4547) — the per-system health report of one full
/// diagnostic recording. Pure data: the analyser
/// (`analyzeDiagnosticRecording`) fills it, the report screen renders
/// it, the localized sentences are chosen there from these fields.
library;

/// Traffic-light verdict of one car system.
enum HealthVerdict { good, check, problem, notReported }

/// Battery & charging.
class ElectricalHealth {
  const ElectricalHealth({
    required this.verdict,
    this.runningAvgV,
    this.runningMinV,
    this.runningMaxV,
    this.dipCount = 0,
    this.restV,
  });

  final HealthVerdict verdict;

  /// Supply voltage while the engine ran (cranking excluded).
  final double? runningAvgV;
  final double? runningMinV;
  final double? runningMaxV;

  /// Separate dips below [ElectricalThresholds.dipV] with the engine on.
  final int dipCount;

  /// Lowest voltage with the engine off (battery at rest), if observed.
  final double? restV;
}

/// One moment where the driver asked for power and it did not reach the
/// wheels — the engine near idle at low speed, or neutral while moving.
class DriveEpisode {
  const DriveEpisode({
    required this.at,
    required this.duration,
    required this.speedKmh,
    required this.rpm,
    this.pedalPct,
    this.voltageV,
    this.neutral = false,
  });

  /// Offset from the start of the recording.
  final Duration at;
  final Duration duration;
  final double speedKmh;
  final double rpm;
  final double? pedalPct;
  final double? voltageV;

  /// True when the gearbox itself reported neutral.
  final bool neutral;
}

/// Gearbox & drive.
class TransmissionHealth {
  const TransmissionHealth({
    required this.verdict,
    required this.gearReported,
    this.episodes = const [],
  });

  final HealthVerdict verdict;

  /// Whether the car answered the standard gear PID (`01A4`).
  final bool gearReported;
  final List<DriveEpisode> episodes;
}

/// Engine (coolant).
class EngineHealth {
  const EngineHealth({
    required this.verdict,
    this.coolantMaxC,
    this.runningMinutes = 0,
  });

  final HealthVerdict verdict;
  final double? coolantMaxC;
  final int runningMinutes;
}

/// Fuel & mixture.
class MixtureHealth {
  const MixtureHealth({
    required this.verdict,
    this.avgTrimPct,
    this.openLoopShare,
  });

  final HealthVerdict verdict;

  /// Mean short + long term fuel trim, bank 1, warm engine. Negative:
  /// the ECU removes fuel (rich); positive: it adds fuel (lean).
  final double? avgTrimPct;

  /// Share of warm-engine readings in open loop (0–1), if reported.
  final double? openLoopShare;
}

/// Emissions & fuel vapour.
class EmissionsHealth {
  const EmissionsHealth({
    required this.verdict,
    this.catalystMaxC,
    this.evapMinPa,
    this.evapMaxPa,
  });

  final HealthVerdict verdict;
  final double? catalystMaxC;
  final double? evapMinPa;
  final double? evapMaxPa;
}

/// Fault codes and the warning light.
class FaultCodeHealth {
  const FaultCodeHealth({
    required this.verdict,
    this.milOn,
    this.stored = const [],
    this.pending = const [],
    this.permanent = const [],
    this.freezeFrame = const [],
  });

  final HealthVerdict verdict;

  /// Engine warning light, from `0101`; null when never reported.
  final bool? milOn;
  final List<String> stored;
  final List<String> pending;
  final List<String> permanent;
  final List<String> freezeFrame;
}

/// The whole report.
class DiagnosticReport {
  const DiagnosticReport({
    required this.duration,
    required this.readings,
    required this.distinctValues,
    required this.electrical,
    required this.transmission,
    required this.engine,
    required this.mixture,
    required this.emissions,
    required this.faults,
    this.unanswered = const [],
  });

  final Duration duration;

  /// Successful adapter replies in the recording.
  final int readings;

  /// Distinct commands that answered at least once.
  final int distinctValues;

  final ElectricalHealth electrical;
  final TransmissionHealth transmission;
  final EngineHealth engine;
  final MixtureHealth mixture;
  final EmissionsHealth emissions;
  final FaultCodeHealth faults;

  /// Commands the car never answered (raw OBD2 requests, e.g. `01A4`).
  final List<String> unanswered;
}

/// Thresholds behind the verdicts (#4552). Documented, conservative
/// rules of thumb — the report says "check", never "broken".
abstract final class ElectricalThresholds {
  /// Healthy charging band with the engine running.
  static const double chargingLowV = 13.2;
  static const double chargingHighV = 14.8;

  /// Average below this with the engine on = charging problem.
  static const double chargingProblemV = 13.0;

  /// A running-engine dip below this is a problem.
  static const double dipV = 12.0;

  /// Battery at rest (engine off) healthy at or above this.
  static const double restGoodV = 12.4;
}

/// See [ElectricalThresholds].
abstract final class DriveThresholds {
  static const double minSpeedKmh = 5;
  static const double maxSpeedKmh = 30;

  /// "Near idle".
  static const double maxRpm = 900;

  /// The driver is asking for power.
  static const double minPedalPct = 15;
}

/// See [ElectricalThresholds].
abstract final class EngineThresholds {
  static const double coolantHotC = 110;
  static const double coolantWarmC = 70;
  static const int warmUpMinutes = 15;
}

/// See [ElectricalThresholds].
abstract final class MixtureThresholds {
  static const double checkPct = 10;
  static const double problemPct = 20;
}

/// See [ElectricalThresholds].
abstract final class EmissionsThresholds {
  static const double catalystHotC = 900;
}

/// The system a DTC's number encodes (SAE J2012 groups).
enum DtcGroup {
  fuelAir,
  ignition,
  emissions,
  idleElectrical,
  computer,
  transmission,
  chassis,
  body,
  network,
  other,
}

/// Group of [code] (`P0301` → [DtcGroup.ignition]).
DtcGroup dtcGroupOf(String code) {
  if (code.length < 3) return DtcGroup.other;
  switch (code[0]) {
    case 'C':
      return DtcGroup.chassis;
    case 'B':
      return DtcGroup.body;
    case 'U':
      return DtcGroup.network;
  }
  return switch (code[2]) {
    '0' || '1' || '2' => DtcGroup.fuelAir,
    '3' => DtcGroup.ignition,
    '4' => DtcGroup.emissions,
    '5' => DtcGroup.idleElectrical,
    '6' => DtcGroup.computer,
    '7' || '8' || '9' => DtcGroup.transmission,
    _ => DtcGroup.other,
  };
}
