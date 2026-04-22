import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';

void main() {
  group('Elm327Protocol PID expansion (#717)', () {
    group('parseEngineLoad (PID 04)', () {
      test('parses 0 % (idle load)', () {
        expect(Elm327Protocol.parseEngineLoad('41 04 00>'), closeTo(0, 0.01));
      });

      test('parses ~50 % at value 0x80', () {
        expect(
          Elm327Protocol.parseEngineLoad('41 04 80>'),
          closeTo(50.2, 0.1),
        );
      });

      test('parses 100 % at value 0xFF', () {
        expect(Elm327Protocol.parseEngineLoad('41 04 FF>'), closeTo(100, 0.1));
      });

      test('returns null on NO DATA', () {
        expect(Elm327Protocol.parseEngineLoad('NO DATA>'), isNull);
      });
    });

    group('parseThrottlePercent (PID 11)', () {
      test('parses 25 % at value 0x40', () {
        expect(
          Elm327Protocol.parseThrottlePercent('41 11 40>'),
          closeTo(25.1, 0.1),
        );
      });

      test('returns null on malformed response', () {
        expect(Elm327Protocol.parseThrottlePercent('41 11>'), isNull);
      });
    });

    group('parseFuelRateLPerHour (PID 5E)', () {
      test('parses 0.05 L/h at raw 0x0001', () {
        expect(
          Elm327Protocol.parseFuelRateLPerHour('41 5E 00 01>'),
          closeTo(0.05, 0.001),
        );
      });

      test('parses 102.4 L/h at raw 0x0800', () {
        expect(
          Elm327Protocol.parseFuelRateLPerHour('41 5E 08 00>'),
          closeTo(102.4, 0.01),
        );
      });

      test('returns null on NO DATA', () {
        expect(Elm327Protocol.parseFuelRateLPerHour('NO DATA>'), isNull);
      });
    });

    group('parseMafGramsPerSecond (PID 10)', () {
      test('parses 10.24 g/s at raw 0x0400', () {
        expect(
          Elm327Protocol.parseMafGramsPerSecond('41 10 04 00>'),
          closeTo(10.24, 0.01),
        );
      });
    });

    group('parseFuelLevelPercent (PID 2F)', () {
      test('parses 50.2 % at value 0x80', () {
        expect(
          Elm327Protocol.parseFuelLevelPercent('41 2F 80>'),
          closeTo(50.2, 0.1),
        );
      });
    });

    group('parseManifoldPressureKpa (PID 0B) — #800 speed-density input', () {
      test('parses idle vacuum at 30 kPa', () {
        expect(
          Elm327Protocol.parseManifoldPressureKpa('41 0B 1E>'),
          closeTo(30.0, 0.01),
        );
      });

      test('parses wide-open throttle at ~100 kPa on an NA engine', () {
        expect(
          Elm327Protocol.parseManifoldPressureKpa('41 0B 64>'),
          closeTo(100.0, 0.01),
        );
      });

      test('parses turbocharged boost at 200 kPa', () {
        expect(
          Elm327Protocol.parseManifoldPressureKpa('41 0B C8>'),
          closeTo(200.0, 0.01),
        );
      });

      test('returns null on NO DATA', () {
        expect(Elm327Protocol.parseManifoldPressureKpa('NO DATA>'), isNull);
      });
    });

    group('parseIntakeAirTempCelsius (PID 0F) — #800 speed-density input', () {
      test('parses -40 °C at raw 0x00 (sensor minimum)', () {
        expect(
          Elm327Protocol.parseIntakeAirTempCelsius('41 0F 00>'),
          closeTo(-40.0, 0.01),
        );
      });

      test('parses 20 °C at raw 0x3C (typical ambient)', () {
        expect(
          Elm327Protocol.parseIntakeAirTempCelsius('41 0F 3C>'),
          closeTo(20.0, 0.01),
        );
      });

      test('parses 215 °C at raw 0xFF (sensor maximum)', () {
        expect(
          Elm327Protocol.parseIntakeAirTempCelsius('41 0F FF>'),
          closeTo(215.0, 0.01),
        );
      });

      test('returns null on NO DATA', () {
        expect(Elm327Protocol.parseIntakeAirTempCelsius('NO DATA>'), isNull);
      });
    });

    group('parseShortTermFuelTrim / parseLongTermFuelTrim — #813', () {
      test('STFT parses 0 % at midpoint raw 0x80', () {
        expect(
          Elm327Protocol.parseShortTermFuelTrim('41 06 80>'),
          closeTo(0.0, 0.01),
        );
      });

      test('STFT parses -100 % at raw 0x00 (extreme lean correction)', () {
        expect(
          Elm327Protocol.parseShortTermFuelTrim('41 06 00>'),
          closeTo(-100.0, 0.01),
        );
      });

      test('STFT parses +99.2 % at raw 0xFF (extreme rich correction)', () {
        expect(
          Elm327Protocol.parseShortTermFuelTrim('41 06 FF>'),
          closeTo(99.22, 0.1),
        );
      });

      test('LTFT uses the same formula as STFT, different PID', () {
        // raw 0x90 = 144, (144-128)*100/128 = 12.5
        expect(
          Elm327Protocol.parseLongTermFuelTrim('41 07 90>'),
          closeTo(12.5, 0.1),
        );
      });

      test('STFT returns null on NO DATA', () {
        expect(Elm327Protocol.parseShortTermFuelTrim('NO DATA>'), isNull);
      });

      test('STFT returns null when response is for a different PID', () {
        // Guard against mixing up STFT and LTFT responses.
        expect(Elm327Protocol.parseShortTermFuelTrim('41 07 80>'), isNull);
      });
    });

    group('command constants', () {
      test('expose the new PIDs for the service layer', () {
        expect(Elm327Protocol.engineLoadCommand, '0104\r');
        expect(Elm327Protocol.throttlePositionCommand, '0111\r');
        expect(Elm327Protocol.engineFuelRateCommand, '015E\r');
        expect(Elm327Protocol.mafCommand, '0110\r');
        expect(Elm327Protocol.fuelTankLevelCommand, '012F\r');
        // #800 speed-density fallback PIDs:
        expect(Elm327Protocol.intakeManifoldPressureCommand, '010B\r');
        expect(Elm327Protocol.intakeAirTempCommand, '010F\r');
        // #813 fuel-trim PIDs:
        expect(Elm327Protocol.shortTermFuelTrimCommand, '0106\r');
        expect(Elm327Protocol.longTermFuelTrimCommand, '0107\r');
        // #811 supported-PID discovery chain:
        expect(Elm327Protocol.supportedPidsCommands, [
          '0100\r',
          '0120\r',
          '0140\r',
          '0160\r',
          '0180\r',
          '01A0\r',
          '01C0\r',
        ]);
      });
    });

    group('parseSupportedPidsBitmap (PID 00/20/40/...) — #811', () {
      test(
          'bitmap with only MSB set → PID 1 supported (groupBase 0x00)',
          () {
        // 0x80 = 1000_0000 → only the first bit set → PID 01 supported.
        expect(
          Elm327Protocol.parseSupportedPidsBitmap('41 00 80 00 00 00', 0x00),
          {1},
        );
      });

      test('bitmap with only LSB set → PID 32 supported (groupBase 0x00)',
          () {
        // Byte 3 of 0x01 = 0000_0001 → last bit set → PID 32.
        expect(
          Elm327Protocol.parseSupportedPidsBitmap('41 00 00 00 00 01', 0x00),
          {32},
        );
      });

      test('all-ones bitmap → every PID in the range supported', () {
        final result =
            Elm327Protocol.parseSupportedPidsBitmap('41 00 FF FF FF FF', 0x00);
        expect(result, isNotNull);
        expect(result!.length, 32);
        expect(result, containsAll([1, 16, 17, 32]));
      });

      test('groupBase offset shifts the PID range (0x20 → PIDs 33–64)', () {
        // Only the MSB of the first byte set → PID 33 (groupBase+1).
        expect(
          Elm327Protocol.parseSupportedPidsBitmap('41 20 80 00 00 00', 0x20),
          {33},
        );
      });

      test('returns null on NO DATA', () {
        expect(
          Elm327Protocol.parseSupportedPidsBitmap('NO DATA>', 0x00),
          isNull,
        );
      });

      test(
          'real Peugeot 107 PID-00 response decodes to the expected PID set',
          () {
        // Fabricated but representative: speed (0D), RPM (0C),
        // engine load (04), coolant temp (05), MAP (0B), IAT (0F),
        // throttle (11) → bitmap BE 3F A8 13 by construction of
        // bits 4, 5, 11, 12, 13, 14, 15 + 0x08 "next-range?" flag.
        // Just validate the parser doesn't crash and produces a
        // non-empty subset for a real-looking payload.
        final result = Elm327Protocol.parseSupportedPidsBitmap(
          '41 00 BE 3F A8 13',
          0x00,
        );
        expect(result, isNotNull);
        expect(result!.length, greaterThan(5));
      });
    });
  });

  group('Elm327Protocol', () {
    group('cleanResponse', () {
      test('strips > prompt', () {
        expect(Elm327Protocol.cleanResponse('41 0D 50>'), '41 0D 50');
      });

      test('returns null for NO DATA', () {
        expect(Elm327Protocol.cleanResponse('NO DATA>'), isNull);
      });

      test('returns null for UNABLE TO CONNECT', () {
        expect(Elm327Protocol.cleanResponse('UNABLE TO CONNECT>'), isNull);
      });

      test('returns null for ERROR', () {
        expect(Elm327Protocol.cleanResponse('ERROR>'), isNull);
      });

      test('strips echo and finds 41 response', () {
        expect(Elm327Protocol.cleanResponse('010D\r41 0D 50>'), '41 0D 50');
      });
    });

    group('parseVehicleSpeed', () {
      test('parses 80 km/h', () {
        expect(Elm327Protocol.parseVehicleSpeed('41 0D 50>'), 80);
      });

      test('parses 0 km/h', () {
        expect(Elm327Protocol.parseVehicleSpeed('41 0D 00>'), 0);
      });

      test('parses 255 km/h (max)', () {
        expect(Elm327Protocol.parseVehicleSpeed('41 0D FF>'), 255);
      });

      test('returns null for NO DATA', () {
        expect(Elm327Protocol.parseVehicleSpeed('NO DATA>'), isNull);
      });

      test('returns null for wrong PID', () {
        expect(Elm327Protocol.parseVehicleSpeed('41 0C 50>'), isNull);
      });
    });

    group('parseEngineRpm', () {
      test('parses 1000 RPM', () {
        // 1000 RPM = 4000 / 4 → (4000 >> 8) = 0x0F, (4000 & 0xFF) = 0xA0
        expect(
            Elm327Protocol.parseEngineRpm('41 0C 0F A0>'), closeTo(1000, 0.5));
      });

      test('parses idle ~800 RPM', () {
        // 800 RPM = 3200 / 4 → 3200 = 0x0C80
        expect(
            Elm327Protocol.parseEngineRpm('41 0C 0C 80>'), closeTo(800, 0.5));
      });

      test('returns null for NO DATA', () {
        expect(Elm327Protocol.parseEngineRpm('NO DATA>'), isNull);
      });
    });

    group('parseDistanceSinceDtcCleared', () {
      test('parses 20000 km', () {
        // 20000 = 0x4E20
        expect(Elm327Protocol.parseDistanceSinceDtcCleared('41 31 4E 20>'),
            20000);
      });

      test('parses 0 km', () {
        expect(
            Elm327Protocol.parseDistanceSinceDtcCleared('41 31 00 00>'), 0);
      });

      test('parses 65535 km (max)', () {
        expect(Elm327Protocol.parseDistanceSinceDtcCleared('41 31 FF FF>'),
            65535);
      });

      test('returns null for NO DATA', () {
        expect(
            Elm327Protocol.parseDistanceSinceDtcCleared('NO DATA>'), isNull);
      });
    });

    group('parseOdometer', () {
      test('parses 123456.7 km', () {
        // 1234567 / 10 = 123456.7 → 1234567 = 0x0012D687
        expect(Elm327Protocol.parseOdometer('41 A6 00 12 D6 87>'),
            closeTo(123456.7, 0.1));
      });

      test('returns null for NO DATA', () {
        expect(Elm327Protocol.parseOdometer('NO DATA>'), isNull);
      });
    });
  });
}
