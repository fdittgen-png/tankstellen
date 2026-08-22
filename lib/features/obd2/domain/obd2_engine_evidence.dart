// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3756 — shared recency stamp of "the ENGINE was demonstrably on".
///
/// Stamped by [Obd2Service] whenever an engine PID actually parses
/// (non-null road speed, rpm > 0) — replies only an awake ECU can give.
/// A powered-but-parked adapter answers `ATRV`/`NO DATA` happily, so
/// adapter-level liveness deliberately does NOT count as evidence.
///
/// Consumed by [Obd2LinkSupervisor]: while evidence is fresh
/// ([defaultWindow]), the #3603 reconnect stand-down is suppressed — a
/// link that drops mid-drive keeps the fast retry ladder for the whole
/// drive instead of being held off for 5–15 minutes (the 2026-08-17
/// field shape: "flap x3 — holding 303s" while the car was moving).
/// A parked car produces no engine parses, so the storm protection
/// (#3642 battery/CPU rationale) stays fully intact there.
///
/// Instance pattern with injectable clock, matching the supervisor's
/// default-to-instance-accept-override constructor convention.
class Obd2EngineEvidence {
  Obd2EngineEvidence({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Process-wide default instance (production wiring).
  static final Obd2EngineEvidence instance = Obd2EngineEvidence();

  /// How long a stamp counts as "fresh". Long enough to bridge a fuel
  /// stop mid-trip (the ACL engine-start hint re-arms on ignition
  /// anyway), short enough that an evening's last drive doesn't
  /// suppress the overnight stand-down.
  static const Duration defaultWindow = Duration(minutes: 10);

  final DateTime Function() _now;
  DateTime? _lastEngineOnAt;

  /// Stamp: an engine PID parsed just now.
  void noteEngineOn() => _lastEngineOnAt = _now();

  /// True while the last stamp is within [window].
  bool isFresh({Duration window = defaultWindow}) {
    final at = _lastEngineOnAt;
    if (at == null) return false;
    return _now().difference(at) < window;
  }

  /// Test hygiene — clear the stamp between cases.
  void reset() => _lastEngineOnAt = null;
}
