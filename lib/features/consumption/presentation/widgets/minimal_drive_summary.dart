// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_coaching.dart';
import '../../providers/trip_recording_provider.dart';
import 'broken_map_widgets.dart';

/// Compact live-drive summary card (#2026) — one big instantaneous
/// L/100 km figure plus three permanently-visible coaching symbols
/// that light up when the matching [DrivingCoachingHint] fires.
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
    final liveAvg = reading?.liveAvgLPer100Km;

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
    final headline = liveAvg == null
        ? '—'
        : UnitFormatter.formatConsumption(liveAvg, isEv: false);

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
              l.minimalDriveInstantConsumption,
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
