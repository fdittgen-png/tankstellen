// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/services/approach_detector.dart';
import '../../consumption/providers/trip_recording_provider.dart';
import '../../profile/data/models/user_profile.dart' as profile_model;
import '../../profile/providers/approach_overlay_enabled_provider.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../search/domain/entities/station.dart';
import 'fuel_station_radar_provider.dart';

part 'approach_state_provider.g.dart';

/// Real-data approach detector (#2163, #2283) — wires [ApproachDetector] to
/// the live trip-recording flow, backed by the Fuel Station Radar.
///
/// Active only while a trip is recording: cold-start cost (a GPS
/// subscription) is bounded to the window where the user is actually
/// driving. The detector is recreated whenever the user edits their profile's
/// approach config or fuel type (per ADR 0011 — the detector itself does not
/// watch the profile).
///
/// ### Data source (#2283)
///
/// The detector's `fetchStations` is delegated to [fuelStationRadarProvider]
/// instead of hitting the search chain on every poll. The radar serves the
/// **cached wide-area corridor** locations (zero network while inside a
/// covered tile) and JIT-fetches the price for only the imminent station(s).
/// The detector's geofence (radius + heading lock) runs locally against that
/// cached set — so the detector's public API and state machine are unchanged;
/// only the bytes flowing into `fetchStations` moved off the per-poll network
/// path onto the corridor cache.
///
/// The UI consumes [effectiveApproachStateProvider] rather than this stream
/// directly, so the in-app simulator (debug button on the trip-recording
/// screen) can override the real signal for testing.
@Riverpod(keepAlive: true)
Stream<ApproachState> approachState(Ref ref) {
  final tripState = ref.watch(tripRecordingProvider);
  final profile = ref.watch(activeProfileProvider);

  // #2382 — gate the live detector behind the approach-overlay feature
  // flag (default-on for the Medium/Full use-modes). When off, the
  // detector never starts: no GPS subscription, no corridor polls. The
  // stream stays Idle so the PiP keeps its default L/100 km layout.
  final overlayEnabled = ref.watch(approachOverlayEnabledProvider);

  if (!overlayEnabled || !tripState.isActive || profile == null) {
    return Stream.value(const ApproachIdle());
  }

  final fuel = ref.watch(effectiveFuelTypeProvider);
  final geo = ref.read(geolocatorWrapperProvider);
  final radar = ref.read(fuelStationRadarProvider);

  final config = ApproachDetectorConfig(
    radiusMeters: (profile.approachRadiusKm * 1000).round(),
    priceMode: _mapPriceMode(profile.approachPriceMode),
    minPollSeconds: profile.approachMinPollSeconds.clamp(1, 30),
    fuelTypeApiValue: fuel.apiValue,
  );

  final detector = ApproachDetector(
    // #2646 — consume the SHARED, refcounted broadcast position source so the
    // detector receives the SAME fixes as the GPS-only recorder. Before this,
    // both opened their own `getPositionStream`; geolocator's single platform
    // EventChannel let the recorder starve the detector in GPS-only mode, so
    // it never left ApproachIdle and the radar / swipe stayed dead. The
    // detector already treats its input as a hot/late-join stream — the shared
    // source replays the latest fix to late joiners, so no detector change.
    gpsStream: geo.sharedPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ),
    fetchStations: (lat, lng, radiusKm, fuelTypeApiValue) async {
      try {
        // Cached corridor locations (tier-1) + JIT price for the imminent
        // station(s) (tier-3). Zero network when the tile is already cached
        // and no imminent station needs a price refresh.
        return await radar.fetchStations(
          lat,
          lng,
          radiusKm,
          fuelTypeApiValue,
        );
      } on Object catch (e, st) {
        // #2297 — the detector treats this as "no stations in radius" and
        // keeps polling (the next iteration retries), but a broken API
        // key / country outage must leave a breadcrumb so it is
        // distinguishable from a genuine "nothing nearby" in telemetry.
        unawaited(errorLogger.log(ErrorLayer.services, e, st, context: const {
          'where': 'approachState.fetchStations',
        }));
        return const <Station>[];
      }
    },
    config: config,
  );

  ref.onDispose(detector.dispose);
  return detector.state;
}

/// Map the profile-model price-mode enum onto the detector's own enum.
/// They carry the same values but the two layers stayed independent on
/// purpose — the profile model is part of the persisted Hive schema,
/// the detector enum is part of the core state-machine contract.
ApproachPriceMode _mapPriceMode(profile_model.ApproachPriceMode m) {
  switch (m) {
    case profile_model.ApproachPriceMode.nearest:
      return ApproachPriceMode.nearest;
    case profile_model.ApproachPriceMode.cheapestInRadius:
      return ApproachPriceMode.cheapestInRadius;
  }
}
