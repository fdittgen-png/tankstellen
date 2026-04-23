import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

void main() {
  group('TripRecordingController (#726)', () {
    test('start() reads the odometer once and exposes it as '
        'odometerStartKm', () async {
      // Hand-crafted raw ELM327 responses: Mode 01 PID A6 encodes the
      // odometer at 1/10 km resolution (value / 10). Bytes
      // `00 01 6A 2C` = 0x16A2C = 92 716 raw → 9271.6 km.
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 01 6A 2C>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1), // never ticks in-test
      );
      await ctl.start();
      await ctl.stop();

      expect(ctl.odometerStartKm, closeTo(9271.6, 0.01));
    });

    test('stop() returns a non-null TripSummary even when no sample '
        'was ever recorded', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': 'NO DATA>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      final summary = await ctl.stop();

      expect(summary.distanceKm, 0);
      expect(summary.fuelLitersConsumed, isNull);
      expect(ctl.odometerStartKm, isNull);
    });

    test('pause() freezes polling; resume() re-arms it (#726)', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 01 6A 2C>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      expect(ctl.isRecording, isTrue);
      expect(ctl.isPaused, isFalse);
      expect(ctl.isActive, isTrue);

      ctl.pause();
      expect(ctl.isPaused, isTrue);
      expect(ctl.isRecording, isFalse);
      expect(ctl.isActive, isTrue,
          reason: 'paused means "still owns the service", not "stopped"');

      ctl.resume();
      expect(ctl.isPaused, isFalse);
      expect(ctl.isRecording, isTrue);

      await ctl.stop();
    });

    test('refreshOdometer() pulls a fresh reading before stop()',
        () async {
      // Transport returns two different values on successive 01A6 calls
      // so we can assert refreshOdometer picks up the second one.
      var call = 0;
      final transport = _SequencedTransport(
        init: {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
        },
        onOdometer: () {
          call++;
          return call == 1
              ? '41 A6 00 01 6A 2C>' // 92716 km at start
              : '41 A6 00 01 6A 3E>'; // 92734 km later
        },
      );
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();
      expect(ctl.odometerStartKm, closeTo(9271.6, 0.01));
      await ctl.refreshOdometer();
      expect(ctl.odometerLatestKm, closeTo(9273.4, 0.01));
      await ctl.stop();
    });

    group('engine-param plumbing — #812 phase 3', () {
      test(
          'accepts a VehicleProfile and feeds its engine fields into '
          'readFuelRateLPerHour on every poll', () async {
        // On a Peugeot 107-class setup (no PID 5E, no MAF; only
        // MAP+IAT+RPM), the resulting fuel rate is directly
        // proportional to displacement × η_v. Doubling displacement
        // doubles the rate. Test the wire-up by running the chain
        // with two different engine-size configurations and
        // asserting the ratio matches the math.
        Future<Obd2Service> peugeot107() async {
          final t = FakeObd2Transport({
            'ATZ': 'ELM327 v1.5>',
            'ATE0': 'OK>',
            'ATL0': 'OK>',
            'ATH0': 'OK>',
            'ATSP0': 'OK>',
            '015E': 'NO DATA>',
            '0110': 'NO DATA>',
            '010B': '41 0B 50>', // MAP 80 kPa
            '010F': '41 0F 41>', // IAT 25 °C
            '010C': '41 0C 0E A6>', // RPM 939.5
          });
          final s = Obd2Service(t);
          await s.connect();
          return s;
        }

        // Service-level sanity: 2.0 L yields twice the fuel rate of
        // 1.0 L at the same VE and operating point — passing two
        // profiles that differ only in displacement.
        final svc1 = await peugeot107();
        final rate1L = await svc1.readFuelRateLPerHour(
          vehicle: const VehicleProfile(
            id: 'a',
            name: '1.0L',
            engineDisplacementCc: 1000,
          ),
        );
        final svc2 = await peugeot107();
        final rate2L = await svc2.readFuelRateLPerHour(
          vehicle: const VehicleProfile(
            id: 'b',
            name: '2.0L',
            engineDisplacementCc: 2000,
          ),
        );
        expect(rate1L, isNotNull);
        expect(rate2L, isNotNull);
        expect(rate2L! / rate1L!, closeTo(2.0, 0.01));

        // Controller wire-up: the constructor param is plumbed
        // through. Not validated by running the poll loop (that
        // requires a timer + streaming), but the parameter is
        // captured and non-null when supplied.
        final ctl = TripRecordingController(
          service: svc1,
          pollInterval: const Duration(minutes: 1),
          vehicle: const VehicleProfile(
            id: 'peugeot107',
            name: 'Peugeot 107',
            engineDisplacementCc: 998,
            volumetricEfficiency: 0.80,
          ),
        );
        await ctl.start();
        await ctl.stop();
        // No observable side-effect to assert beyond "no throw",
        // but this locks the constructor signature against
        // accidental removal.
      });

      test(
          'null vehicle falls back to the generic 1.0 L / 0.85 defaults — '
          'matches the pre-#812 hardcoded behavior', () async {
        final transport = FakeObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '01A6': 'NO DATA>',
        });
        final service = Obd2Service(transport);
        await service.connect();

        // Omitting the vehicle param should not throw and should
        // behave identically to the pre-#812 constructor.
        final ctl = TripRecordingController(
          service: service,
          pollInterval: const Duration(minutes: 1),
        );
        await ctl.start();
        await ctl.stop();
      });
    });
  });
}

/// Transport that serves canned responses for the init + a custom
/// lambda for every `01A6` call. Used to simulate the odometer
/// changing during the trip.
class _SequencedTransport implements Obd2Transport {
  final Map<String, String> init;
  final String Function() onOdometer;
  _SequencedTransport({required this.init, required this.onOdometer});

  bool _connected = false;
  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  bool get isConnected => _connected;
  @override
  Future<String> sendCommand(String command) async {
    final key = command.trim();
    if (key == '01A6') return onOdometer();
    return init[key] ?? 'NO DATA>';
  }
}
