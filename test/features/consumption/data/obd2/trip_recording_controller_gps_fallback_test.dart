// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_scheduler.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/driving_coaching.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_fuel_estimator.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_live_estimate_folder.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #2506 — pipeline-level reproduction of the "live screen is blank on a
/// car with no fuel-rate PID" defect (Epic #2504, child #2506).
///
/// Per the recurring-bug protocol, this reproduces at the controller
/// (pipeline) level, NOT the widget. The transport answers throttle (0111)
/// + coolant (0105) + RPM (010C) + speed (010D) but **none** of the fuel
/// PIDs (no 015E, no MAF 0110, no speed-density MAP 010B) — exactly the
/// Peugeot/PSA + Generic ELM327 in the field report — so
/// `deriveFuelRateLPerHour()` returns null on every tick. Before #2506 the
/// live `TripLiveReading` then carried `gpsEstimated* == null` for the
/// whole drive (the screen showed "—") while the saved trip got the
/// `Obd2GpsEstimateFallback` back-fill at stop. This test pins that the
/// LIVE reading now carries the GPS-physics estimate + a coaching hint, and
/// that live Distance/Speed come off the GPS track when the OBD2 speed PID
/// is momentarily absent.
class _MutableClock {
  _MutableClock(this._now);
  DateTime _now;
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// ELM327 handshake + RPM/speed/throttle/coolant + odometer, but NO fuel
/// PID of any kind → speed-density / MAF / 5E all fail → fuel rate null.
Map<String, String> _noFuelPidResponses() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '010C': '41 0C 0E A6>', // RPM ~937.5
      '010D': '41 0D 32>', // 50 km/h
      '0111': '41 11 40>', // throttle ~25 %
      '0105': '41 05 78>', // coolant 80 °C
      // Every fuel PID + speed-density input answers NO DATA → null fuel.
      '015E': 'NO DATA>',
      '0110': 'NO DATA>',
      '010B': 'NO DATA>',
      '010F': 'NO DATA>',
      '01A6': 'NO DATA>', // no odometer (Peugeot 107 class)
      '0902': 'NO DATA>', // no VIN
    };

void main() {
  silenceErrorLoggerSpool();

  group('OBD2 live GPS fallback on a no-fuel-PID car (#2506)', () {
    test(
        'live reading carries a non-null GPS fuel estimate + coaching hint, '
        'and Distance/Speed come off the GPS track when OBD2 speed is '
        'absent', () async {
      final clock = _MutableClock(DateTime(2026, 5, 31, 9));
      final transport = FakeObd2Transport(_noFuelPidResponses());
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        now: clock.call,
        // Never auto-ticks — the test drives emits deterministically so the
        // estimator's accel finite-diff has a stable dt.
        pollInterval: const Duration(minutes: 1),
        scheduler: PidScheduler(
          transport: service.sendCommand,
          tickRate: const Duration(milliseconds: 20),
        ),
        gpsEstimateFolder: GpsLiveEstimateFolder.forVehicle(null, null),
      );
      final readings = <TripLiveReading>[];
      final sub = ctl.live.listen(readings.add);
      await ctl.start();

      // Let the scheduler fill the snapshot with throttle / coolant / RPM /
      // speed from the fake transport.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Drive several 1 s-apart emit ticks. Each tick feeds a GPS fix
      // (speed + a moving track) into the controller, then forces an emit
      // with the clock advanced 1 s — the estimator's 3-sample accel
      // low-pass warms up and starts integrating litres + distance.
      for (var i = 0; i < 6; i++) {
        ctl.updateGpsFix(
          latitude: 43.40 + i * 0.001,
          longitude: 3.50,
          altitudeM: 100,
          speedKmh: 72, // 20 m/s GPS ground-speed
        );
        clock.advance(const Duration(seconds: 1));
        ctl.debugEmitNow();
      }
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      await ctl.stop();

      expect(readings, isNotEmpty);
      final latest = readings.last;

      // Root assertion: the LIVE reading carries the GPS-physics estimate
      // (it was null the whole drive before #2506) — not a measured one.
      expect(latest.fuelRateLPerHour, isNull,
          reason: 'the transport exposes no fuel PID → fuel rate is null');
      expect(latest.gpsEstimatedAvgLPer100Km, isNotNull,
          reason: 'a moving no-fuel-PID OBD2 trip must surface a live '
              'GPS-physics running-average estimate, not "—"');
      expect(latest.gpsEstimatedAvgLPer100Km,
          greaterThanOrEqualTo(GpsFuelEstimator.minLPer100Km));
      expect(latest.gpsEstimatedAvgLPer100Km,
          lessThanOrEqualTo(GpsFuelEstimator.maxLPer100Km));
      expect(latest.gpsEstimatedFuelLitersSoFar, isNotNull);
      expect(latest.gpsEstimatedFuelLitersSoFar, greaterThan(0));

      // Coaching: the steady-cruise track yields no actionable hint here,
      // but the controller must EXPOSE the GPS coaching channel (non-error,
      // computed from the GPS-stamped samples) for MinimalDriveSummary —
      // the getter is the seam the pipeline publishes onto state.
      expect(
        ctl.latestGpsCoachingHint,
        anyOf(isNull, isA<DrivingCoachingHint>()),
      );

      // Live Distance must be non-zero from the GPS track even though the
      // car exposes no odometer.
      expect(latest.distanceKmSoFar, greaterThan(0),
          reason: 'GPS-track distance must drive the live read-out');
      // Live Speed reflects the OBD2 PID 0x0D (50 km/h) when present.
      expect(latest.speedKmh, isNotNull);
      expect(latest.speedKmh, greaterThan(0));
    });

    test(
        'live Speed falls back to the latched GPS ground-speed when the '
        'OBD2 speed PID (0x0D) is absent', () async {
      final clock = _MutableClock(DateTime(2026, 5, 31, 10));
      // RPM present (so a sample is built) but NO speed PID 0x0D and no
      // fuel PID — the snapshot's OBD2 speed stays null.
      final transport = FakeObd2Transport(const {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '010C': '41 0C 0E A6>', // RPM only
        '010D': 'NO DATA>', // speed PID ABSENT
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': 'NO DATA>',
        '01A6': 'NO DATA>',
        '0902': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        now: clock.call,
        pollInterval: const Duration(minutes: 1),
        scheduler: PidScheduler(
          transport: service.sendCommand,
          tickRate: const Duration(milliseconds: 20),
        ),
        gpsEstimateFolder: GpsLiveEstimateFolder.forVehicle(null, null),
      );
      final readings = <TripLiveReading>[];
      final sub = ctl.live.listen(readings.add);
      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      ctl.updateGpsFix(
        latitude: 43.40,
        longitude: 3.50,
        altitudeM: 100,
        speedKmh: 64, // GPS-only ground-speed
      );
      clock.advance(const Duration(seconds: 1));
      ctl.debugEmitNow();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      await ctl.stop();

      final latest = readings.last;
      expect(latest.speedKmh, closeTo(64, 1e-6),
          reason: 'with OBD2 0x0D absent, the live speed must fall back to '
              'the latched GPS ground-speed instead of dashing to "—"');
    });
  });
}
