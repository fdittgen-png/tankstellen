// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';
import 'package:tankstellen/features/obd2/domain/signal_reading.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_signal.dart';

/// #4159 — the live snapshot marks an implausible φ / baro on its
/// `reading`, keeps the unclamped value on the getter the trip stores, and
/// derives exactly the fuel figure the clamp produced before.

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
    debugSetSupportedPids({0x24});
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

({LiveSampleSnapshot snapshot, void Function(String, String) deliver})
    _snapshot({VehicleProfile? vehicle}) {
  final scheduler = _Capture();
  final snapshot = LiveSampleSnapshot(
    service: _Service(),
    vehicle: vehicle,
    onHighPriorityParse: (_) {},
    onSpeedSample: (_) {},
    clock: () => DateTime.utc(2026, 9, 16, 12),
  )..subscribeAllTiers(scheduler);
  return (
    snapshot: snapshot,
    deliver: (c, f) => scheduler.callbacks[c]!(f),
  );
}

void main() {
  const diesel =
      VehicleProfile(id: 'd', name: 'd', preferredFuelType: 'diesel');

  test('commanded φ 1.9: marked implausible, stored unclamped, fuel as the '
      'clamp made it', () {
    final a = _snapshot();
    a.deliver('0110\r', '41 10 04 00');
    a.deliver('0144\r', '41 44 F3 33'); // 0xF333 / 32768 ≈ 1.9
    final r = a.snapshot.reading(VehicleSignal.commandedPhi);
    expect(r.plausibility, SignalPlausibility.implausible);
    expect(a.snapshot.latestCommandedPhi, 0xF333 / 32768.0);

    final b = _snapshot();
    b.deliver('0110\r', '41 10 04 00');
    b.deliver('0144\r', '41 44 C0 00'); // exactly 1.5, the clamp edge
    expect(b.snapshot.reading(VehicleSignal.commandedPhi).plausibility,
        SignalPlausibility.plausible);
    expect(a.snapshot.deriveFuelRateLPerHour(),
        b.snapshot.deriveFuelRateLPerHour());
  });

  test('baro 50 kPa is implausible; 95 kPa is plausible', () {
    final s = _snapshot();
    s.deliver('0133\r', '41 33 32');
    expect(s.snapshot.reading(VehicleSignal.baroPressure).plausibility,
        SignalPlausibility.implausible);
    s.deliver('0133\r', '41 33 5F');
    expect(s.snapshot.reading(VehicleSignal.baroPressure).plausibility,
        SignalPlausibility.plausible);
  });

  test('measured φ 0.1 is plausible on a diesel, implausible on petrol', () {
    const frame = '41 24 0C CD 00 00'; // 0x0CCD / 32768 ≈ 0.1
    final d = _snapshot(vehicle: diesel);
    d.deliver('0124\r', frame);
    expect(d.snapshot.reading(VehicleSignal.widebandPhi).plausibility,
        SignalPlausibility.plausible);
    final p = _snapshot();
    p.deliver('0124\r', frame);
    expect(p.snapshot.reading(VehicleSignal.widebandPhi).plausibility,
        SignalPlausibility.implausible);
  });

  test('signals without a band stay unchecked; nothing landed stays '
      'unchecked', () {
    final s = _snapshot();
    s.deliver('0105\r', '41 05 FF');
    expect(s.snapshot.reading(VehicleSignal.coolantTemp).plausibility,
        SignalPlausibility.notChecked);
    expect(s.snapshot.reading(VehicleSignal.baroPressure).plausibility,
        SignalPlausibility.notChecked);
  });
}
