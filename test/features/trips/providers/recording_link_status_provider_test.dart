// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/api.dart';
import 'package:tankstellen/features/trips/providers/recording_gps_fix_provider.dart';
import 'package:tankstellen/features/trips/providers/recording_link_status_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_phase.dart';

/// #3916 (Epic #3914) — the recording screen's OBD2 / GPS status
/// derivations, pinned as a decision table so the chip copy can never
/// drift from the recording phase + link state it describes.
void main() {
  RecordingObd2Status obd2({
    TripRecordingPhase phase = TripRecordingPhase.recording,
    TripDropReason? dropReason,
    bool passive = false,
    bool engineData = true,
    int? rps,
    Obd2LinkState link = Obd2LinkState.ready,
    bool gpsOnlyKind = false,
    int? attempt,
  }) =>
      deriveObd2Status(
        phase: phase,
        dropReason: dropReason,
        reconnectPassiveWaiting: passive,
        hasEngineData: engineData,
        readsPerSecond: rps,
        link: link,
        gpsOnlyTripKind: gpsOnlyKind,
        attempt: attempt,
      );

  group('deriveObd2Status', () {
    test('a GPS-only trip kind reads "no adapter" whatever the link does',
        () {
      expect(obd2(gpsOnlyKind: true), const Obd2StatusNoAdapter());
      expect(obd2(gpsOnlyKind: true, link: Obd2LinkState.reconnecting),
          const Obd2StatusNoAdapter());
    });

    test('recording with engine data is live, carrying the read rate', () {
      expect(obd2(rps: 12), const Obd2StatusLive(readsPerSecond: 12));
      expect(obd2(), const Obd2StatusLive());
    });

    test('a ready link without engine data yet still reads live (warming)',
        () {
      expect(obd2(engineData: false), const Obd2StatusLive());
      expect(obd2(engineData: false, link: Obd2LinkState.connecting),
          const Obd2StatusLive());
    });

    test('degraded on GPS with the loop dialing is reconnecting (+ attempt)',
        () {
      expect(
        obd2(
          phase: TripRecordingPhase.degradedGpsOnly,
          engineData: false,
          link: Obd2LinkState.reconnecting,
          attempt: 3,
        ),
        const Obd2StatusReconnecting(attempt: 3),
      );
    });

    test('degraded on GPS with the loop passively waiting is GPS only', () {
      expect(
        obd2(
          phase: TripRecordingPhase.degradedGpsOnly,
          engineData: false,
          passive: true,
          link: Obd2LinkState.reconnecting,
        ),
        const Obd2StatusGpsOnly(),
      );
    });

    test('an engine-off drop reason or a parked link reads engine off', () {
      expect(
        obd2(
          phase: TripRecordingPhase.degradedGpsOnly,
          dropReason: TripDropReason.engineOff,
          engineData: false,
        ),
        const Obd2StatusEngineOff(),
      );
      expect(
        obd2(engineData: false, link: Obd2LinkState.engineOff),
        const Obd2StatusEngineOff(),
      );
      expect(
        obd2(
          phase: TripRecordingPhase.pausedDueToDrop,
          dropReason: TripDropReason.engineOff,
          engineData: false,
        ),
        const Obd2StatusEngineOff(),
      );
    });

    test('both sources dead (pausedDueToDrop) is reconnecting', () {
      expect(
        obd2(
          phase: TripRecordingPhase.pausedDueToDrop,
          dropReason: TripDropReason.transportError,
          engineData: false,
          link: Obd2LinkState.reconnecting,
          attempt: 2,
        ),
        const Obd2StatusReconnecting(attempt: 2),
      );
    });

    test('an idle / user-disconnected link with no engine data is GPS only',
        () {
      expect(obd2(engineData: false, link: Obd2LinkState.idle),
          const Obd2StatusGpsOnly());
      expect(obd2(engineData: false, link: Obd2LinkState.userDisconnected),
          const Obd2StatusGpsOnly());
    });
  });

  group('deriveGpsStatus', () {
    final now = DateTime(2026, 3, 11, 14, 30);

    test('no fix yet', () {
      expect(deriveGpsStatus(null, now), RecordingGpsStatus.noFix);
    });

    test('a fresh fix within the precise band', () {
      final fix = RecordingGpsFix(
        fixAt: now.subtract(const Duration(seconds: 1)),
        firstFixAt: now.subtract(const Duration(seconds: 1)),
        fixCount: 1,
        accuracyM: 4.6,
      );
      expect(
        deriveGpsStatus(fix, now),
        const RecordingGpsStatus(quality: GpsFixQuality.precise, accuracyM: 5),
      );
    });

    test('a coarse fix is approximate and carries coverage once it exists',
        () {
      final first = now.subtract(const Duration(seconds: 20));
      final fix = RecordingGpsFix(
        fixAt: now.subtract(const Duration(seconds: 1)),
        firstFixAt: first,
        fixCount: 18,
        accuracyM: 38.0,
      );
      final status = deriveGpsStatus(fix, now);
      expect(status.quality, GpsFixQuality.approximate);
      expect(status.accuracyM, 38);
      // 18 fixes over a 19 s span (+1 inclusive) = 90 %.
      expect(status.coveragePercent, 90);
    });

    test('a fix without an accuracy figure is flagged as such', () {
      final fix = RecordingGpsFix(
        fixAt: now,
        firstFixAt: now,
        fixCount: 1,
      );
      expect(deriveGpsStatus(fix, now).quality, GpsFixQuality.unknownAccuracy);
    });

    test('a stale fix reads "no fix" but keeps the coverage so far', () {
      final fix = RecordingGpsFix(
        fixAt: now.subtract(const Duration(seconds: 40)),
        firstFixAt: now.subtract(const Duration(seconds: 60)),
        fixCount: 21,
        accuracyM: 5.0,
      );
      final status = deriveGpsStatus(fix, now);
      expect(status.quality, GpsFixQuality.none);
      expect(status.accuracyM, isNull);
      expect(status.coveragePercent, 100);
    });
  });

  group('RecordingGpsFix.coveragePercent', () {
    test('null under the minimum span, clamped to 100 above it', () {
      final t0 = DateTime(2026, 3, 11, 14, 30);
      expect(
        RecordingGpsFix(fixAt: t0, firstFixAt: t0, fixCount: 1)
            .coveragePercent,
        isNull,
      );
      expect(
        RecordingGpsFix(
          fixAt: t0.add(const Duration(seconds: 10)),
          firstFixAt: t0,
          fixCount: 30,
        ).coveragePercent,
        100,
      );
    });
  });
}
