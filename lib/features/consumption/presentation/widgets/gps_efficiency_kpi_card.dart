// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/gps_driving_features.dart';
import '../../domain/gps_kpi_verdict.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/verdict_calibration_provider.dart';

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
class GpsEfficiencyKpiCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // #2795 C6 — band each interpretable KPI into good / moderate /
    // aggressive so the raw figure carries a verdict + colour, mirroring
    // DrivingScoreCard's class band. Climb energy is terrain, not driving
    // style, so it stays an un-banded plain row.
    // #3503 — the bands are the defaults until enough #3501 verdicts
    // accumulate, then the driver's own calibrated set.
    final bands = ref.watch(gpsKpiBandsProvider);
    final rpaVerdict = GpsKpiVerdicts.rpa(
      features.relativePositiveAcceleration,
      bands: bands,
    );
    final pkeVerdict =
        GpsKpiVerdicts.pke(features.positiveKineticEnergy, bands: bands);
    final vaposVerdict =
        GpsKpiVerdicts.vapos(features.meanPositiveVa, bands: bands);
    final coastVerdict =
        GpsKpiVerdicts.coast(features.coastShare, bands: bands);

    final rows = <Widget>[
      _kpiRow(
        theme,
        l,
        key: const Key('gps_kpi_rpa'),
        label: l.gpsKpiRpa,
        value: features.relativePositiveAcceleration.toStringAsFixed(2),
        verdict: rpaVerdict,
      ),
      _kpiRow(
        theme,
        l,
        key: const Key('gps_kpi_pke'),
        label: l.gpsKpiPke,
        value: features.positiveKineticEnergy.toStringAsFixed(2),
        verdict: pkeVerdict,
      ),
      _kpiRow(
        theme,
        l,
        key: const Key('gps_kpi_vapos'),
        label: l.gpsKpiVapos,
        value: features.meanPositiveVa.toStringAsFixed(2),
        verdict: vaposVerdict,
      ),
      _kpiRow(
        theme,
        l,
        key: const Key('gps_kpi_coast'),
        label: l.gpsKpiCoast,
        value: '${(features.coastShare * 100).toStringAsFixed(0)}%',
        verdict: coastVerdict,
      ),
      _kpiRow(
        theme,
        l,
        key: const Key('gps_kpi_climb'),
        label: l.gpsKpiClimbEnergy,
        value: '${features.climbEnergyPerKm.toStringAsFixed(0)} m/km',
      ),
    ];

    // Overall verdict = the worst of the four style KPIs, so the one-line
    // interpretation is conservative + actionable (a single aggressive
    // metric is worth flagging even amid otherwise calm figures).
    final overall = _worst([
      rpaVerdict,
      pkeVerdict,
      vaposVerdict,
      coastVerdict,
    ]);
    rows.add(const SizedBox(height: 10));
    rows.add(
      Text(
        _interpretation(l, overall),
        key: const Key('gps_kpi_interpretation'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: _verdictColor(theme, overall),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final delta = baselineDeltaPercent;
    if (delta != null) {
      final sign = delta >= 0 ? '+' : '';
      final pct = '$sign${delta.toStringAsFixed(0)}%';
      rows.add(const SizedBox(height: 8));
      rows.add(
        Text(
          l.drivingScoreBaselineDelta(pct),
          key: const Key('gps_kpi_baseline_delta'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.gpsKpiCardTitle,
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
    ThemeData theme,
    AppLocalizations l, {
    required Key key,
    required String label,
    required String value,
    GpsKpiVerdict? verdict,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          if (verdict != null) ...[
            Text(
              _verdictLabel(l, verdict),
              style: theme.textTheme.labelMedium?.copyWith(
                color: _verdictColor(theme, verdict),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
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

  /// Localized per-KPI verdict badge ("Efficient" / "Moderate" /
  /// "Aggressive").
  String _verdictLabel(AppLocalizations l, GpsKpiVerdict v) {
    switch (v) {
      case GpsKpiVerdict.good:
        return l.gpsKpiVerdictGood;
      case GpsKpiVerdict.moderate:
        return l.gpsKpiVerdictModerate;
      case GpsKpiVerdict.aggressive:
        return l.gpsKpiVerdictAggressive;
    }
  }

  /// One-line overall interpretation under the KPI rows.
  String _interpretation(AppLocalizations l, GpsKpiVerdict v) {
    switch (v) {
      case GpsKpiVerdict.good:
        return l.gpsKpiInterpretationGood;
      case GpsKpiVerdict.moderate:
        return l.gpsKpiInterpretationModerate;
      case GpsKpiVerdict.aggressive:
        return l.gpsKpiInterpretationAggressive;
    }
  }

  /// Verdict colour band, mirroring DrivingScoreCard._scoreColor: the
  /// positive [ColorScheme.primary] for good, the warm
  /// [ColorScheme.tertiary] for moderate, the [ColorScheme.error] for
  /// aggressive — theme-driven, no brand-specific colours.
  Color _verdictColor(ThemeData theme, GpsKpiVerdict v) {
    switch (v) {
      case GpsKpiVerdict.good:
        return theme.colorScheme.primary;
      case GpsKpiVerdict.moderate:
        return theme.colorScheme.tertiary;
      case GpsKpiVerdict.aggressive:
        return theme.colorScheme.error;
    }
  }

  /// The worst (most aggressive) of [verdicts] — drives the overall
  /// interpretation line so a single hard metric is never masked.
  GpsKpiVerdict _worst(List<GpsKpiVerdict> verdicts) {
    if (verdicts.contains(GpsKpiVerdict.aggressive)) {
      return GpsKpiVerdict.aggressive;
    }
    if (verdicts.contains(GpsKpiVerdict.moderate)) {
      return GpsKpiVerdict.moderate;
    }
    return GpsKpiVerdict.good;
  }
}
