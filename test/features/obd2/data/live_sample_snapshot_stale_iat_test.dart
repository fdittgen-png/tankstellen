// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/pid_scheduler.dart';

/// #2505 — REGRESSION reproduction. `945f155e` (#2457) demoted IAT (PID
/// 0x0F) to ~0.5 Hz on the bandwidth-demotable `slowCorrection` tier, so
/// the speed-density fuel branch — the ONLY measured-fuel path for PSA /
/// Peugeot cars without PID 0x5E or MAF 0x10 — almost never sees a fresh
/// IAT on the same tick as MAP + RPM. The old branch demanded all three
/// same-tick, so `deriveFuelRateLPerHour()` returned null on every tick →
/// measured fuel vanished. The fix reuses the last-known IAT while it is
/// within the staleness window; this test pins both the restored value
/// (stale-but-recent IAT) and the bound (a too-old IAT still yields null).

/// Trivial transport — the snapshot test never reads the bus; it drives
/// the captured per-command callbacks directly with crafted responses.
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

/// An [Obd2Service] that reports every PID as supported (so the optional
/// MAP 0x0B / IAT speed-density inputs subscribe).
class _AllSupportedService extends Obd2Service {
  _AllSupportedService() : super(_StubTransport());
  @override
  bool isPidSupported(int pid) => true;
}

/// A [PidScheduler] subclass that captures each command's `onResult`
/// callback instead of running a timer. Lets the test push crafted PID
/// responses into the snapshot deterministically, with full control over
/// the (separately injected) snapshot clock.
class _CapturingScheduler extends PidScheduler {
  _CapturingScheduler() : super(transport: ((_) async => 'NO DATA'));

  final Map<String, void Function(String)> callbacks =
      <String, void Function(String)>{};

  @override
  void subscribe(
    String command,
    ScheduledPid config,
    void Function(String response) onResult,
  ) {
    callbacks[command] = onResult;
  }

  /// Deliver a crafted [response] to the callback registered for [command].
  void deliver(String command, String response) =>
      callbacks[command]!(response);
}

/// A controllable clock whose `now` the test advances by hand.
class _FakeClock {
  DateTime now;
  _FakeClock(this.now);
  DateTime call() => now;
}

void main() {
  // Crafted Mode-01 responses (see elm327_parsers_test.dart):
  //   RPM 010C: 41 0C 1A F8 -> 1726 rpm
  //   MAP 010B: 41 0B 64    -> 100 kPa
  //   IAT 010F: 41 0F 3C    -> 60 - 40 = 20 °C
  const rpmResponse = '41 0C 1A F8';
  const mapResponse = '41 0B 64';
  const iatResponse = '41 0F 3C';
  final t0 = DateTime(2026, 5, 31, 12);

  /// Builds a snapshot whose IAT latch landed [iatAgeSeconds] before [t0]
  /// (as the #2457 governor leaves it under BLE pressure) while MAP + RPM
  /// land exactly at [t0]. The clock is then parked at [t0] so the caller
  /// evaluates the derivation "now".
  LiveSampleSnapshot buildWithStaleIat(int iatAgeSeconds) {
    final clock = _FakeClock(t0.subtract(Duration(seconds: iatAgeSeconds)));
    final scheduler = _CapturingScheduler();
    final snapshot = LiveSampleSnapshot(
      service: _AllSupportedService(),
      onHighPriorityParse: (_) {},
      onSpeedSample: (_) {},
      clock: clock.call,
    );
    snapshot.subscribeAllTiers(scheduler);
    // IAT lands first, in the past (slow demotable tier).
    scheduler.deliver(Elm327Protocol.intakeAirTempCommand, iatResponse);
    // MAP + RPM land "now" — fast/dynamic, always current.
    clock.now = t0;
    scheduler.deliver(
        Elm327Protocol.intakeManifoldPressureCommand, mapResponse);
    scheduler.deliver(Elm327Protocol.engineRpmCommand, rpmResponse);
    return snapshot;
  }

  test(
      'governor left IAT stale-but-recent (5 s old) while MAP + RPM are '
      'current -> speed-density fuel is non-null (regression #2505)', () {
    final snapshot = buildWithStaleIat(5);
    final rate = snapshot.deriveFuelRateLPerHour();
    expect(rate, isNotNull,
        reason: 'a 5 s-old IAT is physically fine; measured fuel must '
            'survive the #2457 IAT demotion');
    expect(rate, greaterThan(0));
    expect(snapshot.lastFuelRateBranch, Obd2BranchTag.speedDensity);
  });

  test(
      'an IAT older than the staleness window (30 s) yields null — a value '
      'from a stalled / dropped link is correctly rejected (#2505)', () {
    final snapshot = buildWithStaleIat(30);
    final rate = snapshot.deriveFuelRateLPerHour();
    expect(rate, isNull,
        reason: 'a 30 s-old IAT is past the window; the branch must not '
            'reuse it');
    expect(snapshot.lastFuelRateBranch, Obd2BranchTag.none);
  });
}
