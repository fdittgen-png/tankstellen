import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/monthly_insights_aggregator.dart';

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
/// The widget is purely presentational. Bucketing / averaging happens
/// inside the aggregator, which is unit-tested separately.
class MonthlyInsightsCard extends StatelessWidget {
  /// Pre-computed aggregate. Build it via
  /// `aggregateMonthlyInsights(trips, now)`.
  final MonthlyInsightsSummary summary;

  const MonthlyInsightsCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reliable = summary.isComparisonReliable;

    final tripsRow = _MetricRow(
      label: l?.consumptionMonthlyTripsLabel ?? 'Trips',
      currentValue: _fmtCount(summary.currentMonthTripCount),
      previousValue: _fmtCount(summary.previousMonthTripCount),
      delta: summary.tripCountDelta,
      sentiment: _Sentiment.neutral,
      showPrevious: reliable,
    );

    final driveTimeRow = _MetricRow(
      label: l?.consumptionMonthlyDriveTimeLabel ?? 'Drive time',
      currentValue: _fmtDuration(summary.currentMonthDriveTime),
      previousValue: _fmtDuration(summary.previousMonthDriveTime),
      delta: summary.driveTimeDelta.inMinutes,
      sentiment: _Sentiment.neutral,
      showPrevious: reliable,
    );

    final distanceRow = _MetricRow(
      label: l?.consumptionMonthlyDistanceLabel ?? 'Distance',
      currentValue: _fmtDistance(summary.currentMonthDistanceKm),
      previousValue: _fmtDistance(summary.previousMonthDistanceKm),
      // Convert to a comparable scalar for the arrow: 1-decimal km.
      delta: ((summary.distanceKmDelta) * 10).round(),
      sentiment: _Sentiment.neutral,
      showPrevious: reliable,
    );

    // Avg consumption: only render when at least the current month has
    // a figure. When previous is null too, hide the previous column.
    final showConsumptionRow =
        summary.currentMonthAvgConsumptionLPer100km != null;
    final consumptionRow = showConsumptionRow
        ? _MetricRow(
            label: l?.consumptionMonthlyAvgConsumptionLabel ?? 'Avg consumption',
            currentValue: _fmtConsumption(
              summary.currentMonthAvgConsumptionLPer100km,
            ),
            previousValue: _fmtConsumption(
              summary.previousMonthAvgConsumptionLPer100km,
            ),
            // Round to one decimal so a +0.04 swing doesn't render as
            // a coloured arrow when the displayed numbers are equal.
            delta: ((summary.consumptionDeltaLPer100km ?? 0) * 10).round(),
            sentiment: _Sentiment.lowerIsBetter,
            showPrevious: reliable &&
                summary.previousMonthAvgConsumptionLPer100km != null,
          )
        : null;

    return Card(
      key: const ValueKey('monthly_insights_card'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.consumptionMonthlyInsightsTitle ?? 'This month vs last month',
              style: theme.textTheme.titleMedium,
            ),
            if (!reliable) ...[
              const SizedBox(height: 4),
              Text(
                l?.consumptionMonthlyComparisonNotReliable ??
                    'Need at least 3 trips per month for comparison',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            tripsRow,
            const SizedBox(height: 8),
            driveTimeRow,
            const SizedBox(height: 8),
            distanceRow,
            if (consumptionRow != null) ...[
              const SizedBox(height: 8),
              consumptionRow,
            ],
          ],
        ),
      ),
    );
  }
}

/// Sentiment band for the trailing delta arrow. `neutral` means the
/// arrow is rendered grey regardless of direction (more activity is
/// not inherently good/bad). `lowerIsBetter` is for fuel — down green,
/// up red.
enum _Sentiment { neutral, lowerIsBetter }

/// One labelled row inside [MonthlyInsightsCard]. Renders the label on
/// the left, the current value bold, the previous value in muted text
/// (when [showPrevious] is true), and a trailing delta arrow.
class _MetricRow extends StatelessWidget {
  final String label;
  final String currentValue;
  final String previousValue;
  final num delta;
  final _Sentiment sentiment;
  final bool showPrevious;

  const _MetricRow({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.delta,
    required this.sentiment,
    required this.showPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            currentValue,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (showPrevious) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              previousValue,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            child: _DeltaArrow(delta: delta, sentiment: sentiment),
          ),
        ],
      ],
    );
  }
}

/// The trailing arrow on a metric row. Hidden when the displayed
/// values are equal (delta == 0). Colour follows [sentiment]:
///   * `neutral`   → grey, both directions
///   * `lowerIsBetter` → up = error, down = primary
class _DeltaArrow extends StatelessWidget {
  final num delta;
  final _Sentiment sentiment;

  const _DeltaArrow({required this.delta, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    if (delta == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final up = delta > 0;
    final color = switch (sentiment) {
      _Sentiment.neutral => theme.colorScheme.onSurfaceVariant,
      _Sentiment.lowerIsBetter =>
        up ? theme.colorScheme.error : Colors.green.shade700,
    };
    return Icon(
      up ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: color,
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
  return '${hours}h ${mins.toString().padLeft(2, '0')}';
}

String _fmtDistance(double km) {
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.toStringAsFixed(0)} km';
}

String _fmtConsumption(double? lPer100Km) {
  if (lPer100Km == null) return '—';
  return '${lPer100Km.toStringAsFixed(1)} L/100';
}
