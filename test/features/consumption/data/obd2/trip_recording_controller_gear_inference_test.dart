import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Integration test for #1263 phase 2: the controller wires
/// `gear_inference.dart` into `_finaliseSummary()` so the persisted
/// [TripSummary] carries `secondsBelowOptimalGear` for combustion
/// vehicles and null for EVs.
///
/// The test drives the controller through its public surface — start,
/// inject samples via the `debug*` hooks, stop — and asserts on the
/// resulting summary. No real Bluetooth or Hive in scope.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Build a ~600-sample five-speed-manual fixture that exercises
  /// every gear regime — same shape as the
  /// `gear_inference_test.dart` fixture, replicated locally so this
  /// test owns its inputs end-to-end.
  List<TripSample> fiveSpeedFixture(DateTime t0) {
    List<TripSample> regime({
      required DateTime start,
      required int count,
      required double speedKmh,
      required double rpm,
    }) {
      return List<TripSample>.generate(
        count,
        (i) => TripSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: speedKmh,
          rpm: rpm,
        ),
        growable: false,
      );
    }

    return <TripSample>[
      ...regime(start: t0, count: 120, speedKmh: 10, rpm: 1500),
      ...regime(
        start: t0.add(const Duration(seconds: 120)),
        count: 120,
        speedKmh: 25,
        rpm: 2000,
      ),
      ...regime(
        start: t0.add(const Duration(seconds: 240)),
        count: 120,
        speedKmh: 50,
        rpm: 2500,
      ),
      ...regime(
        start: t0.add(const Duration(seconds: 360)),
        count: 120,
        speedKmh: 80,
        rpm: 2500,
      ),
      ...regime(
        start: t0.add(const Duration(seconds: 480)),
        count: 120,
        speedKmh: 110,
        rpm: 2500,
      ),
    ];
  }

  Map<String, String> elmOk() => const {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 01 6A 2C>',
      };

  group('TripRecordingController gear inference (#1263 phase 2)', () {
    test(
        'combustion vehicle with synthetic five-speed samples produces a '
        'non-null secondsBelowOptimalGear', () async {
      final service = Obd2Service(FakeObd2Transport(elmOk()));
      await service.connect();

      const vehicle = VehicleProfile(
        id: 'combustion-1',
        name: 'Combustion Test',
        // Default tireCircumferenceMeters = 1.95 — the same value the
        // fixture's clustering math is anchored on.
      );

      final ctl = TripRecordingController(
        service: service,
        vehicle: vehicle,
        // Never tick the emit timer in-test; we drive the recorder
        // directly via the debug hooks.
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();

      final t0 = DateTime(2026, 4, 28, 8, 0, 0);
      final fixture = fiveSpeedFixture(t0);
      for (final s in fixture) {
        // Feed the recorder so the trip has real distance/duration
        // bookkeeping, AND populate the captured-samples buffer that
        // [_computeGearCoachingMetric] reads.
        ctl.debugInjectSample(
          speedKmh: s.speedKmh,
          rpm: s.rpm,
          at: s.timestamp,
        );
        ctl.debugCaptureSample(s);
      }

      final summary = await ctl.stop();
      expect(summary.secondsBelowOptimalGear, isNotNull,
          reason:
              'A combustion vehicle with sufficient samples must produce '
              'a numeric secondsBelowOptimalGear metric, not null.');
      expect(summary.secondsBelowOptimalGear, greaterThanOrEqualTo(0));
    });

    test('EV vehicle bypasses gear inference — secondsBelowOptimalGear null',
        () async {
      final service = Obd2Service(FakeObd2Transport(elmOk()));
      await service.connect();

      const vehicle = VehicleProfile(
        id: 'ev-1',
        name: 'EV Test',
        type: VehicleType.ev,
      );

      final ctl = TripRecordingController(
        service: service,
        vehicle: vehicle,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();

      // Even though we feed the same fixture, the EV gate short-
      // circuits before [inferGears] runs. Useful regression coverage:
      // the gate must not depend on missing samples or zero centroids.
      final t0 = DateTime(2026, 4, 28, 8, 0, 0);
      final fixture = fiveSpeedFixture(t0);
      for (final s in fixture) {
        ctl.debugInjectSample(
          speedKmh: s.speedKmh,
          rpm: s.rpm,
          at: s.timestamp,
        );
        ctl.debugCaptureSample(s);
      }

      final summary = await ctl.stop();
      expect(summary.secondsBelowOptimalGear, isNull,
          reason: 'EV vehicles must bypass gear inference — no gears, '
              'no coaching.');
    });

    test('combustion vehicle with no captured samples produces null', () async {
      // Edge case: stop() called before any sample landed. Inference
      // must short-circuit on the empty buffer and return null rather
      // than 0.0 — "no signal" beats "no missed gears" because the
      // UI distinguishes the two states.
      final service = Obd2Service(FakeObd2Transport(elmOk()));
      await service.connect();

      const vehicle = VehicleProfile(
        id: 'combustion-empty',
        name: 'Combustion No-Data',
      );

      final ctl = TripRecordingController(
        service: service,
        vehicle: vehicle,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      final summary = await ctl.stop();
      expect(summary.secondsBelowOptimalGear, isNull);
    });

    test('null vehicle profile produces null (no calibration data)', () async {
      final service = Obd2Service(FakeObd2Transport(elmOk()));
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        // No vehicle wired.
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();

      final t0 = DateTime(2026, 4, 28, 8, 0, 0);
      final fixture = fiveSpeedFixture(t0);
      for (final s in fixture) {
        ctl.debugInjectSample(
          speedKmh: s.speedKmh,
          rpm: s.rpm,
          at: s.timestamp,
        );
        ctl.debugCaptureSample(s);
      }
      final summary = await ctl.stop();
      expect(summary.secondsBelowOptimalGear, isNull,
          reason:
              'Without a vehicle profile we have no tyre size — the '
              'gear-inference math is undefined. Return null instead of '
              'guessing.');
    });
  });
}
