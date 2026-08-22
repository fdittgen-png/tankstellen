// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'accel_event_gate.dart';
import 'gps_driving_features.dart' show kSharpCornerYawRateRadPerSec;

/// Hard cap on per-trip [ImuEventRecord]s (#3589). A normal trip produces
/// a handful; the cap only exists so a pathological signal (loose mount,
/// sensor fault) cannot grow the persisted summary without bound. Records
/// past the cap are counted, not stored.
const int kImuEventRecordCap = 48;

/// Micro-jolt floor (#3589 field tuning): the first field trips flooded
/// the cap with 600-700 road-vibration blips (duration ≈ 0.0-0.1 s at
/// barely-over-threshold magnitude), drowning the informative stretches.
/// A stretch shorter than [kImuMicroJoltMaxDuration] whose peak stayed
/// under [kImuMicroJoltMaxPeak] is counted into `dropped`, not stored —
/// it carries no calibration signal a histogram of one 'tooShort' blip
/// after another wouldn't.
const double kImuMicroJoltMaxDuration = 0.15;
const double kImuMicroJoltMaxPeak = 4.5;

/// #3702 — per-trip cap on UNCONFIRMED records (tooShort / ambiguous /
/// cornerGeometry near-misses). The 2026-08-14 field exports carried up
/// to 48 stored tooShort blips (and 23,926 dropped) per trip: the noise
/// filled [kImuEventRecordCap] and — worse — CONFIRMED harsh events
/// finalized after slot 48 were silently dropped from the calibration
/// export. Near-misses only need a representative sample for threshold
/// calibration; confirmed events keep the remaining slots guaranteed.
const int kImuUnconfirmedRecordCap = 16;

/// One strong-manoeuvre stretch as the IMU detector saw it (#3589) —
/// confirmed events AND rejected near-misses, so the accel/brake
/// thresholds can be calibrated against labeled magnitude distributions
/// instead of bare counts (the 2026-07-21 verdict captures contradicted
/// the counters in both directions). Aggregate-only by construction:
/// a stretch is O(1) state folded from the 50 Hz stream, never samples.
class ImuEventRecord {
  /// What the stretch became: `accel` / `brake` / `corner` (confirmed) or
  /// the rejection reason — `tooShort` (magnitude held under the 1 s
  /// sustained floor), `cornerGeometry` (high yaw at constant speed:
  /// centripetal, not longitudinal), `ambiguous` (sustained but the net
  /// GPS-speed change never picked a direction).
  final String outcome;

  /// Peak horizontal linear-accel magnitude over the stretch, m/s².
  final double peakMps2;

  /// How long the magnitude held above the accel threshold, seconds.
  final double durationSec;

  /// GPS ground speed when the stretch began, km/h — the speed band.
  final double startSpeedKmh;

  /// Net GPS-speed change over the stretch, km/h (sign = direction).
  final double netSpeedDeltaKmh;

  /// Peak |yaw rate| over the stretch, rad/s — the cornering context.
  final double peakYawRadPerSec;

  const ImuEventRecord({
    required this.outcome,
    required this.peakMps2,
    required this.durationSec,
    required this.startSpeedKmh,
    required this.netSpeedDeltaKmh,
    required this.peakYawRadPerSec,
  });

  double _r(double v) => (v * 100).roundToDouble() / 100;

  /// Compact persisted form (o/p/d/s/n/y), rounded to 2 decimals — the
  /// calibration only needs magnitude-distribution resolution.
  Map<String, Object?> toJson() => {
        'o': outcome,
        'p': _r(peakMps2),
        'd': _r(durationSec),
        's': _r(startSpeedKmh),
        'n': _r(netSpeedDeltaKmh),
        'y': _r(peakYawRadPerSec),
      };

  static ImuEventRecord? fromJson(Map<String, dynamic> j) {
    final o = j['o'];
    if (o is! String) return null;
    double num_(Object? v) => v is num ? v.toDouble() : 0.0;
    return ImuEventRecord(
      outcome: o,
      peakMps2: num_(j['p']),
      durationSec: num_(j['d']),
      startSpeedKmh: num_(j['s']),
      netSpeedDeltaKmh: num_(j['n']),
      peakYawRadPerSec: num_(j['y']),
    );
  }
}

