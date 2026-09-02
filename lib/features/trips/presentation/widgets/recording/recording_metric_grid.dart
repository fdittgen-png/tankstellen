// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/consumption_unit.dart';
import '../../../../../core/utils/time_formatter.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../obd2/api.dart';
import '../trip_avg_consumption_card.dart';

/// The recording screen's compact trip-figures grid (#3916, Epic #3914):
/// three rows of two — Distance / Elapsed, Fuel used / Driving score —
/// and the consumption card (average + its maturity and fuel-source
/// badges) spanning the last row. Replaces the six full-width metric
/// rows the screen used to stack.
///
/// Portrait ([expand] false) sizes every row to its content inside the
/// scrolling column; landscape ([expand] true) flexes the three rows to
/// fill the pane so nothing scrolls. Every value is shrink-to-fit, so a
/// long figure or a large text scale never overflows a cell.
class RecordingMetricGrid extends StatelessWidget {
  const RecordingMetricGrid({
    super.key,
    required this.reading,
    required this.brokenMapOverride,
    this.unit = ConsumptionUnit.lPer100Km,
    this.expand = false,
  });

  /// The current live reading, or null before the first fix lands.
  final TripLiveReading? reading;

  /// Pre-resolved receipt-derived average when the active vehicle's
  /// broken-MAP belief is in the hard-disable band; null otherwise.
  /// Handed straight to [TripAvgConsumptionCard].
  final String? brokenMapOverride;

  /// #3883 — the display unit of the average.
  final ConsumptionUnit unit;

  /// Flex the rows to fill the available height (landscape).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = reading;
    final score = r?.liveDrivingScore;

    Widget row(List<Widget> cells) {
      final content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: cells[i]),
          ],
        ],
      );
      // IntrinsicHeight keeps the two cells of a row the same height in
      // the content-sized (portrait) layout; a single-cell row needs no
      // equalising (and the consumption card's LayoutBuilder cannot
      // answer an intrinsic-height probe).
      if (expand) return Expanded(child: content);
      return cells.length > 1 ? IntrinsicHeight(child: content) : cells.single;
    }

    final rows = <Widget>[
      row([
        RecordingMetricTile(
          key: const Key('recordingTileDistance'),
          icon: Icons.route,
          label: l.tripMetricDistance,
          value: r == null
              ? '—'
              : UnitFormatter.formatDistance(r.distanceKmSoFar,
                  fractionDigits: 2),
        ),
        RecordingMetricTile(
          key: const Key('recordingTileElapsed'),
          icon: Icons.timer,
          label: l.tripMetricElapsed,
          value: r == null ? '—' : formatMinutesSeconds(r.elapsed),
        ),
      ]),
      const SizedBox(height: 8),
      row([
        RecordingMetricTile(
          key: const Key('recordingTileFuel'),
          icon: Icons.local_gas_station,
          label: l.tripMetricFuelUsed,
          // #2391 — measured litres, else the GPS estimator's running
          // integral with `~`, else `—`.
          value: r?.fuelLitersSoFar != null
              ? '${UnitFormatter.formatDecimal(r!.fuelLitersSoFar!, fractionDigits: 2)} L'
              : r?.gpsEstimatedFuelLitersSoFar != null
                  ? '~${UnitFormatter.formatDecimal(r!.gpsEstimatedFuelLitersSoFar!, fractionDigits: 2)} L'
                  : '—',
        ),
        RecordingMetricTile(
          key: const Key('recordingTileScore'),
          icon: Icons.emoji_events_outlined,
          label: l.recordingTileScore,
          value: score == null
              ? '—'
              : UnitFormatter.formatDecimal(score.toDouble(),
                  fractionDigits: 0),
        ),
      ]),
      const SizedBox(height: 8),
      // The consumption card spans the full row: its label / value Row
      // plus the maturity + fuel-source badges need the width.
      row([
        TripAvgConsumptionCard(
          live: r,
          brokenMapOverride: brokenMapOverride,
          unit: unit,
        ),
      ]),
    ];

    return Column(
      key: const Key('recordingMetricGrid'),
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// One glanceable tile of the grid: a glyph + single-line label over one
/// big tabular-figures value that shrinks to fit its cell.
class RecordingMetricTile extends StatelessWidget {
  const RecordingMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
