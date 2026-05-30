// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/trip_recorder.dart';
import '../widgets/trip_detail_charts.dart';

/// Convert a domain-layer [TripSample] (persisted on
/// [TripHistoryEntry]) into the presentation-layer [TripDetailSample]
/// the trip-detail charts consume (#1040). Lives in its own file so
/// `trip_detail_screen.dart` stays under the 400-line guard.
TripDetailSample toDetailSample(TripSample s) => TripDetailSample(
      timestamp: s.timestamp,
      speedKmh: s.speedKmh,
      rpm: s.rpm,
      fuelRateLPerHour: s.fuelRateLPerHour,
      estimatedFuelRateLPerHour: s.estimatedFuelRateLPerHour,
      throttlePercent: s.throttlePercent,
      engineLoadPercent: s.engineLoadPercent,
      coolantTempC: s.coolantTempC,
      latitude: s.latitude,
      longitude: s.longitude,
      // #2461 — carry pedal / λ / altitude through so the charts and the
      // canonical driving-style score (#2460) see the persisted signals.
      pedalPercent: s.pedalPercent,
      lambda: s.lambda,
      altitudeM: s.altitudeM,
    );
