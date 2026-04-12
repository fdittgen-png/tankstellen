import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';

void main() {
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
