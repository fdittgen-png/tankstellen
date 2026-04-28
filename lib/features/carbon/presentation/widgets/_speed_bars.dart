/// Internal bar-rendering widgets for [SpeedConsumptionCard] (#1192).
///
/// Split out of `speed_consumption_card.dart` to keep that file under
/// the 300-LOC budget (Refs #563). Library-private (`part of`) — no
/// public API surface changes; the bar widgets are still effectively
/// package-private to the card. The shared `maxAvg` denominator and
/// the per-band label switch live with the bars; the card file owns
/// the empty-state branch and the public widget contract.
part of 'speed_consumption_card.dart';

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
