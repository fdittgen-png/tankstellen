// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/services/approach_detector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approach/providers/effective_approach_state_provider.dart';
import '../../../profile/providers/effective_fuel_type_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/cold_start_baselines.dart';
import '../../domain/driving_coaching.dart';
import '../../domain/situation_classifier.dart';
import '../../providers/obd2_connection_state_provider.dart';
import '../../providers/pip_mode_provider.dart';
import '../../providers/trip_recording_provider.dart';
import 'coaching_chip.dart';
import 'gps_degraded_banner.dart';
import 'obd2_pause_banner.dart';
import 'obd2_status_dot.dart';
import 'trip_recording_banner_palette.dart';
import 'trip_recording_pip_view.dart';

/// Persistent indicator of an active OBD2 trip (#726 + #768).
///
/// Zero-height when idle, so wrapping every screen in it is safe.
/// When a trip is active, the banner colour, icon, and label reflect
/// the current driving situation + consumption band, and the right
/// side shows the percentage delta vs the situation's baseline.
/// Tapping routes back to /trip-recording.
class TripRecordingBanner extends ConsumerWidget {
  final Widget child;

  const TripRecordingBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripRecordingProvider);
    final obd2 = ref.watch(obd2ConnectionStatusProvider);

    // #1977 — once the OS shrinks the app into a Picture-in-Picture
    // tile, render ONLY the compact trip strip. This wrapper sits above
    // every screen, so collapsing here strips the shell chrome (the
    // bottom nav bar, app bars) out of the tile no matter which route
    // was visible when PiP fired.
    if (ref.watch(pipModeProvider)) {
      // #2163 — guard both watches: under tests that don't bootstrap
      // Hive the chain raises and would crash the PiP tile.
      ApproachState? approach;
      var fuel = FuelType.e10;
      try { approach = ref.watch(effectiveApproachStateProvider); } on Object { /* fall back to null */ }
      try { fuel = ref.watch(effectiveFuelTypeProvider); } on Object { /* keep e10 */ }
      return _pipView(context, state, approachState: approach, fuelType: fuel);
    }

    // When no trip is active: show a thin strip carrying only the
    // OBD2 status dot — and only when there's an adapter remembered
    // (otherwise the dot itself collapses to zero size). First-run
    // users with nothing configured see no chrome at all.
    if (!state.isActive) {
      if (!obd2.hasVisibleIndicator) return child;
      return Column(
        children: [
          const SafeArea(
            bottom: false,
            child: SizedBox(
              height: 24,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Obd2StatusDot(),
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );
    }

    final bandColor = bandPalette(context, state.band, state.phase);
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Semantics(
          container: true,
          button: true,
          // liveRegion makes TalkBack re-read the label when the
          // band or situation changes — that's the whole point of
          // the ambient consumption signal (#767).
          liveRegion: true,
          label: _semanticsLabel(state, l),
          child: ExcludeSemantics(
            child: Material(
              color: bandColor.background,
              elevation: 2,
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  key: const Key('tripRecordingBanner'),
                  // #1987 — TripRecordingBanner is wrapped via
                  // MaterialApp.builder, so its context sits ABOVE the
                  // Router/Navigator subtree and `GoRouter.of(context)`
                  // fails. Navigate through the router instance from
                  // `routerProvider` instead — always resolvable, no
                  // context lookup — so the banner reliably reopens the
                  // active recording (the old context-lookup fell back
                  // to a snackbar naming the long-removed "Conso" tab).
                  onTap: () =>
                      ref.read(routerProvider).push('/trip-recording'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: _Content(state: state, palette: bandColor),
                  ),
                ),
              ),
            ),
          ),
        ),
        // #797 phase 2 — BT-drop pause banner. Zero-height unless the
        // provider is in pausedDueToDrop; self-watches its slice of
        // the state so the main banner above doesn't rebuild on
        // drop/resume transitions.
        const Obd2PauseBanner(),
        // #2565 — GPS-degraded banner (OBD2 dropped, GPS alive — still
        // recording). Mutually exclusive with the pause banner above;
        // zero-height unless the provider is in degradedGpsOnly.
        const GpsDegradedBanner(),
        Expanded(child: child),
      ],
    );
  }

  /// Full-bleed compact tile shown while the app is a PiP window
  /// (#1977 + #2068 — layout lives in [TripRecordingPipView]).
  Widget _pipView(
    BuildContext context,
    TripRecordingState state, {
    required ApproachState? approachState,
    required FuelType fuelType,
  }) {
    if (!state.isActive) {
      // A trip ended while the app sat in PiP — the OS restores the
      // full window momentarily; a neutral panel avoids flashing the
      // shell (and its nav bar) back into the tile in the meantime.
      return Material(color: Theme.of(context).colorScheme.surface);
    }
    // #2382 — in approach mode (in-radius or the leaving grace) the tile
    // adopts the FUEL TYPE's colour so it matches the same hue the fuel
    // wears everywhere else in the app (price columns, map markers).
    // Outside approach mode it keeps the driving-band palette.
    final inApproach =
        approachState is ApproachInRadius || approachState is ApproachLeaving;
    final palette = inApproach
        ? approachOverlayPalette(fuelType)
        : bandPalette(context, state.band, state.phase);
    return TripRecordingPipView(
      state: state,
      backgroundColor: palette.background,
      foregroundColor: palette.foreground,
      // #2163 — null outside any radius → PiP keeps the default layout.
      approachState: approachState,
      fuelType: fuelType,
    );
  }

  String _semanticsLabel(TripRecordingState state, AppLocalizations? l) {
    if (state.phase == TripRecordingPhase.paused) {
      return l?.tripBannerPaused ?? 'Trip paused';
    }
    final prefix = l?.tripBannerRecording ?? 'Recording trip';
    final situation = _situationLabel(state.situation, l);
    final parts = <String>[prefix, situation];
    final delta = state.liveDeltaFraction;
    if (delta != null) {
      final pct = (delta * 100).round();
      parts.add('${pct >= 0 ? '+' : ''}$pct%');
    }
    final distance = state.live?.distanceKmSoFar;
    if (distance != null) {
      parts.add('${distance.toStringAsFixed(1)} km');
    }
    // #2393 — when the strip is showing the GPS estimate (no measured
    // OBD2 value, estimate present) append the approximate-value
    // disclaimer so screen-reader users hear it. The banner content
    // sits under ExcludeSemantics, so the visible Tooltip can't surface
    // here — this label is the a11y channel for it.
    final live = state.live;
    if (live != null &&
        formatInstantConsumption(live) == null &&
        live.gpsEstimatedLPer100Km != null) {
      parts.add(l?.tripRecordingEstimatedInfo ??
          'Estimated value (~) — modelled from GPS speed, not measured.');
    }
    return parts.join(', ');
  }

  String _situationLabel(DrivingSituation s, AppLocalizations? l) =>
      situationDisplayLabel(s, l);
}

