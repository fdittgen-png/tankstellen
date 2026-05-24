import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/cold_start_baselines.dart';
import '../../domain/driving_coaching.dart';
import '../../domain/situation_classifier.dart';
import '../../providers/obd2_connection_state_provider.dart';
import '../../providers/pip_mode_provider.dart';
import '../../providers/trip_recording_provider.dart';
import 'coaching_chip.dart';
import 'obd2_pause_banner.dart';
import 'obd2_status_dot.dart';

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
      return _pipView(context, state);
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

    final bandColor = _bandColor(context, state.band, state.phase);
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
        Expanded(child: child),
      ],
    );
  }

  /// Full-bleed compact tile shown while the app is a Picture-in-
  /// Picture window (#1977) — the band-coloured trip strip only, none
  /// of the shell chrome.
  Widget _pipView(BuildContext context, TripRecordingState state) {
    if (!state.isActive) {
      // A trip ended while the app sat in PiP — the OS restores the
      // full window momentarily; a neutral panel avoids flashing the
      // shell (and its nav bar) back into the tile in the meantime.
      return Material(color: Theme.of(context).colorScheme.surface);
    }
    final palette = _bandColor(context, state.band, state.phase);
    return Material(
      color: palette.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _Content(state: state, palette: palette),
          ),
        ),
      ),
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
    return parts.join(', ');
  }

  String _situationLabel(DrivingSituation s, AppLocalizations? l) {
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
      case DrivingSituation.hardAccel:
        return l?.situationHardAccel ?? 'Hard accel';
      case DrivingSituation.fuelCutCoast:
        return l?.situationFuelCut ?? 'Fuel cut — coast';
    }
  }

  _BannerPalette _bandColor(
    BuildContext context,
    ConsumptionBand band,
    TripRecordingPhase phase,
  ) {
    // Paused always wins — UI should reflect "not recording" over
    // any consumption signal from a stale reading.
    if (phase == TripRecordingPhase.paused) {
      return _BannerPalette(
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
        foreground: Theme.of(context).colorScheme.onSurface,
      );
    }
    switch (band) {
      case ConsumptionBand.eco:
        return _BannerPalette(
            background: DarkModeColors.success(context),
            foreground: Colors.white);
      case ConsumptionBand.normal:
        return _BannerPalette(
          background: Theme.of(context).colorScheme.primary,
          foreground: Theme.of(context).colorScheme.onPrimary,
        );
      case ConsumptionBand.heavy:
        return _BannerPalette(
            background: DarkModeColors.warning(context),
            foreground: Colors.black);
      case ConsumptionBand.veryHeavy:
        return _BannerPalette(
            background: DarkModeColors.error(context),
            foreground: Colors.white);
      case ConsumptionBand.transient:
        return _BannerPalette(
            background: Colors.teal.shade400, foreground: Colors.white);
    }
  }
}

class _BannerPalette {
  final Color background;
  final Color foreground;
  const _BannerPalette({required this.background, required this.foreground});
}

class _Content extends StatelessWidget {
  final TripRecordingState state;
  final _BannerPalette palette;

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
        paused ? (l?.tripBannerPaused ?? 'Paused') : _label(state.situation, l);
    final bandIcon = paused
        ? Icons.pause_circle_filled
        : _iconFor(state.situation, state.band);

    // #2007 — instantaneous L/100 km (L/h at idle) + a conservative
    // eco-coaching chip surfaced from the live reading. Both pieces
    // are silent when the data isn't available so the strip degrades
    // gracefully on cars without a fuel-rate PID.
    final instantConsumption =
        (live != null && !paused) ? formatInstantConsumption(live) : null;
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

  String _label(DrivingSituation s, AppLocalizations? l) {
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
      case DrivingSituation.hardAccel:
        return l?.situationHardAccel ?? 'Hard accel';
      case DrivingSituation.fuelCutCoast:
        return l?.situationFuelCut ?? 'Fuel cut — coast';
    }
  }

  IconData _iconFor(DrivingSituation s, ConsumptionBand b) {
    if (s == DrivingSituation.hardAccel) return Icons.local_fire_department;
    if (s == DrivingSituation.fuelCutCoast) return Icons.eco;
    if (s == DrivingSituation.idle) return Icons.hourglass_bottom;
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

