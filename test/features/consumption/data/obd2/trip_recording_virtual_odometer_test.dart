import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/data/obd2/virtual_odometer.dart';

// Shared AT-init boilerplate for the FakeObd2Transport.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

Future<Obd2Service> _connectedService(Map<String, String> extra) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport);
  await service.connect();
  return service;
}

TripRecordingController _buildController(Obd2Service service) {
  return TripRecordingController(
    service: service,
    pollInterval: const Duration(minutes: 1), // never emits in-test
  );
}

void main() {
  group('TripRecordingController + VirtualOdometer wiring (#800)', () {
    test(
        'real odometer available → distanceSource == `real`, distanceKm '
        'matches odometerLatest - odometerStart', () async {
      final service = await _connectedService({
        // Start odometer read at trip start. Raw 0x00_01_6A_2C = 92716
        // → 9271.6 km at 1/10 km resolution.
        '01A6': '41 A6 00 01 6A 2C>',
      });
      final ctl = _buildController(service);
      await ctl.start();
      // Simulate end-of-trip odometer bump by 3.0 km.
      ctl.debugSetOdometerReadings(latestKm: 9274.6);
      final summary = await ctl.stop();

      expect(summary.distanceSource, 'real');
      expect(summary.distanceKm, closeTo(3.0, 0.01));
      expect(ctl.currentDistanceKm, closeTo(3.0, 0.01));
    });

    test(
        'real odometer not available → distanceSource == `virtual`, '
        'distanceKm matches VirtualOdometer.integrateKm() of captured '
        'speed samples', () async {
      final service = await _connectedService({
        '01A6': 'NO DATA>', // no PID A6
        '0131': 'NO DATA>', // no PID 31 either → odometer null
      });
      final ctl = _buildController(service);
      await ctl.start();

      // Pre-populate the virtual-odometer buffer: 0→60 km/h ramp over
      // 30 s, then cruise at 60 km/h for 270 s = 4.5 km cruise +
      // 0.25 km ramp = 4.75 km total.
      final t0 = DateTime.utc(2026, 4, 22, 11);
      ctl.debugRecordSpeedSample(speedKmh: 0, at: t0);
      ctl.debugRecordSpeedSample(
        speedKmh: 60,
        at: t0.add(const Duration(seconds: 30)),
      );
      ctl.debugRecordSpeedSample(
        speedKmh: 60,
        at: t0.add(const Duration(seconds: 300)),
      );

      final summary = await ctl.stop();
      final expected = VirtualOdometer(samples: ctl.debugSpeedSamples)
          .integrateKm();
      expect(summary.distanceSource, 'virtual');
      expect(summary.distanceKm, closeTo(expected, 0.01));
      // Within 1 % of the hand-computed 4.75 km ground truth.
      expect(summary.distanceKm, closeTo(4.75, 4.75 * 0.01));
    });

    test(
        'zero-km odometer delta (start == latest) falls through to '
        'virtual path — parked car should not flag `real`', () async {
      final service = await _connectedService({
        '01A6': '41 A6 00 01 6A 2C>', // start = 9271.6 km
      });
      final ctl = _buildController(service);
      await ctl.start();
      // Odometer never moved (car was idling / reading quantised away).
      ctl.debugSetOdometerReadings(latestKm: 9271.6);
      // But some speed samples were recorded.
      final t0 = DateTime.utc(2026, 4, 22, 12);
      ctl.debugRecordSpeedSample(speedKmh: 30, at: t0);
      ctl.debugRecordSpeedSample(
        speedKmh: 30,
        at: t0.add(const Duration(seconds: 60)),
      );

      final summary = await ctl.stop();
      // 0 km real delta → null → virtual. 0.5 km from samples
      // (30 km/h × 60 s).
      expect(summary.distanceSource, 'virtual');
      expect(summary.distanceKm, closeTo(0.5, 0.01));
    });

    test(
        'currentDistanceKm getter reflects the same value stop() '
        'persists — no drift between live reads and finalisation',
        () async {
      final service = await _connectedService({
        '01A6': 'NO DATA>',
        '0131': 'NO DATA>',
      });
      final ctl = _buildController(service);
      await ctl.start();

      final t0 = DateTime.utc(2026, 4, 22, 13);
      ctl.debugRecordSpeedSample(speedKmh: 0, at: t0);
      ctl.debugRecordSpeedSample(
        speedKmh: 60,
        at: t0.add(const Duration(seconds: 60)),
      );
      final live = ctl.currentDistanceKm;
      expect(live, closeTo(0.5, 0.01));

      final summary = await ctl.stop();
      expect(summary.distanceKm, closeTo(live, 1e-9));
    });
  });
}
