// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving_score/api.dart';
import '../../providers/trip_recording_provider.dart';
import 'broken_map_widgets.dart';
import 'recording/coaching_symbol.dart';
import 'recording/live_behaviour_band.dart';

/// The recording screen's HERO (#3916, Epic #3914; born as the compact
/// live-drive summary card, #2026): the ONE live consumption figure on
/// the screen — the rolling "last N s" average in the user's unit via
/// [resolveLiveConsumption] (#3883) — rendered large with the current
/// speed beside it, the trip running average on its own honestly-
/// labelled row (#3431), the live behaviour band (#3845) and the three
/// permanently-visible coaching cues that light up when the matching
/// [DrivingCoachingHint] fires.
///
/// Symbol mapping:
/// - **Shift up** (`Icons.keyboard_double_arrow_up`) → fires when the
///   classifier says you're over-revving in too low a gear
/// - **Shift down** (`Icons.keyboard_double_arrow_down`) → fires when
///   you're lugging the engine in too high a gear
/// - **Ease pedal** (`Icons.eco`) → fires when sustained-high-throttle
///   isn't producing matching acceleration (i.e. wasted fuel)
///
/// Greyed-out symbols carry their literal meaning even when inactive,
/// so the widget doubles as a legend. The cue widget itself lives in
/// [CoachingSymbol]; the band in [LiveBehaviourBand].
class MinimalDriveSummary extends ConsumerWidget {
  const MinimalDriveSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(tripRecordingProvider);
    final reading = state.live;
    // #3431 — the trip RUNNING AVERAGE, rendered on its own honestly-
    // labelled secondary row (measured wins; GPS estimate carries `~`).
    final liveAvg = reading?.liveAvgLPer100Km;
    final gpsAvg = reading?.gpsEstimatedAvgLPer100Km;

    // #1423 — hide the hero when broken-MAP belief is in the
    // hard-disable band. The consumption card in the grid swaps in the
    // receipt-derived value in that branch; we don't want a second
    // display showing the (now-suppressed) live MAP figure.
    final belief = readActiveVehicleBelief(ref);
    if (belief != null &&
        brokenMapBandFor(belief.pointEstimate) == BrokenMapBand.hardDisable) {
      return const SizedBox.shrink();
    }

    final hint = reading == null
        ? null
        : coachingHint(reading, situation: state.situation, band: state.band);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // #3883 — the headline is the rolling "last N s" average in the
    // user's unit when the pipeline stamped one (labelled with the
    // window), else the EMA instant (#3431) under the "Instant" label;
    // GPS-only trajets fall back to the live physics estimate with the
    // `~` estimate marker (banner / PiP convention, ADR 0012).
    final unit = ref.watch(consumptionDisplaySettingProvider).unit;
    final figure =
        reading == null ? null : resolveLiveConsumption(reading, unit: unit);
    final gpsInstant = reading?.gpsEstimatedLPer100Km;
    final headline = figure != null
        ? '${figure.figure} ${figure.shortUnit}'
        : (gpsInstant != null
            ? '${formatEstimatedConsumptionFigure(gpsInstant, unit)} '
                '${unit.shortMask}'
            : '—');
    final windowSeconds = figure?.windowSeconds;
    final headlineLabel = windowSeconds != null
        ? l.liveConsumptionWindowLabel(windowSeconds)
        : l.minimalDriveInstantConsumption;
    final avgText = liveAvg != null
        ? UnitFormatter.formatConsumption(liveAvg, isEv: false, unit: unit)
        : (gpsAvg != null
            // i18n-ignore: `~` estimate marker on a language-neutral mask
            ? '~${UnitFormatter.formatConsumption(gpsAvg, isEv: false, unit: unit)}'
            : null);
    // #3916 — the speed beside the figure (OBD2 PID, else the GPS latch).
    final speedKmh = reading?.speedKmh;
    final speedText = speedKmh == null
        ? '—'
        : UnitFormatter.formatDecimal(speedKmh, fractionDigits: 0);

    // #2058 — when the trajet has no fuel-rate data (GPS-only mode),
    // swap the OBD2-derived tile triplet (shift-up / shift-down /
    // ease-pedal) for the GPS-derived triplet (lift-off / anticipate-
    // brake / smooth-accel). The decision is made on the reading
    // shape, not on `Feature.obd2Optional`: a hybrid trip where
    // OBD2 dropped mid-recording also lands in this branch until the
    // adapter reconnects, which matches the user's mental model
    // ("I have no fuel-rate data right now → show me the GPS coach").
    final gpsMode = reading != null && reading.fuelRateLPerHour == null;
    final gpsHint = gpsMode ? state.gpsCoachingHint : null;
    final tiles = gpsMode
        ? <Widget>[
            CoachingSymbol(
              icon: Icons.eco,
              label: l.coachingGpsLiftOff,
              active: gpsHint == DrivingCoachingHint.gpsLiftOffCoast,
              scheme: scheme,
            ),
            CoachingSymbol(
              icon: Icons.visibility,
              label: l.coachingGpsAnticipateBrake,
              active: gpsHint == DrivingCoachingHint.gpsAnticipateBrake,
              scheme: scheme,
            ),
            CoachingSymbol(
              icon: Icons.swipe_up,
              label: l.coachingGpsSmoothAccel,
              active: gpsHint == DrivingCoachingHint.gpsSmoothAccel,
              scheme: scheme,
            ),
          ]
        : <Widget>[
            CoachingSymbol(
              icon: Icons.keyboard_double_arrow_up,
              label: l.coachingShiftUp,
              active: hint == DrivingCoachingHint.shiftUp,
              scheme: scheme,
            ),
            CoachingSymbol(
              icon: Icons.keyboard_double_arrow_down,
              label: l.coachingShiftDown,
              active: hint == DrivingCoachingHint.shiftDown,
              scheme: scheme,
            ),
            CoachingSymbol(
              icon: Icons.eco,
              label: l.coachingEasePedal,
              active: hint == DrivingCoachingHint.easePedal,
              scheme: scheme,
            ),
          ];

    final mutedLabel = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Card(
      key: const Key('minimal_drive_summary_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              headlineLabel,
              key: const Key('minimal_drive_headline_label'),
              style: mutedLabel,
            ),
            // #3916 — the big figure with the speed beside it. The figure
            // shrinks to fit so a wide unit (mpg) or a large text scale
            // never pushes the speed off the card.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      headline,
                      key: const Key('minimal_drive_instant_value'),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          speedText,
                          key: const Key('recording_hero_speed'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'km/h',
                        style: mutedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // #3431 — the trip running average on its own honest row,
            // so "instant" and "average" are never conflated again.
            if (avgText != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      l.minimalDriveTripAverage,
                      style: mutedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    avgText,
                    key: const Key('minimal_drive_trip_avg_value'),
                    style: mutedLabel?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            // #3845 — always-on driving-behaviour band. Present on every
            // trajet including GPS-only ones (it is scored from the
            // speed series, not from a fuel-rate PID), and absent only
            // while the tracker is still filling its first window.
            if (reading?.liveDrivingScore != null) ...[
              const SizedBox(height: 8),
              LiveBehaviourBand(score: reading!.liveDrivingScore!),
            ],
            const SizedBox(height: 6),
            // #2903 — each symbol gets an equal Expanded share so the
            // triplet fits a narrow pane (the landscape split's left
            // zone) and a large text scale without overflowing.
            Row(
              children: [
                for (final tile in tiles) Expanded(child: Center(child: tile)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
