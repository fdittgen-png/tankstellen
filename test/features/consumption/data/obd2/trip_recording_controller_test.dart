import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';

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
