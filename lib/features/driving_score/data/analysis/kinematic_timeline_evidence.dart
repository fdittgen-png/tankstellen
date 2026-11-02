// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../trips/api.dart';

/// Bounded retained-sample series for independent KPI inspection/calibration.
/// No coordinates or inferred driver verdict are added to the analysis export.
Map<String, Object?> kinematicTimelineEvidence(List<TripSample> samples) {
  const cap = 10000;
  final ordered = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return {
    'rowCap': cap,
    'omittedRows': ordered.length > cap ? ordered.length - cap : 0,
    'source': 'retainedTripSamples',
    'resampled': false,
    'limits':
        'Retained samples are not raw sensor polls and may contain held '
        'values. Individual speed-source and sensor-age stamps are unavailable '
        'on legacy samples. Raw OBD request times are in vehicleHealth.sensorTimeline.',
    'rows': [
      for (final s in ordered.take(cap))
        {
          'atEpochMs': s.timestamp.millisecondsSinceEpoch,
          'speedKmh': s.speedKmh,
          'hAccuracyM': s.hAccuracyM,
          'accelG': s.accelG,
          'altitudeM': s.altitudeM,
          'bearingDeg': s.bearingDeg,
          'rpm': s.rpm,
          'fuelRateLPerHour': s.fuelRateLPerHour,
          'fuelSource': s.fuelSource,
        },
    ],
  };
}
