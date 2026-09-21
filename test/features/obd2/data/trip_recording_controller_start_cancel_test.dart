// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4344 — a stop that lands while [TripRecordingController.start] awaits
/// I/O invalidates that start: when the held read finally answers, the
/// start creates nothing — no PID polling, no emit timer, no recording.
///
/// Each test holds one of the start's three awaits (the protocol search,
/// the identity reads, the engine-off voltage read) on a completer, stops,
/// releases the read, and lets fake time run.
library;

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';

import '../../../helpers/silence_error_logger.dart';

/// A fake ELM327 whose reply to one command waits on [release].
class _HeldReadTransport extends FakeObd2Transport {
  _HeldReadTransport(this.heldCommand, super.responses);

  final String heldCommand;
  final Completer<void> _release = Completer<void>();
  bool held = false;

  /// Hold only once armed — the connect and the bus probe send the same
  /// commands before the start does.
  bool armed = false;

  /// Every command the controller tried to send, even after a disconnect.
  final List<String> attempts = [];

  void release() => _release.complete();

  @override
  Future<String> sendCommand(String command) async {
    final cmd = command.trim();
    attempts.add(cmd);
    if (armed && cmd == heldCommand && !held) {
      held = true;
      await _release.future;
    }
    return super.sendCommand(command);
  }
}

/// A live car: every AT answers; the protocol search runs at start
/// (`ATSP0`, `0100`), then the identity reads (`01A6`, `0902`), then the
/// PID poll loop (`010C`, `010D`, …).
const Map<String, String> _liveCar = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  '0100': '41 00 BE 1F A8 13>',
  '01A6': '41 A6 00 01 6A 2C>',
};

/// A parked car: the bus is silent, the adapter reads 12.4 V — the start
/// reads the voltage, then goes GPS-first on an emit timer (#3858).
const Map<String, String> _parkedCar = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  'ATI': 'ELM327 v1.5>',
  '0100': 'UNABLE TO CONNECT>',
  'ATDPN': 'A0>',
  'ATRV': '12.4V>',
};

bool _isPoll(String cmd) => cmd == '010C' || cmd == '010D';

void main() {
  silenceErrorLoggerSpool();
  tearDown(Obd2VehiclePower.instance.reset);

  /// Start a controller on [transport] with its [heldCommand] read held;
  /// optionally stop it while held; release; run 30 s of fake time.
  /// Returns the commands sent and the live emits after the release, and —
  /// a second after it — the periodic timers the start added and the state.
  ({
    List<String> afterRelease,
    int emits,
    int periodicTimers,
    TripRecordingControllerState state,
  }) runStart(
    FakeAsync async,
    _HeldReadTransport transport, {
    required bool stopWhileHeld,
    bool silentBus = false,
  }) {
    final service = Obd2Service(transport);
    unawaited(service.connect());
    async.elapse(const Duration(seconds: 2));
    if (silentBus) {
      unawaited(service.discoverSupportedPids());
      async.elapse(const Duration(seconds: 10));
      expect(service.busProbe, Obd2BusProbeResult.probedSilent,
          reason: 'precondition: a silent bus');
    }
    final ctl = TripRecordingController(service: service);
    var emits = 0;
    final sub = ctl.live.listen((_) => emits++);
    // Periodic timers the service already runs are not the start's.
    final timersBefore = async.periodicTimerCount;
    transport.armed = true;
    unawaited(ctl.start());
    async.elapse(const Duration(milliseconds: 500));
    expect(transport.held, isTrue,
        reason: 'precondition: the start waits on ${transport.heldCommand}');

    if (stopWhileHeld) unawaited(ctl.stop());
    async.flushMicrotasks();
    final releasedAt = transport.attempts.length;
    transport.release();
    async.elapse(const Duration(seconds: 1));
    final state = ctl.currentState;
    final periodicTimers = async.periodicTimerCount - timersBefore;
    async.elapse(const Duration(seconds: 29));

    final result = (
      afterRelease: transport.attempts.sublist(releasedAt),
      emits: emits,
      periodicTimers: periodicTimers,
      state: state,
    );
    unawaited(sub.cancel());
    unawaited(ctl.stop());
    async.flushMicrotasks();
    return result;
  }

  group('a stop during start creates nothing once the held read answers', () {
    test('held in the protocol search', () {
      fakeAsync((async) {
        final r = runStart(async, _HeldReadTransport('0100', _liveCar),
            stopWhileHeld: true);
        expect(r.afterRelease.where(_isPoll), isEmpty,
            reason: 'no PID polling for a stopped trip');
        expect(r.afterRelease, isNot(contains('01A6')),
            reason: 'nor the identity reads that follow the search');
        expect(r.emits, 0);
        expect(r.periodicTimers, 0, reason: 'no emit timer, no poll loop');
        expect(r.state, TripRecordingControllerState.stopped);
      });
    });

    test('held in the identity reads', () {
      fakeAsync((async) {
        final r = runStart(async, _HeldReadTransport('01A6', _liveCar),
            stopWhileHeld: true);
        expect(r.afterRelease.where(_isPoll), isEmpty);
        expect(r.emits, 0);
        expect(r.periodicTimers, 0);
        expect(r.state, TripRecordingControllerState.stopped);
      });
    });

    test('held in the engine-off voltage read', () {
      fakeAsync((async) {
        final r = runStart(async, _HeldReadTransport('ATRV', _parkedCar),
            stopWhileHeld: true, silentBus: true);
        expect(r.emits, 0);
        expect(r.periodicTimers, 0,
            reason: 'the GPS-first emit timer must not start either');
        expect(r.state, TripRecordingControllerState.stopped);
      });
    });
  });

  test('without a stop, the same held start goes live once the read answers',
      () {
    fakeAsync((async) {
      final r = runStart(async, _HeldReadTransport('01A6', _liveCar),
          stopWhileHeld: false);
      expect(r.afterRelease.where(_isPoll), isNotEmpty);
      expect(r.emits, greaterThan(0));
      expect(r.periodicTimers, greaterThan(0));
      expect(r.state, TripRecordingControllerState.recording);
    });
  });
}
