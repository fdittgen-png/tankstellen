import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/domain/services/trip_length_aggregator.dart';

/// Trip-length consumption breakdown card on the Carbon dashboard
/// Charts tab (#1191).
///
/// Renders three horizontally-stacked tiles — Short (<5 km), Medium
/// (5-25 km), Long (>25 km) — each showing the bucket's avg L/100 km,
/// trip count, and total distance. When [overallAvgLPer100Km] is
/// non-null, each tile additionally renders an above/below indicator
/// arrow against the vehicle-wide average:
///
///   * red arrow_upward    → bucket avg is HIGHER than overall (worse
///                           — the user is burning more in this bucket
///                           than they do on average)
///   * green arrow_downward → bucket avg is LOWER than overall (better)
///
/// Statistical-floor gates:
///   * When EVERY bucket has zero trips, the entire card is hidden
///     (returns [SizedBox.shrink]). The dashboard rendering should
///     not waste vertical space on an empty 3-tile row.
///   * When a bucket has between 1 and 4 trips inclusive, that tile
///     shows the "Need more data" placeholder instead of an average —
///     averaging two trips' L/100 km is dominated by single-trip
///     noise. Five was chosen as the minimum for the same reason
///     `aggregateMonthlyInsights` gates at 3-per-month: it's the
///     smallest count where a pattern becomes visible without one
///     outlier swinging the result.
///
/// Localised strings flow through [AppLocalizations] — see the
/// `trip_length_breakdown_<locale>.arb` fragments for the surface.
class TripLengthBreakdownCard extends StatelessWidget {
  /// Pre-computed aggregate. Build it via
  /// `aggregateByTripLength(trips, vehicleId: ...)` from the dashboard
  /// caller; this widget is purely presentational.
  final TripLengthBreakdown breakdown;

  /// Vehicle-wide average L/100 km used as the comparison baseline for
  /// the per-tile up/down arrows. When null (e.g. no overall trips
  /// have fuel-rate data) the arrows are suppressed. Compute it from
  /// the same filtered trip list the [breakdown] was built from so the
  /// per-tile delta is consistent with the headline figure the user
  /// already sees on the dashboard.
  final double? overallAvgLPer100Km;

  /// Localizations bundle for the host context. Required so the widget
  /// can be unit-tested without an inherited [AppLocalizations] (the
  /// test wraps this in a `MaterialApp` with `AppLocalizations.delegate`
  /// and reads the bundle there).
  final AppLocalizations l;

  /// Theme bundle, threaded in from the host so the widget never
  /// reaches into [Theme.of] directly — keeps it cheap to render
  /// inside a `ListView` without rebuilding on theme inheritance
  /// changes.
  final ThemeData theme;

  const TripLengthBreakdownCard({
    super.key,
    required this.breakdown,
    required this.overallAvgLPer100Km,
    required this.l,
    required this.theme,
  });

  /// Minimum trip count per bucket before the average is shown.
  /// Below this we render the "Need more data" placeholder — averaging
  /// two trips swings on every fill-up.
  static const int minTripsForAverage = 5;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      key: const ValueKey('trip_length_breakdown_card'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.tripLengthCardTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BucketTile(
                      key: const Key('trip_length_tile_short'),
                      label: l.tripLengthBucketShort,
                      stats: breakdown.short,
                      overallAvgLPer100Km: overallAvgLPer100Km,
                      l: l,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BucketTile(
                      key: const Key('trip_length_tile_medium'),
                      label: l.tripLengthBucketMedium,
                      stats: breakdown.medium,
                      overallAvgLPer100Km: overallAvgLPer100Km,
                      l: l,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BucketTile(
                      key: const Key('trip_length_tile_long'),
                      label: l.tripLengthBucketLong,
                      stats: breakdown.long,
                      overallAvgLPer100Km: overallAvgLPer100Km,
                      l: l,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One bucket tile inside [TripLengthBreakdownCard].
///
/// Renders one of three layouts depending on the bucket state:
///   * `tripCount == 0` → tile shows the bucket label, "—" placeholder
///     for the average, "no trips" subtitle. No arrow.
///   * `tripCount in [1, 4]` → tile shows the bucket label, "Need
///     more data" placeholder, count subtitle. No arrow.
///   * `tripCount >= 5` → tile shows the bucket label, average
///     L/100 km, count + distance subtitle, arrow vs. overall avg.
class _BucketTile extends StatelessWidget {
  final String label;
  final TripLengthBucketStats stats;
  final double? overallAvgLPer100Km;
  final AppLocalizations l;
  final ThemeData theme;

  const _BucketTile({
    super.key,
    required this.label,
    required this.stats,
    required this.overallAvgLPer100Km,
    required this.l,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tripCount = stats.tripCount;
    final hasEnoughData = tripCount >= TripLengthBreakdownCard.minTripsForAverage;
    final avg = stats.avgLPer100Km;

    final headline = !hasEnoughData
        ? (tripCount == 0
            ? '—'
            : l.tripLengthBucketNeedMoreData)
        : (avg == null ? '—' : '${avg.toStringAsFixed(1)} L/100');

    final subtitle = tripCount == 0
        ? l.tripLengthBucketTripCount(0)
        : '${l.tripLengthBucketTripCount(tripCount)} · '
            '${stats.totalDistanceKm.toStringAsFixed(0)} km';

    final showArrow = hasEnoughData &&
        avg != null &&
        overallAvgLPer100Km != null &&
        avg != overallAvgLPer100Km;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                headline,
                style: hasEnoughData
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              _DeltaArrow(
                bucketAvg: avg,
                overallAvg: overallAvgLPer100Km!,
                theme: theme,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Up/down arrow on a bucket tile. Rendered only when the bucket has
/// >=5 trips AND the overall average is known AND they differ.
///
/// Sign convention is "lower L/100 km is better":
///   * bucket avg > overall → red arrow_upward (worse)
///   * bucket avg < overall → green arrow_downward (better)
class _DeltaArrow extends StatelessWidget {
  final double bucketAvg;
  final double overallAvg;
  final ThemeData theme;

  const _DeltaArrow({
    required this.bucketAvg,
    required this.overallAvg,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final worse = bucketAvg > overallAvg;
    return Icon(
      worse ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: worse ? theme.colorScheme.error : Colors.green.shade700,
    );
  }
}
