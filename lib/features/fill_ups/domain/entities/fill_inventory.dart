// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../services/pump_gain_learner.dart';
import 'fill_up.dart';

/// The inventory one fill establishes (#3917, Epic #3914 — "Bilan du
/// plein"): what the closed tank window consumed, what the recordings
/// saw of it, and whether the pump re-anchored the estimates (or why
/// not). Built from the learner's [PumpGainOutcome] right after the fill
/// is saved; persisted as the last inventory so the Carburant tab keeps
/// showing it until the next fill.
///
/// "Tank now" is NOT stored — the tank-level provider is the live truth
/// and the card reads it directly.
@immutable
class FillInventory {
  const FillInventory({
    required this.vehicleId,
    required this.fillId,
    required this.fillDate,
    required this.fuelKey,
    required this.isFullTank,
    required this.pumpLiters,
    this.kmSinceLastFull,
    this.pumpLPer100Km,
    this.coverageShare = 0.0,
    this.recordedKm = 0.0,
    this.rawRecordedLPer100Km,
    this.previousGain,
    this.newGain,
    this.skipReason,
  });

  final String vehicleId;
  final String fillId;
  final DateTime fillDate;
  final String fuelKey;
  final bool isFullTank;

  /// Litres pumped over the closed window (the fill's own litres when no
  /// window closed).
  final double pumpLiters;

  /// Odometer km since the previous full tank; null without a window.
  final double? kmSinceLastFull;

  /// The window's pump truth; null without a window.
  final double? pumpLPer100Km;

  /// Recorded km ÷ window km.
  final double coverageShare;
  final double recordedKm;

  /// The recordings' own figure with every gain stripped.
  final double? rawRecordedLPer100Km;

  /// The gain before / after this fill's calibration; both null when the
  /// fill did not calibrate ([skipReason] says why).
  final double? previousGain;
  final double? newGain;
  final PumpGainSkipReason? skipReason;

  bool get calibrated => previousGain != null && newGain != null;

  /// Signed change of the estimates in percent (−22 = they come down).
  int? get changePercent {
    final p = previousGain, n = newGain;
    if (p == null || n == null || p == 0) return null;
    return ((n / p - 1.0) * 100).round();
  }

  /// Build from the learner's verdict on [closing].
  factory FillInventory.fromOutcome(FillUp closing, PumpGainOutcome outcome) {
    final period = outcome.period;
    final result = outcome.result;
    return FillInventory(
      vehicleId: closing.vehicleId ?? '',
      fillId: closing.id,
      fillDate: closing.date,
      fuelKey: outcome.fuelKey,
      isFullTank: closing.isFullTank,
      pumpLiters: period?.liters ?? closing.liters,
      kmSinceLastFull: period?.distanceKm,
      pumpLPer100Km: period?.lPer100Km,
      coverageShare: outcome.coverageShare,
      recordedKm: outcome.recordedKm,
      rawRecordedLPer100Km: outcome.rawRecordedLPer100Km,
      previousGain: result?.previousGain,
      newGain: result?.newGain,
      skipReason: outcome.skipReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'fillId': fillId,
        'fillDate': fillDate.toIso8601String(),
        'fuelKey': fuelKey,
        'isFullTank': isFullTank,
        'pumpLiters': pumpLiters,
        if (kmSinceLastFull != null) 'kmSinceLastFull': kmSinceLastFull,
        if (pumpLPer100Km != null) 'pumpLPer100Km': pumpLPer100Km,
        'coverageShare': coverageShare,
        'recordedKm': recordedKm,
        if (rawRecordedLPer100Km != null)
          'rawRecordedLPer100Km': rawRecordedLPer100Km,
        if (previousGain != null) 'previousGain': previousGain,
        if (newGain != null) 'newGain': newGain,
        if (skipReason != null) 'skipReason': skipReason!.name,
      };

  /// Null on a malformed / foreign payload — a stale setting must never
  /// break the tab.
  static FillInventory? fromJson(Map<String, dynamic> j) {
    final vehicleId = j['vehicleId'] as String?;
    final fillId = j['fillId'] as String?;
    final date = DateTime.tryParse(j['fillDate'] as String? ?? '');
    if (vehicleId == null || fillId == null || date == null) return null;
    final skipName = j['skipReason'] as String?;
    return FillInventory(
      vehicleId: vehicleId,
      fillId: fillId,
      fillDate: date,
      fuelKey: j['fuelKey'] as String? ?? 'unknown',
      isFullTank: j['isFullTank'] as bool? ?? true,
      pumpLiters: (j['pumpLiters'] as num?)?.toDouble() ?? 0.0,
      kmSinceLastFull: (j['kmSinceLastFull'] as num?)?.toDouble(),
      pumpLPer100Km: (j['pumpLPer100Km'] as num?)?.toDouble(),
      coverageShare: (j['coverageShare'] as num?)?.toDouble() ?? 0.0,
      recordedKm: (j['recordedKm'] as num?)?.toDouble() ?? 0.0,
      rawRecordedLPer100Km: (j['rawRecordedLPer100Km'] as num?)?.toDouble(),
      previousGain: (j['previousGain'] as num?)?.toDouble(),
      newGain: (j['newGain'] as num?)?.toDouble(),
      skipReason: skipName == null
          ? null
          : PumpGainSkipReason.values
              .where((r) => r.name == skipName)
              .firstOrNull,
    );
  }
}
