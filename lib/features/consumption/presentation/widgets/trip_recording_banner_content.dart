// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/cold_start_baselines.dart';
import '../../domain/driving_coaching.dart';
import '../../domain/situation_classifier.dart';
import '../../providers/trip_recording_provider.dart';
import 'coaching_chip.dart';
import 'trip_recording_banner_palette.dart';

/// Localized label for a [DrivingSituation], shared by the banner's
/// accessibility label and its visible content strip (#2515 — extracted
/// from the two byte-identical switches so the new buckets only need to
/// be mapped once).
String situationDisplayLabel(DrivingSituation s, AppLocalizations l) {
  switch (s) {
    case DrivingSituation.idle:
      return l.situationIdle;
    case DrivingSituation.stopAndGo:
      return l.situationStopAndGo;
    case DrivingSituation.urbanCruise:
      return l.situationUrban;
    case DrivingSituation.highwayCruise:
      return l.situationHighway;
    case DrivingSituation.deceleration:
      return l.situationDecel;
    case DrivingSituation.climbingOrLoaded:
      return l.situationClimbing;
    // #2515 — the three new persistent buckets.
    case DrivingSituation.coldStartWarmup:
      return l.situationColdStart;
    case DrivingSituation.sustainedLoadOrTowing:
      return l.situationSustainedLoad;
    case DrivingSituation.partialThrottleDecel:
      return l.situationPartialDecel;
    case DrivingSituation.hardAccel:
      return l.situationHardAccel;
    case DrivingSituation.fuelCutCoast:
      return l.situationFuelCut;
  }
}

/// The visible content row of the active-trip banner strip (the
/// situation icon + label, an optional coaching chip + instantaneous
/// consumption, the delta, distance, elapsed, and the tap chevron).
///
/// Extracted from `trip_recording_banner.dart` (#2661) to keep that file
/// under the 400-line cap once the PiP gained the radar price + km plumbing.
class TripRecordingBannerContent extends StatelessWidget {
  final TripRecordingState state;
  final BannerPalette palette;

  const TripRecordingBannerContent({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = state.live;
    final distance = live?.distanceKmSoFar;
    final elapsed = live?.elapsed;
    final paused = state.phase == TripRecordingPhase.paused;

    final fg = palette.foreground;
    final situationLabel = paused
        ? (l.tripBannerPaused)
        : situationDisplayLabel(state.situation, l);
    final bandIcon = paused
        ? Icons.pause_circle_filled
        : _iconFor(state.situation, state.band);

    // #2007 — instantaneous L/100 km (L/h at idle) + a conservative
    // eco-coaching chip surfaced from the live reading. Both pieces
    // are silent when the data isn't available so the strip degrades
    // gracefully on cars without a fuel-rate PID.
    //
    // #2390 — on a GPS-only trajet there's no OBD2 fuel rate, so
    // `formatInstantConsumption` returns null; fall back to the live
    // physics estimate rendered as `~X.X L/100` (reusing the OBD2 unit
    // token, leading `~` flagging it an estimate per ADR 0012). The OBD2
    // measured path stays tilde-free; a null estimate (warm-up / OBD2
    // trip) leaves the slot silent as before.
    final gpsEstimate = (live != null && !paused)
        ? live.gpsEstimatedLPer100Km
        : null;
    final measured = (live != null && !paused)
        ? formatInstantConsumption(live)
        : null;
    // #2393 — true only when the value shown is the GPS estimate (no
    // measured value, estimate present). Drives the approximate tooltip /
    // accessibility disclaimer; the OBD2-measured value never carries it.
    final isEstimate = measured == null && gpsEstimate != null;
    final instantConsumption =
        measured ??
        (isEstimate ? '~${gpsEstimate.toStringAsFixed(1)} L/100' : null);
    final coachingHintValue = (live != null && !paused)
        ? coachingHint(live, situation: state.situation, band: state.band)
        : null;

    return Row(
      children: [
        Icon(bandIcon, size: 18, color: fg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            situationLabel,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (coachingHintValue != null) ...[
          CoachingChip(hint: coachingHintValue, foreground: fg),
          const SizedBox(width: 8),
        ],
        if (instantConsumption != null) ...[
          // #2393 — the GPS estimate carries a long-press tooltip
          // explaining the `~` means a modelled (not measured) value;
          // the OBD2-measured figure renders bare. The same disclaimer
          // is folded into the banner's outer accessibility label
          // (_semanticsLabel) since this content sits under
          // ExcludeSemantics.
          if (isEstimate)
            Tooltip(
              message: l.tripRecordingEstimatedInfo,
              child: Text(
                instantConsumption,
                style: TextStyle(
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            )
          else
            Text(
              instantConsumption,
              style: TextStyle(
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(width: 8),
        ],
        if (state.liveDeltaFraction != null && !paused) ...[
          Text(
            _fmtDelta(state.liveDeltaFraction!),
            style: TextStyle(
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (distance != null)
          Text(
            '${distance.toStringAsFixed(1)} km',
            style: TextStyle(
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(width: 8),
        if (elapsed != null)
          Text(
            _fmtElapsed(elapsed),
            style: TextStyle(
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        // #1237 — chevron makes the banner look tappable. The InkWell
        // already routes to /trip-recording, but without an affordance
        // users read the row as decorative AppBar chrome.
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, size: 18, color: fg),
      ],
    );
  }

  IconData _iconFor(DrivingSituation s, ConsumptionBand b) {
    if (s == DrivingSituation.hardAccel) return Icons.local_fire_department;
    if (s == DrivingSituation.fuelCutCoast) return Icons.eco;
    if (s == DrivingSituation.idle) return Icons.hourglass_bottom;
    // #2515 — a cold engine running rich gets the warm-up icon; the
    // other two new buckets fall through to the band-driven icon below.
    if (s == DrivingSituation.coldStartWarmup) return Icons.ac_unit;
    switch (b) {
      case ConsumptionBand.eco:
        return Icons.eco;
      case ConsumptionBand.heavy:
      case ConsumptionBand.veryHeavy:
        return Icons.local_fire_department;
      case ConsumptionBand.transient:
      case ConsumptionBand.normal:
        return Icons.fiber_manual_record;
    }
  }

  String _fmtDelta(double d) {
    final pct = (d * 100).round();
    final sign = pct > 0 ? '+' : (pct < 0 ? '' : '±');
    return '$sign$pct%';
  }

  static String _fmtElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}
