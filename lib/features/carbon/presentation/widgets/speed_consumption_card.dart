import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/domain/services/speed_consumption_histogram.dart';

/// Consumption-by-speed card on the Carbon dashboard Charts tab (#1192).
///
/// Renders one horizontal bar per [SpeedBand], with bar length
/// proportional to the band's average L/100 km. The user can see at a
/// glance which speed band is costing them most fuel — and adjust their
/// motorway cruising speed accordingly. The whole card stays on the
/// dashboard even when the user has no OBD2 data yet, falling through
/// to an explanatory empty-state so the feature is discoverable.
///
/// ## Empty-state thresholds
///
/// * `totalSampleCount == 0` → no OBD2 telemetry recorded yet.
/// * `totalTimeShareSeconds < 1800` (< 30 min total) → not enough
///   data for the bar averages to be meaningful.
///
/// In either case the card body is replaced by the
/// [AppLocalizations.speedConsumptionInsufficientData] copy. Keeping
/// the card itself visible (as opposed to hiding it) makes the
/// requirement discoverable for the user — the empty-state IS the call
/// to action ("plug in your OBD2 adapter and drive 30 min").
///
/// ## Bar rendering
///
/// * `idleJam` band: thin neutral bar with "—" in the right column.
///   The band exists for time-share only — its `avgLPer100Km` is null
///   by design.
/// * Bands with `avgLPer100Km == null` (under the 30-sample floor):
///   thin bar with the "Need more data" label.
/// * All other bands: bar length = `avg / maxAvg` of the visible bins,
///   so the bar with the highest L/100 km fills the available width.
///   Sub-label shows "23 % of driving" computed from
///   `timeShareSeconds / totalTimeShareSeconds`.
/// * Reference vertical line: rendered when [overallAvgLPer100Km] is
///   non-null AND at least one bar has a non-null avg. Position is
///   `overallAvg / maxAvg` along the bar's track. Anchors which bands
///   are above/below the user's vehicle-wide figure.
class SpeedConsumptionCard extends StatelessWidget {
  /// Pre-computed bins, in [SpeedBand] declaration order. The widget
  /// renders them in the order received — the dashboard caller passes
  /// the result of `aggregateSpeedConsumption(...)` directly.
  final List<SpeedConsumptionBin> bins;

  /// Vehicle-wide average L/100 km used as the reference line. Compute
  /// from the same trip set the [bins] were built from so the line
  /// stays consistent with the bars next to it. Null when no overall
  /// avg can be computed (e.g. no trips have fuel-rate data) — the
  /// reference line is then suppressed.
  final double? overallAvgLPer100Km;

  /// Localizations bundle for the host context. Required so the widget
  /// can be unit-tested without an inherited [AppLocalizations].
  final AppLocalizations l;

  /// Theme bundle, threaded in from the host so the widget never
  /// reaches into [Theme.of] directly — keeps it cheap to render
  /// inside a `ListView`.
  final ThemeData theme;

  const SpeedConsumptionCard({
    super.key,
    required this.bins,
    required this.overallAvgLPer100Km,
    required this.l,
    required this.theme,
  });

  /// Minimum total time-share (in seconds) before the bars are
  /// rendered. 30 min ≈ 1800 s — under that the per-band averages
  /// swing too much on engine-load noise to be useful.
  static const double minTotalTimeShareSeconds = 1800.0;

