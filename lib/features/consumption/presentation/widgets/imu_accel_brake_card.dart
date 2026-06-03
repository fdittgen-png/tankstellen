// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/trip_recorder.dart';
import '../../domain/trip_summary.dart';

/// Trip-detail card surfacing the dongle-less hard-acceleration /
/// hard-braking / sharp-cornering episode counts the phone's IMU detected on a
/// GPS-only trip (#2792 / #2760). These counts are computed at record time and
/// persisted on [TripSummary] but, before this card, were read by nothing.
///
/// Mirrors [GpsEfficiencyKpiCard]: purely presentational, lives in its own
/// file so the trip-detail body holds only a one-line reference.
class ImuAccelBrakeCard extends StatelessWidget {
  final TripSummary summary;

  const ImuAccelBrakeCard({super.key, required this.summary});

  /// Returns [summary] when the card should render, else null. Gated to a
  /// GPS-only trip whose IMU detected **at least one** harsh event. A calm
  /// GPS-only trip (all zero) renders nothing here — the smooth-driving praise
  /// covers it — so we never claim "0 harsh events" for a trip whose IMU may
  /// not have run (there is no availability flag to distinguish calm from
  /// sensor-absent). OBD2 / legacy trips (no IMU signal) are skipped.
  static TripSummary? summaryFor(TripSummary summary) {
    if (summary.kind != TripKind.gpsOnly) return null;
    final hasEvents = summary.imuHardAccelCount > 0 ||
        summary.imuHardBrakeCount > 0 ||
        summary.sharpCornerCount > 0;
    return hasEvents ? summary : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    String fmt(int count, double perKm) =>
        '$count (${perKm.toStringAsFixed(1)}/km)';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.accelBrakeCardTitle ?? 'Acceleration & braking',
              key: const Key('accel_brake_card_title'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _row(theme,
                key: const Key('accel_brake_hard_accel'),
                label: l?.accelBrakeHardAccel ?? 'Hard accelerations',
                value: fmt(summary.imuHardAccelCount, summary.imuHardAccelPerKm)),
            _row(theme,
                key: const Key('accel_brake_hard_brake'),
                label: l?.accelBrakeHardBrake ?? 'Hard braking',
                value: fmt(summary.imuHardBrakeCount, summary.imuHardBrakePerKm)),
            _row(theme,
                key: const Key('accel_brake_sharp_corner'),
                label: l?.accelBrakeSharpCorner ?? 'Sharp corners',
                value: fmt(summary.sharpCornerCount, summary.sharpCornersPerKm)),
            const SizedBox(height: 8),
            Text(
              l?.accelBrakeSource ?? "From the phone's motion sensors",
              key: const Key('accel_brake_source'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme, {
    required Key key,
    required String label,
    required String value,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
