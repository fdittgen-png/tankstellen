import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// Manufacturer-specific odometer fallback (#719).
///
/// SAE J1979's standard PID A6 only appears on cars from ~2018+.
/// Everything older exposes odometer through Mode 22 OEM-specific
/// PIDs. VIN prefix → brand → command table.

const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

Future<Obd2Service> _service(Map<String, String> extra) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport);
  await service.connect();
  return service;
}

void main() {
  group('Elm327Protocol manufacturer odometer parsers (#719)', () {
    test('parseMfgOdometer3Byte for VW group (22 22 03) at 123 456 km', () {
      // 123456 = 0x01E240 → bytes [0x01, 0xE2, 0x40].
      // Response: 62 22 03 01 E2 40
      expect(
        Elm327Protocol.parseMfgOdometer3Byte(
          '62 22 03 01 E2 40>',
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        closeTo(123456, 0.5),
      );
    });

    test('parseMfgOdometer3Byte for BMW (22 30 16)', () {
      expect(
        Elm327Protocol.parseMfgOdometer3Byte(
          '62 30 16 00 10 00>',
          expectedPidHi: 0x30,
          expectedPidLo: 0x16,
        ),
        closeTo(4096, 0.5),
      );
    });

    test('parseMfgOdometer2Byte for Mercedes (22 F1 5B)', () {
      // 2-byte PID response: 62 F1 5B XX YY → km = (XX*256)+YY
      expect(
        Elm327Protocol.parseMfgOdometer2Byte(
          '62 F1 5B 12 34>',
          expectedPidHi: 0xF1,
          expectedPidLo: 0x5B,
        ),
        closeTo(4660, 0.5),
      );
    });

    test('parseMfgOdometerMilesTimes10 for Ford (22 40 4D)', () {
      // Ford 0x404D returns miles × 10 → convert to km
      // 10000 → 1000 miles → 1609.344 km
      expect(
        Elm327Protocol.parseMfgOdometerMilesTimes10(
          '62 40 4D 27 10>', // 0x2710 = 10000
          expectedPidHi: 0x40,
          expectedPidLo: 0x4D,
        ),
        closeTo(1609.344, 0.5),
      );
    });

    test('returns null on NO DATA for every parser', () {
      expect(
        Elm327Protocol.parseMfgOdometer3Byte(
          'NO DATA>',
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        isNull,
      );
      expect(
        Elm327Protocol.parseMfgOdometer2Byte(
          'NO DATA>',
          expectedPidHi: 0xF1,
          expectedPidLo: 0x5B,
        ),
        isNull,
      );
      expect(
        Elm327Protocol.parseMfgOdometerMilesTimes10(
          'NO DATA>',
          expectedPidHi: 0x40,
          expectedPidLo: 0x4D,
        ),
        isNull,
      );
    });

    test('rejects a response where the PID echo does not match', () {
      expect(
        Elm327Protocol.parseMfgOdometer3Byte(
          '62 22 04 01 E2 40>', // PID-lo is 04, not 03
          expectedPidHi: 0x22,
          expectedPidLo: 0x03,
        ),
        isNull,
      );
    });
  });

  group('Obd2Service.readOdometerKm fallback chain (#719)', () {
    test(
        'falls back through manufacturer PID when A6 + 31 both return '
        'NO DATA and VIN matches VW group', () async {
      final service = await _service({
        '01A6': 'NO DATA>',
        '0131': 'NO DATA>',
        '0902':
            // Mode 09 PID 02 = VIN. Encodes "WVWZZZ1JZ3W386752"
            // across 5 × 7-byte frames with the "49 02 NN" header
            // ELM327 emits on multi-line responses. parseVin filters
            // headers ('I' / 0x49) + padding out and returns the last
            // 17 printable chars.
            '49 02 01 00 57 56 57 '
                '49 02 02 5A 5A 5A 31 '
                '49 02 03 4A 5A 33 57 '
                '49 02 04 33 38 36 37 '
                '49 02 05 35 32 00 00 >',
        '222203': '62 22 03 01 E2 40>', // 123 456 km
      });
      final km = await service.readOdometerKm();
      expect(km, closeTo(123456, 0.5));
    });

    test(
        'returns null when A6 + 31 + every manufacturer candidate return '
        'NO DATA', () async {
      final service = await _service({
        '01A6': 'NO DATA>',
        '0131': 'NO DATA>',
        '0902': 'NO DATA>',
        // No 22xxxx entries; FakeObd2Transport returns NO DATA by
        // default for unknown commands.
      });
      expect(await service.readOdometerKm(), isNull);
    });
  });
}
