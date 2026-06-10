// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'flutter_blue_plus_elm_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_pairing_mode.dart';

const _mac = 'AA:BB:CC:DD:EE:31';

/// Channel with the raw CCCD subscribe stubbed (FBP's `setNotifyValue`
/// hits the platform channel), capturing the budget [enableNotify] asked
/// for and optionally failing with an injected fault — optionally only
/// AFTER a delay, to prove the pairing-wait flag is up WHILE the
/// subscribe is in flight.
class _NotifyChannel extends FlutterBluePlusElmChannel {
  _NotifyChannel(super.device, {this.fault, this.delay});

  final Object? fault;
  final Duration? delay;
  final List<int> budgets = [];
  bool? pendingDuringSubscribe;

  @override
  Future<void> rawSetNotify(int timeoutSecs) async {
    budgets.add(timeoutSecs);
    pendingDuringSubscribe = Obd2PairingMode.pairingWaitPending.value;
    final d = delay;
    if (d != null) await Future<void>.delayed(d);
    final f = fault;
    if (f != null) throw f;
  }
}

BluetoothCharacteristic _fakeChar() => BluetoothCharacteristic(
      remoteId: const DeviceIdentifier(_mac),
      serviceUuid: Guid('0000fff0-0000-1000-8000-00805f9b34fb'),
      characteristicUuid: Guid('0000fff1-0000-1000-8000-00805f9b34fb'),
    );

_NotifyChannel _channel({Object? fault, Duration? delay}) {
  final ch = _NotifyChannel(BluetoothDevice.fromId(_mac),
      fault: fault, delay: delay);
  ch.debugPrimeOpenSession(_fakeChar());
  return ch;
}

void main() {
  setUp(() {
    Obd2PairingMode.resetForTest();
    Obd2ConnectTraceLog.clear();
  });
  tearDown(() {
    Obd2PairingMode.resetForTest();
    Obd2ConnectTraceLog.clear();
  });

  group('FlutterBluePlusElmChannel.enableNotify — first-connect pairing '
      'budget (#3181)', () {
    test('an UNMARKED device keeps the steady-state platform budget '
        '(RED on master: no budget selection existed)', () async {
      final ch = _channel();
      await ch.enableNotify();
      expect(ch.budgets,
          [FlutterBluePlusElmChannel.debugSetNotifyTimeout.inSeconds],
          reason: 'steady-state connects keep the tight #3014/#3118 bound');
    });

    test('a FIRST-connect device gets the generous 30 s pairing budget',
        () async {
      Obd2PairingMode.markFirstConnect(_mac);
      final ch = _channel();
      await ch.enableNotify();
      expect(ch.budgets, [Obd2PairingMode.firstConnectSetNotifySecs]);
    });

    test('pairingWaitPending is UP while the first-connect subscribe is in '
        'flight and DOWN after (the picker-hint contract)', () async {
      Obd2PairingMode.markFirstConnect(_mac);
      final ch = _channel(delay: const Duration(milliseconds: 10));
      expect(Obd2PairingMode.pairingWaitPending.value, isFalse);
      await ch.enableNotify();
      expect(ch.pendingDuringSubscribe, isTrue,
          reason: 'the hint must show WHILE the OS pairing dialog can be up');
      expect(Obd2PairingMode.pairingWaitPending.value, isFalse,
          reason: 'cleared in finally once the subscribe resolves');
    });

    test('pairingWaitPending is cleared in finally even when the subscribe '
        'FAILS', () async {
      Obd2PairingMode.markFirstConnect(_mac);
      final ch = _channel(fault: TimeoutException('Timed out after 30s'));
      await expectLater(ch.enableNotify(), throwsA(anything));
      expect(Obd2PairingMode.pairingWaitPending.value, isFalse);
    });

    test('a first-connect setNotify TIMEOUT rethrows as the TYPED '
        'Obd2PairingRequired (likely-pairing)', () async {
      Obd2PairingMode.markFirstConnect(_mac);
      final ch = _channel(fault: TimeoutException('Timed out after 30s'));
      await expectLater(
          ch.enableNotify(), throwsA(isA<Obd2PairingRequired>()));
    });

    test('an explicit AUTH failure rethrows as Obd2PairingRequired even on '
        'a NON-first connect', () async {
      final ch =
          _channel(fault: Exception('GATT_INSUFFICIENT_AUTHENTICATION'));
      await expectLater(
          ch.enableNotify(), throwsA(isA<Obd2PairingRequired>()));
    });

    test('a steady-state (non-first-connect) timeout stays the RAW timeout — '
        'NOT misclassified as pairing', () async {
      final ch = _channel(fault: TimeoutException('Timed out after 4s'));
      await expectLater(ch.enableNotify(), throwsA(isA<TimeoutException>()));
    });

    test('stamps set-notify-start and pairing-wait steps on the active trace '
        '(#3184 stage tags)', () async {
      Obd2PairingMode.markFirstConnect(_mac);
      final trace = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: _mac,
        requestedTransport: Obd2ConnectTransport.ble,
      );
      final ch = _channel();
      await ch.enableNotify();
      Obd2ConnectTraceLog.endTrace(trace);
      final labels =
          Obd2ConnectTraceLog.snapshot().single.steps.map((s) => s.label);
      expect(labels, containsAllInOrder(['set-notify-start', 'pairing-wait']));
    });
  });
}
