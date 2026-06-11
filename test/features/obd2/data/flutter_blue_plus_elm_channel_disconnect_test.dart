// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/flutter_blue_plus_elm_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_read_telemetry.dart';

/// #2900 — the BLE OBD2 channel flooded the error log with
/// `FlutterBluePlusException | writeCharacteristic | fbp-code: 6 | device is
/// not connected` write failures after a link drop (error-log #23, 25×): the
/// ~1 Hz speed poller kept writing into the dropped link, the raw FBP
/// exception escaped unreclassified, so [TripDropDetector] never saw a typed
/// disconnect and every per-cycle failure spooled an ERROR trace.
///
/// The fix mirrors the #2671 [ClassicElmChannel] + #2524
/// [BluetoothObd2Transport] precedents: a write that fails because the adapter
/// dropped mid-flight is reclassified into the recoverable typed
/// [Obd2DisconnectedException], which `_isTypedDisconnect` /
/// `isExpectedObd2ReadTransient` already route through pause/reconnect and
/// de-noise to a breadcrumb. Genuine non-disconnect BLE errors still surface.
class _CapturingRecorder implements TraceRecorder {
  final errors = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A channel whose raw characteristic write throws the injected fault, so the
/// reclassification in [FlutterBluePlusElmChannel.write] can be exercised
/// without a real BLE stack (a real [BluetoothCharacteristic.write] hits the
/// platform). [writeRaw] is the [visibleForTesting] seam.
class _InjectingChannel extends FlutterBluePlusElmChannel {
  _InjectingChannel(super.device, {required this.fault});

  final Object fault;
  int writeRawCalls = 0;

  @override
  Future<void> writeRaw(BluetoothCharacteristic char, List<int> bytes) async {
    writeRawCalls++;
    throw fault;
  }
}

BluetoothCharacteristic _fakeWriteChar() => BluetoothCharacteristic(
      remoteId: const DeviceIdentifier('AA:BB:CC:DD:EE:01'),
      serviceUuid: Guid('0000fff0-0000-1000-8000-00805f9b34fb'),
      characteristicUuid: Guid('0000fff2-0000-1000-8000-00805f9b34fb'),
    );

_InjectingChannel _channelThatFailsWith(Object fault) {
  final ch = _InjectingChannel(
    BluetoothDevice.fromId('AA:BB:CC:DD:EE:01'),
    fault: fault,
  );
  // Prime an established session so `write` passes its open-guard and reaches
  // the (injected) raw write.
  ch.debugPrimeOpenSession(_fakeWriteChar());
  return ch;
}

void main() {
  setUp(() {
    errorLogger.resetForTest();
    BreadcrumbCollector.clear();
  });
  tearDown(errorLogger.resetForTest);

  group('FlutterBluePlusElmChannel.write — disconnect reclassification (#2900)',
      () {
    test(
        'a FlutterBluePlusException(writeCharacteristic, fbp-code 6, "device '
        'is not connected") is rethrown as the recoverable '
        'Obd2DisconnectedException, NOT the raw FBP exception', () async {
      // The exact field shape from error-log #23.
      final fault = FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        6,
        'device is not connected',
      );
      final ch = _channelThatFailsWith(fault);

      await expectLater(
        ch.write([0x41, 0x54, 0x5A, 0x0D]),
        throwsA(isA<Obd2DisconnectedException>()),
        reason: 'the raw FlutterBluePlusException must be reclassified into '
            'the recoverable typed disconnect so the drop detector routes it '
            'through pause/reconnect instead of flooding the error log',
      );
      // The drop flipped the session closed, so the next write short-circuits
      // on the open-guard as the same typed disconnect (no raw write attempt).
      expect(ch.isOpen, isFalse);
    });

    test(
        'a FlutterBluePlusException "device is disconnected" is reclassified',
        () async {
      final ch = _channelThatFailsWith(FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        null,
        'device is disconnected',
      ));

      await expectLater(
        ch.write([0x01]),
        throwsA(isA<Obd2DisconnectedException>()),
      );
    });

    test(
        'an Android GATT_ERROR 133 mid-write is reclassified (dying link)',
        () async {
      final ch = _channelThatFailsWith(FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        133,
        'ANDROID_SPECIFIC_ERROR',
      ));

      await expectLater(
        ch.write([0x01]),
        throwsA(isA<Obd2DisconnectedException>()),
      );
    });

    test(
        'a PlatformException(not connected) mid-write is reclassified '
        '(mirrors #2524 BluetoothObd2Transport)', () async {
      final ch = _channelThatFailsWith(
        PlatformException(code: 'writeCharacteristic', message: 'not connected'),
      );

      await expectLater(
        ch.write([0x01]),
        throwsA(isA<Obd2DisconnectedException>()),
      );
    });

