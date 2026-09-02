// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/consumption_unit.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/monthly_insights_aggregator.dart';
import 'monthly_insights_table.dart';

/// "This month vs last month" card on the Trajets tab landing screen
/// (#1041 phase 4 — Aggregates surface).
///
/// Renders three or four rows of `(label, current value, previous
/// value, delta arrow)`:
///   * Trips
///   * Drive time
///   * Distance
///   * Avg consumption (only when BOTH months have a non-null figure)
///
/// Sign conventions for the delta arrow:
///   * Trip count + drive time + distance going UP → neutral (more
///     activity is not inherently better or worse). Rendered as a
///     small grey chevron.
///   * Avg consumption going DOWN → green (lower L/100 km = better).
///     Going UP → red. Going equal → neutral.
///
/// Reliability gate: when `summary.isComparisonReliable == false`, the
/// card hides the previous-month column and the delta arrows entirely
/// and shows a one-line caption explaining why. The current-month
/// numbers stay visible — even with a single trip the user can see
/// what they did this month.
///
/// Layout (#3904): the rows form ONE [Table] whose value columns take
/// their intrinsic width, so "10,1 L/100 km" never wraps its unit onto a
/// second line — the label column gives way first. See [MonthlyMetricsTable].
///
/// The widget is purely presentational. Bucketing / averaging happens
/// inside the aggregator, which is unit-tested separately.
class MonthlyInsightsCard extends ConsumerWidget {
  /// Pre-computed aggregate. Build it via
  /// `aggregateMonthlyInsights(trips, now)`.
  final MonthlyInsightsSummary summary;

  const MonthlyInsightsCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // #3889 — the month figures follow the app-wide consumption unit.
    final unit = ref.watch(consumptionDisplaySettingProvider).unit;
    final reliable = summary.isComparisonReliable;

    final tripsRow = MonthlyMetric(
      label: l.consumptionMonthlyTripsLabel,
      currentValue: _fmtCount(summary.currentMonthTripCount),
      previousValue: _fmtCount(summary.previousMonthTripCount),
      delta: summary.tripCountDelta,
      sentiment: MonthlyMetricSentiment.neutral,
      showPrevious: reliable,
    );

    final driveTimeRow = MonthlyMetric(
      label: l.consumptionMonthlyDriveTimeLabel,
      currentValue: _fmtDuration(summary.currentMonthDriveTime),
      previousValue: _fmtDuration(summary.previousMonthDriveTime),
      delta: summary.driveTimeDelta.inMinutes,
      sentiment: MonthlyMetricSentiment.neutral,
      showPrevious: reliable,
    );

    final distanceRow = MonthlyMetric(
      label: l.consumptionMonthlyDistanceLabel,
      currentValue: _fmtDistance(summary.currentMonthDistanceKm),
      previousValue: _fmtDistance(summary.previousMonthDistanceKm),
      // Convert to a comparable scalar for the arrow: 1-decimal km.
      delta: ((summary.distanceKmDelta) * 10).round(),
      sentiment: MonthlyMetricSentiment.neutral,
      showPrevious: reliable,
    );

    // Climbed metres (#2697 P3) — only when this month recorded any
    // altitude-bearing trips. Neutral sentiment: terrain, not behaviour.
    final showClimbRow = summary.currentMonthClimbMeters > 0;
    final climbRow = showClimbRow
        ? MonthlyMetric(
            label: l.consumptionMonthlyClimbLabel,
            currentValue: _fmtClimb(summary.currentMonthClimbMeters),
            previousValue: _fmtClimb(summary.previousMonthClimbMeters),
            delta: summary.climbMetersDelta.round(),
            sentiment: MonthlyMetricSentiment.neutral,
            showPrevious: reliable,
          )
        : null;

    // Avg consumption: only render when at least the current month has
    // a figure. When previous is null too, hide the previous column.
    final showConsumptionRow =
        summary.currentMonthAvgConsumptionLPer100km != null;
    final consumptionRow = showConsumptionRow
        ? MonthlyMetric(
            label: l.consumptionMonthlyAvgConsumptionLabel,
            currentValue: _fmtConsumption(
              summary.currentMonthAvgConsumptionLPer100km,
              unit,
            ),
            previousValue: _fmtConsumption(
              summary.previousMonthAvgConsumptionLPer100km,
              unit,
            ),
            // Round to one decimal so a +0.04 swing doesn't render as
            // a coloured arrow when the displayed numbers are equal.
            delta: ((summary.consumptionDeltaLPer100km ?? 0) * 10).round(),
            sentiment: MonthlyMetricSentiment.lowerIsBetter,
            showPrevious:
                reliable &&
                summary.previousMonthAvgConsumptionLPer100km != null,
          )
        : null;

    return Card(
      key: const ValueKey('monthly_insights_card'),
      // #1893 — tighter margin/padding for Trajets-tab space efficiency.
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.consumptionMonthlyInsightsTitle,
              style: theme.textTheme.titleMedium,
            ),
            if (!reliable) ...[
              const SizedBox(height: 4),
              Text(
                l.consumptionMonthlyComparisonNotReliable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 5),
            // #3904 — one table, so the value columns share their widths
            // across rows and a figure never wraps its unit.
            MonthlyMetricsTable(
              metrics: [
                tripsRow,
                driveTimeRow,
                distanceRow,
                ?climbRow,
                ?consumptionRow,
              ],
              showPreviousColumn: reliable,
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatters — kept private and trivial so the widget stays
/// presentation-only.

String _fmtCount(int n) => n.toString();

String _fmtDuration(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final hours = d.inMinutes ~/ 60;
  final mins = d.inMinutes % 60;
  if (mins == 0) return '${hours}h';
  return '${hours}h ${twoDigits(mins)}';
}

String _fmtDistance(double km) {
  if (km < 10) return UnitFormatter.formatDistance(km);
  return UnitFormatter.formatDistance(km, fractionDigits: 0);
}

String _fmtConsumption(double? lPer100Km, ConsumptionUnit unit) {
  if (lPer100Km == null) return '—';
  return UnitFormatter.formatConsumptionLocalized(lPer100Km, unit);
}

String _fmtClimb(double meters) =>
    '${UnitFormatter.formatDecimal(meters, fractionDigits: 0)} m';
