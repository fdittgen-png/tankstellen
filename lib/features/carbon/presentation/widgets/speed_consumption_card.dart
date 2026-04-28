/// Consumption-by-speed card on the Carbon dashboard Charts tab (#1192).
///
/// See [SpeedConsumptionCard] for the rendering contract. The bar
/// widgets (`_BarList`, `_SpeedBar`) live in `_speed_bars.dart` as a
/// `part of` this library so the file stays under the 300-LOC budget
/// (Refs #563) — public API surface is unchanged.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/domain/services/speed_consumption_histogram.dart';

part '_speed_bars.dart';

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
