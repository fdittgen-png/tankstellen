import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_commands.dart';

/// Pure-logic coverage for the ELM327 command catalog and the VIN-WMI
/// brand mapping used to pick a manufacturer-specific odometer PID
/// when standard PID A6 isn't supported (#719). Refs #561.
void main() {
  group('vehicleBrandFromVin', () {
    test('null VIN returns unknown', () {
      expect(vehicleBrandFromVin(null), VehicleBrand.unknown);
    });

    test('empty VIN returns unknown', () {
      expect(vehicleBrandFromVin(''), VehicleBrand.unknown);
    });

    test('VIN shorter than 3 chars returns unknown', () {
      expect(vehicleBrandFromVin('WV'), VehicleBrand.unknown);
      expect(vehicleBrandFromVin('W'), VehicleBrand.unknown);
    });

    test('VW group: WVW prefix (Volkswagen)', () {
      expect(
        vehicleBrandFromVin('WVWZZZ1KZAW123456'),
        VehicleBrand.vwGroup,
      );
    });

    test('VW group: WAU prefix (Audi)', () {
      expect(
        vehicleBrandFromVin('WAUZZZ8K9DA123456'),
        VehicleBrand.vwGroup,
      );
    });

    test('VW group: TMB prefix (Skoda)', () {
      expect(
        vehicleBrandFromVin('TMBJF7NE0K0123456'),
        VehicleBrand.vwGroup,
      );
    });

    test('VW group: VSS prefix (Seat)', () {
      expect(
        vehicleBrandFromVin('VSSZZZ5FZAR123456'),
        VehicleBrand.vwGroup,
      );
    });

    test('VW group: 3VW prefix (VW Mexico)', () {
      expect(
        vehicleBrandFromVin('3VWFE21C04M123456'),
        VehicleBrand.vwGroup,
      );
    });

    test('BMW: WBA prefix', () {
      expect(
        vehicleBrandFromVin('WBA3A5C50DF123456'),
        VehicleBrand.bmw,
      );
    });

    test('BMW: WBS prefix (M-series)', () {
      expect(
        vehicleBrandFromVin('WBSBL93446JR12345'),
        VehicleBrand.bmw,
      );
    });

    test('BMW: WMW prefix (Mini)', () {
      expect(
        vehicleBrandFromVin('WMWXM5C5XBT123456'),
        VehicleBrand.bmw,
      );
    });

    test('Mercedes: WDB prefix', () {
      expect(
        vehicleBrandFromVin('WDB2110161A123456'),
        VehicleBrand.mercedes,
      );
    });

    test('Mercedes: WDD prefix', () {
      expect(
        vehicleBrandFromVin('WDDGF8AB5DA123456'),
        VehicleBrand.mercedes,
      );
    });

    test('Mercedes: W1K prefix (newer WMI)', () {
      expect(
        vehicleBrandFromVin('W1K2050471F123456'),
        VehicleBrand.mercedes,
      );
    });

    test('Ford: WF0 prefix (Europe)', () {
      expect(
        vehicleBrandFromVin('WF0AXXGAJA1A12345'),
        VehicleBrand.ford,
      );
    });

    test('Ford: 1FA prefix (USA)', () {
      expect(
        vehicleBrandFromVin('1FAFP55U6YA123456'),
        VehicleBrand.ford,
      );
    });

    test('Ford: 1FM prefix (USA SUV)', () {
      expect(
        vehicleBrandFromVin('1FMCU0G98EU123456'),
        VehicleBrand.ford,
      );
    });

    test('Ford: 1FT prefix (USA truck)', () {
      expect(
        vehicleBrandFromVin('1FTFW1ET5DF123456'),
        VehicleBrand.ford,
      );
    });

    test('PSA: VF3 prefix (Peugeot)', () {
      expect(
        vehicleBrandFromVin('VF3LCBHZHGS123456'),
        VehicleBrand.psa,
      );
    });

    test('PSA: VF7 prefix (Citroen)', () {
      expect(
        vehicleBrandFromVin('VF7LCBHZHGS123456'),
        VehicleBrand.psa,
      );
    });

    test('PSA: VR3 prefix (newer PSA)', () {
      expect(
        vehicleBrandFromVin('VR3UFYHZJKS123456'),
        VehicleBrand.psa,
      );
    });

    test('PSA: VX1 prefix (DS)', () {
      expect(
        vehicleBrandFromVin('VX1ZBHZHGS1234567'),
        VehicleBrand.psa,
      );
    });

    test('PSA: W0L prefix (Opel/Vauxhall)', () {
      expect(
        vehicleBrandFromVin('W0LJD7EC4DG123456'),
        VehicleBrand.psa,
      );
    });

    test('Renault: VF1 prefix', () {
      expect(
        vehicleBrandFromVin('VF1KZ0J0H40123456'),
        VehicleBrand.renault,
      );
    });

    test('Renault: VF8 prefix', () {
      expect(
        vehicleBrandFromVin('VF8MA1MFA00123456'),
        VehicleBrand.renault,
      );
    });

    test('Unknown WMI returns unknown', () {
      expect(vehicleBrandFromVin('ZZZZZZZZZZZZZZZZZ'), VehicleBrand.unknown);
      expect(vehicleBrandFromVin('JT2BG28K8X0123456'), VehicleBrand.unknown);
      expect(vehicleBrandFromVin('JHM_____________1'), VehicleBrand.unknown);
    });

    test('Lowercase VIN is normalized to uppercase before matching', () {
      expect(vehicleBrandFromVin('wvwzzz1kzaw123456'), VehicleBrand.vwGroup);
      expect(vehicleBrandFromVin('wba3a5c50df123456'), VehicleBrand.bmw);
      expect(vehicleBrandFromVin('vf1kz0j0h40123456'), VehicleBrand.renault);
    });

    test('Mixed case VIN is normalized to uppercase before matching', () {
      expect(vehicleBrandFromVin('WdB2110161a123456'), VehicleBrand.mercedes);
    });

    test('Exactly 3 chars works (lower boundary)', () {
      expect(vehicleBrandFromVin('WVW'), VehicleBrand.vwGroup);
      expect(vehicleBrandFromVin('WBA'), VehicleBrand.bmw);
    });
  });

  group('Elm327Commands AT init constants', () {
    test('reset and echo / line-feed / headers / protocol commands end with CR',
        () {
      expect(Elm327Commands.resetCommand, 'ATZ\r');
      expect(Elm327Commands.echoOffCommand, 'ATE0\r');
      expect(Elm327Commands.autoProtocolCommand, 'ATSP0\r');
      expect(Elm327Commands.lineFeedsOffCommand, 'ATL0\r');
      expect(Elm327Commands.headersOffCommand, 'ATH0\r');
    });

    test('initCommands contains all five AT init commands in expected order',
        () {
      expect(Elm327Commands.initCommands, <String>[
        'ATZ\r',
        'ATE0\r',
        'ATL0\r',
        'ATH0\r',
        'ATSP0\r',
      ]);
    });

    test('every init command ends with carriage return', () {
      for (final cmd in Elm327Commands.initCommands) {
        expect(
          cmd.endsWith('\r'),
          isTrue,
          reason: 'AT init command "$cmd" must end with CR',
        );
      }
    });
  });

  group('Elm327Commands Mode 01 PID commands', () {
    test('all Mode 01 commands have the form 01XX\\r', () {
      const mode01 = <String>[
        Elm327Commands.vehicleSpeedCommand,
        Elm327Commands.engineRpmCommand,
        Elm327Commands.distanceSinceDtcClearedCommand,
        Elm327Commands.odometerCommand,
        Elm327Commands.engineLoadCommand,
        Elm327Commands.throttlePositionCommand,
        Elm327Commands.engineFuelRateCommand,
        Elm327Commands.mafCommand,
        Elm327Commands.intakeManifoldPressureCommand,
        Elm327Commands.intakeAirTempCommand,
        Elm327Commands.shortTermFuelTrimCommand,
        Elm327Commands.longTermFuelTrimCommand,
        Elm327Commands.fuelTankLevelCommand,
      ];
      final pattern = RegExp(r'^01[0-9A-F]{2}\r$');
      for (final cmd in mode01) {
        expect(
          pattern.hasMatch(cmd),
          isTrue,
          reason: 'Mode 01 command "$cmd" must match 01XX\\r',
        );
      }
    });

    test('vehicleSpeedCommand asks for PID 0D', () {
      expect(Elm327Commands.vehicleSpeedCommand, '010D\r');
    });

    test('engineRpmCommand asks for PID 0C', () {
      expect(Elm327Commands.engineRpmCommand, '010C\r');
    });

    test('odometerCommand asks for PID A6', () {
      expect(Elm327Commands.odometerCommand, '01A6\r');
    });

    test('vinCommand asks for Mode 09 PID 02', () {
      expect(Elm327Commands.vinCommand, '0902\r');
    });

    test('Mode 01 PIDs are pairwise distinct', () {
      final pids = <String>{
        Elm327Commands.vehicleSpeedCommand,
        Elm327Commands.engineRpmCommand,
        Elm327Commands.distanceSinceDtcClearedCommand,
        Elm327Commands.odometerCommand,
        Elm327Commands.engineLoadCommand,
        Elm327Commands.throttlePositionCommand,
        Elm327Commands.engineFuelRateCommand,
        Elm327Commands.mafCommand,
        Elm327Commands.intakeManifoldPressureCommand,
        Elm327Commands.intakeAirTempCommand,
        Elm327Commands.shortTermFuelTrimCommand,
        Elm327Commands.longTermFuelTrimCommand,
        Elm327Commands.fuelTankLevelCommand,
      };
      // Set length must equal number of unique commands above (13).
      expect(pids.length, 13);
    });
  });

  group('Elm327Commands.supportedPidsCommands', () {
    test('covers seven group bitmaps from 0100 to 01C0', () {
      expect(Elm327Commands.supportedPidsCommands, <String>[
        '0100\r',
        '0120\r',
        '0140\r',
        '0160\r',
        '0180\r',
        '01A0\r',
        '01C0\r',
      ]);
    });

    test('each entry asks for a Mode 01 group-base PID (multiple of 0x20)',
        () {
      final pattern = RegExp(r'^01([0-9A-F]{2})\r$');
      for (final cmd in Elm327Commands.supportedPidsCommands) {
        final match = pattern.firstMatch(cmd);
        expect(match, isNotNull, reason: '"$cmd" must match 01XX\\r');
        final pid = int.parse(match!.group(1)!, radix: 16);
        expect(
          pid % 0x20,
          0,
          reason: 'Supported-PID group base "$cmd" must be a multiple of 0x20',
        );
      }
    });
  });

  group('Elm327Commands.mfgOdometerCatalog', () {
    test('has exactly one entry for every brand except unknown', () {
      final brandsCovered = Elm327Commands.mfgOdometerCatalog
          .map((e) => e.brand)
          .toSet();
      // VehicleBrand.unknown intentionally has no fallback PID.
      final expected = VehicleBrand.values.toSet()..remove(VehicleBrand.unknown);
      expect(brandsCovered, expected);
    });

    test('catalog has no duplicate brand entries', () {
      final brands = Elm327Commands.mfgOdometerCatalog
          .map((e) => e.brand)
          .toList();
      expect(brands.toSet().length, brands.length);
    });

    test('every command is a Mode 22 request matching 22XXYY\\r', () {
      final pattern = RegExp(r'^22[0-9A-F]{4}\r$');
      for (final entry in Elm327Commands.mfgOdometerCatalog) {
        expect(
          pattern.hasMatch(entry.command),
          isTrue,
          reason:
              'Brand ${entry.brand} command "${entry.command}" must match 22XXYY\\r',
        );
      }
    });

    test('pidHi/pidLo bytes match the PID encoded in the command string', () {
      final pattern = RegExp(r'^22([0-9A-F]{2})([0-9A-F]{2})\r$');
      for (final entry in Elm327Commands.mfgOdometerCatalog) {
        final match = pattern.firstMatch(entry.command);
        expect(match, isNotNull, reason: 'command must be Mode 22 form');
        final hi = int.parse(match!.group(1)!, radix: 16);
        final lo = int.parse(match.group(2)!, radix: 16);
        expect(entry.pidHi, hi, reason: 'pidHi of ${entry.brand}');
        expect(entry.pidLo, lo, reason: 'pidLo of ${entry.brand}');
      }
    });

    test('pidHi and pidLo are byte-sized (0..255)', () {
      for (final entry in Elm327Commands.mfgOdometerCatalog) {
        expect(entry.pidHi, inInclusiveRange(0, 255));
        expect(entry.pidLo, inInclusiveRange(0, 255));
      }
    });

    test('every entry has a known kind', () {
      for (final entry in Elm327Commands.mfgOdometerCatalog) {
        expect(MfgOdometerKind.values.contains(entry.kind), isTrue);
      }
    });

    test('exact mapping for VW group: 22 22 03, threeBytesKm', () {
      final entry = Elm327Commands.mfgOdometerCatalog
          .firstWhere((e) => e.brand == VehicleBrand.vwGroup);
      expect(entry.command, '222203\r');
      expect(entry.pidHi, 0x22);
      expect(entry.pidLo, 0x03);
      expect(entry.kind, MfgOdometerKind.threeBytesKm);
    });

    test('exact mapping for BMW: 22 30 16, threeBytesKm', () {
      final entry = Elm327Commands.mfgOdometerCatalog
          .firstWhere((e) => e.brand == VehicleBrand.bmw);
      expect(entry.command, '223016\r');
      expect(entry.pidHi, 0x30);
      expect(entry.pidLo, 0x16);
      expect(entry.kind, MfgOdometerKind.threeBytesKm);
    });

    test('exact mapping for Mercedes: 22 F1 5B, twoBytesKm', () {
      final entry = Elm327Commands.mfgOdometerCatalog
          .firstWhere((e) => e.brand == VehicleBrand.mercedes);
      expect(entry.command, '22F15B\r');
      expect(entry.pidHi, 0xF1);
      expect(entry.pidLo, 0x5B);
      expect(entry.kind, MfgOdometerKind.twoBytesKm);
    });

    test(
        'exact mapping for Ford: 22 40 4D, twoBytesMilesTimes10 '
        '(US-market encoding)', () {
      final entry = Elm327Commands.mfgOdometerCatalog
          .firstWhere((e) => e.brand == VehicleBrand.ford);
      expect(entry.command, '22404D\r');
      expect(entry.pidHi, 0x40);
      expect(entry.pidLo, 0x4D);
      expect(entry.kind, MfgOdometerKind.twoBytesMilesTimes10);
    });

    test('exact mapping for PSA: 22 D1 01, twoBytesKm', () {
      final entry = Elm327Commands.mfgOdometerCatalog
          .firstWhere((e) => e.brand == VehicleBrand.psa);
      expect(entry.command, '22D101\r');
      expect(entry.pidHi, 0xD1);
      expect(entry.pidLo, 0x01);
      expect(entry.kind, MfgOdometerKind.twoBytesKm);
    });

    test('exact mapping for Renault: 22 21 02, threeBytesKm', () {
      final entry = Elm327Commands.mfgOdometerCatalog
          .firstWhere((e) => e.brand == VehicleBrand.renault);
      expect(entry.command, '222102\r');
      expect(entry.pidHi, 0x21);
      expect(entry.pidLo, 0x02);
      expect(entry.kind, MfgOdometerKind.threeBytesKm);
    });
  });

  group('MfgOdometerEntry constructor wiring', () {
    test('stores all fields verbatim', () {
      const entry = MfgOdometerEntry(
        brand: VehicleBrand.bmw,
        command: '223016\r',
        pidHi: 0x30,
        pidLo: 0x16,
        kind: MfgOdometerKind.threeBytesKm,
      );
      expect(entry.brand, VehicleBrand.bmw);
      expect(entry.command, '223016\r');
      expect(entry.pidHi, 0x30);
      expect(entry.pidLo, 0x16);
      expect(entry.kind, MfgOdometerKind.threeBytesKm);
    });
  });

  group('Enum invariants', () {
    test('VehicleBrand enum has all expected members', () {
      expect(
        VehicleBrand.values.toSet(),
        <VehicleBrand>{
          VehicleBrand.vwGroup,
          VehicleBrand.bmw,
          VehicleBrand.mercedes,
          VehicleBrand.ford,
          VehicleBrand.psa,
          VehicleBrand.renault,
          VehicleBrand.unknown,
        },
      );
    });

    test('MfgOdometerKind enum has all three encoding shapes', () {
      expect(
        MfgOdometerKind.values.toSet(),
        <MfgOdometerKind>{
          MfgOdometerKind.threeBytesKm,
          MfgOdometerKind.twoBytesKm,
          MfgOdometerKind.twoBytesMilesTimes10,
        },
      );
    });
  });
}
