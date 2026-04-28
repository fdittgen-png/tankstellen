import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_parsers.dart';

/// Pure-logic coverage for [Elm327Parsers] — every public static parser
/// for Mode 01, Mode 09 (VIN) and Mode 22 manufacturer odometers. Refs
/// #561.
void main() {
  group('cleanResponse', () {
    test('empty string returns null', () {
      expect(Elm327Parsers.cleanResponse(''), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(Elm327Parsers.cleanResponse('   \r\n  '), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.cleanResponse('NO DATA'), isNull);
    });

    test('UNABLE TO CONNECT returns null', () {
      expect(Elm327Parsers.cleanResponse('UNABLE TO CONNECT'), isNull);
    });

    test('ERROR returns null', () {
      expect(Elm327Parsers.cleanResponse('ERROR'), isNull);
    });

    test('? returns null', () {
      expect(Elm327Parsers.cleanResponse('?'), isNull);
    });

    test('strips > prompt and \\r\\n whitespace', () {
      expect(
        Elm327Parsers.cleanResponse('41 0D FF\r\n>'),
        '41 0D FF',
      );
    });

    test('anchors to first 41 (drops command echo)', () {
      // Echo "01 0D" precedes the response "41 0D FF".
      expect(
        Elm327Parsers.cleanResponse('01 0D 41 0D FF'),
        '41 0D FF',
      );
    });

    test('returns cleaned string when no 41 echo present', () {
      // No "41" anywhere — caller still gets the cleaned string back.
      expect(
        Elm327Parsers.cleanResponse('00 0B FF'),
        '00 0B FF',
      );
    });

    test('NO DATA inside surrounding whitespace returns null', () {
      expect(Elm327Parsers.cleanResponse('  NO DATA  >'), isNull);
    });
  });

  group('cleanResponse22', () {
    test('empty string returns null', () {
      expect(Elm327Parsers.cleanResponse22(''), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.cleanResponse22('NO DATA'), isNull);
    });

    test('UNABLE TO CONNECT returns null', () {
      expect(Elm327Parsers.cleanResponse22('UNABLE TO CONNECT'), isNull);
    });

    test('ERROR returns null', () {
      expect(Elm327Parsers.cleanResponse22('ERROR'), isNull);
    });

    test('? returns null', () {
      expect(Elm327Parsers.cleanResponse22('?'), isNull);
    });

    test('anchors to 62 (drops Mode 22 command echo)', () {
      expect(
        Elm327Parsers.cleanResponse22('22 22 03 62 22 03 00 27 10'),
        '62 22 03 00 27 10',
      );
    });

    test('returns cleaned string when no 62 echo present', () {
      expect(
        Elm327Parsers.cleanResponse22('00 0B FF'),
        '00 0B FF',
      );
    });

    test('strips > prompt', () {
      expect(
        Elm327Parsers.cleanResponse22('62 F1 5B 00 64\r\n>'),
        '62 F1 5B 00 64',
      );
    });
  });

  group('parseVehicleSpeed (PID 0D)', () {
    test('happy path: 41 0D FF -> 255 km/h', () {
      expect(Elm327Parsers.parseVehicleSpeed('41 0D FF'), 255);
    });

    test('happy path: 41 0D 50 -> 80 km/h', () {
      expect(Elm327Parsers.parseVehicleSpeed('41 0D 50'), 80);
    });

    test('zero speed: 41 0D 00 -> 0', () {
      expect(Elm327Parsers.parseVehicleSpeed('41 0D 00'), 0);
    });

    test('wrong PID echo (0C) returns null', () {
      expect(Elm327Parsers.parseVehicleSpeed('41 0C 50'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseVehicleSpeed('41 0D'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseVehicleSpeed('NO DATA'), isNull);
    });
  });

  group('parseEngineRpm (PID 0C)', () {
    test('41 0C 1A F8 -> 1726.0', () {
      // (0x1A * 256 + 0xF8) / 4 = (26*256 + 248) / 4 = 6904/4 = 1726.0
      expect(Elm327Parsers.parseEngineRpm('41 0C 1A F8'), 1726.0);
    });

    test('41 0C 00 00 -> 0.0', () {
      expect(Elm327Parsers.parseEngineRpm('41 0C 00 00'), 0.0);
    });

    test('41 0C FF FF -> 16383.75', () {
      expect(Elm327Parsers.parseEngineRpm('41 0C FF FF'), 16383.75);
    });

    test('wrong PID echo (0D) returns null', () {
      expect(Elm327Parsers.parseEngineRpm('41 0D 1A F8'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseEngineRpm('41 0C 1A'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseEngineRpm('NO DATA'), isNull);
    });
  });

  group('parseDistanceSinceDtcCleared (PID 31)', () {
    test('41 31 01 00 -> 256 km', () {
      expect(Elm327Parsers.parseDistanceSinceDtcCleared('41 31 01 00'), 256);
    });

    test('41 31 00 64 -> 100 km', () {
      expect(Elm327Parsers.parseDistanceSinceDtcCleared('41 31 00 64'), 100);
    });

    test('41 31 FF FF -> 65535 km', () {
      expect(
        Elm327Parsers.parseDistanceSinceDtcCleared('41 31 FF FF'),
        65535,
      );
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseDistanceSinceDtcCleared('41 0D 01 00'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseDistanceSinceDtcCleared('41 31 01'), isNull);
    });
  });

  group('parseOdometer (PID A6)', () {
    test('41 A6 00 01 86 A0 -> 10000.0 km', () {
      // 0x000186A0 = 100000; / 10 = 10000.0
      expect(
        Elm327Parsers.parseOdometer('41 A6 00 01 86 A0'),
        10000.0,
      );
    });

    test('41 A6 00 00 00 00 -> 0.0 km', () {
      expect(Elm327Parsers.parseOdometer('41 A6 00 00 00 00'), 0.0);
    });

    test('41 A6 FF FF FF FF -> 429496729.5 km', () {
      // 0xFFFFFFFF = 4294967295; / 10 = 429496729.5
      expect(
        Elm327Parsers.parseOdometer('41 A6 FF FF FF FF'),
        429496729.5,
      );
    });

    test('5-byte response (too short) returns null', () {
      expect(Elm327Parsers.parseOdometer('41 A6 00 01 86'), isNull);
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseOdometer('41 0D 00 01 86 A0'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseOdometer('NO DATA'), isNull);
    });
  });

  group('parseEngineLoad (PID 04)', () {
    test('41 04 FF -> 100%', () {
      expect(
        Elm327Parsers.parseEngineLoad('41 04 FF'),
        closeTo(100.0, 0.01),
      );
    });

    test('41 04 00 -> 0%', () {
      expect(Elm327Parsers.parseEngineLoad('41 04 00'), 0.0);
    });

    test('41 04 80 -> ~50.196%', () {
      // 128 * 100 / 255 ≈ 50.196
      expect(
        Elm327Parsers.parseEngineLoad('41 04 80'),
        closeTo(50.196, 0.01),
      );
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseEngineLoad('41 11 80'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseEngineLoad('41 04'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseEngineLoad('NO DATA'), isNull);
    });
  });

  group('parseThrottlePercent (PID 11)', () {
    test('41 11 FF -> 100%', () {
      expect(
        Elm327Parsers.parseThrottlePercent('41 11 FF'),
        closeTo(100.0, 0.01),
      );
    });

    test('41 11 33 -> ~20%', () {
      // 51 * 100 / 255 = 20.0
      expect(
        Elm327Parsers.parseThrottlePercent('41 11 33'),
        closeTo(20.0, 0.01),
      );
    });

    test('wrong PID (04) returns null', () {
      expect(Elm327Parsers.parseThrottlePercent('41 04 FF'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseThrottlePercent('41 11'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseThrottlePercent('NO DATA'), isNull);
    });
  });

  group('parseFuelLevelPercent (PID 2F)', () {
    test('41 2F FF -> 100%', () {
      expect(
        Elm327Parsers.parseFuelLevelPercent('41 2F FF'),
        closeTo(100.0, 0.01),
      );
    });

    test('41 2F 80 -> ~50.196%', () {
      expect(
        Elm327Parsers.parseFuelLevelPercent('41 2F 80'),
        closeTo(50.196, 0.01),
      );
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseFuelLevelPercent('41 04 80'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseFuelLevelPercent('41 2F'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseFuelLevelPercent('NO DATA'), isNull);
    });
  });

  group('parseManifoldPressureKpa (PID 0B)', () {
    test('41 0B 64 -> 100 kPa', () {
      expect(
        Elm327Parsers.parseManifoldPressureKpa('41 0B 64'),
        100.0,
      );
    });

    test('41 0B 00 -> 0 kPa', () {
      expect(Elm327Parsers.parseManifoldPressureKpa('41 0B 00'), 0.0);
    });

    test('41 0B FF -> 255 kPa', () {
      expect(Elm327Parsers.parseManifoldPressureKpa('41 0B FF'), 255.0);
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseManifoldPressureKpa('41 0F 64'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseManifoldPressureKpa('41 0B'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseManifoldPressureKpa('NO DATA'), isNull);
    });
  });

  group('parseIntakeAirTempCelsius (PID 0F)', () {
    test('41 0F 28 -> 0 °C (40 - 40)', () {
      expect(
        Elm327Parsers.parseIntakeAirTempCelsius('41 0F 28'),
        0.0,
      );
    });

    test('41 0F 00 -> -40 °C', () {
      expect(
        Elm327Parsers.parseIntakeAirTempCelsius('41 0F 00'),
        -40.0,
      );
    });

    test('41 0F FF -> 215 °C', () {
      expect(
        Elm327Parsers.parseIntakeAirTempCelsius('41 0F FF'),
        215.0,
      );
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseIntakeAirTempCelsius('41 0B 28'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseIntakeAirTempCelsius('41 0F'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseIntakeAirTempCelsius('NO DATA'), isNull);
    });
  });

  group('parseCoolantTempCelsius (PID 05) — #1262', () {
    test('41 05 28 -> 0 °C (40 - 40)', () {
      // Same °C = A − 40 encoding as IAT (PID 0F).
      expect(
        Elm327Parsers.parseCoolantTempCelsius('41 05 28'),
        0.0,
      );
    });

    test('41 05 00 -> -40 °C (sensor minimum)', () {
      expect(
        Elm327Parsers.parseCoolantTempCelsius('41 05 00'),
        -40.0,
      );
    });

    test('41 05 78 -> 80 °C (typical operating temperature)', () {
      // 0x78 = 120 → 120 − 40 = 80 °C — the cold-start surcharge
      // heuristic uses ~80 °C as the "warm" threshold.
      expect(
        Elm327Parsers.parseCoolantTempCelsius('41 05 78'),
        80.0,
      );
    });

    test('41 05 FF -> 215 °C (sensor maximum)', () {
      expect(
        Elm327Parsers.parseCoolantTempCelsius('41 05 FF'),
        215.0,
      );
    });

    test('wrong PID echo (0F) returns null — PID isolation from IAT', () {
      // Important: parseCoolantTempCelsius must NOT decode PID 0F (IAT)
      // even though the formula is identical — otherwise a missing
      // coolant PID would silently masquerade as IAT data.
      expect(Elm327Parsers.parseCoolantTempCelsius('41 0F 28'), isNull);
    });

    test('wrong PID echo (04) returns null', () {
      expect(Elm327Parsers.parseCoolantTempCelsius('41 04 28'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseCoolantTempCelsius('41 05'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseCoolantTempCelsius('NO DATA'), isNull);
    });
  });

  group('parseFuelRateLPerHour (PID 5E)', () {
    test('41 5E 00 64 -> 5.0 L/h', () {
      // (0*256 + 100) * 0.05 = 5.0
      expect(
        Elm327Parsers.parseFuelRateLPerHour('41 5E 00 64'),
        closeTo(5.0, 0.001),
      );
    });

    test('41 5E 00 00 -> 0.0 L/h', () {
      expect(Elm327Parsers.parseFuelRateLPerHour('41 5E 00 00'), 0.0);
    });

    test('41 5E 01 00 -> 12.8 L/h', () {
      expect(
        Elm327Parsers.parseFuelRateLPerHour('41 5E 01 00'),
        closeTo(12.8, 0.001),
      );
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseFuelRateLPerHour('41 0D 00 64'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseFuelRateLPerHour('41 5E 00'), isNull);
    });
  });

  group('parseMafGramsPerSecond (PID 10)', () {
    test('41 10 03 E8 -> 10.0 g/s', () {
      // (3*256 + 232) * 0.01 = 1000 * 0.01 = 10.0
      expect(
        Elm327Parsers.parseMafGramsPerSecond('41 10 03 E8'),
        closeTo(10.0, 0.001),
      );
    });

    test('41 10 00 00 -> 0.0', () {
      expect(Elm327Parsers.parseMafGramsPerSecond('41 10 00 00'), 0.0);
    });

    test('41 10 00 64 -> 1.0 g/s', () {
      expect(
        Elm327Parsers.parseMafGramsPerSecond('41 10 00 64'),
        closeTo(1.0, 0.001),
      );
    });

    test('wrong PID returns null', () {
      expect(Elm327Parsers.parseMafGramsPerSecond('41 11 03 E8'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseMafGramsPerSecond('41 10 03'), isNull);
    });
  });

  group('parseShortTermFuelTrim (PID 06)', () {
    test('41 06 80 -> 0% (stoichiometric)', () {
      expect(
        Elm327Parsers.parseShortTermFuelTrim('41 06 80'),
        closeTo(0.0, 0.0001),
      );
    });

    test('41 06 00 -> -100%', () {
      expect(
        Elm327Parsers.parseShortTermFuelTrim('41 06 00'),
        closeTo(-100.0, 0.0001),
      );
    });

    test('41 06 FF -> ~99.21875%', () {
      // (255-128)*100/128 = 127*100/128 = 99.21875
      expect(
        Elm327Parsers.parseShortTermFuelTrim('41 06 FF'),
        closeTo(99.21875, 0.0001),
      );
    });

    test('wrong PID (07) returns null — PID echo isolation', () {
      // Important: PID 06 parser should not decode a PID 07 response.
      expect(Elm327Parsers.parseShortTermFuelTrim('41 07 80'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseShortTermFuelTrim('41 06'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseShortTermFuelTrim('NO DATA'), isNull);
    });
  });

  group('parseLongTermFuelTrim (PID 07)', () {
    test('41 07 80 -> 0% (stoichiometric)', () {
      expect(
        Elm327Parsers.parseLongTermFuelTrim('41 07 80'),
        closeTo(0.0, 0.0001),
      );
    });

    test('41 07 90 -> ~12.5%', () {
      // (144-128)*100/128 = 16*100/128 = 12.5
      expect(
        Elm327Parsers.parseLongTermFuelTrim('41 07 90'),
        closeTo(12.5, 0.0001),
      );
    });

    test('wrong PID (06) returns null — PID echo isolation', () {
      // Important: PID 07 parser should not decode a PID 06 response.
      expect(Elm327Parsers.parseLongTermFuelTrim('41 06 80'), isNull);
    });

    test('short response returns null', () {
      expect(Elm327Parsers.parseLongTermFuelTrim('41 07'), isNull);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseLongTermFuelTrim('NO DATA'), isNull);
    });
  });

  group('parseSupportedPidsBitmap (PID 00 group)', () {
    test('41 00 BE 1F A8 13 -> expected PID set', () {
      // Byte 0 = 0xBE = 1011 1110 -> bits set at MSB indices 0,2,3,4,5,6
      //   -> PIDs {1, 3, 4, 5, 6, 7}
      // Byte 1 = 0x1F = 0001 1111 -> bits 11,12,13,14,15
      //   -> PIDs {12, 13, 14, 15, 16}
      // Byte 2 = 0xA8 = 1010 1000 -> bits 16,18,20
      //   -> PIDs {17, 19, 21}
      // Byte 3 = 0x13 = 0001 0011 -> bits 27,30,31
      //   -> PIDs {28, 31, 32}
      final supported =
          Elm327Parsers.parseSupportedPidsBitmap('41 00 BE 1F A8 13', 0x00);
      expect(supported, isNotNull);
      expect(
        supported,
        equals({1, 3, 4, 5, 6, 7, 12, 13, 14, 15, 16, 17, 19, 21, 28, 31, 32}),
      );
    });

    test('all-zero bitmap returns empty Set', () {
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('41 00 00 00 00 00', 0x00),
        isEmpty,
      );
    });

    test('all-one bitmap (FF FF FF FF) returns all 32 PIDs (1-32)', () {
      final supported =
          Elm327Parsers.parseSupportedPidsBitmap('41 00 FF FF FF FF', 0x00);
      expect(supported, isNotNull);
      expect(supported!.length, 32);
      expect(supported, equals({for (var i = 1; i <= 32; i++) i}));
    });

    test('MSB of byte 0 maps to PID groupBase+1 (only bit 31 set)', () {
      // 0x80 0x00 0x00 0x00 - only the highest bit is set.
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('41 00 80 00 00 00', 0x00),
        equals({1}),
      );
    });

    test('LSB of byte 3 maps to PID groupBase+32 (only bit 0 set)', () {
      // 0x00 0x00 0x00 0x01 - only the lowest bit is set.
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('41 00 00 00 00 01', 0x00),
        equals({32}),
      );
    });

    test('groupBase 0x20 maps bits to PIDs 33-64', () {
      // Only the MSB of byte 0 set -> PID 33 (groupBase+1 = 0x20+1 = 33).
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('41 20 80 00 00 00', 0x20),
        equals({0x21}),
      );
    });

    test('short response returns null', () {
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('41 00 BE 1F', 0x00),
        isNull,
      );
    });

    test('wrong PID echo returns null', () {
      // groupBase 0x20 expected, but response shows PID 00.
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('41 00 BE 1F A8 13', 0x20),
        isNull,
      );
    });

    test('NO DATA returns null', () {
      expect(
        Elm327Parsers.parseSupportedPidsBitmap('NO DATA', 0x00),
        isNull,
      );
    });
  });

  group('parseMfgOdometer3Byte', () {
    test('62 22 03 00 27 10 -> 10000.0 km (VW group)', () {
      // 0x002710 = 10000.
      expect(
        Elm327Parsers.parseMfgOdometer3Byte(
          '62 22 03 00 27 10',
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        10000.0,
      );
    });

    test('62 22 03 FF FF FF -> 16777215.0 km', () {
      expect(
        Elm327Parsers.parseMfgOdometer3Byte(
          '62 22 03 FF FF FF',
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        16777215.0,
      );
    });

    test('wrong PID-Hi returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometer3Byte(
          '62 22 03 00 27 10',
          expectedPidHi: 0x30,
          expectedPidLo: 0x03,
        ),
        isNull,
      );
    });

    test('wrong PID-Lo returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometer3Byte(
          '62 22 03 00 27 10',
          expectedPidHi: 0x22,
          expectedPidLo: 0x99,
        ),
        isNull,
      );
    });

    test('short response returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometer3Byte(
          '62 22 03 00 27',
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        isNull,
      );
    });

    test('NO DATA returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometer3Byte(
          'NO DATA',
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        isNull,
      );
    });
  });

  group('parseMfgOdometer2Byte', () {
    test('62 F1 5B 00 64 -> 100.0 km (Mercedes)', () {
      expect(
        Elm327Parsers.parseMfgOdometer2Byte(
          '62 F1 5B 00 64',
          expectedPidHi: 0xF1,
          expectedPidLo: 0x5B,
        ),
        100.0,
      );
    });

    test('62 D1 01 FF FF -> 65535.0 km (PSA)', () {
      expect(
        Elm327Parsers.parseMfgOdometer2Byte(
          '62 D1 01 FF FF',
          expectedPidHi: 0xD1,
          expectedPidLo: 0x01,
        ),
        65535.0,
      );
    });

    test('wrong PID returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometer2Byte(
          '62 F1 5B 00 64',
          expectedPidHi: 0xF1,
          expectedPidLo: 0x99,
        ),
        isNull,
      );
    });

    test('short response returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometer2Byte(
          '62 F1 5B 00',
          expectedPidHi: 0xF1,
          expectedPidLo: 0x5B,
        ),
        isNull,
      );
    });
  });

  group('parseMfgOdometerMilesTimes10', () {
    test('62 40 4D 00 64 -> ~16.09344 km (Ford-style miles*10)', () {
      // (0x0064 = 100) / 10 * 1.609344 = 10 mi * 1.609344 = 16.09344 km
      final result = Elm327Parsers.parseMfgOdometerMilesTimes10(
        '62 40 4D 00 64',
        expectedPidHi: 0x40,
        expectedPidLo: 0x4D,
      );
      expect(result, isNotNull);
      expect(result!, closeTo(16.09344, 0.0001));
    });

    test('zero -> 0.0 km', () {
      expect(
        Elm327Parsers.parseMfgOdometerMilesTimes10(
          '62 40 4D 00 00',
          expectedPidHi: 0x40,
          expectedPidLo: 0x4D,
        ),
        0.0,
      );
    });

    test('wrong PID returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometerMilesTimes10(
          '62 40 4D 00 64',
          expectedPidHi: 0xAA,
          expectedPidLo: 0x4D,
        ),
        isNull,
      );
    });

    test('short response returns null', () {
      expect(
        Elm327Parsers.parseMfgOdometerMilesTimes10(
          '62 40 4D 00',
          expectedPidHi: 0x40,
          expectedPidLo: 0x4D,
        ),
        isNull,
      );
    });
  });

  group('parseVin (Mode 09 PID 02)', () {
    /// Helper: encode an ASCII string as space-separated hex bytes.
    String hex(String s) => s.codeUnits
        .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');

    test('5-frame VIN response decodes to last 17 ASCII chars', () {
      // Build a realistic Mode 09 PID 02 multi-frame response. Each
      // frame begins with header "49 02 NN" — 0x49 ('I') is excluded
      // by VIN rules, 0x02 is non-printable, and frame counters
      // (0x01-0x05) are also outside the printable ranges, so all
      // header bytes are dropped. The 17 valid characters that remain
      // are the VIN itself.
      const vin = 'WVWZZZ1KZ8W123456';
      final body = hex(vin);
      final concatenated =
          '49 02 01 $body 49 02 02 49 02 03 49 02 04 49 02 05';
      expect(Elm327Parsers.parseVin(concatenated), vin);
    });

    test("'I'/'O'/'Q' bytes are skipped per VIN rules", () {
      // VIN rules forbid I/O/Q. Verify the parser strips them even
      // when interleaved with valid chars *after* the cleanResponse
      // anchor (so they aren't stripped by the upstream cleaner).
      // Pattern: 17 valid chars + interleaved 0x49 'I', 0x4F 'O',
      // 0x51 'Q' — result must be the original 17 VIN chars.
      const vin = 'ABCDEFGHJKLMNPRST'; // 17 chars, no I/O/Q
      final body = hex(vin);
      // Append junk I/O/Q after the body — they must be filtered out
      // so the last-17 slice still equals the VIN.
      final response = '$body 49 4F 51';
      expect(Elm327Parsers.parseVin(response), vin);
    });

    test('< 17 valid chars returns null', () {
      // Only 5 valid VIN chars after stripping headers/padding.
      expect(Elm327Parsers.parseVin('49 02 01 41 42 43 44 45'), isNull);
    });

    test('non-alphanumeric bytes are skipped', () {
      // Inject 0x20 (space — won't survive split), 0x40 (@ — invalid),
      // 0x4F ('O' — VIN forbidden), 0x51 ('Q' — VIN forbidden) among
      // the 17 valid chars. Result must still be the 17-char VIN.
      const vin = '12345678901234567';
      final body = hex(vin);
      // Sprinkle invalid bytes between header and body.
      final raw = '49 02 01 40 4F 51 $body';
      expect(Elm327Parsers.parseVin(raw), vin);
    });

    test('NO DATA returns null', () {
      expect(Elm327Parsers.parseVin('NO DATA'), isNull);
    });

    test('returns LAST 17 chars when more than 17 valid chars present', () {
      // 20 valid chars - parser keeps the trailing 17.
      const tail = 'WVWZZZ1KZ8W123456';
      final extraThenVin = hex('AAA$tail');
      expect(Elm327Parsers.parseVin(extraThenVin), tail);
    });
  });
}