/// Localized label for a [DrivingSituation], shared by the banner's
/// accessibility label and its visible content strip (#2515 — extracted
/// from the two byte-identical switches so the new buckets only need to
/// be mapped once).
String situationDisplayLabel(DrivingSituation s, AppLocalizations? l) {
  switch (s) {
    case DrivingSituation.idle:
      return l?.situationIdle ?? 'Idle';
    case DrivingSituation.stopAndGo:
      return l?.situationStopAndGo ?? 'Stop & go';
    case DrivingSituation.urbanCruise:
      return l?.situationUrban ?? 'Urban';
    case DrivingSituation.highwayCruise:
      return l?.situationHighway ?? 'Highway';
    case DrivingSituation.deceleration:
      return l?.situationDecel ?? 'Decelerating';
    case DrivingSituation.climbingOrLoaded:
      return l?.situationClimbing ?? 'Climbing / loaded';
    // #2515 — the three new persistent buckets.
    case DrivingSituation.coldStartWarmup:
      return l?.situationColdStart ?? 'Cold start';
    case DrivingSituation.sustainedLoadOrTowing:
      return l?.situationSustainedLoad ?? 'Sustained load / towing';
    case DrivingSituation.partialThrottleDecel:
      return l?.situationPartialDecel ?? 'Coasting';
    case DrivingSituation.hardAccel:
      return l?.situationHardAccel ?? 'Hard accel';
    case DrivingSituation.fuelCutCoast:
      return l?.situationFuelCut ?? 'Fuel cut — coast';
  }
}

class _Content extends StatelessWidget {
  final TripRecordingState state;
  final BannerPalette palette;

  const _Content({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = state.live;
    final distance = live?.distanceKmSoFar;
    final elapsed = live?.elapsed;
    final paused = state.phase == TripRecordingPhase.paused;

    final fg = palette.foreground;
    final situationLabel =
        paused
            ? (l?.tripBannerPaused ?? 'Paused')
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
    final gpsEstimate =
        (live != null && !paused) ? live.gpsEstimatedLPer100Km : null;
    final measured =
        (live != null && !paused) ? formatInstantConsumption(live) : null;
    // #2393 — true only when the value shown is the GPS estimate (no
    // measured value, estimate present). Drives the approximate tooltip /
    // accessibility disclaimer; the OBD2-measured value never carries it.
    final isEstimate = measured == null && gpsEstimate != null;
    final instantConsumption = measured ??
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
              message: l?.tripRecordingEstimatedInfo ??
                  'Estimated value (~) — modelled from GPS speed, '
                      'not measured.',
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

