// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';
import 'package:tankstellen/features/obd2/domain/signal_reading.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_signal.dart';

/// #4159 — the snapshot's normalized reads: `reading(signal)` carries
/// unit, provenance and freshness for every latch (wideband φ through the
/// sensor-priority rule), and `fuelRateReading()` tells an ECU-reported
/// rate from an air-mass derivation without re-deriving.

class _StubTransport implements Obd2Transport {
  @override
  bool get isConnected => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<String> sendCommand(String command) async => 'NO DATA';
}

class _Service extends Obd2Service {
  _Service() : super(_StubTransport()) {
    debugSetSupportedPids({0x24, 0x34, 0x66, 0x9D, 0xA2, 0x52});
  }
}

class _Capture extends PidScheduler {
  _Capture() : super(transport: (_) async => 'NO DATA');
  final Map<String, void Function(String)> callbacks = {};
  @override
  void subscribe(String command, ScheduledPid config,
      void Function(String response) onResult) {
    callbacks[command] = onResult;
  }
}

void main() {
  final t0 = DateTime.utc(2026, 9, 16, 12);
  late DateTime now;
  late _Capture scheduler;
  late LiveSampleSnapshot snapshot;
  late Obd2BreadcrumbCollector collector;

  void deliver(String command, String frame) =>
      scheduler.callbacks[command]!(frame);

  setUp(() {
    now = t0;
    scheduler = _Capture();
    collector = Obd2BreadcrumbCollector();
    snapshot = LiveSampleSnapshot(
      service: _Service(),
      breadcrumbCollector: collector,
      onHighPriorityParse: (_) {},
      onSpeedSample: (_) {},
      clock: () => now,
    )..subscribeAllTiers(scheduler);
  });

  test('every latch reads as a SignalReading with its unit', () {
    expect(snapshot.reading(VehicleSignal.coolantTemp).value,
        const Unknown<double>(reason: DataUnknownReason.notMeasuredYet));
    deliver('0105\r', '41 05 7B');
    final r = snapshot.reading(VehicleSignal.coolantTemp);
    expect(r.value, Measured<double>(83, at: t0));
    expect(r.unit, SignalUnit.celsius);
    expect(snapshot.latestCoolantTempC, 83);
  });

  test('the precision families share the snapshot store', () {
    deliver('0152\r', '41 52 D9');
    expect(snapshot.reading(VehicleSignal.ethanolPercent).valueOrNull,
        snapshot.latestEthanolPercent);
    expect(snapshot.latestEthanolPercent, isNotNull);
  });

  test('IAT reads Stale past 12 s while the getter still holds it', () {
    deliver('010F\r', '41 0F 3C');
    now = t0.add(const Duration(seconds: 13));
    expect(snapshot.reading(VehicleSignal.intakeAirTemp).value,
        const Stale<double>(20, age: Duration(seconds: 13)));
    expect(snapshot.latestIatCelsius, 20);
  });

  test('wideband φ follows the sensor priority, then goes Stale', () {
    deliver('0134\r', '41 34 C0 00 00 00'); // 1.5
    now = t0.add(const Duration(seconds: 1));
    deliver('0124\r', '41 24 80 00 00 00'); // 1.0, sensor 1 voltage
    expect(snapshot.reading(VehicleSignal.widebandPhi).value,
        Measured<double>(1.0, at: t0.add(const Duration(seconds: 1))));
    now = t0.add(const Duration(seconds: 12));
    expect(snapshot.latestMeasuredPhi, isNull);
    expect(snapshot.reading(VehicleSignal.widebandPhi).value,
        const Stale<double>(1.0, age: Duration(seconds: 11)),
        reason: 'the newest sensor, stale');
  });

  group('fuelRateReading', () {
    test('unknown before any derivation', () {
      expect(snapshot.fuelRateReading().value,
          const Unknown<double>(reason: DataUnknownReason.notMeasuredYet));
    });

    test('an ECU-reported rate is Measured at the derivation time', () {
      deliver('015E\r', '41 5E 00 64'); // 5.0 L/h
      now = t0.add(const Duration(seconds: 2));
      expect(snapshot.deriveFuelRateLPerHour(), 5.0);
      final r = snapshot.fuelRateReading();
      expect(r.signal, VehicleSignal.fuelRate);
      expect(r.value, Measured<double>(5.0, at: now));
    });

    test('a MAF derivation is Estimated(derived), and reading it records '
        'no breadcrumb', () {
      deliver('0110\r', '41 10 04 00');
      final lph = snapshot.deriveFuelRateLPerHour();
      final crumbs = collector.entries.length;
      final r = snapshot.fuelRateReading();
      expect(r.value, Estimated<double>(lph!, basis: DataBasis.derived));
      expect(collector.entries.length, crumbs);
    });
  });

  test('fuelRateReadingOf maps every source tag', () {
    final at = t0;
    expect(
      {
        for (final tag in FuelRateSourceTag.values)
          tag: fuelRateReadingOf(1.0, tag, at: at).value.runtimeType,
      },
      {
        FuelRateSourceTag.pid9D: Measured<double>,
        FuelRateSourceTag.pidA2: Measured<double>,
        FuelRateSourceTag.pid5E: Measured<double>,
        FuelRateSourceTag.maf66: Estimated<double>,
        FuelRateSourceTag.maf: Estimated<double>,
        FuelRateSourceTag.speedDensity: Estimated<double>,
        FuelRateSourceTag.none: Unknown<double>,
      },
    );
    expect(fuelRateReadingOf(null, FuelRateSourceTag.pid5E).value,
        isA<Unknown<double>>());
  });
}
