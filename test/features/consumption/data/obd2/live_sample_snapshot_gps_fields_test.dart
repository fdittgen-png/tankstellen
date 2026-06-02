// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/live_sample_snapshot.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// #2648 — `LiveSampleSnapshot.updateGpsFix` now latches GPS horizontal
/// accuracy + bearing alongside lat/lon/altitude, so the OBD2 emit path
/// stops dropping them (they used to reach only 0.3 % of samples — only
/// the GPS-only pipeline kept them). These pin the latch + the null-guard.
class _StubTransport implements Obd2Transport {
  @override
  bool get isConnected => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<String> sendCommand(String command) async => 'NO DATA';
}

LiveSampleSnapshot _snapshot() => LiveSampleSnapshot(
      service: Obd2Service(_StubTransport()),
      onHighPriorityParse: (_) {},
      onSpeedSample: (_) {},
    );

void main() {
  group('#2648 LiveSampleSnapshot GPS accuracy + bearing latch', () {
    test('updateGpsFix latches hAccuracyM + bearingDeg onto the getters', () {
      final snap = _snapshot();
      snap.updateGpsFix(
        latitude: 43.4,
        longitude: 3.5,
        altitudeM: 100,
        hAccuracyM: 4.2,
        bearingDeg: 217.5,
      );
      expect(snap.latestHAccuracyM, 4.2);
      expect(snap.latestBearingDeg, 217.5);
      // The pre-existing latches are unchanged by the new params.
      expect(snap.latestLatitude, 43.4);
      expect(snap.latestLongitude, 3.5);
      expect(snap.latestAltitudeM, 100);
    });

    test('both default null when not supplied (pre-#2648 behaviour)', () {
      final snap = _snapshot();
      snap.updateGpsFix(latitude: 43.4, longitude: 3.5);
      expect(snap.latestHAccuracyM, isNull);
      expect(snap.latestBearingDeg, isNull);
    });

    test('a subsequent null-field call clears the latch', () {
      final snap = _snapshot();
      snap.updateGpsFix(hAccuracyM: 5, bearingDeg: 90);
      expect(snap.latestHAccuracyM, 5);
      expect(snap.latestBearingDeg, 90);
      // Provider pushes a fix with no accuracy/bearing → latch clears,
      // same null-guard contract as altitude.
      snap.updateGpsFix(latitude: 1, longitude: 2);
      expect(snap.latestHAccuracyM, isNull);
      expect(snap.latestBearingDeg, isNull);
    });
  });

  group('#2692 C4-B LiveSampleSnapshot altitude isFinite guard', () {
    test('a NaN altitude is dropped to null (not propagated to grade math)',
        () {
      final snap = _snapshot();
      snap.updateGpsFix(latitude: 43.4, longitude: 3.5, altitudeM: double.nan);
      expect(snap.latestAltitudeM, isNull);
    });

    test('infinite altitude is also dropped to null', () {
      final snap = _snapshot();
      snap.updateGpsFix(altitudeM: double.infinity);
      expect(snap.latestAltitudeM, isNull);
      snap.updateGpsFix(altitudeM: double.negativeInfinity);
      expect(snap.latestAltitudeM, isNull);
    });

    test('a finite altitude latches unchanged', () {
      final snap = _snapshot();
      snap.updateGpsFix(altitudeM: 123.5);
      expect(snap.latestAltitudeM, 123.5);
    });
  });
}