    test(
        'a GENUINE non-disconnect BLE error STILL surfaces unchanged '
        '(not swallowed, not reclassified)', () async {
      // A clone rejecting the write MODE is a real, distinct fault — it must
      // NOT be masked as a recoverable disconnect.
      final fault = FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        1,
        'characteristic does not support write without response',
      );
      final ch = _channelThatFailsWith(fault);

      await expectLater(
        ch.write([0x01]),
        throwsA(
          isA<FlutterBluePlusException>()
              .having((e) => e.code, 'code', 1),
        ),
        reason: 'a non-disconnect BLE fault must keep surfacing so a genuine '
            'adapter problem stays visible',
      );
      // A non-disconnect write failure does NOT tear down the session.
      expect(ch.isOpen, isTrue);
    });

    test(
        'after a drop, a write on the closed session short-circuits as the '
        'recoverable Obd2DisconnectedException without a raw write attempt',
        () async {
      final ch = _channelThatFailsWith(FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        6,
        'device is not connected',
      ));

      // First write trips the drop + reclassification and closes the session.
      await expectLater(
          ch.write([0x01]), throwsA(isA<Obd2DisconnectedException>()));
      final callsAfterFirst = ch.writeRawCalls;

      // Second write must NOT reach the raw write — the open-guard fires.
      await expectLater(
          ch.write([0x02]), throwsA(isA<Obd2DisconnectedException>()));
      expect(ch.writeRawCalls, callsAfterFirst,
          reason: 'a closed session must not dispatch into a dead link');
    });
  });

  group('FlutterBluePlusElmChannel — full session teardown on drop (#2907)',
      () {
    test(
        'a write-time drop tears down the FULL session (notify char + both '
        'subscriptions), not just _open/_writeChar', () async {
      final ch = _channelThatFailsWith(FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        6,
        'device is not connected',
      ));
      // The prime seam wires _writeChar + _notifyChar + both subscriptions —
      // the full state a live session holds.
      expect(ch.debugResidualSessionState, isTrue,
          reason: 'a primed session holds notify-char + subscription state');

      await expectLater(
          ch.write([0x01]), throwsA(isA<Obd2DisconnectedException>()));

      expect(ch.isOpen, isFalse);
      expect(ch.debugResidualSessionState, isFalse,
          reason: '#2907 — a confirmed drop must clear `_notifyChar` and '
              'cancel both subscriptions too. Before #2907 the handler cleared '
              'only `_open`/`_writeChar`, leaving stale notify/conn-state '
              'subscriptions a reconnect would double-wire on the next open()');
    });

    test(
        'a GENUINE non-disconnect write fault does NOT tear the session down',
        () async {
      // Regression-lock: only a confirmed disconnect clears the session. A
      // clone rejecting the write mode must leave the live session intact.
      final ch = _channelThatFailsWith(FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        1,
        'characteristic does not support write without response',
      ));

      await expectLater(
        ch.write([0x01]),
        throwsA(isA<FlutterBluePlusException>()),
      );
      expect(ch.isOpen, isTrue);
      expect(ch.debugResidualSessionState, isTrue,
          reason: 'a non-disconnect fault keeps the session fully wired');
    });
  });

  group('the reclassified disconnect de-noises through recordObd2ReadFailure',
      () {
    test(
        'isExpectedObd2ReadTransient accepts the reclassified disconnect',
        () {
      expect(
        isExpectedObd2ReadTransient(const Obd2DisconnectedException(
            'FlutterBluePlusElmChannel: write failed — adapter not connected')),
        isTrue,
      );
    });

    test(
        'a post-drop write routed through recordObd2ReadFailure records a '
        'breadcrumb and does NOT reach errorLogger (the #23 flood is stopped)',
        () async {
      final rec = _CapturingRecorder();
      errorLogger.testRecorderOverride = rec;

      final ch = _channelThatFailsWith(FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        6,
        'device is not connected',
      ));

      // Mirror the live speed-poll call site: the read helper catches the
      // channel error and routes it through the de-noiser.
      Object? caught;
      StackTrace? caughtStack;
      try {
        await ch.write([0x41, 0x54, 0x5A, 0x0D]);
      } catch (e, st) {
        caught = e;
        caughtStack = st;
      }
      expect(caught, isA<Obd2DisconnectedException>());
      recordObd2ReadFailure(caught!, caughtStack!,
          where: 'OBD2 readSpeed failed');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty,
          reason: 'the reclassified disconnect is an EXPECTED transient — it '
              'must NOT spool an ERROR trace (the error-log #23 ×25 flood)');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 read failed — expected transient'),
      );
    });

    test(
        'the RAW FlutterBluePlusException (the pre-fix escapee) would NOT be '
        'an expected transient — it WOULD reach errorLogger (RED-before proof)',
        () {
      // Documents the bug: before the reclassification the raw FBP exception
      // escaped `write`, and `isExpectedObd2ReadTransient` returns false for
      // it, so `recordObd2ReadFailure` ERROR-logs it → the flood.
      final raw = FlutterBluePlusException(
        ErrorPlatform.android,
        'writeCharacteristic',
        6,
        'device is not connected',
      );
      expect(isExpectedObd2ReadTransient(raw), isFalse);
    });
  });
}
