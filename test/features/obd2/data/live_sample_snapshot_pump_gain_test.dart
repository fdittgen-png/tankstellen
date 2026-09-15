// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4236 — the live fuel-rate integrator applies the pump gain EXACTLY ONCE
// and ONLY to estimated branches, under the tank's fuel. Each case is a
// mutation guard: scaling a measured rate, squaring the gain, or reading
// the E85 gain for an E10 tank fails one of them. Latches are filled by the
// REAL scheduler + parsers with raw ELM327 frames (as in the #3416 suite).
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';

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

class _SupportStubService extends Obd2Service {
  _SupportStubService(Set<int> supported) : super(_StubTransport()) {
    debugSetSupportedPids(supported);
  }
}

Future<LiveSampleSnapshot> _filled({
  required Set<int> supported,
  required Map<String, String> responses,
  required VehicleProfile vehicle,
}) async {
  final scheduler = PidScheduler(
    transport: (cmd) async => responses[cmd.trim()] ?? 'NO DATA>',
    tickRate: const Duration(milliseconds: 2),
  );
  final snapshot = LiveSampleSnapshot(
    service: _SupportStubService(supported),
    vehicle: vehicle,
    onHighPriorityParse: (_) {},
    onSpeedSample: (_) {},
  );
  snapshot.subscribeAllTiers(scheduler);
  scheduler.start();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  scheduler.stop();
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return snapshot;
}

void main() {
  const rpm2500 = '41 0C 27 10>';
  const maf10 = '41 10 04 00>'; // 10.24 g/s air
  const rate5e = '41 5E 00 C8>'; // 10.0 L/h engine fuel rate
  const rate9d = '41 9D 01 F4 00 00>'; // 10.0 g/s engine fuel mass

  const raw = VehicleProfile(id: 'v', name: 'Raw');
  const calibrated =
      VehicleProfile(id: 'v', name: 'Calibrated', pumpGain: 0.8, pumpGainSamples: 3);

  Future<double?> rate(Set<int> supported, Map<String, String> responses,
          VehicleProfile vehicle) async =>
      (await _filled(
              supported: supported, responses: responses, vehicle: vehicle))
          .deriveFuelRateLPerHour();

  test('PID 5E is measured: the pump gain never touches it', () async {
    const r = {'010C': rpm2500, '015E': rate5e};
    final a = await rate({0x0C, 0x5E}, r, raw);
    final b = await rate({0x0C, 0x5E}, r, calibrated);
    expect(a, isNotNull);
    expect(b, a, reason: 'a measured rate scaled by the gain is the mutation');
  });

  test('PID 9D is measured: the pump gain never touches it', () async {
    const r = {'010C': rpm2500, '019D': rate9d};
    final a = await rate({0x0C, 0x9D}, r, raw);
    final b = await rate({0x0C, 0x9D}, r, calibrated);
    expect(a, isNotNull);
    expect(b, a);
  });

  test('the MAF estimate carries the gain exactly once', () async {
    const r = {'010C': rpm2500, '0110': maf10};
    final a = await rate({0x0C, 0x10}, r, raw);
    final b = await rate({0x0C, 0x10}, r, calibrated);
    expect(a, isNotNull);
    expect(b, closeTo(a! * 0.8, 1e-9),
        reason: 'applied twice it would read 0.64×');
  });

  test('an E10 tank uses the E10 gain, never the E85 one', () async {
    const r = {'010C': rpm2500, '0110': maf10};
    const flexRaw = VehicleProfile(
        id: 'v', name: 'Flex', multiFuelCapable: true, tankFuelKey: 'e10');
    const flex = VehicleProfile(
      id: 'v',
      name: 'Flex',
      multiFuelCapable: true,
      tankFuelKey: 'e10',
      pumpGainByFuel: {
        'e10': PumpGainEntry(gain: 1.1, samples: 2),
        'e85': PumpGainEntry(gain: 0.7, samples: 2),
      },
    );
    final a = await rate({0x0C, 0x10}, r, flexRaw);
    final snapshot =
        await _filled(supported: {0x0C, 0x10}, responses: r, vehicle: flex);
    final b = snapshot.deriveFuelRateLPerHour();
    expect(b, closeTo(a! * 1.1, 1e-9));
    expect(snapshot.lastPumpGainResolution?.requestedFuelKey, 'e10',
        reason: 'the key a trip stamps (#4220)');
  });
}
