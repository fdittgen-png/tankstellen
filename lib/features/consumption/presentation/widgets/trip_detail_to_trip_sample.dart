// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/trip_recorder.dart';
import 'trip_detail_charts.dart';

/// Convert a presentation-layer [TripDetailSample] into the domain
/// [TripSample] the analyzer / score / GPS features consume. Extracted
/// from `trip_detail_body.dart` (#2697 P3) to keep that body under its
/// 400-line guard.
///
/// #2692 C4-G — rpm threads through nullable (NOT `?? 0`): a GPS-only
/// sample stays rpm null so the source-aware score re-weight + the
/// GPS-efficiency card fire instead of seeing a fabricated 0.
TripSample tripDetailToTripSample(TripDetailSample s) => TripSample(
      timestamp: s.timestamp,
      speedKmh: s.speedKmh,
      rpm: s.rpm,
      fuelRateLPerHour: s.fuelRateLPerHour,
      // #2460 — carry the persisted driver-intent + mixture signals so the
      // canonical score computes the full-throttle, pedal-velocity,
      // smoothness, and λ-enrichment terms (the old converter dropped them,
      // which is why the full-throttle penalty appeared dead).
      throttlePercent: s.throttlePercent,
      pedalPercent: s.pedalPercent,
      lambda: s.lambda,
      // #2790 — carry the geo/altitude signals so the recomputed GPS features
      // are not silently zeroed. Without these the climb-energy block sees no
      // altitude (→ 0 m/km despite a real climb) and distance falls back to
      // speed×dt instead of haversine. The forward converter (toDetailSample)
      // already preserves them; the reverse must too.
      latitude: s.latitude,
      longitude: s.longitude,
      altitudeM: s.altitudeM,
      // #2931 — carry coolant + fuel trims so the combustion-health
      // heuristic (`CombustionHealthRule`) can gate on a warm closed-loop
      // engine and read the sustained mixture trim. The reverse converter
      // dropped these, so the heuristic would have seen an always-cold
      // engine (warm gate never satisfied) on a real persisted trip.
      coolantTempC: s.coolantTempC,
      stft: s.stft,
      ltft: s.ltft,
    );
