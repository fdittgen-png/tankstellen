// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../consumption/domain/trip_summary.dart';
import '../../../consumption/domain/services/engine_off_transport.dart';
import 'tank_report.dart' show TankPeriod, kTankExplainMinCoverage;
import '../../../consumption/domain/services/trip_consumed_liters.dart';

/// Recorded-behavior aggregate over one tank window's linked trips.
/// Engine-off transport trips (#3599) are excluded wholesale — a towed
/// car explains nothing about driving style.
class TankBehavior {
  const TankBehavior({
    required this.tripCount,
    required this.recordedKm,
    required this.coverageShare,
    required this.recordedLPer100Km,
    required this.highRpmShare,
    required this.idleShare,
    required this.harshPer100Km,
    required this.coldStartCount,
  });

  static const TankBehavior none = TankBehavior(
    tripCount: 0,
    recordedKm: 0,
    coverageShare: 0,
    recordedLPer100Km: null,
    highRpmShare: 0,
    idleShare: 0,
    harshPer100Km: 0,
    coldStartCount: 0,
  );

  final int tripCount;
  final double recordedKm;

  /// Recorded km / tank km, clamped to [0, 1] — the honesty anchor every
  /// downstream consumer gates on.
  final double coverageShare;

  /// Litres-over-distance of the recorded slice (null when the trips
  /// carried no reliable fuel figure or too little distance).
  final double? recordedLPer100Km;

  /// Σ high-RPM seconds / Σ drive seconds.
  final double highRpmShare;

  /// Σ idle seconds / Σ drive seconds.
  final double idleShare;

  /// Effective harsh events (the #2895 IMU-veto counts) per 100 km.
  final double harshPer100Km;

  /// Trips that paid the cold-start surcharge.
  final int coldStartCount;

  /// Fold the linked trips of [period] into one behavior aggregate.
  static TankBehavior fromTrips(
    TankPeriod period,
    Iterable<TripSummary> trips,
  ) {
    var km = 0.0, liters = 0.0, litersKm = 0.0;
    var driveSec = 0.0, highSec = 0.0, idleSec = 0.0;
    var harsh = 0, coldStarts = 0, count = 0;
    for (final t in trips) {
      if (isEngineOffTransport(t)) continue;
      count++;
      km += t.distanceKm;
      final l = tripConsumedLitersOrNull(t);
      if (l != null && t.distanceKm > 0) {
        liters += l;
        litersKm += t.distanceKm;
      }
      final start = t.startedAt, end = t.endedAt;
      if (start != null && end != null) {
        driveSec += end.difference(start).inSeconds.toDouble();
      }
      highSec += t.highRpmSeconds;
      idleSec += t.idleSeconds;
      // #2895 — when the inertial sensor ran, its counts (including a
      // genuine zero) beat the speed-derivative recorder counts.
      harsh += t.imuActive
          ? t.imuHardAccelCount + t.imuHardBrakeCount
          : t.harshAccelerations + t.harshBrakes;
      if (t.coldStartSurcharge) coldStarts++;
    }
    return TankBehavior(
      tripCount: count,
      recordedKm: km,
      coverageShare: period.distanceKm > 0
          ? (km / period.distanceKm).clamp(0.0, 1.0)
          : 0.0,
      recordedLPer100Km:
          liters > 0 && litersKm >= 5 ? liters / litersKm * 100.0 : null,
      highRpmShare: driveSec > 0 ? highSec / driveSec : 0.0,
      idleShare: driveSec > 0 ? idleSec / driveSec : 0.0,
      harshPer100Km: km > 0 ? harsh / km * 100.0 : 0.0,
      coldStartCount: coldStarts,
    );
  }
}

/// A behavior factor whose tank-over-tank movement matches the
/// consumption delta's direction — a *candidate* explanation.
enum TankFactor { highRpm, harshEvents, coldStarts, idle }

class TankExplanation {
  const TankExplanation({
    required this.factor,
    required this.current,
    required this.previous,
    required this.salience,
  });

  final TankFactor factor;

  /// Factor value in the current / previous window, in the factor's
  /// natural unit (share for highRpm/idle, events per 100 km for
  /// harshEvents, a count for coldStarts).
  final double current;
  final double previous;

  /// Normalized delta magnitude — the UI orders by this and keeps the
  /// top few.
  final double salience;
}

/// Behavior deltas that moved in the SAME direction as consumption, each
/// past its own noise floor, ordered by salience. Both windows need
/// [kTankExplainMinCoverage] — thinner slices explain nothing.
List<TankExplanation> explainTankDelta({
  required double deltaLPer100Km,
  required TankBehavior current,
  required TankBehavior previous,
}) {
  if (current.coverageShare < kTankExplainMinCoverage ||
      previous.coverageShare < kTankExplainMinCoverage) {
    return const [];
  }
  final up = deltaLPer100Km > 0;
  final out = <TankExplanation>[];

  void consider(
    TankFactor factor,
    double cur,
    double prev,
    double noiseFloor,
    double scale,
  ) {
    final delta = cur - prev;
    // Only a factor that moved WITH the consumption can explain it.
    if (up ? delta < noiseFloor : delta > -noiseFloor) return;
    out.add(TankExplanation(
      factor: factor,
      current: cur,
      previous: prev,
      salience: delta.abs() / scale,
    ));
  }

  consider(TankFactor.highRpm, current.highRpmShare, previous.highRpmShare,
      0.05, 0.05);
  consider(TankFactor.harshEvents, current.harshPer100Km,
      previous.harshPer100Km, 1.0, 1.0);
  consider(
      TankFactor.coldStarts,
      current.coldStartCount.toDouble(),
      previous.coldStartCount.toDouble(),
      2.0,
      2.0);
  consider(TankFactor.idle, current.idleShare, previous.idleShare, 0.03,
      0.03);

  out.sort((a, b) => b.salience.compareTo(a.salience));
  return out;
}

