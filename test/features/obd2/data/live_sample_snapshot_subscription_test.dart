// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/pid_scheduler.dart';

/// #2457 — subscribeAllTiers wires the live set = target table ∩
/// discovered-supported. A car with only the four basic PIDs must
/// subscribe exactly those plus the unconditional core; a fully-capable
/// car subscribes the optional air-mass / mixture PIDs too.

/// Trivial transport — the snapshot test never reads, it only inspects
/// which commands got subscribed via the recording scheduler.
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

/// [Obd2Service] whose supported-PID answer is driven by [_supported].
/// `null` means "discovery never ran" → don't-reject-blind (`true` for
/// every PID), matching the production resolver contract.
class _SupportStubService extends Obd2Service {
  _SupportStubService(this._supported) : super(_StubTransport());

  final Set<int>? _supported;

  @override
  bool isPidSupported(int pid) =>
      _supported == null || _supported.contains(pid);
}

/// Drives subscribeAllTiers on a scheduler whose transport records each
/// distinct command, then returns the set of subscribed commands. Every
/// PID is newly subscribed (lastReadAt == null → infinity weight), so the
/// scheduler reads each at least once within a few ticks.
Future<Set<String>> _subscribedCommands(Set<int>? supported) async {
  final seen = <String>{};
  final scheduler = PidScheduler(
    transport: (cmd) async {
      seen.add(cmd);
      return 'NO DATA';
    },
    tickRate: const Duration(milliseconds: 2),
  );
  final snapshot = LiveSampleSnapshot(
    service: _SupportStubService(supported),
    onHighPriorityParse: (_) {},
    onSpeedSample: (_) {},
  );
  snapshot.subscribeAllTiers(scheduler);
  scheduler.start();
  await Future<void>.delayed(const Duration(milliseconds: 300));
  scheduler.stop();
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return seen;
}

void main() {
  // The unconditional core (no supportsPid gate): near-universal Mode-01.
  final core = <String>{
    Elm327Protocol.engineRpmCommand, // 010C
    Elm327Protocol.vehicleSpeedCommand, // 010D
    Elm327Protocol.throttlePositionCommand, // 0111
    Elm327Protocol.engineLoadCommand, // 0104
    Elm327Protocol.intakeAirTempCommand, // 010F
    Elm327Protocol.coolantTempCommand, // 0105
    Elm327Protocol.shortTermFuelTrimCommand, // 0106
    Elm327Protocol.longTermFuelTrimCommand, // 0107
    Elm327Protocol.fuelTankLevelCommand, // 012F
  };
  final optional = <String>{
    Elm327Protocol.mafCommand, // 0110
    Elm327Protocol.intakeManifoldPressureCommand, // 010B
    Elm327Protocol.engineFuelRateCommand, // 015E
    Elm327Protocol.commandedEquivalenceRatioCommand, // 0144
    Elm327Protocol.baroPressureCommand, // 0133
    // #2458 / #2459 — newly-acquired optional PIDs.
    Elm327Protocol.acceleratorPedalDCommand, // 0149
    Elm327Protocol.acceleratorPedalECommand, // 014A
    Elm327Protocol.acceleratorPedalFCommand, // 014B
    Elm327Protocol.absoluteLoadCommand, // 0143
    Elm327Protocol.shortTermFuelTrimBank2Command, // 0108
    Elm327Protocol.longTermFuelTrimBank2Command, // 0109
    Elm327Protocol.engineOilTempCommand, // 015C
    Elm327Protocol.ambientAirTempCommand, // 0146
  };

  test(
      'a basic car {010C,010D,0104,0111} subscribes exactly those of the '
      'target — the optional air-mass / mixture PIDs are NOT subscribed',
      () async {
    final subscribed =
        await _subscribedCommands(<int>{0x0C, 0x0D, 0x04, 0x11});
    // The four supported core PIDs are present.
    expect(subscribed, containsAll(<String>{
      Elm327Protocol.engineRpmCommand,
      Elm327Protocol.vehicleSpeedCommand,
      Elm327Protocol.engineLoadCommand,
      Elm327Protocol.throttlePositionCommand,
    }));
    // None of the optional (gated) PIDs were subscribed.
    for (final cmd in optional) {
      expect(subscribed, isNot(contains(cmd)),
          reason: '$cmd is optionalPid-gated and the car lacks it');
    }
  });

  test(
      'a fully-capable car subscribes the unconditional core PLUS every '
      'optional PID', () async {
    final all = <int>{
      0x0C, 0x0D, 0x11, 0x04, 0x0F, 0x05, 0x06, 0x07, 0x2F, // core
      0x10, 0x0B, 0x5E, 0x44, 0x33, // optional (#2456 and earlier)
      0x49, 0x4A, 0x4B, 0x43, 0x08, 0x09, 0x5C, 0x46, // #2458/#2459
    };
    final subscribed = await _subscribedCommands(all);
    expect(subscribed, containsAll(core));
    expect(subscribed, containsAll(optional));
  });

  test(
      'a probe-less clone (discovery never ran) still rotates the full core '
      '+ optional set (don\'t-reject-blind)', () async {
    final subscribed = await _subscribedCommands(null);
    expect(subscribed, containsAll(core),
        reason: 'the unconditional core must always rotate');
    expect(subscribed, containsAll(optional),
        reason: 'blind session does not reject optional PIDs');
  });
}