/// Folds the detector's per-sample stretch state into bounded
/// [ImuEventRecord]s (#3589). Owned by `ImuEventDetector`; kept in its own
/// file so the detector stays under the 400-line guard.
class ImuStretchTracker {
  final List<ImuEventRecord> _records = [];
  int _dropped = 0;

  bool _open = false;
  double _peakMps2 = 0;
  double _peakYaw = 0;
  double _duration = 0;
  double _startSpeedKmh = 0;
  double _lastNetDeltaKmh = 0;
  bool _sawCornerGeometry = false;
  String? _confirmedOutcome;
  int _unconfirmedCount = 0; // #3702 — see [kImuUnconfirmedRecordCap]

  /// Records finalized so far (open stretch not included — call
  /// [finish] first at harvest time).
  List<ImuEventRecord> get records => List.unmodifiable(_records);

  /// Stretches not stored: past [kImuEventRecordCap], or sub-noise
  /// micro-jolts under the #3589 field-tuning floor.
  int get dropped => _dropped;

  /// Fold one sample's stretch state. [strong] mirrors the detector's
  /// `horizMag >= kHardAccelThresholdMps2` stretch predicate.
  void onSample({
    required bool strong,
    required double dt,
    required double horizMag,
    required double yawRate,
    required double speedKmh,
    required double netSpeedDeltaKmh,
    required bool cornerGeometry,
  }) {
    if (strong) {
      if (!_open) {
        _open = true;
        _peakMps2 = 0;
        _peakYaw = 0;
        _duration = 0;
        _startSpeedKmh = speedKmh;
        _sawCornerGeometry = false;
        _confirmedOutcome = null;
      }
      _duration += dt;
      if (horizMag > _peakMps2) _peakMps2 = horizMag;
      if (yawRate > _peakYaw) _peakYaw = yawRate;
      _lastNetDeltaKmh = netSpeedDeltaKmh;
      if (cornerGeometry) _sawCornerGeometry = true;
    } else if (_open) {
      _finalize();
    }
  }

  /// Mark the open stretch (if any) as having confirmed as [outcome]
  /// (`accel` / `brake` / `corner`). First confirmation wins.
  void confirm(String outcome) {
    if (_open) _confirmedOutcome ??= outcome;
  }

  /// A gap / standstill / trip stop broke every episode — close the open
  /// stretch exactly like a below-threshold sample would.
  void breakEpisodes() {
    if (_open) _finalize();
  }

  /// Finalize any open stretch and return the full record list — the
  /// harvest call at trip stop.
  List<ImuEventRecord> finish() {
    if (_open) _finalize();
    return records;
  }

  void _finalize() {
    _open = false;
    // Micro-jolt: a road-vibration blip, counted but not stored — see
    // [kImuMicroJoltMaxDuration]. Confirmed events are always stored.
    if (_confirmedOutcome == null &&
        _duration < kImuMicroJoltMaxDuration &&
        _peakMps2 < kImuMicroJoltMaxPeak) {
      _dropped++;
      return;
    }
    final outcome = _confirmedOutcome ??
        (_duration < kAccelEventMinSustainedSec
            ? 'tooShort'
            : _sawCornerGeometry && _peakYaw >= kSharpCornerYawRateRadPerSec
                ? 'cornerGeometry'
                : 'ambiguous');
    // #3702 — near-misses stop at their own cap so noise can never crowd
    // confirmed events out of the export (a 48-slot list full of
    // tooShort blips used to drop every later confirmed harsh event).
    if (_confirmedOutcome == null &&
        _unconfirmedCount >= kImuUnconfirmedRecordCap) {
      _dropped++;
      return;
    }
    if (_records.length >= kImuEventRecordCap) {
      _dropped++;
      return;
    }
    if (_confirmedOutcome == null) _unconfirmedCount++;
    _records.add(ImuEventRecord(
      outcome: outcome,
      peakMps2: _peakMps2,
      durationSec: _duration,
      startSpeedKmh: _startSpeedKmh,
      netSpeedDeltaKmh: _lastNetDeltaKmh,
      peakYawRadPerSec: _peakYaw,
    ));
  }
}
