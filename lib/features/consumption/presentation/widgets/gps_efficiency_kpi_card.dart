// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/gps_driving_features.dart';
import '../../domain/trip_recorder.dart';

/// GPS-only efficiency KPI card on the Trip detail screen (#2695 C9 /
/// #2697 P3). Surfaces the speed-only energy KPIs — RPA, PKE, VAPOS,
/// coasting share, climb energy — for trips recorded without an engine
/// signal, where the OBD2-derived cards (driving score breakdown, RPM
/// histogram) carry no information.
///
/// Lives in its own file (NOT inlined into the trip_detail_body
/// god-class): the body only references it in its Column. Purely
/// presentational — all KPI math lives in [GpsDrivingFeatures.from].
///
/// Optionally shows the consumption-vs-efficient-baseline delta (#2696
/// C10) as a trailing line when the caller resolved one.
class GpsEfficiencyKpiCard extends StatelessWidget {
  /// Pre-computed GPS features for the trip.
  final GpsDrivingFeatures features;

  /// Signed % vs the synced efficient baseline (#2696 C10), or null when
  /// the driver has no learned baseline yet — then the line is hidden.
  final double? baselineDeltaPercent;

  const GpsEfficiencyKpiCard({
    super.key,
    required this.features,
    this.baselineDeltaPercent,
  });

  /// Resolve the GPS-only features for a trip's [samples], or null when the
  /// card should not render: an EV trip, an empty trip, or any trip that
  /// carried an engine RPM on a sample (i.e. an OBD2 trip — #2692 C4-G).
  /// Keeps the gating + the `GpsDrivingFeatures.from` call next to the
  /// widget so the trip-detail body only holds a one-line reference.
  static GpsDrivingFeatures? featuresFor(
    Iterable<TripSample> samples, {
    required bool isEv,
  }) {
    if (isEv) return null;
    final list = samples.toList(growable: false);
    if (list.isEmpty || list.any((s) => s.rpm != null)) return null;
    return GpsDrivingFeatures.from(list);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final rows = <Widget>[
      _kpiRow(theme, key: const Key('gps_kpi_rpa'),
          label: l?.gpsKpiRpa ?? 'Positive acceleration (RPA)',
          value: features.relativePositiveAcceleration.toStringAsFixed(2)),
      _kpiRow(theme, key: const Key('gps_kpi_pke'),
          label: l?.gpsKpiPke ?? 'Kinetic energy demand (PKE)',
          value: features.positiveKineticEnergy.toStringAsFixed(2)),
      _kpiRow(theme, key: const Key('gps_kpi_vapos'),
          label: l?.gpsKpiVapos ?? 'Acceleration intensity (VAPOS)',
          value: features.meanPositiveVa.toStringAsFixed(2)),
      _kpiRow(theme, key: const Key('gps_kpi_coast'),
          label: l?.gpsKpiCoast ?? 'Coasting share',
          value: '${(features.coastShare * 100).toStringAsFixed(0)}%'),
      _kpiRow(theme, key: const Key('gps_kpi_climb'),
          label: l?.gpsKpiClimbEnergy ?? 'Climb energy',
          value: '${features.climbEnergyPerKm.toStringAsFixed(0)} m/km'),
    ];

    final delta = baselineDeltaPercent;
    if (delta != null) {
      final sign = delta >= 0 ? '+' : '';
      final pct = '$sign${delta.toStringAsFixed(0)}%';
      rows.add(const SizedBox(height: 8));
      rows.add(Text(
        l?.drivingScoreBaselineDelta(pct) ?? '$pct vs your efficient baseline',
        key: const Key('gps_kpi_baseline_delta'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ));
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.gpsKpiCardTitle ?? 'GPS efficiency',
              key: const Key('gps_kpi_card_title'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _kpiRow(
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
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
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
