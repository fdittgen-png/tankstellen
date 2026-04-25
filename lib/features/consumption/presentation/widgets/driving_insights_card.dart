import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_insight.dart';

/// "Top wasteful behaviours" card on the Trip detail screen
/// (#1041 phase 2).
///
/// Surfaces the up-to-three [DrivingInsight] cost lines produced by
/// `analyzeTrip()` (phase 1) as a stack of [ListTile]-style rows. Each
/// row shows:
///   * a localized headline derived from [DrivingInsight.labelKey]
///     (e.g. "Engine over 3000 RPM (12% of trip): wasted 0.6 L"),
///   * a secondary "{x}% of trip" caption, and
///   * a trailing "+{y} L" badge that re-states the wasted-fuel
///     number for at-a-glance scanning.
///
/// Liters are formatted to a single decimal — telematics-grade
/// precision is misleading given the analyzer's coarse counterfactual
/// model (documented in `docs/guides/driving-insights.md`). Showing
/// "0.6 L" coaches without overclaiming.
///
/// Renders an empty-state message ("No notable inefficiencies — keep
/// it up!") when [insights] is empty so the card never silently
/// disappears — the user always knows the analysis ran.
///
/// The widget is purely presentational. Sorting / capping / metadata
/// extraction all happen inside the analyzer; the card trusts the
/// caller's order. Re-sorting here would let a future analyzer change
/// (e.g. ranking by user-impact rather than litres) ship without UI
/// edits.
class DrivingInsightsCard extends StatelessWidget {
  /// Top-N cost lines from `analyzeTrip()` — already sorted by
  /// `litersWasted` desc and capped at 3. Empty list → empty-state.
  final List<DrivingInsight> insights;

  const DrivingInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.insightCardTitle ?? 'Top wasteful behaviours',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (insights.isEmpty)
              _EmptyState(
                message: l?.insightEmptyState ??
                    'No notable inefficiencies — keep it up!',
              )
            else
              for (final insight in insights)
                _InsightTile(insight: insight),
          ],
        ),
      ),
    );
  }
}

/// One row in the [DrivingInsightsCard]. Renders a localized headline
/// derived from [DrivingInsight.labelKey], a "% of trip" subtitle, and
/// a trailing "+x L" badge.
class _InsightTile extends StatelessWidget {
  final DrivingInsight insight;

  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final litersFormatted = _formatLiters(insight.litersWasted);
    final pctFormatted = _formatPercent(insight.percentOfTrip);
    final headline = _buildHeadline(l, litersFormatted, pctFormatted);
    final subtitle =
        l?.insightSubtitlePctOfTrip(pctFormatted) ?? '$pctFormatted% of trip';
    final trailing =
        l?.insightTrailingLitersWasted(litersFormatted) ?? '+$litersFormatted L';

    return ListTile(
      key: ValueKey('insight_tile_${insight.labelKey}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _iconFor(insight.labelKey),
        color: theme.colorScheme.error,
      ),
      title: Text(headline),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        trailing,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.error,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Map an analyzer-emitted label key to the localized template.
  /// Unknown keys fall back to a generic "+{liters} L" sentence so a
  /// future analyzer category surfaces visibly even before its ARB
  /// entry lands.
  String _buildHeadline(
    AppLocalizations? l,
    String litersFormatted,
    String pctFormatted,
  ) {
    switch (insight.labelKey) {
      case 'insightHighRpm':
        return l?.insightHighRpm(pctFormatted, litersFormatted) ??
            'Engine over 3000 RPM ($pctFormatted% of trip): wasted $litersFormatted L';
      case 'insightHardAccel':
        // Hard-accel uses an event count, not a percent of trip; pull
        // the count out of the metadata bag emitted by the analyzer.
        final count =
            (insight.metadata['eventCount'] ?? 0).toInt().toString();
        return l?.insightHardAccel(count, litersFormatted) ??
            '$count hard accelerations: wasted $litersFormatted L';
      case 'insightIdling':
        return l?.insightIdling(pctFormatted, litersFormatted) ??
            'Idling ($pctFormatted% of trip): wasted $litersFormatted L';
      default:
        // Unknown key — show a defensive fallback rather than crash.
        // Logged via the parent screen's tracing in production.
        return '+$litersFormatted L';
    }
  }

  IconData _iconFor(String labelKey) {
    switch (labelKey) {
      case 'insightHighRpm':
        return Icons.speed;
      case 'insightHardAccel':
        return Icons.flash_on;
      case 'insightIdling':
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }
}

/// Empty-state row used when the analyzer found nothing above the
/// noise floor. Kept inline rather than reusing `core/widgets/empty_state.dart`
/// because that widget is full-screen and would dominate the trip detail
/// scroll view.
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.thumb_up_alt_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-decimal litres formatter — "0.6", not "0.6000". Negative values
/// (impossible in production but cheap to defend against) are clamped
/// to zero so we never coach with a negative waste figure.
String _formatLiters(double liters) {
  final clamped = liters < 0 ? 0.0 : liters;
  return clamped.toStringAsFixed(1);
}

/// Whole-number percent formatter — "12", not "12.345". Matches the
/// analyzer's coaching-grade precision.
String _formatPercent(double pct) {
  return pct.toStringAsFixed(0);
}