  @override
  Widget build(BuildContext context) {
    final totalSampleCount =
        bins.fold<int>(0, (sum, bin) => sum + bin.sampleCount);
    final totalTimeShareSeconds =
        bins.fold<double>(0.0, (sum, bin) => sum + bin.timeShareSeconds);

    final hasInsufficientData = totalSampleCount == 0 ||
        totalTimeShareSeconds < minTotalTimeShareSeconds;

    return Card(
      key: const ValueKey('speed_consumption_card'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.speedConsumptionCardTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (hasInsufficientData)
              _InsufficientData(l: l, theme: theme)
            else
              _BarList(
                bins: bins,
                totalTimeShareSeconds: totalTimeShareSeconds,
                overallAvgLPer100Km: overallAvgLPer100Km,
                l: l,
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty-state shown inside the card when there isn't enough OBD2
/// telemetry yet. Renders the localised copy with a leading info icon
/// so the user reads it as guidance, not an error.
class _InsufficientData extends StatelessWidget {
  final AppLocalizations l;
  final ThemeData theme;

  const _InsufficientData({required this.l, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('speed_consumption_insufficient_data'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.speedConsumptionInsufficientData,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical stack of one [_SpeedBar] per band, plus an optional
/// reference line at the vehicle's overall avg. The list owns the
/// shared `maxAvg` so every bar in the stack scales against the same
/// denominator — bar length comparisons are honest.
class _BarList extends StatelessWidget {
  final List<SpeedConsumptionBin> bins;
  final double totalTimeShareSeconds;
  final double? overallAvgLPer100Km;
  final AppLocalizations l;
  final ThemeData theme;

  const _BarList({
    required this.bins,
    required this.totalTimeShareSeconds,
    required this.overallAvgLPer100Km,
    required this.l,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Find the max avg across bins that actually have one. Used as the
    // bar-length denominator so the worst-consumption band fills the
    // track. Falls back to 1.0 when no bin has an avg (every bin is
    // null) — bars then render at their floor width.
    double maxAvg = 0.0;
    for (final bin in bins) {
      final avg = bin.avgLPer100Km;
      if (avg != null && avg > maxAvg) maxAvg = avg;
    }
    if (maxAvg <= 0) maxAvg = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final bin in bins)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _SpeedBar(
              key: Key('speed_bar_${bin.band.name}'),
              bin: bin,
              maxAvg: maxAvg,
              overallAvgLPer100Km: overallAvgLPer100Km,
              totalTimeShareSeconds: totalTimeShareSeconds,
              l: l,
              theme: theme,
            ),
          ),
      ],
    );
  }
}

/// One horizontal bar inside the bar list. Renders three pieces:
///   * leading band label (left-aligned, width-capped so long
///     translations don't shove the bar offscreen);
///   * the bar itself, with width proportional to the bin's avg, plus
///     the optional vertical reference line;
///   * trailing avg L/100 km figure (or "—" / "Need more data").
class _SpeedBar extends StatelessWidget {
  final SpeedConsumptionBin bin;
  final double maxAvg;
  final double? overallAvgLPer100Km;
  final double totalTimeShareSeconds;
  final AppLocalizations l;
  final ThemeData theme;

  const _SpeedBar({
    super.key,
    required this.bin,
    required this.maxAvg,
    required this.overallAvgLPer100Km,
    required this.totalTimeShareSeconds,
    required this.l,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final avg = bin.avgLPer100Km;
    final isIdle = bin.band == SpeedBand.idleJam;

    // Bar fill fraction in [0, 1]. Idle/jam and under-threshold bins
    // render a thin "floor" bar (3 %) so their label still has visual
    // presence — a zero-width bar would look like a rendering bug.
    final fillFraction = avg == null ? 0.03 : (avg / maxAvg).clamp(0.0, 1.0);

    final referenceFraction = (avg != null && overallAvgLPer100Km != null)
        ? (overallAvgLPer100Km! / maxAvg).clamp(0.0, 1.0)
        : null;

    final timeShareLabel = totalTimeShareSeconds > 0
        ? l.speedConsumptionTimeShare(
            ((bin.timeShareSeconds / totalTimeShareSeconds) * 100).round(),
          )
        : l.speedConsumptionTimeShare(0);

    final trailing = avg == null
        ? (isIdle ? '—' : l.speedConsumptionNeedMoreData)
        : '${avg.toStringAsFixed(1)} L/100';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _bandLabel(bin.band),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                timeShareLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final barWidth = trackWidth * fillFraction;
              return SizedBox(
                height: 18,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(
                      width: barWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: avg == null
                              ? theme.colorScheme.outlineVariant
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (referenceFraction != null)
                      Positioned(
                        left: trackWidth * referenceFraction,
                        top: -2,
                        bottom: -2,
                        child: Container(
                          key: const ValueKey(
                            'speed_consumption_reference_line',
                          ),
                          width: 2,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            trailing,
            textAlign: TextAlign.end,
            style: avg == null
                ? theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Map a [SpeedBand] to its localised label. Switch is exhaustive so
  /// adding a band to the enum without updating the UI is a compile-
  /// time error — surfaces missing translations the moment the
  /// aggregator grows.
  String _bandLabel(SpeedBand band) {
    switch (band) {
      case SpeedBand.idleJam:
        return l.speedBandIdleJam;
      case SpeedBand.urban:
        return l.speedBandUrban;
      case SpeedBand.suburban:
        return l.speedBandSuburban;
      case SpeedBand.rural:
        return l.speedBandRural;
      case SpeedBand.motorwaySlow:
        return l.speedBandMotorwaySlow;
      case SpeedBand.motorway:
        return l.speedBandMotorway;
      case SpeedBand.motorwayFast:
        return l.speedBandMotorwayFast;
    }
  }
}
