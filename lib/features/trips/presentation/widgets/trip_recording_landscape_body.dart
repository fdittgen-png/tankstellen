// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/domain/consumption_unit.dart';
import '../../../obd2/api.dart';
import 'broken_map_widgets.dart';
import '../../../driving_score/api.dart';
import 'minimal_drive_summary.dart';
import 'recording/recording_metric_grid.dart';
import 'recording/recording_status_strip.dart';
import 'trip_radar_card.dart';

/// #2903 / #3916 — the glanceable, zero-touch LANDSCAPE recording layout.
///
/// Landscape is a DIFFERENT, driver-safe surface from the scrolling
/// portrait column: a driver is driving, so every key metric is visible
/// at once, large and high-contrast, with NO scrolling and NO small tap
/// targets. It mirrors the portrait hierarchy (#3916):
///
///  - **LEFT — live driving feedback**: the hero ([MinimalDriveSummary]:
///    the one live consumption figure + speed + coaching cues), the
///    OBD2 / GPS [RecordingStatusStrip] under it, then the
///    [TripRadarCard] (price + station + closeness bar).
///  - **RIGHT — trip figures**: the [RecordingMetricGrid] flexed to
///    fill the pane (Distance / Elapsed, Fuel / Score, the consumption
///    card with its badges).
///
/// The hero shrinks to fit whatever height the strip and the radar leave
/// (a large text scale on a short landscape phone), so the left zone
/// never overflows and never scrolls. The status banner and the Pause /
/// Stop controls live in the host scaffold.
///
/// Layout-only: the closeness-bar fill logic and all OBD2 connection code
/// are untouched — this widget re-arranges already-built widgets.
class TripRecordingLandscapeBody extends StatelessWidget {
  const TripRecordingLandscapeBody({
    super.key,
    required this.reading,
    required this.brokenMapOverride,
    this.unit = ConsumptionUnit.lPer100Km, // #3883
  });

  /// #3883 — the display unit of the average tile.
  final ConsumptionUnit unit;

  /// The current live reading, or null before the first fix lands. Owned
  /// by the host screen so this widget stays free of provider reads for
  /// the raw figures (the embedded cards do their own watches).
  final TripLiveReading? reading;

  /// Pre-resolved receipt-derived L/100 km string when the active
  /// vehicle's broken-MAP belief is in the hard-disable band; null
  /// otherwise. Handed straight to the grid's consumption card, exactly
  /// as the portrait path does — no fill logic changes here.
  final String? brokenMapOverride;

  @override
  Widget build(BuildContext context) {
    // Two equal zones. No SingleChildScrollView: the design goal is a
    // glanceable, non-scrolling surface.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT — live driving feedback.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The hero takes what is left after the strip + radar and
              // scales down rather than overflowing; a LayoutBuilder pins
              // its width so the Expanded rows inside it stay bounded.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: const MinimalDriveSummary(),
                    ),
                  ),
                ),
              ),
              // #3432 — live eco-nudge SnackBars in landscape too (the
              // portrait column mounts its own; zero-size widget).
              const EcoNudgeListener(),
              const SizedBox(height: 8),
              const RecordingStatusStrip(),
              const SizedBox(height: 8),
              const TripRadarCard(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // RIGHT — trip figures.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RecordingMetricGrid(
                  reading: reading,
                  brokenMapOverride: brokenMapOverride,
                  unit: unit,
                  expand: true,
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
}
