// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/services/approach_detector.dart';
import '../../../core/services/service_providers.dart';
import '../../consumption/providers/trip_recording_provider.dart';
import '../../profile/data/models/user_profile.dart' as profile_model;
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';

part 'approach_state_provider.g.dart';

/// Real-data approach detector (#2163) — wires [ApproachDetector] to
/// the live trip-recording flow.
///
/// Active only while a trip is recording: cold-start cost (a GPS
/// subscription + periodic search-chain calls) is bounded to the
/// window where the user is actually driving. The detector is
/// recreated whenever the user edits their profile's approach config
/// or fuel type (per ADR 0011 — the detector itself does not watch
/// the profile).
///
/// The UI consumes [effectiveApproachStateProvider] rather than this
/// stream directly, so the in-app simulator (debug button on the
/// trip-recording screen) can override the real signal for testing.
@Riverpod(keepAlive: true)
Stream<ApproachState> approachState(Ref ref) {
  final tripState = ref.watch(tripRecordingProvider);
  final profile = ref.watch(activeProfileProvider);

  if (!tripState.isActive || profile == null) {
    return Stream.value(const ApproachIdle());
  }

  final fuel = ref.watch(effectiveFuelTypeProvider);
  final geo = ref.read(geolocatorWrapperProvider);
  final svc = ref.read(stationServiceProvider);

  final config = ApproachDetectorConfig(
    radiusMeters: (profile.approachRadiusKm * 1000).round(),
    priceMode: _mapPriceMode(profile.approachPriceMode),
    minPollSeconds: profile.approachMinPollSeconds.clamp(1, 30),
    fuelTypeApiValue: fuel.apiValue,
  );

  final detector = ApproachDetector(
    gpsStream: geo.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ),
    fetchStations: (lat, lng, radiusKm, fuelTypeApiValue) async {
      try {
        final result = await svc.searchStations(
          SearchParams(
            lat: lat,
            lng: lng,
            radiusKm: radiusKm,
            fuelType: FuelType.fromString(fuelTypeApiValue),
            sortBy: SortBy.distance,
          ),
        );
        return result.data;
      } on Object {
        // Swallow — the detector treats this as "no stations in
        // radius" and keeps polling. The next iteration retries.
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
