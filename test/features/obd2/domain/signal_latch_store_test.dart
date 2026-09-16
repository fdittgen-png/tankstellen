// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/features/obd2/domain/precision_pid_latches.dart';
import 'package:tankstellen/features/obd2/domain/signal_latch_store.dart';
import 'package:tankstellen/features/obd2/domain/signal_reading.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_signal.dart';

/// #4159 — [SignalLatchStore]: hold-last [latest], window-gated [fresh],
/// and a [reading] that carries unit, provenance and freshness.

class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

void main() {
  late _Clock clock;
  late SignalLatchStore store;
  final t0 = DateTime.utc(2026, 9, 16, 12);

  setUp(() {
    clock = _Clock(t0);
    store = SignalLatchStore(clock: clock.call);
  });

  test('before anything lands: unknown, not measured yet', () {
    expect(store.latest(VehicleSignal.engineRpm), isNull);
    expect(store.fresh(VehicleSignal.engineRpm), isNull);
    expect(store.arrivedAt(VehicleSignal.engineRpm), isNull);
    final r = store.reading(VehicleSignal.engineRpm);
    expect(r.value,
        const Unknown<double>(reason: DataUnknownReason.notMeasuredYet));
    expect(r.unit, SignalUnit.rpm);
    expect(r.valueOrNull, isNull);
    expect(r.plausibility, SignalPlausibility.notChecked);
  });

  test('a write is measured at its arrival time', () {
    clock.advance(const Duration(seconds: 3));
    store.write(VehicleSignal.coolantTemp, 83);
    clock.advance(const Duration(seconds: 1));
    expect(store.arrivedAt(VehicleSignal.coolantTemp),
        t0.add(const Duration(seconds: 3)));
    expect(store.reading(VehicleSignal.coolantTemp).value,
        Measured<double>(83, at: t0.add(const Duration(seconds: 3))));
  });

  test('a signal without a window holds forever and never goes stale', () {
    store.write(VehicleSignal.engineRpm, 1726);
    clock.advance(const Duration(hours: 5));
    expect(SignalLatchStore.freshnessWindowOf(VehicleSignal.engineRpm),
        isNull);
    expect(store.latest(VehicleSignal.engineRpm), 1726);
    expect(store.fresh(VehicleSignal.engineRpm), 1726);
    expect(store.reading(VehicleSignal.engineRpm).value, isA<Measured<double>>());
  });

  test('IAT: fresh for exactly 12 s, then stale with its age — and the '
      'hold-last value survives', () {
    store.write(VehicleSignal.intakeAirTemp, 20);
    clock.advance(const Duration(seconds: 12));
    expect(store.fresh(VehicleSignal.intakeAirTemp), 20);
    expect(store.reading(VehicleSignal.intakeAirTemp).value,
        isA<Measured<double>>());
    clock.advance(const Duration(milliseconds: 1));
    expect(store.fresh(VehicleSignal.intakeAirTemp), isNull);
    expect(store.latest(VehicleSignal.intakeAirTemp), 20);
    final r = store.reading(VehicleSignal.intakeAirTemp);
    expect(r.value, const Stale<double>(20,
        age: Duration(seconds: 12, milliseconds: 1)));
    expect(r.valueOrNull, 20);
  });

  test('a new write refreshes the window', () {
    store.write(VehicleSignal.intakeAirTemp, 20);
    clock.advance(const Duration(seconds: 30));
    store.write(VehicleSignal.intakeAirTemp, 21);
    expect(store.fresh(VehicleSignal.intakeAirTemp), 21);
  });

  test('the wideband window is the per-sensor staleness the latches apply',
      () {
    expect(SignalLatchStore.freshnessWindowOf(VehicleSignal.widebandPhi),
        PrecisionPidLatches.measuredPhiStaleness);
  });

  test('SignalReading.marked keeps signal and value', () {
    final r = store.reading(VehicleSignal.baroPressure);
    final m = r.marked(SignalPlausibility.implausible);
    expect(m.signal, VehicleSignal.baroPressure);
    expect(m.value, r.value);
    expect(m.plausibility, SignalPlausibility.implausible);
    expect(m, isNot(r));
    expect(m, r.marked(SignalPlausibility.implausible));
  });
}
