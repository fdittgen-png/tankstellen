// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/trip_recorder.dart';

/// (De)serialise a single [TripSample] for the trip-history rolling log.
///
/// Extracted from `trip_history_repository.dart` (#2431) so the
/// repository stays under the 400-line guard once the #2431 estimated
/// fuel-rate key (`'fe'`) joined the per-sample schema.
///
/// Compact key names ('t','s','r','f','fe','th','el','ct','la','lo',
/// 'al','ha','be','ag') keep per-trip JSON small — a 39-min trip × 1 Hz
/// lands around 19 KB compressed at this density. The timestamp uses
/// millisecondsSinceEpoch so the JSON parses fast and round-trips
/// precisely. Every optional key is emitted only when its field is
/// non-null, so trips written before each key landed deserialise with
/// the field null.
Map<String, dynamic> sampleToJson(TripSample s) => {
      't': s.timestamp.millisecondsSinceEpoch,
      's': s.speedKmh,
      'r': s.rpm,
      if (s.fuelRateLPerHour != null) 'f': s.fuelRateLPerHour,
      // #2431 — GPS-physics *estimated* fuel rate (L/h). A distinct key
      // from 'f' so a measured value and an estimate are never confused
      // on reload; only present for OBD2/hybrid trips whose adapter+ECU
      // supported no fuel PID (every 'f' omitted whole-trip).
      if (s.estimatedFuelRateLPerHour != null)
        'fe': s.estimatedFuelRateLPerHour,
      if (s.throttlePercent != null) 'th': s.throttlePercent,
      if (s.engineLoadPercent != null) 'el': s.engineLoadPercent,
      if (s.coolantTempC != null) 'ct': s.coolantTempC,
      if (s.latitude != null) 'la': s.latitude,
      if (s.longitude != null) 'lo': s.longitude,
      if (s.altitudeM != null) 'al': s.altitudeM,
      if (s.hAccuracyM != null) 'ha': s.hAccuracyM,
      if (s.bearingDeg != null) 'be': s.bearingDeg,
      if (s.accelG != null) 'ag': s.accelG,
    };

TripSample sampleFromJson(Map<String, dynamic> j) => TripSample(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['t'] as num).toInt(),
      ),
      speedKmh: (j['s'] as num).toDouble(),
      rpm: (j['r'] as num).toDouble(),
      fuelRateLPerHour: (j['f'] as num?)?.toDouble(),
      // #2431 — missing 'fe' → null so legacy trips (and trips with a
      // real fuel signal, which never carry an estimate) round-trip clean.
      estimatedFuelRateLPerHour: (j['fe'] as num?)?.toDouble(),
      throttlePercent: (j['th'] as num?)?.toDouble(),
      engineLoadPercent: (j['el'] as num?)?.toDouble(),
      coolantTempC: (j['ct'] as num?)?.toDouble(),
      latitude: (j['la'] as num?)?.toDouble(),
      longitude: (j['lo'] as num?)?.toDouble(),
      altitudeM: (j['al'] as num?)?.toDouble(),
      hAccuracyM: (j['ha'] as num?)?.toDouble(),
      bearingDeg: (j['be'] as num?)?.toDouble(),
      accelG: (j['ag'] as num?)?.toDouble(),
    );
