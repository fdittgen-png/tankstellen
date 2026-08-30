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

/// Compact live-drive summary card (#2026) — one big instantaneous
/// L/100 km figure plus three permanently-visible coaching symbols
/// that light up when the matching [DrivingCoachingHint] fires.
///
/// #3431 — the headline is now the TRUE instantaneous signal (the
/// EMA-smoothed `instantLPer100Km` / `instantLPerHour` stamped by the
/// recording controller, formatted by [formatInstantConsumption]);
/// before, it rendered the trip running average `liveAvgLPer100Km`
/// under the "Instant consumption" label — a mislabel. The running
/// average keeps its place on a clearly-labelled "Trip average"
/// secondary row, so both figures are visible and honestly named.
///
/// Designed to be the *primary* surface during recording — the
/// existing `_MetricCard` column stays underneath it for users who
/// still want the detail breakdown, but a glance at the top of the
/// screen now tells you the only thing that matters live ("how am I
/// driving right now?").
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
/// so the widget doubles as a legend.
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

    // #1423 — hide the minimal card when broken-MAP belief is in the
    // hard-disable band. The existing _MetricCard column below
    // swaps in the receipt-derived value in that branch; we don't
    // want a second display showing the (now-suppressed) live MAP
    // figure. Hiding entirely is simpler than mirroring the swap
    // logic and keeps the widget's single responsibility.
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
    // #3431 — headline: the TRUE instant signal (EMA-smoothed L/100 km,
    // L/h at idle) via the shared formatter; GPS-only trajets fall back
    // to the live physics estimate with the `~` estimate marker
    // (matching the banner / PiP convention, ADR 0012).
    // #3883 — the headline is the rolling "last N s" average in the
    // user's unit when the pipeline stamped one (labelled with the
    // window), else the EMA instant under the "Instant" label.
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
            _CoachingSymbol(
              icon: Icons.eco,
              label: l.coachingGpsLiftOff,
              active: gpsHint == DrivingCoachingHint.gpsLiftOffCoast,
              scheme: scheme,
            ),
            _CoachingSymbol(
              icon: Icons.visibility,
              label: l.coachingGpsAnticipateBrake,
              active: gpsHint == DrivingCoachingHint.gpsAnticipateBrake,
              scheme: scheme,
            ),
            _CoachingSymbol(
              icon: Icons.swipe_up,
              label: l.coachingGpsSmoothAccel,
              active: gpsHint == DrivingCoachingHint.gpsSmoothAccel,
              scheme: scheme,
            ),
          ]
        : <Widget>[
            _CoachingSymbol(
              icon: Icons.keyboard_double_arrow_up,
              label: l.coachingShiftUp,
              active: hint == DrivingCoachingHint.shiftUp,
              scheme: scheme,
            ),
            _CoachingSymbol(
              icon: Icons.keyboard_double_arrow_down,
              label: l.coachingShiftDown,
              active: hint == DrivingCoachingHint.shiftDown,
              scheme: scheme,
            ),
            _CoachingSymbol(
              icon: Icons.eco,
              label: l.coachingEasePedal,
              active: hint == DrivingCoachingHint.easePedal,
              scheme: scheme,
            ),
          ];

    return Card(
      key: const Key('minimal_drive_summary_card'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              headlineLabel,
              key: const Key('minimal_drive_headline_label'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              headline,
              key: const Key('minimal_drive_instant_value'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            // #3431 — the trip running average on its own honest row,
            // so "instant" and "average" are never conflated again.
            if (avgText != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.minimalDriveTripAverage,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    avgText,
                    key: const Key('minimal_drive_trip_avg_value'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            // #3845 — always-on driving-behaviour band. Present on every
            // trajet including GPS-only ones (it is scored from the
            // speed series, not from a fuel-rate PID), and absent only
            // while the tracker is still filling its first window.
            if (reading?.liveDrivingScore != null) ...[
              const SizedBox(height: 8),
              _BehaviourBand(score: reading!.liveDrivingScore!),
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

class _CoachingSymbol extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final ColorScheme scheme;

  const _CoachingSymbol({
    required this.icon,
    required this.label,
    required this.active,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.4);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          // #2903 — shrink-to-fit so the cue label never overflows its
          // (now Expanded) cell at a large text scale / narrow pane.
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The live driving-behaviour band (#3845): one traffic-light colour
/// for the rolling 0..100 score, with the band name and the number
/// beside it.
///
/// Colour is never the only channel — the band name and score are both
/// rendered, so the widget still reads correctly for a colour-blind
/// driver and in a screen-reader announcement.
class _BehaviourBand extends StatelessWidget {
  const _BehaviourBand({required this.score});

  final int score;

  /// The four bands the user asked for, in order good → bad. Fixed
  /// traffic-light colours rather than scheme roles: "green / yellow /
  /// orange / red" is the shared driving vocabulary here, and a theme
  /// that maps `tertiary` to something else would break the reading.
  static Color _colorFor(DrivingStyleClass c) {
    switch (c) {
      case DrivingStyleClass.veryGood:
        return const Color(0xFF2E7D32); // green 800
      case DrivingStyleClass.good:
        return const Color(0xFFF9A825); // yellow 800
      case DrivingStyleClass.average:
        return const Color(0xFFEF6C00); // orange 800
      case DrivingStyleClass.bad:
        return const Color(0xFFC62828); // red 800
    }
  }

  static String _labelFor(AppLocalizations l, DrivingStyleClass c) {
    switch (c) {
      case DrivingStyleClass.veryGood:
        return l.drivingScoreClassVeryGood;
      case DrivingStyleClass.good:
        return l.drivingScoreClassGood;
      case DrivingStyleClass.average:
        return l.drivingScoreClassAverage;
      case DrivingStyleClass.bad:
        return l.drivingScoreClassBad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final styleClass = DrivingStyleClass.fromScore(score);
    final color = _colorFor(styleClass);
    final bandLabel = _labelFor(l, styleClass);

    return Semantics(
      key: const Key('minimal_drive_behaviour_band'),
      label: '${l.minimalDriveBehaviour}: $bandLabel',
      value: '$score',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l.minimalDriveBehaviour,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                bandLabel,
                key: const Key('minimal_drive_behaviour_label'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                // The 0..100 score through the locale-aware formatter —
                // a bare '$score' would render Western digits on locales
                // that use their own numerals.
                UnitFormatter.formatDecimal(score.toDouble(),
                    fractionDigits: 0),
                key: const Key('minimal_drive_behaviour_score'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // The bar fills in proportion to the score, so the colour and
          // the length say the same thing twice.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
