// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/approach_detector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approach/providers/effective_approach_state_provider.dart';
import '../../../approach/providers/nearest_station_radar_provider.dart';
import '../../../profile/providers/effective_fuel_type_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../search/providers/radar_search_provider.dart';
import '../../../search/providers/search_filters_provider.dart';
import '../../../obd2/api.dart';
import '../../domain/driving_coaching.dart';
import '../../domain/situation_classifier.dart';
import '../../providers/live_activity_provider.dart';
import '../../providers/pip_mode_provider.dart';
import '../../providers/trip_recording_provider.dart';
import 'gps_degraded_banner.dart';
import 'trip_recording_banner_content.dart';
import 'trip_recording_banner_palette.dart';
import 'trip_recording_pip_price_layout.dart';
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

    // #3170 — arm the iOS Live Activity sync here, where every screen
    // passes through (MaterialApp.builder), so the lock-screen/Dynamic
    // Island surface tracks the trip no matter which route was visible
    // when the user switched to their navigation app. Inert no-op off
    // iOS (the provider subscribes to nothing); guarded like the PiP
    // watches below so a harness without the full graph never crashes.
    try {
      ref.watch(liveActivitySyncProvider);
    } on Object {
      // best-effort surface — never let it take the banner down
    }

    // #1977 — once the OS shrinks the app into a Picture-in-Picture
    // tile, render ONLY the compact trip strip. This wrapper sits above
    // every screen, so collapsing here strips the shell chrome (the
    // bottom nav bar, app bars) out of the tile no matter which route
    // was visible when PiP fired.
    if (ref.watch(pipModeProvider)) {
      // #2163 — guard every watch: under tests that don't bootstrap
      // Hive the chain raises and would crash the PiP tile.
      ApproachState? approach;
      var fuel = FuelType.e10;
      // #2661 — the nearest priced radar station off the polling fallback,
      // plus the radar radius (for the proximity bar). Both guarded; a raise
      // leaves them null so the tile degrades to the consumption layout.
      Station? radarStation;
      double? radiusMeters;
      try {
        approach = ref.watch(effectiveApproachStateProvider);
      } on Object {
        /* fall back to null */
      }
      try {
        fuel = ref.watch(effectiveFuelTypeProvider);
      } on Object {
        /* keep e10 */
      }
      try {
        radarStation = ref.watch(nearestStationRadarProvider).value;
      } on Object {
        /* no radar station */
      }
      try {
        final p = ref.watch(activeProfileProvider);
        if (p != null) radiusMeters = p.approachRadiusKm * 1000.0;
      } on Object {
        /* no radius */
      }
      // #2677 — guarded fallback for the on-search Fuel Station Radar PiP
      // (no trip required): when the trip radar found nothing AND the
      // on-search radar is active, feed its nearest priced station into the
      // SAME price layout (the search radius is the proximity bar's radius).
      // Reuses TripRecordingPipPriceLayout + fuelStationRadarPalette unchanged
      // — no parallel PiP host.
      var searchRadarActive = false;
      if (radarStation == null) {
        try {
          if (ref.watch(radarSearchProvider).active) {
            searchRadarActive = true;
            radarStation = ref.watch(radarSearchNearestProvider);
            radiusMeters = ref.watch(searchRadiusProvider) * 1000.0;
          }
        } on Object {
          /* no on-search radar */
        }
      }
      // #2964 — tapping the floating PiP tile body restores the full app.
      // Built here where `ref` is in scope; the controller is the app-wide
      // singleton (PiP is Activity-bound) and bringToFront is an inert no-op
      // off Android, so the tile stays safe on every other platform.
      void onBodyTap() {
        try {
          unawaited(ref.read(pipControllerProvider).bringToFront());
        } on Object {
          // Best-effort: a failed reorder just leaves the tile in PiP.
        }
      }

      return _pipView(
        context,
        state,
        approachState: approach,
        fuelType: fuel,
        radarStation: radarStation,
        radiusMeters: radiusMeters,
        searchRadarActive: searchRadarActive,
        onBodyTap: onBodyTap,
      );
    }

    // #3529 (Epic #3527) — the app-wide link supervisor. Watching it here
    // keeps the keepAlive provider alive (so the supervisor subscribes to
    // the proactive link-drop signal) and surfaces the ambient
    // "reconnecting…" dot ABOVE every screen, decoupled from any live
    // trip — a drop while idle still recovers. There is no terminal
    // "tap to retry" state anymore: the supervisor's capped-backoff loop
    // retries until user stop or engine-off.
    final reconnectState = ref.watch(obd2ReconnectProvider);
    final reconnectVisible = reconnectState == Obd2LinkState.reconnecting;

    // When no trip is active: show a thin strip carrying only the
    // OBD2 status dot — and only when there's an adapter remembered
    // (otherwise the dot itself collapses to zero size). First-run
    // users with nothing configured see no chrome at all.
    if (!state.isActive) {
      // #3019/#3505 — a drop while idle still surfaces its (ambient dot /
      // terminal strip) chrome even when no paired-adapter indicator shows.
      if (!obd2.hasVisibleIndicator && !reconnectVisible) return child;
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
          // #3529 — the reconnect loop is ambient-only now (the pulsing
          // status dot above); the terminal "tap to retry" strip and the
          // wedge-recovery hint died with their subsystems (#3527: the
          // supervisor has no dead-end states to advertise).
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
                      ref.read(routerProvider).push(RoutePaths.tripRecording),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: TripRecordingBannerContent(
                      state: state,
                      palette: bandColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // #3545 — the drop/degraded status floats OVER the content instead
        // of being inserted as a row: every appear/disappear used to reflow
        // the whole screen below (forms visibly jumped on each reconnect
        // cycle). Both pills render zero-size when idle and are mutually
        // exclusive (#797 pausedDueToDrop vs #2565 degradedGpsOnly), and
        // only the pill itself claims hits — taps beside it fall through.
        Expanded(
          child: Stack(
            children: [
              child,
              const Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Obd2PauseBanner(),
                ),
              ),
              const Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GpsDegradedBanner(),
                ),
              ),
            ],
          ),
        ),
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
    required Station? radarStation,
    required double? radiusMeters,
    bool searchRadarActive = false,
    VoidCallback? onBodyTap,
  }) {
    if (!state.isActive) {
      // #2677 — the on-search Fuel Station Radar runs WITHOUT a trip. When it
      // owns the PiP tile and has a nearest priced station, render the SAME
      // price layout (no trip state needed — the layout is paint-only) instead
      // of the neutral panel. Reuses TripRecordingPipPriceLayout +
      // fuelStationRadarPalette unchanged.
      if (searchRadarActive && radarStation != null) {
        final palette = fuelStationRadarPalette(fuelType);
        return TripRecordingPipPriceLayout(
          station: radarStation,
          fuel: fuelType,
          backgroundColor: palette.background,
          foregroundColor: palette.foreground,
          distanceMeters: radarStation.dist > 0
              ? radarStation.dist * 1000.0
              : null,
          radiusMeters: radiusMeters,
          onBodyTap: onBodyTap,
        );
      }
      // A trip ended while the app sat in PiP — the OS restores the
      // full window momentarily; a neutral panel avoids flashing the
      // shell (and its nav bar) back into the tile in the meantime.
      return Material(color: Theme.of(context).colorScheme.surface);
    }
    // #2382 — when the tile leads with a fuel price (in-radius/leaving OR the
    // #2661 polling radar station) it adopts the FUEL TYPE's colour so it
    // matches the same hue the fuel wears everywhere else (price columns, map
    // markers). Outside any radar lead it keeps the driving-band palette.
    final inRadius =
        approachState is ApproachInRadius || approachState is ApproachLeaving;
    final leadsWithRadar = inRadius || radarStation != null;
    final palette = leadsWithRadar
        ? fuelStationRadarPalette(fuelType)
        : bandPalette(context, state.band, state.phase);
    return TripRecordingPipView(
      state: state,
      backgroundColor: palette.background,
      foregroundColor: palette.foreground,
      // #2163 — null outside any radius → PiP keeps the default layout.
      approachState: approachState,
      fuelType: fuelType,
      // #2661 — the polling radar station + its distance + the radar radius.
      radarStation: inRadius ? null : radarStation,
      radarDistanceMeters: radarStation != null && radarStation.dist > 0
          ? radarStation.dist * 1000.0
          : null,
      radiusMeters: radiusMeters,
      onBodyTap: onBodyTap,
    );
  }

  String _semanticsLabel(TripRecordingState state, AppLocalizations l) {
    if (state.phase == TripRecordingPhase.paused) {
      return l.tripBannerPaused;
    }
    final prefix = l.tripBannerRecording;
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
      parts.add(l.tripRecordingEstimatedInfo);
    }
    return parts.join(', ');
  }

  String _situationLabel(DrivingSituation s, AppLocalizations l) =>
      situationDisplayLabel(s, l);
}
