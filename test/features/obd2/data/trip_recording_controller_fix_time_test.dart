// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/trip_distance_source.dart';
import 'package:tankstellen/features/obd2/data/trip_recording_controller.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3253 — `updateGpsFix` must stamp buffered fixes with the fix's OWN
/// timestamp (`fixAt` = `Position.timestamp`), not the arrival clock.
///
/// Under Android location batching a whole burst of fixes is delivered
/// on ONE arrival instant. Stamped with the arrival clock, every batched
/// pair has Δt ≈ 0, so the #3004 non-advancing-clock rule keeps ALL of
/// them (no decimation) and the #2963 teleport gate (which requires
/// Δt ≥ 0.5 s) is blind — a cold-start position jump inside the batch
/// counts as road distance. Threading the real fix time restores the
/// per-pair Δt both gates need.
void main() {
  silenceErrorLoggerSpool();

  TripRecordingController build(DateTime Function() now) =>
      TripRecordingController(
        service: Obd2Service(FakeObd2Transport(const {})),
        now: now,
      );

  group('#3253 updateGpsFix fix-time stamping', () {
    test(
        'a teleport jump inside an arrival-batched burst is rejected when '
        'fixAt carries the real fix times (RED with the arrival clock)', () {
      // Frozen arrival clock — the whole burst "arrives" on one instant,
      // exactly what Android batching looks like to the controller.
      final arrival = DateTime.utc(2026, 6, 1, 8);
      final ctl = build(() => arrival);

      // 12 plausible fixes 1 s apart (~22 m/s ≈ 80 km/h) with ONE
      // ~1.1 km cold-start jump in the middle (≈ 4000 km/h implied).
      final t0 = DateTime.utc(2026, 6, 1, 7, 59);
      var lat = 45.0;
      for (var i = 0; i < 12; i++) {
        lat += (i == 6) ? 0.01 : 0.0002; // the i==6 hop is the teleport
        ctl.updateGpsFix(
          latitude: lat,
          longitude: 5.0,
          hAccuracyM: 6.0,
          fixAt: t0.add(Duration(seconds: i)),
        );
      }

      expect(ctl.distanceSource, kDistanceSourceGps);
      // 11 plausible ~22 m legs ≈ 0.24 km; the 1.1 km jump must NOT be
      // summed. With the arrival clock (all fixes on one instant) the
      // teleport gate is skipped (Δt < 0.5 s) and the distance balloons
      // past 1.3 km — the pre-#3253 behaviour.
      expect(ctl.currentDistanceKm, lessThan(0.5),
          reason: 'the batched cold-start jump must be teleport-gated');
      expect(ctl.currentDistanceKm, greaterThan(0.1),
          reason: 'the genuine legs still count (no over-rejection)');
    });

    test('fixAt omitted falls back to the arrival clock (legacy callers)',
        () {
      var tick = DateTime.utc(2026, 6, 1, 8);
      final ctl = build(() => tick);

      // A legacy caller passing no fixAt still gets arrival-clock stamps:
      // fixes 10 s apart at ~111 m per hop resolve to a plausible GPS
      // track exactly as before.
      for (var i = 0; i < 12; i++) {
        ctl.updateGpsFix(latitude: 45.0 + i * 0.001, longitude: 5.0);
        tick = tick.add(const Duration(seconds: 10));
      }

      expect(ctl.distanceSource, kDistanceSourceGps);
      expect(ctl.currentDistanceKm, closeTo(1.223, 0.05));
    });
  });
}
