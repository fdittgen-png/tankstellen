// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/obd2_session_diagnostic.dart';
import 'package:tankstellen/features/obd2/data/protocol/elm327_mode22_parsers.dart';
import 'package:tankstellen/features/obd2/data/protocol/elm327_parsers.dart';
import 'package:tankstellen/features/obd2/data/protocol/frame_decode.dart';
import 'package:tankstellen/features/obd2/data/protocol/obd2_response_class.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_odometer_reader.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

/// #4325 — a frame that ARRIVED but decodes outside its plausible bounds is
/// a named outcome, not a null indistinguishable from NO DATA. Consumers
/// still get null; comm diagnostics count the fault.

const _voltage = FrameDecode<double>.implausible(
  ImplausibleFrameKind.batteryVoltage,
);
const _odometer = FrameDecode<double>.implausible(ImplausibleFrameKind.odometer);
const _absent = FrameDecode<double>.absent();

/// `41 A6` frame carrying [tenths] of a km as four big-endian bytes.
String _a6(int tenths) {
  String b(int shift) =>
      ((tenths >> shift) & 0xFF).toRadixString(16).padLeft(2, '0');
  return '41 A6 ${b(24)} ${b(16)} ${b(8)} ${b(0)}';
}

void main() {
  group('battery voltage (ATRV) bounds — 5 V and 20 V are inclusive', () {
    test('5.0 V is a reading; 4.9 V is an implausible frame', () {
      expect(Elm327Parsers.decodeBatteryVoltage('5.0V'),
          const FrameDecode<double>.value(5.0));
      expect(Elm327Parsers.decodeBatteryVoltage('4.9V'), _voltage);
    });

    test('20.0 V is a reading; 20.1 V is an implausible frame', () {
      expect(Elm327Parsers.decodeBatteryVoltage('20.0V'),
          const FrameDecode<double>.value(20.0));
      expect(Elm327Parsers.decodeBatteryVoltage('20.1V'), _voltage);
    });

    test('no reply is absent, never implausible', () {
      for (final raw in ['?', 'NO DATA', 'OK', '', '41 0C 1A F8']) {
        expect(Elm327Parsers.decodeBatteryVoltage(raw), _absent, reason: raw);
      }
    });

    test('the consumer API still returns null for an implausible frame', () {
      expect(Elm327Parsers.parseBatteryVoltage('4.9V'), isNull);
      expect(Elm327Parsers.parseBatteryVoltage('20.1V'), isNull);
      expect(Elm327Parsers.parseBatteryVoltage('5.0V'), 5.0);
    });
  });

  group('odometer bounds — 0 km exclusive, 2,000,000 km inclusive', () {
    test('PID A6: 0 km is implausible; 0.1 km is a reading', () {
      expect(Elm327Parsers.decodeOdometer(_a6(0)), _odometer);
      expect(Elm327Parsers.decodeOdometer(_a6(1)),
          const FrameDecode<double>.value(0.1));
    });

    test('PID A6: 2,000,000 km is a reading; 2,000,000.1 km is implausible',
        () {
      expect(Elm327Parsers.decodeOdometer(_a6(20000000)),
          const FrameDecode<double>.value(2000000.0));
      expect(Elm327Parsers.decodeOdometer(_a6(20000001)), _odometer);
    });

    test('PID A6: NO DATA, a short frame or a PID mismatch is absent', () {
      expect(Elm327Parsers.decodeOdometer('NO DATA'), _absent);
      expect(Elm327Parsers.decodeOdometer('41 A6 00 01 86'), _absent);
      expect(Elm327Parsers.decodeOdometer('41 0D 00 01 86 A0'), _absent);
      expect(Elm327Parsers.parseOdometer(_a6(0)), isNull);
    });

    test('Mode 22 3-byte: 0 and 2,000,001 km implausible; 1 and 2,000,000 read',
        () {
      FrameDecode<double> d(String payload) =>
          Elm327Mode22Parsers.decodeMfgOdometer3Byte('62 22 03 $payload>',
              expectedPidHi: 0x22, expectedPidLo: 0x03);
      expect(d('00 00 00'), _odometer);
      expect(d('00 00 01'), const FrameDecode<double>.value(1.0));
      expect(d('1E 84 80'), const FrameDecode<double>.value(2000000.0));
      expect(d('1E 84 81'), _odometer);
      expect(
        Elm327Mode22Parsers.decodeMfgOdometer3Byte('62 22 04 00 00 00>',
            expectedPidHi: 0x22, expectedPidLo: 0x03),
        _absent,
        reason: 'a PID-echo mismatch is not a frame for this request',
      );
    });

    test('Mode 22 2-byte and miles×10: 0 is implausible, 1 is a reading', () {
      expect(
        Elm327Mode22Parsers.decodeMfgOdometer2Byte('62 F1 5B 00 00>',
            expectedPidHi: 0xF1, expectedPidLo: 0x5B),
        _odometer,
      );
      expect(
        Elm327Mode22Parsers.decodeMfgOdometer2Byte('62 F1 5B 00 01>',
            expectedPidHi: 0xF1, expectedPidLo: 0x5B),
        const FrameDecode<double>.value(1.0),
      );
      expect(
        Elm327Mode22Parsers.decodeMfgOdometerMilesTimes10('62 40 4D 00 00>',
            expectedPidHi: 0x40, expectedPidLo: 0x4D),
        _odometer,
      );
      expect(
        Elm327Mode22Parsers.parseMfgOdometerMilesTimes10('62 40 4D 00 00>',
            expectedPidHi: 0x40, expectedPidLo: 0x4D),
        isNull,
      );
    });
  });

  group('FrameDecode.valueReporting', () {
    test('hands only an implausible outcome to the reporter', () {
      final seen = <ImplausibleFrameKind>[];
      expect(_odometer.valueReporting(seen.add), isNull);
      expect(_absent.valueReporting(seen.add), isNull);
      expect(const FrameDecode<double>.value(3.0).valueReporting(seen.add), 3.0);
      expect(seen, [ImplausibleFrameKind.odometer]);
    });
  });

  group('Obd2CommDiagnostics counts implausible frames', () {
    test('per kind, apart from the per-PID NO DATA bucket', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteResult('01A6', ResponseClass.noData);
      c.noteImplausibleFrame(ImplausibleFrameKind.batteryVoltage);
      c.noteImplausibleFrame(ImplausibleFrameKind.batteryVoltage);
      c.noteImplausibleFrame(ImplausibleFrameKind.odometer);

      final snap = c.snapshot();
      expect(snap.implausibleFrames, {'batteryVoltage': 2, 'odometer': 1});
      expect(snap.pidStats['01A6']!.noData, 1,
          reason: 'NO DATA keeps its own bucket');
      c.endSession();
      expect(c.finishedSessions.single.implausibleFrames,
          {'batteryVoltage': 2, 'odometer': 1});
    });

    test('disabled, or before a session, is a no-op', () {
      final off = Obd2CommDiagnostics()..beginSession();
      off.noteImplausibleFrame(ImplausibleFrameKind.odometer);
      expect(off.snapshot(), const Obd2SessionDiagnostic());

      final noSession = Obd2CommDiagnostics(enabled: true);
      noSession.noteImplausibleFrame(ImplausibleFrameKind.odometer);
      noSession.beginSession();
      expect(noSession.snapshot().implausibleFrames, isEmpty);
    });

    test('the export carries the counts under `imp` and round-trips', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteImplausibleFrame(ImplausibleFrameKind.odometer);
      final json = c.snapshot().toJson();
      expect(json['imp'], {'odometer': 1});
      expect(Obd2SessionDiagnostic.fromJson(json).implausibleFrames,
          {'odometer': 1});
    });
  });

  group('Obd2OdometerReader reports implausible frames and walks on', () {
    Obd2OdometerReader reader(
      Map<String, String> replies,
      List<ImplausibleFrameKind> seen,
    ) =>
        Obd2OdometerReader(
          send: (cmd) async => replies[cmd.trim()] ?? 'NO DATA>',
          isConnected: () => true,
          onImplausibleFrame: seen.add,
        );

    test('an implausible A6 and Mode 22 frame are each reported once', () async {
      final seen = <ImplausibleFrameKind>[];
      final km = await reader({
        '01A6': '${_a6(0)}>',
        '222203': '62 22 03 FF FF FF>',
      }, seen)
          .read(odometerPidStrategy: 'vwUds');
      expect(km, isNull, reason: 'the figure is unchanged: still no reading');
      expect(seen, [ImplausibleFrameKind.odometer, ImplausibleFrameKind.odometer]);
    });

    test('NO DATA everywhere reports nothing', () async {
      final seen = <ImplausibleFrameKind>[];
      expect(await reader({}, seen).read(odometerPidStrategy: 'vwUds'), isNull);
      expect(seen, isEmpty);
    });
  });

  group('the implausible channel leaves fuelRateSuspect and breadcrumbs alone',
      () {
    late Obd2CommDiagnostics diag;

    setUp(() {
      diag = Obd2CommDiagnostics.instance
        ..reset()
        ..enabled = true
        ..beginSession();
    });

    tearDown(() {
      diag
        ..reset()
        ..enabled = false;
    });

    test('service reads count into diagnostics, never into the breadcrumbs',
        () async {
      // A baseline sample, so a flag routed through `recordFlag` (which is a
      // no-op on an empty buffer) WOULD raise the suspicious tally.
      final breadcrumbs = Obd2BreadcrumbCollector()
        ..record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 4.2);
      final service = Obd2Service(
        FakeObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          'ATRV': '48.0V>',
          '01A6': '${_a6(0)}>',
          '0131': 'NO DATA>',
        }),
        breadcrumbCollector: breadcrumbs,
      );
      await service.connect();

      expect(await service.readBatteryVoltageV(), isNull);
      expect(await service.readOdometerKm(), isNull);

      final snap = diag.snapshot();
      expect(snap.implausibleFrames, {'batteryVoltage': 1, 'odometer': 1});
      expect(snap.fuelDowngrade, const Obd2FuelDowngradeStats());
      expect(breadcrumbs.entries.single.flag, isNull);
      expect(breadcrumbs.snapshotAndResetCounters(),
          (total: 1, suspicious: 0),
          reason: 'the fuelRateSuspect ratio has nothing new to count');
    });
  });
}
