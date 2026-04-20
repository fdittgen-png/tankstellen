import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

// Shared AT-init boilerplate for the FakeObd2Transport.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

Future<Obd2Service> _connected(Map<String, String> extra) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport);
  await service.connect();
  return service;
}

void main() {
  group('Obd2Service PID expansion (#717)', () {
    test('readEngineLoad parses PID 04', () async {
      final service = await _connected({'0104': '41 04 80>'});
      expect(await service.readEngineLoad(), closeTo(50.2, 0.1));
    });

    test('readThrottlePercent parses PID 11', () async {
      final service = await _connected({'0111': '41 11 40>'});
      expect(await service.readThrottlePercent(), closeTo(25.1, 0.1));
    });

    test('readFuelRateLPerHour returns PID 5E when supported', () async {
      final service = await _connected({'015E': '41 5E 08 00>'});
      expect(await service.readFuelRateLPerHour(), closeTo(102.4, 0.1));
    });

    test(
        'readFuelRateLPerHour falls back to MAF (PID 10) when 5E returns '
        'NO DATA', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': '41 10 04 00>', // MAF = 10.24 g/s
      });
      final rate = await service.readFuelRateLPerHour();
      // 10.24 × 3600 / (14.7 × 740) ≈ 3.389 L/h
      expect(rate, closeTo(3.389, 0.01));
    });

    test(
        'readFuelRateLPerHour returns null when neither PID 5E nor MAF '
        'are supported', () async {
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
      });
      expect(await service.readFuelRateLPerHour(), isNull);
    });

    test('readMafGramsPerSecond parses PID 10', () async {
      final service = await _connected({'0110': '41 10 04 00>'});
      expect(await service.readMafGramsPerSecond(), closeTo(10.24, 0.01));
    });

    test('readFuelLevelPercent parses PID 2F', () async {
      final service = await _connected({'012F': '41 2F 80>'});
      expect(await service.readFuelLevelPercent(), closeTo(50.2, 0.1));
    });

    test('every new reader returns null when the transport is disconnected',
        () async {
      final service = await _connected({});
      await service.disconnect();
      expect(await service.readEngineLoad(), isNull);
      expect(await service.readThrottlePercent(), isNull);
      expect(await service.readFuelRateLPerHour(), isNull);
      expect(await service.readMafGramsPerSecond(), isNull);
      expect(await service.readFuelLevelPercent(), isNull);
    });
  });

  group('Obd2Service', () {
    test('connect initializes ELM327 adapter', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
      });
      final service = Obd2Service(transport);

      final connected = await service.connect();

      expect(connected, isTrue);
      expect(service.isConnected, isTrue);
    });

    test('readOdometerKm returns odometer from PID A6', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 12 D6 87>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm();

      expect(km, closeTo(123456.7, 0.1));
    });

    test('readOdometerKm falls back to PID 31 when A6 not supported',
        () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': 'NO DATA>',
        '0131': '41 31 4E 20>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final km = await service.readOdometerKm();

      expect(km, 20000.0);
    });

    test('readOdometerKm returns null when not connected', () async {
      final transport = FakeObd2Transport();
      final service = Obd2Service(transport);

      final km = await service.readOdometerKm();

      expect(km, isNull);
    });

    test('readSpeedKmh returns current speed', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '010D': '41 0D 50>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final speed = await service.readSpeedKmh();

      expect(speed, 80);
    });

    test('readRpm returns engine RPM', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '010C': '41 0C 0F A0>',
      });
      final service = Obd2Service(transport);
      await service.connect();

      final rpm = await service.readRpm();

      expect(rpm, closeTo(1000, 0.5));
    });

    test('disconnect works', () async {
      final transport = FakeObd2Transport({
        'ATZ': 'OK>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
      });
      final service = Obd2Service(transport);
      await service.connect();
      expect(service.isConnected, isTrue);

      await service.disconnect();
      expect(service.isConnected, isFalse);
    });
  });
}
