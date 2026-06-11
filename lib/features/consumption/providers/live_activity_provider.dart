// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ui' as ui;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/services/approach_detector.dart';
import '../../../l10n/app_localizations.dart';
import '../../approach/providers/effective_approach_state_provider.dart';
import '../../approach/providers/nearest_station_radar_provider.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/station.dart';
import '../data/live_activity_controller.dart';
import '../data/live_activity_coordinator.dart';
import '../domain/live_activity_content.dart';
import 'trip_recording_provider.dart';

part 'live_activity_provider.g.dart';

/// The single app-wide [LiveActivityController] (#3170) — the channel
/// admits exactly one native counterpart, so one Dart binding mirrors
/// the [PipController] singleton convention.
@Riverpod(keepAlive: true)
LiveActivityController liveActivityController(Ref ref) =>
    LiveActivityController();

/// The single app-wide [LiveActivityCoordinator] — keepAlive so its
/// throttle state (last-sent content / timestamps) survives across
/// [LiveActivitySync] rebuilds, which happen on every recorder emit.
@Riverpod(keepAlive: true)
LiveActivityCoordinator liveActivityCoordinator(Ref ref) =>
    LiveActivityCoordinator(
      controller: ref.watch(liveActivityControllerProvider),
    );

/// Keeps the iOS Live Activity (lock screen + Dynamic Island, #3170) in
/// lock-step with the live trip/approach state — the iOS counterpart of
/// the Android PiP tile's data wiring in `TripRecordingBanner`.
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), so the sync runs no matter which route is
/// visible when the user backgrounds the app for their navigation app.
///
/// Watches the SAME sources the PiP tile renders from — the recorder
/// state, the effective approach state, the polling-radar fallback, the
/// effective fuel and the profile radius — builds one formatted
/// [LiveActivityContent] snapshot per emit and hands it to the
/// [LiveActivityCoordinator], which owns the start/update/end decision
/// and the ActivityKit cadence budget.
///
/// Every auxiliary watch is guarded exactly like the banner's PiP
/// watches (#2163): under a harness without the full graph the snapshot
/// degrades (no radar lead, default fuel) instead of crashing.
@Riverpod(keepAlive: true)
class LiveActivitySync extends _$LiveActivitySync {
  @override
  void build() {
    final coordinator = ref.watch(liveActivityCoordinatorProvider);
    // Off-iOS: subscribe to NOTHING — zero extra rebuild traffic on the
    // platforms that can't host a Live Activity.
    if (!coordinator.isSupported) return;

    final state = ref.watch(tripRecordingProvider);

    ApproachState? approach;
    Station? radarStation;
    var fuel = FuelType.e10;
    double? radiusMeters;
    try {
      approach = ref.watch(effectiveApproachStateProvider);
    } on Object {
      // fall back to null — consumption layout
    }
    try {
      fuel = ref.watch(effectiveFuelTypeProvider);
    } on Object {
      // keep e10
    }
    try {
      radarStation = ref.watch(nearestStationRadarProvider).value;
    } on Object {
      // no radar station
    }
    try {
      final p = ref.watch(activeProfileProvider);
      if (p != null) radiusMeters = p.approachRadiusKm * 1000.0;
    } on Object {
      // no radius — the closeness bar collapses
    }

    final content = buildLiveActivityContent(
      state: state,
      approach: approach,
      radarStation: radarStation,
      fuel: fuel,
      radiusMeters: radiusMeters,
      l: _l10n(),
      now: DateTime.now(),
    );
    unawaited(coordinator.apply(content));
  }

  /// Resolve [AppLocalizations] without a `BuildContext` (#2766 pattern
  /// — `lookupAppLocalizations` is a pure synchronous constructor).
  /// Guarded twice so a harness without the language graph degrades to
  /// English, then to the builder's literal fallbacks.
  AppLocalizations? _l10n() {
    String code;
    try {
      code = ref.read(activeLanguageProvider).code;
    } on Object {
      code = 'en';
    }
    try {
      return lookupAppLocalizations(ui.Locale(code));
    } on Object {
      try {
        return lookupAppLocalizations(const ui.Locale('en'));
      } on Object {
        return null;
      }
    }
  }
}
