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
        'are supported AND the speed-density PIDs also fail', () async {
      // All three fallback tiers unsupported → final null. No change
      // to this contract after #800 added step 3 — only the path to
      // null grew an extra branch.
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': 'NO DATA>',
        '010F': 'NO DATA>',
        '010C': 'NO DATA>',
      });
      expect(await service.readFuelRateLPerHour(), isNull);
    });

    test(
        'readFuelRateLPerHour falls back to speed-density (MAP+IAT+RPM) '
        'when neither PID 5E nor MAF are supported — #800 Peugeot 107 path',
        () async {
      // Peugeot 107 1.0L 1KR-FE ground truth: no 5E, no MAF, but MAP
      // + IAT + RPM all present. At idle (RPM 800, MAP 40 kPa, IAT
      // 25 °C) the speed-density estimate should land in a plausible
      // range around 0.5–1.5 L/h — not null, not zero, not insane.
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 28>', // MAP = 40 kPa (idle vacuum)
        '010F': '41 0F 41>', // IAT = 25 °C (raw 0x41 = 65, 65−40 = 25)
        '010C': '41 0C 0C 80>', // RPM = ((12×256)+128)/4 = 800
      });
      final rate = await service.readFuelRateLPerHour();
      expect(rate, isNotNull);
      expect(rate, greaterThan(0.2));
      expect(rate, lessThan(3.0));
    });

    test(
        'readFuelRateLPerHour speed-density step returns null when any '
        'of MAP/IAT/RPM is missing — all three required', () async {
      // MAP present but IAT missing → step 3 bails out rather than
      // making up a temperature. Callers see the honest null and the
      // trip summary shows "—".
      final service = await _connected({
        '015E': 'NO DATA>',
        '0110': 'NO DATA>',
        '010B': '41 0B 40>',
        '010F': 'NO DATA>',
        '010C': '41 0C 0C 80>',
      });
      expect(await service.readFuelRateLPerHour(), isNull);
    });

    test('readManifoldPressureKpa parses PID 0B', () async {
      final service = await _connected({'010B': '41 0B 64>'});
      expect(await service.readManifoldPressureKpa(), closeTo(100.0, 0.01));
    });

    test('readIntakeAirTempCelsius parses PID 0F', () async {
      final service = await _connected({'010F': '41 0F 3C>'});
      expect(
        await service.readIntakeAirTempCelsius(),
        closeTo(20.0, 0.01),
      );
    });

    group('estimateFuelRateLPerHourFromMap — #800 speed-density math', () {
      test('typical Peugeot 107 cruise: 2500 RPM, 65 kPa, 30 °C → '
          '~3–5 L/h (plausible cruise consumption)', () {
        final rate = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: 65,
          iatCelsius: 30,
          rpm: 2500,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        );
        expect(rate, isNotNull);
        expect(rate, greaterThan(2.5));
        expect(rate, lessThan(6.0));
      });

      test('returns null when any input is non-positive', () {
        expect(
          Obd2Service.estimateFuelRateLPerHourFromMap(
            mapKpa: 0, // can't have 0 kPa physically
            iatCelsius: 25,
            rpm: 800,
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
          ),
          isNull,
        );
        expect(
          Obd2Service.estimateFuelRateLPerHourFromMap(
            mapKpa: 40,
            iatCelsius: -273.15, // 0 K — breaks ideal gas law
            rpm: 800,
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
          ),
          isNull,
        );
        expect(
          Obd2Service.estimateFuelRateLPerHourFromMap(
            mapKpa: 40,
            iatCelsius: 25,
            rpm: 0, // engine off
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
          ),
          isNull,
        );
      });

      test('scales linearly with displacement (2.0 L burns 2× the fuel '
          'of a 1.0 L at the same operating point)', () {
        final small = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: 50,
          iatCelsius: 20,
          rpm: 2000,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        )!;
        final big = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: 50,
          iatCelsius: 20,
          rpm: 2000,
          engineDisplacementCc: 2000,
          volumetricEfficiency: 0.85,
        )!;
        expect(big / small, closeTo(2.0, 0.01));
      });

      test('matches the stoichiometric MAF path on the same underlying '
          'air-mass flow — formulas agree when given equivalent inputs', () {
        // Hand-compute the air mass flow for known inputs, then verify
        // both the speed-density method and the MAF-based formula
        // agree on the resulting fuel rate.
        const mapKpa = 100.0;
        const iatCelsius = 25.0;
        const rpm = 3000.0;
        const displacementCc = 1000;
        const ve = 0.85;
        const r = 287.0;
        const iatK = iatCelsius + 273.15;
        const displacementM3 = displacementCc / 1_000_000.0;
        const airKgPerS = (mapKpa * 1000 * displacementM3 * (rpm / 120) * ve) /
            (r * iatK);
        const airGPerS = airKgPerS * 1000;
        const expectedFromMaf = airGPerS * 3600 / (14.7 * 740);
        final fromMap = Obd2Service.estimateFuelRateLPerHourFromMap(
          mapKpa: mapKpa,
          iatCelsius: iatCelsius,
          rpm: rpm,
          engineDisplacementCc: displacementCc,
          volumetricEfficiency: ve,
        )!;
        expect(fromMap, closeTo(expectedFromMaf, 0.001));
      });
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
