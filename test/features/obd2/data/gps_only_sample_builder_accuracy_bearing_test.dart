// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/degraded_gps_emitter.dart';
import 'package:tankstellen/features/obd2/data/gps_only_sample_builder.dart';
import 'package:tankstellen/features/obd2/data/trip_sample_buffer.dart';
import 'package:tankstellen/features/consumption/data/trip_sample_codec.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #2648 — the DEGRADED GPS-only path (OBD2 dropped mid-trip) used to drop
/// GPS horizontal accuracy + bearing along with the OBD2 path. The builder
/// + the [DegradedGpsEmitter] that drives it now carry them onto the
/// [TripSample] so a degraded trip still feeds the cornering analytic +
/// accuracy-gate.
void main() {
  group('#2648 GpsOnlySampleBuilder.build stamps accuracy + bearing', () {
    test('forwards hAccuracyM + bearingDeg onto the sample (round-trips '
        'through the codec)', () {
      final sample = GpsOnlySampleBuilder.build(
        timestamp: DateTime(2026, 6, 1, 9),
        speedKmh: 50,
        latitude: 43.4,
        longitude: 3.5,
        altitudeM: 100,
        hAccuracyM: 6.3,
        bearingDeg: 271.0,
      );
      expect(sample.hAccuracyM, 6.3);
      expect(sample.bearingDeg, 271.0);
      // Persisted form keeps them ('ha' / 'be') and decodes clean.
      final decoded = sampleFromJson(sampleToJson(sample));
      expect(decoded.hAccuracyM, 6.3);
      expect(decoded.bearingDeg, 271.0);
    });

    test('both null when not supplied stay null (legacy-compatible)', () {
      final sample = GpsOnlySampleBuilder.build(
        timestamp: DateTime(2026, 6, 1, 9),
        speedKmh: 50,
        latitude: 43.4,
        longitude: 3.5,
      );
      expect(sample.hAccuracyM, isNull);
      expect(sample.bearingDeg, isNull);
    });
  });

  group('#2648 DegradedGpsEmitter threads accuracy + bearing to the sample',
      () {
    test('the GPS-only sample fed to the buffer carries accuracy + bearing',
        () {
      final buffer = TripSampleBuffer();
      final recorder = TripRecorder();
      final now = DateTime(2026, 6, 1, 10);
      final emitter = DegradedGpsEmitter(
        now: () => now,
        recorder: recorder,
        sampleBuffer: buffer,
        gpsAliveWindow: const Duration(seconds: 5),
        onEscalate: () {},
        onSampleAt: (_) {},
        overlayEstimate: (reading,
                {required nowTs,
                required effectiveSpeedKmh,
                required altitudeM}) =>
            reading,
      );

      final reading = emitter.emitTick(
        latestGpsSpeedKmh: 50,
        latitude: 43.4,
        longitude: 3.5,
        altitudeM: 100,
        hAccuracyM: 7.7,
        bearingDeg: 12.5,
        lastGpsFixAt: now, // within the alive window
        startedAt: now.subtract(const Duration(minutes: 1)),
        resolverDistanceKm: 1,
        odometerStartKm: null,
        odometerLatestKm: null,
      );

      expect(reading, isNotNull);
      expect(buffer.capturedSamples, isNotEmpty);
      expect(buffer.capturedSamples.last.hAccuracyM, 7.7);
      expect(buffer.capturedSamples.last.bearingDeg, 12.5);
    });
  });
}
