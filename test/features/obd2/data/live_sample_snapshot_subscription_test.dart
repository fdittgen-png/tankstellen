// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_precision_pids.dart';
import 'package:tankstellen/features/obd2/data/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/pid_scheduler.dart';

/// #2457 → #3532 — subscribeAllTiers wires the OPTIMISTIC UNION: the
/// full target table subscribes regardless of the discovered bitmap
/// (clone adapters under-report it; the old `target ∩ discovered`
/// starved PIDs the ECU actually answers — Epic #3527). Bitmap-absent
/// optional PIDs poll NO DATA and self-evict via runtime probation
/// (3× real NO DATA) plus the scheduler's #2379 backoff. Only the
/// strict #3416 precision families stay bitmap-gated
/// (`isPidKnownSupported`) and are never blind-subscribed.

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

/// [Obd2Service] whose support answers are driven by the REAL resolver:
/// a non-null [supported] set is seeded via the #3416 seam (a RESOLVED
/// set — strict membership for `isPidKnownSupported`, membership for
/// `isPidSupported`); `null` leaves discovery un-run → the legacy gates
/// stay don't-reject-blind while the strict precision gates answer false.
class _SupportStubService extends Obd2Service {
  _SupportStubService(Set<int>? supported) : super(_StubTransport()) {
    if (supported != null) debugSetSupportedPids(supported);
  }
}

/// Drives subscribeAllTiers on a scheduler whose transport records each
/// distinct command, then returns the set of subscribed commands. Every
/// PID is newly subscribed (lastReadAt == null → infinity weight), so the
/// scheduler reads each at least once within a few ticks. Pass a
/// pre-built [service] to exercise probation state seeded before the
/// subscription (#3532); otherwise one is built from [supported].
Future<Set<String>> _subscribedCommands(
  Set<int>? supported, {
  Obd2Service? service,
}) async {
  final seen = <String>{};
  final scheduler = PidScheduler(
    transport: (cmd) async {
      seen.add(cmd);
      return 'NO DATA';
    },
    tickRate: const Duration(milliseconds: 2),
  );
  final snapshot = LiveSampleSnapshot(
    service: service ?? _SupportStubService(supported),
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
  // Epic #3416 — precision PIDs (#3427/#3428/#3429): unlike the legacy
  // optional set they are gated STRICTLY (`isPidKnownSupported` =
  // resolved ∧ contains) and are never blind-subscribed — an unresolved
  // clone would flood the round-robin with NO DATA initial reads and
  // starve the dynamics tier.
  final precision = <String>{
    Elm327PrecisionPids.widebandCommand(0x24), // wideband φ sensor 1 (V)
    Elm327PrecisionPids.widebandCommand(0x34), // wideband φ sensor 1 (I)
    Elm327PrecisionPids.mafSensorCommand, // 0166
    Elm327PrecisionPids.engineFuelRateGramsCommand, // 019D
    Elm327PrecisionPids.cylinderFuelRateCommand, // 01A2
    Elm327PrecisionPids.ethanolPercentCommand, // 0152
  };

  test(
      'a basic car {010C,010D,0104,0111} still subscribes the FULL target '
      '— the bitmap no longer gates the legacy optional PIDs (#3532 '
      'optimistic union); only the strict precision families stay off',
      () async {
    final subscribed =
        await _subscribedCommands(<int>{0x0C, 0x0D, 0x04, 0x11});
    // The four bitmap-claimed core PIDs are present…
    expect(subscribed, containsAll(<String>{
      Elm327Protocol.engineRpmCommand,
      Elm327Protocol.vehicleSpeedCommand,
      Elm327Protocol.engineLoadCommand,
      Elm327Protocol.throttlePositionCommand,
    }));
    // …and so is every legacy optional PID: under #3532 the bitmap is a
    // prior, not a gate (under-reporting clones starved real PIDs).
    // Bitmap-absent PIDs poll NO DATA and self-evict via probation +
    // the scheduler's #2379 backoff instead of being pre-rejected.
    expect(subscribed, containsAll(optional),
        reason: '#3532 — the full target set subscribes optimistically');
    // The #3416 precision families keep the STRICT bitmap gate: the
    // resolved set lacks them, so they are never blind-subscribed.
    for (final cmd in precision) {
      expect(subscribed, isNot(contains(cmd)),
          reason: '$cmd is strictly gated and the bitmap lacks it');
    }
  });

  test(
      'a PID parked by runtime probation (3× real NO DATA) is dropped '
      'from the subscription set (#3532 self-eviction)', () async {
    final service = _SupportStubService(<int>{0x0C, 0x0D, 0x04, 0x11});
    // Drive 3 real NO DATA replies through the service's read path —
    // the _StubTransport answers every command with 'NO DATA', so three
    // MAF reads park PID 0x10 via SupportedPidsResolver.noteMode01Reply.
    for (var i = 0; i < 3; i++) {
      expect(await service.readMafGramsPerSecond(), isNull);
    }
    expect(service.isPidSupported(0x10), isFalse,
        reason: 'sanity: 3× real NO DATA parks MAF in probation');

    final subscribed = await _subscribedCommands(null, service: service);
    expect(subscribed, isNot(contains(Elm327Protocol.mafCommand)),
        reason: 'a probation-parked PID must not be subscribed');
    // The rest of the optional set stays optimistically live.
    expect(subscribed,
        containsAll(optional.difference({Elm327Protocol.mafCommand})));
    expect(subscribed, containsAll(core));
  });

  test(
      'a fully-capable car subscribes the unconditional core PLUS every '
      'optional PID', () async {
    final all = <int>{
      0x0C, 0x0D, 0x11, 0x04, 0x0F, 0x05, 0x06, 0x07, 0x2F, // core
      0x10, 0x0B, 0x5E, 0x44, 0x33, // optional (#2456 and earlier)
      0x49, 0x4A, 0x4B, 0x43, 0x08, 0x09, 0x5C, 0x46, // #2458/#2459
      0x24, 0x34, 0x66, 0x9D, 0xA2, 0x52, // Epic #3416 precision PIDs
    };
    final subscribed = await _subscribedCommands(all);
    expect(subscribed, containsAll(core));
    expect(subscribed, containsAll(optional));
    expect(subscribed, containsAll(precision),
        reason: 'a RESOLVED set naming the precision PIDs passes the '
            'strict isPidKnownSupported gate');
  });

  test(
      'a probe-less clone (discovery never ran) still rotates the core + '
      'legacy optional set (don\'t-reject-blind) but NEVER the strict '
      'precision families', () async {
    final subscribed = await _subscribedCommands(null);
    expect(subscribed, containsAll(core),
        reason: 'the unconditional core must always rotate');
    expect(subscribed, containsAll(optional),
        reason: 'blind session does not reject legacy optional PIDs');
    // #3416 contract change: unresolved ⇒ precision families OFF. Blind-
    // subscribing ~20 rare PIDs starved the 5 Hz dynamics tier (RPM
    // cadence collapse in the #726 scheduler tests).
    for (final cmd in precision) {
      expect(subscribed, isNot(contains(cmd)),
          reason: '$cmd must not be blind-subscribed on an unresolved set');
    }
  });
}
