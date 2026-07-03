// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'elm327_precision_pids.dart';
import 'pid_scheduler.dart';

/// Latest-value latches + scheduler subscriptions for the
/// consumption-precision PID families (Epic #3416): measured wideband φ
/// (#3427), MAF 0x66 / engine fuel rate 0x9D / cylinder fuel rate 0xA2
/// (#3428) and ethanol % 0x52 (#3429).
///
/// A collaborator of [LiveSampleSnapshot] (kept in its own file so the
/// grandfathered snapshot grows by a field + one `subscribe` call, not by
/// twenty latches). Same contract as the snapshot's own latches: scheduler
/// callbacks write, the derivation reads, everything is support-mask gated
/// so a car without a PID never subscribes it and the getters stay null.
class PrecisionPidLatches {
  PrecisionPidLatches({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// How long a latched wideband φ stays usable (#3427). The mixture tier
  /// targets 2 Hz but the #2457 governor may demote it on a slow link;
  /// 10 s spans several demoted periods yet rejects a value from before a
  /// link drop, so a stale φ can't keep skewing the AFR long after the
  /// sensor stopped answering.
  static const Duration measuredPhiStaleness = Duration(seconds: 10);

  // Measured wideband φ per PID + when it last landed. Keyed by PID so
  // the getter can apply sensor-1 (bank-1) priority over whichever other
  // sensors the car streams.
  final Map<int, double> _phiByPid = {};
  final Map<int, DateTime> _phiAtByPid = {};

  double? _mafSensorGPerS;
  double? _engineFuelRate9dGPerS;
  double? _cylinderFuelRateMgPerStroke;
  double? _ethanolPercent;

  /// Total MAF from the dual-sensor PID 0x66 (g/s), preferred over the
  /// legacy PID 0x10 in the MAF fuel branch (#3428). Null when
  /// unsupported / not yet landed.
  double? get mafSensorGPerS => _mafSensorGPerS;

  /// Engine fuel rate from PID 0x9D (g/s) — the top-precision mass-based
  /// branch (#3428). Null when unsupported / not yet landed.
  double? get engineFuelRate9dGPerS => _engineFuelRate9dGPerS;

  /// Cylinder fuel rate from PID 0xA2 (mg/stroke, per cylinder). Needs
  /// RPM + cylinder count to become g/s (#3428). Null when unsupported.
  double? get cylinderFuelRateMgPerStroke => _cylinderFuelRateMgPerStroke;

  /// Measured ethanol fuel fraction from PID 0x52 (%), driving the
  /// petrol↔E85 AFR/density blend (#3429). Null when unsupported.
  double? get ethanolPercent => _ethanolPercent;

  /// The freshest MEASURED wideband φ (#3427), with bank-1-sensor-1
  /// priority: PID 0x24 (voltage family) then 0x34 (current family) win
  /// when fresh — sensor 1 is the primary fuel-control sensor on
  /// virtually every layout — else the freshest of whatever other sensors
  /// answered. Values older than [measuredPhiStaleness] are ignored, so a
  /// dead sensor's last reading can't linger. Null when nothing fresh.
  double? measuredPhi() {
    final now = _clock();
    bool fresh(int pid) {
      final at = _phiAtByPid[pid];
      return at != null && now.difference(at) <= measuredPhiStaleness;
    }

    for (final pid in const [0x24, 0x34]) {
      if (fresh(pid)) return _phiByPid[pid];
    }
    int? bestPid;
    DateTime? bestAt;
    for (final entry in _phiAtByPid.entries) {
      if (!fresh(entry.key)) continue;
      if (bestAt == null || entry.value.isAfter(bestAt)) {
        bestAt = entry.value;
        bestPid = entry.key;
      }
    }
    return bestPid == null ? null : _phiByPid[bestPid];
  }

  /// Wire the precision-PID subscriptions onto [scheduler], gated by
  /// [isPidSupported] (the #811 discovered set — same don't-subscribe-
  /// unsupported contract as the snapshot's `_sub`).
  ///
  /// Tiers: wideband φ joins the MIXTURE tier at 2 Hz (it tracks throttle
  /// inputs, like commanded φ 0x44); the fuel-rate drivers 0x66 / 0x9D /
  /// 0xA2 join DYNAMICS at 5 Hz high priority (they feed the per-tick
  /// fuel integration exactly like 0x5E / 0x10 / 0x0B); ethanol 0x52
  /// joins SLOW-CORRECTION at 0.5 Hz (the blend only changes at a
  /// fill-up).
  void subscribe(
    PidScheduler scheduler, {
    required bool Function(int pid) isPidSupported,
  }) {
    for (final pid in Elm327PrecisionPids.allWidebandPids) {
      if (!isPidSupported(pid)) continue;
      scheduler.subscribe(
        Elm327PrecisionPids.widebandCommand(pid),
        ScheduledPid(hz: 2.0, tier: PidTier.mixture),
        (r) {
          final v = Elm327PrecisionPids.parseEquivalenceRatioPhi(r, pid);
          if (v != null) {
            _phiByPid[pid] = v;
            _phiAtByPid[pid] = _clock();
          }
        },
      );
    }
    if (isPidSupported(0x66)) {
      scheduler.subscribe(
        Elm327PrecisionPids.mafSensorCommand,
        ScheduledPid(
            hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics),
        (r) {
          final v = Elm327PrecisionPids.parseMafSensorGramsPerSecond(r);
          if (v != null) _mafSensorGPerS = v;
        },
      );
    }
    if (isPidSupported(0x9D)) {
      scheduler.subscribe(
        Elm327PrecisionPids.engineFuelRateGramsCommand,
        ScheduledPid(
            hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics),
        (r) {
          final v = Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond(r);
          if (v != null) _engineFuelRate9dGPerS = v;
        },
      );
    }
    if (isPidSupported(0xA2)) {
      scheduler.subscribe(
        Elm327PrecisionPids.cylinderFuelRateCommand,
        ScheduledPid(
            hz: 5.0, priority: PidPriority.high, tier: PidTier.dynamics),
        (r) {
          final v = Elm327PrecisionPids.parseCylinderFuelRateMgPerStroke(r);
          if (v != null) _cylinderFuelRateMgPerStroke = v;
        },
      );
    }
    if (isPidSupported(0x52)) {
      scheduler.subscribe(
        Elm327PrecisionPids.ethanolPercentCommand,
        ScheduledPid(hz: 0.5, tier: PidTier.slowCorrection),
        (r) {
          final v = Elm327PrecisionPids.parseEthanolPercent(r);
          if (v != null) _ethanolPercent = v;
        },
      );
    }
  }
}
