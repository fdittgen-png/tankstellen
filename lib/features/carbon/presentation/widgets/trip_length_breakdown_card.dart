import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/domain/services/consumption_trip_length_aggregator.dart';

/// Carbon dashboard card that breaks down consumption by trip length —
/// short / medium / long voyages — so the user can see whether fuel is
/// wasted on cold-engine short hops vs. cruising voyages (#1191).
///
/// Layout: a single [SectionCard] with three horizontally-stacked tiles
/// (Short / Medium / Long). Each tile shows
///   * the bucket label,
///   * the bucket distance range,
///   * average L/100 km (one decimal),
///   * trip count and total km.
/// A trailing arrow icon (`arrow_drop_up` / `arrow_drop_down`) and tile
/// background tint signal whether the bucket is above or below the
/// vehicle's overall average. The aggregator returns the overall avg
/// alongside the buckets so the widget never re-walks the trip list.
///
/// Per-tile fallback: when `tripCount < 5`, that tile renders a
/// "need more data" placeholder instead of the consumption number.
/// The other tiles continue to render normally; the threshold is per-
/// bucket so a city-only car still gets a Short reading even when
/// Long has only one entry.
///
/// Whole-card fallback: the parent should hide this card entirely when
/// the breakdown's [ConsumptionTripLengthBreakdown.isEmpty] is true —
/// that guard is also enforced internally as a defence-in-depth so the
/// widget never renders a row of three empty placeholders. See
/// [build] for the early return.
class TripLengthBreakdownCard extends StatelessWidget {
  /// Pre-computed breakdown — typically derived in the parent
  /// (`carbon_dashboard_screen.dart`) from the active vehicle's trips
  /// via [aggregateConsumptionByTripLength].
  final ConsumptionTripLengthBreakdown breakdown;

  /// Minimum trip count required to surface a bucket's avg L/100 km.
  /// Below this the tile shows the "need more data" placeholder. Five
  /// is the lowest count where averaging across cold-engine variability
  /// stops being dominated by a single outlier; the issue body fixes
  /// this number, so it lives here as a constant rather than a config.
  static const int minTripsForAvg = 5;

  const TripLengthBreakdownCard({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    // Defence-in-depth — the parent should already have hidden the
    // card when there's nothing to show. Returning a zero-sized box
    // keeps the surface intact even if the parent forgets.
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SectionCard(
        title: l?.tripLengthCardTitle ?? 'Consumption by trip length',
        subtitle: l?.tripLengthCardSubtitle ??
            'Cold-engine short hops vs. long voyages',
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BucketTile(
                  key: const Key('trip_length_bucket_short'),
                  label: l?.tripLengthBucketShort ?? 'Short',
                  rangeLabel: '< 5 km',
                  stats: breakdown.short,
                  overallAvg: breakdown.overallAvgLPer100Km,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BucketTile(
                  key: const Key('trip_length_bucket_medium'),
                  label: l?.tripLengthBucketMedium ?? 'Medium',
                  rangeLabel: '5–25 km',
                  stats: breakdown.medium,
                  overallAvg: breakdown.overallAvgLPer100Km,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BucketTile(
                  key: const Key('trip_length_bucket_long'),
                  label: l?.tripLengthBucketLong ?? 'Long',
                  rangeLabel: '>= 25 km',
                  stats: breakdown.long,
                  overallAvg: breakdown.overallAvgLPer100Km,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tile in the three-bucket row. Renders one of three states:
///   1. `tripCount == 0` — tile shows the label + range + dash (no
///      data). The widget never renders a visible "0 trips" tile in
///      practice because the parent hides the whole card when every
///      bucket is empty; this branch is the safety net.
///   2. `tripCount < minTripsForAvg` — placeholder ("need more data")
///      replaces the avg L/100 km.
///   3. `tripCount >= minTripsForAvg` — full reading + arrow indicator
///      against the overall vehicle average.
class _BucketTile extends StatelessWidget {
  final String label;
  final String rangeLabel;
  final ConsumptionTripLengthBucketStats stats;
  final double? overallAvg;

  const _BucketTile({
    super.key,
    required this.label,
    required this.rangeLabel,
    required this.stats,
    required this.overallAvg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final hasEnough =
        stats.tripCount >= TripLengthBreakdownCard.minTripsForAvg;
    final avg = stats.avgLPer100Km;
    final overall = overallAvg;

    // One-decimal formatter — locale-aware (uses ',' on de_DE, '.' on
    // en_US). intl's NumberFormat respects the inherited locale of the
    // parent MaterialApp via Intl.defaultLocale, so we don't pin one
    // explicitly here.
    final formatter = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;

    final isAbove = (hasEnough && avg != null && overall != null && avg > overall);
    final isBelow = (hasEnough && avg != null && overall != null && avg < overall);

    final tint = isAbove
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
        : isBelow
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final arrowIcon = isAbove
        ? Icons.arrow_drop_up
        : isBelow
            ? Icons.arrow_drop_down
            : null;

    Widget valueLine;
    String? semanticLabel;
    if (!hasEnough) {
      valueLine = Text(
        l?.tripLengthNeedMoreData ??
            'Need at least 5 trips in this bucket',
        key: const Key('trip_length_need_more_data'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      final formatted = formatter.format(avg);
      final unitLine = l?.tripLengthAvgUnit(formatted) ?? '$formatted L/100 km';
      valueLine = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              unitLine,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (arrowIcon != null)
            Icon(
              arrowIcon,
              size: 20,
              color: isAbove
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
        ],
      );
      if (isAbove) {
        semanticLabel = l?.tripLengthAboveAverageA11y(formatted) ??
            '$formatted L per 100 km, above average';
      } else if (isBelow) {
        semanticLabel = l?.tripLengthBelowAverageA11y(formatted) ??
            '$formatted L per 100 km, below average';
      }
    }

    final countStr = stats.tripCount.toString();
    final kmStr = formatter.format(stats.totalDistanceKm);
    final subtitle = l?.tripLengthBucketSubtitle(countStr, kmStr) ??
        '$countStr trips · $kmStr km';

    final tile = Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rangeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          valueLine,
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, child: tile);
    }
    return tile;
  }
}
