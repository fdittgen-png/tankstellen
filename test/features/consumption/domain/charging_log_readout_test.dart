import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/charging_log_readout.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

/// Unit tests for [computeChargingLogReadout] — the pure derivation
/// rule extracted from `add_charging_log_screen.dart` (#563 refactor).
/// Three states must be distinguishable: incomplete (`null`), no
/// anchor (`ChargingLogReadout.empty`), and fully-populated.
ChargingLog _log({
  String id = 'p1',
  String vehicleId = 'ev-1',
  double kWh = 40,
  double costEur = 20,
  int odometerKm = 10000,
}) =>
    ChargingLog(
      id: id,
      vehicleId: vehicleId,
      date: DateTime.utc(2026, 4, 1),
      kWh: kWh,
      costEur: costEur,
      chargeTimeMin: 30,
      odometerKm: odometerKm,
    );

void main() {
  final date = DateTime.utc(2026, 4, 26);

  group('computeChargingLogReadout — incomplete inputs return null', () {
    test('null vehicleId returns null', () {
      expect(
        computeChargingLogReadout(
          vehicleId: null,
          kWhText: '30',
          costText: '12',
          odometerText: '10500',
          date: date,
          allLogs: const [],
        ),
        isNull,
      );
    });

    test('blank kWh returns null', () {
      expect(
        computeChargingLogReadout(
          vehicleId: 'ev-1',
          kWhText: '',
          costText: '12',
          odometerText: '10500',
          date: date,
          allLogs: const [],
        ),
        isNull,
      );
    });

    test('zero kWh returns null', () {
      expect(
        computeChargingLogReadout(
          vehicleId: 'ev-1',
          kWhText: '0',
          costText: '12',
          odometerText: '10500',
          date: date,
          allLogs: const [],
        ),
        isNull,
      );
    });

    test('negative cost returns null', () {
      expect(
        computeChargingLogReadout(
          vehicleId: 'ev-1',
          kWhText: '30',
          costText: '-12',
          odometerText: '10500',
          date: date,
          allLogs: const [],
        ),
        isNull,
      );
    });

    test('zero odometer returns null', () {
      expect(
        computeChargingLogReadout(
          vehicleId: 'ev-1',
          kWhText: '30',
          costText: '12',
          odometerText: '0',
          date: date,
          allLogs: const [],
        ),
        isNull,
      );
    });

    test('null allLogs (still loading) returns null', () {
      expect(
        computeChargingLogReadout(
          vehicleId: 'ev-1',
          kWhText: '30',
          costText: '12',
          odometerText: '10500',
          date: date,
          allLogs: null,
        ),
        isNull,
      );
    });
  });

  group('computeChargingLogReadout — empty branch (no anchor)', () {
    test('no prior logs at all returns empty readout', () {
      final r = computeChargingLogReadout(
        vehicleId: 'ev-1',
        kWhText: '30',
        costText: '12',
        odometerText: '10500',
        date: date,
        allLogs: const [],
      );
      expect(r, isNotNull);
      expect(r!.hasValues, isFalse);
      expect(r.eurPer100km, isNull);
      expect(r.kwhPer100km, isNull);
    });

    test('only prior logs for OTHER vehicles returns empty readout', () {
      final r = computeChargingLogReadout(
        vehicleId: 'ev-1',
        kWhText: '30',
        costText: '12',
        odometerText: '10500',
        date: date,
        allLogs: [_log(vehicleId: 'ev-2', odometerKm: 5000)],
      );
      expect(r, isNotNull);
      expect(r!.hasValues, isFalse);
    });

    test('prior log has same odometer (zero km driven) returns empty', () {
      final r = computeChargingLogReadout(
        vehicleId: 'ev-1',
        kWhText: '30',
        costText: '12',
        odometerText: '10500',
        date: date,
        allLogs: [_log(odometerKm: 10500)],
      );
      expect(r, isNotNull);
      expect(r!.hasValues, isFalse);
    });
  });

  group('computeChargingLogReadout — happy path', () {
    test('30 kWh / 12 EUR over 500 km yields 2.40 EUR/100 km, 6.0 kWh/100 km',
        () {
      final r = computeChargingLogReadout(
        vehicleId: 'ev-1',
        kWhText: '30',
        costText: '12',
        odometerText: '10500',
        date: date,
        allLogs: [_log(odometerKm: 10000)],
      );
      expect(r, isNotNull);
      expect(r!.hasValues, isTrue);
      expect(r.eurPer100km, closeTo(2.4, 1e-9));
      expect(r.kwhPer100km, closeTo(6.0, 1e-9));
    });

    test('picks the most-recent prior log with odometer < current', () {
      // Anchor candidate: 10000 (latest log with odo < 10500). The
      // 10800 log is filtered out — you can't drive backwards.
      final r = computeChargingLogReadout(
        vehicleId: 'ev-1',
        kWhText: '30',
        costText: '12',
        odometerText: '10500',
        date: date,
        allLogs: [
          _log(id: 'a', odometerKm: 9000),
          _log(id: 'b', odometerKm: 10000),
          _log(id: 'c', odometerKm: 10800),
        ],
      );
      expect(r, isNotNull);
      expect(r!.eurPer100km, closeTo(2.4, 1e-9));
    });

    test('comma-decimal inputs parse identically to dot-decimal', () {
      final r = computeChargingLogReadout(
        vehicleId: 'ev-1',
        kWhText: '30,0',
        costText: '12,0',
        odometerText: '10500',
        date: date,
        allLogs: [_log(odometerKm: 10000)],
      );
      expect(r, isNotNull);
      expect(r!.eurPer100km, closeTo(2.4, 1e-9));
    });
  });

  group('ChargingLogReadout', () {
    test('empty constructor produces hasValues == false', () {
      const r = ChargingLogReadout.empty();
      expect(r.hasValues, isFalse);
      expect(r.eurPer100km, isNull);
      expect(r.kwhPer100km, isNull);
    });

    test('populated constructor produces hasValues == true', () {
      const r = ChargingLogReadout(eurPer100km: 2.4, kwhPer100km: 6.0);
      expect(r.hasValues, isTrue);
    });
  });
}
