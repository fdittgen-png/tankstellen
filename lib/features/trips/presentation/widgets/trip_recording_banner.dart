// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/consumption_unit.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/services/approach_detector.dart';
import '../../../approach/providers/effective_approach_state_provider.dart';
import '../../../approach/providers/nearest_station_radar_provider.dart';
import '../../../profile/providers/effective_fuel_type_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../search/providers/radar_search_provider.dart';
import '../../../search/providers/search_filters_provider.dart';
import '../../../obd2/api.dart';
import '../../providers/live_activity_provider.dart';
import '../../providers/vehicle_odometer_tracker.dart';
import 'parked_prompt_pill.dart';
import '../../../fill_ups/api.dart';
import '../../providers/pip_mode_provider.dart';
import '../../providers/trip_recording_provider.dart';
import 'gps_degraded_banner.dart';
import 'trip_recording_banner_palette.dart';
import 'trip_recording_pip_price_layout.dart';
import 'trip_recording_pip_view.dart';

/// The app-wide recording wrapper (#726 + #768, emptied of chrome by
/// #3959).
///
/// It is mounted through `MaterialApp.builder`, so it sits above every
/// screen. It claims **no layout height**: it arms the always-on recording
/// side-effects (iOS Live Activity sync, the OBD2 fuel-level and odometer
/// trackers), owns the Picture-in-Picture branch — the reduced tile IS this
/// widget — floats the transient pause / GPS-degraded / parked pills over
/// the content, and shows the ambient OBD2 status dot on a 24 dp strip when
/// NO trip is running.
///
/// #3959 — the band-coloured efficiency strip it used to draw during a
/// recording is gone: that signal is the recording form's own
/// [LiveBandHeader] and the PiP tile's background colour.
class TripRecordingBanner extends ConsumerWidget {
  final Widget child;

  const TripRecordingBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #3613 — this wrapper sits above EVERY screen and the recording
    // state emits at ~1 Hz, so watch only the fields the strip renders
    // (phase, situation, band, liveDeltaFraction, live reading); the
    // non-rendered fields each have their own widget and no longer
    // rebuild the whole app subtree (the record's == is structural).
    // The PiP branch below re-watches the full state: the PiP tile is
    // the ONLY thing on screen there, so selecting buys nothing.
    final view = ref.watch(tripRecordingProvider.select((s) => (
          phase: s.phase,
          live: s.live,
          situation: s.situation,
          band: s.band,
          liveDeltaFraction: s.liveDeltaFraction,
        )));
    // Re-assembled projection carrying exactly the rendered fields —
    // keeps TripRecordingBannerContent/_semanticsLabel signatures (and
    // behaviour) identical.
    final state = TripRecordingState(
      phase: view.phase,
      live: view.live,
      situation: view.situation,
      band: view.band,
      liveDeltaFraction: view.liveDeltaFraction,
    );
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
    // #3647 — arm the OBD2 fuel-level tracker the same way: it persists
    // the live tank reading per vehicle so the Carburant card can show
    // the sensor truth BETWEEN drives (tank level v2 — fills anchor,
    // the sensor tracks, no trip simulation). Watching from the banner
    // keeps it alive for backgrounded recordings on every route.
    try {
      ref.watch(obd2FuelLevelTrackerProvider);
      ref.watch(vehicleOdometerTrackerProvider); // #3877
    } on Object {
      // best-effort — a harness without the recording graph skips it
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
        // #3613 — the tile is the whole UI in PiP: hand it the full state.
        ref.watch(tripRecordingProvider),
        approachState: approach,
        fuelType: fuel,
        radarStation: radarStation,
        radiusMeters: radiusMeters,
        searchRadarActive: searchRadarActive,
        onBodyTap: onBodyTap,
        unit: ref.watch(consumptionDisplaySettingProvider).unit, // #3883
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

    // #3959 — a RECORDING claims no chrome above the app. The ambient
    // efficiency signal the strip used to carry is now the recording
    // form's own band header ([LiveBandHeader]) and, when the app is
    // reduced, the PiP tile's background — both `bandPalette`, so the
    // colour vocabulary is unchanged; what is gone is ~40 dp taken from
    // every screen for the length of the drive. Getting back into the
    // running trip is the Trajets FAB ("Resume recording") and the
    // foreground-service notification, both of which already do it.
    //
    // The floating pills stay: they are transient warnings ABOUT the
    // recording, they claim no layout height, and only the pill itself
    // takes hits.
    return Stack(
      children: [
        child,
        // #3545 — the drop/degraded status floats OVER the content instead
        // of being inserted as a row: every appear/disappear used to reflow
        // the whole screen below (forms visibly jumped on each reconnect
        // cycle). Both pills render zero-size when idle and are mutually
        // exclusive (#797 pausedDueToDrop vs #2565 degradedGpsOnly).
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GpsDegradedBanner(),
            ParkedPromptPill(), // #3862 — stacks under the engine pill
          ]),
        ),
      ],
    );
  }

  /// Full-bleed PiP tile (#1977/#2068 — layout in [TripRecordingPipView]).
  Widget _pipView(
    BuildContext context,
    TripRecordingState state, {
    required ApproachState? approachState,
    required FuelType fuelType,
    required Station? radarStation,
    required double? radiusMeters,
    bool searchRadarActive = false,
    VoidCallback? onBodyTap,
    ConsumptionUnit unit = ConsumptionUnit.lPer100Km, // #3883
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
      unit: unit, // #3883
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

}
