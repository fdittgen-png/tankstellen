// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../driving_score/api.dart';
import '../../../domain/cold_start_baselines.dart';
import '../../../domain/situation_classifier.dart';
import '../../../providers/trip_recording_provider.dart';
import '../trip_recording_banner_palette.dart';

/// Localized label for a [DrivingSituation] (#2515 — one switch, shared by
/// every surface that names the driving situation).
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

/// The band-coloured header of the RECORDING FORM (#3959).
///
/// The ambient "how efficiently am I driving" signal used to be a strip
/// above **every** screen (`TripRecordingBanner`), which cost ~40 dp of
/// each screen for the whole drive. It lives here instead: on the form the
/// driver is actually looking at, and — unchanged — as the background
/// colour of the Picture-in-Picture tile when the app is reduced.
///
/// It carries only what the form does not already say: the driving
/// situation (or "Trip paused"), the live coaching cue, and the delta
/// against that situation's baseline. Distance, elapsed and the live
/// consumption are the hero's and the metric grid's job — repeating them
/// here is what made the old strip a second, competing dashboard.
///
/// Colour is never the only channel: the situation label and the signed
/// delta both render, so the header reads correctly for a colour-blind
/// driver and in a screen-reader announcement.
class LiveBandHeader extends ConsumerWidget {
  const LiveBandHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #3613 — the recording state emits at ~4 Hz; select only what this
    // header renders so an unchanged band never rebuilds it.
    final view = ref.watch(tripRecordingProvider.select((s) => (
          phase: s.phase,
          situation: s.situation,
          band: s.band,
          liveDeltaFraction: s.liveDeltaFraction,
          live: s.live,
          isActive: s.isActive,
        )));
    if (!view.isActive) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final palette = bandPalette(context, view.band, view.phase);
    final paused = view.phase == TripRecordingPhase.paused;
    final label =
        paused ? l.tripBannerPaused : situationDisplayLabel(view.situation, l);
    final icon = paused
        ? Icons.pause_circle_filled
        : _iconFor(view.situation, view.band);
    final hint = (view.live == null || paused)
        ? null
        : coachingHint(view.live!, situation: view.situation, band: view.band);
    final delta = paused ? null : view.liveDeltaFraction;

    return Semantics(
      key: const Key('liveBandHeader'),
      liveRegion: true,
      label: [
        label,
        if (delta != null) _fmtDelta(delta),
      ].join(', '),
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: AppRadius.lg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: palette.foreground),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hint != null) ...[
                CoachingChip(hint: hint, foreground: palette.foreground),
                const SizedBox(width: Spacing.md),
              ],
              if (delta != null)
                Text(
                  _fmtDelta(delta),
                  style: TextStyle(
                    color: palette.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The glyph the band wears: the situation when it has one of its own,
  /// else the consumption band's own eco / neutral / burning icon.
  static IconData _iconFor(DrivingSituation s, ConsumptionBand b) {
    if (s == DrivingSituation.hardAccel) return Icons.local_fire_department;
    if (s == DrivingSituation.fuelCutCoast) return Icons.eco;
    if (s == DrivingSituation.idle) return Icons.hourglass_bottom;
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

  /// `+12%` / `-8%` / `±0%` against the situation's baseline.
  static String _fmtDelta(double d) {
    final pct = (d * 100).round();
    final sign = pct > 0 ? '+' : (pct < 0 ? '' : '±');
    return '$sign$pct%';
  }
}
