// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../obd2/api.dart';
import 'broken_map_widgets.dart';
import 'minimal_drive_summary.dart';
import 'trip_avg_consumption_card.dart';
import 'trip_radar_card.dart';

/// #2903 — the glanceable, zero-touch LANDSCAPE recording layout.
///
/// Portrait keeps the scrolling vertical list (radar → metric cards →
/// coaching card). Landscape is a DIFFERENT, driver-safe surface: a
/// driver is driving, so every key metric is visible at once, large and
/// high-contrast, with NO scrolling and NO small tap targets.
///
/// Two-zone [Row] of [Expanded] panes — each REUSES the existing
/// recording widgets, only re-arranged (never reinvented):
///
///  - **LEFT — live driving feedback** (the most time-critical glance):
///    the big [MinimalDriveSummary] (instant L/100 km + the eco-coaching
///    cues: lift-off / anticipate / smooth-accel, or shift-up/down/ease)
///    on top, then a large **Speed** read-out underneath.
///  - **RIGHT — trip + radar**: the [TripRadarCard] (price + station +
///    closeness bar) on top, then a 2×2 grid of large
///    **Distance / Avg / Elapsed / Fuel used** tiles.
///
/// The status banner ([BrokenMapBanner]) and the Pause/Stop controls live
/// in the host scaffold (banner above this body, controls in the AppBar),
/// so this widget owns the two metric zones only.
///
/// Layout-only: the closeness-bar fill logic and all OBD2 connection code
/// are untouched — this widget re-arranges already-built widgets, it does
/// not read the adapter or compute fills.
class TripRecordingLandscapeBody extends StatelessWidget {
  const TripRecordingLandscapeBody({
    super.key,
    required this.reading,
    required this.brokenMapOverride,
  });

  /// The current live reading, or null before the first fix lands. Owned
  /// by the host screen so this widget stays free of provider reads for
  /// the raw figures (the embedded cards do their own watches).
  final TripLiveReading? reading;

  /// Pre-resolved receipt-derived L/100 km string when the active
  /// vehicle's broken-MAP belief is in the hard-disable band; null
  /// otherwise. Handed straight to [TripAvgConsumptionCard], exactly as
  /// the portrait path does — no fill logic changes here.
  final String? brokenMapOverride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = reading;

    // Two equal zones. No SingleChildScrollView: the design goal is a
    // glanceable, non-scrolling surface, so each zone is a Column whose
    // children flex to the available height.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT — live driving feedback.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instant L/100 km + the eco-coaching cue triplet. Already
              // a large-headline card; it leads the most time-critical
              // glance zone.
              const MinimalDriveSummary(),
              const SizedBox(height: 12),
              // Large speed read-out — the second live-feedback figure.
              Expanded(
                child: _BigMetricTile(
                  key: const Key('landscapeSpeedTile'),
                  icon: Icons.speed,
                  label: l?.tripMetricSpeed ?? 'Speed',
                  value: r?.speedKmh == null
                      ? '—'
                      : '${r!.speedKmh!.toStringAsFixed(0)} km/h',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // RIGHT — trip + radar.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fuel Station Radar (price + station + closeness bar) on top.
              const TripRadarCard(),
              const SizedBox(height: 8),
              // 2×2 grid of large glanceable tiles. Two Rows of two
              // Expanded tiles keeps every cell equal width and lets the
              // grid flex to the remaining height with no scrolling.
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BigMetricTile(
                              key: const Key('landscapeDistanceTile'),
                              icon: Icons.route,
                              label: l?.tripMetricDistance ?? 'Distance',
                              value: r == null
                                  ? '—'
                                  : '${r.distanceKmSoFar.toStringAsFixed(2)} km',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Avg consumption — same big-tile shape as the
                          // other three cells (a wide label/value Row card
                          // can't shrink into a quarter-cell). The value +
                          // `~`-estimate decision is REUSED verbatim from
                          // [TripAvgConsumptionCard.resolveDisplay], so the
                          // measured → GPS-estimate → broken-MAP-override
                          // logic stays in ONE place — not reinvented.
                          Expanded(
                            child: _BigMetricTile(
                              key: const Key('landscapeAvgTile'),
                              icon: Icons.eco,
                              label: l?.tripMetricAvgConsumption ?? 'Avg',
                              value: TripAvgConsumptionCard.resolveDisplay(
                                r,
                                brokenMapOverride: brokenMapOverride,
                              ).value,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BigMetricTile(
                              key: const Key('landscapeElapsedTile'),
                              icon: Icons.timer,
                              label: l?.tripMetricElapsed ?? 'Elapsed',
                              value: r == null ? '—' : _fmtElapsed(r.elapsed),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _BigMetricTile(
                              key: const Key('landscapeFuelTile'),
                              icon: Icons.local_gas_station,
                              label: l?.tripMetricFuelUsed ?? 'Fuel used',
                              value: r?.fuelLitersSoFar != null
                                  ? '${r!.fuelLitersSoFar!.toStringAsFixed(2)} L'
                                  : r?.gpsEstimatedFuelLitersSoFar != null
                                      ? '~${r!.gpsEstimatedFuelLitersSoFar!.toStringAsFixed(2)} L'
                                      : '—',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Broken-MAP disclaimer chip — self-hides outside the
              // verifying band, same as the portrait path (#1423).
              const BrokenMapDisclaimerChip(),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmtElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}

/// Large, high-contrast metric tile for the landscape grid — a label
/// over one big tabular-figures value, centred and sized to fill its
/// grid cell so the driver reads it at a glance.
///
/// Distinct from the portrait `_MetricCard` (an icon + label + trailing
/// value Row) because the landscape goal is a BIG centred number, not a
/// dense list row. The value text auto-shrinks via [FittedBox] so a long
/// figure (or a large text-scale) never overflows the cell.
class _BigMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BigMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Big value, shrink-to-fit so neither a long figure nor a
            // large text-scale overflows the cell.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
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
