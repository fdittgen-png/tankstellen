// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../error/exceptions.dart';
import '../utils/geo_utils.dart';
import 'geolocator_wrapper.dart';

part 'location_service.g.dart';

@riverpod
LocationService locationService(Ref ref) {
  return LocationService(ref.watch(geolocatorWrapperProvider));
}

class LocationService {
  final GeolocatorWrapper _geolocator;

  LocationService(this._geolocator);

  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // English diagnostic per exceptions.dart contract (#2316).
      // User-facing text is handled by ErrorLocalizer → ARB.
      throw const LocationException(
        message: 'Location services are disabled.',
      );
    }

    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // English diagnostic per exceptions.dart contract (#2316).
        throw const LocationException(
          message: 'Location permission denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        message: 'Location permission permanently denied.',
      );
    }

    final position = await _geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // #2872 — a degenerate fix ((0,0), a one-axis-unacquired (lat,0), or a
    // NaN/Inf axis) is NOT a real position: it slips past every downstream
    // station/distance guard and poisons the route origin so OSRM routes
    // from the Gulf of Guinea and the route map centres in the Sahara.
    // Reject it at this single acquisition chokepoint so both the route
    // start (RouteInput._useGpsForStart) and searchByGps surface the
    // existing "could not determine your location" error instead of
    // storing/using it. English diagnostic per the exceptions.dart
    // contract — ErrorLocalizer maps LocationException → errorLocation.
    if (!isUsableCoord(position.latitude, position.longitude)) {
      throw const LocationException(
        message: 'Degenerate GPS fix (unacquired or null-island coordinate).',
      );
    }

    return position;
  }

  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return _geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
